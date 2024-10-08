/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/01/10  RV      TCommoditiesInfo, TPackingListDetails: Added UnitCost, LineTotalCost and LineTotalPrice (OBV3-1653)
  2021/07/30  RV      TPackingListDetails: Added LineType (OB2-1960)
  2021/06/28  RV      TPackingListDetails: DisplaySKU and DisplaySKUDesc (OB2-1822)
  2021/01/06  RKC     TPackingListDetails: Changed the data type for HarmonizedCode field (CID-1616)
  2020/09/23  PHK     TPackingListDetails: Added NumCartons (HA-1308)
  2019/08/20  RT      TPackingListDetails: Included OD_UDF11 to 20 (CID-944)
  2019/07/04  KSK     TPackingListDetails: Added the HarmonizedCode,CoO (CID-632)
  2019/04/12  AJ      TPackingListDetails: Added Brand (CID-219)
  2019/03/29  OK      Added PDNote to type TPackingListDetails (HPI-2541)
  2016/08/02  RV      TPackingListDetails: UnitsBackOrdered renamed as BackOrdered.
  2016/07/20  YJ      Added more fields to type TPackingListDetails (HPI-330)
  Create Type TPackingListDetails as Table (
  Grant References on Type:: TPackingListDetails to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TPackingListDetails as Table (
    RecordId                 TRecordId,
    RecordType               TTypeCode,
    /* LPN Info */
    PackageSeqNo             TInteger,
    LPN                      TLPN,
    LPNId                    TRecordId,
    LPNDetailId              TRecordId,
    CoO                      TCoO,
    UCCBarcode               TBarcode,
    TrackingNo               TTrackingNo,
    Weight                   TWeight,
    /* LPN Details */
    SKUId                    TRecordId,
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,
    SKUDescription           TDescription,
    SKU1Description          TDescription,
    SKU2Description          TDescription,
    SKU3Description          TDescription,
    SKU4Description          TDescription,
    SKU5Description          TDescription,
    DisplaySKU               TSKU,
    DisplaySKUDesc           TDescription,
    Brand                    TBrand,
    HarmonizedCode           THarmonizedCode,
    CustSKU                  TCustSKU,
    UoM                      TUoM,
    UPC                      TUPC,
    InnerPacks               TInnerPacks,
    Quantity                 TQuantity,
    UnitsPerInnerPack        TInteger,
    QtyOrdered               TQuantity,
    QtyBackOrder             TQuantity,
    /* Pallet */
    PalletId                 TRecordId,
    Pallet                   TPallet,
    /* Order */
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    SalesOrder               TSalesOrder,
    OrderDetailId            TRecordId,

    /* Order Details */
    OrderLine                TDetailLine,
    HostLineNo               THostOrderLine,
    HostOrderLine            THostOrderLine,
    LineType                 TTypeCode,
    UnitPrice                TUnitPrice,
    LineSubTotal             TMoney,
    LineTax                  TMoney,
    LineTotal                TMoney,
    /* Counts */
    UnitsOrdered             TQuantity,
    UnitsShipped             TQuantity,
    UnitsAuthorizedToShip    TQuantity,
    UnitsAssigned            TQuantity,
    BackOrdered              TQuantity,
    NumCartons               TQuantity,
    /* Money */
    UnitCost                 TMoney,
    RetailUnitPrice          TRetailUnitPrice,
    UnitSalePrice            TUnitPrice,
    UnitValue                TMoney,
    LineSaleAmount           TMoney,
    LineValue                TMoney,
    LineDiscount             TMoney,
    LineTotalAmount          TMoney,
    UnitTaxAmount            TMoney,
    LineTaxAmount            TMoney,

    PDNote                   TNote,

    Value1                   TDescription,
    Value2                   TDescription,
    Value3                   TDescription,
    Value4                   TDescription,
    Value5                   TDescription,
    Value6                   TDescription,
    Value7                   TDescription,
    Value8                   TDescription,
    Value9                   TDescription,
    Value10                  TDescription,
    Value11                  TDescription,
    Value12                  TDescription,

    TotalValue               varchar(10),
    SortOrder                TDescription,
    ProductInfo1             TVarchar,
    ProductInfo2             TVarchar,
    ProductInfo3             TVarchar,

    NumRows                  TInteger,
    Counter                  TInteger,

    /* UDFs */
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

    PL_UDF1                  TUDF,          /* Future Use */
    PL_UDF2                  TUDF,
    PL_UDF3                  TUDF,
    PL_UDF4                  TUDF,
    PL_UDF5                  TUDF,

    PLD_UDF1                 TUDF,
    PLD_UDF2                 TUDF,
    PLD_UDF3                 TUDF,
    PLD_UDF4                 TUDF,
    PLD_UDF5                 TUDF,

    BusinessUnit             TBusinessUnit
);

Grant References on Type:: TPackingListDetails to public;

Go
