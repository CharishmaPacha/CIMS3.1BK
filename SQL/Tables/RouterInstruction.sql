/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/05  MS      RouterInstruction: Added UDF1 to UDF5 (JL-294)
  2018/04/23  AY      RouterInstruction: Added RouteLPN & UCC Barcode (S2G-684)
  2018/02/14  DK      RouterInstruction: Added TrackingNo and EstimatedWeight, OrderId (S2G-232)
  2014/08/05  AY      RouterInstruction: Added WaveId, WaveNo and changed type of WorkId
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: RouterInstruction

  When CIMS is integrated with DCMS, we would need to send instructions to DCMS
  on how to route the cartons. This table is the staging table used to generate
  such instructions. An export process would take the data from this table and
  post it to DCMS with the appropriate interface.

  Fields:
  RouteLPN         A carton riding on the conveyor that needs to be routed may have multiple
                   barcodes on it i.e. the LPN barcode, UCC, TrackingNo etc. The RouteLPN
                   is to indicate to DCMS the barcode it needs to look for to route the carton

  Destination      The lane/destination for the LPN being routed. There usually is an
                   agreed upon convention between DCMS and CIMS for this.

  WorkId           In some cases, routing is dynamically done in DCMS i.e. the specific
                   lane to be routed is determined by DCMS and in such cases the Destination
                   is the Zone for the carton and within that zone, WorkId would determine
                   how to route the carton. For example, at GNC, there are multiple pack
                   stations and some have bagging machines and some not. So, the WorkId
                   specifies that the carton needs bagging and DCMS figures out based upon
                   lane capacity and fullness and routes the carton to one of the lanes
                   which has bagging machine.

  ExportStatus     N - Need to be Exported, Y - Exported
------------------------------------------------------------------------------*/
Create Table RouterInstruction (
    RecordId                 TRecordId      identity (1,1) not null,

    LPNId                    TRecordId,
    LPN                      TLPN,
    TrackingNo               TTrackingNo,
    UCCBarcode               TBarcode,
    RouteLPN                 TLPN, -- Used to determine the primary number used by DCMS for routing
    EstimatedWeight          TWeight default 0.0,

    WaveId                   TRecordId,
    WaveNo                   TWaveNo,
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    ReceiptId                TRecordId,
    ReceiptNumber            TReceiptNumber,

    Destination              TLocation,
    WorkId                   TWorkId,

    ExportStatus             TStatus        default 'N' /* Need to be Exported */,
    ExportDateTime           TDateTime,
    ExportBatch              TBatch         not null default 0,
    ExportedOn               As convert(date, ExportDateTime),

    RI_UDF1                  TUDF,
    RI_UDF2                  TUDF,
    RI_UDF3                  TUDF,
    RI_UDF4                  TUDF,
    RI_UDF5                  TUDF,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkRouteInstruction_RecordId  PRIMARY KEY (RecordId)
);

create index ix_RouterInstruction_LPNId          on RouterInstruction (LPNId) Include (Archived);
create index ix_RouterInstruction_LPN            on RouterInstruction (LPN) Include (Archived);
create index ix_RouterInstruction_ExportStatus   on RouterInstruction (ExportStatus) Include (LPNId, LPN);
/* Purging */
create index ix_RouterInstruction_ExportedOn     on RouterInstruction (Archived, ExportedOn) Include (ExportStatus);
/* For Receiving Sortation lookups */
create index ix_RouterInstruction_ReceiptNumber  on RouterInstruction (ReceiptNumber) Include (Archived, LPN, RecordId);
create index ix_RouterInstruction_ReceiptId      on RouterInstruction (ReceiptId);

Go
