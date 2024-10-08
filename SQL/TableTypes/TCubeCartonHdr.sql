/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/03  AY      TCubeCartonHdr: Added SortOrder (HA-2127)
  2020/01/11  TK      TCubeCartonHdr & TCubeCartonDtls: Added  UDFs (HA-1899)
  2020/07/24  TK      TCartonTypes & TCubeCartonHdr: Added Dimensions (S2GCA-1202)
  2020/05/30  TK      TCubeCartonHdr: Added inventory classes (HA-703)
  2020/05/06  TK      TDetailsToCube, TCubeCartonHdrs, TCubeCartonDtls & TCartonTypes:
  2019/10/07  TK      TCubeCartonHdr: Added more fields
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Holds the list of cartons that are being used for cubing */
Create Type TCubeCartonHdr as Table (

    CartonId                 TRecordId      identity(1,1),
    CartonType               TCartonType,

    LPNId                    TRecordId,
    LPN                      TLPN,
    UCCBarcode               TBarcode,

    WaveId                   TRecordId,
    WaveNo                   TWaveNo,

    OrderId                  TRecordId,
    PickTicket               TPickTicket,

    PackingGroup             TCategory,
    Status                   TStatus        default 'O',  -- O - Open, C - Closed

    EmptyCartonSpace         TFloat,               -- Space available in an empty carton
    SpaceUsed                TFloat         default 0,
    WeightUsed               TWeight        default 0,
    SpaceRemaining           as (EmptyCartonSpace - SpaceUsed),

    MaxUnits                 TCount,
    MaxWeight                TWeight,
    MaxDimension             TFloat,
    FirstDimension           TFloat,
    SecondDimension          TFloat,
    ThirdDimension           TFloat,
    UnitsRemaining           as (MaxUnits - NumUnits),
    WeightRemaining          as (MaxWeight - WeightUsed),

    NumUnits                 TInteger       default 0,
    NumSKUs                  TInteger       default 0,  -- future use

    SalesOrder               TSalesOrder,
    Ownership                TOwnership,
    Warehouse                TWarehouse,

    InventoryClass1          TInventoryClass    DEFAULT '',
    InventoryClass2          TInventoryClass    DEFAULT '',
    InventoryClass3          TInventoryClass    DEFAULT '',

    SortOrder                TSortOrder,
    SortIndex                TInteger,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    Primary Key              (CartonId),
    Unique                   (OrderId, Status, CartonId)
);

Grant References on Type:: TCubeCartonHdr  to public;

Go
