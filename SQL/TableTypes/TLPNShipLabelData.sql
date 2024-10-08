/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/04  MS      TLPNShipLabelData: Added new fields WaveSeqNo & NumOrders (BK-344)
  2020/10/20  PK      TLPNShipLabelData: Included OD_UDF11..OD_UDF30 - Port back from HA Prod/Stag by VM (HA-1483)
  2020/07/09  VM      TLPNShipLabelData: Add CustSKU (Deprecate CustomerSKU) (HA-1130)
  2020/07/07  VM      TLPNShipLabelData: Add LPNNumLines,LPNNumSKUs,LPNNumSizes (HA-1072)
  2020/06/30  VM      TLPNShipLabelData: Add SCCBarcode (HA-1037)
  2020/06/26  VM      TLPNShipLabelData: Add OH_UDF11..OH_UDF30 (HA-1037)
  2020/06/25  VM      TLPNShipLabelData: Added SKUSizeScale, SKUSizeSpread (HA-1013)
  2020/05/26  RV      TLPNShipLabelData: Commented out Label image type - causing conversion issue (HA-667)
  2020/01/07  MJ      TLPNContentsLabelData, TLPNShipLabelData: Added ShipToAddress3 (CID-1240)
  2019/07/30  PHK     TLPNShipLabelData : Added WaveType (CID-751)
  2019/07/16  AY/RV   TLPNShipLabelData: Changed ShipVia domain type to TShipVia (CID-806)
  2019/04/24  MS      Added LPNWeight in TLPNShipLabelData (CID-420)
  2019/04/18  RV      TLPNShipLabelData: Added Label and IsValidTrackingnNo (CID-210)
  2019/03/26  MJ      TLPNShipLabelData: Added AlternateLPN (CID-209)
  2019/03/19  MJ      TLPNShipLabelData: Added UOM (CID-174)
  2018/05/10  MJ      TLPNShipLabelData: Added required fields (S2G-803)
  2018/04/05  MJ      Added field MarkForAddress in TLPNShipLabelData (SRI-862)
  2016/06/27  PSK     TLPNShipLabelData: Added LPNLot (HPI-173).
  2016/06/19  DK      TLPNShipLabelData: Added Account and AccountName (HPI-169)
  2015/10/27  AY      TLPNShipLabelData: Added new fields to be in sync with procedure
  2015/06/14  VM      TLPNShipLabelData: Fieds considered as case sensitive in bartender label, hence corrected NumberofCartons
  2015/02/06  PKS     TLPNShipLabelData:Added Warehouse.
  2014/09/11  PK      TLPNShipLabelData: TaskId
  2014/07/30  PKS     TLPNShipLabelData: Added PickZone, PickedBy, Location Row, Level and Section
  If an new field is added to TLPNShipLabelData,
  Create Type TLPNShipLabelData as Table (
  Grant References on Type:: TLPNShipLabelData to public;
  with TLPNShipLabelData so the fields should not repeat and hence any common
------------------------------------------------------------------------------*/

Go

/* !!!! WARNING !!!WARNING !!!WARNING !!!
   If an new field is added to TLPNShipLabelData,
   pr_ShipLabel_GetLPNData should be updated to return the new field as well in its return dataset
   Otherwise, there will be issues in callers. One is Printing labels from ShippingDocs - pr_ShipLabel_GetLPNDataXML calls it */
Create Type TLPNShipLabelData as Table (
    ShipFromName             TName,
    ShipFromAddress1         TAddressLine,
    ShipFromAddress2         TAddressLine,
    ShipFromCity             TCity,
    ShipFromState            TState,
    ShipFromZip              TZip,
    ShipFromCountry          TCountry,
    ShipFromCSZ              TCityStateZip,
    ShipFromPhoneNo          TPhoneNo,
    /* Mark for information */
    MarkForAddress           TContactRefId,
    MarkforName              TName,
    MarkforStore             TShipToStore,
    MarkforAddress1          TAddressLine,
    MarkforAddress2          TAddressLine,
    MarkforCity              TCity,
    MarkforState             TState,
    MarkforZip               TZip,
    MarkforCSZ               TCityStateZip,
    MarkForReference1        TDescription,
    MarkForReference2        TDescription,
    /* ShipTo information.*/
    ShipToId                 TShipToId,
    ShipToName               TName,
    ShipToStore              TShipToStore,
    ShipToAddress1           TAddressLine,
    ShipToAddress2           TAddressLine,
    ShipToAddress3           TAddressLine,
    ShipToCity               TCity,
    ShipToState              TState,
    ShipToZip                TZip,
    ShipToCSZ                TCityStateZip,
    ShipToReference1         TDescription,
    ShipToReference2         TDescription,
    /* SoldTo Info */
    SoldToName               TName,
    SoldToAddr1              TAddressLine,
    SoldToAddr2              TAddressLine,
    SoldToCity               TCity,
    SoldToState              TState,
    SoldToZip                TZip,
    SoldToCSZ                TCityStateZip,
    SoldToEmail              TEmailAddress,
    /* Shipping Info */
    ShipVia                  TShipVia,
    ShipViaDesc              TDescription,
    SCAC                     TSCAC,
    BillofLading             TBoL,
    ProNumber                TProNumber,
    DesiredShipDate          TDate,
    LoadNumber               TLoadNumber,
    ClientLoad               TLoadNumber,
    /* UCC Barcode */
    BarcodeType              TTypeCode,
    UCCBarcode               TBarcode,
    SCCBarcode               TBarcode,
    PackingCode              TTypeCode,
    CompanyId                TBarcode,
    SequentialNumber         TBarcode,
    CheckDigit               TFlag,
    TrackingNo               TTrackingNo,
    /* Pick Batch Info */
    WaveId                   TRecordId,
    WaveNo                   TWaveNo,
    WaveType                 TTypeCode,
    WaveNumOrders            TInteger,
    PickBatchNo              TPickBatchNo,
    /* Order header Info */
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    SalesOrder               TSalesOrder,
    CustPO                   TCustPO,
    Account                  TCustomerId,
    AccountName              TName,
    PickZone                 TZoneId,
    ShippedDate              TDateTime,
    WaveSeqNo                TInteger,
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
    Warehouse                TWarehouse,
    /* Order Detail Info */
    HostOrderLine            THostOrderLine,
    CustomerSKU              TCustSKU, /* 2020/07/09 Deprecated */
    CustSKU                  TCustSKU,
    RetailUnitPrice          TPrice,
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
    OD_UDF21                 TUDF,
    OD_UDF22                 TUDF,
    OD_UDF23                 TUDF,
    OD_UDF24                 TUDF,
    OD_UDF25                 TUDF,
    OD_UDF26                 TUDF,
    OD_UDF27                 TUDF,
    OD_UDF28                 TUDF,
    OD_UDF29                 TUDF,
    OD_UDF30                 TUDF,
    /* SKU Details */
    SKUId                    TRecordId,
    SKU                      TSKU,
    SKUDescription           TDescription,
    UPC                      TUPC,
    UOM                      TUOM,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,
    SKU1Desc                 TDescription,
    SKU2Desc                 TDescription,
    SKU3Desc                 TDescription,
    SKU4Desc                 TDescription,
    SKU5Desc                 TDescription,
    SKUSizeScale             TSizeScale,
    SKUSizeSpread            TSizeSpread,
    /* LPN */
    LPNId                    TRecordId,
    LPN                      TLPN,
    LPNInnerPacks            TInnerPacks,
    LPNQuantity              TQuantity,
    UnitsPerPackage          TInteger,
    PrepackQty               TQuantity,
    LPNLot                   TLot,
    ExpiryDate               TDescription,
    AlternateLPN             TLPN,
    LPNWeight                TWeight,
    LPNNumLines              TCount,
    LPNNumSKUs               TCount,
    LPNNumSizes              TCount,
    /* LPN Details */
    CoO                      TCoO,
    PickedBy                 TUserId,
    /* Label */
    NumberofLabels           TInteger,
    CurrentCarton            TInteger,
    NumberofCartons          TInteger,
    --Label                    Image,  /* RV: Discussed with AY, Getting errors while convering to xml commented out as label is not any where */
    IsValidTrackingnNo       TFlag,
    /* Other */
    PickLocation             TLocation,
    PickLocationRow          TRow,
    PickLocationLevel        TLevel,
    PickLocationSection      TSection,
    CurrentDateTime          DateTime,

    TaskId                   TRecordId,
    IsLastPickFromLocation   TFlags,
    Destination              TLocation,
    LabelType                TTypeCode,
    CartonType               TCartonType,
    CartonTypeDesc           TDescription,

    UDF1                     TVarchar,      /* Additional Info - Dept & PO */
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF

);

Grant References on Type:: TLPNShipLabelData to public;

Go
