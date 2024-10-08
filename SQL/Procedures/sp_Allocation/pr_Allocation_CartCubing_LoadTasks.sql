/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_CartCubing_LoadTasks') is not null
  drop Procedure pr_Allocation_CartCubing_LoadTasks;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_CartCubing_LoadTasks: This procedure loads cart shelf spaces into a
    hash table for all the tasks of a given wave or if task is given it will load cart shelf spaces
    only for that particular task
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_CartCubing_LoadTasks
  (@WaveId             TRecordId,
   @TaskId             TRecordId,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,

          @vRecordId            TRecordId,
          @vControlCategory     TCategory,

          @vWaveId              TRecordId,
          @vWaveNo              TWaveNo,
          @vWaveType            TTypeCode,

          @vTaskId              TRecordId,
          @vCartType            TLookUpCode,
          @vNumShelves          TInteger,
          @vShelfWidth          TWidth,
          @vShelfHeight         THeight;

  declare @ttExistingTasks      TEntityKeysTable;
begin /* pr_Allocation_CartCubing_LoadTasks */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get Wave Info */
  select @vWaveId   = RecordId,
         @vWaveNo   = BatchNo,
         @vWaveType = BatchType
  from Waves
  where (RecordId = @WaveId);

  /* Get all the tasks for which Labels are not yet printed */
  if (@WaveId is not null)
    insert into @ttExistingTasks(EntityId, EntityKey)
      select TaskId, CartType
      from Tasks
      where (WaveId = @vWaveId) and
            (Status in ('O', 'N'/* OnHold, Ready To Start */)) and
            (LabelsPrinted = 'N'/* No */);
  else
  if (@TaskId is not null)
    insert into @ttExistingTasks(EntityId, EntityKey)
      select TaskId, CartType
      from Tasks
      where (TaskId = @TaskId) and
            (Status in ('O', 'N'/* OnHold, Ready To Start */)) and
            (LabelsPrinted = 'N'/* No */);

  /* Loop through each task and load cart shelves info */
  while exists (select * from @ttExistingTasks where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId        = RecordId,
                   @vTaskId          = EntityId,
                   @vCartType        = EntityKey,
                   @vControlCategory = 'CartDims_' + EntityKey
      from @ttExistingTasks
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Get Controls */
      select @vNumShelves  = dbo.fn_Controls_GetAsString (@vControlCategory, 'NumShelves', '6', @BusinessUnit, null /* UserId */),
             @vShelfWidth  = dbo.fn_Controls_GetAsString (@vControlCategory, 'ShelfWidth', '50', @BusinessUnit, null /* UserId */),
             @vShelfHeight = dbo.fn_Controls_GetAsString (@vControlCategory, 'ShelfHeight', '50', @BusinessUnit, null /* UserId */);

      insert into #CartShelves(TaskId, CartType, Shelf, ShelfWidth, ShelfHeight, SortOrder)
        select @vTaskId, @vCartType, Alphabet, @vShelfWidth, @vShelfHeight, Alphabet
        from dbo.fn_GenerateAlphabetSequence(@vNumShelves);

      /* If Task has no details yet, then continue to next task */
      if not (exists(select * from TaskDetails where TaskId = @vTaskId)) continue;

      /* Update used widths on the shelves */
      ;with TempLabels(TaskId, TempLabelId, TDCategory1, Shelf, CartonType, CartonWidth) as
      (
        select distinct TD.TaskId, TD.TempLabelId, TD.TDCategory1,
                        left(TD.PickPosition, 1), CT.CartonType, CT.OuterWidth
        from TaskDetails TD
          join LPNs L on (TD.TemplabelId = L.LPNId)
          join CartonTypes CT on (L.CartonType = CT.CartonType)
        where (TD.TaskId = @vTaskId) and
              (TD.Status not in ('C', 'X'/* Completed/Canceled */))
      ),
      ShelveSpaces(TaskId, TDCategory1, Shelf, UsedWidth) as
      (
        select TaskId, TDCategory1, Shelf, sum(CartonWidth)
        from TempLabels
        group by TaskId, TDCategory1, Shelf
      )
      update ttCS
      set ttCS.UsedWidth   = case when (ttCS.Shelf  = ttSS.Shelf) then ttSS.UsedWidth else ttCS.UsedWidth end,
          ttCS.TDCategory1 = ttSS.TDCategory1
      from #CartShelves ttCS
        join ShelveSpaces ttSS on (ttCS.TaskId = ttSS.TaskId);
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_CartCubing_LoadTasks */

Go
