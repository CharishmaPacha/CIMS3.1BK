/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/30  RKC     pr_Picking_UnloadLPNsFromPallet: Clear the empty Totes from the cart , if they are not used (CID-881)
  2019/06/03  VS      pr_Picking_UnloadLPNsFromPallet: Intial Version (CID-486)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_UnloadLPNsFromPallet') is not null
  drop Procedure pr_Picking_UnloadLPNsFromPallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_UnloadLPNsFromPallet: To Unload the Incomplete and Complete Orders in Respective Zones
    from Totes on the Picked/Picking pallet.
    ex: Incomplete Orders will drop at Pause-Hold Zone and Complete Orders Will drop at Respective Wave Zone.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_UnloadLPNsFromPallet
  (@LPNsOnPallet   TEntityKeysTable READONLY,
   @LocationId     TRecordId,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vLPNId             TRecordId,
          @vPalletId          TRecordId,
          @vCartPos           TLPN;

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get the Complete and Incomplete Orders and Unload from Pallet */
  while exists(select * from @LPNsOnPallet where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId = RecordId,
                   @vLPNId    = EntityId,
                   @vCartPos  = EntityKey
      from @LPNsOnPallet
      where RecordId > @vRecordId
      order by RecordId

      /* Move LPNs to the Location */
      exec pr_LPNs_Move @vLPNId, null /* LPN */, null /* LPN Status */, @LocationId,
                        null /* Location */, @BusinessUnit, @UserId;

      /* Clear Alternate LPN on the picked LPN */
      update LPNs
      set @vPalletId   = coalesce(@vPalletId, PalletId),
          PalletId     = null,
          Pallet       = null,
          AlternateLPN = null
      where (LPNId = @vLPNId);

      /* Clear Alternate LPN on the cart position for reuse */
      update LPNs
      set AlternateLPN = null
      where (LPN = @vCartPos);
    end

  /* Remove empty totes from the Cart */
  update LPNs
  set PalletId = null,
      Pallet   = null
  where (PalletId = @vPalletId) and
        (LPNType  = 'TO') and
        (Quantity = 0);

  /* If all LPNs are unloaded from the Pallet, then clear the TaskId on Pallet
     It is ok to have empty Cart positions or empty Totes on the Pallet */
  if (not exists(select * from LPNs where PalletId = @vPalletId and
                                          ((LPNType not in ('A', 'TO')) or (Quantity > 0))))
    update Pallets
    set TaskId = null
    where (PalletId = @vPalletId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_UnloadLPNsFromPallet */

Go
