/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/28  AY      pr_Load_Recount: Set ShipToName (HA GoLive)
  2021/04/27  RKC     pr_Load_Recount: Made changes to get the correct weight (HA-2650)
  2021/04/15  AY      pr_Load_Recount: Reset BoL Status if any changes (HA-2467)
  2021/04/06  RKC     pr_Load_Recount: Ported the changes from HA prod Patches folder (HA-2531)
  2021/03/12  TK      pr_Load_Recount: bug fix in updating NumPallets on Loads (HA-2051)
  2021/02/11  TK      pr_Load_Recount: Changes to update EstimatedCartons (HA-1964)
  2021/02/09  RKC     pr_Load_Recount: Made changes to update the correct numpallets counts on the Loads (HA-1954)
  2021/01/29  RKC     pr_Load_Recount: Made changes to update the correct numpallets counts on the Loads (HA-1954)
  2021/01/20  PK      pr_Load_GenerateBoLs, pr_Loads_Action_ModifyBoLInfo, pr_Load_Recount: Ported back changes are done by Pavan (HA-1749) (Ported from Prod)
  2020/10/27  VM      pr_Load_Recount: Do not clear FromWarehouse from Load, when it is empty/canceled (HA-1617)
  2020/10/09  RKC     pr_Load_Recount: Removed the coalesce while calculating the distinct count (HA-1527)
                      pr_Load_Recount: If Palletized as N the do not include Pallet weight in the Load Weight (HA-1106)
                      pr_Load_CreateNew, pr_Load_Update, pr_Load_Recount: changes for ShipFrom(CIMSV3-996)
  2020/07/01  TK      pr_Load_Recount: Do not  override FromWarehouse, ShipToId & SoldToId for transfers load type
  2020/06/22  OK      pr_Load_Recount: Changes to update the NumPallets properly before BoLs got generated (HA-967)
                      pr_Load_Recount: Return Status
  2019/07/11  AY      pr_Load_Recount: Save LPNWeight/Volume on Load (CID-785)
                      pr_Load_Recount: Set SoldToId to make the clientLoad (OB2-683)
  2018/05/08  AY      pr_Load_Recount: Summarize ShipToName on Load (S2G-805)
  2016/08/09  AY      pr_Load_Recount: Created new LoadType UPSE for UPS Next and Second Day orders
                      pr_Load_Recount: Not allowing to change the Load type.
  2016/04/20  AY      pr_Load_Recount: Calc ShipFrom on Load (NBD-363).
  2015/10/22  AY      pr_Load_Recount: Fix Load volume issue to include correct pallet volume
  2015/10/08  YJ/AY   pr_Load_Recount: Added summarized fields. (ACME-353)
  2013/10/19  PK      pr_Load_Recount: Updating the LPN weight and volume on the load.
              PK      pr_Load_Recount: Updating Load type based on the ShipTo Count.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_Recount') is not null
  drop Procedure pr_Load_Recount;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_Recount:
   Recount will calculate the counts afresh. Also calls SetStatus of Load
   to update the Load Status accordingly

  BoLStatus: If there is change in count of Orders/Pallets/Units, then reset
