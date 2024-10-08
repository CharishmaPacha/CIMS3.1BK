/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/07/18  AY      BoLs: Added ShipmentId
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: BoLs -
    Header Table to capture the BoL Header information- This information will be
    the one to be used by Bill Of Lading Report

  ShipFromAddressId  -- Foreign Key from Contacts Table for ShipFrom of the Shipment
  ShipToAddressId    -- Foreign Key from Contacts Table for ShipTo of the Shipment
  BillToAddressId    -- Foreign Key from Contacts Table for BillTo of the
                        Shipment This can be the same as ShipTo in most casess
------------------------------------------------------------------------------*/
Create Table BoLs (

    BoLId                    TRecordId      identity (1,1) not null,
    BoLNumber                TBoLNumber     not null,
    VICSBoLNumber            TVICSBoLNumber,

    BoLType                  TTypeCode      default 'U',
    BoLTypeDesc              As case when BoLType = 'M' then 'Master' else 'Underlying' end,
    LoadId                   TLoadId,
    ShipmentId               TShipmentId,

  /* Future use - for now all values from Loads would be used */
    TrailerNumber            TTrailerNumber,
    SealNumber               TSealNumber,
    ProNumber                TProNumber,

    ShipVia                  TShipvia,
    ShipFromAddressId        TRecordId,
    ShipToAddressId          TRecordId,
    BillToAddressId          TRecordId,

    ShipToLocation           TShipToLocation,
    FoB                      TFlags,
    BoLCID                   TBoLCID,
    MasterBoL                TBoLNumber,
    FreightTerms             TLookUpCode,
    BoLInstructions          TVarchar,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,
    UDF6                     TUDF,
    UDF7                     TUDF,
    UDF8                     TUDF,
    UDF9                     TUDF,
    UDF10                    TUDF,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkBoL_BoLId     PRIMARY KEY (BoLId),
    constraint ukBoL_BoLNumber UNIQUE (BoLNumber, BusinessUnit)
);

create index ix_BoLs_LoadId                      on BoLs (LoadId) Include (BoLId, VICSBoLNumber, BoLType);

Go
