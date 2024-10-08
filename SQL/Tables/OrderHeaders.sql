/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/05/16  SK      ix_OrderHeaders_Archived: Added OrderId (BK-1114)
  2023/10/18  YAN     OrderHeaders: Added PTShipStatus (JLCA-1144)
  2023/08/22  YAN     OrderHeaders: Added ShippedOn (OBV3-1923)
  2023/03/09  TK      OrderHeaders & OrderDetails: Added fields need for order consolidation (FBV3-1522)
  2023/01/19  VS      OrderHeaders: Added Currency (OBV3-1684)
  2022/12/09  RKC     OrderHeaders: ix_OrderHeaders_PreprocessFlag: Included PickBatchId (CIMSV3-2396)
  2022/12/08  RKC     OrderHeaders: Added StatusGroup (OBV3-1559)
  2022/09/27  AY      OrderHeaders: ix_OrderHeaders_WaveNo: Added NumUnits and WaveFlag in the Includes in this index: Ported changes (CIMSV3-2281)
  2022/07/22  RKC     OrderHeaders: ix_OrderHeaders_Archived: Included SourceSystem (CIMSV3-2142)
  2022/06/27  SUC     OrderHeaders:Changed the fieldname PickZone to PickZones (CIMSV3-2102)
  2022/05/31  AY      OrderHeaders: Change datatype of PickZone (OBV3-656)
  2021/10/12  SJ      OrderHeaders: Added EstimatedVolume & EstimatedWeight (OB2-2075)
  2021/09/14  AY      OrderHeaders: Added ShipToCityState (HA-3160)
  2021/08/11  AY      OrderHeaders: Revised indices as per MSSQL recommentation (HA-3076)
  2021/08/02  SJ      OrderHeaders: Added FillRatePercent (OB2-1971)
  2021/04/21  PK/YJ   OrderHeaders: ix_OrderHeaders_Archived: ported changes from prod onsite (HA-2678)
  2021/04/20  TK      OrderHeaders: Added IsMultiShipmentOrder (HA-2641)
  2021/02/18  MS      OrderHeaders: Added WaveSeqNo, LoadSeqNo (BK-174)
  2021/02/03  TK      OrderHeaders: Added EstimatedCartons (HA-1964)
  2020/08/18  SK      OrderHeaders: Add new column TotalShipmentValue (HA-1267)
  2020/06/30  RKC     OrderHeaders: Add ModifiedOn computed column and index (CIMS-3118)
  2020/05/28  OK      OrderHeaders: Added ShipFromCompanyId (HA-657)
  AY      OrderHeaders: Added UCC128, ContentsLabel and PackingList formats
  2019/12/25  AY      OrderHeaders: Added SoldToName as it is a commonly used field and will be setup in Preprocess
  2019/09/06  AY      OrderHeaders: Revised indices (CID-1022)
  2019/08/21  RKC     OrderHeaders: Changed ixOrderHeadersArchived to include OrderType as well (CID-923)
  2019/07/15  SDC     OrderHeaders: Added PackedDate (CID-776)
  2019/07/05  SPP     OrderHeaders: Added ix_OrderHeaders_WaveId (CID-136) (Ported from Prod)
  2019/06/20  AY      OrderHeaders: Changed ShipCompletePercent to TPercent (CID-582)
  2019/05/14  VS      OrderHeaders: Added ix_OrderHeaders_UDFs index for consoldiated Orders(CID-334)
  2019/01/29  YJ      OrderHeaders: Added LoadId, LoadNumber (S2G-1197)
  2019/01/04  MJ      OrderHeaders: Added NB4Date and changed the fields order (S2G-1075)
  2018/12/06  RV      OrderHeaders: Added ShipperAccountName (S2GCA-434)
  2018/11/28  RV      OrderHeaders: Added AESNumber, ShipmentRefNumber (S2G-1177)
  2018/09/24  TK      OrderHeaders: Added CartonGroups (HPI-2047)
  2018/09/18  MJ      OrderHeaders: Added NB4Date (S2G-1075)
  2018/07/25  VM      OrderHeaders: Added NumCases (S2G-1006)
  2018/05/07  AY      OrderHeaders: Added LoadGroup (S2G-830)
  2018/03/16  AY      OrderHeaders: Added HostNumLines, SourceSystem (FB-1114)
  2017/09/06  DK      OrderHeaders: Added CarrierOptions (FB-1020)
  2017/08/22  SP      OrderHeaders: Added UDF11 - UDF30 (OB-548)
  2017/03/28  NB      OrderHeaders: Added DeliveryRequirement(CIMS-1259)
  2017/02/20  YJ      OrderHeaders: Added fields DownloadedDate, QualifiedDate (HPI-1382)
  2017/01/05  ??      OrderHeaders: Added index ix_OrderHeadersCustPO (HPI-GoLive)
  2016/12/16  SV      OrderHeaders: Added ProcessOperation (HPI-1175)
  2016/12/10  AY      OrderHeaders: Added PrevWaveNo to be able to cancel and re-do waves (HPI-GoLive)
  2016/12/06  PK      OrderHeaders: Added UDF11 - UDF20.
  2016/05/04  TD      OrderHeaders: PriceStickerFormat.
  2016/03/31  SV      OrderHeaders: Added WaveFlag (NBD-321)
  2015/09/25  KN      OrderHeaders: Added ReturnLabelRequired (FB-386)
  2015/09/14  YJ      OrderHeaders: Added ReceiptNumber (FB-381)
  2014/06/02  NB      OrderHeaders: Added PreprocessFlag
  2014/04/11  TD      OrderHeaders: Added PickBatchId.
  2014/02/27  DK      OrderHeaders: Added HasNotes field
  2013/06/21  SP      OrderHeaders: Added ExchangeStatus field.
  2013/04/04  AY      OrderHeaders: Added FreightCharges, FreightTerms, BillToAccount, BillToAddress.
  2013/03/21  TD      OrderHeaders: Added TotalWeight, TotalVolume.
  2013/02/08  PK      OrderHeaders: Added Account, AccountName, OrderCategory1, OrderCategory2,
  2012/09/29  AY      OrderHeaders: Added index by CustPO
  2012/09/13  AY      OrderHeaders: Added LPNsAssigned, ShipToStore
  2012/08/17  AY      OrderHeaders: Added index ixOrderHeadersShipTo, ixOrderHeadersSoldTo
  2012/07/15  AY      OrderHeaders: Added PickBatchGroup, TotalDiscount
  2012/07/11  AY      OrderHeaders: Added NumLPNs, Comments. OrderDetails UDF6..10
  2012/06/26  AY      OrderHeaders: Added MarkForAddress
  2012/06/20  AY      OrderHeaders: Added index ixOrderHeaderStatus
  2012/03/17  AY      OrderHeaders: Pick Zone, NumLines, NumSKU, NumUnits for OrderHeaders
  2011/11/28  AA      OrderHeaders: Added New Field ShortPick
  2011/10/12  AY      OrderHeaders: Added TotalTax, TotalShippingCost, TotalSalesAmount
  2011/10/10  VM      OrderHeaders: Added Warehouse
  2011/08/03  PK      OrderHeaders: Added PickBatchNo, ShipTos: Added Status.
  2011/07/08  PK      OrderHeaders: Added ReturnAddrId.
  OrderHeaders: Added Status
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: OrderHeaders

 PickBatchGroup: Depending upon the site, our clients would want to group Orders
   when creating PickBatches. For example - at Loehmanns, the Orders are grouped
   by PickZone, for TD - Orders are expected to be grouped by CustPO for Target,
   but ShipTo for JCPenny. Instead of changing the code for each - we now have
   this field on OrderHeader which would be used to generate PickBatches. This
   field would be determined in PreProcessOrders.

 Priority: Priority of the order to be processed, it is basically depends on the
   quanity ordered or the customer who is doing business regularly with the vendor.

 FreightCharges: Charges that will be applied to Order for shipping.

 CarrierOptions: This field would be a CSV of various values applicable as per the
                 carrier i.e. all options are not avaialable for all carriers. These
                 options include insurance required information, Signature required options.
                 see init_OrderInfo.sql for values used

  WaveSeqNo: The sequence number of the order in the Wave
  LoadSeqNo: The sequence in which the orders have to be loaded

  PTShipStatus:  Meant to be used to determine if the Order is qualified for shipping or not.
                 For example, there may be a credit hold on the customer and so it could be on hold
                 By default all Orders are qualified unless determined otherwise.
