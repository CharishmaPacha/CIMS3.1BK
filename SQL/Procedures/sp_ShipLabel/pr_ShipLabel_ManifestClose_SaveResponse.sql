/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/16  RV      pr_ShipLabel_ManifestClose_GetDataToProcess
                        pr_ShipLabel_ManifestClose_SaveResponse: Initial version
                        pr_ShipLabel_GetLabelFormat, pr_ShipLabel_GetLabelsToPrint,
                        pr_ShipLabel_GetLabelsToPrintProcess: Changed CarrierInterface domain name (S2GCA-434)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_ManifestClose_SaveResponse') is not null
  drop Procedure pr_ShipLabel_ManifestClose_SaveResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_ManifestClose_SaveResponse:
  This procedure is called from console application to export to Manifest Close complete

@xmlInput xml structure:
<OutputXML>
  <InterfaceLogId>LogId</InterfaceLogId>
  <TransferType>MainfestExport</TransferType>
  <RecordType>ME</RecordType>
  <ManifestExportBatch>ManifestExportBatch</ManifestExportBatch>
  <ManifestCloseResult>Notification</ManifestCloseResult>
  <BusinessUnit>S2G</BusinessUnit>
  <UserId>CIMSAgent</UserId>
</OutputXML>'

@xmlResult xml structure:
For future use.
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_ManifestClose_SaveResponse
  (@xmlInput          XML,
   @xmlResult         XML output)
as
  declare @vInterfaceLogId            TRecordId,
          @vTransferType              TTransferType,
          @vRecordType                TRecordType,

          @vManifestExportBatch       TBatch,
          @vManifestCloseResult       TDescription,

          @vRecordsProcessed          TCount,
          @vRecordsFailed             TCount,
          @vRecordsPassed             TCount,

          @vBusinessUnit              TBusinessUnit,
          @vUserId                    TUserId;

begin /* pr_ShipLabel_ManifestClose_SaveResponse */
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @vRecordsFailed = 0;

  if (@xmlInput is null)
    return;

  /* Based upon the Manifest service close response, we may add Response info, based on the response info need to update
     ShipLabels and InterfaceLogDetails */
  select @vInterfaceLogId            = Record.Col.value('InterfaceLogId[1]',            'TRecordId'),
         @vManifestExportBatch       = Record.Col.value('ManifestExportBatch[1]',       'TBatch'),
         @vTransferType              = Record.Col.value('TransferType[1]',              'TTransferType'),
         @vRecordType                = Record.Col.value('RecordType[1]',                'TRecordType'),
         @vManifestCloseResult       = Record.Col.value('ManifestCloseResult[1]',       'TDescription'),
         @vBusinessUnit              = Record.Col.value('BusinessUnit[1]',              'TBusinessUnit'),
         @vUserId                    = Record.Col.value('UserId[1]',                    'TUserId')
  from @xmlInput.nodes('/OutputXML') as Record(Col);

  if (charindex('Error:', @vManifestCloseResult) > 0)
    begin
      /* Update the process status based on the response, this will change*/
      update SL
      set SL.ManifestExportStatus    = 'XE' /* Manifest Export Error */,
          SL.ManifestExportTimeStamp = current_timestamp,
          SL.ModifiedDate            = current_timestamp,
          SL.ModifiedBy              = @vUserId
      from ShipLabels SL
      where (SL.ManifestExportBatch  = @vManifestExportBatch) and
            (SL.ManifestExportStatus = 'XI' /* Manifest Export Inprogress */);

      select @vRecordsFailed = @@rowcount;
    end
  else
    /* Update the remaining labels of the export with export complete */
    update SL
    set SL.ManifestExportStatus    = 'XC' /* Export Completed */,
        SL.ManifestExportTimeStamp = current_timestamp,
        SL.ModifiedDate            = current_timestamp,
        SL.ModifiedBy              = @vUserId
    from ShipLabels SL
    where (SL.ManifestExportBatch  = @vManifestExportBatch) and
          (SL.ManifestExportStatus = 'XI' /* Export Inprogress */);

  if (@vRecordsFailed > 0)
    /* Log all errors in InterfaceLogDetails */
    insert into InterfaceLogDetails (ParentLogId, TransferType, RecordType, KeyData, LogMessage, ResultXML, BusinessUnit)
      select @vInterfaceLogId, @vTransferType, @vRecordType,
             @vManifestExportBatch , @vManifestCloseResult /* LogMessage */, null /* ResultXML */, @vBusinessUnit;

  /* Update counts & status on Interface log */
  exec pr_InterfaceLog_UpdateCounts @vInterfaceLogId, @vRecordsFailed;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;
end catch
end /* pr_ShipLabel_ManifestClose_SaveResponse */

Go
