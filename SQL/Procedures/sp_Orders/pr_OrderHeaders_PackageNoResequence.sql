/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/07  TK      pr_OrderHeaders_PackageNoResequence: Initial Revision (CID-883)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_PackageNoResequence') is not null
  drop Procedure pr_OrderHeaders_PackageNoResequence;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_PackageNoResequence:
    This procedure will Re order the Package Sequence number, if those are
    not in sequence.
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_PackageNoResequence
  (@WaveId     TRecordId,
   @OrderId    TRecordId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @vOrderId           TRecordId;

  declare @ttOrders           TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get the orders to process */
  if (@WaveId is not null)
    insert into @ttOrders(EntityId)
      select OrderId
      from OrderHeaders
      where (PickBatchId = @WaveId);
  else
  if (@OrderId is not null)
    insert into @ttOrders (EntityId)
      select @OrderId;

  /* Loop thru each order and resequence */
  while exists (select * from @ttOrders where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId = RecordId,
                   @vOrderId  = EntityId
      from @ttOrders
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Invoke procedure to resequence */
      exec pr_LPNs_PackageNoResequence @vOrderId, null /* LPNId */;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end  /* pr_OrderHeaders_PackageNoResequence */

Go
