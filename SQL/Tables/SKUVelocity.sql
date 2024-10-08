/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/22  TD      Added SKUVelocity (BK-768)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: SKUVelocity: This table is used to maintain the velocity (movement) of the
   SKU for the given day. There could be different ways to measure the Velocity and
   VelocityType determines that.

 Velocity defines the speed of movement
 SKU Velocity refers to the velocity with which the SKU moved i.e.
   the rate at which is it shipped from the WH or the rate at which it is
   picked from the location.

 VelocityType  - This field will define whether it is PICK or SHIP information.
   SHIP Velocity - Shows the units of SKU shipped each day from the WH
   PICK Velocity - Shows the units of the SKU picked from a Location each day.

 So, SKU SHIP Velocity will not have a Location where as SKU PICK Velocity records
   will have a location.

 NumPallets- How many Pallets picked/shipped. If the VelocityType is PICKED (PICK) then
             if will be num pallets picked from the location. If the VelocityType is
               SHIP then it will be number pallets shipped for that SKU.
 NumLPNs   - How many LPNs picked/shipped.
 NumCases  - How many InnerPacks picked/shipped.
 NumUnits  - How many united picked/shipped.

 ------------------------------------------------------------------------------*/
Create Table SKUVelocity (
    RecordId                 TRecordId      identity (1,1) not null,

    TransDate                TDate,
--     TransWeek                TInteger,   -- couldn't create it as computed column and have an index on it
--     TransMonth               TInteger,   -- couldn't create it as computed column and have an index on it
    VelocityType             TTypeCode,

    SKUId                    TRecordId      not null,
    SKU                      TSKU,
    InventoryClass1          TInventoryClass,
    InventoryClass2          TInventoryClass,
    InventoryClass3          TInventoryClass,

    LocationId               TRecordId,
    Location                 TLocation,

    NumPallets               TInteger,
    NumLPNs                  TInteger,
    NumCases                 TInteger,
    NumUnits                 TInteger,

    InventoryKey             TInventoryKey,
    Warehouse                TWarehouse,
    Ownership                TOwnership,
    /* Future use */
    Account                  TAccount,
    AccountName              TName,
    SoldToId                 TCustomerId,
    ShipToId                 TShipToId,
    WaveType                 TTypeCode,
    /* Future use */
    SVCategory1              TCategory,
    SVCategory2              TCategory,
    SVCategory3              TCategory,
    SVCategory4              TCategory,
    SVCategory5              TCategory,

    Status                   TStatus        not null default 'A' /* Active */,

    SV_UDF1                  TUDF,
    SV_UDF2                  TUDF,
    SV_UDF3                  TUDF,
    SV_UDF4                  TUDF,
    SV_UDF5                  TUDF,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkSKUVelocity_RecordId PRIMARY KEY (RecordId)
);

create index ix_SKUVelocity_SKUId      on SKUVelocity (SKUId, LocationId, VelocityType, Status, Archived) Include (NumPallets, NumLPNs, NumCases, NumUnits);
create index ix_SKUVelocity_TransDate  on SKUVelocity (TransDate, VelocityType, SKUId) Include (NumPallets, NumLPNs, NumCases, NumUnits);
-- create index ix_SKUVelocity_TransMonth on SKUVelocity (TransMonth, TransYear, VelocityType, SKUId) Include (RecordId);
-- create index ix_SKUVelocity_TransWeek  on SKUVelocity (TransWeek, TransYear, VelocityType, SKUId) Include (RecordId);

Go
