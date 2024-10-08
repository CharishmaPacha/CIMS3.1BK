/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/04  PHK     Added Sample Consolidator address (HA-1020)
  2018/04/24  VM      Added Tractor's ShipFrom and BillTo addresses (SRI-860)
  2015/06/25  SV      Included Addresses for DropShip
  2012/05/19  AY      ShipFrom/return addresses would both be 'CO' for TD
  2012/03/15  YA      Changed address(Name to Email) Loehmanns to Topson Downs specific.
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
