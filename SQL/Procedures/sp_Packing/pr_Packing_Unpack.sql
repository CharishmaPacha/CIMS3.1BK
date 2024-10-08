/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/09/03  SK      pr_Packing_Unpack, pr_Packing_UnpackOrders: Added procedures to unpack packed LPNs from given orders (CIMS-584).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_Unpack') is not null
  drop Procedure pr_Packing_Unpack;
Go
Create Procedure pr_Packing_Unpack
  (@xmlData           xml,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @MessageName       TMessageName output,
   @Message           TMessage output)
as
  declare @vEntity            TEntity,
          @vAction            TAction,
          @vPickCart          TPallet,
          @vWaveId            TRecordId,
          @vWaveNo            TPickBatchNo,
          @vWaveCount         TInteger,
          @vPalletId          TRecordId,
          @vPalletType        TTypeCode,
          @vPalletWave        TPickBatchNo,
          @vWaveStatus        TStatus,
          @vOrderId           TRecordId,
          @vPickTicket        TPickTicket,
          @vRecordId          TRecordId,
          @vOrderStatus       TStatus,
          @vValidOrderStatus  TStatus,
          @vValidWaveStatus   TStatus,
          @vOrdersUnpacked    TInteger,
          @vOrdersCount       TInteger,
          @vFromLPNId         TRecordId,

          @vDateTime          TDateTime,
          @vReturnCode        TInteger,
          @xmlResult          TXML;

  declare @ttOrdersList       TEntityKeysTable;

