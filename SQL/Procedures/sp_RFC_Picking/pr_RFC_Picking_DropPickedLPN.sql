/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/10/30  SPP     pr_RFC_Picking_DropPickedLPN: added activity log
                      pr_RFC_Picking_DropPickedLPN: Enhanced to transfer the inventory to drop in picklane location for replenish LPN picks (S2G-453)
  2016/01/20  NY      pr_RFC_Picking_DropPickedLPN, pr_RFC_Picking_DropPickedPallet : Added validation to not to drop pallet/lpn in Inactive location (GNC-1236)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_DropPickedLPN') is not null
  drop Procedure pr_RFC_Picking_DropPickedLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_DropPickedLPN:

  <ConfirmDropPickedLPN xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <DeviceId>Pocket_PC</DeviceId>
    <UserId>teja</UserId>
    <BusinessUnit>GNC</BusinessUnit>
    <LPN>I000000109</LPN>
    <DropDestLocation>RA11-001-01</DropDestLocation>
    <TaskId>1</TaskId>
    <TaskDetailId>2</TaskDetailId>
</ConfirmDropPickedLPN>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_DropPickedLPN
  (@xmlInput      xml,
   @xmlResult     xml output)
As
  declare @xmlResultvar                 TVarChar,
          @vLPNToDrop                   TLPN,
          @vDropLocation                TLocation,
          @vDestLocation                TLocation,
          @vBusinessUnit                TBusinessUnit,
          @vDeviceId                    TDeviceId,
          @vUserId                      TUserId,
          @vLPNId                       TRecordId,
          @vWarehouse                   TWarehouseId,
          @vLocationId                  TRecordId,
          @vLocationType                TTypeCode,
          @vLocationStatus              TStatus,
          @vOrderId                     TRecordId,
          @vPickBatchId                 TRecordId,
          @vWaveNo                      TWaveNo,
          @vTaskId                      TRecordId,
          @vTaskDetailId                TRecordId,
          @vPickBatchType               TTypeCode,
          @vLocation                    TLocation,
          @vOperation                   TDescription,

          @ReturnCode                   TInteger,
          @MessageName                  TMessageName,
          @ConfirmDropPickedLPNMessage  TDescription,
          @vActivityLogId               TRecordId;

begin /* pr_RFC_Picking_DropPickedLPN */
begin try

  SET NOCOUNT ON;

  select @vDeviceId      = Record.Col.value('DeviceId[1]',         'TDeviceId'),
         @vUserId        = Record.Col.value('UserId[1]',           'TUserId'),
         @vBusinessUnit  = Record.Col.value('BusinessUnit[1]',     'TBusinessUnit'),
         @vWarehouse     = Record.Col.value('Warehouse[1]',        'TWarehouseId'),
         @vLPNToDrop     = Record.Col.value('LPN[1]',              'TLPN'),
         @vDropLocation  = Record.Col.value('DropDestLocation[1]', 'TLocation'),
         @vTaskId        = Record.Col.value('TaskId[1]',           'TRecordId'),
         @vTaskDetailId  = Record.Col.value('TaskDetailId[1]',     'TRecordId'),
         @vOperation     = Record.Col.value('Operation[1]',        'TDescription')
  from @xmlInput.nodes('ConfirmDropPickedLPN') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      @vTaskId, @vLPNToDrop, 'TaskId-LPN',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get LPN details here */
  select @vLPNId        = LPNId,
         @vOrderId      = OrderId,
         @vPickBatchId  = PickBatchId,
         @vDestLocation = DestLocation
  from LPNs
  where (LPN          = @vLPNToDrop) and
        (BusinessUnit = @vBusinessUnit);

  /* get LocationId */
  select @vLocationId     = LocationId,
         @vLocation       = Location,
         @vLocationType   = LocationType,
         @vLocationStatus = Status
  from Locations
  where (Location     = @vDropLocation) and
        (BusinessUnit = @vBusinessUnit);

  /* Get BatchType here */
  select @vPickBatchType = BatchType,
         @vWaveNo        = BatchNo
  from PickBatches
  where (RecordId = @vPickBatchId);

    /* Validations */
  if (@vLocationId is null)
    set @MessageName = 'LocationIsInvalid';
  else
  if (@vLocationStatus = 'I' /*Inactive*/)
    set @MessageName = 'LocationIsInactive';
  else
  if (@vLPNId is null)
    set @Messagename = 'LPNIsInvalid';
  else
  /* Allow drop into SDC locations only, except for Replenishments when LPN is destined for the Location */
  if (@vPickBatchType not in ('R', 'RU', 'RP' /* Replensihments */)) and
     (@vLocationType not in ('S', 'D', 'C' /* Staging , Dock, Conveyor */))
    set @Messagename = 'DropPickedLPN_InvalidLocation';
  else
  if (@vPickBatchType in ('R', 'RU', 'RP' /* Replenishments */)) and
     (@vLocation <> coalesce(@vDestLocation, ''))
    set @Messagename = 'DropPickedLPN_InvalidLocation';

  if (@Messagename is not null)
    goto ErrorHandler;

  if (@vOperation = 'DropTote')
    begin
      exec pr_Picking_DropPickedTote @vLPNToDrop, @vDropLocation, @vTaskId, @vTaskDetailId,
                                     @vBusinessUnit, @vUserId;

    end
  else
    begin
      /* Call pr_Picking_DropPickedLPN */
      exec pr_Picking_DropPickedLPN @vLPNToDrop, @vDropLocation, @vTaskId, @vTaskDetailId,
                                    @vBusinessUnit, @vUserId;
    end

  /* Get Confirmation Message */
  set @ConfirmDropPickedLPNMessage = dbo.fn_Messages_GetDescription('DroppedPickedLPNComplete');

  /* XmlMessage to RF, after Pallet is dropped to a Location */
  exec pr_BuildRFSuccessXML @ConfirmDropPickedLPNMessage, @xmlResult output;

  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @vDeviceId, @vUserId, 'DropPickedLPN', @xmlResultvar, @@ProcId;

  /* Insert audit record for every successfull transaction */
  exec pr_AuditTrail_Insert 'PickedLPNDropped', @vUserId, null /* ActivityTimestamp */,
                            @LPNId       = @vLPNId,
                            @LocationId  = @vLocationId,
                            @OrderId     = @vOrderId,
                            @PickBatchId = @vPickBatchId;

ErrorHandler:
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
end /* pr_RFC_Picking_DropPickedLPN */

Go
