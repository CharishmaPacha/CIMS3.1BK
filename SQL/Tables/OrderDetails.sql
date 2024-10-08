/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/03/26  AY      ix_OrderDetails_OrderId: Enhanced by adding UnitsPreallocated (CIMSV3-2715)
  2023/03/09  TK      OrderHeaders & OrderDetails: Added fields need for order consolidation (FBV3-1522)
  2022/11/19  AY      OrderDetails: ix_OrderDetails_OrderId and ix_OrderDetails_Archived - performance changes (OBV3-1489)
  2022/02/04  TK      OrderDetails: Added Ownership, Warehouse, (new) InventoryKey & Lot should be empty by default (FBV3-772 & 810) (FBV3-772 & 810)
  2021/11/02  NB      OrderDetails: Added Archived, Index on Archived(FBV3-366)
  2021/08/19  SK      OrderDetails: Revised computer column UnitsToAllocate for Kit orders (BK-483)
  2021/05/21  TK      OrderDetails: Added PrepackCode (HA-2664)
  2021/03/18  SK      OrderDetails: Added constraint for UnitsAssigned to not update below 0 (HA-2319)
  2021/03/03  AY      OrderDetails: Added SortOrder (HA-2127)
  2020/09/11  TK      OrderDetails: UnitsToAllocate for Kit Lines (HA-1238)
  2020/05/17  AY      OrderDetails: Added SKU, SKU1..5, NewSKU (HA-543)
  2020/05/09  TK      OrderDetails: Added NewSKUId & NewInventoryClasses (HA-475)
  2020/04/04  TK      OrderDetails: InventoryClass defaulted to empty string (HA-84)
  2020/03/29  AY      OrderDetails: Added Lot & InventoryClasses (HA-77)
  2019/04/18  RT      OrderDetails: Included Serialized (S2GCA-559)
  2019/03/12  PHK     OrderDetails: Removed unique key violations on OrderLine field (HPI-2449)
  2019/02/26  PK      OrderDetails: Added ParentLineId, ParentHostLineNo.
  2019/01/28  TK      OrderDetails: Added ParentHostLineNo (S2GCA-476)
  2018/12/18  TK      OrderDetails: Changed ix_OrderDetails_DestLocation to include OrderId as well (HPI-Support)
  2019/01/28  TK      OrderDetails: Added ParentHostLineNo (S2GCA-476)
  2018/08/08  VS      OrderDetails: Added index for Performance improvement (OB2-349)
  2018/03/15  TD      OrderDetails: Added DestLocationId (S2G-432)
  2017/10/05  VM      OrderDetails: Added UDF11 - UDF20 (OB-617)
  OrderDetails: ix_OrderDetails_HostOrderLine
  2016/07/29  TK      OrderDetails: Added PackingGroup (HPI-380)
  2016/05/18  TK      OrderDetails: Added UnitsPreAllocated (HPI-31)
  2015/06/18  AY      OrderDetails: Added CustPO
  2014/10/07  TD      OrderDetails: Added AllocateFlags
  2014/04/02  TD      OrderDetails: DestLocation, DestZone.
  2014/04/01  NY      OrderDetails: Added OrigUnitsAuthorizedToShip.
  2013/11/23  VP      OrderDetails: Added Index ixOrderDetailsOrderId.
  2013/10/03  AY      OrderDetails: Added UnitsPerInnerPack
  2013/09/12  TD      OrderDetails: Added new fields PickZone and others.
  2012/09/24  AY      OrderDetails: Added UnitsPerCarton
  2012/07/11  AY      OrderHeaders: Added NumLPNs, Comments. OrderDetails UDF6..10
  2012/05/15  NY      OrderDetails: Added a Check constraint to validate Overpack
  2012/02/07  YA      OrderDetails: Added new fields LocationId & Location
  OrderDetails: New field UnitTaxAmount
  2011/10/20  AY      OrderDetails: Changed computation of UnitsToAllocate so
  2011/10/13  AY      OrderDetails: Added LineType
  OrderDetails: Added UnitSalePrice
  2010/10/22  VM      OrderDetails: Added Foreign Key with On Delete Cascade
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: OrderDetails

 LineType: When its 'A' it is a Kit Assembly and UnitsAuthorizedToShip on that line would be zero and UnitsToAllocate
           would be the difference between UnitsOrdered & UnitsAssigned
 NewSKUId/NewSKU:       This is used when inventory with one SKU to be reworked and converted to another SKU,
                        for a rework order when NewSKUId is given then picked inventory will be converted to
                        available inventory with new SKU
 NewInventoryClass(es): This is used when inventory with one InventoryClass to be reworked and converted to
                        another InventoryClass, for a rework order when NewInventoryClass is specified then
                        picked inventory will be converted to available inventory with new inventory class

 PrepackCode:           Multiple Order lines can be part of one prepack and can only be packed as one item. For
                        example if Lines 1-4 are for sizes S,M,L,XL and the are in the ratio of 1-2-2-1, then we
                        can only pack or cube in multiples of this ratio in any carton. So, if the Ordered qty is
                        10-20-20-10 i.e. 10 prepacks, each shipping carton can have 1 or more of these prepacks
                        but we cannot have for example S in one carton, M in another carton etc. The ratio is
                        defined in UnitsPerInnerPack
