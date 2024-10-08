/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/04/24  RV      pr_Shipping_GetCommoditiesInfo: Bug fixed to calculate the UnitValue properly (CIMSV3-3571)
  2023/07/06  VS      pr_Shipping_GetCommoditiesInfo: Get the SKU.UnitPrice if OD.UnitPrice (BK-1063)
  2023/05/19  VS      pr_Shipping_GetCommoditiesInfo: Get the SKU component details for Carrier generated CI (BK-1054)
  2021/08/10  OK      pr_Shipping_GetCommoditiesInfo: removed the Businessunit from selection list as it is already being passed in caller and causing runtime issues (CIMSV3-1596)
  2020/10/15  RV      pr_Shipping_GetCommoditiesInfo: Bug fixed to calculate customs value (HA-1545)
  2019/02/13  RV      pr_Shipping_GetCommoditiesInfo: Made change to send custom detail value as CustomsValueAmount (S2G-1210)
  2018/06/01  RV      pr_Shipping_GetCommoditiesInfo: Made changes to return WeightUOM and NumberOfPieces in commodities xml (S2G-602)
  2017/12/06  OK      pr_Shipping_GetCommoditiesInfo: Enhanced to send the Mapped Country codes (OB-668)
                      pr_Shipping_GetCommoditiesInfo: Enhanced to send the description with max lenght of 35 and also by removing special chars (OB-642)
  2016/07/02  KN      pr_Shipping_GetCommoditiesInfo: Added HTSCode to @ttCommodities (NBD-637)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetCommoditiesInfo') is not null
  drop Procedure pr_Shipping_GetCommoditiesInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetCommoditiesInfo: This procedure will return the commodities
    information of all the LPNs which are passed in #ttLPNs. If #CommoditiesInfo
    is created by caller, info is returned in that table, else as XML. If @LPNId
    is given, then we get it only for the given LPN (which is how it is used for V2)

  #ttLPNs: TEntityKeysTable
  #CommoditiesInfo: TCommoditiesInfo
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetCommoditiesInfo
  (@LPNId          TRecordId,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @CommoditiesXML Txml output)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vRecordId         TRecordId,
          @vOrderId          TRecordId,
          @vShipVia          TShipVia,
          @vCarrier          TCarrier,
          @vWeight           TWeight,
          @vQuantity         TQuantity,
          @vWeightUOM        TUOM,
          @vUnitValueOption  TControlValue,
          @vCurrency         TCurrency,
          @vBusinessUnit     TBusinessUnit,
          @vUserId           TUserId;

  /* Temp table to capture Commodities data */
  declare @ttCommodities     TCommoditiesInfo;

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get Weight UOM from the control variable */
  select @vWeightUoM       = dbo.fn_Controls_GetAsString('Shipping', 'WeightUoM', 'LB',            @BusinessUnit, @vUserId),
         @vUnitValueOption = dbo.fn_Controls_GetAsString('Shipping', 'UnitValue', 'UnitSalePrice', @BusinessUnit, @vUserId);

  select @vWeight       = sum(LPNWeight),
         @vQuantity     = sum(Quantity),
         @vOrderId      = min(OrderId) -- assumption that all given LPNs are for same order
  from LPNs L
    join #ttLPNs ttL on (ttL.EntityId = L.LPNId) and (ttL.EntityId = coalesce(@LPNId, ttl.EntityId));

  select @vShipVia  = OH.ShipVia,
         @vCarrier  = SV.Carrier,
         @vCurrency = OH.Currency
  from OrderHeaders OH
    join ShipVias SV on (OH.ShipVia = SV.ShipVia) and (OH.BusinessUnit = SV.BusinessUnit)
  where (OH.OrderId = @vOrderId);

  select LD.LPNId, coalesce(SPP.ComponentSKUId, LD.SKUId) SKUId, LD.OrderDetailId,
         case when SPP.MasterSKUId is not null then SPP.ComponentQty * LD.Quantity
              else LD.Quantity
         end as Quantity,
         LD.Quantity LineQuantity, OD.UnitSalePrice, S.UnitPrice as SKUUnitPrice, S.UnitCost,
         case -- when Prepack and OD has UnitPrice, then UnitPrice of the component
              -- will be divided against each component
              when SPP.MasterSKUId is not null and nullif(OD.UnitSalePrice, 0) is not null
                then OD.UnitSalePrice * (SPP.ComponentQty * 1.0/LD.Quantity)
              else coalesce(nullif(OD.UnitSalePrice, 0 ), S.UnitPrice)
         end UnitPrice,
         case -- when prepack, divide the ODUnitSalePrice in ratio of component qty
              when (@vUnitValueOption = 'UnitSalePrice') and
                   (SPP.MasterSKUId is not null)
                then coalesce(nullif(OD.UnitSalePrice, 0 ), nullif(S.UnitPrice, 0), S.UnitPrice) * (SPP.ComponentQty * 1.0/LD.Quantity)
              -- when not a prepack use OD or SKU price
              when (@vUnitValueOption = 'UnitSalePrice')
                then coalesce(nullif(OD.UnitSalePrice, 0 ), nullif(S.UnitPrice, 0), S.UnitPrice)
              else S.UnitCost
         end UnitValue,
         coalesce(nullif(LD.CoO, ''), nullif(S.DefaultCoO, '')) CoO
  into #LPNDetails
  from LPNDetails LD
    join #ttLPNs ttL     on (ttL.EntityId = LD.LPNId) and (ttL.EntityId = coalesce(@LPNId, ttl.EntityId))
    join OrderDetails OD on (LD.OrderDetailId = OD.OrderDetailId)
    left join SKUPrePacks SPP on (LD.SKUId = SPP.MasterSKUId)
    join SKUs S on (S.SKUId = coalesce(SPP.ComponentSKUId, LD.SKUId))

  /* Gather info for Commodities */
  insert into @ttCommodities (EntityType, EntityId, EntityKey,
                              NumberOfPieces, SKU, Description, ProductInfo1, ProductInfo2, ProductInfo3,
                              Quantity, QuantityUoM, Currency,
                              UnitCost, UnitPrice, UnitValue,
                              LineTotalCost, LineTotalPrice, LineValue,
                              UnitWeight, QtyWeight, WeightUoM,
                              CoO, FreightClass, HarmonizedCode, HTSCode, LPNWeight, PackageSeqNo)
    select 'LPN', LD.LPNId, L.LPN,
           LD.Quantity, S.SKU, left(coalesce(dbo.fn_RemoveSpecialChars(S.Description), S.SKU), 30),
           dbo.fn_RemoveSpecialChars(S.ProductInfo1),
           dbo.fn_RemoveSpecialChars(S.ProductInfo2),
           dbo.fn_RemoveSpecialChars(S.ProductInfo3),
           LD.Quantity, coalesce(nullif(S.UoM, ''), 'EA'), @vCurrency,
           S.UnitCost, LD.UnitPrice, LD.UnitValue,
           (S.UnitCost * LD.Quantity), (LD.UnitPrice * LD.Quantity), (LD.UnitValue * LD.Quantity),
           convert(numeric(7,2), S.UnitWeight), cast(convert(numeric(10,2), LD.Quantity * nullif(S.UnitWeight, 0)) as varchar), @vWeightUoM,
           coalesce(LD.CoO, 'US'), S.NMFC, S.HarmonizedCode, S.HTSCode, L.LPNWeight, L.PackageSeqNo
    from #LPNDetails LD
      join LPNs L on (L.LPNId  = LD.LPNId)
      join SKUs S on (LD.SKUId = S.SKUId);

  /* TempFix: Clean up Harmonized Code for USPS. This needs to really be done in USPS code */
  if (@vCarrier = 'USPS')
    update @ttCommodities
    set HTSCode = replace(replace(HTSCode, '.', ''), '-', '');

  /* Map country names to codes */
  update @ttCommodities set CoO = dbo.fn_Contacts_GetCountryCode(CoO, @BusinessUnit, @UserId);

  /* Field deprecated, but may be used in V2 & CIMSSI, so populate it */
  update @ttCommodities set Manufacturer = CoO;

  /* If any of the lines do not have a weight, then redistribute the LPN weight or
     if the sum of line weights > @vWeight on the LPN or Pallet.
     Reduce by 0.01 or else causes issue with rounding. If total package weight is
     2.0 and there are three lines each rounded off would be .666666 (rounded to 0.67 * 3 = 2.01
     and USPS will not allow unit weight > package weight */
  if (exists (select * from @ttCommodities where QtyWeight is null)) or
     ((select sum(cast(QtyWeight as float)) from @ttCommodities) > @vWeight)
    update @ttCommodities
    set QtyWeight = cast(convert(numeric(6, 2), ((@vWeight * Quantity) / @vQuantity) -0.01) as varchar);

  if object_id('tempdb..#CommoditiesInfo') is not null
    begin
      delete from #CommoditiesInfo;
      insert into #CommoditiesInfo select * from @ttCommodities;
    end
  else
    begin
      /* In Shipping Integrator, get custom value in CustomsValueAmount node instead of Value node (S2G-1210) */
      select @Commoditiesxml = (select LineValue as CustomsValueAmount, *
                                from @ttCommodities
                                for xml raw('COMMODITY'), elements);
      select @Commoditiesxml = dbo.fn_XMLNode('COMMODITIES', convert(varchar(max), @Commoditiesxml));
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_GetCommoditiesInfo */

Go
