/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/27  RKC     pr_Shipping_ShipManifest_GetDetails, pr_Shipping_GetBoLDataCustomerOrderDetails: Made changes to get the correct Weight (HA-2650)
  2021/04/27  SAK     pr_Shipping_ShipManifest_GetDetails: Added InventoryClass1,InventoryClass2,InventoryClass3 field to show in RDLC's,
  2021/04/20  TK      pr_Shipping_ShipManifest_GetDetails: Contractor Loads may or may not have order info (HA-GoLive)
  2021/04/08  AY      pr_Shipping_ShipManifest_GetDetails: Print OH UDF on manifest (HA-2572)
  2021/04/06  RV      pr_Shipping_ShipManifest_GetDetails: Added new parameter xml input to get the action and
  2021/02/19  AY      pr_Shipping_ShipManifest_GetDetails: Fix issue with handling multi SKU cartons with PackingGroup (HA-2024)
  2021/01/17  TK      pr_Shipping_ShipManifest_GetDetails: Consider SKU.DefaultCoO if there is none on LPN detail (HA-1912)
  2020/01/05  RT      pr_Shipping_ShipManifest_GetDetails,pr_Shipping_ShipManifest_GetData: Included LoT and CoO and joined the Loads (HA-1849)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_ShipManifest_GetDetails') is not null
  drop Procedure pr_Shipping_ShipManifest_GetDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_ pr_Shipping_ShipManifest_GetDetails: Returns all the info associated with the
    Load and it's Cartons to print a shipping manifest.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_ShipManifest_GetDetails
  (@xmlInput        xml,
   @LoadId          TLoadId      = null,
   @ShipmentId      TShipmentId,
   @ReportName      TName,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @SMDetailsxml    TXML        = null output,
   @Debug           TFlags      = null)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage               TDescription,
          @vDebug                 TFlags = 'N',

          @Reportsxml             varchar(max),

          @vLoadId                TLoadId,
          @vLoadNumber            TLoadNumber,
          @vShipmentId            TShipmentId,
          @vOrderId               TRecordId,
          @vReport                TResult,
          @vDummyRows             TInteger,
          @vNumDetails            TInteger,
          @vNumPallets            TInteger,
          @vTotalShipmentWeight   TWeight,
          @vPalletTareWeight      TWeight,
          @vPalletTareVolume      TVolume,
          @vxmlRulesData          TXML,

          @vEntity                varchar(max),
          @vAction                TAction,
          @Resultxml              varchar(max);

  declare @ttShipmentPallets  TEntityKeysTable;

  declare @ttLPNs table
          (ShipmentId  TShipmentId,
           LPNWeight   TWeight);

  declare @ttShipmentLPNDetails      TManifestLPNDetails;
  declare @ttManifestLPNDetails      TShippingManifestDetails;
  declare @ttShippingManifestDetails TShippingManifestDetails;

