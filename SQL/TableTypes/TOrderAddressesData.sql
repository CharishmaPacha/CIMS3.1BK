/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  NB      Added ContactId to TOrderAddressesData (HA-2309)
  2020/06/10  MS      Added TOrderAddressesData (HA-861)
  Create Type TOrderAddressesData as Table (
  Grant References on Type:: TOrderAddressesData to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TOrderAddressesData as Table (
    OrderId                  TRecordId,

    ContactId                TRecordId,
    ContactRefId             TContactRefId,
    ContactType              TContactType,
    ContactTypeDesc          TDescription,

    Name                     TName,
    AddressLine1             TAddressLine,
    AddressLine2             TAddressLine,
    AddressLine3             TAddressLine,

    City                     TCity,
    State                    TState,
    Country                  TCountry,
    ZIP                      TZip,
    PhoneNo                  TPhoneNo,
    Email                    TEmailAddress,

    Reference1               TReference,
    Reference2               TReference,
    CityStateZip             TCityStateZip,
    Status                   TStatus,
    BusinessUnit             TBusinessUnit,

    RecordId                 TRecordId        identity(1, 1)
);

Grant References on Type:: TOrderAddressesData to public;

Go
