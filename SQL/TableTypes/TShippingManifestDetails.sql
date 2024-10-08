/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  SAK     TManifestLPNDetails and TShippingManifestDetails: Added fields LPNInventoryClass1..,InventoryClass1.. (HA-2674)
  2021/04/08  AY      TShippingManifestDetails: Added OrderId, SortOrder (HA-2572)
  2020/01/05  RT      TManifestLPNDetails, TShippingManifestDetails: Included LPNLot and LPNLot (HA-1849)
  2020/09/01  RKC     TShippingManifestDetails, TManifestLPNDetails: Added ShipCartons (HA-1304)
  2018/10/09  AY      TManifestLPNDetails, TShippingManifestDetails: Added (S2GCA-357)
  Create Type TShippingManifestDetails as table (
  Grant References on Type:: TShippingManifestDetails to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TShippingManifestDetails as table (
    LoadId                   TLoadId,
    ShipmentId               TShipmentId,

    CustPO                   TCustPO,
    PickTicket               TPickTicket,
    Pallet                   TPallet,
    PalletSeqNo              TRecordId,

    OrderId                  TRecordId,
    SKUId                    TRecordId,
    PalletId                 TRecordId,

    LPN                      TLPN,
    Weight                   TWeight,
    InnerPacks               TInnerPacks,
    Cases                    TCount,
    UnitsPerPackage          TInteger,
    Quantity                 TQuantity,
    ShipCartons              TCount,
    Lot                      TLot,
    CoO                      TCoO,
    InventoryClass1          TInventoryClass,
    InventoryClass2          TInventoryClass,
    InventoryClass3          TInventoryClass,

    CustSKU                  TCustSKU,
    SKU                      TSKU,
    UPC                      TUPC,
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
    AlternateSKU             TSKU,

    SortOrder                TSortOrder,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,
    RecordId                 TRecordId      identity (1,1)
);

Grant References on Type:: TShippingManifestDetails to public;

Go
