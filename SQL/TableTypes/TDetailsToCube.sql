/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/06  TK      TDetailsToCube: Added required fields for single carton orders processing
  2020/09/16  TK      TDetailsToCube: Added Dimensions (HA-1446)
  2020/06/05  TK      TDetailsToCube: Added inventory classes (HA-829)
  2020/05/06  TK      TDetailsToCube, TCubeCartonHdrs, TCubeCartonDtls & TCartonTypes:
  2020/04/15  TK      TDetailsToCube: Added WaveId, WaveNo, TaskId, TaskDetailId, OrderDetailId
  TDetailsToCube & TCubeCartonDtls TaskRecordId -> UniqueId (HA-171)
  Create Type TDetailsToCube as Table (
  Grant References on Type:: TDetailsToCube  to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TDetailsToCube as Table (
    UniqueId                 TRecordId,
    WaveId                   TRecordId,
    WaveNo                   TWaveNo,
    TaskId                   TRecordId,
    TaskDetailId             TRecordId,
    PickType                 TTypeCode,

    SKUId                    TRecordId,
    SKU                      TSKU,
    SpacePerUnit             TFloat,
    SpacePerIP               TFloat,
    UnitWeight               TWeight,
    InnerPackWeight          TWeight,
    SKUCartonGroup           TCartonGroup,

    UnitsPerIP               TInteger,
    NestingFactor            TFloat         default 1.0,
    ShipPack                 TInteger,

    MaxUnitDimension         TFloat,
    MaxFirstDimension        TFloat,
    MaxSecondDimension       TFloat,
    MaxThirdDimension        TFloat,

    FirstDimension           TFloat,
    SecondDimension          TFloat,
    ThirdDimension           TFloat,

    ProdCategory             TCategory,
    ProdSubCategory          TCategory,

    OrderId                  TRecordId,
    OrderDetailId            TRecordId,
    PickTicket               TPickTicket,
    SalesOrder               TSalesOrder,
    OrderCartonGroup         TCartonGroup,
    PackingGroup             TCategory,
    CartonType               TCartonType,

    AllocatedQty             TQuantity,                                -- Original Qty allocated
    CubedQty                 TQuantity      default 0,                 -- Qty already cubed into cartons
    QtyToCube                as (AllocatedQty - CubedQty),             -- Units yet to be cubed

    AllocatedIPs             as case when UnitsPerIP > 0 then (AllocatedQty / UnitsPerIP)
                                     else 0
                                end,                                    -- Original IPs allocated
    CubedIPs                 as case when UnitsPerIP > 0 then (CubedQty / UnitsPerIP)
                                     else 0
                                end,                                    --IPs already cubed
    IPsToCube                as case when UnitsPerIP > 0 then ((AllocatedQty / UnitsPerIP) - (CubedQty / UnitsPerIP))
                                     else 0
                                end, --IPs yet to be cubed

    SpaceRequired            as case when (AllocatedQty - CubedQty) = 0 then 0
                                     /* when IPstoCube > 0 and there are no units, then space is IPsToCube * SpaceperIP */
                                     when (UnitsPerIP > 0 and
                                          ((AllocatedQty / UnitsPerIP) - (CubedQty / UnitsPerIP) /* IPsToCube */) > 0) and
                                          ((AllocatedQty - CubedQty) % UnitsPerIP) = 0 then
                                       (((AllocatedQty / UnitsPerIP) - (CubedQty / UnitsPerIP)) * SpacePerIP)                         -- IPsToCube * SpacePerIP
                                     /* when IPstoCube > 0 and some units, then space is IPsToCube * SpaceperIP + Space for units considering nesting factor */
                                     when (UnitsPerIP > 0 and
                                          ((AllocatedQty / UnitsPerIP) - (CubedQty / UnitsPerIP) /* IPsToCube */) > 0) then
                                      ((((AllocatedQty / UnitsPerIP) - (CubedQty / UnitsPerIP)) * SpacePerIP) +                       -- IPsToCube * SpacePerIP +
                                       (SpacePerUnit + (((AllocatedQty - CubedQty) % UnitsPerIP) - 1) * SpacePerUnit * NestingFactor)) -- UnitsToCube * SpacePerUnit ~ Applying NestingFactor
                                     else
                                     /* when remaining qty is only units and there are no IPs */
                                       SpacePerUnit + ((AllocatedQty - CubedQty - 1) * SpacePerUnit * NestingFactor)
                                end, -- Space required for the remaining units which are yet to be cubed

    TotalSpaceRequired       as case when (AllocatedQty = 0) then 0
                                     /* when AllocatedIPs > 0 and there are no remaining units, then it is IPsAllocated * SpacePerIP */
                                     when (UnitsPerIP > 0 and (AllocatedQty / UnitsPerIP) /* IPsAllocated */ > 0) and
                                          (AllocatedQty % UnitsPerIP) = 0 then
                                       ((AllocatedQty / UnitsPerIP) * SpacePerIP)                                                    -- IPsAllocated * SpacePerIP
                                     /* when AllocatedIPs > 0, then it is IPsAllocated * SpacePerIP + Remainingunits * Spaces for units considering nesting factor */
                                     when (UnitsPerIP > 0 and (AllocatedQty / UnitsPerIP) /* IPsAllocated */ > 0) then
                                       (((AllocatedQty / UnitsPerIP) * SpacePerIP) +                                                  -- IPsAllocated * SpacePerIP +
                                       (SpacePerUnit + (((AllocatedQty % UnitsPerIP) - 1) * SpacePerUnit * NestingFactor)))           -- UnitsAllocated * SpaceperUnit ~ Apply Nesting factor
                                     else
                                     /* when AllocatedQty is only units i.e. no IPs */
                                       SpacePerUnit + ((AllocatedQty - 1) * SpacePerUnit * NestingFactor)
                                end,

   /* if space was cubed in multiples of cases then it should be number of IPs multiplied with the innerpack volume
      if there are any units it should be units multiplied by the unit volume */
   SpaceCubed                as case when (CubedQty = 0) then 0
                                     /* when CubedQty is only IPs and ther are no remaining units */
                                     when (UnitsPerIP > 0) and (CubedQty % UnitsPerIP = 0) and (SpacePerIP > 0) then
                                       ((CubedQty / UnitsPerIP) * SpacePerIP)                                                        -- IPsCubed * SpacePerIP
                                     /* when CubedQty is IPs + some additonal units */
                                     when (UnitsPerIP > 0) and (CubedQty % UnitsPerIP > 0) and (SpacePerIP > 0) then
                                       (((CubedQty / UnitsPerIP) * SpacePerIP) +                                                      -- IPsCubed * SpacePerIP +
                                        (SpacePerUnit + ((CubedQty % UnitsPerIP) - 1) * SpacePerUnit * NestingFactor))                 -- UnitsCubed * SpacePerUnit ~ Apply nesting factor
                                     else
                                     /* CubedQty is only units, no IPs */
                                       SpacePerUnit + ((CubedQty - 1) * SpacePerUnit * NestingFactor)
                                end,

    TotalWeight              as case when (AllocatedQty = 0) then 0
                                     /* when AllocatedIPs > 0 and there are no remaining units, then it is IPsAllocated * InnerPackWeight */
                                     when (UnitsPerIP > 0) and  (AllocatedQty % UnitsPerIP = 0) and (InnerPackWeight > 0) then
                                       ((AllocatedQty / UnitsPerIP) * InnerPackWeight)                                                    -- IPsAllocated * InnerPackWeight
                                     /* when AllocatedIPs > 0, then it is IPsAllocated * InnerPackWeight + Remainingunits * UnitWeight for units */
                                     when (UnitsPerIP > 0) and (AllocatedQty % UnitsPerIP > 0) and (InnerPackWeight > 0) then
                                       ((AllocatedQty / UnitsPerIP) * InnerPackWeight) +
                                       ((AllocatedQty % UnitsPerIP) * UnitWeight)
                                     else
                                     /* when AllocatedQty is only units i.e. no IPs */
                                       UnitWeight * AllocatedQty
                                end,

    SortSeq                  TInteger       default 0,
    Status                   TStatus        default 'A',                      -- A - Available to cube, I - Ignore, future use

    Ownership                TOwnership,
    Warehouse                TWarehouse,

    InventoryClass1          TInventoryClass    DEFAULT '',
    InventoryClass2          TInventoryClass    DEFAULT '',
    InventoryClass3          TInventoryClass    DEFAULT '',

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    RecordId                 TRecordId      identity(1,1),

    Primary Key              (RecordId),
    Unique                   (OrderId, Status, RecordId),               -- Additional indices for performance as we select by these fields
    Unique                   (QtyToCube, RecordId)
);

Grant References on Type:: TDetailsToCube  to public;

Go
