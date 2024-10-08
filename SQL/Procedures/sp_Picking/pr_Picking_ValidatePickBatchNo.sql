/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/01  YJ    : pr_Picking_ValidatePickBatchNo: Migrated from Prod (S2GCA-98)
                      pr_Picking_ValidatePickBatchNo: Added new Parameter BatchType (FB-440).
  2015/09/01  VM      pr_Picking_ValidatePickBatchNo: BatchNoDoesNotExist => BatchDoesNotExist
  2015/03/20  NY      pr_Picking_ValidatePickBatchNo: Added Packing status batch to validate picking.
  2015/03/02  TK      pr_Picking_ValidatePickBatchNo: Added validation to restrict user using other than Cart type Pallets
  2015/01/16  TK      pr_Picking_ValidatePickBatchNo: Added validtion to check whether batch is allocated or not.
  2014/04/22  TD      pr_Picking_ValidatePickBatchNo:Changed Quantity to DetailQuantity as per view change.
                      pr_Picking_ValidatePickBatchNo: Changed to check the UnitsToAllocate fron PickTasks.
  2012/09/06  PK      pr_Picking_ValidatePickBatchNo: Modifed to allow Picked Batch if there are
  2012/07/20  NY      pr_Picking_ValidatePickBatchNo: Added valid batch status 'E - Being Pulled' for picking
  2012/07/11  YA      pr_Picking_ValidatePickBatchNo: Fixes in statuses.
  2011/11/17  PK      pr_Picking_ValidatePickBatchNo : Added new parameter @PickPallet.
  2011/09/11  TD      pr_Picking_ValidatePickBatchNo: Added 'U' (Paused) in condition.
                      pr_Picking_ValidatePickBatchNo,pr_Picking_NextBatchToPick: implemented the procedures
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ValidatePickBatchNo') is not null
  drop Procedure pr_Picking_ValidatePickBatchNo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_ValidatePickBatchNo:
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_ValidatePickBatchNo
  (@PickBatchNo      TPickBatchNo,
   @PickPallet       TPallet,
   @ValidPickBatchNo TPickBatchNo      output,
   @BatchType        TTypeCode         output,
   @BatchWarehouse   TWarehouse = null output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,

          @UserId             TUserId,

          @vBatchStatus       TStatus,
          @vBatchPallet       TPallet,
          @vPalletType        TTypeCode,
          @vUnitsToPick       TQuantity,
          @vIsBatchAllocated    TFlag,
          @vBusinessUnit        TBusinessUnit,
          @vValidBatchStatuses  TVarChar;
begin /* pr_Picking_ValidatePickBatchNo */

  select @vReturnCode  = 0,
         @vMessageName = null;

  select @ValidPickBatchNo  = BatchNo,
         @vBatchStatus      = Status,
         @BatchType         = BatchType,
         @vBatchPallet      = Pallet,
         @vIsBatchAllocated = IsAllocated,
         @BatchWarehouse    = Warehouse,
         @vBusinessUnit     = BusinessUnit
  from PickBatches
  where (BatchNo = @PickBatchNo);

  /* select the valid Batch Statuses */
  select @vValidBatchStatuses = dbo.fn_Controls_GetAsString('BatchPicking', 'ValidBatchStatusToPick', 'RLPUCEKA'/* ReadyToPick to Packing */, @vBusinessUnit, @UserId);

  select @vPalletType = PalletType
  from Pallets
  where (Pallet = @PickPallet);

  /* select the sum of UnitsToAllocate */
  if (@vIsBatchAllocated = 'Y'/* Yes */)
    begin
      select @vUnitsToPick = sum(DetailQuantity - CompletedCount)
      from vwPickTasks
      where (BatchNo = @PickBatchNo);
    end
  else
    begin
      select @vUnitsToPick = sum(UnitsToAllocate)
      from vwOrderDetails
      where (PickBatchNo = @PickBatchNo);
    end

  /* As this is not required for TopsonDowns becuase they use multiple pallets
     while picking a batch */
  /* if (@PickPallet <> @vBatchPallet)
    set @vMessageName = 'BatchUsedWithAnotherPallet';
  else */
  if (@BatchType = 'BP' /* BulkPull */) and (@vPalletType <> 'C' /* Cart */)
    set @vMessageName = 'BulkPull_InvalidPallet'
  else
  /* Verify whether the given PickBatchNo exists */
  if (@ValidPickBatchNo is null)
    set @vMessageName = 'BatchDoesNotExist';
  else
  /* Verify whether the given Batch Status is valid or not */
  if (charindex(@vBatchStatus, @vValidBatchStatuses) = 0)
    set @vMessageName = 'BatchNotAvailableForPicking';
  else
  /* Check whether Batch is allocated or not */
  if (@vIsBatchAllocated = 'N')
    set @vMessageName = 'BatchIsNotAllocated'
  /* if the batch is picked and UnitsToAllocate is zero then if user tries to
     pick the batch then raise the error */
  if ((@vBatchStatus in ('K'/* Picked */)) and (@vUnitsToPick = 0))
    set @vMessageName = 'BatchIsCompletelyPicked';

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_ValidatePickBatchNo */

Go

/*------------------------------------------------------------------------------
  Proc pr_Picking_ValidatePickTicket:
------------------------------------------------------------------------------*/
