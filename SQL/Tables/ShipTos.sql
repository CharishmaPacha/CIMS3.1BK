/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/08/26  AY      ShipTos: Added ShipToName
  2011/08/03  PK      OrderHeaders: Added PickBatchNo, ShipTos: Added Status.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: Ship Tos - Deprecated?
------------------------------------------------------------------------------*/
Create Table ShipTos (
    RecordId                 TRecordId      identity (1,1) not null,

    CustomerId               TCustomerId    not null,
    ShipToId                 TShipToId      not null,
    ShipToName               TName,
    ShipToAddressId          TRecordId      not null,
    Status                   TStatus        default 'A',

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkShipTos_RecordId       PRIMARY KEY (RecordId),
    constraint ukShipTos_CustomerShipTo UNIQUE (CustomerId, ShipToId)
);

Go
