/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/09/04  RT      fn_Contacts_GetShipToAddress: Included ContactPerson (HPI-2712)
  2019/08/29  RKC     pr_Contacts_AddOrUpdate, pr_Contacts_AddOrUpdateAddress, pr_Contacts_AddOrUpdateCustomer
                      fn_Contacts_GetShipToAddress, pr_Contacts_AddOrUpdateVendor:Pass the AddressLine3 (HPI-2711)
  2019/06/06  KSK     fn_Contacts_GetShipToAddress: Added TaxId field (CID-634)
  2018/11/13  AY      fn_Contacts_GetShipToAddress: Use only left 5 digits of zip code for US (OB-Support)
  2018/09/10  AY      fn_Contacts_GetShipToAddress: Added Residential flag in output
  2016/10/07  AY      fn_Contacts_GetShipToAddress: Return dummy record when no address exists so that PL can be printed (HPI-GoLive)
  2016/07/28  PSK     fn_Contacts_GetShipToAddress: Use control variable for default phoneNo.(CIMS-1024)
  2015/06/29  AY      fn_Contacts_GetShipToAddress: Added CityStateZip, AddressRegion and References
  2015/06/02  RV      fn_Contacts_GetShipToAddress : function added.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Contacts_GetShipToAddress') is not null
  drop Function fn_Contacts_GetShipToAddress;
Go
/*------------------------------------------------------------------------------
  fn_Contacts_GetShipToAddress:
  Function that returns the Ship To address based upon ShipToId Or OrderId.

------------------------------------------------------------------------------*/
Create Function fn_Contacts_GetShipToAddress
  (@OrderId           TRecordId,
   @ContactRefId      TContactRefId)
returns
  /* temp table  to return data */
  @ttShipToAddress   table
    (ContactType     TContactType,
     ContactRefId    TContactRefId,
     Name            TName,
     AddressLine1    TAddressLine,
     AddressLine2    TAddressLine,
     AddressLine3    TAddressLine,
     City            TCity,
     State           TState,
     Country         TCountry,
     Zip             TZip,
     PhoneNo         TPhoneNo,
     Email           TEmailAddress,
     CityStateZip    TCityStateZip,
     CountryCode     TTypeCode,
     Reference1      TDescription,
     Reference2      TDescription,
     TaxId           TTaxId,
     Residential     TFlag,
     AddressRegion   TAddressRegion,
     ContactPerson   TName)
as
begin
  declare @vOrdShipToId         TShipToId,
          @vDefaultShipToPhone  TPhoneNo,
          @vBusinessUnit        TBusinessUnit;

  /* If Ship To Id is not passed then we should get from Orders */
  if (@ContactRefId is null)
    select @ContactRefId  = ShipToId,
           @vBusinessUnit = BusinessUnit
    from OrderHeaders
    where (OrderId = @OrderId);
  else
    select @vBusinessUnit = BusinessUnit
    from Contacts
    where (ContactRefId = @ContactRefId);

  /* Get control value */
  select @vDefaultShipToPhone = dbo.fn_Controls_GetAsString('Default', 'ShipToPhoneNo', '' /* Default PhoneNo */, @vBusinessUnit, null/* UserId */);

  /* Check if there is a ShipToAddress with the given ContactRefId */
  insert into @ttShipToAddress (ContactType, ContactRefId, Name, AddressLine1, AddressLine2, AddressLine3,
                                City, State, Country, Zip, CityStateZip, CountryCode, PhoneNo, Email,
                                Reference1, Reference2, TaxId, Residential, AddressRegion, ContactPerson)
    select ContactType, ContactRefId, Name, AddressLine1, AddressLine2, AddressLine3,
           City, State, Country,
           case when coalesce(Country, '') in ('', 'US', 'USA') then left(Zip, 5) else Zip end,
           CityStateZip, CountryCode, coalesce(nullif(PhoneNo, ''), @vDefaultShipToPhone), Email,
           Reference1, Reference2, TaxId, Residential, AddressRegion, ContactPerson
    from vwShipToAddress
    where (ContactRefId = @ContactRefId) and
          (ContactType = 'S' /* Ship To Address */);

  /* If there is no Ship To Address is available then we should ship to Customer Address */
  if (@@rowcount = 0)
    insert into @ttShipToAddress (ContactType, ContactRefId, Name, AddressLine1, AddressLine2, AddressLine3,
                                  City, State, Country, Zip, CityStateZip, CountryCode, PhoneNo, Email,
                                  Reference1, Reference2, TaxId, Residential, AddressRegion, ContactPerson)
      select ContactType, ContactRefId, Name, AddressLine1, AddressLine2, AddressLine3,
             City, State, Country,
             case when coalesce(Country, '') in ('', 'US', 'USA') then left(Zip, 5) else Zip end,
             CityStateZip, CountryCode, PhoneNo, Email,
             Reference1, Reference2, TaxId, Residential,AddressRegion, ContactPerson
      from vwShipToAddress
      where (ContactRefId = @ContactRefId) and
            (ContactType = 'C' /* Customer Address */);

  /* If there is no valid data then return a dummy record so that packing list can be printed without the shipping address */
  if not (exists (select * from @ttShipToAddress))
    insert into @ttShipToAddress (ContactType, ContactRefId)
      select 'S', @ContactRefId;

  return;
end /* fn_Contacts_GetShipToAddress */

Go
