/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/14  SK      pr_Receivers_Recount, pr_Receivers_Recalculate: Clear BoL# & Container values if receiver is associated with more than one receipt
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_Recalculate') is not null
  drop Procedure pr_Receivers_Recalculate ;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receivers_Recalculate:

    This procedure is used to process Receivers

  Assumption:
    All validations are done prior to this call
------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_Recalculate
  (@ReceiverId          TRecordId,
   @Options             TFlags         = 'C',
   @BusinessUnit        TBusinessUnit  = null,
   @UserId              TUserId        = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vOptions           TFlags,

          @vReceiverId        TRecordId,
          @vReceiverNo        TReceiverNumber;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  select  @vReceiverId = ReceiverId,
          @vReceiverNo = ReceiverNumber
  from Receivers
  where (ReceiverId = @ReceiverId) and (BusinessUnit = coalesce(@BusinessUnit, BusinessUnit));

  /* Defer Receiver Count updates */
  if (charindex('$C' /* Defer counts */, @Options) <> 0)
    exec pr_Entities_RequestRecalcCounts 'Receiver', @vReceiverId, @vReceiverNo, 'C' /* RecalcOption */,
                                         @@ProcId, default /* Operation */, @BusinessUnit;
  else
  /* Recount */
  if (charindex('C' /* Re(C)ount */, @Options) <> 0)
    exec pr_Receivers_Recount @vReceiverId, @BusinessUnit, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Receivers_Recalculate */

Go
