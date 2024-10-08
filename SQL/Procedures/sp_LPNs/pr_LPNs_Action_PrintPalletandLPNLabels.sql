/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/11  OK      pr_LPNs_Action_PrintPalletandLPNLabels: Added new action proc to print all selected LPNs and associated Pallets (HA-1645)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Action_PrintPalletandLPNLabels') is not null
  drop Procedure pr_LPNs_Action_PrintPalletandLPNLabels;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Action_PrintPalletandLPNLabels:
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Action_PrintPalletandLPNLabels
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,

          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,

          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,

          @vPalletLabelFormatName      TName,
          @vLPNLabelFormatName         TName,
          @vLabelPrinterName           TName;

begin /* pr_Module_Action_Name */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = '';

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Read inputs from XML */
  select @vPalletLabelFormatName   = nullif(Record.Col.value('PalletLabelFormatName[1]',  'TName'), ''),
         @vLPNLabelFormatName      = nullif(Record.Col.value('LPNLabelFormatName[1]',     'TName'), ''),
         @vLabelPrinterName        = nullif(Record.Col.value('LabelPrinterName[1]',       'TName'), '')
  from @xmlData.nodes('/Root/Data') as Record(Col);

  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Insert all the selected LPNs to #EntitiesToPrint to print all LPN Labels */
  insert into #EntitiesToPrint (EntityType, EntityId, EntityKey, Operation, DocumentFormat, LabelPrinterName)
    select 'LPN', EntityId, EntityKey, 'PrintPalletandLPNLabels', @vLPNLabelFormatName, @vLabelPrinterName
    from #ttSelectedEntities

  /* Insert all the associated pallets of selected LPNs to #EntitiesToPrint to print Pallet Labels */
  insert into #EntitiesToPrint (EntityType, EntityId, EntityKey, Operation, DocumentFormat, LabelPrinterName)
    select distinct 'Pallet', L.PalletId, L.Pallet, 'PrintPalletandLPNLabels', @vPalletLabelFormatName, @vLabelPrinterName
    from LPNs L
      join #ttSelectedEntities SE on (SE.EntityId = L.LPNId);

  exec pr_Printing_EntityPrintRequest 'PalletAndLPNs', 'PrintLabels', 'LPN', null /* EntityId */, null /* EntityKey */,
                                      @BusinessUnit, @UserId,
                                      @RequestMode = 'IMMEDIATE', @LabelPrinterName = @vLabelPrinterName;

  /* Temporay to return the success message. pr_Printing_EntityPrintRequest is not returning the which records are printed and which are not
     We need to findout some way to return proper success message */
  select @vRecordsUpdated = @vTotalRecords;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Action_PrintPalletandLPNLabels */

Go
