/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/13  MS      TImportValidationType: Added HostOrderLine
  2019/09/24  RKC     TSKUImportType ,TImportValidationType:Added CartonGroup
  TImportValidationType : Added LPNType,DestWarehouse (HPI-2360)
  TImportValidationType : Added LocationClass (S2GCAN-24)
  2018/03/22  DK      TOrderHeaderImportType, TImportValidationType: Added SourceSystem (FB-1117)
  2017/11/09  TD      TSKUImportType, TImportValidationType - added HostRecId (CIMSDE-14)
  2016/06/01  KL      Added UoM field in TImportValidationType (HPI-97)
  2015/12/10  AY      TImportValidationType: Added more fields for generic use
  2015/08/27  AY      TImportValidationType: Added EntityType & Status
  2015/08/05  YJ      Added missing fields for TImportValidationType.
  2014/05/14  NB      Added TOrderDetailsImportType, TImportValidationType
  Create Type TImportValidationType as Table (
  Grant References on Type:: TImportValidationType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type to use in Validation of data being imported, capture the validations, use to update the InterfaceLogDetails */
Create Type TImportValidationType as Table (
    RecordId                 TRecordId,
    RecordAction             TAction,

    EntityId                 Integer,
    EntityKey                TEntityKey,
    EntityType               TTypeCode,
    EntityStatus             TStatus,

    RecordType               TRecordType,
    SKU                      TSKU,
    SKUId                    TRecordId,
    SKUStatus                TStatus,
    UoM                      TUoM,

    PickTicket               TPickTicket,
    OrderId                  TRecordId,
    OrderDetailId            TRecordId,
    HostOrderLine            THostOrderLine,

    LPN                      TLPN,
    LPNId                    TRecordId,
    LPNType                  TTypeCode,
    DestWarehouse            TWarehouse,

    LocationId               TRecordId,
    Location                 TLocation,
    LocationType             TTypeCode,
    LocationClass            TCategory,
    StorageType              TStorageType,

    Vendor                   TName,
    VendorId                 TVendorId,

    ReceiptNumber            TReceiptNumber,
    ReceiptId                TRecordId,
    ReceiptDetailId          TRecordId,

    Ownership                TOwnership,
    SourceSystem             TName,
    Warehouse                TWarehouse,

    --LogMessage             TDescription,
    --LogDateTime            TDateTime      Default current_timestamp,
    KeyData                  TReference,
    HostReference            TReference,
    HostRecId                TRecordId,
    InputXML                 TXML,
    ResultXML                TXML,
    BusinessUnit             TBusinessUnit,

    Primary Key              (RecordId),
    Unique                   (RecordAction, RecordId)
);

Grant References on Type:: TImportValidationType   to public;

Go
