/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/13  VS      pr_Pallets_Recalculate: Passed EntityStatus Parameter (BK-910)
  2020/04/03  MS      pr_Pallets_Recalculate: Changes to defer pallet recalculate (JL-65)
  2017/05/22  AY      pr_Pallets_Recalculate: Enhance to use TRecountKeysTable (CIMS-1512)
  2012/10/01  AY/PKS  pr_Pallets_Recalculate: New proc to recalc multiple pallets.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_Recalculate') is not null
  drop Procedure pr_Pallets_Recalculate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_Recalculate:

  Flags : C - Update Counts, S - set Status
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_Recalculate
  (@PalletsToUpdate  TRecountKeysTable readonly,
   @Flags            TFlags = 'CS',
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode  TInteger,
          @vMessageName TMessageName,
          @vMessage     TDescription,

          @vPalletId    TRecordId;

  declare @ttRecountKeysTable TRecountKeysTable;
begin
  SET NOCOUNT ON;

  /* defer re-count for later */
  if (charindex('$', @Flags) > 0)
    begin
      /* Input to this procedure is EntityKeysTable but caller is expecting RecountKeysTable, so copy the data */
      insert into @ttRecountKeysTable (EntityId, EntityKey) select EntityId, EntityKey from @PalletsToUpdate;

      /* invoke RequestRecalcCounts to defer Order count updates */
      exec pr_Entities_RequestRecalcCounts 'Pallet', null /* EntityId */, null /* Entity key */,  @Flags, @@ProcId,
                                            null /* Operation */, @BusinessUnit, null /* EntityStatus */, @ttRecountKeysTable;

      return (0);
    end

  select @vPalletId = 0;

  while (exists(select * from @PalletsToUpdate where EntityId > @vPalletId))
    begin
      /*  Getting the next PalletId to process */
      select top 1 @vPalletId = EntityId
      from @PalletsToUpdate
      where (EntityId > @vPalletId)
      order by EntityId ;

      /* Calling pallet update count procedure to update each pallet */
      if (charindex('C' /* Count */, @Flags) <> 0)
        exec pr_Pallets_UpdateCount @vPalletId, null /* Pallet */, '*' /* Update Option */,
                                    @UserId = @UserId;

      if (charindex('S' /* Status */, @Flags) <> 0)
        exec pr_Pallets_SetStatus @vPalletId, default /* New status */, @Userid;
    end
end /* pr_Pallets_Recalculate */

Go
