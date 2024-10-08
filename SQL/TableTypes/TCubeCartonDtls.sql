/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/11  TK      TCubeCartonHdr & TCubeCartonDtls: Added  UDFs (HA-1899)
  2020/05/06  TK      TDetailsToCube, TCubeCartonHdrs, TCubeCartonDtls & TCartonTypes:
  TDetailsToCube & TCubeCartonDtls TaskRecordId -> UniqueId (HA-171)
  2018/06/12  TK      TCubeCartonDtls: Bug fix to consider InnerPackVolume properly (S2G-925)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Holds details of each carton that is being cubed */
Create Type TCubeCartonDtls as Table (
    CartonId                 TRecordId,
    UniqueId                 TRecordId,   -- This could be OrderDetailId or TaskDetailId based on the entity that is being cubed

    SKUId                    TRecordId,
    SKU                      TSKU,
    PackingGroup             TCategory,
    SpacePerIP               TFloat,
    SpacePerUnit             TFloat,
    WeightPerIP              TWeight,
    WeightPerUnit            TWeight,
    NestingFactor            TFloat         Default 1.0,
    UnitsPerIP               TInteger,
    ShipPack                 TInteger,

    UnitsCubed               TInteger       default 0,
    SpaceUsed                as case when (UnitsCubed = 0) then 0
                                     /* when CubedQty is only IPs and ther are no remaining units */
                                     when (UnitsPerIP > 0) and (UnitsCubed % UnitsPerIP = 0) and (SpacePerIP > 0) then
                                       ((UnitsCubed / UnitsPerIP) * SpacePerIP)                                                        -- IPsCubed * SpacePerIP
                                     /* when CubedQty is IPs + some additonal units */
                                     when (UnitsPerIP > 0) and (UnitsCubed % UnitsPerIP > 0) and (SpacePerIP > 0) then
                                       (((UnitsCubed / UnitsPerIP) * SpacePerIP) +                                                      -- IPsCubed * SpacePerIP +
                                        (SpacePerUnit + ((UnitsCubed % UnitsPerIP) - 1) * SpacePerUnit * NestingFactor))                 -- UnitsCubed * SpacePerUnit ~ Apply nesting factor
                                     else
                                     /* CubedQty is only units, no IPs */
                                       SpacePerUnit + ((UnitsCubed - 1) * SpacePerUnit * NestingFactor)
                                end,
    WeightUsed               as case when (UnitsCubed = 0) then 0
                                     /* when AllocatedIPs > 0 and there are no remaining units, then it is IPsAllocated * InnerPackWeight */
                                     when (UnitsPerIP > 0) and (UnitsCubed % UnitsPerIP = 0) and (WeightPerIP > 0) then
                                       ((UnitsCubed / UnitsPerIP) * WeightPerIP)                                                    -- IPsAllocated * InnerPackWeight
                                     /* when AllocatedIPs > 0, then it is IPsAllocated * InnerPackWeight + Remainingunits * UnitWeight for units */
                                     when (UnitsPerIP > 0) and (UnitsCubed % UnitsPerIP > 0) and (WeightPerIP > 0) then
                                       ((UnitsCubed / UnitsPerIP) * WeightPerIP) +
                                       ((UnitsCubed % UnitsPerIP) * WeightPerUnit)
                                     else
                                     /* when AllocatedQty is only units i.e. no IPs */
                                       UnitsCubed * WeightPerUnit
                                end,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    RecordId                 TRecordId      identity(1,1),

    Primary Key              (RecordId),
    Unique                   (CartonId, RecordId)
);

Grant References on Type:: TCubeCartonDtls  to public;

Go
