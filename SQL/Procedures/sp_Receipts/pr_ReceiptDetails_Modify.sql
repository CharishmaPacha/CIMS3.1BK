/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/06/14  MV      pr_ReceiptDetails_Modify: Add action to allow user to modify Receipt Details (FB-706)
  2016/06/04  TK      pr_ReceiptDetails_Modify: Initial Revision (FB-685)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptDetails_Modify') is not null
  drop Procedure pr_ReceiptDetails_Modify;
Go
/*------------------------------------------------------------------------------
Proc pr_ReceiptDetails_Modify: This procedure will update the Order lines with given
                             data after validating it.

  <Root>
    <Entity>ReceiptDetails</Entity>
    <Action></Action>
    <data>
      <QtyOrdered></QtyOrdered>
    </data>
    <ReceiptDetails>
      <ReceiptDetail>
        <ReceiptDetailId></ReceiptDetailId>
      </ReceiptDetail>
    </ReceiptDetails>
  </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptDetails_Modify
  (@ReceiptDetailContent  XML,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId,
   @xmlResult             TXML           output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,
          @vActivityType          TActivityType,
          @vActivityDateTime      TDateTime,
          @vAction                TAction,

          @vReceiptDetailsCount   TCount,
          @vTotalReceiptDetails   TCount,
          @vReceiptDetailsUpdated TCount,
          @vTotalOrderDetails     TCount,

          @vReceiptId             TRecordId,
          @vReceiptDetailId       TRecordId,

          @vNewQtyOrdered         TQuantity,
          @vNewQtyToReceive       TQuantity,
          @vPrevQtyOrdered        TQuantity,
          @vPrevQtyToReceive      TQuantity;

  declare @ttReceiptsToRecount    TEntityKeysTable;

  declare @ttReceiptDetails table
          (ReceiptDetailId      TRecordId,
           ReceiptId            TRecordId,
           ReceiptNumber        TPickTicket,
           ReceiptStatus        TStatus,
           SKUId                TRecordId,
           HostReceiptLine      THostReceiptLine,
           PrevQtyOrdered       TQuantity,
           ProcessedFlag        TFlag,

           RecordId             TRecordId identity(1,1)
           primary key (RecordId));
begin
begin try
  begin transaction;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get the Action from the xml */
  select @vAction = Record.Col.value('Action[1]', 'TAction')
  from @ReceiptDetailContent.nodes('/ModifyReceiptDetails') as Record(Col);

  /* insert all the ReceiptDetails into the temp table which are to be updated in Order Details */
  insert into @ttReceiptDetails (ReceiptDetailId, ReceiptId, ReceiptNumber, ReceiptStatus, SKUId, HostReceiptLine, PrevQtyOrdered, --PrevReceiptStatus,
                                 ProcessedFlag)
    select RD.ReceiptDetailId,
           RD.ReceiptId,
           RH.ReceiptNumber,
           RH.Status,
           RD.SKUId,
           RD.HostReceiptLine,
           RD.QtyOrdered,
           'N'/* Process Flag - Not Processed */
    from @ReceiptDetailContent.nodes('/ModifyReceiptDetails/ReceiptDetails/ReceiptDetail') as Record(Col)
      join ReceiptDetails RD on (RD.ReceiptDetailId =Record.Col.value('ReceiptDetailId[1]', 'TRecordId'))
      join ReceiptHeaders RH on (RD.ReceiptId = RH.ReceiptId);

  /* Get the row count into a variable */
  select @vTotalReceiptDetails = @@rowcount;

  /* Modifying ReceiptDetails according to the action */
  if (@vAction = 'ModifyReceiptDetails')
    begin
      select @vActivityType     = 'RDModified_QtyOrdered',
             @vActivityDateTime = current_timestamp;

      /* Get the User input value of QtyOrdered */
      select @vNewQtyOrdered   = nullif(Record.Col.value('QtyOrdered[1]'   , 'TQuantity'), 0)
      from @ReceiptDetailContent.nodes('/ModifyReceiptDetails/Data') as Record(Col);

      /* Marking items as failed which are not authorized to modify */
      update ROD
      set ProcessedFlag = 'F' /* Failed, Not to be processed */
      from @ttReceiptDetails ROD
      where ReceiptStatus not in ('I', 'R' /* Initial, In Progress */);

      select @vRecordId              = 0,
             @vReceiptDetailsUpdated = 0;

      /* Loop through and process all the Details */
      while exists (select *
                    from @ttReceiptDetails
                    where (RecordId > @vRecordId) and
                          (ProcessedFlag = 'N' /* No, yet to be processed */))
        begin
          select top 1 @vRecordId        = RecordId,
                       @vReceiptId       = ReceiptId,
                       @vReceiptDetailId = ReceiptDetailId,
                       @vPrevQtyOrdered  = PrevQtyOrdered
          from @ttReceiptDetails
          where (RecordId > @vRecordId) and
                (ProcessedFlag = 'N' /* No, yet to be processed */)
          order by RecordId;

          /* Update ReceiptDetails with the New Qty Ordered, but only if it is above Qty already received */
          update RD
          set RD.QtyOrdered   = @vNewQtyOrdered,
              RD.ModifiedBy   = @UserId,
              RD.ModifiedDate = @vActivityDateTime
          from  ReceiptDetails RD
          where (ReceiptDetailId = @vReceiptDetailId) and
                (@vNewQtyOrdered >= QtyReceived) and
                (@vNewQtyOrdered >= QtyInTransit);

          /* Update the AT if ReceiptDetail modified only */
          if (@@rowcount >0)
            begin
              /* Recount Receipts */
              exec pr_ReceiptHeaders_Recount @vReceiptId;

              /* Log the Audit Trail */
              exec pr_AuditTrail_Insert @ActivityType     = @vActivityType,
                                        @UserId           = @UserId,
                                        @Note2            = @vPrevQtyOrdered,
                                        @ActivityDateTime = @vActivityDateTime,
                                        @ReceiptDetailId  = @vReceiptDetailId;

              /* Update temp table row as processed */
              update @ttReceiptDetails
              set ProcessedFlag = 'Y' /* Yes, Processed */
              where (RecordId = @vRecordId);

              set @vReceiptDetailsUpdated += 1;
            end
        end
    end /* ModifyReceiptDetails */

  /* Building success message response with counts */
  exec @xmlResult  = dbo.fn_Messages_BuildActionResponse 'ReceiptDetails', 'Modify', @vReceiptDetailsUpdated, @vTotalReceiptDetails;

ErrorHandler:
  if (@vMessageName is not null)
    select @xmlResult = dbo.fn_Messages_GetDescription(@vMessageName);

  commit transaction;
end try
begin catch
  /* Handling transactions in case if it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch
ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ReceiptDetails_Modify */

Go
