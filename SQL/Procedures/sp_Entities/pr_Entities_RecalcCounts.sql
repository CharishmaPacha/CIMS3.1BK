/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/09  VS      pr_Entities_RecalcCounts: Ignore the records which BussinessUnit is null (FBV3-1321)
  2021/12/02  TK      pr_Entities_RecalcCounts: Changes to recount only entities with status 'N' (FBV3-551)
  2021/08/25  RKC     pr_Entities_RecalcCounts: Made changes to recounts the task count & status (OB2-2020)
  2021/08/18  AY      pr_Entities_RecalcCounts/pr_Entities_ExecuteProcess: Added StartTime to track performance (HA-3098)
  2021/05/04  AY      pr_Entities_RecalcCounts: Handle invalid requests (HA GoLive)
  2021/04/03  AY      pr_Entities_RequestRecalcCounts, pr_Entities_RecalcCounts: Revised to process
  2021/03/17  MS      pr_Entities_RecalcCounts: Changes to recount Shipment&BoL (HA-1935)
  2020/06/30  SK      pr_Entities_RecalcCounts: Modified to include Receivers Count (HA-392)
  2020/04/03  MS      pr_Entities_RecalcCounts: Changes to recalculate pallets (JL-65)
  2020/02/27  MS      pr_Entities_RecalcCounts: Bug fix to preprocess the LPNs (JL-129)
  2019/02/05  OK      pr_Entities_RecalcCounts: Enhanced to support LPNs, Load entities (HPI-2363)
  2018/03/17  TK      pr_Entities_RecalcCounts: Changes to confirm picks for given wave (S2G-394)
              TK      pr_Entities_RecalcCounts: Added step to compute Wave Dependencies (S2G-253)
  2017/08/28  TK      pr_Entities_RecalcCounts: Changes to avoid processing same entity multiple times
  2017/06/24  TK      pr_Entities_RecalcCounts: Initial Revision (CIMS-1467)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Entities_RecalcCounts') is not null
  drop Procedure pr_Entities_RecalcCounts ;
