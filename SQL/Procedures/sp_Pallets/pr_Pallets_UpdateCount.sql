/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/11  TK      pr_Pallets_UpdateCount: ShipmentId should be an integer value (HA-2255)
  2021/03/07  SK      pr_Pallets_UpdateCount: Update consideration for ShipToId updated (HA-2152)
  2021/03/02  AY      pr_Pallets_UpdateCount: Changes to use Condolidation address as Shipto when multiple Orders on Pallet (HA MockGoLive)
  2021/01/20  PHK     pr_Pallets_UpdateCount: Made changes to properly update the counts on the pallet (HA-1901)
  2020/10/15  MS      pr_Pallets_UpdateCount: Bug fix to update SKU info on Pallet (JL-258)
  2020/08/26  TK      pr_Pallets_UpdateCount: Do not clear load info when the pallet status is loaded (S2GCA-1248)
  2020/07/31  AY      pr_Pallets_UpdateCount: Set ShipToStore, CustPO (HA-1299)
  2020/07/09  RKC     pr_Pallets_UpdateCount: Made changes to update the SKU information on pallets table (HA-994)
  2020/03/13  AY      pr_Pallets_UpdateCount: Change to setup SKU, SKU1..5 (JL-125)
  2017/08/27  PK      pr_Pallets_UpdateCount: Performance fixes - to call pr_Pallets_SetLocation only when LocationId on a pallet is not null (HPI-Support).
  2017/08/25  AY      pr_Pallets_SetLocation: Performance fixes - to not process empty cart positions (HPI-Support)
                      pr_Pallets_UpdateCount: Performance fix (HPI-Support)
  2016/10/13  OK      pr_Pallets_UpdateCount: Restricted the updating Load and shipment on the carts (HPI-857)
  2016/08/05  AY      pr_Pallets_UpdateCount: Changed to use ShipToStore instead of OHUDF10 (HPI-393)
  2016/06/17  TK      pr_Pallets_UpdateCount: Changes made to update PickBatch details on the Pallet (NBD-606)
  2015/12/08  KL      pr_Pallets_UpdateCount: Ownership will have to update while Building Pallet option(FB-547)
              AY      pr_Pallets_UpdateCount, SetStatus: Update OrderId (FB-513)
  2015/09/28  TK      pr_Pallets_UpdateCount: Bug fix (ACME-354)
  2015/08/21  RV      pr_Pallets_UpdateCount: Restrict to clear location if any cartons avaialble on Pallet (not cart) (FB-319)
  2013/12/13  AY      pr_Pallets_UpdateCount: Change Pallet volume to be in Cu ft.
  2013/10/29  TD/AY   pr_Pallets_UpdateCount: updating ShipToId, Weight, Volume on Pallets.
  2013/10/19  PK      pr_Pallets_UpdateCount: Updating LoadId and ShipmentId on the Pallet.
                      pr_Pallets_SetStatus: Updating the status of the Pallet.
  2012/09/30  AY      pr_Pallets_UpdateCount: Performance improvements.
  2012/09/12  AY      pr_Pallets_UpdateCount: Introduced new option to recompute all counts on Pallet
  2012/06/01  AA      pr_Pallets_UpdateCount: Update SKUId on pallet
  2012/05/18  YA      Reflection of signature changes on pr_Pallets_SetStatus, Inculded UserId as i/p param on pr_Pallets_UpdateCount.
  2012/05/07  PK      pr_Pallets_UpdateCount: Set default value of @vPallet to null as this is not always required
  2012/03/29  PK      Added pr_Pallets_UpdateCount, pr_Pallets_SetStatus: Computing Empty Status.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_UpdateCount') is not null
  drop Procedure pr_Pallets_UpdateCount;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_UpdateCount:

  /* '=' - Exact Qty, '+' - Add Qty, '-' - Subtract Qty, '*' - Recompute */
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_UpdateCount
  (@PalletId     TRecordId,
   @Pallet       TPallet     = null,
   @UpdateOption TFlag       = '=',
   @NumLPNs      TCount      = null,
   @InnerPacks   TInnerPacks = null,
   @Quantity     TQuantity   = null,
   @UserId       TUserId     = null)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vMessage                TDescription,

          @vQuantity               TQuantity,
          @vPrevQuantity           TQuantity,
          @vPalletizedQty          TQuantity,
          @vCurrentMultiplier      TInteger,
          @vNewMultiplier          TInteger,
          @vPalletType             TTypeCode,
          @vPalletSKUId            TRecordId,

          @vSKUId                  TRecordId,
          @vSKUCount               TInteger,
          @vSKU                    TSKU,
          @vSKU1                   TSKU,
          @vSKU2                   TSKU,
          @vSKU3                   TSKU,
          @vSKU4                   TSKU,
          @vSKU5                   TSKU,

          @vLocationId             TRecordId,
          @vOwnershipCount         TInteger,
          @vOwnership              TOwnership,
          @vLoadId                 TLoadId,
          @vLoadCount              TInteger,
          @vConsolidatorAddressId  TShipToId,
          @vShipmentId             TShipmentId,
          @vShipmentCount          TInteger,
          @vNumLPNs                TCount,
          @vLPNInnerPacks          TInnerPacks,
          @vLPNQuantity            TQuantity,
          @vNumCartons             TQuantity,
          @vTotalVolume            TVolume,
          @vTotalWeight            TWeight,

          @vBusinessUnit           TBusinessUnit,
          @vOrderId                TRecordId,
          @vOrderCount             TCount,
          @vShipToId               TShipToId,
          @vShipToIdCount          TCount,
          @vShipToStoreCount       TCount,
          @vShipToStore            TShipToStore,
          @vCustPOCount            TCount,
          @vCustPO                 TCustPO,

          @vDistinctPBCount        TCount,
          @vPickBatchCount         TCount,
          @vPickBatchId            TRecordId,
          @vPickBatchNo            TPickBatchNo,

          @vxmlRulesData           TXML;

  declare @ttSKUAttributes table (SKU      TSKU,
                                  SKU1     TSKU,
                                  SKU2     TSKU,
                                  SKU3     TSKU,
                                  SKU4     TSKU,
                                  SKU5     TSKU);

