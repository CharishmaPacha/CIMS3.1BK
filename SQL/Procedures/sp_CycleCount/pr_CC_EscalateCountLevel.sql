/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/13  SK      pr_CC_EscalateCountLevel: Updated AllowCycleCount_L2 to CycleCount.Pri.AllowCycleCount_L2 (CIMSV3-788)
                      pr_CC_EscalateCountLevel: New procedure (GNC-1408)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CC_EscalateCountLevel') is not null
  drop Procedure pr_CC_EscalateCountLevel;
Go
/*------------------------------------------------------------------------------
  Proc pr_CC_EscalateCountLevel:
    This procedure evaluates and escalates the CC level based on the threshold values from Control vars.
    1. If User doesn't have permissions for Supervisor counts and trying to CyccleCount the location
       beyond the Unit & Value threshold values then we will cancel the current CC task and upgrade
       to Supervisor count i.e. Supervisor should CycleCount that location.
    2. If User has permissions for Supervisor counts we are allowing to CC beyond L1 threshold values.
       However we are not allowing user to CC location beyond L2 threshold values.
    3. We cannot allow CC locations beyond L2 threshold values. However user only able to adjust the Location
       instead of CC.

  output:
   If user does not exceeded thresholds: Status = Y
   If L1 user exceeds thresholds: Status = Y and message to inform user of escalation
   If L2 user exceeds thresholds: Exception raised
------------------------------------------------------------------------------*/
Create Procedure pr_CC_EscalateCountLevel
  (@CCSummary      TCCSummaryInfo readonly,
   @LocationId     TRecordId,
   @TaskId         TRecordId,
   @BatchNo        TPickBatchNo,
   @UserId         TUserId,
   @Businessunit   TBusinessUnit,
   @StatusFlag     TFlag    output,
   @Message        TMessage output)
as
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,

          @vLocationId               TRecordId,
          @vTaskId                   TRecordId,
          @vUnitVariance             TQuantity, --Better to have new data type TVariance
          @vValueVariance            TFloat,

          /* Controls */
          @vL1MaxUnitVariance        TControlValue,
          @vL1MaxValueVariance       TControlValue,
          @vL2MaxUnitVariance        TControlValue,
          @vL2MaxValueVariance       TControlValue,
          @vAllowSupervisorCount     TControlValue,

          @vCurrentTaskPriority      TPriority,
          @vCurrentTaskScheduledDate TDate,

          @vSupervisorTaskCreated    TRecordId;
begin
  /* get the required control values */
  select @vL1MaxUnitVariance    = dbo.fn_Controls_GetAsString('CycleCount', 'L1MaxUnitVariance',  '80',   @BusinessUnit, @UserId),
         @vL1MaxValueVariance   = dbo.fn_Controls_GetAsString('CycleCount', 'L1MaxValueVariance', '400',  @BusinessUnit, @UserId),
         @vL2MaxUnitVariance    = dbo.fn_Controls_GetAsString('CycleCount', 'L2MaxUnitVariance',  '1000', @BusinessUnit, @UserId),
         @vL2MaxValueVariance   = dbo.fn_Controls_GetAsString('CycleCount', 'L2MaxValueVariance', '5000', @BusinessUnit, @UserId),
         @vAllowSupervisorCount = case when dbo.fn_Permissions_IsAllowed(@UserId, 'CycleCount.Pri.AllowCycleCount_L2') = '1' then 'Y' else 'N' end;

  /* get the unit variance and Value variance from the cycle count */
  select @vUnitVariance  = sum(ABS(QtyChange)),
         @vValueVariance = sum(ABS(QtyChange) * S.UnitPrice)
  from @CCSummary CC
    join SKUs S on (S.SKU = CC.SKU) and (S.BusinessUnit = @Businessunit)

  /* If User doesn't have permissions for Supervisor counts and units & Value variance exceeds the L1 threshold values
    then cancel the current CC task and create the task for supervisor count */
  if ((@vAllowSupervisorCount = 'N') and ((@vUnitVariance > @vL1MaxUnitVariance) or (@vValueVariance > @vL1MaxValueVariance)))
    begin
      /* cancel the currest task detail and upgrade/create supervisor task */
      exec pr_CycleCount_UpgradeToSupervisorCount @TaskId, @LocationId, @UserId, @BusinessUnit, @vSupervisorTaskCreated output;

      /* Set the status flag to 'N' to stop the further process */
      select @StatusFlag = 'N',
             @Message    = 'CC_SupervisorTaskCreated';
    end
  else
  /* If User have permission for Supervisor counts and units & Value variance exceeds the L2 threshold values
     Do not allow cycle counting that location. User can only adjust location instead of Cycle Counting.*/
  if ((@vAllowSupervisorCount = 'Y') and ((@vUnitVariance > @vL2MaxUnitVariance) or (@vValueVariance > @vL2MaxValueVariance)))
    select @StatusFlag   = 'N',
           @vMessageName = 'CC_L2ThresholdValueExceeded'; /* raises exception below */
  else
    select @StatusFlag = 'Y',
           @Message    = null;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_CC_EscalateCountLevel */

Go