------------------------------------------------------------------------------*/
Create Table OrderDetails (
    OrderDetailId            TRecordId identity (1,1) not null,

    OrderId                  TRecordId      not null,
    HostOrderLine            THostOrderLine not null,

    LineType                 TTypeCode,
    SKUId                    TRecordId,
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,

    UnitsOrdered             TQuantity          default 0,
    UnitsAuthorizedToShip    TQuantity          default 0,
    OrigUnitsAuthorizedToShip
                             TQuantity          default 0,
    UnitsAssigned            TQuantity          default 0,
    UnitsPreAllocated        TQuantity          default 0,
    UnitsToAllocate          As Case
                               when (LineType = 'F' /* Fees */) then 0
                               else (UnitsAuthorizedToShip - UnitsAssigned)
                             end,
    UnitsShipped             TQuantity          default 0,

    UnitsPerCarton           TInteger,
    UnitsPerInnerPack        TInteger,

    RetailUnitPrice          TRetailUnitPrice   default 0.0,
    UnitSalePrice            TUnitPrice         default 0.0,
    UnitTaxAmount            TMonetaryValue     default 0.0,

    Ownership                TOwnership,
    Warehouse                TWarehouse,
    Lot                      TLot               not null default '',
    InventoryClass1          TInventoryClass    default '',
    InventoryClass2          TInventoryClass    default '',
    InventoryClass3          TInventoryClass    default '',
    NewInventoryClass1       TInventoryClass    default '',
    NewInventoryClass2       TInventoryClass    default '',
    NewInventoryClass3       TInventoryClass    default '',
    CustSKU                  TCustSKU,
    CustPO                   TCustPO,

    NewSKUId                 TRecordId,
    NewSKU                   TSKU,

    PickZone                 TZoneId,
    DestZone                 TZoneId,
    DestLocationId           TRecordId,
    DestLocation             TLocation,

    PickBatchGroup           TWaveGroup,
    PickBatchCategory        TCategory,

    PackingGroup             TCategory,
    PrepackCode              TCategory, -- identifies which lines are part of a prepack in the ratio of UnitsPerInnerPack
    SortOrder                TSortOrder,

    ParentLineId             TRecordId,
    ParentHostLineNo         THostOrderLine,

    AllocateFlags            TFlags default 'N',
    Serialized               TFlag              default 'N',

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

    OrderLine                TDetailLine,  -- depcreated do not use
    LocationId               TRecordId,    -- Deprecated - Using DestLocationId for replenishments
    Location                 TLocation,    -- Deprecated - Using DestLocationId for replenishments

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    InventoryKey             as concat_ws('-', SKUId, Ownership, Warehouse, Lot, InventoryClass1, InventoryClass2, InventoryClass3),
    NewInventoryKey          as concat_ws('-', NewSKUId, Ownership, Warehouse, Lot, NewInventoryClass1, NewInventoryClass2, NewInventoryClass3),

    constraint pkOrderDetails_OrderDetailId    PRIMARY KEY (OrderDetailId),

    constraint ccOrderDetails_UnitsAssigned        CHECK(UnitsAssigned <= UnitsAuthorizedToShip),

    constraint ccOrderDetails_UnitsAssigned_GTZero CHECK(UnitsAssigned >= 0)

);

create index ix_OrderDetails_SKUId               on OrderDetails (SKUId, DestZone, OrderId) Include(UnitsToAllocate, OrderDetailId, LocationId, Location);
create index ix_OrderDetails_OrderId             on OrderDetails (OrderId, OrderDetailId) Include(LineType, UnitsAuthorizedToShip, UnitsAssigned, UnitsShipped, BusinessUnit, HostOrderLine, SKUId, OrderLine);
create index ix_OrderDetails_Archived            on OrderDetails (Archived, BusinessUnit, Warehouse) Include (OrderDetailId) where (Archived ='N');
/* User in Min-Max replenishment */
create index ix_OrderDetails_DestLocation        on OrderDetails (DestLocation) Include (OrderId);
create index ix_OrderDetails_HostOrderLine       on OrderDetails (OrderId, HostOrderLine, SKUId) Include(OrderDetailId);
create index ix_OrderDetails_Location            on OrderDetails (Location) Include(OrderId);

Go