begin
begin try
begin transaction;
  SET NOCOUNT ON;

  /* Validation Steps
      1. Validate Wave status - picking, picked, packing, packed
      2. Validate Pallet association with Wave

     Process Steps
      1. Get list of orders from the Wave into temp table
         a) Filter order status
      2. Process Orders  Unpack */

  select @vReturnCode     = 0,
         @vRecordId       = 0,
         @vOrdersUnpacked = 0,
         @vDateTime       = getdate();

  /* Get XML Input data */
  select  @vEntity   = Record.Col.value('Entity[1]',   'TEntity'),
          @vAction   = Record.Col.value('Action[1]',   'TAction'),
          @vPickCart = Record.Col.value('PickCart[1]', 'TPallet')
  from @xmlData.nodes('/Root') as Record(Col)

  /* Get wave number if given */
  select @vWaveNo = Record.Col.value('WaveNo[1]', 'TPickBatchNo')
  from @xmlData.nodes('/Root/Waves') as Record(Col)

  /* Get orders list if given */
  insert into @ttOrdersList(EntityId)
    select Record.Col.value('OrderId[1]', 'TRecordId')
    from @xmlData.nodes('/Root/Orders') as Record(Col)

  /* Get wave status to validate */
  select @vWaveId     = RecordId,
         @vWaveStatus = Status
  from Pickbatches
  where (BatchNo = @vWaveNo) and (BusinessUnit = @BusinessUnit);

  /* Get wave no associated with the pallet to validate */
  select @vPalletId   = PalletId,
         @vPalletWave = PickBatchNo,
         @vPalletType = PalletType
  from Pallets
  where (Pallet = @vPickCart) and (BusinessUnit = @BusinessUnit);

  /* Get wave count from the order list if given
     0 - Order list is not provided
     1 - In case of no errors
     2 - Orders given are of more than one batch */
  if (coalesce(@vWaveId, '') = '')
    begin
      select @vWaveCount = count(distinct(OH.PickBatchId)),
             @vWaveId    = min(OH.PickBatchId)
      from @ttOrdersList TT
        join OrderHeaders OH on TT.EntityId     = OH.OrderId and
                                OH.BusinessUnit = @BusinessUnit
    end

  /* Get allowable status for waves and orders to be unpacked */
  /* Expl.: Some of the orders of the wave might still be under picked
            or a status before that and hence wave can be checked for all
            the statuses below */
  select @vValidWaveStatus  = dbo.fn_Controls_GetAsString('Packing', 'ValidUnpackWaveStatus', 'PKAC' /* Picking, Picked, Packing, Packed */, @BusinessUnit, null),
         @vValidOrderStatus = dbo.fn_Controls_GetAsString('Packing', 'ValidUnpackOrderStatus', 'CPK' /* Picking, Picked, Packed */, @BusinessUnit, null);

  /* Validations */
  if (coalesce(@vWaveNo, '') = '' and
      exists(select * from @ttOrdersList where EntityId = 0))
    select @MessageName = 'Unpack_NeedWaveorOrdersList';
  else
  if (coalesce(@vWaveNo, '') <> '') and (@vWaveId is null)
    select @MessageName = 'Unpack_InvalidWave';
  else
  /* Status of the wave is not in the allowable list */
  if (coalesce(@vWaveNo, '') <> '' and
      charindex(@vWaveStatus, @vValidWaveStatus) = 0)
    select @MessageName = 'Unpack_StatusNotValidForWave';
  else
  /* Error out if given wave is not associated with the pallet */
  if (coalesce(@vWaveNo, '') <> '') and
     (@vPalletWave is not null) and
     (@vPalletWave <> @vWaveNo)
    select @MessageName = 'Unpack_PalletNotAssociatedwithWave';
  else
  /* Error out if the order list given are of two different batches */
  if  (@vWaveCount > 1)
    select @MessageName = 'Unpack_InvalidOrdersList';
  else
  if (@vPalletId is null)
    select @MessageName = 'Unpack_InvalidCart';
  else
  if (@vPalletType <> 'C' /* Picking Cart */)
    select @MessageName = 'Unpack_InvalidPalletType';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get Orders list from wave if wave provided and order list not provided
     By default, order list takes precedence over wave number */
  if (coalesce(@vWaveNo, '') <> '' and
      exists(select * from @ttOrdersList where EntityId = 0))
  begin
    /* delete existing values from table */
    delete from @ttOrdersList

    /* insert values using wave number if given */
    insert into @ttOrdersList(EntityId)
      select OrderId
      from OrderHeaders
      where PickBatchNo = @vWaveNo
  end

  /* Get count of orders to be unpacked */
  select @vOrdersCount = count(*)
  from @ttOrdersList

  /* Looping through orders to Unpack */
  while (exists(select * from @ttOrdersList where RecordId > @vRecordId))
    begin
      /* Get next order to unpack */
      select top 1 @vOrderId  = EntityId,
                   @vRecordId = RecordId
      from @ttOrdersList
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Get order info */
      select @vOrderStatus = Status,
             @vPickTicket  = PickTicket
      from OrderHeaders
      where OrderId = @vOrderId

      /* If order status is not one of the valid statuses to unpack, then skip the order */
      if (charindex(@vOrderStatus, @vValidOrderStatus) = 0)
        continue;

      /* Execute unpacking orders */
      exec pr_Packing_UnpackOrders @vOrderId,
                                   @vPickCart,
                                   @BusinessUnit,
                                   @UserId,
                                   @vFromLPNId output,
                                   @xmlResult output;

      exec pr_AuditTrail_Insert @ActivityType     = 'UnpackingOrder',
                                @UserId           = @UserId,
                                @ActivityDateTime = @vDateTime,
                                @LPNId            = @vFromLPNId,
                                @OrderId          = @vOrderId,
                                @ToPalletId       = @vPalletId

      select @vOrdersUnpacked = @vOrdersUnpacked + 1;
    end /* End while loop */



  /* Update pallet with the wave id */
  update Pallets
  set PickBatchId = @vWaveId,
      PickBatchNo = @vWaveNo
  where PalletId = @vPalletId

  /* Manually set status to <Picked> if Status remains in empty
     Assumption: All orders have been unpacked successfully, but the
                 pallet status remains in Empty */
  exec pr_Pallets_SetStatus @PalletId = @vPalletId,
                            @Status = 'K' /* Picked */;

  /* Generate success message */
  exec @Message = dbo.fn_Messages_BuildActionResponse 'Orders', 'Unpack', @vOrdersUnpacked, @vOrdersCount;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @MessageName;

  if (@@trancount > 0)
    commit transaction;

end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_Unpack */

Go
