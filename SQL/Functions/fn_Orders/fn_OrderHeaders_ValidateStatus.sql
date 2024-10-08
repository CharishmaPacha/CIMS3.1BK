/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/12/03  SV      fn_OrderHeaders_ValidateStatus: Had corrected the signature
  2011/01/23  AY      Migrated from RFConnect pr_OrderHeaders_SetStatus,
                      pr_OrderHeaders_Recount & fn_OrderHeaders_ValidateStatus
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_OrderHeaders_ValidateStatus') is not null
  drop Function dbo.fn_OrderHeaders_ValidateStatus;
Go
/*------------------------------------------------------------------------------
  Function fn_OrderHeaders_ValidateStatus:

    function validates if the Order or PickTicket status is present in the
    given ListOfStatus values. Now, this list can be a comma seperated status list
    or a plain string of statuses

    comma seperated list would be the case when the status codes are two or more char
    codes.
    in the case of single char codes, with or without comma is the same
------------------------------------------------------------------------------*/
Create Function fn_OrderHeaders_ValidateStatus
  (@OrderId             TRecordId,
   @PickTicket          TPickTicket,
   @ListOfStatus        varchar(max))
  ----------------------------------
   returns              TInteger
as
begin
  declare @vReturnCode         TInteger,
          @vPickTicketStatus   TStatus;

  set @vReturnCode = 0;

  select @vPickTicketStatus = Status
  from OrderHeaders
  where ((OrderId = @OrderId) or (PickTicket = @PickTicket));

  if (charindex(@vPickTicketStatus, @ListOfStatus) = 0)
    set @vReturnCode = 1;

  return(coalesce(@vReturnCode, 0));
end /* fn_OrderHeaders_ValidateStatus */

Go
