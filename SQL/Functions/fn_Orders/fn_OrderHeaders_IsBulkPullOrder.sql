/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/03/04  NB      Added fn_OrderHeaders_IsBulkPullOrder
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_OrderHeaders_IsBulkPullOrder') is not null
  drop Function dbo.fn_OrderHeaders_IsBulkPullOrder;
Go
/*------------------------------------------------------------------------------
  Function fn_OrderHeaders_IsBulkPullOrder:

    function validates if the Order or Batch is processed via Bulk Pull process
    The condition to determine is to identify if the Order's PickBatch consists
    of any Order of type Bulk Pull
------------------------------------------------------------------------------*/
Create Function fn_OrderHeaders_IsBulkPullOrder
  (@OrderId             TRecordId)
  ----------------------------------
   returns              TBoolean
as
begin /* fn_OrderHeaders_IsBulkPullOrder */
  declare  @vReturnCode   TBoolean,
           @vPickBatchNo  TPickBatchNo,
           @vBulkOrderId  TRecordId;

  select @vReturnCode = 0;

  /* Identify if the Order belongs to a Bulk Pick Batch */
  select @vPickBatchNo = PickBatchNo
  from OrderHeaders
  where (OrderId = @OrderId);

  select @vBulkOrderId = null;
  select @vBulkOrderId = OrderId
  from OrderHeaders
  where ((PickBatchNo = @vPickBatchNo) and (OrderType = 'B' /* Bulk Pull*/));

  if (@vBulkOrderId is not null)
    select @vReturnCode = 1;

  return(coalesce(@vReturnCode, 0))
end /* fn_OrderHeaders_IsBulkPullOrder */

Go
