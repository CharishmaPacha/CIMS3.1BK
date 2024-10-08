/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/20  TD      pr_Allocation_CreatePickTasks, pr_PickBatch_IsValidToAddTaskDetail,
                      pr_Allocation_GetTaskStatistics: Changes to consider num picks while creating tasks (S2G-456)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_IsValidToAddTaskDetail') is not null
  drop Procedure pr_PickBatch_IsValidToAddTaskDetail;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_IsValidToAddTaskDetail: This procedure will return flag like Y - Yes
       N- No.
       This Procedure will take the LPNWeight and Volume to validate add detail to
       the existign task or create new one based on the control variable.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_IsValidToAddTaskDetail
  (@PickBatchId   TRecordId,
   @PickWeight    TWeight,
   @PickVolume    TVolume,
   @PickCases     TInnerPacks,
   @PickUnits     TQuantity,
   @CartonVolume  TInteger,
   @NumOrders     TInteger,
   @NumPicks      TInteger,
   @TaskSubType   TTypeCode,
   @Result        TFlag output)
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessageName,

          @vBatchType       TTypeCode,
          @vBusinessUnit    TBusinessUnit,
          @UserId           TUserId,
          @vMaxWeight       TWeight,
          @vMaxVolume       TVolume,
          @vMaxCases        TInnerPacks,
          @vMaxCartonVolume TInteger,
          @vControlCategory TCategory,
          @vControlCode     TCategory,
          @vMaxUnits        TQuantity,
          @vMaxOrders       TInteger,
          @vMaxPicks        TInteger;
begin /* pr_PickBatch_IsValidToAddTaskDetail */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @Result       = 'N';

  /* Get Warehouse and BatchType here */
  select @vBatchType    = BatchType,
         @vBusinessUnit = BusinessUnit
  from PickBatches
  where (RecordId = @PickBatchId);

  /* Get MaxWeight and MaxVolume for Controls here */
  select @vControlCategory = 'PickBatch_' + @vBatchType,
         @vControlCode     = 'MaxPicksPerTask_' + @TaskSubType;
  select @vMaxWeight       = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'MaxWeight', 500, @vBusinessUnit, @UserId),
         @vMaxVolume       = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'MaxVolume', 90,  @vBusinessUnit, @UserId) * 1728,  /* Control var is in Cu. ft. */
         @vMaxCases        = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'MaxCases',  20,  @vBusinessUnit, @UserId),
         @vMaxUnits        = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'MaxUnits',  200,  @vBusinessUnit, @UserId),
         @vMaxOrders       = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'MaxOrders',  30,  @vBusinessUnit, @UserId),
         /* We need to limit max cartons for a task depending upon carton type, if we know the volume of cart
              then we can easily identify how many cartons it can hold */
         @vMaxCartonVolume = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'MaxCartonVolume', 45000,  @vBusinessUnit, @UserId),
         @vMaxPicks        = dbo.fn_Controls_GetAsInteger(@vControlCategory, @vControlCode, 999,  @vBusinessUnit, @UserId);

  if (@PickWeight <= @vMaxWeight) and
     (@PickVolume <= @vMaxVolume) and
     (@PickCases <= @vMaxCases) and
     (@NumOrders <= @vMaxOrders) and
     (coalesce(@CartonVolume, 0) <= @vMaxCartonVolume) and
     (coalesce(@PickUnits, 0) <= @vMaxUnits) and
     (coalesce(@NumPicks, 0) <= @vMaxPicks)
    set @Result = 'Y' /* Yes */;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_PickBatch_IsValidToAddTaskDetail */

Go
