/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/01/03  MS      pr_Wave_AutoGenerateWaves: Changes to insert xml rules into #hash table (CIMSV3-2537)
                      pr_Wave_ReleaseForPicking, pr_Wave_ReleaseForPickingValidation, pr_Wave_ReleaseForPickingValidation
                      pr_Wave_ReleaseForPicking and pr_Wave_ReleaseForPickingValidation: Replaced Status => Wavestatus (CIMSV3-1416)
              AY      pr_PickBatch_Modify, pr_Wave_ReleaseForPicking, pr_Wave_ReleaseForPickingValidation: Changed
                        to execute the actual proc in background for performance reasons (S2G-1056)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Wave_ReleaseForPickingValidation') is not null
  drop Procedure pr_Wave_ReleaseForPickingValidation;
Go
/*------------------------------------------------------------------------------
  Proc pr_Wave_ReleaseForPickingValidation:
    This procedure validates the given waves to make sure they can be released.
    Also, makes sure there is only one wave in queue for being released.
------------------------------------------------------------------------------*/
Create Procedure pr_Wave_ReleaseForPickingValidation
  (@WavesToRelease   TEntityKeysTable  ReadOnly,
   @xmlData          xml,              -- Future use, we should use this now to have BU, UserId and selected entities.
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @Message          TMessage  = null output)
as
  declare @vRecordId                TRecordId,
          @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TMessage,

          @vRuleRecordId            TRecordId,
          @vRuleSetId               TRecordId,
          @vRuleSetName             TName,
          @vRuleId                  TRecordId,
          @vXMLData                 TXML,
          @vOperation               TOperation,

          @vWaveId                  TRecordId,
          @vWaveNo                  TPickBatchNo,
          @vWaveType                TTypeCode,
          @vWaveStatus              TStatus,
          @vWCSStatus               TDescription,
          @vWCSDependency           TFlags,
          @vValidWaveTypesToRelease TControlValue,
          @vValidStatusesToRelease  TControlValue,

          @vErrorMessages           TMessage,
          @vErrorsCounts            TCount,

          @vConfirmWCSPicks         TControlValue;

  declare @ttTaskPicksInfo          TTaskDetailsInfoTable,
          @ttWavesToConfirm         TRecountKeysTable,
          @ttTasksToRelease         TEntityKeysTable,
          @ttRules                  TRules;

  declare @ttWavesToReleaseForPicking table (RecordId         TRecordId identity(1,1),
                                             WaveId           TRecordId,
                                             WaveNo           TPickBatchNo,
                                             WaveType         TTypeCode,
                                             Status           TStatus,
                                             WCSDependency    TFlags,
                                             WCSStatus        TDescription);
