/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/12  TK      pr_LPNs_CreateLPNs: Changes to create Kit LPNs
                      pr_LPNs_CreateLPNs_TransferInventory: Code Refractoring
                      pr_LPNs_CreateLPNs_CreateKits, pr_LPNs_CreateLPNs_MaxKitsToCreate, pr_LPNs_Locate:
                        Initial Revision (HA-1238)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Locate') is not null
  drop Procedure pr_LPNs_Locate;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Locate: Locates the LPNs and associated pallets present in temp table #LPNsToLocate
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Locate
  (@LocationId       TRecordId,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,

          @vLocationId              TRecordId,
          @vLocation                TLocation;

  declare @ttPalletsToLocate        TRecountKeysTable;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  if (@LocationId is null) or
     object_id('tempdb..#LPNsToLocate') is null
    return;

  /* Get the Location info */
  select @vLocationId = LocationId,
         @vLocation   = Location
  from Locations
  where (LocationId = @LocationId);

  /* Update location info on LPNs */
  update L
  set LocationId = @vLocationId,
      Location   = @vLocation
  output deleted.PalletId into @ttPalletsToLocate (EntityId)
  from LPNs L
    join #LPNsToLocate TL on (L.LPNId = TL.LPNId);

  /* If pallet is generated the update location info on pallets */
  if exists (select * from @ttPalletsToLocate)
    update P
    set LocationId = @vLocationId
    from Pallets P
      join @ttPalletsToLocate ttP on (P.PalletId = ttP.EntityId);

  /* Update counts on the location */
  exec pr_Locations_UpdateCount @vLocationId, @vLocation, '*' /* UpdateOption */;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Locate */

Go