------------------------------------------------------------------------------*/
Create Procedure pr_Load_Recount
  (@LoadId  TLoadId,
   @Status  TStatus = null output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vTotalOrders           TCount,
          @vWarehouseCount        TCount,
          @vWarehouse             TWarehouse,
          @vShipFromCount         TCount,
          @vShipFrom              TShipFrom,
          @vShipToCount           TCount,
          @vShipToId              TShipToId,
          @vShipToName            TName,
          @vSoldToCount           TCount,
          @vSoldToId              TShipToId,
          @vLoadShipToId          TShipToId,
          @vLoadShipToName        TName,
          @vTotalPallets          TCount,
          @vTotalLPNs             TCount,
          @vTotalPackages         TCount,
          @vTotalUnits            TCount,
          @vEstimatedCartons      TCount,
          @vTotalShipmentValue    TMoney,
          @vOrderId               TRecordId,
          @vLPNVolume             TFloat,
          @vBoLWeight             TFloat,
          @vLPNWeight             TFloat,
          @vAccount               TAccount,
          @vAccountCount          TCount,
          @vAccountNameCount      TCount,
          @vAccountName           TName,
          @vPBGroupCount          TCount,
          @vPickBatchGroup        TWaveGroup,
          @vBusinessUnit          TBusinessUnit,
          /* Prev counts */
          @vPrevOrders            TCount,
          @vPrevPallets           TCount,
          @vPrevLPNs              TCount,
          @vPrevUnits             TCount,
          @vPalletTareWeight      TInteger,
          @vPalletVolume          TFloat,
          @vMasterBoLPallets      TCount,
          @vUnderlyingBoLPallets  TCount,
          @vBoLId                 TBoLId;
begin  /* pr_Load_Recount */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vTotalOrders   = 0,
         @vTotalPallets  = 0,
         @vTotalLPNs     = 0,
         @vTotalPackages = 0,
         @vTotalUnits    = 0;

  select @vTotalOrders        = count(*),
         @vTotalUnits         = sum(NumUnits),
         @vEstimatedCartons   = sum(EstimatedCartons),
         @vTotalShipmentValue = sum(TotalShipmentValue),
         @vWarehouseCount     = count(distinct Warehouse),
         @vWarehouse          = min(Warehouse),
         @vShipFromCount      = count(distinct ShipFrom),
         @vShipFrom           = min(ShipFrom),
         @vShipToCount        = count(distinct ShipToId),
         @vShipToId           = min(ShipToId),
         @vShipToName         = min(ShipToName),
         @vSoldToCount        = count(distinct SoldToId),
         @vSoldToId           = min(SoldToId),
         @vAccountCount       = count(distinct Account),
         @vAccount            = min(Account),
         @vAccountNameCount   = count(distinct AccountName),
         @vAccountName        = min(AccountName),
         @vPBGroupCount       = count(distinct PickBatchGroup),
         @vPickBatchGroup     = min(PickBatchGroup)
  from vwLoadOrders
  where (LoadId = @LoadId);

  select @vLoadShipToId = ShipToId,
         @vPrevOrders   = NumOrders,
         @vPrevPallets  = NumPallets,
         @vPrevLPNs     = NumLPNs,
         @vPrevUnits    = NumUnits,
         @vBusinessUnit = BusinessUnit
  from Loads
  where (LoadId = @LoadId);

  /* PK:20210120 - For Transfer load type, there might not be any orders and so to retrieving ShipToName by
                   considering Load.ShipToId */
  select @vLoadShipToName = Name
  from Contacts
  where (ContactRefId = @vLoadShipToId) and
        (ContactType  = 'S' /* ShipTo */) and
        (BusinessUnit = @vBusinessUnit);

  /* Get the Counts from LPNs */
  select @vTotalPallets  = count(distinct PalletId),
         @vTotalLPNs     = count(distinct LPNId),
         @vTotalPackages = coalesce(sum(InnerPacks), 0),
         @vTotalUnits    = coalesce(sum(Quantity), 0),
         @vLPNVolume     = sum(LPNVolume),
         @vLPNWeight     = sum(LPNWeight)
  from LPNs
  where (LoadId = @LoadId);

  select @vBoLWeight = sum(Weight)
  from BoLCarrierDetails BCD join BoLs B on BCD.BoLId = B.BoLId
  where (B.LoadId = @LoadId) and
        (BOLType <> 'M');

  select @vPalletTareWeight = dbo.fn_Controls_GetAsInteger('BoL', 'PalletTareWeight', '35' /* lbs */, @vBusinessUnit, null),
         @vPalletVolume     = dbo.fn_Controls_GetAsInteger('BoL', 'PalletVolume', '7680' /* cu.in. */, @vBusinessUnit, null);

  /* Update Load with latest counts */
  update Loads
  set NumOrders          = @vTotalOrders,
      NumPallets         = @vTotalPallets,
      NumLPNs            = @vTotalLPNs,
      NumPackages        = @vTotalPackages,
      NumUnits           = @vTotalUnits,
      EstimatedCartons   = @vEstimatedCartons,
      TotalShipmentValue = @vTotalShipmentValue,
      LPNVolume          = @vLPNVolume,
      LPNWeight          = @vLPNWeight,
                           /* If there is change in Orders/Pallets/Units, then reset BoL Status */
      BoLStatus          = case when ((@vPrevOrders  <> @vTotalOrders ) or
                                      (@vPrevPallets <> @vTotalPallets) or
                                      (@vPrevLPNs    <> @vTotalLPNs   ) or
                                      (@vPrevUnits   <> @vTotalUnits  )) and
                                     (BoLStatus = 'Generated') then 'To Generate'
                                else BoLStatus
                           end,
      Volume             = case when (@vTotalUnits > 0) then
                             cast((coalesce(@vLPNVolume, 0) + (coalesce(@vTotalPallets, 0) * (case when Palletized = 'N' then 0 else @vPalletVolume end))) * 0.000578704 as decimal(8,0))
                           else
                             0
                           end, /* convert to cubic feet */
      Weight             = case when (@vTotalUnits > 0) and (@vBoLweight > 0) then @vBoLweight
                                when (@vTotalUnits > 0) then coalesce(@vLPNWeight,0) + (coalesce(@vTotalPallets, 0) * (case when Palletized = 'N' then 0 else @vPalletTareWeight end))
                           else
                             0
                           end,
      LoadType           = case
                             when LoadType = 'MULTIDROP' and @vShipToCount = 1 then 'SINGLEDROP'
                             when LoadType = 'SINGLEDROP' and @vShipToCount > 1 then 'MULTIDROP'
                             else LoadType
                           end,
      Account            = case
                             when @vAccountCount = 1 then @vAccount
                             when @vAccountCount = 0 then null
                             else 'Multiple'
                           end,
      AccountName        = case
                             when @vAccountNameCount = 1 then @vAccountName
                             when @vAccountNameCount = 0 then null
                             else 'Multiple'
                           end,
      PickBatchGroup     = case
                             when @vPBGroupCount = 1 then @vPickBatchGroup
                             when @vPBGroupCount = 0 then null
                             else 'Multiple'
                           end,
      FromWarehouse      = case
                             when LoadType = 'Transfer' then FromWarehouse
                             when @vWarehouseCount = 1 then @vWarehouse
                             /* Retain FromWarehouse even if Load is empty/canceled for record purpose and also to show in UI as well
                                as currently in V3, system does not show loads if there is no Warehouse on the load */
                             when @vWarehouseCount = 0 then FromWarehouse
                             else 'Multiple'
                           end,
      ShipFrom           = case
                             when LoadType = 'Transfer' then ShipFrom
                             when @vShipFromCount = 1 then @vShipFrom
                             when @vShipFromCount = 0 then ShipFrom -- do not clear ShipFrom even when all Orders are removed from the Load
                             else 'Multiple'
                           end,
      ShipToId           = case
                             when LoadType = 'Transfer' then ShipToId -- do not change for transfers
                             when @vShipToCount = 1 then @vShipToId
                             when @vShipToCount = 0 then null
                             else 'Multiple'
                           end,
      ShipToDesc         = case
                             when LoadType = 'Transfer' then @vLoadShipToName
                             when @vShipToCount = 1 then @vShipToName
                             when @vShipToCount = 0 then null
                             else 'Multiple'
                           end,
      SoldToId           = case
                             when LoadType = 'Transfer' then SoldToId
                             when @vSoldToCount = 1 then @vSoldToId
                             when @vSoldToCount = 0 then null
                             else 'Multiple'
                           end
  where (LoadId = @LoadId);

  /* Update Load Status */
  exec @vReturnCode = pr_Load_SetStatus @LoadId, @Status output;

  /* When the Load is shipped then update NumPallets with BoL pallet count as they could have changed on the BoL */
  if (@Status = 'S' /* Shipped */)
    begin
      /* If Load has Master BoL then take Pallet count from Master BoL, else from the only underlying BoL
         therefore, ordering by BoLType. We use the BoL pallet counts instead of the actual pallet counts
         from LPNs because practically they repalletize the LPNs but don't take time to do it in the system */
      select @vMasterBolPallets = sum(BCD.HandlingUnitQty)
      from BoLCarrierDetails BCD
        join BoLs B on BCD.BoLId = B.BoLId
      where (B.LoadId = @LoadId) and
            (B.BolType = 'M' /* Master */);

      if (@@rowcount = 0)
        select @vUnderlyingBoLPallets = sum(BCD.HandlingUnitQty)
        from BoLCarrierDetails BCD
          join BoLs B on BCD.BoLId = B.BoLId
        where (B.LoadId = @LoadId) and
              (B.BolType = 'U' /* Underlying BoLs */);

      update Loads
      set NumPallets = coalesce(@vMasterBolPallets, @vUnderlyingBoLPallets, NumPallets)
      from Loads
      where (LoadId = @LoadId);
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Load_Recount */

Go