------------------------------------------------------------------------------*/
Create Table OrderHeaders (
    OrderId                  TRecordId      identity (1,1) not null,

    PickTicket               TPickTicket    not null,
    SalesOrder               TSalesOrder,
    OrderType                TOrderType,
    Status                   TStatus,

    OrderDate                TDateTime,  /* Date on which customer placed the order */
    NB4Date                  TDateTime,  /* The customer does not want the order to be shipped before this date */
    DesiredShipDate          TDateTime,  /* The target shipping date */
    CancelDate               TDateTime,
    DeliveryStart            TDateTime,
    DeliveryEnd              TDateTime,
    DownloadedDate           TDateTime,  /* Date the Order has been sent to the Warehouse */
    QualifiedDate            TDateTime,  /* The Date Order has been qualified where we have the inventory */
    PackedDate               TDateTime,

    Priority                 TPriority,

    SoldToId                 TCustomerId,  /* Customer Number */
    ShipToId                 TShipToId,    /* Id for the particular location */
    SoldToName               TName,
    ShipToName               TName,
    Account                  TAccount,
    AccountName              TName,
    ReturnAddress            TReturnAddress,
    MarkForAddress           TContactRefId,
    ShipToDC                 TShipToStore,
    ShipToStore              TShipToStore,
    ShipToCityState          TAddressLine,

    PickBatchId              TRecordId,
    PickBatchNo              TPickBatchNo,
    PrevWaveNo               TWaveNo,
    LoadId                   TLoadId,
    LoadNumber               TLoadNumber,

    ShipVia                  TShipVia,      /* Carrier codes(UPS) + Service level options(Ground) EX: UPSG */
    DeliveryRequirement      TDescription,  /* The expected delivery days/time i.e. 1;10:00AM is next day 10 AM */
    CarrierOptions           TDescription,
    ShipFrom                 TShipFrom,
    CustPO                   TCustPO,

    AESNumber                TAESNumber,
    ShipmentRefNumber        TShipmentRefNumber,

    VASCodes                 TVarchar, -- CSV of VAS Codes
    VASDescriptions          TVarchar, -- CSV of VAS Descriptions

    OrderCategory1           TOrderCategory,
    OrderCategory2           TOrderCategory,
    OrderCategory3           TOrderCategory,
    OrderCategory4           TOrderCategory,
    OrderCategory5           TOrderCategory,

    Ownership                TOwnership     not null,
    Warehouse                TWarehouse     not null,
    PickZone                 TZoneId,
    PickBatchGroup           TWaveGroup     default '',
    CartonGroups             TVarchar,
    LoadGroup                TLoadGroup     default '',
    StatusGroup              TStatusGroup   default '',

    ReturnLabelRequired      TFlag,
    IsMultiShipmentOrder     TFlag          default 'N',

    HostNumLines             TCount         default 0,  /* Host will send Number of Lines for the Order */
    NumLines                 TCount         default 0,  /* Number of Lines for the Order in CIMS */
    NumSKUs                  TCount         default 0,
    NumLPNs                  TCount         default 0,
    NumCases                 TCount         default 0,
    NumUnits                 TQuantity      default 0, /* UnitsOrdered */
    EstimatedCartons         TCount         default 0,

    LPNsAssigned             TCount         default 0,
    LPNsPicked               TCount         default 0,
    LPNsPacked               TCount         default 0,
    LPNsLoaded               TCount         default 0,
    LPNsStaged               TCount         default 0,
    LPNsShipped              TCount         default 0,

    UnitsAssigned            TQuantity      default 0,
    UnitsPicked              TQuantity      default 0,
    UnitsPacked              TQuantity      default 0,
    UnitsStaged              TQuantity      default 0,
    UnitsLoaded              TQuantity      default 0,
    UnitsShipped             TQuantity      default 0,

    EstimatedWeight          TWeight        default 0,
    EstimatedVolume          TVolume        default 0,
    TotalWeight              TWeight        default 0.0,
    TotalVolume              TVolume        default 0,
    TotalSalesAmount         TMoney, /* sum of Qty * UnitSalePrice) of all lines */
    TotalShipmentValue       TMoney, /* sum(OD.UnitsAssigned * OD.UnitSalePrice) */
    TotalTax                 TMoney,
    TotalShippingCost        TMoney,
    TotalDiscount            TMoney,
    Currency                 TCurrency      default 'USD',

    FreightCharges           TMoney,
    FreightTerms             TDescription,
    PaymentTerms             TDescription,
    BillToAccount            TBillToAccount,
    ShipperAccountName       TName,
    BillToAddress            TContactRefId,

    ShortPick                TFlag          default 'N',
    Comments                 TVarchar,
    HasNotes                 TFlag          default 'N',
    PreprocessFlag           TFlag          default 'N',
    ProcessOperation         TVarChar,
    ShipComplete             TFlag,         -- deprecated in favour of ShipCompletePercent
    ShipCompletePercent      TPercent,
    WaveFlag                 TFlag,

    PTShipStatus             TStatus        default 'Qualified To Ship',
    ShippedDate              TDateTime,
    ShipFromCompanyId        TBarcode,

    UCC128LabelFormat        TName,
    PackingListFormat        TName,
    ContentsLabelFormat      TName,
    PriceStickerFormat       TName,

    PrevStatus               TStatus,
    ExchangeStatus           TStatus,
    ReceiptNumber            TReceiptNumber,
    VendorNumber             TVendorNumber,

    SalesPerson              TName,
    Dept                     TDepartment,
    DeptDesc                 TDescription,
    Division                 TDescription,

    WaveSeqNo                TInteger,
    LoadSeqNo                TInteger,

    ConsolidationCriteria    TVarchar,
    ConsolidatedOrderId      TRecordId,
    ConsolidatedPickTicket   TPickTicket,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,
    UDF6                     TUDF,
    UDF7                     TUDF,
    UDF8                     TUDF,
    UDF9                     TUDF,
    UDF10                    TUDF,

    UDF11                    TUDF,
    UDF12                    TUDF,
    UDF13                    TUDF,
    UDF14                    TUDF,
    UDF15                    TUDF,
    UDF16                    TUDF,
    UDF17                    TUDF,
    UDF18                    TUDF,
    UDF19                    TUDF,
    UDF20                    TUDF,

    UDF21                    TUDF,
    UDF22                    TUDF,
    UDF23                    TUDF,
    UDF24                    TUDF,
    UDF25                    TUDF,
    UDF26                    TUDF,
    UDF27                    TUDF,
    UDF28                    TUDF,
    UDF29                    TUDF,
    UDF30                    TUDF,

    SourceSystem             TName          default 'HOST',
    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default getdate(),
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    CreatedOn                as convert(date, CreatedDate),
    ModifiedOn               as convert(date, ModifiedDate),
    DownloadedOn             as convert(date, DownloadedDate),
    ShippedOn                as convert(date, ShippedDate),
    FillRatePercent          as (case when (Numunits > 0) then (UnitsAssigned * 100) / (NumUnits) else 0 end),

    constraint pkOrderHeaders_OrderId    primary key (OrderId),
    constraint ukOrderHeaders_PickTicket unique (PickTicket, BusinessUnit)
);

