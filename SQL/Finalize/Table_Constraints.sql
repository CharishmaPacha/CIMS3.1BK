/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024-03-05  VM      Add foreign key constrains on required tables (CIMSV3-3429)
------------------------------------------------------------------------------*/
-- Add constraints on Detail Tables

Go

/* Customers */
alter table Customers
  add constraint fkCustomers_CustomerContactId foreign key (CustomerContactId) references Contacts (ContactId);
alter table Customers
  add constraint fkCustomers_CustomerBillToId foreign key (CustomerBillToId) references Contacts (ContactId);

Go

/* CycleCountResults */
alter table CycleCountResults
  add constraint fkCycleCountResults_TaskDetaiId foreign key (TaskDetailId) references TaskDetails (TaskDetailId);

Go

/* OrderDetails */
alter table OrderDetails
  add constraint fkROrderDetail_OrderId  foreign key (OrderId) references OrderHeaders(OrderId) on delete cascade;

Go

/* ReceiptDetails */
alter table ReceiptDetails
  add constraint fkReceiptDetails_ReceiptId foreign key (ReceiptId) references ReceiptHeaders(ReceiptId) on delete cascade;

Go

/* Vendors */
alter table Vendors
  add constraint fkVendors_VendorContactId foreign key (VendorContactId) references Contacts (ContactId);

Go
