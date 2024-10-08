/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/07/29  PK      Vendors: Added VendorId to unique key ukVendors_Name.
  2012/06/29  AY      Customers, Vendors: Corrected indices to be unique for BusinessUnit
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: Vendors
------------------------------------------------------------------------------*/
Create Table Vendors (
    RecordId                 TRecordId      identity (1,1) not null,

    VendorId                 TVendorId      not null,
    VendorName               TName          not null,
    VendorContactId          TRecordId,
    Status                   TStatus        not null default 'A' /* Active*/,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkVendors_RecordId PRIMARY KEY (RecordId),
    constraint ukVendors_Id       UNIQUE (VendorId, BusinessUnit),
    constraint ukVendors_Name     UNIQUE (VendorId, VendorName, BusinessUnit)
);

Go
