/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_SL_GetNextOrderToPack') is not null
  drop Procedure pr_Packing_SL_GetNextOrderToPack;
Go
/*------------------------------------------------------------------------------
  pr_Packing_SL_GetNextOrderToPack:
    procedure returns all details to be displayed in packing screen

------------------------------------------------------------------------------*/
Create Procedure pr_Packing_SL_GetNextOrderToPack
  (@WaveNo        TPickBatchNo = null,
   @SKUId         TRecordId,
   @QtyToConsider TQuantity = null,
   @OrderId       TRecordId = null output)
as
  declare @vReturnCode     TInteger,
          @xmlODToPack     TXML,

          @vMessageName    TMessage;
begin
  select @vMessageName  = null,
         @QtyToConsider = coalesce(@QtyToConsider, 1);

  if (@SKUId is null) and (@WaveNo is null)
    return;

  /* we need to get the first order to pack  */
  select @OrderId = OrderId
  from vwOrderDetails
  where (PickBatchNo  = @WaveNo) and
        (SKUId            = @SKUId) and
        (UnitsToAllocate >= @QtyToConsider) and
        (OrderType not in ('B', 'RU', 'RP')) and
        (Status not in ('S', 'X' /* Shipped or Canceled */))
  order by OrderDate;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_SL_GetNextOrderToPack */

Go
