/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_GetPickForLPN') is not null
  drop Procedure pr_RFC_Picking_GetPickForLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_GetPickForLPN: This procedure will give you the response
     for the scanned tote/LPN.

------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_GetPickForLPN
  (@xmlInput   xml,
   @xmlResult  xml output)
As
  declare @vLPNId               TRecordId,
          @vLPN                 TLPN,
          @vLPNDetailId         TRecordId,
          @vPickZone            TZoneId,
          @vPallet              TLocation,
          @vPickBatchNo         TPickBatchNo,
          @vOrderId             TRecordId,
          @vLocToPickFrom       TLocation,
          @vValidPickZone       TZoneId,
          @vWarehouseId         TWarehouseId,
          @vBusinessUnit        TBusinessUnit,
          @vUserId              TUserId,
          @vDeviceId            TDeviceId,

          @vOrderDetailIdToPick TRecordId,
          @vLPNIdToPickFrom     TRecordId,
          @vLPNToPickFrom       TLPN,
          @vLPNDetailIdToPick   TRecordId,
          @vSKUIdPick           TRecordId,
          @vTaskId              TRecordId,
          @vTaskDetailId        TRecordId,
          @vUnitsToPick         TQuantity,

          @vActivityLogId       TRecordId;

  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @Message             TDescription,
          @xmlResultvar        TVarchar;
begin /* pr_RFC_Picking_GetPickForLPN */
begin try
  SET NOCOUNT ON;

  /* Get values from input xml */
  select @vLPN          = Record.Col.value('LPN[1]', 'TLPN'),
         @vPickZone     = Record.Col.value('PickZone[1]', 'TZoneId'),
         @vPallet       = Record.Col.value('Pallet[1]', 'TPallet'),
         @vOrderId      = Record.Col.value('OrderId[1]', 'TRecordId'),
         @vPickBatchNo  = Record.Col.value('PickBatchNo[1]', 'TPallet'),
         @vWarehouseId  = Record.Col.value('Warehouse[1]', 'TWarehouse'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
         @vUserId       = Record.Col.value('UserId[1]', 'TUserId'),
         @vDeviceId     = Record.Col.value('DeviceId[1]', 'TDeviceId')
  from @xmlInput.nodes('INPUTPARAMS') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      @vOrderId, @vPickBatchNo, 'Order-Wave',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Verify whether the given PickZone is valid, if provided only */
  exec pr_ValidatePickZone @vPickZone, @vValidPickZone output;

  /* call procedure here get next task here */
  exec pr_Picking_FindNextTaskForLPN @vOrderId, @vValidPickZone, @vOrderDetailIdToPick output, @vLPNIdToPickFrom output,
                                     @vLPNToPickFrom output, @vLPNDetailIdToPick output, @vSKUIdPick output,
                                     @vLocToPickFrom output, @vTaskId output, @vTaskDetailId output,
                                     @vUnitsToPick output;

  /* pass the above values to build the buld xml for the next pick */
  if (@vLPNToPickFrom is not null)
    exec pr_Picking_BuildPickResponseForLPN @vPallet, @vLPNIdToPickFrom, @vLPNToPickFrom, @vLPNDetailIdToPick,
                                            @vLocToPickFrom, @vOrderDetailIdToPick, @vPickBatchNo, @vValidPickZone,
                                            @vSKUIdPick, @vTaskId, @vTaskDetailId, @vUnitsToPick, @vBusinessUnit,
                                            @vUserId, @xmlResult output;

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* Save Device State */
  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @vDeviceId, @vUserId, 'GetUnitPickForLPN', @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Add to RF Log */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_GetPickForLPN */

Go
