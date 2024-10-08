/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/10/24  AY      fn_OrderDays: Function to calculate how old the order is
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_OrderDays') is not null
  drop Function fn_OrderDays;
Go
/*------------------------------------------------------------------------------
  fn_OrderDays: Compute how old the order is considering the work days since the
    order was placed.
------------------------------------------------------------------------------*/
Create Function fn_OrderDays (@OrderDateTime TDateTime, @CutOffTime TTime = '16:00')
  Returns int
as
begin
  declare @vOrderDate TDate, @vCutOffDateTime TDateTime;

  /* If the Order Date Is null, return a null and Exit. */
  if (@OrderDateTime Is null)
    return null

  select @vOrderDate = cast(@OrderDateTime as date);

  /* If order time is past cut off time, then consider receiving the order the next day */
  if (cast(@OrderDateTime as time) > @CutoffTime)
    select @vOrderDate = dateadd(dd, 1, @vOrderDate);

  if (datename(Dw, @vOrderDate) = 'Saturday')
    select @vOrderDate = dateadd(dd, 2, @vOrderDate);
  else
  if (datename(Dw, @vOrderDate) = 'Sunday')
    select @vOrderDate = dateadd(dd, 1, @vOrderDate);

  /* Get the number of days between the Order date and current date */
  return dbo.fn_WorkDays(@vOrderDate, cast(getdate() as date));

end /* fn_OrderDays */

Go
