/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/02/12  DK      SrtrWaveDetails: Added WaveDropLocation, TrackingNo, EstimatedWeight,
  2014/09/11  PK      SrtrWaveDetails, SrtrLPNs: Added AllocatedQty.
  2014/08/30  AY      SrtrWaveDetails: Added SKUDescription
  2014/04/11  PK      SrtrWaveDetails: Added Weight, Warehouse.
  2014/03/27  TK/TD   SrtrWaveDetails: Added and removed fields as per new document.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: SrtrWaveDetails.

    SorterName : This is about destination , may be we will decide this based on
      Wave-Type.

------------------------------------------------------------------------------*/
Create Table SrtrWaveDetails (
    RecordId                 TRecordId      identity (1,1) not null,

    WaveId                   TRecordId,
    WaveNo                   TWaveNo,        --Map to OrderWaveId
    WaveType                 TTypeCode,
    WaveDropLocation         TLocation,

    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    SalesOrder               TSalesOrder,
    OrderType                TTypeCode,
    Description              TDescription,   --Map to Description

    LPNId                    TRecordId,
    LPN                      TLPN,           --Map to CartonId
    TrackingNo               TTrackingNo,
    EstimatedWeight          TWeight        default 0.0,
    LPNNumLines              TCount         default 0,
    CartonType               TCartonType,

    PickZone                 TZoneId,
    /* future use */
    OrderDetailId            TRecordId,
    SKUId                    TRecordId,
    SKU                      TSKU,
    Barcode                  TUPC,
    SKUDescription           TDescription,
    IsSortable               TFlags,

    Quantity                 TQuantity,
    AllocatedQty             TQuantity,

    PackSize                 TInteger,
    PickLocation             TLocation,
    Volume                   TVolume,
    Weight                   TWeight,

    Status                   TStatus,         --Map to Done

    ExportedStatus           TStatus        default 'N',
    ExportedDate             TDateTime,

    SorterName               TName,           --Map to SorterId
    LastCarton               TFlag          default 'N',

    Warehouse                TWarehouse,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    CreatedOn                As convert(date, ExportedDate),
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

  constraint pkSrtrWaveDetails_RecordId PRIMARY KEY (RecordId)

);

create index ix_SrtrWaveDetails_ExportedStatus   on SrtrWaveDetails (ExportedStatus, WaveNo) Include (CreatedDate, WaveId);
create index ix_SrtrWaveDetails_WaveNo           on SrtrWaveDetails (WaveNo, SorterName);
create index ix_SrtrWaveDetails_WaveId           on SrtrWaveDetails (WaveId, ExportedStatus, OrderId, LPNId) Include (Quantity, CreatedDate, RecordId);

Go
