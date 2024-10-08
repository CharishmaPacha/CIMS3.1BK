/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/05/01  AY      fn_Imports_GetPickTicket: Generate PT on order import (HPI-69).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Imports_GetPickTicket') is not null
  drop Function fn_Imports_GetPickTicket;
Go
/*------------------------------------------------------------------------------
  Function fn_Imports_GetPickTicket: This function returns the PickTicket no
   to be used for the order sent from the Host. This is very critical if the
   Host is sending the same order download again and again i.e. CIMS has to
   recognize and distinguish between and update to an order vs generating a
   new PT for the Order.

  This function returns the OrderId and PickTicketNo. If Order is is returned
  then import procedure updates the order. If Order is null, then the given
  PickTicket number is used to create a new PickTicket.
------------------------------------------------------------------------------*/
Create Function fn_Imports_GetPickTicket
  (@PickTicket       TPickTicket,
   @SalesOrder       TSalesOrder,
   @BusinessUnit     TBusinessUnit)
  ----------------------------------
   returns           @ttPTInfo table(OrderId    TRecordId,
                                     PickTicket TPickTicket)
as
begin
  declare @vOrderId      TRecordId,
          @vPickTicket   TPickTicket,
          @vOrderStatus  TStatus,

          @vPTGeneratedByHost      TControlValue,
          @vAlwaysUpdateStatuses   TControlValue,
          @vSuffix                 varchar(10),
          @vNewSuffix              varchar(10);

  select @vPickTicket            = rtrim(@PickTicket),
         @vPTGeneratedByHost     = 'N',
         @vAlwaysUpdateStatuses  = 'ONW' /* Downlaoded, New, Waved */;

  /* Check if PT already exists in the system */
  select @vOrderId     = OrderId,
         @vOrderStatus = Status
  from OrderHeaders
  where (PickTicket   = @vPickTicket) and
        (BusinessUnit = @BusinessUnit);

  /* For many clients, generation of PT  by CIMS is not necessary */
  if (@vPTGeneratedByHost = 'Y')
    goto ExitHandler;

  /* If PT is given but does not exist, then use that PickTicketNo */
  if (@vOrderId is null) and (coalesce(@vPickTicket, '') <> '')
    goto ExitHandler;

  /* if PT is shipped, cancelled, then get check the latest PT for the Order */
  if (@vOrderStatus in ('S', 'X' /* Shipped, Cancelled */))
    select top 1
           @vOrderId     = OrderId,
           @vPickTicket  = PickTicket,
           @vOrderStatus = Status
    from OrderHeaders
    where (SalesOrder   = @SalesOrder) and
          (BusinessUnit = @BusinessUnit)
    order by PickTicket desc;

  /* Unless the latest PT is shipped/cancelled, it can be used */
  if (charindex(@vOrderStatus, 'SX' /* Shipped, Cancelled */) = 0)
    goto ExitHandler;

  /* Generate new PT since the previous one for order is already shipped or cancelled */

  if (charindex('.', @vPickTicket) = 0)
    select @vPickTicket = @vPickTicket + '.1';
  else
    begin
      /* Extract the previous suffix from PT */
      select @vSuffix = substring(@vPickTicket, charindex('.', @vPickTicket) + 1, 50);

      /* Increment it by one */
      select @vNewSuffix = convert(int, @vSuffix) + 1;
      --exec pr_IncrementString @vSuffix, 1 /* length */, 1 /* Increment */, 'N' /* Numeric only */, @vNewSuffix output;

      /* Replace with new suffix */
      select @vPickTicket = replace(@vPickTicket, @vSuffix, @vNewSuffix);
    end

ExitHandler:
  /* insert into output table */
  insert into @ttPTInfo values (@vOrderId, @vPickTicket);

  return;
end /* fn_Imports_GetPickTicket */

Go
