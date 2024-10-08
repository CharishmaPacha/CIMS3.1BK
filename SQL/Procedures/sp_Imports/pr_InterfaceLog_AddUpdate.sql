/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/04/20  VS/TK   pr_Imports_ImportRecord, pr_InterfaceLog_AddUpdateDetails, pr_Imports_Contact:
  2017/07/05  NB      pr_InterfaceLog_Prepare: corrected caller for pr_InterfaceLog_AddUpdate to pass in null for xmlDocHandle param(CIMS-1183)
  2017/07/03  NB      pr_InterfaceLog_AddUpdate: Enhanced to handle log processing for exports to update older records on batch reprocess,
                      pr_InterfaceLog_AddUpdate: Migrated changes from Staging SQL. changes suggested for
                      pr_InterfaceLog_AddUpdate: Update with latest xml processed
                      pr_InterfaceLog_AddUpdateDetails: Minor changes to input params.
  2013/08/04  AY      pr_InterfaceLog_AddUpdateResults, pr_InterfaceLog_SaveResult: Added.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_InterfaceLog_AddUpdate') is not null
  drop Procedure pr_InterfaceLog_AddUpdate;
Go
/*------------------------------------------------------------------------------
  Procedure pr_InterfaceLog_AddUpdate is used to add the given entry to InterfaceLog
------------------------------------------------------------------------------*/
Create Procedure pr_InterfaceLog_AddUpdate
  (@SourceSystem          TName         = null,
   @TargetSystem          TName         = null,
   @SourceReference       TName         = null,
   @TransferType          TTransferType = null,
   @RecordType            TRecordType   = null,
   @BusinessUnit          TBusinessUnit = null,
   @xmlData               Xml,
   @xmlDocHandle          TInteger,
   @RecordsProcessed      TCount,
   @LogId                 TRecordId    output,
   @RecordTypes           TRecordTypes output)
as
  declare @vRecordsPassed  TCount;
begin
  select @RecordTypes = nullif(@RecordTypes, '');

  /* Migrated from FB */
  if ((@LogId is null) and (@TransferType = 'Export'))
    begin
      /* Update any existing inprocess log records status, prior to inserting a new log record
         This could be case when the same batch is being reprocessed */
      update InterfaceLog
      set Status = case when ((RecordsFailed > 0) or (RecordsProcessed > RecordsPassed)) then 'F' else 'S' end
      where (SourceReference = @SourceReference) and (Status = 'P' /* Inprocess */);
    end

  /* Fetch any existing log record id when it is not passed in, to update the in process records */
  if (@LogId is null)
    select @LogId = RecordId
    from InterfaceLog
    where (SourceReference = @SourceReference    ) and    /* FileName */
          (Status          = 'P' /* In process */);

  if (@LogId is null)
    begin
      /* In the case of exports, all the records exported are considered as processed successfully */
      set @vRecordsPassed = case when (@TransferType = 'Export') then @RecordsProcessed else 0 end;

      /* While inserting a new log record, verify if document handle is given. If given, fetch relevant details from the document */
      if (@xmlDocHandle is not null)
        begin
          /* Read header values from XML */
          select @SourceSystem    = SourceSystem,
                 @TargetSystem    = TargetSystem,
                 @SourceReference = SourceReference
          from OPENXML(@xmlDocHandle, '//msg/msgHeader', 2)
          with (SourceSystem           TName,
                TargetSystem           TName,
                SourceReference        TName);
        end

      /* If RecordTypes is given use it, else use RecordType */
      insert into InterfaceLog(TransferType, RecordTypes, SourceReference, SourceSystem, TargetSystem, InputXML, RecordsProcessed, RecordsPassed, BusinessUnit)
        select @TransferType, coalesce(@RecordTypes, @RecordType),
               @SourceReference, @SourceSystem, @TargetSystem,
               convert(varchar(max), convert(nvarchar(max), @xmlData)),
               @RecordsProcessed, @vRecordsPassed, @BusinessUnit;

       select @LogId = Scope_Identity();
    end
  else
    begin
      /* Increment the Records processed */
      update InterfaceLog
      set InputXML          = convert(varchar(max), convert(nvarchar(max), @xmlData)),
          RecordsProcessed += @RecordsProcessed,
          ModifiedDate      = current_timestamp
      where RecordId = @LogId;
    end
end /* pr_InterfaceLog_AddUpdate */

Go
