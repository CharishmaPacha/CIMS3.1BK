/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/07/09  AY      pr_OrderHeaders_Recalculate: Deferred Updates (S2G-1010)
  2015/01/22  VM      pr_OrderHeaders_Recalculate: Recount too after set status
  2012/10/25  AY/YA   pr_OrderHeaders_Recalculate: Modified default value as we are not suppose to Preprocess by default.
  2012/10/04  AY      pr_OrderHeaders_Recalculate: Recalculate various counts on the Order
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_Recalculate') is not null
  drop Procedure pr_OrderHeaders_Recalculate;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_Recalculate:

  Flags : P - Preprocess C - Update Counts, S - set Status

  Note that Recount calls SetStatus anyway.
  If Flags suggests to defer the recalculate for later, then just request for
    a deferred recount and exit
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_Recalculate
  (@PickTicketsToUpdate   TEntityKeysTable readonly,
   @Flags                 TFlags = 'S',
   @UserId                TUserId,
   @BusinessUnit          TBusinessUnit = null)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription,
          @vRecordId   TRecordId,

          @vOrderId    TRecordId;

  declare @ttRecountKeysTable    TRecountKeysTable;

begin
  SET NOCOUNT ON;

  /* defer re-count for later */
  if (charindex('$', @Flags) > 0)
    begin
      select @Flags = replace (@Flags, '$', ''); -- strip out the $

      /* Input to this procedure is EntityKeysTable but caller is expecting RecountKeysTable, so copy the data */
      insert into @ttRecountKeysTable (EntityId, EntityKey) select EntityId, EntityKey from @PickTicketsToUpdate;

      /* invoke RequestRecalcCounts to defer Order count updates */
      exec pr_Entities_RequestRecalcCounts 'Order', @RecalcOption = @Flags, @ProcId = @@ProcId,
                                           @BusinessUnit = @BusinessUnit, @RecountKeysTable = @ttRecountKeysTable;

      return (0);
    end

  /* Initialize */
  select @vRecordId = 0;

  while (exists (select * from @PickTicketsToUpdate where RecordId > @vRecordId))
    begin
      select top 1 @vOrderId  = EntityId,
                   @vRecordId = RecordId
      from @PickTicketsToUpdate
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Call orders recount, PreProcess and SetStatus based on the flag. */
      if (charindex('C' /* Count */, @Flags) <> 0)
        exec pr_OrderHeaders_Recount @vOrderId;

      if (charindex('P' /* Pre-Process */, @Flags) <> 0)
        exec pr_OrderHeaders_Preprocess @vOrderId;

      if (charindex('S' /* Set Status */, @Flags) <> 0)
        begin
          exec pr_OrderHeaders_SetStatus @vOrderId, default /* Status: Calculate */, @UserId;
          exec pr_OrderHeaders_Recount @vOrderId;
        end
    end
end /* pr_OrderHeaders_Recalculate */

Go
