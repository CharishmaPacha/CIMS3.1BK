/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/25  TK      pr_Allocation_CartCubing_FindPositionToAddCarton: Bug fix in considering CartType on Tasks (HA-Support)
  2020/08/05  TK      pr_Allocation_CartCubing_FindPositionToAddCarton, pr_Allocation_CreatePickTasks_PTS,
                      pr_Allocation_ProcessTaskDetails & pr_Allocation_AddDetailsToExistingTask:
                        Changes to use CartType that is defined in rules (HA-1137)
                      pr_Allocation_FinalizeTasks: Removed unnecessary code as updating dependices is being
                        done in pr_Allocation_UpdateWaveDependencies (HA-1211)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_CartCubing_FindPositionToAddCarton') is not null
  drop Procedure pr_Allocation_CartCubing_FindPositionToAddCarton;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_CartCubing_FindPositionToAddCarton: This procedure return task and shelf
    for which carton can be added
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_CartCubing_FindPositionToAddCarton
  (@CartonType         TCartonType,
   @CartType           TControlValue,
   @Category1          TCategory,
   @Category2          TCategory,
   @Category3          TCategory,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @TaskId             TRecordId = null output,
   @Shelf              TLevel    = null output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,

          @vCartonType          TCartonType,
          @vCartonWidth         TWidth,
          @vCartonHeight        THeight;
begin /* pr_Allocation_CartCubing_FindPositionToAddCarton */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @TaskId       = null;

  /* Get Wave Info */
  select @vCartonType   = CartonType,
         @vCartonWidth  = OuterWidth,
         @vCartonHeight = OuterHeight
  from CartonTypes
  where (CartonType   = @CartonType  ) and
        (BusinessUnit = @BusinessUnit);

  /* Find the task & shelf to add Carton, task should match with Category1 & Category2 */
  select top 1 @TaskId = CS.TaskId,
               @Shelf  = CS.Shelf
  from #CartShelves CS
  where (CS.AvailableWidth >= @vCartonWidth ) and
        (CS.ShelfHeight    >= @vCartonHeight) and
        (CS.CartType       = coalesce(@CartType, CS.CartType)) and
        ((CS.TDCategory1 is null) or (CS.TDCategory1 = @Category1)) and
        ((CS.TDCategory2 is null) or (CS.TDCategory2 = @Category2))
       -- ((CS.TDCategory3 is null) or (CS.TDCategory3 = @Category3))
  order by TaskId, CS.SortOrder;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_CartCubing_FindPositionToAddCarton */

Go
