/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_LPNs_GetReservedQty') is not null
  drop Function dbo.fn_LPNs_GetReservedQty;
Go
/*------------------------------------------------------------------------------
  Function fn_LPNs_GetReservedQty:

    Returns the total qty reserved in the LPN.

    AY: I initially had this function as IsAllocated, but then realized that it provides
    a single usage. It is just as easy to return total reservedqty and let caller determine
    if it is allocated. Returning reservedqty seemed like a more valuable data
    that can be used elsewhere.
------------------------------------------------------------------------------*/
Create Function fn_LPNs_GetReservedQty
  (@LPNId  TRecordId)
  -------------------
   returns TInteger
as
begin
  declare @vReturnValue  TInteger,
          @vLPNStatus    TStatus;

  set @vReturnValue = 0;

  select @vReturnValue = sum(Quantity)
  from LPNDetails
  where (LPNId = @LPNId) and
        (OrderId is not null);

  return(@vReturnValue)
end /* fn_LPNs_GetReservedQty */

Go
