/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/02/24  SK      TCarrierTrackingData: Added SourceSystem (BK-1025)
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TCarrierTrackingData as Table (

  TrackingNo                 TTrackingNo,
  Carrier                    TCarrier,
  LPNId                      TRecordId,
  LPN                        TLPN,
  --order info
  OrderId                    TRecordId,
  PickTicket                 TPickTicket,
  --ship via info
  ServiceClass               TDescription,
  --wave info
  WaveId                     TRecordId,
  WaveNo                     TWaveNo,
  --export info
  ExportFreq                 TDescription,
  ExportPriority             TInteger,
  --Other info
  SourceSystem               TName,
  BusinessUnit               TBusinessUnit,
  CreatedBy                  TUserId

);

grant references on Type:: TCarrierTrackingData to public;

Go
