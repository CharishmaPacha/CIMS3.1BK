/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/15  TK      fn_OrderHeaders_IsInternationalOrder: Initial Revision (CID-1624)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_OrderHeaders_IsInternationalOrder') is not null
  drop Function fn_OrderHeaders_IsInternationalOrder;
Go
/*------------------------------------------------------------------------------
  fn_OrderHeaders_IsInternationalOrder: Returns Boolean value 'Y' if the order is an
    international order or it will return 'N'
------------------------------------------------------------------------------*/
Create Function fn_OrderHeaders_IsInternationalOrder
  (@OrderId          TRecordId)
  returns TFlag
as
begin
  declare @vIsInternationalOrder    TFlag;

  select @vIsInternationalOrder = 'N' /* No */;

  /* Identify whether it is international order or not based upon ShipVia, AddressRegion and State */
  select @vIsInternationalOrder = 'Y'
  from OrderHeaders OH
    join Contacts SHIPTO on (OH.ShipToId = SHIPTO.ContactRefId)
    join Contacts SOLDTO on (OH.SoldToId = SOLDTO.ContactRefId)
  where (OH.OrderId = @OrderId) and
        ((SHIPTO.AddressRegion = 'I') or
         (SOLDTO.AddressRegion = 'I') or
         (SHIPTO.State = 'PR') or
         (SOLDTO.State = 'PR') or
         (OH.ShipVia in ('ITNL', 'INTL')));

  return @vIsInternationalOrder;
end /* fn_OrderHeaders_IsInternationalOrder */

Go
