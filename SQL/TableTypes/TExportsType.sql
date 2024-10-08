/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/08/25  AJM     TExportsType: Added CreatedDate (portback from prod) (BK-904)
  2022/08/18  VS      TExportsType: Added Comments field (BK-885)
  2021/03/02  PK      Added ClientLoad to TExportsType table domain (HA-2109)
  2021/02/20  PK      Added DesiredShipDate to TExportsType table domain (HA-2029)
  2020/01/22  AY      TExportsType: Added NumPallets, NumLPNs, NumCartons, Quantity (HA-1896)
  TOnhandInventoryExportType, TOrderDetailsImportType, TExportsType: Added InventoryClass1 to InventoryClass3
  2019/11/28  RKC     TExportsType:Added ShipToAddressLine1, ShipToAddressLine2, ShipToCity, ShipToState, ShipToCountry, ShipToZip,
  2018/03/21  SV      TOpenOrderExportType, TOpenReceiptExportType, TExportsType Added SourceSystem field (S2G-379)
  2018/03/15  SV      TExportsType: Added the missing fields to send the complete exports to DE db (S2G-379)
  Create Type TExportsType as Table
  Grant References on Type:: TExportsType to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type to use for Export date to host
   This table structure mimics the record structure of Exports, with few additional fields to store data etc.,
   If you make any changes to the order of the fields, you ought to make the same in pr_Exports_GetData */
