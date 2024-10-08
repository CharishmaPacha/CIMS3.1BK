/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/02/23  SK      Added new column SourceSystem and updated ix_CarrierTrackingInfo_Archived (BK-1025)
  2022/11/01  SK      CarrierTrackingInfo: Added ExportFreq, ExportPriority (BK-956)
  2022/10/04  VS      CarrierTrackingInfo: Added DeliveryStatus (BK-920)
  2022/07/14  AY      CarrierTrackingInfo: Added ModifiedOn, Added ix_CarrierTrackingInfo_Created/ModifiedOn (BK-865)
  2021/10/07  TK      CarrierTrackingInfo: Added ix_CarrierTrackingInfo_LPNId (BK-626)
  2021/05/19  TK      CarrierTrackingInfo: Added DeliveredOn (BK-291)
  2021/03/19  TK      CarrierTrackingInfo: Added ix_CarrierTrackingInfo_DeliveryDateTime (BK-291)
  2021/02/11  AY      CarrierTrackingInfo: New table
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: CarrierTrackingInfo: Used to keep track of the SPG Carrier tracking information.
    There is expected to be only one record for each package shipped.

  Carriers will send different info in different methods, this table is to synthesize
  them into a common platform. However, the statuses used may be descriptive or cryptic

  LastEvent: UPS  - package.activity (most recent).status.description
             USPS - TrackResponse.TrackSummary.Event

  ExportStatus: Takes 3 values
                None: The record will remain in this state until a tracking response is received
                ToBeExported: Updated after any successful tracking response is received
                Exported: Updated after export is successful
                Failed: If the API processing was not successful, export will be regarded as this
  ExportFreq: Frequency with which exports should be sent out. Depends on carrier service.
              Inserted when record is being inserted into the table.
              Values: Daily1Hr to Daily24Hr
  ExportPriority: Integer substring of ExportFreq. default is 24. This is used during records batching
                  to send as updates
                  Values: 1 to 24
------------------------------------------------------------------------------*/
Create Table CarrierTrackingInfo (
    RecordId                 TRecordId      identity (1,1) not null,

    TrackingNo               TTrackingNo,
    Carrier                  TCarrier,
    LPN                      TLPN,
    PickTicket               TPickTicket,
    WaveNo                   TWaveNo,
    /* Final delivery info */
    DeliveryStatus           TStatus       default 'Not Delivered',  -- Not Delivered or Delivered
    DeliveryDateTime         TDateTime,                              -- the final delivery date and time
    /* Last known event/activity details */
    LastEvent                TDescription,                           -- Last known status/event as given by carrier
    LastUpdateDateTime       TDateTime,
    LastLocation             TDescription,
    /* Internal fields */
    LPNId                    TRecordId,
    OrderId                  TRecordId,
    WaveId                   TRecordId,
    APIRecordId              TRecordId,
    /* Carrier */
    RequestBatch             TBatch         not null default 0,
    ResponseReceived         TDateTime,
    /* To be exported to host */
    ExportStatus             TStatus        default 'None',                  /* None */
    ExportInstance           TDescription,                                 /* Some times we running multiple instance to export shiping labels, So we are saving which instance processed this label*/
    ExportBatch              TBatch         not null default 0,
    ExportFreq               TDescription   default 'Daily24Hr',
    ExportPriority           TInteger       default 24,
    ExportedDate             TDateTime,

    AlertSent                TFlags         default 'NR',                  /* Y - Yes, NR - Not required, T - To be sent */
    ActivityInfo             TVarchar,                                     /* to store any additional information retrieved from shipper */

    SourceSystem             TName,
    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    CreatedOn                as convert(date, CreatedDate),
    ModifiedOn               as convert(date, ModifiedDate),
    DeliveredOn              as convert(date, DeliveryDateTime),

    constraint pkCarrierTrackingInfo_RecordId    PRIMARY KEY (RecordId),
    constraint ukCarrierTrackingInfo_TrackingNo  UNIQUE (TrackingNo, Carrier)
);

/* Included DeliveryStatus for exports  */
create index ix_CarrierTrackingInfo_Archived        on CarrierTrackingInfo (Archived, ExportStatus, BusinessUnit) include (Carrier, SourceSystem, DeliveryStatus, DeliveredOn, ActivityInfo);
create index ix_CarrierTrackingInfo_LPNId           on CarrierTrackingInfo (LPNId);
/* Used by pr_OrderHeaders_OrderDeliveryStatus */
create index ix_CarrierTrackingInfo_CreatedOn       on CarrierTrackingInfo (CreatedOn) Include(OrderId, RecordId);
create index ix_CarrierTrackingInfo_ModifiedOn      on CarrierTrackingInfo (ModifiedOn) Include(OrderId, RecordId);
/* For Exports */
create index ix_CarrierTrackingInfo_APIRecordId     on CarrierTrackingInfo (APIRecordId) Include(OrderId, RecordId);
/* For Alert */
create index ix_CarrierTrackingInfo_DeliveryStatus  on CarrierTrackingInfo (DeliveryStatus, Archived) Include(OrderId, RecordId);

Go
