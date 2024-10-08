/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/08  RIA     pr_Picking_ValidatePallet: Changes to show pallet (BK-678)
  2018/04/18  TK      pr_Picking_ValidatePallet: Consider pallet wave no as next wave no only if there are open tasks for the wave (S2G-CRP)
  2018/03/26  RV      pr_Picking_ValidatePallet: Bug fixed to return the correct task detail (S2G-479)
  2016/06/04  PK      pr_Picking_ValidatePallet: Avoid picking multiple waves into same cart (NBD-587)
  2016/03/18  DK      pr_Picking_ValidatePallet: We do not consider pallet status if validateoption is 'E'(in use) (NBD-279).
  2016/02/11  TK      pr_Picking_ValidatePallet: If user scanned a Task then return that task only (FB-597)
  2015/11/30  TK      pr_Picking_ValidatePallet: Skip validating Pallet Quantity if the task is already associated with the scanned pallet(ACME-425)
  2015/05/06  TK      pr_Picking_ValidatePallet: Added new validation execute condition only if there exists a LPNTask
  2013/11/12  PK      pr_Picking_ValidatePallet: Validating Pallet if the pallet is not empty and if it is been picked
  2103/10/28  TD      pr_Picking_ValidatePallet: Changes to pass pallet associated TaskId.
  2013/10/24  PK      pr_Picking_ValidatePallet: Validating Pallet Status.
  2012/07/31  YA      pr_Picking_ValidatePallet: Allow resuming picking of batch by giving just Pallet.
                      pr_Picking_ValidatePallet: Ensure we are picking to a picking Pallet.
  2011/08/03  DP      pr_Picking_ValidatePallet: Changes done as per review comments
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ValidatePallet') is not null
  drop Procedure pr_Picking_ValidatePallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_ValidatePallet: Validates if the Pallet can be used for Picking
    and for the specified PickBatch. If no PickBatch is specified, then it is
    assumed the existing PickBatch on the Pallet is going to be resumed.

  ValidateOption: 'E' - Validates to make sure the Pallet is Empty
                  'U' - Validates a pallet that is already being used for picking
                        this allows to bypass checks of an empty pallet
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_ValidatePallet
  (@PickPallet      TPallet,
   @ValidateOption  TFlag,
   @PickBatchNo     TPickBatchNo     output,
   @ValidPallet     TPallet          output,
   @TaskId          TRecordId = null output,
   @TaskDetailId    TRecordId = null output)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vMessage              TDescription,
          @vQuantity             TQuantity,
          @vPalletStatus         TStatus,
          @vPalletType           TTypeCode,
          @vPalletBatchNo        TPickBatchNo,
          @vBusinessUnit         TBusinessUnit,
          @vValidPalletStatuses  TVarChar,
          @vPalletId             TRecordId,
          @vTaskId               TRecordId,
          @vTaskPalletId         TRecordId,
          @vTaskPallet           TPallet,
          @vTaskStatus           TStatus,
          @vIsTaskAllocated      TFlag,
          @vTaskSubType          TTypeCode;
