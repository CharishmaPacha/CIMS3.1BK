/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/31  KBB     Loads: Added BoLStatus (HA-2467)
  2021/02/10  TK      Loads: Added EstimatedCartons (HA-1964)
  2020/07/06  AY      Loads: Added StagingLocation, Palletized
  2020/07/01  NB      Loads: Added ShipFrom (CIMSV3-996)
  2020/06/31  RKC     Loads: Add ModifiedOn computed column and index (CIMS-3118)
  2020/06/23  SAK     Loads Added new field ConsolidatorAddressId (HA-1001)
  2019/12/23  AY      Loads, Shipments: Added/Updated indexes (CID-1234)
  2019/10/29  MJ      Loads: Added AppointmentConfirmation, AppointmentDateTime, DeliveryRequestType (S2GCA-1018)
  2019/07/23  AJ      Loads: Added MasterTrackingNo (CId-843)
  2019/07/10  AY      Loads: Added LPNWeight/LPNVolume (CID-785)
  2019/07/10  YJ      Loads: Added new field FreightCharges (CID-749)
  2018/10/31  CK      Loads: SoldToId (OB2-683)
  2015/09/02  RV      Added PickBatchGroup field to Loads (FB-350)
  2015/06/18  AY      Added FoB, BoLCID, BoLInstructions fields to Loads and BoL
  2014/01/06  DK      Loads: Added ShipToId field.
  2013/09/13  NY/AY   Loads: Added FromWarehouse, ClientLoad, MasterBoL
  2013/07/19  AY      Loads: Added Dock Location
  2012/06/28  TD      Loads: Added counts related fields.
  2012/06/18  TD      Added New Tables Loads, Shipments, OrderShipments
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: Loads

    This table contains Load information. This would have Carrier info, Start From,
    Destination Location Information. The dates related to shipping and estimated
    delivery date.

    RoutingStatus
      'P' -'Pending'
        The Routing information is yet to be processed. The Load is allowed to be
        modified and changed in this Routing Status
      'A' - 'Awaiting Confirmation',
        The Routing information is currently in process, the Carrier or Shipping Company
        is expected to respond with the details of Truck and timing for the Pickup
        In this routing status, the Load and underlying shipments etc.,. are frozen, and
        no editing should be allowed as the carrier confirmation is awaited
      'C' - 'Confirmed'
        The Shipping or Trucking company has responded and a confirmation is given that
        the said Load Shipments will be picked up and the Load is marked as Routing status
        confirmed. When in Confirmed Status, the Load cannot be added or removed with any
        shipments

   LoadingMethod
     RF - LPNs/Pallets will be marked as Loaded via RF Loading
     WCS - LPNs will be marked as Loaded when LPNs are confirmed as diverted by WCS
     Auto - LPNs will be marked as Loaded when Orders/LPNs are added to Load
     None - LPNs need not be marked as Loaded to be shipped

   Palletized
     Y - LPNs are on Pallets in the Truck
     N - LPNs are floor loaded onto the Truck

   BoLStatus: A Load can have muttiple BoLs and this is not about the status of those BoLs
              but instead an indicator to know if they have a Final BoL.
              Values are: Not Generated, Generated, ReGenerate,
------------------------------------------------------------------------------*/
Create Table Loads (
    LoadId                   TLoadId        identity (1,1) not null,

    LoadNumber               TLoadNumber    not null,
    LoadType                 TTypeCode      not null,

    Status                   TStatus        not null default 'N' /* New*/,

    RoutingStatus            TStatus        not null default 'P' /* Pending */,
    LoadingMethod            TTypeCode      default 'RF',

    ShipVia                  TShipvia,
    Priority                 TPriority,

    TrailerNumber            TTrailerNumber,
    SealNumber               TSealNumber,
    ProNumber                TProNumber,
    MasterTrackingNo         TTrackingNo,

    FromWarehouse            TWarehouse,
    ShipFrom                 TShipFrom,
    Account                  TAccount,
    AccountName              TAccountName,
    SoldToId                 TCustomerId,
    ShipToId                 TShipToId,
    ShipToDesc               TDescription, -- could be multiple DCs or Stores
    ConsolidatorAddressId    TContactRefId,
    DockLocation             TLocation,
    StagingLocation          TLocation,
    ClientLoad               TLoadNumber,
    MasterBoL                TBoLNumber,
    BoLStatus                TStatus,
    FoB                      TFlags,
    BoLCID                   TBoLCID,   -- To be printed on all BoLs of the Load
    LoadGroup                TLoadGroup default '',
    PickBatchGroup           TWaveGroup,  -- Deprecated
    Palletized               TFlags,

    DesiredShipDate          TDateTime,
    ShippedDate              TDateTime,
    DeliveryDate             TDateTime,
    CarrierCheckIn           TTime,
    CarrierCheckOut          TTime,
    TransitDays              TCount,

    NumOrders                TCount         default 0,
    NumPallets               TCount         default 0,
    NumLPNs                  TCount         default 0,
    NumPackages              TCount         default 0,
    NumUnits                 TCount         default 0,
    EstimatedCartons         TCount         default 0,
    TotalShipmentValue       TMoney,

    Volume                   TVolume        default 0.0,
    Weight                   TWeight        default 0.0,
    AppointmentConfirmation  TDescription,
    AppointmentDateTime      TDateTime,
    DeliveryRequestType      TLookupCode,

    LPNVolume                TVolume        default 0.0,
    LPNWeight                TWeight        default 0.0, -- Actual product volume/weight (does not include tare weight)
    FreightCharges           TMoney,

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

    CreatedOn                as cast (CreatedDate as date),
    ModifiedOn               as cast (ModifiedDate as date),

    constraint pkLoads_LoadId     PRIMARY KEY (LoadId),
    constraint ukLoads_LoadNumber UNIQUE (LoadNumber, BusinessUnit)
);

/* Used in pr_Archive_Loads */
create index ix_Loads_Archived   on Loads (Archived, Status) Include (ModifiedOn, CreatedOn, CreatedBy);
create index ix_Loads_Status     on Loads (Status) Include (NumOrders, CreatedBy);
create index ix_Loads_LoadGroup  on Loads (LoadGroup, Archived) include (Status);

/*
  Add Indexes for the following
    Composite Index for ShipVia, DesiredShipDate, Status
    Composite Index for LoadType, Status
    Composite Index for ShippedDate, Status

*/

Go
