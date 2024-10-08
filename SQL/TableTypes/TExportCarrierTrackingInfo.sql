/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/15  TD      Added new domain TExportCarrierTrackingInfo (BK-207)
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type to use for TExportCarrierTrackingInfo date to host
   This table structure mimics the record structure of CarrierTrackingInfo */
Create Type TExportCarrierTrackingInfo as Table
  (
    TrackingNo               TTrackingNo,
    Carrier                  TCarrier,
    LPN                      TLPN,
    PickTicket               TPickTicket,

    /* Final delivery info */
    DeliveryStatus           TStatus,      -- Not Delivered or Delivered
    DeliveryDateTime         TDateTime,    -- the final delivery date and time

    /* Last known event/activity details */
    LastEvent                TDescription, -- Last known status/event as given by carrier
    LastUpdateDateTime       TDateTime,
    LastLocation             TDescription,

    ActivityInfo             TVarchar,                                     /* to store any additional information retrieved from shipper */
    ExportBatch              TBatch,

    SourceSystem             TName,
    BusinessUnit             TBusinessUnit,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,
    CIMSRecId                TRecordId,

    RecordId                 TRecordId      identity (1,1) not null

    Primary Key              (RecordId)
  );

Grant References on Type:: TExportCarrierTrackingInfo to public;

Go
