/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/08  TK      pr_Wave_ReleaseForPicking: Changes to Rules_GetRules procedure (CID-833)
  2018/10/05  VM      pr_Wave_ReleaseForPicking: Commented transaction controls to handle within internal procedures (S2GCA-353)
              AY      pr_PickBatch_Modify, pr_Wave_ReleaseForPicking, pr_Wave_ReleaseForPickingValidation: Changed
                        to execute the actual proc in background for performance reasons (S2G-1056)
  2018/05/18  TK      pr_Wave_ReleaseForPicking: Bug Fix while evaluating dependency flags (S2G-853)
  2018/03/28  TK      pr_Wave_ReleaseForPicking & pr_Wave_UpdateDependencies:
                        Ignore cancelled tasks
                      pr_Wave_UpdateDependencies: Update WCS dependency if wave is dependent on Replenishments (S2G-499)
  2018/03/23  RV      pr_Wave_ReleaseForPicking: Made changes to show success message (S2G-431)
  2018/03/15  TK      pr_Wave_ReleaseForPicking: Update WCS status upon releasing the wave for picking (S2G-242)
  2018/03/14  TK      pr_Wave_ReleaseForPicking: Changes to release Tasks when a wave is released to WCS (S2G-409)
  2018/03/13  RV      pr_Wave_ReleaseForPicking: Bug fixed to show success message if all the waves are release successfully (S2G-400)
              TK      pr_Wave_ReleaseForPicking: Changes to confirm picks for the waves released to WCS (S2G-394)
  2018/03/07  RV      pr_Wave_ReleaseForPicking: Initial version (S2G-240)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Wave_ReleaseForPicking') is not null
  drop Procedure pr_Wave_ReleaseForPicking;
Go
/*------------------------------------------------------------------------------
  Proc pr_Wave_ReleaseForPicking:
    This procedure insert the wave sorter details to pick the inventory to the WSS if the all the validations
    are passed.
------------------------------------------------------------------------------*/
Create Procedure pr_Wave_ReleaseForPicking
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

          @vErrorMessages           TMessage,
          @vErrorsCounts            TCount;

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
  --begin transaction
  SET NOCOUNT ON;

  select @vRecordId      = 0,
         @vReturnCode    = 0,
         @vMessageName   = null,
         @vErrorMessages = '',
         @vErrorsCounts  = 0;

  /* Validate the waves */
  exec pr_Wave_ReleaseForPickingValidation @WavesToRelease, @xmlData, @BusinessUnit, @UserId, @vMessageName output;

  if (@vMessageName <> '')
    goto ErrorHandler;

  /* Get all the waves to be released */
  insert into @ttWavesToReleaseForPicking (WaveId, WaveNo, WaveType, Status, WCSDependency, WCSStatus)
    select PB.RecordId, BatchNo, BatchType, Status, WCSDependency, WCSStatus
    from PickBatches PB
      join @WavesToRelease WR on (WR.EntityKey = PB.BatchNo)
    where (BusinessUnit = @BusinessUnit);

  /* Loop through all waves and process one at a time */
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
      insert into @ttRules(RuleId, RuleSetId, RuleSetName, TransactionScope)
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

          /* Handle transactions for each operation to give better performance to the system */
          if (@vOperation = 'AllocatePesudoPicks')
            exec pr_Allocation_AllocateFromDynamicPicklanes @vWaveId, @vOperation /* Operation */, @BusinessUnit, @UserId;

          if (@vOperation = 'ReleaseTasks')
            begin
              begin transaction
              exec pr_Tasks_Release default, null /* TaskId */ , @vWaveNo, default /* Force Release */,
                                    @BusinessUnit, @UserId, @vMessage output;
              commit transaction
            end
        end
    end

  /* Note: If we do not send success message, calling procedure show message as None
           of the selected waves are released for picking */
  select @Message = dbo.fn_Messages_Build('Wave_RFP_Successful', null, null, null, null, null);

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  --commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch
end /* pr_Wave_ReleaseForPicking */

Go
