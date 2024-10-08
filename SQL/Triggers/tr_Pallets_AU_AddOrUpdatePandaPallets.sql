/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('tr_Pallets_AU_AddOrUpdatePandaPallets') is not null
  drop Trigger tr_Pallets_AU_AddOrUpdatePandaPallets;
Go
/*------------------------------------------------------------------------------
  After Update Trigger tr_Pallets_AU_AddOrUpdatePandaPallets to insert the pallet info into the PandaPallets table
     which needs to process in Panda
------------------------------------------------------------------------------*/
Create Trigger [tr_Pallets_AU_AddOrUpdatePandaPallets] on [Pallets] for Update
As
  declare @vPalletId       TRecordId,
          @vPallet         TPallet,
          @vOperation      TOperation,
          @vNewLocationId  TRecordId,
          @vPrevLocationId TRecordId,
          @vLocationZone   TZoneId,
          @vBusinessUnit   TBusinessUnit;
begin
  if (not update(LocationId))
    return;

  select @vPalletId      = INS.PalletId,
         @vPallet        = INS.Pallet,
         @vNewLocationId = INS.LocationId,
         @vLocationZone  = Loc.PutawayZone,
         @vBusinessUnit  = INS.BusinessUnit
  from Inserted INS
    join Locations Loc on (Loc.LocationId = INS.LocationId);

  /* Get the Pallet Prev Location */
  select @vPrevLocationId = DEL.LocationId
  from deleted DEL;

  /* TODO: As of now there is no zone setup with name Amazon. Need to setup zone or change the zone here */
  /* Insert the Pallet into PandaPallets to process in Panda */
  --if (@vLocationZone = 'APS') and (@vNewLocationId <> @vPrevLocationId)
  if (@vLocationZone = 'APS') and (not exists (select * from PandaPallets where Pallet = @vPallet))
    insert into PandaPallets (PalletId, Pallet, PandAStation, BusinessUnit)
      select @vPalletId, @vPallet, 'Amazon', @vBusinessUnit;
end /* tr_Pallets_AU_AddOrUpdatePandaPallets */

Go

alter table Pallets Disable trigger tr_Pallets_AU_AddOrUpdatePandaPallets;

Go

