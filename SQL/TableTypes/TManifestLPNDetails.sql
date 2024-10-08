/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  SAK     TManifestLPNDetails and TShippingManifestDetails: Added fields LPNInventoryClass1..,InventoryClass1.. (HA-2674)
  2020/01/05  RT      TManifestLPNDetails, TShippingManifestDetails: Included LPNLot and LPNLot (HA-1849)
  2020/09/01  RKC     TShippingManifestDetails, TManifestLPNDetails: Added ShipCartons (HA-1304)
  2018/10/09  AY      TManifestLPNDetails, TShippingManifestDetails: Added (S2GCA-357)
  Create Type TManifestLPNDetails as Table (
  Grant References on Type:: TManifestLPNDetails to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TManifestLPNDetails as Table (
    LPNId                    TRecordId,
    LPNDetailId              TRecordId,
    LPNInnerPacks            TInnerPacks,
    LPNQuantity              TQuantity,
    LPNLot                   TLot,
    LPNCoO                   TCoO,
    LPNInventoryClass1       TInventoryClass,
    LPNInventoryClass2       TInventoryClass,
    LPNInventoryClass3       TInventoryClass,
    LDInnerPacks             TInnerPacks,
    LDQuantity               TQuantity,
    UnitsPerPackage          TInteger,
    ShipCartons              TCount,
    NumLines                 TCount,

    LPNWeight                TWeight,
    PalletId                 TRecordId,
    OrderId                  TRecordId,
    OrderDetailId            TRecordId,
    SKUId                    TRecordId,

    GroupCriteria1           TCategory,
    GroupCriteria2           TCategory,
    GroupCriteria3           TCategory,

    RecordId                 TRecordId Identity(1,1),
    Unique                   (LPNId, LPNDetailId, RecordId)
);

Grant References on Type:: TManifestLPNDetails to public;

Go
