/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/12  PHK     pr_LPNs_DePalletize: Changes to recount the shipments during Depalletization (BK-692)
  2020/07/11  TK      pr_LPNs_Action_PalletizeLPNs, pr_LPNs_Palletize & pr_LPNs_DePalletize:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_DePalletize') is not null
  drop Procedure pr_LPNs_DePalletize;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_DePalletize: Removes given set of LPNs from its pallet, recounts Pallets & Locations and logs AT
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_DePalletize
  (@Operation             TOperation = 'LPNDePalletized',
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,

          @vNumLPNsSelected       TCount,
          @vLPNsDePalletized      TCount,
          @vLPNsIgnored           TCount;

  declare @ttAuditTrailInfo       TAuditTrailInfo,
          @ttLocationsToRecalc    TRecountKeysTable,
          @ttPalletsToRecalc      TRecountKeysTable,
          @ttShipmentsToRecalc    TEntityKeysTable;

  declare @ttLPNsDePalletized  table (LPNId            TRecordId,
                                      LPN              TLPN,

                                      PalletId         TRecordId,
                                      Pallet           TPallet,
                                      LocationId       TRecordId,
                                      Location         TLocation,

                                      ShipmentId       TRecordId,

                                      ActivityType     TActivityType,
                                      Comment          TVarChar,

                                      RecordId         TRecordId identity(1,1));
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  select @vLPNsIgnored     = sum(case when L.PalletId is null then 1 else 0 end),
         @vNumLPNsSelected = count(*)
  from LPNs L
    join #LPNsToDePalletize LTDP on (L.LPNId = LTDP.LPNId);

  /* Show how many LPNs were ignored to user */
  if (@vLPNsIgnored > 0)
    insert into #ResultMessages (MessageType, MessageName, Value1, Value2)
      select 'I' /* Info */, 'LPNDePalletized_LPNsNotOnPallet', @vLPNsIgnored, @vNumLPNsSelected;

  /*---------------- De-Palletize LPNs ----------------*/
  update L
  set PalletId = null,
      Pallet   = null
  output inserted.LPNId, inserted.LPN, deleted.PalletId, deleted.Pallet, inserted.LocationId, inserted.Location,
         inserted.ShipmentId, 'AT_' + @Operation
  into @ttLPNsDePalletized (LPNId, LPN, PalletId, Pallet, LocationId, Location, ShipmentId,  ActivityType)
  from LPNs L
    join #LPNsToDePalletize LTDP on (L.LPNId = LTDP.LPNId)

  select @vLPNsDePalletized = @@rowcount;

  /*---------------- Recalc Pallets ----------------*/
  if exists (select * from @ttLPNsDePalletized)
    begin
      /* Get all the Pallets to Recount */
      insert into @ttPalletsToRecalc (EntityId, EntityKey) select PalletId, Pallet from @ttLPNsDePalletized;
      exec pr_Pallets_Recalculate @ttPalletsToRecalc, default, @BusinessUnit, @UserId;
    end

  /*---------------- Recalc Locations ----------------*/
  if exists (select * from @ttLPNsDePalletized where LocationId is not null)
    begin
      insert into @ttLocationsToRecalc (EntityId, EntityKey) select LocationId, Location from @ttLPNsDePalletized where LocationId is not null
      exec pr_Locations_Recalculate @ttLocationsToRecalc, '*' /* Recount */, @BusinessUnit;
    end

  /*---------------- Recalc Shipments ----------------*/
  if exists (select * from @ttLPNsDePalletized where ShipmentId is not null)
    begin
      insert into @ttShipmentsToRecalc (EntityId) select distinct ShipmentId from @ttLPNsDePalletized where ShipmentId is not null
      exec pr_Shipment_Recalculate @ttShipmentsToRecalc, '$CS' /* Recount */, @BusinessUnit, @UserId;
    end

  /*---------------- Log Audit Trail ----------------*/
  /* Build Audit Comment */
  update @ttLPNsDePalletized
  set Comment = dbo.fn_Messages_BuildDescription(ActivityType, 'LPN', LPN, 'Pallet', Pallet, null, null, null, null, null, null, null, null)
  from @ttLPNsDePalletized;

  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, UDF1, Comment)
    /* LPN*/
    select distinct 'LPN', LPNId, LPN, ActivityType, @BusinessUnit, @UserId, RecordId, Comment from @ttLPNsDePalletized
    union all
    /* Pallet */
    select distinct 'Pallet', PalletId, Pallet, ActivityType, @BusinessUnit, @UserId, RecordId, Comment from @ttLPNsDePalletized
    union all
    /* Location */
    select distinct 'Location', LocationId, Location, ActivityType, @BusinessUnit, @UserId, RecordId, Comment from @ttLPNsDePalletized where LocationId is not null

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response to display to user */
  exec pr_Messages_BuildActionResponse 'LPN', @Operation, @vLPNsDePalletized, @vNumLPNsSelected;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_DePalletize */

Go
