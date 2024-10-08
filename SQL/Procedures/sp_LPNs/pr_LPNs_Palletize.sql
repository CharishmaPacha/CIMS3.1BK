/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/20  PHK     pr_LPNs_Palletize: Made changes to consider the distinct palletId (HA-1901)
  2020/07/11  TK      pr_LPNs_Action_PalletizeLPNs, pr_LPNs_Palletize & pr_LPNs_DePalletize:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Palletize') is not null
  drop Procedure pr_LPNs_Palletize;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Palletize: Add given set of LPNs on to pallet, recounts Pallets & LPNs and logs AT
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Palletize
  (@Operation             TOperation = 'LPNPalletized',
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,

          @vNumPalletsToCreate    TCount,
          @vWarehouse             TWarehouse,
          @vLPNsLocationCount     TCount,
          @vLocationId            TRecordId,
          @vLocation              TLocation,
          @vLocStorageType        TTypeCode,

          @vFirstPalletId         TRecordId,
          @vFirstPallet           TPallet,
          @vLastPalletId          TRecordId,
          @vLastPallet            TPallet;

  declare @ttAuditTrailInfo       TAuditTrailInfo,
          @ttPalletsLocated       TEntityKeysTable,
          @ttLocationsToRecalc    TRecountKeysTable,
          @ttPalletsToRecalc      TRecountKeysTable;

  declare @ttLPNsPalletized  table (LPNId            TRecordId,
                                    LPN              TLPN,

                                    OldPalletId      TRecordId,
                                    OldPallet        TPallet,
                                    NewPalletId      TRecordId,
                                    NewPallet        TPallet,
                                    LocationId       TRecordId,
                                    Location         TLocation,

                                    ActivityType     TActivityType,
                                    Comment          TVarChar,

                                    RecordId         TRecordId identity(1,1));
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  select @vNumPalletsToCreate = max(PalletRecordId),
         @vWarehouse          = min(L.DestWarehouse)
  from #LPNsToPalletize LTP
    join LPNs L on (LTP.LPNId = L.LPNId);

  /* Return if LPNs per Pallet is zero */
  if (@vNumPalletsToCreate = 0) return;

  /*---------------- Generate Pallets ----------------*/
  /* Generate required number of inventory pallets */
  exec pr_Pallets_GeneratePalletLPNs 'I', @vNumPalletsToCreate, null /* PalletFormat */,
                                     0 /* LPNsPerPallet */, null /* LPN Type */, null /* LPN Format */,
                                     @vWarehouse, @BusinessUnit, @UserId,
                                     @FirstPalletId = @vFirstPalletId output, @FirstPallet = @vFirstPallet output,
                                     @LastPalletId = @vLastPalletId output, @LastPallet = @vLastPallet output;

  /* Capture pallets generated to palletize LPNs */
  insert into #Pallets (EntityId, EntityKey)
    select PalletId, Pallet
    from Pallets
    where (Pallet between @vFirstPallet and @vLastPallet) and
          (PalletType   = 'I' /* Inventory */) and
          (BusinessUnit = @BusinessUnit) and
          (CreatedBy    = @UserId);

  /*---------------- Palletize LPNs ----------------*/
  update L
  set PalletId = P.EntityId,
      Pallet   = P.EntityKey
  output inserted.LPNId, inserted.LPN, deleted.PalletId, deleted.Pallet, inserted.PalletId, inserted.Pallet, inserted.LocationId, inserted.Location,
         'AT_'+ @Operation + case when deleted.PalletId is not null then '_FromDiffPallet' else '' end /* ActivityType */
  into @ttLPNsPalletized (LPNId, LPN, OldPalletId, OldPallet, NewPalletId, NewPallet, LocationId, Location, ActivityType)
  from LPNs L
    join #LPNsToPalletize LTP on (L.LPNId = LTP.LPNId)
    join #Pallets         P   on (LTP.PalletRecordId = P.RecordId);

  /*---------------- Locate or De-Locate LPNs ----------------*/
  /* If all the LPNs on the Pallet are in same location and pallet can be stored in that location
     then update pallets with the LPN's location info */
  ;with PalletsToLocate as
  (
    select NewPalletId, min(LTP.LocationId) as LocationId
    from @ttLPNsPalletized LTP
      left outer join Locations LOC on (LTP.LocationId = LOC.LocationId) and
                                       (charindex('A', LOC.StorageType) > 0)
    group by NewPalletId
    having count(distinct coalesce(LTP.LocationId, '')) = 1
  )
  update P
  set LocationId = PTL.LocationId
  output inserted.PalletId into @ttPalletsLocated (EntityId)
  from Pallets P
    join PalletsToLocate PTL on (P.PalletId = PTL.NewPalletId);

  /* If the LPNs being palletized are from multiple locations or if LPNs are in LPNs storage locations then
     we cannot move generated pallets into LPN storage location so clear location info on the LPNs */
  update LPNs
  set LocationId = null,
      Location   = null
  from LPNs L
    join @ttLPNsPalletized LTP on (L.LPNId = LTP.LPNId)
    left outer join @ttPalletsLocated ttPL on (LTP.NewPalletId = ttPL.EntityId)
  where (L.LPNId is null);

  /*---------------- Recalc Pallets ----------------*/
  if exists (select * from @ttLPNsPalletized)
    begin
      /* Get all the Pallets to Recount */
      insert into @ttPalletsToRecalc (EntityId, EntityKey)
        select distinct OldPalletId, OldPallet from @ttLPNsPalletized where OldPalletId is not null
        union all
        select distinct NewPalletId, NewPallet from @ttLPNsPalletized;

      exec pr_Pallets_Recalculate @ttPalletsToRecalc, default, @BusinessUnit, @UserId;
    end

  /*---------------- Recalc Locations ----------------*/
  if exists (select * from @ttLPNsPalletized where LocationId is not null)
    begin
      insert into @ttLocationsToRecalc (EntityId, EntityKey) select LocationId, Location from @ttLPNsPalletized where LocationId is not null
      exec pr_Locations_Recalculate @ttLocationsToRecalc, '*' /* Recount */, @BusinessUnit;
    end

  /*---------------- Log Audit Trail ----------------*/
  /* Build Audit Comment */
  update @ttLPNsPalletized
  set Comment = dbo.fn_Messages_BuildDescription(ActivityType, 'LPN', LPN, 'OldPallet', OldPallet, 'NewPallet', NewPallet, null, null, null, null, null, null)
  from @ttLPNsPalletized;

  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, UDF1, Comment)
    /* LPN*/
    select distinct 'LPN', LPNId, LPN, ActivityType, @BusinessUnit, @UserId, RecordId, Comment
    from @ttLPNsPalletized
    union all
    /* New Pallet */
    select distinct 'Pallet', NewPalletId, NewPallet, ActivityType, @BusinessUnit, @UserId, RecordId, Comment
    from @ttLPNsPalletized
    union all
    /* Old Pallet */
    select distinct 'Pallet', OldPalletId, OldPallet, ActivityType, @BusinessUnit, @UserId, RecordId, Comment
    from @ttLPNsPalletized
    where OldPalletId is not null
    union all
    /* Location */
    select distinct 'Location', LocationId, Location, ActivityType, @BusinessUnit, @UserId, RecordId, Comment
    from @ttLPNsPalletized
    where LocationId is not null;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Palletize */

Go