begin /* pr_Picking_ValidatePallet */

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vTaskId      = @TaskId;

  /* Get Pallet info */
  select @ValidPallet    = Pallet,
         @vQuantity      = Quantity,
         @vPalletType    = PalletType,
         @vPalletStatus  = Status,
         @vPalletBatchNo = PickBatchNo,
         @vBusinessUnit  = BusinessUnit,
         @vPalletId      = PalletId
  from  Pallets
  where (Pallet = @PickPallet);

  /* Get TaskId if user did not scan any Task, this is because user sometimes wants to pick a particular
     Task, so we dont want to change the Task, however we would validate the scanned TaskId later,

     In perfect world, we do not have two tasks associated with a pallet. But in some  case,
     if we do have then we need to get the first one */
  if (@TaskId is null)
    begin
      select top 1 @TaskId = TaskId
      from Tasks
      where (PalletId = @vPalletId) and
            (Status in ('N' /* New */, 'I' /* InProgress */))
      order by Status;
    end

  /* Get TaskDetailId - this is related performance, we need to get first one instead of
     scanning all lines */
  select top 1 @TaskDetailId = TaskDetailId
  from TaskDetails
  where (TaskDetailId =  coalesce(nullif(@TaskDetailId, 0), TaskDetailId)) and
        (TaskId       = @TaskId) and
        (Status in ('N' /* New */, 'I' /* InProgress */))
  order by Status;

  /* Get the Task PalletId to verify wether scanned TaskId is associated with other pallet */
  select @vTaskPalletId    = PalletId,
         @vTaskPallet      = Pallet,
         @vTaskStatus      = Status,
         @vIsTaskAllocated = IsTaskAllocated,
         @PickBatchNo      = coalesce(@PickBatchNo, BatchNo),
         @vTaskSubType     = TaskSubType
  from Tasks
  where (TaskId = @TaskId);

  /* select the valid Pallet Statuses */
  select @vValidPalletStatuses = dbo.fn_Controls_GetAsString('Picking', 'ValidPalletStatuses', 'ECKPA'/* Empty, Picking, Picked, Putaway, Allocated */, @vBusinessUnit, null/* UserId */);

  /* If the pallet is already associated with the given batch, then treat it
     as a Pallet in use and ignore other validations */
  if (@vPalletBatchNo = @PickBatchNo)
    set @ValidateOption = 'U';
  else
  if ((@PickBatchNo is null) and (@vPalletBatchNo is not null) and (@vTaskStatus = 'I'/* InProgress */))
    select @ValidateOption = 'U',
           @PickBatchNo    = @vPalletBatchNo;

  /* Validate the Pallet */
  if (@ValidPallet is null)
    set @vMessageName = 'PalletDoesNotExist';
  else
  if (@PickBatchNo <> @vPalletBatchNo) /* If both are not null, they should be the same */
    set @vMessageName = 'PalletUsedWithAnotherBatch';
  else
  if (@vTaskPalletId is not null) and (@vTaskPalletId <> @vPalletId)
    exec @vMessageName = dbo.fn_Messages_Build 'TaskAssociatedwithAnotherPallet', @vTaskPallet;
  else
  /* Validate the Pallet Quantity and LPNs Quantity on Pallet */
  if (@ValidateOption = 'E') and (@vQuantity > 0) and
     ((@TaskId is null) or (coalesce(@vTaskPalletId, 0) <> @vPalletId))
    set @vMessageName = 'Picking_PalletNotEmpty';
  else
  if (@ValidateOption = 'E') and
     (exists(select * from vwLPNs where Pallet = @ValidPallet and Quantity > 0)) and
     ((@TaskId is null) or (coalesce(@vTaskPalletId, 0) <> @vPalletId))
    set @vMessageName = 'LPNsonPalletNotEmpty';
  else
  /* Validate Pallet Status */
  if (charindex(@vPalletStatus, @vValidPalletStatuses) = 0)
    set @vMessageName = 'PalletNotAvailableForPicking';
  else
  if (@ValidateOption = 'U' /* In use */) and
     (@vPalletType not in ('P','C', 'T') /* Picking Pallet, Cart or Trolley */) and
     (@vPalletStatus <> 'E' /* Empty */)
    set @vMessageName = 'NotaPickingPallet';
  else
  if (@vPalletStatus <> 'E'/* Empty */) and (@TaskId is null) and (@ValidateOption = 'E' /* Empty */)
    set @vMessageName = 'Picking_PalletAlreadyPickedForTask';
  else
  /* if user scans the Task and pallet which is associated with another task then
     we need to raise an error */
  if (@vPalletStatus <> 'E'/* Empty */) and
     (coalesce(@vTaskId, @TaskId, '')) <> coalesce(@TaskId, '')
    set @vMessageName = 'Picking_PalletAlreadyPickedForTask';
  else
  /* Allow user to pick into the cart which is built for the scanned TaskId
    ***Assuming that PalletId will be updated on the Task when building the cart*/
  if exists(select * from LPNTasks
            where TaskId = @vTaskId) and
     not exists (select * from Tasks
                 where PalletId = @vPalletId and
                       TaskId   = @vTaskId) and
     (@vIsTaskAllocated = 'N' /* Not Allocated */)
    set @vMessageName = 'ScannedPalletIsNotAssociatedWithTask';
  else
  if (@vTaskSubType = 'L' /* LPN Pick */) and (@vPalletType = 'C'/* Cart */)
    set @vMessageName = 'CannotPickLPNsOnToCart';

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_ValidatePallet */

Go
