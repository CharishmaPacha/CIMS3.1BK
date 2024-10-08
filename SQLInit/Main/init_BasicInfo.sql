/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/12/09  VM      File consolidation changes (CIMSV3-2472)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Owners
------------------------------------------------------------------------------*/
declare @Owner TLookUpsTable, @LookUpCategory TCategory = 'Owner';

insert into @Owner
       (LookUpCode,  LookUpDescription,       Status)
/* SCT */
values ('SCT',       'Supply Chain Tech',     'A'),
/* Demo */
       ('DEMO',      'Supply Chain Tech',     'A'),
/* The Latin Products */
       ('V1',        'Vendor 1',              'A'),
       ('V2',        'Vendor 2',              'A')

exec pr_LookUps_Setup @LookUpCategory, @Owner, @LookUpCategoryDesc = 'Owners';

Go

/*------------------------------------------------------------------------------
  DefaultWarehouse

  Default Warehouse mapping is to map the Ownercode with respective Physical or Logical Warehouse
  This is used for setting the default Warehouse where the order must be shipped from, during Order Imports

  in this mapping, the OwnerCode is the LookUp code where as the mapped Warehouse is the LookUpDescription.
 -----------------------------------------------------------------------------*/
declare @DefaultWarehouses TLookUpsTable, @LookUpCategory TCategory = 'OwnerDefaultWarehouse';

/* By default let us setup all combinations of Owners and Warehouses. This can be customized as per client needs */

insert into @DefaultWarehouses
       (LookUpCode,  LookUpDescription,  Status)
values ('SCT',       'W1',               'A'),
       ('DEMO',      'W2',               'A'),
       ('V1',        'W1',               'A'),
       ('V2',        'W2',               'A')

exec pr_LookUps_Setup @LookUpCategory, @DefaultWarehouses, @LookUpCategoryDesc = 'Owner Warehouse Mapping';

Go

/*------------------------------------------------------------------------------
  Warehouses
 -----------------------------------------------------------------------------*/
declare @Warehouses TLookUpsTable, @LookUpCategory TCategory = 'Warehouse';

insert into @Warehouses
/* SCT */
       (LookUpCode,  LookUpDescription,  Status)
values ('W1',        'Atlanta DC',       'A'),
       ('W2',        'Greenville DC',    'A'),

/* The Latin Products */
       ('ATLGA',     'Atlanta, GA',      'I')

exec pr_LookUps_Setup @LookUpCategory, @Warehouses, @LookUpCategoryDesc = 'Warehouses';

Go

/*------------------------------------------------------------------------------
  Addresses
------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------*/
/* Insert Default ShipFrom Address   */
/*------------------------------------------------------------------------------*/
exec pr_Imports_Contacts
   @xmlData                    = null,
   @Action                     = 'I', /* Insert */
   @ContactRefId               = 'W1',
   @ContactType                = 'F', /* Ship From  */
   @Name                       = 'CIMS',
   @AddressLine1               = '123 First Avenue',
   @AddressLine2               = '',
   @City                       = 'Atlanta',
   @State                      = 'GA',
   @Country                    = 'USA',
   @Zip                        = '30001',
   @PhoneNo                    = '',
   @Email                      = '',
   @ContactPerson              = null,
   @PrimaryContactRefId        = null,
   @OrganizationContactRefId   = null,
   @ContactAddrId              = null,
   @OrgAddrId                  = null,
   @BusinessUnit               = 'SCT',
   @CreatedDate                = null,
   @ModifiedDate               = null,
   @CreatedBy                  = null,
   @ModifiedBy                 = null
;

/*------------------------------------------------------------------------------*/
/* Insert Default return Address: Return address ContactRefId should be the
   ShipFrom Code + 'R' for return   */
/*------------------------------------------------------------------------------*/
exec pr_Imports_Contacts
   @xmlData                    = null,
   @Action                     = 'I', /* Insert */
   @ContactRefId               = 'W1R',
   @ContactType                = 'R', /* Return */
   @Name                       = 'CIMS',
   @AddressLine1               = '123 First Avenue',
   @AddressLine2               = '',
   @City                       = 'Atlanta',
   @State                      = 'GA',
   @Country                    = 'USA',
   @Zip                        = '30001',
   @PhoneNo                    = '',
   @Email                      = '',
   @ContactPerson              = null,
   @PrimaryContactRefId        = null,
   @OrganizationContactRefId   = null,
   @ContactAddrId              = null,
   @OrgAddrId                  = null,
   @BusinessUnit               = 'SCT',
   @CreatedDate                = null,
   @ModifiedDate               = null,
   @CreatedBy                  = null,
   @ModifiedBy                 = null
;

/*------------------------------------------------------------------------------*/
/*  Default Billing address: ContactRefId should be the ShipFrom Code + 'B'     */
/*------------------------------------------------------------------------------*/
exec pr_Imports_Contacts
   @xmlData                    = null,
   @Action                     = 'I', /* Insert */
   @ContactRefId               = 'W1B',
   @ContactType                = 'F', /* Ship From  */
   @Name                       = 'CIMS',
   @AddressLine1               = '123 First Avenue',
   @AddressLine2               = '',
   @City                       = 'Atlanta',
   @State                      = 'GA',
   @Country                    = 'USA',
   @Zip                        = '30001',
   @PhoneNo                    = '',
   @Email                      = '',
   @ContactPerson              = null,
   @PrimaryContactRefId        = null,
   @OrganizationContactRefId   = null,
   @ContactAddrId              = null,
   @OrgAddrId                  = null,
   @BusinessUnit               = 'SCT',
   @CreatedDate                = null,
   @ModifiedDate               = null,
   @CreatedBy                  = null,
   @ModifiedBy                 = null
;

/*------------------------------------------------------------------------------*/
/*  Sample consolidator address: ContactRefID should be the Consolidator Code + 'A'     */
/*------------------------------------------------------------------------------*/
exec pr_Imports_Contacts
   @xmlData                    = null,
   @Action                     = 'I', /* Insert */
   @ContactRefId               = 'ABCD',
   @ContactType                = 'CO', /* Consolidator  */
   @Name                       = 'Ship Consolidator',
   @AddressLine1               = '123 ABC Way',
   @AddressLine2               = '',
   @City                       = 'New York',
   @State                      = 'DC',
   @Country                    = 'USA',
   @Zip                        = '00001',
   @PhoneNo                    = '',
   @Email                      = '',
   @ContactPerson              = null,
   @PrimaryContactRefId        = null,
   @OrganizationContactRefId   = null,
   @ContactAddrId              = null,
   @OrgAddrId                  = null,
   @BusinessUnit               = 'SCT',
   @CreatedDate                = null,
   @ModifiedDate               = null,
   @CreatedBy                  = null,
   @ModifiedBy                 = null;

Go
