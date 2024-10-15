/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/03/20  VS      TCarrierResponseData: Added BillToAccount (JLFL-297)
  2022/10/18  VS      TCarrierResponseData: Initial version (CIMSV3-1780)
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TCarrierResponseData as Table (
    RecordId                 TRecordId identity(1,1),

    EntityId                 TRecordId,
    EntityKey                TEntityKey,
    LPNId                    TRecordId,
    LPN                      TLPN,
    LPNStatus                TStatus,
    PackageSeqNo             TInteger,
    -- Order Info
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    -- Wave Info
    WaveId                   TRecordId,
    WaveNo                   TWaveNo,
    WaveType                 TTypeCode,
    TotalPackages            TCount,
    -- Label Details
    LabelType                TTypeCode,
    Label                    TShippingLabel,
    ZPLLabel                 TVarchar,
    TrackingNo               TTrackingNo,
    TrackingBarcode          TTrackingNo,
    Barcode                  TVarChar,
    -- Carrier details
    Carrier                  TDescription,
    ShipVia                  TDescription,
    IsSmallPackageCarrier    TFlags,
    RequestedShipVia         TShipVia,
    ServiceSymbol            TCarrier,
    CarrierInterface         TCarrierInterface,
    MSN                      TCarrier,
    BillToAccount            TAccount,
    -- Charges
    ListNetCharge            TMoney,
    AcctNetCharge            TMoney,
    InsuranceFee             TMoney,
    -- Package Dims
    PackageLength            TLength,
    PackageWidth             TLength,
    PackageHeight            TLength,
    PackageWeight            TWeight,
    PackageVolume            TVolume,
    -- Additional Info
    Reference                xml,
    Notifications            TVarChar,
    NotificationSource       TVarChar,
    NotificationTrace        TVarChar,
    BusinessUnit             TBusinessUnit,
    ShipLabelRecordId        TRecordId
);

grant references on Type:: TCarrierResponseData to public;

Go
