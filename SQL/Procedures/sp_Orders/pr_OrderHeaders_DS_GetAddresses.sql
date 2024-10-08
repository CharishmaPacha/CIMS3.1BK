/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/22  NB      pr_OrderHeaders_DS_GetAddresses: Return ContactId in dataset, needed for edit action(HA-2309)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_DS_GetAddresses') is not null
  drop Procedure pr_OrderHeaders_DS_GetAddresses;
Go
/*------------------------------------------------------------------------------
  Procedure pr_OrderHeaders_DS_GetAddresses
    Datasource procedure for Order Addresses Listing
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_DS_GetAddresses
  (@xmlInput     XML,
   @OutputXML    TXML = null output)
as
  declare @vEntityDetailXML               xml,
          @vMenuCaption                   TName,
          @vResultXML                     xml,
          @vErrorsXML                     xml,
          @vSelectSQL                     TVarchar,
          @vCountSQL                      TVarchar,
          @vMessage                       TMessage,

          @vShipFrom                      TShipFrom,
          @vSoldToId                      TCustomerId,
          @vShipToId                      TShipToId,
          @vReturnAddress                 TReturnAddress,
          @vMarkForAddress                TContactRefId,
          @vOrderId                       TRecordId,
          @vBusinessUnit                  TBusinessUnit;

  declare @ttOrderAddressesData           TOrderAddressesData,
          @ttContacts                     TEntityValuesTable;
begin /* pr_OrderHeaders_DS_GetAddresses */

  if (object_id('tempdb..#ResultDataSet')) is null return;

  /* Fetch the inputs */
  select @vOrderId      = Record.Col.value('(MasterSelectionFilters/Filter/FilterValue) [1]', 'TName'),
         @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit) [1]', 'TBusinessUnit')
  from @xmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlInput = null ));

  /* Get the required values */
  select @vShipFrom       = ShipFrom,
         @vSoldToId       = SoldToId,
         @vShipToId       = ShipToId,
         @vReturnAddress  = ReturnAddress,
         @vMarkForAddress = MarkForAddress
  from OrderHeaders
  where (OrderId = @vOrderId);

  insert into @ttContacts (RecordId, EntityKey, UDF1)
    select 1, @vShipFrom, 'F' /* ShipFrom */
    union
    select 2, @vSoldToId, 'C' /* Customer */
    union
    select 3, @vShipToId, 'S' /* Ship To */
    union
    select 4, @vReturnAddress, 'R' /* Return */
    union
    select 5, @vMarkForAddress, 'M' /* Mark For */;

  insert into #ResultDataSet(OrderId, ContactId, ContactRefId, ContactType, ContactTypeDesc, Name, AddressLine1, AddressLine2, AddressLine3,
                             City, State, Country, Zip, PhoneNo, Email, Reference1, Reference2, CityStateZip, Status, BusinessUnit)
    select @vOrderId, C.ContactId, C.ContactRefId, C.ContactType, C.ContactTypeDesc, C.Name, C.AddressLine1, C.AddressLine2, C.AddressLine3,
           C.City, C.State, C.Country, C.Zip, C.PhoneNo, C.Email, C.Reference1, C.Reference2, C.CityStateZip, C.Status, @vBusinessUnit
    from vwContacts C join @ttContacts TTC on (C.ContactRefId = TTC.EntityKey) and (C.ContactType = TTC.UDF1)
    order by TTC.RecordId;

end  /* pr_OrderHeaders_DS_GetAddresses */

Go
