/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/19  SK      pr_Imports_PreprocessOrders: Include waved orders to pre process (HA-2343)
  2017/02/01  NB      pr_Imports_PreprocessOrders: Modified to skip locked records(HPI-1295)
  2016/06/07  NY      pr_Imports_PreprocessOrders : Added Try..Catch to log exceptions (NBD-594)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_PreprocessOrders') is not null
  drop Procedure pr_Imports_PreprocessOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Import_PreprocessOrders:

  Used For: For each New or Updated Order, call pr_Order_Preprocess procedure
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_PreprocessOrders
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;

  declare @vOrderId           TRecordId,
          @vPickTicket        TPickTicket,
          @vErrMsg            TMessage,
          @vActivityLogId     TRecordId;

  declare @ttOrdersToPreprocess TRecountKeysTable;

begin /* pr_Imports_PreprocessOrders */
  /* This isolation level is only for the scope of this procedure
    https://msdn.microsoft.com/en-us/library/ms173763.aspx

    The READPAST hint in the select statement below works only in the case of
    Isolation Level Repeatable Read
    */
  set TRANSACTION ISOLATION LEVEL REPEATABLE READ;

  SET NOCOUNT ON;

  select @vRecordId = 0;

  /* Identify the orders to be preprocessed
     Readpast hint makes the select statement to skip the records which are locked by other processes
  */
  insert into @ttOrdersToPreprocess (EntityId, EntityKey)
    select OrderId, PickTicket
    from OrderHeaders with (READPAST)
    where (Status in ('O' /* Downloaded */, 'I' /* Initial */))
    order by Status desc;

  /* select New Orders flagged for preprocessing */
  insert into @ttOrdersToPreprocess(EntityId, EntityKey)
    select OrderId, PickTicket
    from OrderHeaders with (READPAST)
    where (PreprocessFlag = 'N') and (Status in ('N' /* New */));

  /* select Waved Orders flagged for preprocessing but Wave is not yet Released */
  insert into @ttOrdersToPreprocess(EntityId, EntityKey)
    select OH.OrderId, OH.PickTicket
    from OrderHeaders OH with (READPAST)
      join Waves W on (OH.PickBatchId = W.WaveId)
    where (OH.PreprocessFlag = 'N') and
          (OH.Status in ('W' /* Waved */)) and
          (W.Status = 'N' /* New */);

  /* process each order */
  while exists (select * from @ttOrdersToPreprocess where RecordId > @vRecordId)
    begin
      begin try
        /* The NOWAIT hint in the below query causes the statement to raise an error if the corresponding record is locked by another process
           In that instance, the process skips to the next order to preprocess */
        -- select @vTempOrderId = OrderId
        -- from OrderHeaders with (NOWAIT)
        -- where (OrderId = @vOrderId);

        select top 1
               @vRecordId   = RecordId,
               @vOrderId    = EntityId,
               @vPickTicket = EntityKey
        from @ttOrdersToPreprocess
        where (RecordId > @vRecordId)
        order by RecordId;

        /* Call pr_OrderHeaders_Preprocess procedure */
        exec pr_OrderHeaders_Preprocess @vOrderId;

        exec pr_ActivityLog_AddMessage 'Preprocess', @vOrderId, @vPickTicket, 'PickTicket',
                                       'Successfully processed', @@ProcId;

      end try
      begin catch
        /* Log Exception into activitylog */
        select @vErrMsg = Error_Message();

        exec pr_ActivityLog_AddMessage 'Preprocess', @vOrderId, @vPickTicket, 'PickTicket',
                                       @vErrMsg, @@ProcId;

        select @vMessageName = 'Import_PreProcessException';
      end catch
    end /* while there is another record to process */

  /* On Error, return Error Code/Error Message. Since exception is raised job would fail
     and an alert would be sent out. We can research the ActivityLog to determine which
     order failed and why */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_PreprocessOrders */

Go

/*------------------------------------------------------------------------------
  Proc pr_Imports_PreprocessReceipts:

  Used For: For each New or Updated Receipt, call pr_ReceiptHeaders_Preprocess procedure
------------------------------------------------------------------------------*/
