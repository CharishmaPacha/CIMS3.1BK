/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/20  AY      pr_QCInbound_SelectLPNs: Changed to give proper response when there are no LPNs (CIMSV3-472)
  2019/08/28  VS      pr_QCInbound_SelectLPNs: Changed to QC based on SKU Color and Size (CID-986)
  2019/02/20  RV      pr_QCInbound_SelectLPNs: Enhance to accept ReceiptId, ReceiverId and ReceiptNumber (CID-123)
  2019/02/12  RV/AY   pr_QCInbound_SelectLPNs: Initial revision (CID-53).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_QCInbound_SelectLPNs') is not null
  drop Procedure pr_QCInbound_SelectLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_QCInbound_SelectLPNs: This procedure first identifies the list of LPNs
   to be processed. It could be the provided list or all LPNs of a Receipt or
   Receiver.

 QCPercentage: What percent of the LPNs have tbe QCed from the given list of LPNs.
   this is determined by using rules (for future use) with a default for the client.

 After the list is identified, the QC Percentage would be determined.
 Then, the required number of LPNs are flagged (selected) randomly to meet the QCPercentage
 The flagged LPNs are then placed on QC Hold - again using rules
------------------------------------------------------------------------------*/
Create Procedure pr_QCInbound_SelectLPNs
  (@ReceiptId      TRecordId        = null,
   @ReceiptNumber  TReceiptNumber   = null,
   @ReceiverId     TRecordId        = null,
   @ReceiverNumber TReceiverNumber  = null,
   @ttLPNsToQC     TEntityKeysTable READONLY,
   @Operation      TOperation,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   -----------------------------------
   @Message        TMessage         output)
as
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName,
          @vRecordId          TRecordId,

          @vReceiptId         TRecordId,
          @vReceiptType       TTypeCode,
          @vVendorId          TVendorId,
          @vReceiverId        TRecordId,
          @vReceiverNumber    TReceiverNumber,
          @vQCPercentage      TInteger,
          @vTotalLPNs         TCount,
          @vPreselectedLPNs   TCount,
          @vLPNsToSelect      TCount,

          @xmlRulesData       TXML,
          @vResult            TResult;

declare @ttLPNsForQC table(RecordId       TRecordId identity(1,1),
                           LPNId          TRecordId,
                           LPN            TLPN,
                           NumLines       TCount,
                           SKUId          TRecordId,
                           SKU            TSKU,
                           SKU1           TSKU,
                           SKU2           TSKU,
                           SKU3           TSKU,
                           SKU4           TSKU,
                           ReceiptId      TRecordId,
                           ReceiverNumber TReceiverNumber,
                           ReceiptNumber  TReceiptNumber,
                           ReceiptType    TTypeCode,
                           VendorId       TVendorId,
                           InvStatus      TInventoryStatus,
                           Selected       TFlag default 'N',
                           QCGroup        Tcategory,
                           QCIndex        TRecordId);

declare @ttQCGroups table (QCGroup         Tcategory,
                           NumLPNs         TCount,
                           NumLPNsToSelect TCount);
