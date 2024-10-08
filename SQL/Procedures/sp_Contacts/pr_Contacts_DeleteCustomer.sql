/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Contacts_DeleteCustomer') is not null
  drop Procedure pr_Contacts_DeleteCustomer;
Go
/*------------------------------------------------------------------------------
  Proc pr_Contacts_DeleteCustomer:
------------------------------------------------------------------------------*/
Create Procedure pr_Contacts_DeleteCustomer
  (@CustomerId    TCustomerId,
   @RecordId      TRecordId = null)
as
  declare @CustomerContactId TRecordId,
          @CustomerBillToId  TRecordId;
begin
  SET NOCOUNT ON;

  select @CustomerContactId = CustomerContactId,
         @CustomerBillToId  = CustomerBillToId
  from Customers
  where (RecordId = @RecordId) or (CustomerId = @CustomerId);

  delete
  from Customers
  where RecordId = @RecordId;

  /* Delete Contacts associated with this Customer */
  delete
  from Contacts
  where ContactId = @CustomerContactId
     or ContactId = @CustomerBillToId;
end /* pr_Contacts_DeleteCustomer */

Go
