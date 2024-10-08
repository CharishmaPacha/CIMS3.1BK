/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/10/11  AY      pr_Picking_ValidatePickTicket: Add Staged status as well in invalid list
                      pr_Picking_ValidatePickTicket: Returning PickBatchNo also with default value  'null'
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ValidatePickTicket') is not null
  drop Procedure pr_Picking_ValidatePickTicket;
Go

Create Procedure pr_Picking_ValidatePickTicket
  (@PickTicket      TPickTicket,
   @OrderId         TRecordId    = null output,
   @ValidPickTicket TPickTicket  = null output,
   @PickBatchNo     TPickBatchNo = null output)
as
  declare @vReturnCode                           TInteger,
          @vMessageName                          TMessageName,
          @vMessage                              TDescription,
          @vPickTicketStatus                     TStatus;
begin /* pr_Picking_ValidatePickTicket */

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* The reason for outputting the PickTicket is that we might allow users
     to key in onto a part of the PickTicket and so on Validate we return
     the complete PickTicket as well */
  select @OrderId           = OrderId,
         @ValidPickTicket   = PickTicket,
         @vPickTicketStatus = Status,
         @PickBatchNo       = PickBatchNo
  from OrderHeaders
  where (PickTicket = @PickTicket);

  /* Verify whether the given PickTicket exists */
  if (@OrderId is null)
    set @vMessageName = 'PickTicketDoesNotExist';
  else
  /* Verify whether the given PickTicket can be Picked
     PickTicket should be either Waved, Allocated, Picking status
     Allow Initial as well as we do not have 'Waving' process yet */
  if (dbo.fn_OrderHeaders_ValidateStatus(@OrderId, null /* PickTicket*/, 'IWACG') = 1)
    set @vMessageName = 'PickTicketInvalidForPicking';

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_ValidatePickTicket */

Go
