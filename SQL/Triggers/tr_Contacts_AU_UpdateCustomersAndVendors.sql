/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('tr_Contacts_AU_UpdateCustomersAndVendors') is not null
  drop Trigger tr_Contacts_AU_UpdateCustomersAndVendors;
Go
/*------------------------------------------------------------------------------
  After Update Trigger tr_Contacts_AU_UpdateCustomersAndVendors to update Customers.Name/Vendors.VendorName when Contacts.Name is updated
------------------------------------------------------------------------------*/
Create Trigger [tr_Contacts_AU_UpdateCustomersAndVendors] on [Contacts] for Update
As
begin
 if (update(Name))
   begin
     update C
     set  C.CustomerName = INS.Name
     from Customers C
          join Inserted INS on ((INS.ContactType = 'C' /* Customer */) and
                                (C.CustomerId    = INS.ContactRefId ))
     update V
     set  V.VendorName = INS.Name
     from Vendors V
          join Inserted INS on ((INS.ContactType = 'V' /* Vendor */ ) and
                                (V.VendorId      = INS.ContactRefId))
   end
end /* tr_Contacts_AU_UpdateCustomersAndVendors */

Go

