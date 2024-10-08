/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/15  SJ      pr_ReceiptHeaders_ROClose:Modified permission name (HA-1355)
  2020/04/03  AY      pr_ReceiptHeaders_ROClose: Changed to return results via ResultMessages (JL-160)
  2018/06/14  TK      pr_ReceiptHeaders_GetToReceiveDetails & pr_ReceiptHeaders_ROClose:
                        Changes to validate SKU Attributes (S2GCAN-26)
  2014/03/08  NY      pr_ReceiptHeaders_ROClose : Added control variable to not to validate SKU while closing RO.(xsc-505)
  2013/09/03  TD      pr_ReceiptHeaders_ROClose:Changes to close the RO if the SKU has valid dimensions.
  2013/09/02  PK      Added new procedure pr_ReceiptHeaders_ROClose, pr_ReceiptHeaders_ROReopen to close and reopen
                        receipts and generating exports.
                      pr_ReceiptHeaders_Modify: Modified to call pr_ReceiptHeaders_ROCloseReopen.
              TD      pr_ReceiptHeaders_GetToReceiveDetails:Send QtyToreceive =0 lines as response, but those are
                         end of the result.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptHeaders_ROClose') is not null
  drop Procedure pr_ReceiptHeaders_ROClose;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptHeaders_ROClose: Closes the RO if it can be closed,
    generates exports if required and also marks the LPN as putaway if so
    desired.
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptHeaders_ROClose
  (@Receipts           TEntityKeysTable ReadOnly,
   @Export             TFlag,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @ReceiptsUpdated    TCount   output,
   @Message            TNVarChar output)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,

          @vReceiptid        TRecordId,
          @vRecordId         TRecordId,
          @vOwnership        TOwnership,
          @vWarehouse        TWarehouse,
          @vActivityType     TActivityType,
          @vAuditId          TRecordId,
          @vAuditRecordId    TRecordId,
          @vAllowedToCloseIncompleteROs
                             TFlag;

  /* Temp table */
  declare @ttReceiptsUpdated TEntityKeysTable;
  declare @ttValidReceipts   TEntityKeysTable;

  declare @ttReceiptDetails Table
          (RecordId      TRecordId Identity(1,1),
           ReceiptId     TRecordId,
           ReceiptNumber TReceiptNumber,
           SKU           TSKU,
           Message       TDescription);
begin
begin try
  SET NOCOUNT ON;
  /* Variable Initialization */
  select @ReceiptsUpdated = 0,
         @vReceiptId      = 0,
         @vActivityType   = 'Receipts_ROClose';

  /* If a RO is not completely received, then only allow personnel with higher
      authorization to close it */
  select @vAllowedToCloseIncompleteROs = dbo.fn_Permissions_IsAllowed(@UserId, 'Receipts.Pri.CloseIncompleteRO');

  /* Not to consider SKU Dimesions when closing RO */
  -- Now implemented as SKUs_IsOperationAllowed
  --select @vCloseROValidateSKUDim = dbo.fn_Controls_GetAsString('Receipts', 'CloseROValidateSKUDim', 'N', @BusinessUnit, @UserId);

  /* Iterate thru each RO and verify if there are any SKU validations, if not
     add it to the list of ROs to be closed */
  while (exists(select * from @Receipts where EntityId > @vReceiptId))
    begin
      /* select next  top 1 receipt info */
      select top 1 @vReceiptId  = EntityId
      from @Receipts
      where (EntityId > @vReceiptId)
      order by EntityId;

      /* Get all RODtls and their corresponding Warnings - if any */
      insert into @ttReceiptDetails(ReceiptId, ReceiptNumber, SKU, Message)
        select ReceiptId, ReceiptNumber, SKU, dbo.fn_SKUs_IsOperationAllowed(SKUId, 'CloseRO') /* Message */
        from vwReceiptDetails
        where (ReceiptId = @vReceiptid);

      /* if the PO has valid SKU dimension then we need to Insert that data */
      /* if message is not null then it is not a valid SKU, i.e. if there is any rows with message is not null
         then it is not a valid RO to close  */
      if (not exists(select * from @ttReceiptDetails where Message is not null))
        begin
          insert into @ttValidReceipts(EntityId) select @vReceiptid;
        end
      else
        begin
          insert into #ResultMessages (MessageType, MessageText, EntityId, EntityKey)
            select distinct 'E', 'RO ' + ReceiptNumber, ReceiptId, ReceiptNumber
            from @ttReceiptDetails where Message is not null;

          insert into #ResultMessages (MessageType, MessageText, ParentEntityKey)
            select 'E', 'RO ' + coalesce(ReceiptNumber, '') + ' SKU ' + coalesce(SKU, '') + ' - ' +
                   coalesce(dbo.fn_Messages_GetDescription(Message), ''), ReceiptNumber
            from @ttReceiptDetails
            where Message is not null;
        end
    end

  /* Close Receipts */
  update R
  set Status       = 'C' /* Close */,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId,
      @vOwnership  = R.Ownership,
      @vWarehouse  = R.Warehouse
  output Inserted.ReceiptId, Inserted.ReceiptNumber
  into @ttReceiptsUpdated
  from ReceiptHeaders R
    join @ttValidReceipts TR on (TR.EntityId = R.ReceiptId)
  where (R.Status = 'E' /* Received */) or
        ((@vAllowedToCloseIncompleteROs = '1' /* Yes */) and
        (R.Status != 'C'/* Close */));

  /* Get the count of Receipts */
  set @ReceiptsUpdated = @@rowcount;

  if (@Export = 'Y'/* Yes */)
    begin
      select @vRecordId = 0;

      /* Loop through each record and export the data to host system */
      while (exists(select * from @ttReceiptsUpdated where RecordId > @vRecordId))
        begin
          /* Get the next record receipt from temp table */
          select top 1 @vRecordId   = TRH.RecordId,
                       @vReceiptid  = TRH.EntityId,
                       @vOwnership  = RH.Ownership,
                       @vWarehouse  = RH.Warehouse
          from @ttReceiptsUpdated TRH
            join ReceiptHeaders RH on (RH.ReceiptId    = TRH.EntityId) and
                                      (RH.BusinessUnit = @BusinessUnit)
          where (TRH.RecordId > @vRecordId);

          /* Puatway all the received LPNs for the receipt before we close an receipt */
          exec pr_Receipts_PutawayInventory null /* Receiver */, @vReceiptId, @BusinessUnit, @UserId;

          /* Generate the necessary exports on RO Close */
          exec pr_ReceiptHeaders_AfterROClose @vReceiptId, @BusinessUnit, @UserId;
        end
    end

  /* Only if any of the ROHs are updated, generate audittrail else skip. */
  if (@ReceiptsUpdated > 0)
    begin
      exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */,
                                @BusinessUnit  = @BusinessUnit,
                                @AuditRecordId = @vAuditId output;

      exec pr_AuditTrail_InsertEntities @vAuditId, 'Receipt', @ttReceiptsUpdated, @BusinessUnit;
    end

  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

end try
begin catch

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_ReceiptHeaders_ROClose */

Go