Create Type TExportsType as Table
  (
    /* Transaction */
    RecordType               TTypeCode,
    ExportBatch              TBatch,
    TransDate                Date,
    TransDateTime            TDateTime,
    TransQty                 TQuantity,
    /* SKU */
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,
    Description              TDescription,
    UoM                      TUoM,
    UPC                      TUPC,
    Brand                    TBrand,
    /* LPN */
    LPN                      TLPN,
    LPNType                  TTypeCode,
    ASNCase                  TASNCase,
    UCCBarcode               TBarcode,
    TrackingNo               TTrackingNo,
    CartonDimensions         TDescription,
    /* Counts */
    NumPallets               TCount,
    NumLPNs                  TCount,
    NumCartons               TCount,
    /* LPN Details */
    LPNLine                  TDetailLine,
    Innerpacks               TInteger,
    Quantity                 TInteger,
    UnitsPerPackage          TInteger,
    SerialNo                 TSerialNo,
    /* Pallet & Location */
    Pallet                   TPallet,
    Location                 TLocation,
    HostLocation             TLocation,
    /* Receiver */
    ReceiverNumber           TReceiverNumber,
    ReceiverDate             TDateTime,
    ReceiverBoL              TBoLNumber,
    ReceiverRef1             TDescription,
    ReceiverRef2             TDescription,
    ReceiverRef3             TDescription,
    ReceiverRef4             TDescription,
    ReceiverRef5             TDescription,
    /* From RH */
    ReceiptNumber            TReceiptNumber,
    ReceiptType              TTypeCode,
    VendorId                 TVendorId,
    ReceiptVessel            TVessel,
    ReceiptContainerNo       TContainer,
    ReceiptContainerSize     TContainerSize,
    ReceiptBillNo            TBolNumber,
    ReceiptSealNo            TSealNumber,
    ReceiptInvoiceNo         TInvoiceNo,
    /* RO Detail info */
    HostReceiptLine          THostReceiptLine,
    CoO                      TCoO,
    UnitCost                 TFloat,
    /* General */
    ReasonCode               TReasonCode,
    Warehouse                TWarehouse,
    Ownership                TOwnership,
    ExpiryDate               TDate,
    Lot                      TLot,
    InventoryClass1          TInventoryClass,
    InventoryClass2          TInventoryClass,
    InventoryClass3          TInventoryClass,
    Weight                   TWeight,
    Volume                   TVolume,
    Length                   TLength,
    Width                    TWidth,
    Height                   THeight,
    InnerPacksPerLPN         TInteger,
    UnitsPerInnerPack        TInteger,
    Reference                TReference,
    MonetaryValue            TMonetaryValue,
    /* Pick Ticket Info */
    PickTicket               TPickTicket,
    SalesOrder               TSalesOrder,
    OrderType                TTypeCode,
    SoldToId                 TCustomerId,
    SoldToName               TName,
    ShipVia                  TShipVia,
    ShipViaDescription       TDescription,
    ShipViaSCAC              TTypeCode,
    ShipFrom                 TShipFrom,
    CustPO                   TCustPO,
    Account                  TCustomerId,
    AccountName              TName,
    FreightCharges           TMoney,
    FreightTerms             TDescription,
    BillToAccount            TBillToAccount,
    BillToName               TName,
    BillToAddress            TContactRefId,
    /* Order Details */
    HostOrderLine            THostOrderLine,
    UnitsOrdered             TQuantity,
    UnitsAuthorizedToShip    TQuantity,
    UnitsAssigned            TQuantity,
    CustSKU                  TCustSKU,
    /* Load */
    LoadNumber               TLoadNumber,
    ClientLoad               TLoadNumber,
    DesiredShipDate          TDateTime,
    ShippedDate              TDateTime,
    BoL                      TBoL,
    LoadShipVia              TShipVia,
    TrailerNumber            TTrailerNumber,
    ProNumber                TProNumber,
    SealNumber               TSealNumber,
    MasterBoL                TBoLNumber,
    /* Transfers related */
    FromWarehouse            TWarehouse,
    ToWarehouse              TWarehouse,
    FromLocation             TLocation,
    ToLocation               TLocation,
    FromSKU                  TSKU,
    ToSKU                    TSKU,
    /* EDI related */
    EDIShipmentNumber        TVarchar,
    EDITransCode             TTypeCode,
    EDIFunctionalCode        TTypeCode,

    /* ShipToAddress */
    ShipToId                 TShipToId,
    ShipToName               TName,
    ShipToAddressLine1       TAddressLine,
    ShipToAddressLine2       TAddressLine,
    ShipToCity               TCity,
    ShipToState              TState,
    ShipToCountry            TCountry,
    ShipToZip                TZip,
    ShipToPhoneNo            TPhoneNo,
    ShipToEmail              TEmailAddress,
    ShipToReference1         TDescription,
    ShipToReference2         TDescription,

    Comments                 TVarchar,

    SKU_UDF1                 TUDF,
    SKU_UDF2                 TUDF,
    SKU_UDF3                 TUDF,
    SKU_UDF4                 TUDF,
    SKU_UDF5                 TUDF,
    SKU_UDF6                 TUDF,
    SKU_UDF7                 TUDF,
    SKU_UDF8                 TUDF,
    SKU_UDF9                 TUDF,
    SKU_UDF10                TUDF,

    LPN_UDF1                 TUDF,
    LPN_UDF2                 TUDF,
    LPN_UDF3                 TUDF,
    LPN_UDF4                 TUDF,
    LPN_UDF5                 TUDF,

    LPND_UDF1                TUDF,
    LPND_UDF2                TUDF,
    LPND_UDF3                TUDF,
    LPND_UDF4                TUDF,
    LPND_UDF5                TUDF,

    RH_UDF1                  TUDF,
    RH_UDF2                  TUDF,
    RH_UDF3                  TUDF,
    RH_UDF4                  TUDF,
    RH_UDF5                  TUDF,

    RD_UDF1                  TUDF,
    RD_UDF2                  TUDF,
    RD_UDF3                  TUDF,
    RD_UDF4                  TUDF,
    RD_UDF5                  TUDF,

    OH_UDF1                  TUDF,
    OH_UDF2                  TUDF,
    OH_UDF3                  TUDF,
    OH_UDF4                  TUDF,
    OH_UDF5                  TUDF,
    OH_UDF6                  TUDF,
    OH_UDF7                  TUDF,
    OH_UDF8                  TUDF,
    OH_UDF9                  TUDF,
    OH_UDF10                 TUDF,
    OH_UDF11                 TUDF,
    OH_UDF12                 TUDF,
    OH_UDF13                 TUDF,
    OH_UDF14                 TUDF,
    OH_UDF15                 TUDF,
    OH_UDF16                 TUDF,
    OH_UDF17                 TUDF,
    OH_UDF18                 TUDF,
    OH_UDF19                 TUDF,
    OH_UDF20                 TUDF,
    OH_UDF21                 TUDF,
    OH_UDF22                 TUDF,
    OH_UDF23                 TUDF,
    OH_UDF24                 TUDF,
    OH_UDF25                 TUDF,
    OH_UDF26                 TUDF,
    OH_UDF27                 TUDF,
    OH_UDF28                 TUDF,
    OH_UDF29                 TUDF,
    OH_UDF30                 TUDF,

    OD_UDF1                  TUDF,
    OD_UDF2                  TUDF,
    OD_UDF3                  TUDF,
    OD_UDF4                  TUDF,
    OD_UDF5                  TUDF,
    OD_UDF6                  TUDF,
    OD_UDF7                  TUDF,
    OD_UDF8                  TUDF,
    OD_UDF9                  TUDF,
    OD_UDF10                 TUDF,
    OD_UDF11                 TUDF,
    OD_UDF12                 TUDF,
    OD_UDF13                 TUDF,
    OD_UDF14                 TUDF,
    OD_UDF15                 TUDF,
    OD_UDF16                 TUDF,
    OD_UDF17                 TUDF,
    OD_UDF18                 TUDF,
    OD_UDF19                 TUDF,
    OD_UDF20                 TUDF,

    LD_UDF1                  TUDF,
    LD_UDF2                  TUDF,
    LD_UDF3                  TUDF,
    LD_UDF4                  TUDF,
    LD_UDF5                  TUDF,
    LD_UDF6                  TUDF,
    LD_UDF7                  TUDF,
    LD_UDF8                  TUDF,
    LD_UDF9                  TUDF,
    LD_UDF10                 TUDF,

    EXP_UDF1                 TUDF,
    EXP_UDF2                 TUDF,
    EXP_UDF3                 TUDF,
    EXP_UDF4                 TUDF,
    EXP_UDF5                 TUDF,
    EXP_UDF6                 TUDF,
    EXP_UDF7                 TUDF,
    EXP_UDF8                 TUDF,
    EXP_UDF9                 TUDF,
    EXP_UDF10                TUDF,
    EXP_UDF11                TUDF,
    EXP_UDF12                TUDF,
    EXP_UDF13                TUDF,
    EXP_UDF14                TUDF,
    EXP_UDF15                TUDF,
    EXP_UDF16                TUDF,
    EXP_UDF17                TUDF,
    EXP_UDF18                TUDF,
    EXP_UDF19                TUDF,
    EXP_UDF20                TUDF,
    EXP_UDF21                TUDF,
    EXP_UDF22                TUDF,
    EXP_UDF23                TUDF,
    EXP_UDF24                TUDF,
    EXP_UDF25                TUDF,
    EXP_UDF26                TUDF,
    EXP_UDF27                TUDF,
    EXP_UDF28                TUDF,
    EXP_UDF29                TUDF,
    EXP_UDF30                TUDF,

    ShipmentId               TRecordId,
    LoadId                   TRecordId,

    SourceSystem             TName,
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,
    CIMSRecId                TRecordId,

    RecordId                 TRecordId      identity (1,1) not null

    Primary Key              (RecordId)
  );

Grant References on Type:: TExportsType to public;

Go
