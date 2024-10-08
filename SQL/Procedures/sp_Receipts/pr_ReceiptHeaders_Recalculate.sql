/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/07  MS      pr_Receipts_ReceiveInventory, pr_ReceiptHeaders_Recalculate: Changes to correct LPNsReceived count (HA-286)
  2020/02/18  AY      pr_ReceiptHeaders_Recalculate: New procedure (JL-58)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptHeaders_Recalculate') is not null
  drop Procedure pr_ReceiptHeaders_Recalculate;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptHeaders_Recalculate:

  Flags : P - Preprocess C - Update Counts, S - set Status

  Note that Recount calls SetStatus anyway.
  If Flags suggests to defer the recalculate for later, then just request for
    a deferred recount and exit
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptHeaders_Recalculate
  (@ReceiptsToUpdate   TEntityKeysTable readonly,
   @Flags              TFlags = 'S',
   @UserId             TUserId,
   @BusinessUnit       TBusinessUnit = null)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription,
          @vRecordId   TRecordId,

          @vReceiptId  TRecordId;

  declare @ttRecountKeysTable    TRecountKeysTable;

begin
  SET NOCOUNT ON;

  /* defer re-count for later */
  if (charindex('$', @Flags) > 0)
    begin
      select @Flags = replace (@Flags, '$', ''); -- strip out the $

      /* Input to this procedure is EntityKeysTable but caller is expecting RecountKeysTable, so copy the data */
      insert into @ttRecountKeysTable (EntityId, EntityKey) select EntityId, EntityKey from @ReceiptsToUpdate;

      /* invoke RequestRecalcCounts to defer Order count updates */
      exec pr_Entities_RequestRecalcCounts 'ReceiptHdr', @RecalcOption = @Flags, @ProcId = @@ProcId,
                                           @BusinessUnit = @BusinessUnit, @RecountKeysTable = @ttRecountKeysTable;

      return (0);
    end

  /* Initialize */
  select @vRecordId = 0;

  while (exists (select * from @ReceiptsToUpdate where RecordId > @vRecordId))
    begin
      select top 1 @vReceiptId  = EntityId,
                   @vRecordId = RecordId
      from @ReceiptsToUpdate
      where (RecordId > @vRecordId)
      order by RecordId;

      if (charindex('P' /* Pre-Process */, @Flags) <> 0)
        exec pr_ReceiptHeaders_Preprocess @vReceiptId;

      /* Call orders recount, PreProcess and SetStatus based on the flag. */
      if (charindex('C' /* Count */, @Flags) <> 0)
        exec pr_ReceiptHeaders_Recount @vReceiptId;

      if (charindex('S' /* Set Status */, @Flags) <> 0)
        exec pr_ReceiptHeaders_SetStatus @vReceiptId, default /* Status: Calculate */;
    end
end /* pr_ReceiptHeaders_Recalculate */

Go
