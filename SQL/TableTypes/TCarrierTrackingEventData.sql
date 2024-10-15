/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/11/07  SK/AY   TCarrierTrackingEventData: New Type (BK-956)
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TCarrierTrackingEventData as Table (

  TrackingNo                 TTrackingNo,
  Carrier                    TCarrier,
  LPNId                      TRecordId,
  LPN                        TLPN,
  -- Order info
  OrderId                    TRecordId,
  PickTicket                 TPickTicket,
  -- Event info
  EventDateTime              TDateTime,
  EventDesc                  TResult,
  EventLocation              TDescription,
  EventStatusDesc            TResult,
  EventStatusType            TDescription,
  --
  RecordId                   TRecordId
);

grant references on Type:: TCarrierTrackingEventData to public;

Go
