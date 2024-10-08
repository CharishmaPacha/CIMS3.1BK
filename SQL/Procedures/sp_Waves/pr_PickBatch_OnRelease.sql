/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_OnRelease') is not null
  drop Procedure pr_PickBatch_OnRelease;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_OnRelease:

   This procedure will do multiple operations.
    First One: Update DestZone on OrderDetails

    For this we have 3 cases.
    #1. If the SKU on orderdetail is non Sortable/Scannable then we need to direct the SKU to PTL.
    #2  =>  If the average number of units per order for all orders receiving a SKU
            within a wave exceeds a given number, the entire SKU for that wave
            should be processed through the PTL.

    #3 =>  If the number of units per line for any SKU exceeds a certain parameter,
           those units associated with orders exceeding that units per line
           Parameter will be processed through the PTL.

    #4 =>  If the % of orders within the wave that receive a specific SKU exceeds a
           user defined percentage, then the whole SKU for that wave will be
           processed through the PTL.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_OnRelease
  (@PickBatchId      TRecordId,
   @PickBatchNo      TPickBatchNo,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,

          @vWaveType         TTypeCode,
          @vWaveId           TRecordId,
          @vWaveNo           TPickBatchNo,
          @vWaveStatus       TStatus,

          @vOrderDetailId    TRecordId,
          @vSKUId            TRecordId,
          @vNumOrders        TInteger,

          /* PickBatch Attributes */
          @IsSortable             TFlag,
          @vDefaultDestination    TName,
          @vAvgUnitsPerOrder      TInteger,
          @vUnitsPerLine          TInteger,
          @vNumSKUOrdersPerBatch  TInteger,
          @ttBatchedOrderDetails  TBatchedOrderDetails;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Validations */
  if (@PickBatchId is null)
    set @vMessageName = 'PickBatchInvalid';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Get the Wave status */
  select @vWaveStatus = Status
  from Waves
  where (WaveId = @PickBatchId);

  /* If the Wave has not been planned, then determine the dest zone */
  if (@vWaveStatus in ('N' /* New */))
    begin
      /* insert into temp table here */
      insert into @ttBatchedOrderDetails
        exec pr_PickBatch_ProcessOrderDetails @PickBatchId, null /* xml - Attributes */, @BusinessUnit, @UserId;

      /* Update Order Details here */
      update OD
      set OD.DestZone     = TBOD.DestZone,
          OD.ModifiedDate = current_timestamp
      from OrderDetails OD
      join @ttBatchedOrderDetails TBOD on (TBOD.OrderDetailId = OD.OrderDetailId);
    end

  if (@vReturnCode > 0)
    goto ExitHandler;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_PickBatch_OnRelease */

Go
