/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/06/13  VM      pr_Receivers_PutawayInventory: Exclude voided LPNs (S2G-947)
                      pr_Receivers_Close: Consider receivers with void LPNs as well and code optimization (S2G-947)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_PutawayInventory') is not null
  drop Procedure pr_Receivers_PutawayInventory;
Go
/*------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_PutawayInventory
  ( @ttReceipts    TEntityKeysTable readonly,
    @BusinessUnit  TBusinessUnit,
    @UserId        TUserId)
as
  declare @vReceiptId                  TRecordId,
          @vRecordId                   TRecordId,
          @vReceiverNo                 TReceiverNumber,

          @vReceiverLPNCount           TCount,
          @vReceiverLPNPutAwayCount    TCount,
          @ReturnCode                  TInteger;

  /* Declare temp table for holding the Receipt values */
  declare @ttReceiptLPNs table(RecordId       TRecordId Identity(1,1),
                               ReceiptId      TRecordId,
                               ReceiverNumber TReceiverNumber,
                               LPNStatus      TStatus);
begin
begin try
  SET NOCOUNT ON;

  select @vRecordId = 0;

  /* Exclude voided LPNs to process */
  insert into @ttReceiptLPNs(ReceiptId, ReceiverNumber, LPNStatus)
    select R.EntityId, R.EntityKey, L.Status
    from @ttReceipts R
      join LPNs L on (R.EntityKey = L.ReceiverNumber)
    where (L.Status <> 'V' /* Voided */);

  while (exists ( select * from @ttReceiptLPNs where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId   = RecordId,
                   @vReceiptId  = ReceiptId,
                   @vReceiverNo = ReceiverNumber
      from @ttReceiptLPNs
      where RecordId > @vRecordId
      order by RecordId;

      /* Count the total LPNs of the Receiver and how many have been Putaway */
      select @vReceiverLPNCount        = count(*),
             @vReceiverLPNPutawayCount = sum(case when LPNStatus = 'R' then 1 else 0 end)
      from @ttReceiptLPNs
      where ReceiverNumber = @vReceiverNo;

      --select @vReceiverLPNCount, @vReceiverLPNPutAwayCount

      /* If all LPNs are not already Putaway then */
      if (@vReceiverLPNCount <> @vReceiverLPNPutawayCount)
         begin
           delete from @ttReceiptLPNs where ReceiverNumber = @vReceiverNo;
         end
      else
        begin
          /* Putaway all LPNs on the receiver */
          exec pr_Receipts_PutawayInventory @vReceiverNo, @vReceiptId, @BusinessUnit, @UserId;
        end
    end
end try
begin catch
  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_Receivers_PutawayInventory */

Go