Go
/*------------------------------------------------------------------------------
  Proc pr_Entities_RecalcCounts: This procedure is run from a job and will
    recalculate the count or update status of the entities that are not yet
    processed.
------------------------------------------------------------------------------*/
Create Procedure pr_Entities_RecalcCounts
  (@BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vRecordId          TRecordId,
          @vEntityRecId       TRecordId,
          @vEntityType        TTypeCode,
          @vEntityId          TRecordId,
          @vEntityKey         TEntityKey,
          @vEntityStatus      TStatus,
          @vRecalcOption      TFlags,
          @vBusinessUnit      TBusinessUnit,
          @vStartTime         TDateTime,
          @vSource            TName;

  declare @ttTaskPicksInfo    TTaskDetailsInfoTable;

  declare @ttEntitiesToRecalc table (EntityRecId    TRecordId,
                                     EntityType     TTypeCode,
                                     EntityId       TRecordId,
                                     EntityKey      TEntityKey,
                                     EntityStatus   TStatus,
                                     RecalcOption   TFlags,
                                     BusinessUnit   TBusinessUnit,

                                     IsProcessed    TFlag     default 'N',

                                     RecordId       TRecordId identity(1,1)
                                     primary key(RecordId),
                                     unique (IsProcessed, RecordId),
                                     unique (EntityId, EntityKey, RecordId));
begin
begin try
  SET NOCOUNT ON;

  /* Ignore the records which BussinessUnit is null */
  if exists (select RecordId from RecalcCounts where Status = 'N' and BusinessUnit is null)
    update RecalcCounts
    set Status        = 'Ignore',
        ProcessedTime = current_timestamp
    where (Status     = 'N'/* Not Yet Processed */) and
          (BusinessUnit is null);

  /* process all entities from #EntitiesToRecalc which are not to be deferred */
  if (object_id('tempdb..#EntitiesToRecalc') is not null)
    begin
      select @vSource = '#EntitiesToRecalc';

      insert into @ttEntitiesToRecalc(EntityRecId, EntityType, EntityId, EntityKey, EntityStatus, RecalcOption, BusinessUnit)
        select RecordId, EntityType, EntityId, EntityKey, EntityStatus, RecalcOption, coalesce(BusinessUnit, @BusinessUnit)
        from #EntitiesToRecalc
        where (RecalcOption not like '$%') and
              (Status = 'N' /* Not Yet Processed */)
        order by RecordId;
    end
  else
    insert into @ttEntitiesToRecalc(EntityRecId, EntityType, EntityId, EntityKey, EntityStatus, RecalcOption, BusinessUnit)
      select RecordId, EntityType, EntityId, EntityKey, EntityStatus, RecalcOption, BusinessUnit
      from RecalcCounts
      where (Status       = 'N' /* Not Yet Processed */) and
            ((EntityId is not null) or (EntityKey is not null)) and -- atleast one must be present
            (BusinessUnit = @BusinessUnit)
      order by RecordId;

  select @vRecordId = 0,
         @vSource   = coalesce(@vSource, 'RecalcCounts');

  while exists(select * from @ttEntitiesToRecalc where (RecordId > @vRecordId) and
                                                       (IsProcessed = 'N'/* No */))
    begin
      /* Get the next recordid that needs to be processed */
      select top 1 @vRecordId     = RecordId,
                   @vEntityRecId  = EntityRecId,
                   @vEntityType   = EntityType,
                   @vEntityId     = EntityId,
                   @vEntityKey    = EntityKey,
                   @vEntityStatus = nullif(EntityStatus, ''),
                   @vRecalcOption = RecalcOption,
                   @vBusinessUnit = BusinessUnit,
                   @vStartTime    = current_timestamp
      from @ttEntitiesToRecalc
      where (RecordId > @vRecordId) and (IsProcessed = 'N' /* No */)
      order by RecordId;

      begin transaction;

      if (@vEntityType = 'Wave')
        begin
          /* Confirm Picks for given wave */
          if (charindex('CP'/* Confirm Picks */, @vRecalcOption) <> 0)
            begin
              /* Initialize */
              delete from @ttTaskPicksInfo;

              /* Get all the picks to be confirmed */
              insert into @ttTaskPicksInfo(PickBatchNo, TaskDetailId, OrderId, OrderDetailId, SKUId, FromLPNId, FromLPNDetailId,
                                            FromLocationId, TempLabelId, TempLabelDtlId, QtyPicked)
                select PickBatchNo, TaskDetailId, OrderId, OrderDetailId, SKUId, LPNId, LPNDetailId,
                       LocationId, TempLabelId, TempLabelDetailId, Quantity
                from TaskDetails
                where (WaveId = @vEntityId) and
                      (Status not in ('C', 'X'/* Completed, Canceled */));

              /* Invoke procedure to confirm picks */
              exec pr_Picking_ConfirmPicks @ttTaskPicksInfo, 'ConfirmTaskPick', @BusinessUnit, @UserId, default/* Debug */;
            end

          /* Update counts on the Wave */
          if (charindex('C' /* Count */, @vRecalcOption) <> 0)
            exec pr_PickBatch_UpdateCounts @vEntityKey;

          /* Compute Status of the Wave */
          if (charindex('S' /* Set Status */, @vRecalcOption) <> 0)
            exec pr_PickBatch_SetStatus @vEntityKey, @vEntityStatus, @UserId;

          /* Compute Dependencies on the Wave */
          if (charindex('D' /* DependencyFlags */, @vRecalcOption) <> 0)
            exec pr_Wave_UpdateDependencies default, @vEntityId, 'N'/* No - Don't compute TDs */;
        end
      else
      if (@vEntityType = 'Order')
        begin
          /* Update counts on the Order */
          if (charindex('C' /* Count */, @vRecalcOption) <> 0)
            exec pr_OrderHeaders_Recount @vEntityId;

          /* Compute Status of the Order */
          if (charindex('S' /* Set Status */, @vRecalcOption) <> 0)
            exec pr_OrderHeaders_SetStatus @vEntityId, @vEntityStatus, @UserId;
        end
      else
      if (@vEntityType = 'Location')
        begin
          /* Update counts on the Location */
          if (charindex('C' /* Count */, @vRecalcOption) <> 0)
            exec pr_Locations_UpdateCount @vEntityId, @vEntityKey, '*'/* Update Option */;

          /* Compute Status of the Location */
          if (charindex('S' /* Set Status */, @vRecalcOption) <> 0)
            exec pr_Locations_SetStatus @vEntityId, @vEntityStatus;
        end
      else
      if (@vEntityType = 'LPN')
        begin
          /* Preprocess the LPN */
          if (charindex('P' /* PreProcess */, @vRecalcOption) <> 0)
            exec pr_LPNs_PreProcess @vEntityId, default, @BusinessUnit;

          /* Update counts on the LPN */
          if (charindex('C' /* Count */, @vRecalcOption) <> 0)
            exec pr_LPNs_Recount @vEntityId;

          /* Compute Status of the LPN */
          if (charindex('S' /* Set Status */, @vRecalcOption) <> 0)
            exec pr_LPNs_SetStatus @vEntityId, @vEntityStatus;
        end
      else
      if (@vEntityType = 'Load')
        begin
          /* Update counts on the Load */
          if (charindex('C' /* Count */, @vRecalcOption) <> 0)
            exec pr_Load_Recount @vEntityId;

          /* Compute Status of the Load */
          if (charindex('S' /* Set Status */, @vRecalcOption) <> 0)
            exec pr_Load_SetStatus @vEntityId, @vEntityStatus;
        end
      else
      if (@vEntityType = 'Shipment')
        begin
          /* Calling Shipment update count procedure to update each Shipment */
          if (charindex('C' /* Count */, @vRecalcOption) <> 0)
            exec pr_Shipment_Recount @vEntityId;

          if (charindex('S' /* Count */, @vRecalcOption) <> 0)
            exec pr_Shipment_SetStatus @vEntityId, default /* New status */;
        end
      else
      if (@vEntityType = 'BoL')
        begin
          /* Calling BoL update count procedure to update each BoL */
          if (charindex('C' /* Count */, @vRecalcOption) <> 0)
            exec pr_BoL_Recount @vEntityId;

          if (charindex('S' /* Count */, @vRecalcOption) <> 0)
            exec pr_BoL_Recount @vEntityId, default /* New status */;
        end
      else
      if (@vEntityType in ('Receipt', 'ReceiptHdr'))
        begin
          /* Update counts on the Receipt */
          if (charindex('C' /* Count */, @vRecalcOption) <> 0)
            exec pr_ReceiptHeaders_Recount @vEntityId;

          /* Compute Status of the Receipt */
          if (charindex('S' /* Set Status */, @vRecalcOption) <> 0)
            exec pr_ReceiptHeaders_SetStatus @vEntityId, @vEntityStatus;
        end
      else
      if (@vEntityType = 'Receiver')
        begin
          /* Process counts on Receiver */
          if (charindex('C' /* Re(C)ount */, @vRecalcOption) <> 0)
            exec pr_Receivers_Recount @vEntityId, @vBusinessUnit, @UserId;
        end
      else
      if (@vEntityType = 'Pallet')
        begin
          /* Calling pallet update count procedure to update each pallet */
          if (charindex('C' /* Count */, @vRecalcOption) <> 0)
            exec pr_Pallets_UpdateCount @vEntityId, null /* Pallet */, '*' /* Update Option */,
                                        @UserId = @UserId;

          if (charindex('S' /* Count */, @vRecalcOption) <> 0)
            exec pr_Pallets_SetStatus @vEntityId, default /* New status */, @UserId;
        end
      else
      if (@vEntityType = 'Task')
        begin
          /* Call Recount and SetStatus based on the RecalcOption */
          if (charindex('C' /* Re(C)ount */, @vRecalcOption) <> 0)
            exec pr_Tasks_Recount @vEntityId;

          if (charindex('S' /* Set (S)tatus */, @vRecalcOption) <> 0)
            exec pr_Tasks_SetStatus @vEntityId, @UserId, null /* Status */, 'Y' /* recount */;
        end

      /* set IsProcessed flag to 'Y' on processed entity such that it won't be processed again */
      update @ttEntitiesToRecalc
      set IsProcessed = 'Y' /* Yes */
      where (EntityId     = @vEntityId    ) and
            (EntityType   = @vEntityType  ) and
            (RecalcOption = @vRecalcOption) and
            (BusinessUnit = @vBusinessUnit);

      /* Update Status of the entity after computing */
      if (@vSource = 'RecalcCounts')
        update RecalcCounts
        set Status        = 'P' /* Processed */,
            StartTime     = @vStartTime,
            ProcessedTime = current_timestamp
        where (EntityId     = @vEntityId                ) and
              (EntityType   = @vEntityType              ) and
              (RecalcOption = @vRecalcOption            ) and
              (Status       = 'N'/* Not Yet Processed */) and
              (BusinessUnit = @vBusinessUnit            );
      else
      if (@vSource = '#EntitiesToRecalc')
        update #EntitiesToRecalc
        set Status        = 'P' /* Processed */,
            ProcessedTime = current_timestamp
        where (EntityId     = @vEntityId                ) and
              (EntityType   = @vEntityType              ) and
              (RecalcOption = @vRecalcOption            ) and
              (Status       = 'N'/* Not Yet Processed */) and
              (BusinessUnit = @vBusinessUnit            );

      commit transaction;
    end

end try
begin catch
  /* Handling transactions in case if it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  /* Update Status of the entity after computing */
  if (@vSource = 'RecalcCounts')
    update RecalcCounts
    set Status        = 'E' /* Error */,
        StartTime     = @vStartTime,
        ProcessedTime = current_timestamp
    where (EntityId     = @vEntityId                ) and
          (coalesce(EntityKey, '') = coalesce(@vEntityKey, '')) and  -- This may not be present always
          (EntityType   = @vEntityType              ) and
          (RecalcOption = @vRecalcOption            ) and
          (Status       = 'N'/* Not Yet Processed */) and
          (BusinessUnit = @vBusinessUnit            );
  else
  /* if there is an error processing, then let us defer the remaining ones for later */
  if (@vSource = '#EntitiesToRecalc')
    exec pr_Entities_RequestRecalcCounts null, @BusinessUnit = @BusinessUnit;

end catch;

end /* pr_Entities_RecalcCounts */

Go
