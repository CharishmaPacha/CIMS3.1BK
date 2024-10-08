/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/05/20  OK      pr_ReceiptHeaders_Modify: Added ModifyOwnership action to modify Ownership on the receipt,
  2014/03/03  NY      pr_ReceiptHeaders_Modify: Changed fn_Messages_Build to use fn_Messages_BuildActionResponse to display messages.
  pr_ReceiptHeaders_Modify: Modified to call pr_ReceiptHeaders_ROCloseReopen.
  pr_ReceiptHeaders_Modify: Do not allow close of ROs that are not completely received.
  2013/08/22  NY      pr_ReceiptHeaders_Modify:Added new procedure to close/open receipts.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptHeaders_Modify') is not null
  drop Procedure pr_ReceiptHeaders_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptHeaders_Modify:
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptHeaders_Modify
  (@ReceiptContents  TXML,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @Message          TNVarChar output)
as
  declare @ReturnCode            TInteger,
          @MessageName           TMessageName,
          @vAction               TAction,
          @vReceipt              TReceiptNumber,
          @vReceiptid            TRecordId,
          @xmlData               xml,
          @vReceiptsCount        TCount,
          @vReceiptsUpdated      TCount,
          @vExportROCloseROOpen  TFlag,

          /* Owner change */
          @vRecordId             TRecordId,
          @vOldOwner             TOwnership,
          @vNewOwner             TOwnership,
          @vOldOwnerDescription  TDescription,
          @vNewOwnerDescription  TDescription,
          @vValidReceiptStatuses TControlValue,
          @vInValidLPNCount      TCount,

          @vAuditRecordId        TRecordId,
          @vAuditActivity        TActivityType;

  /* Temp table to hold all the Receipts to be updated */
  declare @ttReceipts         TEntityKeysTable,
          @ttReceiptsUpdated  TEntityKeysTable,
          @ttLPNsUpdated      TEntityKeysTable;

