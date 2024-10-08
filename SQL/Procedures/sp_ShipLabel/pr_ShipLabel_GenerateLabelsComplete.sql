/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/06  OK      pr_ShipLabel_GenerateLabelsComplete: Changes to use new proc pr_PrintJobs_EvaluatePrintStatus
  2020/07/30  RV      pr_ShipLabel_GenerateLabelsComplete: Made changes to update the print dependencies on Tasks and Waves
                      pr_ShipLabel_GenerateLabelsComplete: Change status code from E to LGE (S2G-110)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GenerateLabelsComplete') is not null
  drop Procedure pr_ShipLabel_GenerateLabelsComplete;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GenerateLabelsComplete: This procedure is called from console
   application after generate ship labels to log interface details

  @XMLInput structure:
  <Root>
    <InterfaceLogId>LogId<InterfaceLogId>
  </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GenerateLabelsComplete
  (@xmlInput          XML,
   @xmlResult         XML output) -- for future use
as
  declare @vProcessBatch          TReference,

          @vInterfaceLogId        TRecordId,
          @vTransferType          TTransferType,
          @vRecordType            TRecordType,
          @vWaveId                TRecordId,

          @vRecordsProcessed      TCount,
          @vRecordsFailed         TCount,
          @vRecordsPassed         TCount,

          @vXMLEntities           XML,
          @vXMLResult             TXML,

          @vBusinessUnit          TBusinessUnit,
          @vUserId                TUserId;

  declare @ttInterfaceLogDetails  table
          (RecordId        TRecordId identity(1,1),

           KeyData         TReference,
           ResultXML       TXML);
  declare @ttPrintEntitiesToEvaluate TPrintEntities;

begin /* pr_ShipLabel_GenerateLabelsComplete */
begin try
  begin transaction;
  SET NOCOUNT ON;

  if (@xmlInput is null)
    return;

  select @vInterfaceLogId = Record.Col.value('InterfaceLogId[1]', 'TRecordId'),
         @vTransferType   = Record.Col.value('TransferType[1]',   'TTransferType'),
         @vRecordType     = Record.Col.value('RecordType[1]',     'TRecordType'),
         @vBusinessUnit   = Record.Col.value('BusinessUnit[1]',   'TBusinessUnit'),
         @vUserId         = Record.Col.value('UserId[1]',         'TUserId')
  from @xmlInput.nodes('/Root') as Record(Col);

  /* While inserting SourceReference ProcessBatch prefix with GenerateLabels_, So we exclude this to get the ProcessBatchNo */
  select @vProcessBatch = substring(SourceReference, charindex('_', SourceReference) + 1, len(SourceReference))
  from InterfaceLog
  where (RecordId = @vInterfaceLogId);

  /* Copy errors from ShipLabels to InterfaceLogDetails */
  insert into InterfaceLogDetails (ParentLogId, TransferType, RecordType, KeyData, ResultXML, BusinessUnit)
    select @vInterfaceLogId, @vTransferType, @vRecordType, EntityKey,
           /* Build Result XML */
           '<Error>' +
             dbo.fn_XMLNode('Notification', Notifications) +
           '</Error>',
            @vBusinessUnit
    from ShipLabels
    where (ProcessBatch  = @vProcessBatch) and
          (ProcessStatus = 'LGE' /* Label Generation Error */) and
          (Status        = 'A') and
          (BusinessUnit  = @vBusinessUnit);

  /* Save failed record count */
  select @vRecordsFailed = @@rowcount;

  /* Update counts & status on Interface log */
  exec pr_InterfaceLog_UpdateCounts @vInterfaceLogId, @vRecordsFailed;

  /* Prepare hash table to evaluate Print status */
  select * into #ttEntitiesToEvaluate from @ttPrintEntitiesToEvaluate;
  insert into #ttEntitiesToEvaluate(EntityId, EntityType)
    select distinct WaveId, 'Wave'
    from ShipLabels
    where (ProcessBatch = @vProcessBatch) and (Status = 'A') and (BusinessUnit = @vBusinessUnit);

  /* Compute Wave PrintStatus & Task PrintStatus */
  exec pr_PrintJobs_EvaluatePrintStatus @vBusinessUnit, @vUserId;

  commit transaction;
end try
begin catch
  rollback transaction;
end catch
end /* pr_ShipLabel_GenerateLabelsComplete */

Go
