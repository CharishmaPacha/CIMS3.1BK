/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/21  SK      pr_Imports_ImportRecords, pr_InterfaceLog_AddDetails: Eliminate XML logging when not required (HA-2952)
                      pr_InterfaceLog_AddDetails: Import process changed to New process by using ##Tables (HA-3084)
  2021/06/30  RKC     pr_Imports_ReceiptHeaders, pr_Imports_ReceiptHeaders_Validate, pr_InterfaceLog_AddDetails: Made changes to Replaced temp table with hash table (HA-2933)
  2020/03/15  MRK     pr_Imports_ImportRecords, pr_Imports_ImportRecords, pr_Imports_ValidateASNLPNDetails, pr_InterfaceLog_AddDetails
  2018/01/22  TD      pr_Imports_GetXmlResult,pr_InterfaceLog_AddDetails:Changes to CIMSRecId on DE tables (S2G-135)
  2016/07/01  TD      pr_InterfaceLog_AddDetails:Changes to record while deleting a record.
  2016/06/25  TK      pr_InterfaceLog_AddDetails: Corrected Data mapping (HPI-192)
  2014/05/14  NB      pr_InterfaceLog_AddDetails: Added new procedure to insert into InterfaceLogDetails
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_InterfaceLog_AddDetails') is not null
  drop Procedure pr_InterfaceLog_AddDetails;
Go
/*------------------------------------------------------------------------------
  Procedure pr_InterfaceLog_AddDetails is used to add the bulk entries
   to InterfaceLogDetails, and update the counts on the respective interfacelog header

  Caller can pass in the valdiations using @ImportValidations or #ImportValidations

  #ImprotValidations: TImportValidationType
------------------------------------------------------------------------------*/
Create Procedure pr_InterfaceLog_AddDetails
  (@ParentLogId        TRecordId,
   @TransferType       TTransferType,
   @BusinessUnit       TBusinessUnit,
   @ImportValidations  TImportValidationType READONLY)
as
  declare @vRecordsProcessed   TCount,
          @vRecordsPassed      TCount,
          @vRecordsFailed      TCount,
          @vDebugOption        TControlValue;
begin /* pr_InterfaceLog_AddDetails */

  /* If caller created #ImportValidations, then assume that they are already loaded
     else load the input table into hash table */
  if (object_id('tempdb..#ImportValidations') is null)
    select * into #ImportValidations from @ImportValidations

  /* capture the counts */
  select  @vRecordsProcessed = count(*) ,
          @vRecordsPassed    = sum(case when RecordAction <> 'E' then 1 else 0 end),
          @vRecordsFailed    = sum(case when RecordAction = 'E' then 1 else 0 end)
   from #ImportValidations;

  /* Fetch the debug option from controls based on the RecordType and Business Unit of the imported or Updated records
     Assumption: All records are for the same BusinessUnit and RecordType */
  select top 1
         @vDebugOption = dbo.fn_Controls_GetAsString('IMPORT_'+ RecordType, 'DEBUG', 'E' /* Default: on Error only */, BusinessUnit, '' /* UserId */)
  from #ImportValidations
  where (RecordAction in ('I', 'U', 'D', 'R', 'C'));

   /* Log Errors or All records, based on the debug option */
  if ((@vDebugOption in ('A' /* Always */)) or
      (exists (select * from #ImportValidations where (RecordAction = 'E'))))
    begin
      insert into InterfaceLogDetails (ParentLogId, TransferType, RecordType, KeyData, HostReference, BusinessUnit,
                                       Inputxml, Resultxml, HostRecId)
        select @ParentLogId, @TransferType, RecordType, KeyData, HostReference, BusinessUnit,
               case when (RecordAction = 'E') then convert(varchar(max), convert(nvarchar(max), Inputxml)) else null end,
               convert(varchar(max), convert(nvarchar(max), Resultxml)),
               HostRecId
        from #ImportValidations
        where ((RecordAction = 'E') or (@vDebugOption in ('A' /* Always */)));
    end

  /* Update the counts.
     update the ModifiedDate - but not the EndDatetime as that should be updated when the file is completed */
  update InterfaceLog
  set RecordsPassed = coalesce(RecordsPassed, 0) + coalesce(@vRecordsPassed, 0),
      RecordsFailed = coalesce(RecordsFailed, 0) + coalesce(@vRecordsFailed, 0),
      ModifiedDate  = current_timestamp,
      EndTime       = current_timestamp
  where (RecordId = @ParentLogId);
end /* pr_InterfaceLog_AddDetails */

Go
