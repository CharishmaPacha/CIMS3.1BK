/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/12  SV      pr_ReceiptHeaders_Preprocess: Executing rules to update ReceiptType over Receipt for RMA (OB2-1794)
  2020/04/10  VM      pr_ReceiptHeaders_Preprocess: Process custom rules (HA-118)
  2020/02/20  MS      pr_ReceiptHeaders_Preprocess: Call pr_ReceiptHeaders_Recount instead of calculating in the procedure (JL-102)
  2017/05/04  OK      pr_ReceiptHeaders_Preprocess: Enhanced to recompute the ReceiptDetails based on the control var (CIMS-1162)
  2016/08/26  AY      pr_ReceiptHeaders_Preprocess: Recount and set status on RH after importing RO details (FB-746)
  2016/04/16  TK      pr_ReceiptHeaders_Preprocess: Update Preprocess flag (FB-672)
  2014/12/08  SK      pr_ReceiptHeaders_Preprocess: Added new procedure for pre processing receipt details.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptHeaders_Preprocess') is not null
  drop Procedure pr_ReceiptHeaders_Preprocess;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptHeaders_Preprocess:

  If Options = ROD then update the NumUnits on ROH from ROD
  If Options = LPN then update the LPNsIntransit and UnitsInTransit from LPNs.

  After ROD import call Preprocess with Option = ROD
  After ASNLPN and ASNLPNDtl Import, call preprocess with Option = ROH
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptHeaders_Preprocess
  (@ReceiptId      TRecordId,
   @Operation      TOperation,
   @BusinessUnit   TBusinessUnit = null)
as
  declare @vReceiptNumber       TReceiptNumber,
          @vReceiptType         TTypeCode,
          @vReceiptStatus       TStatus,

          @vNumUnitsOnROD       TQuantity,
          @vNumLPNsInTransit    TCount,
          @vNumUnitsInTransit   TQuantity,
          @vOverReceiptPercent  TControlValue,
          @vWarehouse           TWarehouse,
          @vSourceSystem        TName,

          @vMessageName         TMessageName,
          @vReturnCode          TInteger,

          @xmlRulesData         TXML;
begin
  /* Fetch the receipt number to valid whether the receipt exists or not */
  select @vReceiptNumber = ReceiptNumber,
         @vReceiptType   = ReceiptType,
         @vReceiptStatus = Status,
         @vWarehouse     = Warehouse,
         @vSourceSystem  = SourceSystem,
         @BusinessUnit   = coalesce(@BusinessUnit, BusinessUnit)
  from ReceiptHeaders
  where (ReceiptId = @ReceiptId);

  if (@ReceiptId is null)
    set @vMessageName = 'ReceiptIsRequired';
  else
  if (@vReceiptNumber is null)
    set @vMessageName = 'ReceiptIsInvalid';
  else
  if (@Operation is null)
    set @vMessageName = 'OptionIsRequired';
  else
  if (@Operation not in ('Import_ROD', 'Import_ASNLPN', 'Import_ASNLPNDetail'))
    set @vMessageName = 'OptionIsInvalid';

  if (@vMessageName is not null)
    goto Errorhandler;

  /* Get the Extra Qty allowed from control var for the receipt type */
  select @vOverReceiptPercent  = dbo.fn_Controls_GetAsinteger('Receiving_' + @vReceiptType, 'OverReceiptPercent', 5, @BusinessUnit, null /* UserId */);

  /* Setup Rules data */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                         dbo.fn_XMLNode('EntityType',          'Receipt')          +
                         dbo.fn_XMLNode('Operation',           @Operation)         +
                         dbo.fn_XMLNode('ReceiptId',           @ReceiptId)         +
                         dbo.fn_XMLNode('ReceiptType',         @vReceiptType)      +
                         dbo.fn_XMLNode('ReceiptStatus',       @vReceiptStatus)    +
                         dbo.fn_XMLNode('BusinessUnit',        @BusinessUnit)      +
                         dbo.fn_XMLNode('Warehouse',           @vWarehouse)        +
                         dbo.fn_XMLNode('SourceSystem',        @vSourceSystem)     +
                         dbo.fn_XMLNode('OverReceiptPercent',  @vOverReceiptPercent));

  /* Executing rules to update ReceiptType over Receipt for RMA */
  exec pr_RuleSets_ExecuteRules 'ReceiptHdr_PreprocessUpdates', @xmlRulesData;

  /* If Options = ROD then update the NumUnits on ROH from ROD */
  If (@Operation = 'Import_ROD')
    begin
      /* Update the counts as well as status. If new lines are added, the status would have to be recomputed */
      exec pr_ReceiptHeaders_SetStatus @ReceiptId;
    end
  else
  if (@Operation like 'Import_ASNLPN%')
    begin
      exec pr_ReceiptHeaders_Recount @ReceiptId;
    end

  /* Update the Extra quantity allowed on the Receipt Details based on the OverReceiptPercent */
  exec pr_RuleSets_ExecuteRules 'ReceiptDtl_PreprocessUpdates', @xmlRulesData;

  /* Update ReceiptHeader as preprocess completed */
  update ReceiptHeaders
  set PreProcessFlag  = 'Y' /* Yes */,
      ModifiedDate    = current_timestamp,
      ModifiedBy      = 'CIMSAgent'
  where (ReceiptId = @ReceiptId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ReceiptHeaders_Preprocess */

Go
