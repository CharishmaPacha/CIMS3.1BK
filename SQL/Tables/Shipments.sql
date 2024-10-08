/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/12/23  AY      Loads, Shipments: Added/Updated indexes (CID-1234)
  2012/10/16  AY      Created indices on Shipments, OrderShipments
  2012/06/18  TD      Added New Tables Loads, Shipments, OrderShipments
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: Shipments

    This table contains Shipments Header or Summary Information. This would have
    #of Orders, Pallets, LPNs, Packages and Units and shipment Status Can be assumed
    to be the min status of the Orders on the shipment or can be calculated a new
    set of status values based on the diff status values of the Ordders associated
    with the Shipments.

------------------------------------------------------------------------------*/
Create Table Shipments (
    ShipmentId               TShipmentId    identity (1,1) not null,

    ShipFrom                 TShipFrom      not null,
    SoldTo                   TCustomerId    not null,
    ShipTo                   TShipToId      not null,
    ShipVia                  TShipVia       not null,
    BillTo                   TCustomerId,

    FreightTerms             TLookUpCode    not null,
    ShipmentValue            TPrice,

    IsSmallPackage           TFlag          not null default 'N',
    ShipmentType             TLookUpCode    not null default 'C', /* Customer Shipment*/

    Status                   TStatus        not null default 'N', /* New */
    Priority                 TPriority,

    MaxOrders                TCount         default 0,
    MaxPallets               TCount         default 0,
    MaxLPNs                  TCount         default 0,
    MaxUnits                 TCount         default 0,

    NumOrders                TCount         default 0,
    NumPallets               TCount         default 0,
    NumLPNs                  TCount         default 0,
    NumPackages              TCount         default 0,
    NumUnits                 TCount         default 0,

    LoadId                   TLoadId,
    LoadNumber               TLoadNumber,
    LoadSequence             TSequence,

    BoLId                    TRecordId,
    BoLNumber                TBoLNumber,    --Future Use

    DesiredShipDate          TDateTime,
    ShippedDate              TDateTime,
    DeliveryDate             TDateTime,
    TransitDays              TCount,

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

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,

    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkShipments_ShipmentId PRIMARY KEY (ShipmentId),

);

create index ix_Shipments_LoadId                 on Shipments(LoadId) Include(ShipmentId, Status);
/* used in pr_BoL_GenerateCarrierDetails */
create index ix_Shipments_BoLId                  on Shipments(BoLId) Include(LoadId, ShipmentId);

Go