create index ix_OrderHeaders_PT                  on OrderHeaders (PickTicket, BusinessUnit) include (OrderId, Status);
/* NumUnits and WaveFlag used in vwOrdersToBatch */
create index ix_OrderHeaders_WaveNo              on OrderHeaders (PickBatchNo, Status) include (OrderId, OrderType, BusinessUnit, NumUnits, WaveFlag);
create index ix_OrderHeaders_Status              on OrderHeaders (Status, PickBatchNo) include (OrderId, PickTicket, PickBatchId, NumLPNs, NumUnits, BusinessUnit);
/* Used for pr_Replenish_GenerateOrders */
create index ix_OrderHeaders_OrderType           on OrderHeaders (Archived, OrderType, Status, BusinessUnit) include (OrderId, Ownership, OrderCategory5, ModifiedOn);
/* Include WH as default query from UI includes user WH */
create index ix_OrderHeaders_Archived            on OrderHeaders (Archived, BusinessUnit, Status) include (OrderId, OrderType, Warehouse, SourceSystem) where (Archived ='N');
create index ix_OrderHeaders_ShipTo              on OrderHeaders (ShipToId, Status);
create index ix_OrderHeaders_SoldTo              on OrderHeaders (SoldToId, Status);
create index ix_OrderHeaders_SalesOrder          on OrderHeaders (SalesOrder, BusinessUnit, Status) include (OrderType, OrderId, Ownership, Warehouse);
create index ix_OrderHeaders_CustPO              on OrderHeaders (CustPO, PickBatchNo, Status);
/* For Shipping Dashboard */
create index ix_OrderHeaders_PreprocessFlag      on OrderHeaders (PreprocessFlag, Status) include(OrderId, PickTicket, PickBatchId);
create index ix_OrderHeaders_OrderDate           on OrderHeaders (OrderDate) include (Status, OrderId);
create index ix_OrderHeaders_Account             on OrderHeaders (Account) include (Status, OrderId, PreprocessFlag, NumUnits, Archived, OrderDate, PickTicket, OrderType, AccountName);
create index ix_OrderHeaders_WaveId              on OrderHeaders (PickBatchId, Status, OrderType) include (OrderId, NumUnits, UnitsAssigned);
create index ix_OrderHeaders_DownloadedOn        on OrderHeaders (DownloadedOn, Archived) include (OrderId);

Go
