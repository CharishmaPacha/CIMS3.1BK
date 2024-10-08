/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/09/04  TD      Added pr_Picking_GetPickTaskForPickZone.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_GetPickTaskForPickZone') is not null
  drop Procedure pr_Picking_GetPickTaskForPickZone;
Go

Create Procedure pr_Picking_GetPickTaskForPickZone
  (@PickZone        TZoneId,
   @DestZone        TLookUpCode,
   @PickGroup       TPickGroup,
   @PickTicket      TPickTicket,
   @PickBatchNo     TPickBatchNo,
   @Operation       TDescription = null,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @Warehouse       TWarehouse,
   @ValidPickZone   TZoneId   = null output,
   @TaskId          TRecordId = null output)
as
  declare @vReturnCode                           TInteger,
          @vMessageName                          TMessageName,
          @vMessage                              TDescription;
begin /* pr_Picking_GetPickTaskForPickZone */

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* select first task here from the Tasks table for the given Zone and PickGroup .
    If the user is passing the DestZone then we need to conisder that as well */
  select top 1 @TaskId        = T.TaskId,
               @ValidPickZone = T.PickZone
  from Tasks T
    join TaskDetails TD on (T.TaskId = TD.TaskId)
    join OrderHeaders OH on (TD.OrderId = OH.OrderId)
  where (T.Status       in ('N' /* Ready to pick */, 'I' /* InProgress */)) and
        (T.BatchNo      = coalesce(@PickBatchNo, T.BatchNo)) and
        (OH.PickTicket   = coalesce(@PickTicket,  OH.PickTicket)) and
        (T.BusinessUnit = @BusinessUnit) and
        (T.Warehouse    = @Warehouse) and
        (T.PickGroup    like @PickGroup + '%') and
        (T.DestZone     = coalesce(@DestZone, T.DestZone)) and
        (@UserId      = coalesce(AssignedTo, @UserId)) and
        (T.PickZone like coalesce(@PickZone, T.PickZone) + '%');

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_GetPickTaskForPickZone */

Go
