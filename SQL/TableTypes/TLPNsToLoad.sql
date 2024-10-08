/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/19  AY      TLPNsToLoad: Renamed status as LPNStatus (HA-2002)
  2021/01/31  TK      TLPNsToLoad: Added fields that are required to Create Shipments in bulk (HA-1947)
  2020/01/24  AY      TLPNsToLoad: Added LoadNumber, BoLNumber (HA-1947)
  2020/07/24  RT      TLPNsToLoad: Added (S2GCA-970)
  2020/01/21  TK      TLPNsToLoad: Added (S2GCA-970)
  Create Type TLPNsToLoad as Table (
  Grant References on Type:: TLPNsToLoad   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TLPNsToLoad as Table (
    RecordId                  TRecordId identity(1,1) not null,

    LPNId                     TRecordId,
    LPN                       TLPN,
    LPNStatus                 TStatus,
    PalletId                  TRecordId,
    Pallet                    TPallet,

    OrderId                   TRecordId,
    PickTicket                TPickTicket,
    OrderType                 TTypeCode,
    DesiredShipDate           TDateTime,
    FreightTerms              TDescription,

    WaveId                    TRecordId,
    WaveNo                    TWaveNo,

    ShipFrom                  TShipFrom,
    ShipToId                  TShipToId,
    SoldToId                  TCustomerId,
    ShipVia                   TShipVia,

    LoadId                    TLoadId,
    LoadNumber                TLoadNumber,
    ShipmentId                TShipmentId,
    BoLId                     TBoLId,
    BoLNumber                 TBoLNumber,

    UDF1                      TUDF,
    UDF2                      TUDF,
    UDF3                      TUDF,
    UDF4                      TUDF,
    UDF5                      TUDF

    Primary Key               (RecordId)
);

Grant References on Type:: TLPNsToLoad   to public;

Go