begin
begin try
  begin transaction
  SET NOCOUNT ON;

  select @vRecordId      = 0,
         @vReturnCode    = 0,
         @vMessageName   = null,
         @vErrorMessages = '',
         @vErrorsCounts  = 0;

  select @vValidWaveTypesToRelease = dbo.fn_Controls_GetAsString('WaveReleaseForPicking', 'ValidWaveTypes', 'AUTO,CF,ZC' /* No */, @BusinessUnit, @UserId),
         @vValidStatusesToRelease  = dbo.fn_Controls_GetAsString('WaveReleaseForPicking', 'ValidWaveStatuses', 'R' /* Ready To Pick */, @BusinessUnit, @UserId),
         @vConfirmWCSPicks         = dbo.fn_Controls_GetAsString('WaveReleaseForPicking', 'ConfirmWCSPicks', 'D' /* Defer */, @BusinessUnit, @UserId);

  /* Get the all waves with release flag */
  insert into @ttWavesToReleaseForPicking (WaveId, WaveNo, WaveType, Status, WCSDependency, WCSStatus)
    select PB.RecordId, BatchNo, BatchType, Status, WCSDependency, WCSStatus
    from PickBatches PB
      join @WavesToRelease WR on (WR.EntityKey = PB.BatchNo)
    where (BusinessUnit = @BusinessUnit);

  /* Restrict if user is trying to release more than one wave */
  if (@@rowcount > 1)
    begin
      select @vMessageName = 'Wave_RFP_CannotReleaseMultipleWaves';
      goto ErrorHandler;
    end

  /* Iterate thru each wave and release it */
  while (exists(select * from @ttWavesToReleaseForPicking where RecordId > @vRecordId))
    begin
      /* Get next wave to process */
      select top 1 @vWaveId        = WaveId,
                   @vRecordId      = RecordId,
                   @vWaveNo        = WaveNo,
                   @vWaveType      = WaveType,
                   @vWaveStatus    = Status,
                   @vWCSStatus     = WCSStatus,
                   @vWCSDependency = WCSDependency
      from @ttWavesToReleaseForPicking
      where (RecordId > @vRecordId)
      order by RecordId;

      if (charindex(@vWaveType, @vValidWaveTypesToRelease) = 0)
        select @vMessageName = 'Wave_RFP_NotValidTypeToRelease';
      else
      if (charindex(@vWaveStatus, @vValidStatusesToRelease) = 0)
        select @vMessageName = 'Wave_RFP_WaveStatusNotValid';
      else
      if (@vWCSDependency is null)
        select @vMessageName = 'Wave_RFP_NotRequired';
      else
      if (charindex('R' /* Replenish */, @vWCSDependency) > 0)
        select @vMessageName = 'Wave_RFP_WaitingOnReplenishment';
      else
      if (charindex('L' /* Label Generation */, @vWCSDependency) > 0)
        select @vMessageName = 'Wave_RFP_LabelGenerationIncomplete';
      else
      if (charindex('D' /* Shipping Docs Exports */, @vWCSDependency) > 0)
        select @vMessageName = 'Wave_RFP_ShippingDocsNotExported';
      else
      if exists(select * from Tasks where WaveId = @vWaveId and Status not in ('X', 'C') and DependencyFlags in ('R', 'S'))
        select @vMessageName = 'Wave_RFP_TasksNotReadyToConfirm';
      else
      if (@vWCSStatus in ('Exported to WSS', 'Released To WSS'))
        select @vMessageName = 'Wave_RFP_AlreadyReleasedToWSS';

      if (@vMessageName is not null)
        select @vErrorMessages += dbo.fn_Messages_Build(@vMessageName, @vWaveNo, null, null, null, null) + '<br/>',
               @vMessageName    = null,
               @vErrorsCounts   = @vErrorsCounts + 1;

      /* We are only showing first two invalid wave error messages */
      if (@vErrorsCounts > 1)
        break;
    end /* End of the while */

  if (@vErrorMessages <> '')
    begin
      select @Message      = 'None of the Waves are Released for picking: ' + @vErrorMessages;
      goto ErrorHandler;
    end

  /* Reset RecordId to use again */
  select @vRecordId = 0;

  /* Loop through all waves */
  while (exists(select * from @ttWavesToReleaseForPicking where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId = RecordId,
                   @vWaveId   = WaveId,
                   @vWaveNo   = WaveNo,
                   @vWaveType = WaveType
      from @ttWavesToReleaseForPicking
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Initialize */
      set @vRuleRecordId = 0;
      delete from @ttRules;

      /* Build xml to evaluate Rules */
      select @vXMLData = '<RootNode>' +
                           dbo.fn_XMLNode('WaveId',     @vWaveId) +
                           dbo.fn_XMLNode('WaveType',   @vWaveType) +
                         '</RootNode>'

      /* Find the RuleSet to apply for this wave using the params passed in */
      exec pr_RuleSets_Find 'Wave_ReleaseForPicking', @vXMLData, @vRuleSetId output, @vRuleSetName output;

      /* Get the rules into Temp table */
      insert into @ttRules(RuleId, RuleSetId, RuleSetName)
        exec pr_Rules_GetRules @vRuleSetName;

      /* Ignore the Wave if there is no RuleSet found */
      if (@vRuleSetName is null) or (@@rowcount = 0)
        continue;

      /* Loop through the rules and process each one in order */
      while (exists(select * from @ttRules where RecordId > @vRuleRecordId))
        begin
          select top 1 @vRuleRecordId   = RecordId,
                       @vRuleId         = RuleId,
                       @vRuleSetId      = RuleSetId,
                       @vOperation      = null
          from @ttRules
          where (RecordId > @vRuleRecordId)
          order by RecordId;

          /* Process the rule and see if the rule is applicable */
          exec pr_Rules_Process @vRuleSetId, @vRuleId, @vXMLData, @vOperation output;

          if (@vOperation = 'ReleaseToWSS')
            exec pr_Wave_ReleaseToWSS @vWaveId, @vOperation /* Opeartion */, @BusinessUnit, @UserId;

          if (@vOperation = 'AllocatePesudoPicks')
            exec pr_Allocation_AllocateFromDynamicPicklanes @vWaveId, @vOperation /* Operation */, @BusinessUnit, @UserId;

          if (@vOperation = 'ReleaseTasks')
            exec pr_Tasks_Release default, null /* TaskId */ , @vWaveNo, default /* Force Release */,
                                  @BusinessUnit, @UserId, @vMessage output;
        end
    end

  /* Note: If we do not send success message, calling procedure show message as None
           of the selected waves are released for picking */
  select @Message = dbo.fn_Messages_Build('Wave_RFP_Successful', null, null, null, null, null);

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch
end /* pr_Wave_ReleaseForPickingValidation */

Go
