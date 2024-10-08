/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/08  MS      pr_Imports_ImportRecord, pr_InterfaceLog_SaveResult: Insert HostRecId in Interfacelogdetails (HA-126)
                      pr_InterfaceLog_SaveResult: Changed datatype from TFlags to TControlValue for ControlValue variables (CIMS-2979)
  2013/08/04  AY      pr_InterfaceLog_AddUpdateResults, pr_InterfaceLog_SaveResult: Added.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_InterfaceLog_SaveResult') is not null
  drop Procedure pr_InterfaceLog_SaveResult;
Go
/*------------------------------------------------------------------------------
  Procedure pr_InterfaceLog_SaveResult is used to save the results in the
   InterfaceLogDetails if it already exists, else adds a new record.
------------------------------------------------------------------------------*/
Create Procedure pr_InterfaceLog_SaveResult
  (@ParentLogId    TRecordId,
   @RecordType     TRecordType,
   @TransferType   TTransferType,
   @BusinessUnit   TBusinessUnit,
   @Inputxml       XML,
   @Resultxml      XML,
   @LogMessage     TDescription  = null,
   @KeyData        TReference    = null,
   @HostReference  TReference    = null,
   @HostRecId      TRecordId,
   -------------------------------------
   @ILogRecordId   TRecordId output)
as
  declare @vReturnCode  TInteger,
          @vResultxml   xml,
          @vDebugOption TControlValue;
begin
  /* Get Debug option - default to debug on error only */
  select @vReturnCode  = 0,
         @vDebugOption = dbo.fn_Controls_GetAsString('IMPORT_'+ @RecordType, 'DEBUG', 'E' /* Default: on Error only */, @BusinessUnit, '' /* UserId */) ;

  /* Return as XML any errors that have been inserted into the errors table
     The output will look similar to this (but null if there are no records):
     <Errors>
       <Error>Some error message</Error>
       <Error>Some other error message</Error>
     </Errors>
  */
  set @vResultxml = (
    select Error
    from #Errors
    for xml path(''), elements, root('Errors')
  );

  /* If there were no errors, then set return code as zero, else 1 to indicate the error */
  select @vReturnCode = case when @vResultxml is null then 0 else 1 end;

  /* If there is an error, and need to log it, do so */
  if (@vDebugOption = 'E' /* Debug On Error */) and (@vResultxml is not null)
    begin
      exec pr_InterfaceLog_AddUpdateDetails @ParentLogId, @RecordType, @TransferType, @BusinessUnit, @Inputxml, @vResultxml,
                                            @HostRecId    = @HostRecId,
                                            @ILogRecordId = @ILogRecordId output;
    end
  else
  if  (@vDebugOption in ('A' /* Always */))
    begin
      exec pr_InterfaceLog_AddUpdateDetails @ParentLogId  = @ParentLogId,
                                            @RecordType   = @RecordType,
                                            @TransferType = @TransferType,
                                            @BusinessUnit = @BusinessUnit,
                                            @Resultxml    = @vResultxml,
                                            @HostRecId    = @HostRecId,
                                            @ILogRecordId = @ILogRecordId output;
    end

   return(coalesce(@vReturnCode, 0));
end /* pr_InterfaceLog_SaveResult */

Go
