/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/07/09  AY      pr_PickBatch_Recalculate: Deferred Updates (S2G-1010)
  2015/12/08  TK      pr_PickBatch_Recalculate: Compute Status even if the batch status is 'New' (ACME-419)
  2015/01/02  PKS     Added pr_PickBatch_Recalculate
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_Recalculate') is not null
  drop Procedure pr_PickBatch_Recalculate;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_Recalculate:

  Flags : C - Update Counts, S - set Status

  Note that Recount calls SetStatus anyway.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_Recalculate
  (@PickBatchesToUpdate   TEntityKeysTable readonly,
   @Flags                 TFlags = 'S',
   @UserId                TUserId,
   @BusinessUnit          TBusinessUnit = null)
as
  declare @ReturnCode   TInteger,
          @MessageName  TMessageName,
          @Message      TDescription,
          @vRecordId    TRecordId,

          @vPickBatchNo TPickBatchNo;

  declare @ttRecountKeysTable    TRecountKeysTable;

begin
  SET NOCOUNT ON;

  /* defer re-count for later */
  if (charindex('$', @Flags) > 0)
    begin
      select @Flags = replace (@Flags, '$', ''); -- strip out the $

      /* Input to this procedure is EntityKeysTable but caller is expecting RecountKeysTable, so copy the data */
      insert into @ttRecountKeysTable (EntityId, EntityKey) select EntityId, EntityKey from @PickBatchesToUpdate;

      /* invoke RequestRecalcCounts to defer Wave count updates */
      exec pr_Entities_RequestRecalcCounts 'Wave', @RecalcOption = @Flags, @ProcId = @@ProcId,
                                           @BusinessUnit = @BusinessUnit, @RecountKeysTable = @ttRecountKeysTable;

      return (0);
    end

  /* Initialize */
  select @vRecordId = 0;

  while (exists (select * from @PickBatchesToUpdate where RecordId > @vRecordId))
    begin
      select top 1 @vPickBatchNo = EntityKey,
                   @vRecordId    = RecordId
      from @PickBatchesToUpdate
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Call orders recount, PreProcess and SetStatus based on the flag. */
      if (charindex('C' /* Count */, @Flags) <> 0)
        exec pr_PickBatch_UpdateCounts @vPickBatchNo;

      if (charindex('S' /* Set Status */, @Flags) <> 0)
        exec pr_PickBatch_SetStatus @vPickBatchNo, '*' /* Status: Calculate */, @UserId, default /* PickBatchId */;
    end
end /* pr_PickBatch_Recalculate */

Go
