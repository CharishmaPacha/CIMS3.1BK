/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this procedure exists. Taken here for extended functionality.
  So, if there is any common code to be modified, MUST consider modifying the same in Base version as well.
  *****************************************************************************

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Contacts_Delete') is not null
  drop Procedure pr_Contacts_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_Contacts_Delete:
------------------------------------------------------------------------------*/
Create Procedure pr_Contacts_Delete
  (@ContactId      TRecordId)
as
begin
  SET NOCOUNT ON;

  /* Update other Contact records having references to this Contact */
  update Contacts
  set ContactAddrId = null
  where ContactAddrId = @ContactId;

  update Contacts
  set OrgAddrId = null
  where OrgAddrId = @ContactId;

  /* Update Customer records having references to this Contact */
  update Customers
  set CustomerContactId = null
  where CustomerContactId = @ContactId;

  update Customers
  set CustomerBillToId = null
  where CustomerBillToId = @ContactId;

  /* Update Vendor records having references to this Contact */
  update Vendors
  set VendorContactId = null
  where VendorContactId = @ContactId;

  /* Now delete the Contact */
  delete
  from Contacts
  where ContactId = @ContactId
end /* pr_Contacts_Delete */

Go