begin
begin try
  select @vRecordId = 0;

  /* Check whether the #LPNsForQC not exists then create temp table*/
  if (object_id('tempdb..#LPNsForQC') is null)
    select * into #LPNsForQC
      from @ttLPNsForQC;

  /* Check whether the #QCGroups not exists then create temp table*/
  if (object_id('tempdb..#QCGroups') is null)
    select * into #QCGroups
      from @ttQCGroups;

  /* Get the ReceiptHeader information if ReceiptId/ReceiptNumber sent */
  if (@ReceiptId is not null) or (@ReceiptNumber is not null)
    select @vReceiptId   = ReceiptId,
           @vReceiptType = ReceiptType,
           @vVendorId    = VendorId
    from ReceiptHeaders
    where (ReceiptId = @ReceiptId) or ((ReceiptNumber = @ReceiptNumber) and (BusinessUnit  = @BusinessUnit));
  else
  /* Get the Receiver information if ReceiverId/ReceiverNumber sent */
  if (@ReceiverId is not null) or (@ReceiverNumber is not null)
    select @vReceiverId     = ReceiverId,
           @vReceiverNumber = ReceiverNumber
    from Receivers
    where (ReceiverId = @ReceiverId) or (ReceiverNumber = @ReceiverNumber) and (BusinessUnit = @BusinessUnit);

  if (exists (select * from @ttLPNsToQC))
    insert into #LPNsForQC (LPNId, LPN, SKU, SKU1, SKU2, SKU3, ReceiverNumber, ReceiptId, ReceiptNumber, ReceiptType, VendorId, InvStatus)
      select L.LPNId, L.LPN, L.SKU, L.SKU1, L.SKU2, L.SKU3, L.ReceiverNumber, L.ReceiptId, RH.ReceiptNumber, RH.VendorId, RH.ReceiptType, L.InventoryStatus
      from @ttLPNsToQC QC
        join LPNs L on            (QC.EntityId  = L.LPNId)
        join ReceiptHeaders RH on (L.ReceiptId  = RH.ReceiptId);
  else
  if (@vReceiptId is not null)
    insert into #LPNsForQC (LPNId, LPN, SKU, SKU1, SKU2, SKU3, ReceiverNumber, ReceiptId, ReceiptNumber, ReceiptType, VendorId, InvStatus)
      select LPNId, LPN, SKU, SKU1, SKU2, SKU3, ReceiverNumber, ReceiptId, ReceiptNumber, @vReceiptType, @vVendorId, InventoryStatus
      from LPNs
      where (ReceiptId = @vReceiptId);
  else
  if (@vReceiverId is not null)
    insert into #LPNsForQC (LPNId, LPN, SKU, SKU1, SKU2, SKU3, ReceiverNumber, ReceiptId, ReceiptNumber, ReceiptType, VendorId, InvStatus)
      select LPNId, LPN, SKU, SKU1, SKU2, SKU3, ReceiverNumber, ReceiptId, ReceiptNumber, @vReceiptType, @vVendorId, InventoryStatus
      from LPNs
      where (ReceiverNumber = @vReceiverNumber);

  select @vTotalLPNs = @@rowcount;

  if (@vTotalLPNs = 0) goto ExitHandler;

  /* Determine how many LPNs are already selected from the list */
  select @vPreselectedLPNs = count(*)
  from #LPNsForQC
  where (InvStatus = 'QC');

  /* Build the data for rule evaluation */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Operation',             @Operation) +
                           dbo.fn_XMLNode('Action',                'AutoSelectedQCHold') +
                           dbo.fn_XMLNode('ReceiptId',             @vReceiptId) +
                           dbo.fn_XMLNode('ReceiptNumber',         @ReceiptNumber) +
                           dbo.fn_XMLNode('ReceiptType',           @vReceiptType) +
                           dbo.fn_XMLNode('VendorId',              @vVendorId) +
                           dbo.fn_XMLNode('QCInbound_Percentage',  5) + /* Default */
                           dbo.fn_XMLNode('TotalLPNs',             @vTotalLPNs) +
                           dbo.fn_XMLNode('LPNsPreSelected',       @vPreselectedLPNs) +
                           dbo.fn_XMLNode('LPNsToSelect',          0) +
                           dbo.fn_XMLNode('BusinessUnit',          @BusinessUnit));

  /* select the LPNs to be QCed */
  exec pr_RuleSets_ExecuteAllRules 'QCInbound_AutoSelectLPNs', @xmlRulesData, @BusinessUnit;

  /* Get the Total Count of Selected LPNs */
  select @vLPNsToSelect = Count(*)
  from #LPNsForQC
  where Selected = 'Y' and InvStatus <> 'QC'

  /* Place selected LPNs on QC */
  exec pr_RuleSets_Evaluate 'QCInbound_LPNHoldorRelease', @xmlRulesData, @vResult output;

Exithandler:
  exec @Message = dbo.fn_Messages_BuildActionResponse 'QCInbound', 'SelectLPNs', @vLPNsToSelect, @vTotalLPNs, @vPreselectedLPNs;

end try
begin catch

  exec @ReturnCode = pr_ReRaiseError;
end catch;

  return(coalesce(@ReturnCode, 0));
end /* pr_QCInbound_SelectLPNs */

Go
