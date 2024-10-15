/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/01/10  RV      TCommoditiesInfo, TPackingListDetails: Added UnitCost, LineTotalCost and LineTotalPrice (OBV3-1653)
  2022/12/09  AY      TCommoditiesInfo: Added ProductInfo1/2/3 (OBV3-1586)
  2022/10/27  AY      TCommoditiesInfo: Added more fields for handling multiple packages (OBV3-1305)
  2021/07/30  OK      Added TCommoditiesInfo (BK-382)
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TCommoditiesInfo as Table (
    EntityType            TTypeCode,
    EntityId              TRecordId,
    EntityKey             TEntityKey,
    NumberOfPieces        TQuantity,
    NumPackages           TCount,
    SKU                   TSKU,
    UPC                   TUPC,
    Description           TDescription,
    ProductInfo1          TVarchar,
    ProductInfo2          TVarchar,
    ProductInfo3          TVarchar,
    Quantity              TQuantity,
    QuantityUoM           TUoM,
    UnitCost              TMoney,
    UnitPrice             TMoney,
    UnitValue             TMoney,
    Currency              TCurrency,
    Value                 TMoney,       -- deprecated
    LineTotalCost         TMoney,
    LineTotalPrice        TMoney,
    LineValue             TMoney,
    UnitWeight            Numeric(11, 5),
    WeightUoM             TUoM,
    QtyWeight             TVarChar,
    CoO                   TCoO,
    Manufacturer          TCoO, -- deprecated
    FreightClass          TCategory,
    FreightIsHazardous    TFlag,
    FreightNMFC           TDescription,
    FreightNMFCSub        TDescription,
    FreightPackagingType  TCartonType,
    HarmonizedCode        THarmonizedCode,
    HTSCode               THTSCode,
    LPNWeight             TWeight,
    PackageSeqNo          TInteger,
    RecordId              TRecordId
);

grant references on Type:: TCommoditiesInfo to public;

Go
