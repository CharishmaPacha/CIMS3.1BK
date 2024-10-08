/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/04/16  TD      Customers: Added customerId to unique key ukCustomers_Name.
  2012/06/29  AY      Customers, Vendors: Corrected indices to be unique for BusinessUnit
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: Customers
------------------------------------------------------------------------------*/
Create Table Customers (
    RecordId                 TRecordId      identity (1,1) not null,

    CustomerId               TCustomerId    not null,
    CustomerName             TName          not null,
    CustomerContactId        TRecordId,
    CustomerBillToId         TRecordId,
    Status                   TStatus        not null default 'A' /* Active*/,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkCustomers_RecordId PRIMARY KEY (RecordId),
    constraint ukCustomers_Id       UNIQUE (CustomerId, BusinessUnit),
    constraint ukCustomers_Name     UNIQUE (CustomerId, CustomerName, BusinessUnit)
);

Go