begin
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vSKUCount      = null,
         @vLoadCount     = null,
         @vShipmentCount = null,
         @vNumCartons    = 0;

  if (@PalletId is null) and (@Pallet is not null)
    select @PalletId = PalletId
    from Pallets
    where (Pallet = @Pallet);

  /* Get LocationId from pallet */
  select @vLocationId   = LocationId,
         @vPrevQuantity = Quantity,
         @vPalletType   = PalletType,
         @vPalletSKUId  = SKUId
  from Pallets
  where (PalletId = @PalletId);

  /* If no pallet id is passed in, then return */
  if (@PalletId is null) return;

  if (@UpdateOption = '=' /* Exact */) or (@UpdateOption = '*' /* Recompute */)
    select @vCurrentMultiplier = '0',
           @vNewMultiplier     = '1';
  else
  if (@UpdateOption = '+' /* Add */)
    select @vCurrentMultiplier = '1',
           @vNewMultiplier     = '1';
  else
  if (@UpdateOption = '-' /* Subtract */)
    select @vCurrentMultiplier = '1',
           @vNewMultiplier     = '-1';

  /* Recompute SKU of Pallet if NumLPNs is not zero or if the UpdateOption is =,
     meaning that the values are being set and it would be safe to recompute.  */
  if (@NumLPNs <> 0) or (@UpdateOption = '=') or (@UpdateOption = '*')
    begin
      select @vSKUCount         = count(distinct L.SKUId),
             @vSKUId            = min(L.SKUId),
             @vOwnershipCount   = count(distinct L.Ownership),
             @vOwnership        = min(L.Ownership),
             @vLoadCount        = count(distinct L.LoadId),
             @vLoadId           = min(L.LoadId),
             @vOrderCount       = count(distinct L.OrderId),
             @vOrderId          = min(L.OrderId),
             @vDistinctPBCount  = count(distinct L.PickBatchId),
             @vPickBatchCount   = count(L.PickBatchId),
             @vPickBatchId      = min(L.PickBatchId),
             @vPickBatchNo      = min(L.PickBatchNo),
             @vShipmentCount    = count(distinct L.ShipmentId),
             @vShipmentId       = min(L.ShipmentId),
             @vShipToIdCount    = count(distinct OH.ShipToId),
             @vShipToId         = min(OH.ShipToId),
             @vShipToStoreCount = count(distinct OH.ShipToStore),
             @vShipToStore      = min(OH.ShipToStore),
             @vCustPOCount      = count(distinct OH.CustPO),
             @vCustPO           = min(OH.CustPO),
             @vNumLPNs          = count(*),
             @vLPNInnerPacks    = sum(L.InnerPacks),
             @vLPNQuantity      = sum(L.Quantity),
             @vNumCartons       = sum(case when L.LPNType <> 'A' /* Cart */ then 1 else 0 end),
             @vTotalVolume      = sum(coalesce(nullif(L.ActualVolume, 0), nullif(L.EstimatedVolume, 0), 0)),
             @vTotalWeight      = sum(coalesce(nullif(L.ActualWeight, 0), nullif(L.EstimatedWeight, 0), 0))
      from LPNs L left outer join OrderHeaders OH on OH.OrderId = L.OrderId
      where (L.PalletId = @PalletId);

      select @vOrderCount = coalesce(@vOrderCount, 0);

      /* Get the actual quantity on the Pallet */
      select @vLPNInnerPacks = sum(case when (LD.OnhandStatus in ('A', 'R')) then coalesce(LD.InnerPacks, 0) else 0 end),
             @vLPNQuantity   = sum(case when (LD.OnhandStatus in ('A', 'R')) then coalesce(LD.Quantity, 0) else 0 end),
             @vPalletizedQty = sum(LD.Quantity)
      from LPNs L left outer join LPNDetails LD on (LD.LPNId = L.LPNId)
      where (L.PalletId = @PalletId);
    end

  /* If update option is +, - or =, we need to reset SKU attribues on Pallet.
     If update option is *, then do so only if quantity changed */
  if  (@UpdateOption <> '*') or (@vPrevQuantity <> coalesce(@vLPNQuantity, 0)) or (@vPrevQuantity <> coalesce(@vPalletizedQty, 0) or (@vPalletSKUId <> @vSKUId))
    begin
      /* Get the consolidated SKU attributes to update on the LPN */
      insert into @ttSKUAttributes(SKU, SKU1, SKU2, SKU3, SKU4, SKU5)
        select * from fn_LPNs_GetConsolidatedSKUAttributes (null /* LPNId */, @PalletId);

      select @vSKU  = coalesce(SKU,  'Mixed'),
             @vSKU1 = coalesce(SKU1, 'Mixed'),
             @vSKU2 = coalesce(SKU2, 'Mixed'),
             @vSKU3 = coalesce(SKU3, 'Mixed'),
             @vSKU4 = coalesce(SKU4, 'Mixed'),
             @vSKU5 = coalesce(SKU5, 'Mixed')
      from @ttSKUAttributes;
    end

  /* Get Shipto from Loads */
  if (@vLoadId <> 0)
    select @vConsolidatorAddressId = ConsolidatorAddressId
    from Loads
    where (LoadId = @vLoadId);

  /* If recomputing all counts, then overwrite the passed in values with recomputed values */
  if (@UpdateOption = '*')
    select @NumLPNs    = @vNumLPNs,
           @InnerPacks = coalesce(@vLPNInnerPacks, 0),
           @Quantity   = coalesce(nullif(@vLPNQuantity, 0), nullif(@vPalletizedQty, 0), 0);

  /* Always use computed values if there is one */
  select @InnerPacks = coalesce(@InnerPacks, @vLPNInnerPacks, 0);

  /* 1. update Counts */
  update Pallets
  set NumLPNs        = coalesce((NumLPNs     * @vCurrentMultiplier) +
                                (@NumLPNs    * @vNewMultiplier), NumLPNs),
      InnerPacks     = coalesce((InnerPacks  * @vCurrentMultiplier) +
                                (@InnerPacks * @vNewMultiplier), InnerPacks),
      @vQuantity     =
      Quantity       = coalesce((Quantity    * @vCurrentMultiplier) +
                                (@Quantity   * @vNewMultiplier), Quantity),
      SKUId          = case when (@vSKUCount = 1)     then @vSKUId
                            when (@vSKUCount is null) then SKUId -- no change
                            else null
                       end,
      SKU            = case when @vQuantity = 0 then null
                            else coalesce(@vSKU, SKU)
                       end,
      SKU1           = case when @vQuantity = 0 then null
                            else coalesce(@vSKU1, SKU1)
                       end,
      SKU2           = case when @vQuantity = 0 then null
                            else coalesce(@vSKU2, SKU2)
                       end,
      SKU3           = case when @vQuantity = 0 then null
                            else coalesce(@vSKU3, SKU3)
                       end,
      SKU4           = case when @vQuantity = 0 then null
                            else coalesce(@vSKU4, SKU4)
                       end,
      SKU5           = case when @vQuantity = 0 then null
                            else coalesce(@vSKU5, SKU5)
                       end,
      OrderId        = case when (@vOrderCount = 1)     then @vOrderId
                            when (@vOrderCount is null) then OrderId
                            else null
                       end,
      /* PickBatch Info: if it is a Picking Cart then there could be some empty LPNs on which PickBatch info will be null so we would update PickBatch
         info on the Cart if distinct Count = 1

         If it is a pallet the all LPNs should have Pickbatch info on them and should be distinct else we won't update */
      PickBatchId    = case when (PalletType <> 'C'/* Cart */) and (@vPickBatchCount = @vNumLPNs) and (@vDistinctPBCount = 1) then @vPickBatchId
                            when (PalletType = 'C'/* Cart */) and (@vDistinctPBCount = 1) then @vPickBatchId
                            else null
                       end,
      PickBatchNo    = case when (PalletType <> 'C'/* Cart */) and (@vPickBatchCount = @vNumLPNs) and (@vDistinctPBCount = 1) then @vPickBatchNo
                            when (PalletType = 'C'/* Cart */) and (@vDistinctPBCount = 1) then @vPickBatchNo
                            else null
                       end,
      LoadId         = case when (PalletType = 'C'/* Cart */) then null
                            when (Status = 'L' /* Loaded */) then LoadId
                            when (@vLoadCount = 1) then @vLoadId
                            when (@vLoadCount is null) then LoadId
                            else null
                       end,
      ShipmentId     = case when (PalletType = 'C'/* Cart */) then null
                            when (@vShipmentCount = 1) then @vShipmentId
                            when (@vShipmentCount is null) then ShipmentId
                            else 0
                       end,
      /* Pallet can have multiple ShipTos on it which is being shipped to a consolidator */
      ShipToId       = case when (LoadId > 0) and (@vShipToIdCount > 1) then @vConsolidatorAddressId
                            when (@vShipToIdCount = 1)     then @vShipToId
                            when (@vShipToIdCount is null) then ShipToId
                            else null
                       end,
      ShipToStore    = case when (@vShipToStoreCount = 1)     then @vShipToStore
                            when (@vShipToStoreCount is null) then ShipToStore
                            else null
                       end,
      CustPO         = case when (@vCustPOCount = 1)     then @vCustPO
                            when (@vCustPOCount is null) then CustPO
                            else null
                       end,
      Ownership      = case when (@vOwnershipCount = 1)      then @vOwnership
                            when (@vOwnershipCount is null)  then Ownership
                            else null
                       end,
      Weight         = @vTotalWeight,
      Volume         = @vTotalVolume * 0.000578704, /* Cu. ft. */
      @PalletId      = PalletId,
      @vBusinessUnit = BusinessUnit
  where (PalletId = @PalletId);

  /* If pallet does not have any inventory anymore, clear location of the pallet */
  if (@vQuantity = 0) and (coalesce(@vNumCartons, 0) = 0) and (@vLocationId is not null)
    exec pr_Pallets_SetLocation @PalletId, null /* Location */, 'Y'  /* Yes - UpdateLocation */, @vBusinessUnit, @UserId;

  exec @vReturnCode = pr_Pallets_SetStatus @PalletId = @PalletId, @UserId   = @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Pallets_UpdateCount */

Go
