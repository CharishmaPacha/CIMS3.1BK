/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Contacts_DeleteVendor') is not null
  drop Procedure pr_Contacts_DeleteVendor;
Go
/*------------------------------------------------------------------------------
  Proc pr_Contacts_DeleteVendor:
------------------------------------------------------------------------------*/
Create Procedure pr_Contacts_DeleteVendor
  (@VendorId      TVendorId,
   @RecordId      TRecordId = null)
as
  declare @VendorContactId TRecordId;
begin
  SET NOCOUNT ON;

  select @VendorContactId = VendorContactId
  from Vendors
  where (RecordId = @RecordId) or (VendorId = @VendorId);

  delete
  from Vendors
  where RecordId = @RecordId;

  /* Delete Contacts associated with this Vendor */
  delete
  from Contacts
  where ContactId = @VendorContactId;
end /* pr_Contacts_DeleteVendor */

Go
