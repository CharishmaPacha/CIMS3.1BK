/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/14  SK      pr_Receivers_Recount, pr_Receivers_Recalculate: Clear BoL# & Container values if receiver is associated with more than one receipt
                      pr_Receivers_AutoCreateReceiver: Pass on BoL# & Container values when auto create receiver is called to update Receiver (HA-392)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_Recount') is not null
  drop Procedure pr_Receivers_Recount ;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receivers_Recount:

    This procedure is used to process Receivers counts

  Assumption:
    All validations are done prior to this call
------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_Recount
  (@ReceiverId       TRecordId,
   @BusinessUnit     TBusinessUnit  = null,
   @UserId           TUserId        = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vOptions           TFlags,

          @vReceiverId        TRecordId,
          @vBolNoCount        TCount,
          @vContainerNoCount  TCount;

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get Receiver details */
  select @vReceiverId = @ReceiverId;

  /* Fetch Counts */
  select @vBolNoCount       = count(distinct ROH.BillNo),
         @vContainerNoCount = count(distinct ROH.ContainerNo)
  from ReceivedCounts RC
    join ReceiptHeaders ROH on RC.ReceiptId = ROH.ReceiptId
  where (RC.ReceiverId = @vReceiverId) and
        (RC.Status = 'A' /* Active */);

  /* Update Receivers */
  update Receivers
  set BoLNumber = case when @vBolNoCount       > 1 then null
                       else BoLNumber end,
      Container = case when @vContainerNoCount > 1 then null
                       else Container end
  where (ReceiverId = @vReceiverId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Receivers_Recount */

Go