begin
begin try
  begin transaction;
  SET NOCOUNT ON;
  set @xmlData = convert(xml, @ReceiptContents);

  select @vReceiptsUpdated = 0,
         @vRecordId        = 0;

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    return

  /* Get the Action from the xml */
  select @vAction = Record.Col.value('Action[1]', 'varchar(100)')
  from @xmlData.nodes('/ModifyReceiptOrders') as Record(Col);

  /* Load all the Receipts into the temp table which are to be updated in ReceiptHeaders table */
  insert into @ttReceipts (EntityId)
    select Record.Col.value('.', 'TRecordId') Receipt
    from @xmlData.nodes('/ModifyReceiptOrders/Receipts/ReceiptId') as Record(Col);

  /* Get number of rows inserted */
  select @vReceiptsCount = @@rowcount;

  /* Get the Control option whether to Generate/Log ROClose and ROOpen Transactions */
  select @vExportROCloseROOpen = dbo.fn_Controls_GetAsBoolean('Receipts', 'ExportROCloseROOpen', 'N' /* No */,
                                                              @BusinessUnit, @UserId);

  /* If action is ROClose */
  if (@vAction = 'ROClose')
    begin
      /* Close Receipt */
      exec pr_ReceiptHeaders_ROClose @ttReceipts,
                                     @vExportROCloseROOpen,
                                     @BusinessUnit,
                                     @UserId,
                                     @vReceiptsUpdated output,
                                     @Message          output;

     /* if the Message is not null then go to Errorhandler */
     if (@Message is not null)
       goto ErrorHandler;
    end
  else
  if (@vAction = 'ROOpen')
    begin
      /* Reopen Receipt */
      exec pr_ReceiptHeaders_ROReopen @ttReceipts,
                                      @vExportROCloseROOpen,
                                      @BusinessUnit,
                                      @UserId,
                                      @vReceiptsUpdated output;
    end
  else
  if (@vAction = 'Receipts_ModifyOwnership')
    begin
      select @vAuditActivity        = 'ReceiptOwnerModified',
             @vValidReceiptStatuses = dbo.fn_Controls_GetAsString('Receipts', 'ValidReceiptsToUpdateOwner', 'I' /* Initial */, @BusinessUnit, @UserId);

      /* Get the New Ownership */
      select @vNewOwner = Record.Col.value('NewOwnership[1]', 'varchar(100)')
      from @xmlData.nodes('/ModifyReceiptOrders/Data') as Record(Col);

      /* Validations */
      select @MessageName = dbo.fn_IsValidLookUp('Owner', @vNewOwner, @BusinessUnit, @UserId);

      if (@MessageName is not null)
        goto ErrorHandler;

      /* loop thru each Receipt to update the Ownership */
      while (exists(select * from @ttReceipts where RecordId > @vRecordId))
        begin
          /* get the next RO to update */
          select top 1 @vRecordId     = RecordId,
                       @vReceiptId    = EntityId
          from @ttReceipts
          where (RecordId > @vRecordId)
          order by RecordId;

          /* Verify all the LPNs Statuses against the Receipt */
          select @vInValidLPNCount = count (*)
          from LPNs
          where (ReceiptId = @vReceiptId) and
                (Status not in ('T','R','V' /* InTransit, Received, Voided */));

          /* Should not allow change of RO if there are any LPNs not in Intransit, Received, Voided status */
          if (coalesce(@vInValidLPNCount, 0) = 0)
            begin
              /* Modify Ownership */
              update RH
              set @vReceiptId    = ReceiptId,
                  @vOldOwner     = Ownership,
                  Ownership      = @vNewOwner,
                  ModifiedDate   = current_timestamp,
                  ModifiedBy     = @UserId
              from ReceiptHeaders RH
              where (RH.ReceiptId  =  @vReceiptId ) and
                    (RH.Ownership  <> @vNewOwner  ) and /* Should not update if Prev and selected Owner is same */
                    (charindex (RH.Status, @vValidReceiptStatuses) > 0) and
                    (BusinessUnit  =  @BusinessUnit);

              if (@@rowcount > 0) /* Update AT if Receipt updated only */
                begin
                  /* Fetch the UOM descriptions */
                  select @vOldOwnerDescription = dbo.fn_LookUps_GetDesc('Owner', @vOldOwner, @BusinessUnit, default),
                         @vNewOwnerDescription = dbo.fn_LookUps_GetDesc('Owner', @vNewOwner, @BusinessUnit, default);

                  /* Update LPN Ownership too if that is Intransit or Received LPN */
                  update L
                  set Ownership    = @vNewOwner,
                      ModifiedDate = current_timestamp,
                      ModifiedBy   = @UserId
                  output Inserted.LPNId, Inserted.LPN into @ttLPNsUpdated
                  from LPNs L
                  where (L.ReceiptId = @vReceiptId) and
                        (L.Status in ('T','R' /* InTransit, Received */));

                  /* Log Audit Trail */
                  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                            @BusinessUnit  = @BusinessUnit,
                                            @ReceiptId     = @vReceiptId,
                                            @Note1         = @vOldOwnerDescription,
                                            @Note2         = @vNewOwnerDescription,
                                            @AuditRecordId = @vAuditRecordId output;

                  /* Log the AuditTrail to all modified LPNs */
                  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'LPN', @ttLPNsUpdated, @BusinessUnit;

                  set @vReceiptsUpdated += 1;
                end
            end
        end
    end
  else
    begin
      /* If the action is not one of the above, send a message to UI saying Unsupported Action*/
      set @MessageName = 'UnsupportedAction';
      goto ErrorHandler;
    end;

  /* Building success message response with counts */
  exec @Message  = dbo.fn_Messages_BuildActionResponse 'Receipt', @vAction, @vReceiptsUpdated, @vReceiptsCount;

  if (@@error <> 0)
    goto ErrorHandler;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_ReceiptHeaders_Modify */

Go
