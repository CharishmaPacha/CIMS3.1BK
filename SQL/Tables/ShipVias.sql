/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/09/22  MS      ShipVias: Added CutOffTime (MBW-473)
  2023/05/26  PKK     ShipVias: Added TransitDays (FBV3-1568)
  2020/11/24  KBB     ShipVias: Added ServiceClassDesc, SCAC, ServiceClass (HA-1670)
  2018/08/06  TK      ShipVias: Added IsSmallPackageCarrier (S2GCA-121)
  2017/01/17  NB      Added SpecialServices column to ShipVias(HPI-1270)
  2012/06/21  AY      ShipVias: Added description
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: ShipVias

  Maps the ShipVia Codes with Carrier specific codes and along with, holds the service
  level options to use, when processing transactions or generating ship labels

  CarrierServiceCode - Service Code as given by the Carrier
                        Ex: FEDEX_GROUND, STANDARD_OVERNIGHT
  StandardAttributes - Service Options to use for transactions
                       Ex:
                         <LABELIMAGETYPE>PNG</LABELIMAGETYPE>
                         <LABELFORMAT>COMMON2D</LABELFORMAT>
                         <LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE>
                         <CARRIER>FEDEX</CARRIER>
                         <SERVICECODE>FEDEX_GROUND</SERVICECODE>
                         <PACKAGINGTYPE>YOUR_PACKAGING</PACKAGINGTYPE>
                         <RATEREQUESTTYPES>ACCOUNT</RATEREQUESTTYPES>
                         <ISCODSHIPMENT>false</ISCODSHIPMENT>
  SpecialServices - Special Service options to use for transactions
                    Ex: <SERVICETYPE>SD</SERVICETYPE>

  ServiceClass: GND, AIR, CON

  Consolidator. Shipping to a consolidator means that the Load is going to ship
    to a consolidator who will ship to the end party. So, when Load is chosen to
    ship to a consolidator, we set the consolidator address on the Load corresponding
    to the ship via. So, if ShipVia is ABC, then the consolidator address will be FC-ABC.

  CutOffTime: This is applicable for small package carriers. Small package carriers
    pick up the packages at a certain time and hence all packages packed after a
    certain time of the day would have to be considered with the next ship date. The
    time when the ship date shifts from current dqy to next day is considred as the CutOffTiime.
------------------------------------------------------------------------------*/
Create Table ShipVias (
    RecordId                 TRecordId      identity (1,1) not null,

    ShipVia                  TShipvia       not null,
    Carrier                  TCarrier       not null,
    Description              TDescription,

    CarrierServiceCode       varchar(50), /* LTL Carriers will not have this */
    StandardAttributes       varchar(max),
    SpecialServices          varchar(max),

    ServiceClass             TDescription,
    ServiceClassDesc         TDescription,
    SCAC                     TShipVia,
    CutOffTime               time,
    TransitDays              TInteger,
    IsSmallPackageCarrier    TFlags         default 'N' /* No */,
    Status                   TStatus        not null default 'A' /* Active*/,
    SortSeq                  TSortSeq       default 0,
    BusinessUnit             TBusinessUnit  not null,

    CreatedDate              TDateTime      default getdate(),
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkShipVias_RecordId primary key (RecordId),
    constraint ukShipVias_ShipVia  unique (ShipVia, BusinessUnit)
);

create index ix_ShipVias_ShipVia on ShipVias (ShipVia, BusinessUnit, Status) include (Carrier, Description);

Go
