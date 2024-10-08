/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/13  SK      TUserProductivity: Initial version (HA-2972)
------------------------------------------------------------------------------*/

Go

if type_id('dbo.TUserProductivity') is not null drop type TUserProductivity;
/*---------------------------------------------------------------------------------------
 TUserProductivity: Table Type for User productivity data set dervied from vwProductivity
---------------------------------------------------------------------------------------*/
Create Type TUserProductivity as Table (
    ProductivityId             TRecordId,

    Operation                  TDescription,
    SubOperation               TDescription,
    JobCode                    TJobCode,
    Assignment                 TDescription,

    ActivityDate               TDate,

    NumWaves                   TCount,
    NumOrders                  TCount,
    NumLocations               TCount,
    NumPallets                 TCount,
    NumLPNs                    TCount,
    NumTasks                   TCount,
    NumPicks                   TCount,
    NumSKUs                    TCount,
    NumUnits                   TCount,
    NumAssignments             TCount,

    Weight                     TFloat,
    Volume                     TFloat,

    EntityType                 TTypeCode,
    EntityId                   TRecordId,
    EntityKey                  TEntity,

    SKUId                      TRecordId,
    SKU                        TSKU,
    LPNId                      TRecordId,
    LPN                        TLPN,
    LocationId                 TRecordId,
    Location                   TLocation,
    PalletId                   TRecordId,
    Pallet                     TPallet,
    ReceiptId                  TRecordId,
    ReceiptNumber              TReceiptNumber,
    ReceiverId                 TRecordId,
    ReceiverNumber             TReceiverNumber,
    OrderId                    TRecordId,
    PickTicket                 TPickTicket,
    WaveNo                     TWaveNo,
    WaveId                     TRecordId,
    WaveType                   TTypeCode,
    WaveTypeDesc               TDescription,
    TaskId                     TRecordId,
    TaskDetailId               TRecordId,

    DayNumber                  TInteger,
    Day                        TString,
    DayMonth                   TString,
    WeekNumber                 TInteger,
    Week                       TString,
    MonthWeek                  TString,
    MonthNumber                TInteger,
    MonthShort                 TString,
    Month                      TString,
    Year                       TInteger,

    StartDateTime              TDateTime,
    EndDateTime                TDateTime,

    Duration                   TString,
    DurationInSecs             TInteger,
    DurationInMins             TInteger,
    DurationInHrs              TInteger,

    UnitsPerMin                TInteger,
    UnitsPerHr                 TInteger,

    Comment                    TVarChar,
    Status                     TStatus,
    Archived                   TFlag,

    DeviceId                   TDeviceId,
    UserId                     TUserId,
    UserName                   TName,
    ParentRecordId             TRecordId,

    Warehouse                  TWarehouse,
    Ownership                  TOwnership,
    BusinessUnit               TBusinessUnit,
    CreatedDate                TDateTime,
    ModifiedDate               TDateTime,
    CreatedBy                  TUserId,
    ModifiedBy                 TUserId,
  
    RecordId                   TRecordId    identity (1,1),

    Primary Key (RecordId)
);

Grant References on Type:: TUserProductivity to public;

Go
