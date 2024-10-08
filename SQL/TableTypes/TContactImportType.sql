/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TReceiptDetailImportType: Added Lot, InventoryClass1 to InventoryClass3 and Removed RD_UDF11 to 30, TContactImportType: Added CT_UDF1 to 5
  2019/08/29  RKC     TContactImportType: Added AddressLine3 (HPI-2711)
  2017/04/11  DK      TOrderHeaderImportType, TContactImportType: Added ShipToResidential, DeliveryRequirement (CIMS-1289)
  2015/07/09  SK      Extended Unique constraint for TContactImportType including RecordId (LL-206).
  2015/01/08  SK      Added TContactImportType
  Create Type TContactImportType as Table (
  Grant References on Type:: TContactImportType to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type used in OrderHeader type Importing Address Fields
   This table structure contains all the address fields imported with orders with few additional fields
   to capture key fields, etc.,. */
Create Type TContactImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,

    ContactId                TRecordId,
    ContactRefId             TContactRefId,
    ContactType              TContactType,

    Name                     TName,
    AddressLine1             TAddressLine,
    AddressLine2             TAddressLine,
    AddressLine3             TAddressLine,
    City                     TCity,
    State                    TState,
    Country                  TCountry,
    Zip                      TZip,
    PhoneNo                  TPhoneNo,
    Email                    TEmailAddress,
    AddressReference1        TAddressLine,
    AddressReference2        TAddressLine,

    Residential              TFlag          DEFAULT 'N',

    CT_UDF1                  TUDF,
    CT_UDF2                  TUDF,
    CT_UDF3                  TUDF,
    CT_UDF4                  TUDF,
    CT_UDF5                  TUDF,

    ContactPerson            TName,
    PrimaryContactRefId      TContactRefId,
    OrganizationContactRefId TContactRefId,
    ContactAddrId            TRecordId,
    OrgAddrId                TRecordId,

    SourceSystem             TName          DEFAULT 'HOST',
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    /* Rest of the fields are for processing and not used for import */
    InputXML                 TXML,
    ResultXML                TXML,

    Primary Key              (RecordId),
    Unique                   (RecordId, ContactRefId, ContactType, BusinessUnit),
    Unique                   (RecordAction, RecordId)
);

Grant References on Type:: TContactImportType to public;

Go
