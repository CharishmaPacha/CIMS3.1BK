/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  TK      pr_API_6River_Outbound_GroupCancel_GetMsgData & pr_API_6River_Outbound_PickWave_GetMsgData:
  2021/02/12  TK      pr_API_6River_Outbound_PickWave_GetMsgData: Changes to format message data properly
  pr_API_6River_Outbound_PickWave_GetMsgData: groupType should be batchPick for PTC & SLB (CID-1624)
  2020/11/27  TK      pr_API_6River_Outbound_PickWave_GetMsgData: Fixed issue with locating identifiers in PickWave JSON (CID-1583)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_6River_Outbound_PickWave_GetMsgData') is not null
  drop Procedure pr_API_6River_Outbound_PickWave_GetMsgData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_6River_Outbound_PickWave_GetMsgData generates Picks data in JSON format for the given entity
------------------------------------------------------------------------------*/
Create Procedure pr_API_6River_Outbound_PickWave_GetMsgData
  (@IntegrationName    TName,
   @MessageType        TName,
   @EntityType         TTypeCode,
   @EntityId           TRecordId,
   @EntityKey          TEntityKey,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @MessageData        TVarchar   output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @ResultParam             TVarchar,
          @vTranCount              TCount,

          @vFieldList              TVarchar,
          @vSQLQuery               TNVarChar;
  declare @ttTaskDetails           TEntityKeysTable,
          @ttTaskDetailsToExport   TEntityKeysTable;
begin /* pr_API_6River_Outbound_PickWave_GetMsgData */
begin try
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vTranCount   = @@trancount;

  /* If we are not running in the scope of the transaction, then start one */
  if (@vTranCount = 0) begin transaction;

  /* Create Required hash tables */
  select * into #TaskDetailsToConfirm from @ttTaskDetails;
  select * into #TaskDetailsToExport from @ttTaskDetailsToExport;

  /* Get the task details to be exported based upon entity type */
  if (@EntityType = 'Wave')
    insert into #TaskDetailsToConfirm (EntityId)
      select TaskDetailId
      from TaskDetails
      where (WaveId       = @EntityId) and
            (UnitsToPick  > 0)         and
            (ExportStatus ='ReadyToExport');
  else
  if (@EntityType = 'PickTicket')
    insert into #TaskDetailsToConfirm (EntityId)
      select TaskDetailId
      from vwUIPickTaskDetails
      where (OrderId      = @EntityId) and
            (UnitsToPick  > 0)         and
            (ExportStatus = 'ReadyToExport');
  else
  if (@EntityType = 'LPN')
    insert into #TaskDetailsToConfirm (EntityId)
      select TaskDetailId
      from vwUIPickTaskDetails
      where (TempLabelId  = @EntityId) and
            (UnitsToPick  > 0)         and
            (ExportStatus = 'ReadyToExport');

  exec pr_TaskDetails_ConfirmReservation null, @BusinessUnit, @UserId;

  insert into #TaskDetailsToExport (EntityId)
    select TaskDetailId
    from TaskDetails TD
      join #TaskDetailsToConfirm TDC on (TD.TaskDetailId = TDC.EntityId)
    where (UnitsToPick  > 0) and
          (ExportStatus in ('ReadyToExport'));

  /* If there are no picks to be exported then return */
  if not exists (select * from #TaskDetailsToExport) return;

  /* Build Message Type */
  select top 1 @MessageType = 'PickWave_' + WaveType
  from vwUIPickTaskDetails vwPTD
    join #TaskDetailsToExport TDE on (vwPTD.TaskDetailId = TDE.EntityId);

  /* Get the Field List to generate wave data */
  exec pr_API_GetInterfaceFields @IntegrationName, @MessageType, @BusinessUnit, @vFieldList out;

  /* Build Query with task details to be exported */
  select @vSQLQuery = 'select @ResultParam =
                        (select ''pickWave'' messagetype,
                          (select ' + @vFieldList +
                           ' from vwUIPickTaskDetails vwPTD
                               join #TaskDetailsToExport TDE on (vwPTD.TaskDetailId = TDE.EntityId)
                             FOR JSON PATH) picks
                             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)';

  /* Execute SQL query */
  exec sp_executesql @vSQLQuery,
                     N'@ResultParam varchar(max) output',
                     @ResultParam = @MessageData output;

  /* Identifiers being built for 6River are not of valid JSON format, so 'FOR JSON PATH' will
     add some escape characters and we need to relpace those so that will be accepted by 6River

   Raw JSON: "identifiers":"[{\"label\":\"UPC\",\"allowedValues\":[\"889610243836\"]},{\"label\":\"COO\",\"allowedValues\":[\"AF\",\"BG\",\"CN\",\"CH\",\"EG\",\"ET\",\"HT\",\"IN\",\"ID\",\"MG\",\"LK\",\"US\",\"USA\",\"VN\"]}]"}
   Converted JSON: "identifiers":[{"label":"UPC","allowedValues":["847153005403"]},{"label":"COO","allowedValues":["AF","BG","CN","CH","EG","ET","HT","IN","ID","MG","LK","US","USA","VN"]}]}

   Please note that we cannot just replace '\"' with '"' as there are chances that SKU desc may contain '"' which will be designated as inches so
   replace '\",\"' with '","', '"[{\"' with '"[{"'and so on */
  /* Format JSON and remove unnecessary */
  select @MessageData = replace(replace(replace(replace(replace(replace(replace(replace(replace(@MessageData, '"[{\', '[{'), '\":\"', '":"'), '\",\"', '","'), '\":[\"', '":["'), '\"]}]"', '"]}]'), '\"]},{\"', '"]},{"'), '"{\"', '{"'), '\"]}"','"]}'), '\"}"', '"}');

  /* Update Export Status on the task details */
  update TD
  set ExportStatus = 'Exported'
  from TaskDetails TD
    join #TaskDetailsToExport TDE on (TD.TaskDetailId = TDE.EntityId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  if (@vTranCount = 0) commit transaction;
end try
begin catch
  if (@vTranCount = 0) rollback transaction

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_6River_Outbound_PickWave_GetMsgData */

Go
