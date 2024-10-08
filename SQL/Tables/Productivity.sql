/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/30  SK      Productivity tables: further enhancements (HA-2937)
  2020/03/06  SK      All tables related to Productivity moved from def_AuditTrail.sql (CIMS-2967)
  2020/01/02  SK      ProductivityDetails: Revisions post the new design discussion (CIMS-2871)
  2017/08/04  TK      ProductivityDetails: Initial Revision (CIMS-1426)
  2016/10/10  AY      Productivity: Added several fields for Packing productivity statistics.
  2013/11/23  VP      Productivity: Added Index ixProductivityOpEntity
  2013/07/17  TD      Added ProductivityId to AuditTrail Table.
  2012/08/30  AY      Productivity: Added table
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: Productivity

 Operation    - can be BatchPick
 SubOperation - can be PalletPick, LPNPick, Unit Pick
------------------------------------------------------------------------------*/
Create Table Productivity (
    ProductivityId           TRecordId      identity (1,1) not null,

    Operation                TDescription,
    SubOperation             TDescription,
    JobCode                  TJobCode,

    UserId                   TUserId,
    Assignment               TDescription,
    ActivityDate             TDate,
    StartDateTime            TDateTime,
    EndDateTime              TDateTime,
    DurationInSecs           TInteger,

    NumWaves                 TCount,
    NumOrders                TCount,
    NumLocations             TCount,
    NumPallets               TCount,
    NumLPNs                  TCount,
    NumInnerPacks            TCount,
    NumUnits                 TCount,
    NumTasks                 TCount,
    NumPicks                 TCount,
    NumSKUs                  TCount,

    Weight                   TFloat,
    Volume                   TFloat,

    EntityType               TTypeCode,
    EntityId                 TRecordId,
    EntityKey                TEntity,

    /* SKU */
    SKUId                    TRecordId,
    SKU                      TSKU,
    /* LPN */
    LPNId                    TRecordId,
    LPN                      TLPN,
    /* Location */
    LocationId               TRecordId,
    Location                 TLocation,
    /* Pallet */
    PalletId                 TRecordId,
    Pallet                   TPallet,
    /* Receipt */
    ReceiptId                TRecordId,
    ReceiptNumber            TReceiptNumber,
    /* Receiver */
    ReceiverId               TRecordId,
    ReceiverNumber           TReceiverNumber,
    /* Order */
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    /* Wave */
    WaveId                   TRecordId,
    WaveNo                   TWaveNo,
    WaveType                 TTypeCode,
    WaveTypeDesc             TDescription,
    /* Task */
    TaskId                   TRecordId,
    TaskDetailId             TRecordId,

    Comment                  TVarChar,
    Status                   TStatus        default 'A' /* Active */,
    Archived                 TFlag          default 'N',

    UserName                 TName,
    Warehouse                TWarehouse,
    Ownership                TOwnership,
    DeviceId                 TDeviceId,
    ParentRecordId           TRecordId,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    CreatedOn                as (cast(CreatedDate as date)),

    constraint pkProductivity PRIMARY KEY (ProductivityId)
);

create index ix_Productivity_Archived             on Productivity (Archived);
create index ix_Productivity_Operation            on Productivity (Operation, SubOperation);
create index ix_Productivity_OpEntity             on Productivity (Operation, EntityId, UserId, BusinessUnit, Status);
/* used in pr_Prod_ProcessATRecord */
create index ix_Productivity_UserAssignment       on Productivity (UserId, Assignment) Include(ActivityDate);
create index ix_Productivity_ActivityDate         on Productivity (ActivityDate, Operation) Include (SubOperation, WaveType);

Go
