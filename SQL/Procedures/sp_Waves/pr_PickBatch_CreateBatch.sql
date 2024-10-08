/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/30  RT      pr_PickBatch_CreateBatch: Included Wave as per Init_WaveType (HA-321)
  2020/04/28  TK      pr_PickBatch_AddOrder, pr_PickBatch_CreateBatch & pr_PickBatch_UpdateCounts:
  2019/06/04  SK      pr_PickBatch_CreateBatch: addition of WaveStatus field for value insert
  2017/05/25  YJ      pr_PickBatch_CreateBatch: Added validation to get valid Batchtype and Status (HPI-1442)
  2017/03/27  YJ      pr_PickBatch_CreateBatch: To avoid exception if there is empty in PickBatchNo (HPI-1442)
  2015/11/04  RV      pr_PickBatch_CreateBatch: If input PickBatchNo already exist we will create with next Batch No (FB-482)
  2015/11/03  RV      pr_PickBatch_CreateBatch: If PickBatch No pass to this procedure then we will create pick batch with passed batch no (FB-482)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_CreateBatch') is not null
  drop Procedure pr_PickBatch_CreateBatch;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_CreateBatch
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_CreateBatch
  (@BatchType      TTypeCode,
   @CurrentRuleId  TRecordId,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   ------------------------------------
   @PickBatchNo    TPickBatchNo output,
   @PickBatchId    TRecordId    output)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,
          @vMessage        TDescription,

          @vWaveId         TRecordId,
          @vCreatedDate    TDateTime,
          @vWaveRuleGroup  TDescription,
          @vStatus         TStatus;
begin
  /* setting default status as N(New) for newly generated BatchNo */
  select @vStatus      = 'N'/* New */,
         @vCreatedDate = current_timestamp,
         @PickBatchNo  = nullif(@PickBatchNo, '');

  /* If input PickBatchNo already exist we will create with next Batch No */
  if (exists (select BatchNo from PickBatches
              where (BatchNo = @PickBatchNo)))
    select @PickBatchNo = null;

  /* To validate Batchtype and Status */
  if (@BatchType is null)
    select @vMessageName = 'WaveTypeIsRequired';
  else
  if (@Batchtype not in (select Typecode
                         from Entitytypes
                         where (Entity = 'Wave') and
                               (Status = 'A' /* Active */)))
    set @vMessageName = 'InvalidBatchType';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* get WaveRuleGroup */
  select @vWaveRuleGroup = WaveRuleGroup
  from PickBatchRules
  where (RuleId = @CurrentRuleId);

  /* If PickBatch No is already passed we will create batch with this PickBatch No else
     get the next Batch No */
  if (@PickBatchNo is null)
    exec pr_PickBatch_GetNextBatchNo @BatchType,
                                     @BusinessUnit,
                                     @PickBatchNo output;

  /* NumOrders, NumLines, NumSKUs, NumUnits fields are set Default to 0 while inserting */
  insert into PickBatches (BatchNo,
                           WaveNo,
                           WaveType,
                           BatchType,
                           WaveStatus,
                           Status,
                           RuleId,
                           WaveRuleGroup,
                           BusinessUnit,
                           CreatedDate,
                           CreatedBy)
                    values(@PickBatchNo,
                           @PickBatchNo,
                           @BatchType,
                           @BatchType,
                           @vStatus,
                           @vStatus,
                           @CurrentRuleId,
                           coalesce(@vWaveRuleGroup, cast(@CurrentRuleId as varchar), ''),
                           @BusinessUnit,
                           @vCreatedDate,
                           @UserId);

  /* Save id of the audit trail record just created */
  set @vWaveId = Scope_Identity();

  /* Update WaveId */
  update Waves set RecordId = @vWaveId where WaveId = @vWaveId;

  /* Call procedure here to populate batch attributes */
  exec pr_PickBatch_SetUpAttributes @vWaveId, @BusinessUnit, @UserId;

  /* Auditing */
  exec pr_AuditTrail_Insert 'PickBatchCreated', @UserId, @vCreatedDate, @WaveId = @vWaveId;

  /* Return PickBatchId as o/p */
  select @PickBatchId = @vWaveId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_PickBatch_CreateBatch */

Go
