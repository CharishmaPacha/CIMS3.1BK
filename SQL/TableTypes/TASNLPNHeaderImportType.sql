/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TASNLPNHeaderImportType: UDF Renamed as LH_UDF1 to 5 and Removed from 6-30 UDF's
  2019/02/22  RIA     TASNLPNImportType, TASNLPNHeaderImportType: Changed LPNId type (CID-87)
  2019/02/04  TD      TASNLPNHeaderImportType,TASNLPNImportType  (CID-66)
  2019/02/02  AY      Earlier TASNLPNImportType renamed to TASNLPNHeaderImportType
  Create Type TASNLPNHeaderImportType as Table (
  Grant References on Type:: TASNLPNHeaderImportType to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type to use in def_DE_Interface
   This table structure mimics the record structure of ASNLPND import, with few additional fields
   to capture key fields, etc.,. */
Create Type TASNLPNHeaderImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,
    LPNId                    TRecordId,
    LPN                      TLPN,
    LPNType                  TTypeCode,
    LPNWeight                TFloat,
    ActualWeight             TFloat,
    InnerPacks               TInteger,
    Quantity                 TQuantity,
    Pallet                   TPallet,
    PalletId                 TRecordId,
    Ownership                TOwnership,
    ASNCase                  TASNCase,

    ReceiptId                TRecordId,
    ReceiptNumber            TReceiptNumber,
    ReceiptType              TReceiptType,

    ShipmentId               TRecordId, --?
    LoadId                   TRecordId, --?

    CountryOfOrigin          TCoO,
    ReceivedDate             TDateTime,
    ExpiryDate               TDateTime,
    DestWarehouse            TWarehouse,
    Location                 TLocation,

    Status                   TStatus,
    InventoryStatus          TStatus,
    OnhandStatus             TStatus,

    LPN_UDF1                 TUDF,
    LPN_UDF2                 TUDF,
    LPN_UDF3                 TUDF,
    LPN_UDF4                 TUDF,
    LPN_UDF5                 TUDF,

    SourceSystem             TName          DEFAULT 'HOST',
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    /* Rest of the fields are for processing and not used for import */
    InputXML                 TXML,
    ResultXML                TXML,

    HostRecId                TRecordId,

    PRIMARY KEY              (RecordId),
    Unique                   (LPN, RecordId),
    Unique                   (RecordAction, RecordId)
);

Grant References on Type:: TASNLPNHeaderImportType to public;

Go
