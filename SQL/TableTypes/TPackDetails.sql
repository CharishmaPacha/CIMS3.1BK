/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/21  AY      TPackDetails: Added Inventory Key (FBV3-886)
  2021/10/12  RV      TPackDetails: Added PackingGroup, UnitsPicked and PackGroupKey (BK-636)
  2019/07/05  MS      Added TPackDetails (CID-609)
  Create Type TPackDetails as Table (
  Grant References on Type:: TPackDetails to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TPackDetails as Table (
    OrderId                  TRecordId,
    OrderDetailId            TRecordId,

    FromLPNId                TRecordId,
    FromLPNDetailId          TRecordId,
    PalletId                 TRecordId,

    SKUId                    TRecordId,
    SKU                      TSKU,

    UnitsPicked              TQuantity,
    UnitsPacked              TQuantity,

    SerialNo                 TVarChar,
    PackingGroup             TCategory,
    LineType                 TFlag,

    PackGroupKey             TVarChar,
    InventoryKey             TInventoryKey,

    RecordId                 TRecordId      identity(1,1) not null
);

Grant References on Type:: TPackDetails to public;

Go