begin /* pr_Shipping_ShipManifest_GetDetails */
  select @vReturnCode   = 0,
         @vMessagename  = null,
         @vDebug        = coalesce(@Debug, @vDebug);

  /* Create hash tables */
  select * into #ShipmentLPNDetails      from @ttShipmentLPNDetails;
  select * into #ShippingManifestDetails from @ttShippingManifestDetails;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Start', @@ProcId;

  select @vAction = Record.Col.value('ActionId[1]', 'TAction')
  from @xmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlInput = null ) );

  /* Get the PalletTareWeight and Volume and update accordingly */
  select @vPalletTareWeight = dbo.fn_Controls_GetAsInteger('Shipping', 'PalletTareWeight', '35' /* lbs */, @BusinessUnit, null),
         @vPalletTareVolume = dbo.fn_Controls_GetAsInteger('Shipping', 'PalletTareVolume', '7680' /* cu.in. */, @BusinessUnit, null);

  /* Correct the sequence number on the Pallets if needed */
  exec pr_Pallets_PalletNoResequence @LoadId;

  /* insert all the pallets into a table to give them a sequence */
  insert into @ttShipmentPallets (EntityId, EntityKey)
    select coalesce(PalletId, 0), coalesce(Pallet, '')
    from LPNs
    where (ShipmentId = @ShipmentId)
    group by coalesce(PalletId, 0), coalesce(Pallet, '');

  /* Build Rules data */
  select @vxmlRulesData = '<RootNode>' +
                            dbo.fn_XMLNode('LoadId',           @vLoadId) +
                            dbo.fn_XMLNode('OrderId',          @vOrderId) +
                            dbo.fn_XMLNode('ShipmentId',       @ShipmentId) +
                         '</RootNode>'

  /* Get all the LPN Details of the shipment for analysis - correct any errors in LDInnerPacks or LDUnitsPerPackage */
  insert into #ShipmentLPNDetails (LPNId, LPNDetailId, LPNWeight, LPNLot, LPNCoO,
                                   LPNInventoryClass1, LPNInventoryClass2, LPNInventoryClass3,
                                   LDInnerPacks, LDQuantity, UnitsPerPackage, LPNQuantity,
                                   NumLines, ShipCartons, PalletId, OrderId, SKUId, OrderDetailId)
    select L.LPNId, LD.LPNDetailId, LD.Weight, L.Lot, LD.CoO,
           L.InventoryClass1, L.InventoryClass2, L.InventoryClass3,
           case when LD.InnerPacks <> 0 then LD.InnerPacks
                when LD.UnitsPerPackage > 0 and LD.Quantity >= LD.UnitsPerPackage then LD.Quantity/LD.UnitsPerPackage
                else 0
           end /* LDInnerPacks */,
           LD.Quantity,
           case when coalesce(LD.UnitsPerPackage, 0) <> 0 then LD.UnitsPerPackage
                when LD.InnerPacks > 0 then LD.Quantity/LD.InnerPacks
                when L.NumLines > 1 then LD.Quantity
                else 0
           end /* UnitsPerPackage */,
           L.Quantity, L.NumLines, 0, coalesce(L.PalletId, 0), L.OrderId, LD.SKUId, LD.OrderDetailId
    from LPNs L join LPNDetails LD on L.LPNId = LD.LPNId
    where (L.ShipmentId = @ShipmentId);

  /* LPNs will be summarized based upon if it is for summary report then group pallet otherwise multi-SKU LPN or a single SKU LPN
     and within single SKU LPNs, they are based upon UnitsPerPackage or Quantity */
  update #ShipmentLPNDetails
  set GroupCriteria1 = case when @vAction like '%Summary%' then cast(PalletId as varchar)
                            else concat_ws('-', PalletId, SLD.SKUId, InventoryClass1, InventoryClass2, InventoryClass3)
                       end,
      GroupCriteria2 = '', -- future use
      GroupCriteria3 = case when @vAction like '%Summary%' then ''
                            else case when NumLines > 1 and coalesce(OD.PackingGroup, '') > '' then 'PG-' + OD.PackingGroup
                                      when NumLines > 1 and coalesce(OD.PackingGroup, '') = '' then 'LPN-' + cast(SLD.LPNId as varchar)
                                      when UnitsPerPackage = 0 then 'LPNQ' + cast(LPNQuantity as varchar)
                                      else 'UPP-' + cast(UnitsPerPackage as varchar)
                                 end
                       end
  from #ShipmentLPNDetails SLD left outer join OrderDetails OD on SLD.OrderDetailId = OD.OrderDetailId;

  /* Calculating the number of cartons for each LPN */
  with LPNShipCartons as
  (
    select LPNId, Min(LPNDetailId) LPNDetailId
    from #ShipmentLPNDetails
    where NumLines > 1 and GroupCriteria3 not like 'PG%'
    group by LPNId
    union
    select LPNId, LPNDetailId
    from #ShipmentLPNDetails
    where NumLines > 1 and GroupCriteria3 like 'PG%'
    group by LPNId, LPNDetaiLId
    union
    select LPNId, LPNDetailId
    from #ShipmentLPNDetails
    where NumLines = 1
  )
  update SLD
  set ShipCartons = 1
  from #ShipmentLPNDetails SLD join LPNShipCartons LSC on SLD.LPNDetailId = LSC.LPNDetailId;

  /* Use rules to alter or add any info of #ShipmentLPNDetails */
  exec pr_RuleSets_ExecuteAllRules 'ShippingManifest_LPNDetails', @vxmlRulesData, @BusinessUnit;

  /* Summarize the info by CustPO/SalesOrder/Pallet/SKUId and UnitsPerPackage */
  insert into #ShippingManifestDetails
      (CustPO, OrderId, PickTicket, PalletId, SKUId, ShipCartons, InnerPacks, Quantity, UnitsPerPackage, Weight, CustSKU, Lot, CoO,
       InventoryClass1, InventoryClass2, InventoryClass3)
    select OH.CustPO,
           case when count(distinct OH.OrderId) = 1 then min(OH.OrderId) else null end,
           case when count(distinct OH.PickTicket) = 1 then min(OH.PickTicket) else 'Multiple' end, -- PickTicket
           L.PalletId,
           case when count(distinct L.SKUId) = 1 then min(L.SKUId) else null end, -- SKUId
           sum(ShipCartons), sum(LDInnerPacks), sum(LDQuantity),
           min(coalesce(nullif(L.UnitsPerPackage, 0), L.LPNQuantity)), sum(LPNWeight),
           case when count(distinct L.SKUId) = 1 then min(OD.CustSKU) else null end, -- CustSKU
           min(L.LPNLot), min(L.LPNCoO), min(L.LPNInventoryClass1),  min(L.LPNInventoryClass2),  min(L.LPNInventoryClass3)
    from #ShipmentLPNDetails L
      left join OrderHeaders       OH  on (OH.OrderId    = L.OrderId)
      left join OrderDetails       OD  on (OD.OrderId    = L.OrderId) and (OD.OrderDetailId = L.OrderDetailId)
      left join @ttShipmentPallets SP  on (L.PalletId    = SP.EntityId)
    group by OH.CustPO, L.PalletId, L.GroupCriteria1, L.GroupCriteria2, L.GroupCriteria3;

  -- /* In the scenario, where LD Innerpacks and LDQuantity are not divisible, break up into two lines */
  -- insert into @ttShippingManifestDetails (CustPO, PickTicket, PalletId, SKUId, ShipCartons, InnerPacks, Quantity, UnitsPerPackage, Weight, CustSKU)
  --   select L.CustPO, L.PickTicket, L.PalletId, L.SKUId, ShipCartons, L.InnerPacks, L.Quantity, L.UnitsPerPackage, L.Weight, L.CustSKU
  --   from @ttManifestLPNDetails L

  /* Update Pallet Info & NumCases/UnitsPerPackage */
  update SMD
  set Pallet          = SP.EntityKey,
      PalletSeqNo     = P.PalletSeqNo,
      SortOrder       = dbo.fn_LeftPadNumber(P.PalletSeqNo, 2), -- to sort
      Cases           = ShipCartons,
      UnitsPerPackage = case when SMD.UnitsPerPackage = 0 then SMD.Quantity else SMD.UnitsPerPackage end
  from #ShippingManifestDetails SMD
    left join @ttShipmentPallets SP  on (SMD.PalletId = SP.EntityId)
    left outer join Pallets P on SMD.PalletId = P.PalletId;

  select @vNumPallets = count(distinct Pallet)
  from #ShippingManifestDetails

  /* Temp fix, do not print Units Perpakcage on summary report */
  if (@vAction like '%Summary%')
    update SMD
    set UnitsPerPackage = null
    from #ShippingManifestDetails SMD

  /* Add the Pallet Tare Weight to the first record so that the weight on Manifest matches that of Load */
  if (@vNumPallets > 0)
    begin
      update SMD
      set Weight += (case when @vNumPallets > 0 then (@vNumPallets * @vPalletTareWeight) else weight end)
      from #ShippingManifestDetails SMD
      where Recordid = 1
    end

  /* Update SKU Info */
  update SMD
  set SKU  = S.SKU,
      UPC  = S.UPC,
      SKU1 = S.SKU1,
      SKU2 = S.SKU2,
      SKU3 = S.SKU3,
      SKU4 = S.SKU4,
      SKU5 = S.SKU5,
      SKUDescription  = S.Description,
      SKU1Description = S.SKU1Description,
      SKU2Description = S.SKU2Description,
      SKU3Description = S.SKU3Description,
      SKU4Description = S.SKU4Description,
      SKU5Description = S.SKU5Description,
      AlternateSKU    = S.AlternateSKU
  from #ShippingManifestDetails SMD left join SKUs S on (SMD.SKUId = S.SKUId);

  if (charindex('D', @vDebug) > 0) select 'ShipmentLPNDetails', * from #ShipmentLPNDetails;
  if (charindex('D', @vDebug) > 0) select 'SMDetails', * from #ShippingManifestDetails;

  /* Update the LoadId and ShipmemntId on the ShippingManifestDetail Records */
  update #ShippingManifestDetails
  set LoadId     = @LoadId,
      ShipmentId = @ShipmentId;

  select @vNumDetails = @@rowcount;

  /* Use rules to alter or add any info of #ShippingManifestDetails */
  exec pr_RuleSets_ExecuteAllRules 'ShippingManifest_ManifestDetails', @vxmlRulesData, @BusinessUnit;

  /* Get the details to print on first report */
  set @SMDetailsxml = (select * from #ShippingManifestDetails
                       order by SortOrder, CustPO, PickTicket, SKU, Quantity desc
                       for xml raw('SHIPPINGMANIFESTDETAILS'), elements);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_ShipManifest_GetDetails */

Go
