/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/09/02  PK      Added new procedure pr_ReceiptHeaders_ROClose, pr_ReceiptHeaders_ROReopen to close and reopen
                        receipts and generating exports.
                      pr_ReceiptHeaders_Modify: Modified to call pr_ReceiptHeaders_ROCloseReopen.
              TD      pr_ReceiptHeaders_GetToReceiveDetails:Send QtyToreceive =0 lines as response, but those are
                         end of the result.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptHeaders_ROReopen') is not null
  drop Procedure pr_ReceiptHeaders_ROReopen;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptHeaders_ROReopen:
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptHeaders_ROReopen
  (@Receipts           TEntityKeysTable ReadOnly,
   @Export             TFlag,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @ReceiptsUpdated    TCount  output)
as
  declare @ReturnCode      TInteger,
          @MessageName     TMessageName,

          @vReceiptid      TRecordId,
          @vRecordId       TRecordId,
          @vOwnership      TOwnership,
          @vWarehouse      TWarehouse,
          @vActivityType   TActivityType,
          @vAuditId        TRecordId,
          @vAuditRecordId  TRecordId;

  /* Temp table */
  declare @ttReceiptsUpdated TEntityKeysTable;
begin
begin try
  SET NOCOUNT ON;
  /* Variable Initialization */
  select @ReceiptsUpdated = 0,
         @vActivityType   = 'Receipts_ROReopen';

  /* Reopen Receipts */
  update R
  set Status         = 'I' /* Initial */,
      ModifiedDate   = current_timestamp,
      ModifiedBy     = @UserId
  output Inserted.ReceiptId, Inserted.ReceiptNumber
  into @ttReceiptsUpdated
  from ReceiptHeaders R
    join @Receipts TR on (TR.EntityId = R.ReceiptId)
  where (R.Status = 'C'/* Close */);

  /* Get the count of Receipts */
  set @ReceiptsUpdated = @@rowcount;

  /* select the top 1 receipt info */
  select top 1 @vRecordId   = TRH.RecordId,
               @vReceiptid  = TRH.EntityId,
               @vOwnership  = RH.Ownership,
               @vWarehouse  = RH.Warehouse
  from @ttReceiptsUpdated TRH
    join ReceiptHeaders RH on (RH.ReceiptId    = TRH.EntityId) and
                              (RH.BusinessUnit = @BusinessUnit);

  /* Loop through each record and export the data to host system */
  while (@@rowcount > 0)
    begin
      /* Set the Status of Receipt */
      exec @ReturnCode = pr_ReceiptHeaders_SetStatus @vReceiptid;

      /* Export the log to host system if the Receipt is reopened */
      if (@Export = 'Y'/* Yes */)
        exec pr_Exports_AddOrUpdate @TransType    = 'ROOpen',
                                    @TransEntity  = 'RH',
                                    @TransQty     = 0,
                                    @BusinessUnit = @BusinessUnit,
                                    @ReceiptId    = @vReceiptId,
                                    @Warehouse    = @vWarehouse,
                                    @Ownership    = @vOwnership;

        /* Get the row count of receipts in temp table */
        select top 1 @vRecordId   = TRH.RecordId,
                     @vReceiptid  = TRH.EntityId,
                     @vOwnership  = RH.Ownership,
                     @vWarehouse  = RH.Warehouse
        from @ttReceiptsUpdated TRH
          join ReceiptHeaders RH on (RH.ReceiptId    = TRH.EntityId) and
                                    (RH.BusinessUnit = @BusinessUnit)
        where (TRH.RecordId > @vRecordId);
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
end /* pr_ReceiptHeaders_ROReopen */

Go
