/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/08/21  RV      Renamed FedEx to FedEx2 (CIMSV3-3532)
  2022/11/15  RKC     tr_Contacts_AU_AddressValidation: Made changes to create AddressValidation API outbound Transaction for FedEx also (OBV3-1443)
  2022/02/25  RT      tr_Contacts_AU_AddressValidation: Trigger to create AddressValidation API outbound Transaction (CID-1904)
------------------------------------------------------------------------------*/

Go

if object_id('tr_Contacts_AU_AddressValidation') is not null
  drop Trigger tr_Contacts_AU_AddressValidation;
Go
/*------------------------------------------------------------------------------
  tr_Contacts_AU_AddressValidation: When there is modification in Contacts
    we need to validate the Address through the respective Carrier integration where
    we would need to send the data to those systems and this triggers creates
    an API outbound transaction to validate the Street level Address.
------------------------------------------------------------------------------*/
Create Trigger tr_Contacts_AU_AddressValidation on Contacts After Update
as
begin
  /* Get all the Contacts when there is a change in AVMethod (Carrier) and
    only for US and PR origins, because other than these may cause address format errors */
  select distinct INS.ContactId, INS.ContactRefId, INS.AVMethod, INS.BusinessUnit
  into #ContactsUpdated
  from Inserted INS
  where (INS.AVStatus  = 'ToBeVerified') and
        (INS.AVMethod in ('FedEx2', 'UPS')) and
        --(INS.Country in ('US', 'USA', 'PR')) and
        (INS.ContactType = 'S');

  /* Do not insert if the record already exists, which is not yet processed */
  delete #ContactsUpdated
  from #ContactsUpdated ETC
    join APIOutboundTransactions AOT on (AOT.EntityId = ETC.ContactId) and (AOT.EntityType = 'Contact') and (AOT.TransactionStatus = 'Initial');

  if not exists (select * from #ContactsUpdated) return;

  /* If there is any change in order ShipVia/Contacts table then generate an API transaction for the Contact to validate the Addresss */
  insert into APIOutboundTransactions (IntegrationName, MessageType, EntityType, EntityId, EntityKey, BusinessUnit, CreatedBy)
    select distinct 'CIMS' + AVMethod, 'AddressValidation', 'Contact', ContactId, ContactRefId, BusinessUnit, System_User
    from #ContactsUpdated;

end /* tr_Contacts_AU_AddressValidation */

Go

/* By default we will use address validation, so leave the trigger enabled */
--alter table Contacts disable trigger tr_Contacts_AU_AddressValidation;

Go
