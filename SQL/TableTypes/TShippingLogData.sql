/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/16  OK      TShippingLogData: Changed the data type of DesiredShipDate and CancelDate to TDateTime as original table data is type of TDateTime (HA-2291)
  2021/03/13  OK      TShippingLogData: Added LoadType, LoadStatus and ShipToId (HA-2264)
  2021/03/10  AY      TShippingLogData: (HA-1093)
  2020/09/30  KBB     Added TShippingLogData (HA-1093)
  Create Type TShippingLogData as table (
  Grant References on Type:: TShippingLogData to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TShippingLogData as table (
    ShipFrom                 TShipFrom,
    ShipFromName             TName,
    Warehouse                TWarehouse,
    WarehouseDesc            TDescription,

    LoadId                   TRecordId,
    Loadnumber               TLoadNumber,
    ClientLoad               TLoadNumber,
    LoadType                 TTypeCode,
    LoadTypeDesc             TDescription,
    LoadStatus               TTypeCode,
    LoadStatusDesc           TDescription,
    RoutingStatusDesc        TDescription,

    Account                  TAccount,
    AccountName              TAccountName,

    DesiredShipDate          TDateTime,
    CancelDate               TDateTime,
    ShippedDate              TDateTime,

    CustPO                   TCustPO,
    ShipToDC                 TShipToStore,
    ShipToStore              TShipToStore,

    ShipToId                 TShipToId,
    ShipToName               TName,
    ShipToCityState          TName, -- City, State
    ShipToCity               TCity,
    ShipToState              TState,
    ShipToZip                TZip,

    ShipVia                  TShipVia,
    ShipViaDesc              TDescription,

    LPNsAssigned             TCount,
    EstimatedCartons         TCount,
    TotalWeight              TWeight,
    TotalVolume              TVolume,

    Count1                   TInteger,
    Count2                   TInteger,
    Count3                   TInteger,
    Count4                   TInteger,
    Count5                   TInteger,

    AppointmentConfirmation  TDescription,
    AppointmentDateTime      TDateTime,
    ApptTime                 TString,
    GroupCriteria            TCategory,

    /* UDF Fields for descriptive info */
    UDFDesc1                 TVarchar,
    UDFDesc2                 TVarchar,
    UDFDesc3                 TVarchar,
    UDFDesc4                 TVarchar,
    UDFDesc5                 TVarchar,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    Archived                 TFlag,
    BusinessUnit             TBusinessUnit,
    ModifiedDate             TDateTime,
    ModifiedBy               TUserId,
    CreatedDate              TDateTime,
    CreatedBy                TUserId,

    RecordId                 TRecordId identity(1,1)
);

Grant References on Type:: TShippingLogData to public;

Go
