/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/06/30  SAS     pr_OrderHeaders_Preprocess: Updated orderdate ,CreatedDate to Procedure (BK-406)
  2022/01/22  AY      pr_OrderHeaders_Preprocess: Moved address management to rules (BK-742)
  2021/10/12  RV      pr_OrderHeaders_Preprocess: Bug fixed to update the priority (BK-628)
  2021/09/03  MS      pr_OrderHeaders_Preprocess: Changes to send IsSmallPackageCarrier in xml (BK-560)
  2021/08/04  VS      pr_OrderHeaders_Preprocess: Pass the Operation as OrderPreprocess (BK-465)
  2021/04/06  AY/YJ   pr_OrderHeaders_Preprocess: Consider OD.UnitsPerInnerpack instead of SKU (HA-2553)
  2021/03/26  TK      pr_OrderHeaders_Preprocess: Invoke new proc to estimate cartons on the order (HA-2445)
  2021/02/23  TK      pr_OrderHeaders_Preprocess: When rule result stuffed with XMLData need to output the variable to be used further (HA-2043)
  2021/02/22  VS      pr_OrderHeaders_Preprocess: Added ShipToCity for validations (BK-170)
  2021/02/04  TK      pr_OrderHeaders_Preprocess: Order status should be downloaded only when there are error validations (HA-1964)
  2021/01/12  TK      pr_OrderHeaders_Preprocess: Changes to pass SKUCount to rules (BK-65)
  2020/09/04  AY      pr_OrderHeaders_Preprocess: Set OH.ShipToName (HA-1385)
  2020/08/07  RT      pr_OrderHeaders_Preprocess: Calculating the TotalSalement Amount with respect o the Prices (HA-1198)
  2020/07/17  YJ      pr_OrderHeaders_Preprocess: To update the Priority to default if it is zero (HA-675)
  2020/07/07  AY      pr_OrderHeaders_Preprocess: All preprocess update rules were not being processed
  2020/06/02  OK      pr_OrderHeaders_Preprocess: Changes to do not update UnitsPerCarton on OD (HA-772)
  2020/05/29  YJ      pr_OrderHeaders_Preprocess: Migrated from Production (HA-689)
  2020/05/25  TK      pr_OrderHeaders_Preprocess: Update Packing Group using rules (HA-648)
  2020/05/20  RKC     pr_OrderHeaders_Preprocess: Changes to update the SKU information on Orderdetails (HA-596)
  2020/05/15  RT/TK   pr_OrderHeaders_Preprocess: Migrated OH_PreprocessOrderStatus (HA-301)
  2020/04/14  TK      pr_OrderHeaders_Preprocess: Update OD.InventoryClass to empty if they pass null (HA-84)
  2020/02/20  VS      pr_OrderHeaders_Preprocess: replace & Symbol with Empty on CustPO (CID-1347)
  2019/08/12  AJ      pr_OrderHeaders_Preprocess: Added CustPO and made changes to remove special chars in it (CID-916)
  2019/07/08  MS      pr_OrderHeaders_Preprocess: Changes to update FreightTerms (CID-734)
  2018/10/15  VS      pr_OrderHeaders_Preprocess: When an Order is only given ShipTo address or only given SoldTo address copy from one to another (OB2-638)
  2018/09/18  TK      pr_OrderHeaders_Preprocess: Execute Rules to update Orders (S2GCA-281)
  2018/03/28  TD      pr_OrderHeaders_Preprocess: Updating Order Status based on the HostNumLines (HPI-1831)
  2018/02/26  TD      pr_OrderHeaders_Preprocess:Changes to update ShipVia,FreightTerms and BillToAccount based on the configured RoutingRules (CIMS-1751)
  2018/02/12  TK/AY   pr_OrderHeaders_Preprocess: Changes to update Order pickzone with comma separated values (S2G-106)
  2018/02/02  RT      pr_OrderHeaders_Preprocess: Enhanced the rules to get the OrderCategory1 based on the Carrier in ShipVias (S2G-103)
  2018/01/29  MJ      pr_OrderHeaders_Preprocess: Enhanced the rules to get the ShipFrom based on the Ownership (S2G-102)
  2017/12/08  VM      pr_OrderHeaders_Preprocess: Included to process SoldTo rules and insert new SoldTo does not exists (OB-671)
  2017/11/08  OK      pr_OrderHeaders_Preprocess: Implemented rules to get the ShipVia, BillToAccount based on order data (OB-650)
  2016/07/29  TK      pr_OrderHeaders_Preprocess: OD.PackingGroup should be OrderId by default (HPI-380)
  2016/06/07  TK      pr_OrderHeaders_Preprocess: Changes made to update SKU Location Details on the OrderDetails
  2016/05/23  TK      pr_OrderHeaders_Preprocess: Update PreprocessFlag using Rules (HPI-71)
  2016/05/04  TD      pr_OrderHeaders_Preprocess:Changes to update pricestickers format.
  2016/04/03  TK      pr_OrderHeaders_Preprocess: Transform Order Details to PrePacks if the Order Qty is in multiples of PrePacks (FB-642)
  2016/03/30  SV      pr_OrderHeaders_Preprocess : Updating the ShipComplete over OrderHeader (NBD-293)
  2016/02/10  KN      pr_OrderHeaders_Preprocess: USPS related code (NBD-162).
  2015/12/30  DK      pr_OrderHeaders_Preprocess: Enhanced to use rule to update ReturnLabelRequired flag (CIMS-733).
  2015/10/20  AY/TK   pr_OrderHeaders_Preprocess: Enhanced to use rule for PickBatchGroup (ACME-382)
  2015/04/14  PK      pr_OrderHeaders_Preprocess: Defaulting FreightTerms to Sender.
  2015/03/29  SV      pr_OrderHeaders_Preprocess: Implemented Rules for updating the ShipVia
  2015/02/26  TK      pr_OrderHeaders_Preprocess: PickBatchGroup should be updated with SoldToId
  2014/09/16  SV/VM   pr_OrderHeaders_Preprocess: Enhanced for drop Ship customer orders.
  2014/06/03  NB      pr_OrderHeaders_Preprocess: Modified to update PreprocessFlag on OrderHeader
  2014/04/01  NY      pr_OrderHeaders_Preprocess : Added OrigUnitsAuthorizedToShip.
  2014/03/11  DK      pr_OrderHeaders_Preprocess: Enhanced to set OrderHeaders.HasNotes column
  2014/02/06  NY      pr_OrderHeaders_Preprocess: Showing Batch # from Details.
  2013/11/13  TD      pr_OrderHeaders_Preprocess: Passing ShipToStore as PickBatchGroup.
  2013/10/29  AY      pr_OrderHeaders_Preprocess: ShipToStore is same as ShipToId for XSC
  2013/10/08  NY      pr_OrderHeaders_Preprocess: Updated OD.UDF9 with SKU.UDF9.
  2013/10/08  TD      pr_OrderHeaders_Preprocess: Orderheaders Total Volume.
  2013/10/02  TD      pr_OrderHeaders_Preprocess: Updating PickbatchGroup with SHipToId.
  2013/09/30  PK      pr_OrderHeaders_Preprocess: Updating PickbatchGroup based on the SKUUDF1.
  2103/09/25  TD      pr_OrderHeaders_Preprocess: Updating PickBatchGroup.
  2013/09/16  PK      pr_OrderHeaders_Preprocess: Changes related to the change of Order
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_Preprocess') is not null
  drop Procedure pr_OrderHeaders_Preprocess;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_Preprocess:

  Used For: This proc is the base procedure to analyze the order and set some
  fields on the OrderHeader/Details which would be used in the processing of the
  order in the DC. Summary info of the order i.e. Lines, SKUs, TotalUnits etc
  are also computed.

  @xmlData structure could be

  '<RootNode>
    <OrderId>74</OrderId>
    <ShipViaServiceType>ORD</ShipViaServiceType>
    <Department>38</Department>
    <AddressType>S</AddressType>
    <BusinessUnit>LL</BusinessUnit>
    <UDF1></UDF1>
    <UDF2></UDF2>
    <UDF3></UDF3>
    <UDF4></UDF4>
    <UDF5></UDF5>
    <UDF6></UDF6>
    <UDF7></UDF7>
    <UDF8></UDF8>
    <UDF9></UDF9>
    <UDF10></UDF10>
  </RootNode>'
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_Preprocess
  (@OrderId           TRecordId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TMessage,

          @vPickZoneCount           TInteger,
          @vPickZone                TZoneId,
          @vMultiplePickZones       TVarchar,

          @vStorageTypeCount        TInteger,
          @vStorageType             TStorageType,
          @vOrderLineCOunt          TInteger,
          @vSKUCount                TInteger,
          @vSKUsToShip              TInteger,
          @vLinesToShip             TInteger,
          @vHostNumLines            TInteger,
          @vODUniqueKey             TControlValue,
          @vSourceSystem            TName,
          @vNumLPNs                 TInteger,
          @vNumInnerPacks           TInteger,
          @vNumUnits                TInteger,
          @vTotalUnits              TInteger,
          @vSoldToId                TCustomerId,
          @vSoldToName              TName,
          @vNewSoldToId             TCustomerId,
          @vShipToId                TShipToId,
          @vShipToName              TName,
          @vShipToCountry           TCountry,
          @vShipToState             TState,
          @vShipToCity              TCity,
          @vShipToZip               TZip,
          @vShipToCityState         TAddressLine,
          @vShipToAddressRegion     TAddressRegion,
          @vFreightTerms            TDescription,
          @vNewFreightTerms         TDescription,
          @vBillToAccount           TBillToAccount,
          @vNewBillToAccount        TBillToAccount,
          @vDropShipFrom            TShipFrom,
          @vShipFrom                TShipFrom,
          @vShipVia                 TShipVia,
          @vCarrier                 TCarrier,
          @vIsSmallPackageCarrier   TFlag,
          @vNewShipVia              TShipVia,
          @vNewCarrier              TCarrier,
          @vPickTicket              TPickTicket,
          @vDesiredShipDate         TDate,
          @vPickbatchNo             TPickbatchNo,
          @vPickBatchGroup          TWaveGroup,
          @vUoMCount                TCount,
          @vUoM                     TUoM,
          @vStdPackQty              TInteger,
          @vShipToReference1        TReference,
          @vShipToReference2        TReference,
          @vSalesAmount             TMoney,
          @vSalesOrder              TSalesOrder,
          @vTotalWeight             TWeight,
          @vTotalVolume             TVolume,
          @vComputePackQty          TFlags,
          @vOrderHasNotes           TFlags,
          @vReturnLabelRequired     TFlags,
          @vPreprocessFlag          TFlags,
          @vOrderType               TTypeCode,
          @vOrderStatus             TStatus,
          @vOrderPriority           TPriority,
          @vOrderCategory1          TCategory,
          @vOrderCategory2          TCategory,
          @vOrderCategory5          TCategory,
          @vControlCategory         TCategory,
          @vBusinessUnit            TBusinessUnit,
          @vUserId                  TUserId    = 'cIMSAgent',
          @vOperation               TOperation = 'OrderPreprocess',
          @vComputeShipVia          TControlValue,
          @vPriceStickersFormat     TName,
          @vAccount                 TAccount,
          @vVASCodes                TVarchar,
          @vVASDescriptions         TVarchar,
          @vOHUDF1                  TUDF,
          @vOHUDF2                  TUDF,
          @vOHUDF3                  TUDF,
          @vOHUDF4                  TUDF,
          @vOHUDF5                  TUDF,
          @vOHUDF6                  TUDF,
          @vOHUDF7                  TUDF,
          @vOHUDF8                  TUDF,
          @vOHUDF9                  TUDF,
          @vOHUDF10                 TUDF,
          @vOHUDF20                 TUDF,
          @vDepartment              TUDF,
          @vOwnership               TOwnership,
          @vWarehouse               TWarehouse,
          @CreatedBy                TUserId,

          @vRoutingRuleId           TRecordId,
          @xmlRulesData             TXML;

  declare @ttValidations        TValidations,
          @ttOrdersToEstimate   TEntityKeysTable;

  declare @ttOrderDetails Table
          (RecordId              TRecordId identity (1,1),
           OrderDetailId         TRecordId,
           PickZone              TZoneId,
           StorageType           TStorageType,
           LineType              TTypeCode,
           SKUId                 TRecordId,
           SKU                   TSKU,
           SKU1                  TSKU,
           SKU2                  TSKU,
           SKU3                  TSKU,
           SKU4                  TSKU,
           SKU5                  TSKU,
           UnitsAuthorizedToShip TInteger,
           OrigUnitsAuthorizedToShip
                                 TInteger,
           UnitsPerCarton        TInteger,
           UnitsPerInnerPack     TInteger,
           NumLPNs               TInteger,
           NumInnerPacks         TInteger,
           NumUnits              TInteger,
           LocationId            TRecordId,
           Location              TLocation,
           UDF1                  TUDF,
           UDF2                  TUDF,
           UDF7                  TUDF,
           UDF9                  TUDF,
           UoM                   TUoM,
           UnitWeight            TWeight,
           UnitVolume            TVolume,
           UnitsOrdered          TQuantity,
           UnitSalePrice         TUnitPrice,
           UnitPrice             TUnitPrice,
           RetailUnitPrice       TUnitPrice)

begin
  SET NOCOUNT ON;

  select @vReturnCode       = 0,
         @vMessageName      = null;

  /* Create #Validations if it doesn't exist */
  if object_id('tempdb..#Validations') is null
    select * into #Validations from @ttValidations;

  select * into #OrderDetails from @ttOrderDetails;
  select * into #OrdersToEstimateCartons from @ttOrdersToEstimate;
  alter table #OrdersToEstimateCartons add EstimationMethod  varchar(20);

  /* Transform Order Details into PrePacks first, if the Ordered Qty is in Multiple of PrePacks */
  --exec pr_OrderHeaders_TransformToPrepacks @OrderId, @vBusinessUnit, 'cIMS Agent' /* UserId */;

  /* Fetch the PickZones and StorageTypes for all order details */
  insert into #Orderdetails (OrderDetailId, PickZone, StorageType, SKUId, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UnitsAuthorizedToShip,
                               OrigUnitsAuthorizedToShip, LocationId, Location, UDF1, UDF2, UDF7, UDF9, UoM, UnitsPerCarton,
                               UnitsPerInnerPack, UnitWeight, UnitVolume, UnitsOrdered, UnitSalePrice, UnitPrice, RetailUnitPrice)
    select OD.OrderDetailId,
           S.PrimaryPickZone,
           '', /* For TD Storage Type is not relevant */
           OD.SKUId,
           S.SKU,
           S.SKU1,
           S.SKU2,
           S.SKU3,
           S.SKU4,
           S.SKU5,
           OD.UnitsAuthorizedToShip,
           OD.UnitsAuthorizedToShip,
           S.PrimaryLocationId,
           S.PrimaryLocation,
           OD.UDF1,
           OD.UDF2,
           OD.UDF7,
           S.UDF9,
           coalesce(nullif(S.UoM, ''), 'EA'),
           OD.UnitsPerCarton,
           coalesce(OD.UnitsPerInnerpack, nullif(S.UnitsPerInnerPack, 0), 1),
           S.UnitWeight,
           S.UnitVolume,
           OD.UnitsOrdered,
           OD.UnitSalePrice,
           S.UnitPrice,
           OD.RetailUnitPrice  -- Use UnitSalePrice or RetailUnitPrice
    from OrderDetails OD left outer join SKUs S on OD.SKUId = S.SKUId
    where (OD.OrderId = @OrderId) and (coalesce(OD.LineType, '') <> 'F' /* Fees */);

  /* Determine the UnitsPerCarton - for Prepacks, Units per carton is the sum of
     Component units from SKUPrepacks. For Others, it would be the most common
     quantity in the LPNs */
  if (@vComputePackQty = 'Y')
    begin
      /* First get the pack qty for EA SKUs */
      with SKUPackQty (SKUId, UnitsPerCarton, NumLPNs, Ranking)
      as
      (
        select L.SKUId, L.Quantity, count(*),
               RANK() over (partition by L.SKUID order by count(*) desc)
        from #OrderDetails OD left outer join LPNs L on L.SKUId = OD.SKUId
        where (L.OnhandStatus in ('A', 'R') or L.Status = 'N') and
              (OD.UoM = 'EA') and
              (coalesce(OD.UnitsPerCarton, 0) = 0)
        group by L.SKUId, L.Quantity
      )
      update #OrderDetails
      set UnitsPerCarton = SPQ.UnitsPerCarton
      from #OrderDetails OD left outer join SKUPackQty SPQ on OD.SKUId = SPQ.SKUId and SPQ.Ranking = 1
      where (coalesce(OD.UnitsPerCarton, 0) = 0);

      /* Next, get the pack qty for PP SKUs */
      with SKUPackQty (SKUId, UnitsPerCarton)
      as
      (
        select OD.SKUId, sum(ComponentQty)
        from #OrderDetails OD left outer join SKUPrePacks SPP on OD.SKUId = SPP.MasterSKUId
        where (OD.UoM = 'PP') and
              (SPP.Status = 'A' /* Active */) and
              (coalesce(OD.UnitsPerCarton, 0) = 0)
        group by OD.SKUId
      )
      update #OrderDetails
      set UnitsPerCarton = SPQ.UnitsPerCarton
      from #OrderDetails OD left outer join SKUPackQty SPQ on OD.SKUId = SPQ.SKUId
      where (coalesce(OD.UnitsPerCarton, 0) = 0);

      /* If we still do not have UnitsPerCarton, then assume it to be of others of same style i.e. SKU1 */
      update #OrderDetails
      set UnitsPerCarton = (select Top 1 OD2.UnitsPerCarton from #OrderDetails OD2 where OD2.SKU1 = SKU1 and OD2.UnitsPerCarton > 0)
      where (coalesce(UnitsPerCarton, 0) = 0);
    end

  /* Update the NumLPNs, NumUnits */
  update #OrderDetails
  set NumLPNs        = case when UoM = 'EA' and UnitsPerCarton > 0 then UnitsAuthorizedToShip /UnitsPerCarton
                            else UnitsAuthorizedToShip end,
      NumInnerPacks  = case when UnitsPerInnerPack > 0 then UnitsAuthorizedToShip/ UnitsPerInnerPack
                            else UnitsAuthorizedToShip end,
      NumUnits       = case when UoM = 'EA' then UnitsAuthorizedToShip
                            else UnitsAuthorizedToShip * UnitsPerCarton end

  select @vOrderLineCount = 0;

  /* Summarize Order details to categorize the order */
  select @vPickZoneCount    = count(distinct PickZone),    /* PickZone Count */
         @vPickZone         = Min(PickZone),               /* Unique PickZone */
         @vStorageTypeCount = count(distinct StorageType), /* StorageType Count */
         @vStorageType      = Min(StorageType),            /* Unique StorageType */
         @vOrderLineCount   = count(*),
         @vSKUCount         = count(distinct SKUId),       /* Get SKU Count */
         @vLinesToShip      = sum(case when UnitsAuthorizedToShip > 0 then 1 else 0 end),
         @vSKUsToShip       = count(distinct case when UnitsAuthorizedToShip > 0 then SKUId else null end),
         @vNumLPNs          = sum(NumLPNs),
         @vNumInnerPacks    = sum(NumInnerPacks),
         @vNumUnits         = sum(NumUnits),
         @vTotalUnits       = sum(UnitsAuthorizedToShip),
         @vUoMCount         = count(distinct UoM),
         @vUoM              = min(UoM),
         @vSalesAmount      = sum(case
                                    when UoM = 'EA' then
                                    (UnitsAuthorizedToShip * coalesce(nullif(UnitSalePrice, 0), nullif(UnitPrice, 0), nullif(RetailUnitPrice, 0)))
                                  else
                                    (UnitsAuthorizedToShip * UnitsPerCarton * coalesce(nullif(UnitSalePrice, 0), nullif(UnitPrice, 0), nullif(RetailUnitPrice, 0)))
                                  end),
         @vTotalWeight      = sum(UnitsAuthorizedToShip * UnitWeight),
         @vTotalVolume      = sum(UnitsAuthorizedToShip * UnitVolume) *  0.000578704 /* convert from cu.in. to cu.ft. */
  from #OrderDetails;

  /* Get Order Header info to get other info */
  select @vSoldToId        = OH.SoldToId,
         @vShipToId        = OH.ShipToId,
         @vShipFrom        = OH.ShipFrom,
         @vShipVia         = OH.ShipVia,
         @vPickTicket      = OH.PickTicket,
         @vSalesOrder      = OH.SalesOrder,
         @vPickbatchNo     = OH.PickbatchNo ,
         @vDesiredShipDate = OH.DesiredShipDate,
         @vOrderType       = OH.OrderType,
         @vOrderStatus     = Status,
         @vOrderCategory1  = OH.OrderCategory1,
         @vOwnership       = Ownership,
         @vWarehouse       = Warehouse,
         @vBusinessUnit    = OH.BusinessUnit,
         @vAccount         = Account,
         @vFreightTerms    = FreightTerms,
         @vOHUDF1          = UDF1,
         @vOHUDF2          = UDF2,
         @vOHUDF3          = UDF3,
         @vOHUDF4          = UDF4,
         @vOHUDF5          = UDF5,
         @vOHUDF6          = UDF6,
         @vOHUDF7          = UDF7,
         @vOHUDF8          = UDF8,
         @vOHUDF9          = UDF9,
         @vOHUDF10         = UDF10,
         @vPreprocessFlag  = PreprocessFlag,
         @vHostNumLines    = HostNumLines,
         @vSourceSystem    = SourceSystem
  from OrderHeaders OH
  where (OH.OrderId = @OrderId);

  select @vShipToName          = Name,
         @vShipToReference1    = Reference1,
         @vShipToReference2    = Reference2,
         @vShipToState         = State,
         @vShipToCity          = City,
         @vShipToZip           = Zip,
         @vShipToCountry       = CountryCode,
         @vShipToAddressRegion = AddressRegion
  from vwShipToAddress
  where (ShipToId = @vShipToId);

  select @vCarrier               = Carrier,
         @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from ShipVias
  where (ShipVia = @vShipVia);

  /* If the specific order has notes or if there are customer notes, then flag
     the order as having notes */
  set @vOrderHasNotes = 'N';
  if (exists(select RecordId
             from Notes
              where  (((EntityType = 'PT') and
                       ((EntityId  = @OrderId) or (EntityKey = @vPickTicket))) or
                      ((EntityType = 'Cust') and
                       (EntityKey  = @vSoldToId)))))
    set @vOrderHasNotes = 'Y';

  /* Get control value */
  select @vODUniqueKey = dbo.fn_Controls_GetAsString('Import_OD', 'ODUniqueKey', 'PTHostOrderLine', @vBusinessUnit, '' /* UserId */) ;

  /* Prepare XML for rules */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('OrderId',            @OrderId) +
                           dbo.fn_XMLNode('PickTicket',         @vPickTicket) +
                           dbo.fn_XMLNode('SalesOrder',         @vSalesOrder) +
                           dbo.fn_XMLNode('Status',             @vOrderStatus) +
                           dbo.fn_XMLNode('OrderType',          @vOrderType) +
                           dbo.fn_XMLNode('OrderCategory1',     @vOrderCategory1) +
                           dbo.fn_XMLNode('OrderCategory2',     @vOrderCategory2) +
                           dbo.fn_XMLNode('ShipViaServiceType', 'ORD') +
                           dbo.fn_XMLNode('ShipFrom',           @vShipFrom) +
                           dbo.fn_XMLNode('PrevSoldToId',       @vSoldToId) +
                           dbo.fn_XMLNode('SoldToId',           @vSoldToId) +
                           dbo.fn_XMLNode('ShipToId',           @vShipToId) +
                           dbo.fn_XMLNode('ShipToCountry',      @vShipToCountry)  +
                           dbo.fn_XMLNode('ShipToState',        @vShipToState)  +
                           dbo.fn_XMLNode('ShipToCity',         @vShipToCity) +
                           dbo.fn_XMLNode('ShipToZip',          @vShipToZip)  +
                           dbo.fn_XMLNode('ShipVia',            coalesce(@vShipVia, '')) +
                           dbo.fn_XMLNode('Carrier',            coalesce(@vCarrier, '')) +
                           dbo.fn_XMLNode('IsSmallPackageCarrier', @vIsSmallPackageCarrier) +
                           dbo.fn_XMLNode('FreightTerms',       @vFreightTerms)  +
                           dbo.fn_XMLNode('Account',            @vAccount) +
                           dbo.fn_XMLNode('Ownership',          @vOwnership) +
                           dbo.fn_XMLNode('Warehouse',          @vWarehouse) +
                           dbo.fn_XMLNode('SourceSystem',       @vSourceSystem) +
                           dbo.fn_XMLNode('ShipDate',           convert(varchar(10), @vDesiredShipDate, 102)) +
                           dbo.fn_XMLNode('UDF1',               @vOHUDF1) +
                           dbo.fn_XMLNode('UDF2',               @vOHUDF2) +
                           dbo.fn_XMLNode('UDF3',               @vOHUDF3) +
                           dbo.fn_XMLNode('UDF4',               @vOHUDF4) +   -- ShipToDC
                           dbo.fn_XMLNode('UDF5',               @vOHUDF5) +
                           dbo.fn_XMLNode('UDF6',               @vOHUDF6) +
                           dbo.fn_XMLNode('UDF7',               @vOHUDF7) +
                           dbo.fn_XMLNode('UDF8',               @vOHUDF8) +
                           dbo.fn_XMLNode('UDF9',               @vOHUDF9) +
                           dbo.fn_XMLNode('UDF10',              @vOHUDF10) +
                           dbo.fn_XMLNode('UDF20',              @vOHUDF20) +
                           dbo.fn_XMLNode('PreprocessFlag',     @vPreprocessFlag) +
                           dbo.fn_XMLNode('OrderWeight',        @vTotalWeight) +
                           dbo.fn_XMLNode('OrderLineCount',     @vOrderLineCount) +
                           dbo.fn_XMLNode('NumSKUs',            @vSKUCount) +
                           dbo.fn_XMLNode('LinesToShip',        @vLinesToShip) +
                           dbo.fn_XMLNode('SKUsToShip',         @vSKUsToShip) +
                           dbo.fn_XMLNode('HostNumLines',       @vHostNumLines) +
                           dbo.fn_XMLNode('ODUniqueKey',        @vODUniqueKey) +
                           dbo.fn_XMLNode('Operation',          @vOperation) +
                           dbo.fn_XMLNode('BusinessUnit',       @vBusinessUnit));

  /* Insert the Error messages into temp table */
  delete from #Validations;
  exec pr_RuleSets_ExecuteRules 'OH_PreprocessValidations', @xmlRulesData;

  /* Get the SoldTo based on the rules */
  exec pr_RuleSets_Evaluate 'SoldToId' /* RuleSetType */, @xmlRulesData, @vNewSoldToId output, @StuffResult = 'Y';

  /* Get the ShipFrom based on the Ownership & rules */
  exec pr_RuleSets_Evaluate 'ShipFrom' /* RuleSetType */, @xmlRulesData output, @vShipFrom output, @StuffResult = 'Y';

  exec pr_RuleSets_ExecuteRules 'OH_ManageAddresses', @xmlRulesData;

  /* Get SoldToName from Contacts */
  select @vSoldToName = Name
  from Contacts
  where (ContactRefId = coalesce(@vNewSoldToId, @vSoldToId)) and (ContactType = 'C' /* Customer */);

  select @vComputeShipVia = dbo.fn_Controls_GetAsString('ShipViaService', 'ComputeOnOrderPreProcess',
                                                        'Y', @vBusinessUnit, 'CIMSAgent');

  /* If the Order does not have ShipVia specified and control var says we have to compute it then do so
     TD- If we need to recalculate shpvia for all orders(if the shipvia exists or not) then we need to remove the below condition  */
  if (@vComputeShipVia = 'Y') --and (coalesce(@vShipVia, '') = '')
    exec pr_RuleSets_Evaluate 'GetShipVia' /* RuleSetType */, @xmlRulesData, @vNewShipVia output;

  /* Get the RoutingRule to be applied */
  exec pr_RuleSets_Evaluate 'GetRouting' /* RuleSetType */, @xmlRulesData, @vRoutingRuleId output;

  if (@vRoutingRuleId is not null)
    begin
      select @vNewShipVia       = nullif(ShipVia, ''),
             @vNewFreightTerms  = nullif(FreightTerms, ''),
             @vNewBillToAccount = nullif(BillToAccount, '')
      from RoutingRules
      where (RecordId = @vRoutingRuleId);

      /* If the rule says the new Shipvia is $, it means we do not want to change ShipVia on such Orders */
      if (@vNewShipvia = '$') select @vNewShipVia = null;
    end

  if (@vNewShipVia is not null)
    begin
      select @vNewCarrier            = Carrier,
             @vIsSmallPackageCarrier = IsSmallPackageCarrier
      from ShipVias
      where ShipVia = @vNewShipVia;

      select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'ShipVia', @vNewShipVia);
      select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'Carrier', @vNewCarrier)
      select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'IsSmallPackageCarrier', @vIsSmallPackageCarrier);
    end

  /* Get FreightTerms based on the rules */
  exec pr_RuleSets_Evaluate 'GetFreightTerms' /* RuleSetType */, @xmlRulesData, @vNewFreightTerms output;

  /* Get the BillToAccount based on the rules */
  exec pr_RuleSets_Evaluate 'GetBillToAccount' /* RuleSetType */, @xmlRulesData, @vNewBillToAccount output;

  /* Get ReturnLabel Required flag */
  exec pr_RuleSets_Evaluate 'ReturnLabels' /* RuleSetType */, @xmlRulesData, @vReturnLabelRequired output;

  /* Determine Order Type stuff into XML for further evaluation of other rules  */
  exec pr_RuleSets_Evaluate 'OrderType', @xmlRulesData output, @vOrderType output, @StuffResult = 'Y';

  /* Return the value of priority based on the shipvia  */
  exec pr_RuleSets_Evaluate 'OrderPriority', @xmlRulesData, @vOrderPriority output;
  select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'Priority', cast(coalesce(@vOrderPriority, 5) as varchar(3)));

  /* Determine the order categories based on the numskus and numunits etc.  */
  exec pr_RuleSets_Evaluate 'OrderCategory1', @xmlRulesData output, @vOrderCategory1 output, @StuffResult = 'Y';
  exec pr_RuleSets_Evaluate 'OrderCategory2', @xmlRulesData output, @vOrderCategory2 output, @StuffResult = 'Y';

  /* Return the value of category based on the numskus and numunits  */
  exec pr_RuleSets_Evaluate 'PriceStickers', @xmlRulesData, @vPriceStickersFormat output;

  /* Get the pick batch group - this has to be done at the end as above fields may be used in the grouping */
  exec pr_RuleSets_Evaluate 'WaveGrouping' /* RuleSetType */, @xmlRulesData, @vPickBatchGroup output;

  /* Get the Preprocess Flag */
  exec pr_RuleSets_Evaluate 'PreprocessFlag' /* RuleSetType */, @xmlRulesData, @vPreprocessFlag output;

  /* Check if there are any updates to be done in preprocess */
  exec pr_RuleSets_ExecuteAllRules 'OH_PreprocessUpdates', @xmlRulesData, @vBusinessUnit;

  /* Save the validations into Notifications. Even if there are no validations, we need to call
     this so that the earlier setup validations will be disabled */
  exec pr_Notifications_SaveValidations 'Order', @OrderId, @vPickTicket, 'NO', 'OrderPreprocess', @vBusinessUnit, 'CIMSAgent';

  /* Verify if the customer is of drop ship customer */
  select @vDropShipFrom = dbo.fn_Controls_GetAsString('DropShip', @vSoldToId, '' /* Default */, @vBusinessUnit, '' /* @vUserId */);

  /* if drop ship customer and ShipVia is SmallPackage carrier (FedEx or UPS) - get other details */
  if (coalesce(@vDropShipFrom, '') <> '')
    select @vNewFreightTerms = '3RDPARTY';

  /* Update the Customer SKU with Master Item if CustSKU is not downloaded : TD specific */
  update OrderDetails
  set --UnitsPerCarton    = TOD.UnitsPerCarton,
      UnitsPerInnerPack = TOD.UnitsPerInnerPack,
      PickBatchGroup    = coalesce(@vPickBatchGroup, ''), -- Varies between customer to customer. some customers requires this - @vShipToId
      LocationId        = TOD.LocationId,
      Location          = TOD.Location,
      PickZone          = TOD.PickZone,
      InventoryClass1   = coalesce(InventoryClass1, ''),
      InventoryClass2   = coalesce(InventoryClass2, ''),
      InventoryClass3   = coalesce(InventoryClass3, ''),
      UDF9              = TOD.UDF9,
      SKU               = TOD.SKU,
      SKU1              = TOD.SKU1,
      SKU2              = TOD.SKU2,
      SKU3              = TOD.SKU3,
      SKU4              = TOD.SKU4,
      SKU5              = TOD.SKU5,
      ModifiedDate      = current_timestamp,
      ModifiedBy        = 'CIMSAgent'
  from OrderDetails OD
    join #OrderDetails TOD on OD.OrderDetailId = TOD.OrderDetailId
  where (OrderId = @OrderId);

  /* By this time we would know whether if there are any pick bins set up for the ordered SKUs,
     if the pick bins are set up then update Pickzones on the OH */
  if (@vPickZoneCount > 1)
    select @vMultiplePickZones = stuff((select distinct '-' + PickZone from #OrderDetails
                                                                        where PickZone is not null
                                                                        for XML PATH(''), type
                                       ).value('.','TVarchar'), 1, 1,'');

  /* Update OrderHeaders.PickZone with OD.PickZone, if the Order has all details from one zone,
     if the order has details from two zones, set it to be Zone1 + Zone 2, if Order has details from
     more than two zones, then set to 'Multiple'

     Similarly, Orderheaders.UDF4 will have StorageType */
  update OrderHeaders
  set PickZone            = case
                              when @vPickZoneCount = 1 then @vPickZone
                              when @vPickZoneCount = 2 then @vMultiplePickZones
                              else 'Multiple'
                            end,
      NumSKUs             = @vSKUCount,            /* No of SKUs in the Order */
      --NumLPNs           = @vNumLPNs,             /* Estimated LPNs To Ship for the Order */
      NumLPNs             = @vNumInnerPacks,
      NumUnits            = @vNumUnits,            /* Total Units To Ship for the Order */
      NumLines            = @vOrderLineCount,      /* No Of Lines in the Order */
      Priority            = coalesce(nullif(@vOrderPriority, 0), nullif(Priority, 0), 5), /* Default it set to 5 if it is null */
      /* if there are validation failures, then revert status to Downloaded */
      Status              = case when exists (select * from #Validations where MessageType = 'E' /* Error */) then 'O' /* Downloaded */
                                 when Status = 'O' /* Downloaded */ then 'N' /* New/Initial */
                                 else Status
                            end,
      HasNotes            = @vOrderHasNotes,
      ShipComplete        = 'N' /* No - CIMS, Yes - NBD */,
      ShipToStore         = coalesce(nullif(ShipToStore,     ''), @vShipToReference1),
      ShipFrom            = coalesce(nullif(@vDropShipFrom, ''), @vShipFrom, ShipFrom),
      SoldToId            = coalesce(nullif(@vNewSoldToId, ''), @vSoldToId, nullif(SoldToId, '')),
      SoldToName          = coalesce(@vSoldToName, nullif(SoldToName, '')),
      ShipToId            = coalesce(nullif(ShipToId,  ''), @vShipToId),
      ShipToName          = coalesce(@vShipToName, nullif(ShipToName, '')),
      /* Preserve host sent in SoldToId in case CIMS changes as per rules */
     -- UDF30               = case when (@vNewSoldToId <> SoldToId) then @vSoldToId end,
      FreightTerms        = coalesce(nullif(@vNewFreightTerms,  ''), nullif(FreightTerms, ''), 'SENDER' /* Default it to Sender */),
      BillToAccount       = coalesce(@vNewBillToAccount, nullif(@vBillToAccount, ''), BillToAccount), /* If any Rule matched then update with that, else update with Control value and then existing */
      BillToAddress       = coalesce(nullif(@vDropShipFrom,  ''), BillToAddress),
      ShipVia             = coalesce(nullif(@vNewShipVia, ''), ShipVia), /* Update with ShipVia returned from the rules */
      TotalSalesAmount    = @vSalesAmount,
      TotalWeight         = @vTotalWeight,
      TotalVolume         = @vTotalVolume,
      PickBatchGroup      = coalesce(@vPickBatchGroup, ''),
      PreprocessFlag      = coalesce(nullif(@vPreprocessFlag, ''), PreProcessFlag),
      ReturnLabelRequired = coalesce(@vReturnLabelRequired, ReturnLabelRequired),
      OrderDate           = coalesce(OrderDate, CreatedDate),
      OrderCategory1      = coalesce(@vOrderCategory1, OrderCategory1),
      OrderCategory2      = coalesce(@vOrderCategory2, OrderCategory2),
      UDF20               = coalesce(nullif(UDF20, ''), @vShipVia), -- save original value from Host for reference
      OrderType           = coalesce(@vOrderType, OrderType),
      CustPO              = dbo.fn_RemoveSpecialChars(CustPO),
      PriceStickerFormat  = @vPriceStickersFormat,
      ModifiedDate        = current_timestamp,
      ModifiedBy          = 'CIMSAgent'
  where (OrderId = @OrderId);

  /* Invoke proc that updates estimated cartons on Order Headers table */
  insert into #OrdersToEstimateCartons (EntityId) select @OrderId;
  exec pr_OrderHeaders_EstimateCartons @vBusinessUnit, @vUserId;

  /* if Order is already on a batch, recalculate batch counts */
  if (coalesce(@vPickbatchNo, '') <> '')
    exec pr_PickBatch_UpdateCounts @vPickBatchNo;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_Preprocess */

Go
