/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/12/19  TD      pr_RFC_Picking_GetLPNPick:Added more validations.
  2014/07/12  TD      pr_RFC_Picking_GetLPNPick, pr_RFC_Picking_ConfirmLPNPick:Changes to
  2014/06/13  TD      pr_RFC_Picking_GetLPNPick, pr_RFC_Picking_ConfirmLPNPick: Changes to display Quantity,
  2014/05/09  PK      pr_RFC_Picking_GetLPNPick, pr_RFC_Picking_ConfirmLPNPick:
  2012/10/10  PK      pr_RFC_Picking_GetLPNPick, pr_RFC_Picking_GetUnitPick, pr_RFC_Picking_GetBatchPalletPick,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_GetLPNPick') is not null
  drop Procedure pr_RFC_Picking_GetLPNPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_GetLPNPick:

   @xmlInput Contains                        XML:
                                       <SelectionCriteria>
   1. @OrderType                         <OrderType></OrderType>
   2. @StartRow                          <StartRow></StartRow>
   3. @EndRow                            <EndRow></EndRow>
   4. @StartLevel                        <StartLevel></StartLevel>
   5. @EndLevel                          <EndLevel></EndLevel>
   6. @StartSection                      <StartSection></StartSection>
   7. @EndSection                        <EndSection></EndSection>
                                         <TaskId></TaskId>
                                         <TaskDetailId></TaskDetailId>
                                       </SelectionCriteria>

------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_GetLPNPick
  (@DeviceId       TDeviceId,
   @UserId         TUserId,
   @PickTicket     TPickTicket,
   @PickZone       TZoneId,
   @xmlInput       xml       = null, /* User input */
   @xmlResult      xml       output)
As
  declare @ValidPickZone                  TZoneId,
          @LPNToPick                      TLPN,
          @LPNIdToPick                    TRecordId,
          @LocationToPick                 TLocation,
          @SKUToPick                      TSKU,
          @UnitsToPick                    TInteger,
          @LPNLocationId                  TLocation,
          @LPNLocation                    TLocation,
          @LPNPalletId                    TPallet,
          @TaskId                         TRecordid,
          @vLPNSKUId                      TRecordId,
          @LPNSKU                         TSKU,
          @LPNQuantity                    TInteger,
          @vLPNInnerPacks                 TInnerPacks,
          @ValidPickTicket                TPickTicket,
          @OrderId                        TRecordId,
          @OrderDetailId                  TRecordId,
          @SalesOrder                     TSalesOrder,
          @OrderLine                      TOrderLine,
          @OrderType                      TTypeCode,
          @HostOrderLine                  THostOrderLine,
          @UnitsAuthorizedToShip          TInteger,
          @UnitsAssigned                  TInteger,
          @PickingPallet                  TPallet,
          @Warehouse                      TWarehouse,
          @BusinessUnit                   TBusinessUnit,
          @vIsOrderTasked                 TFlag,
          @vTaskId                        TRecordId,
          @vTaskDetailId                  TRecordId,
          @vTaskStatus                    TStatus,
          @vTaskSubType                   TTypeCode,
          @LPNSKUDesc                     TDescription,
          @vUserWarehouse                 TWarehouse,
          @vDestDropZone                  TZoneId,
          @vDestDropLoc                   TLocation,
          @vBatchType                     TTypeCode,
          @PickBatchNo                    TPickBatchNo,
          @DestZone                       TLookUpCode,
          @PickType                       TTypeCode,
          @Operation                      TOperation,

          @vPickingPalletId               TRecordId,
          @vPickBatchNo                   TPickBatchNo,
          @PTForDisplay                   TDescription,
          @xmlInputparamsInfo             xml,

          @vPickGroup                     TPickGroup,
          @xmlRulesData                   TXML,

          @vActivityLogId                 TRecordId;

  declare @ReturnCode                     TInteger,
          @MessageName                    TMessageName,
          @Message                        TDescription,
          @xmlResultvar                   TVarchar;
begin /* pr_RFC_Picking_GetLPNPick */
begin try
  SET NOCOUNT ON;

  select @xmlInputparamsInfo = convert(xml, @xmlInput),
         @PickTicket         = nullif(@PickTicket, ''),
         @PickZone           = nullif(@PickZone, '');

  /* Get values from input xml */
  ;WITH XMLNAMESPACES(DEFAULT 'SelectionCriteria')
  select @OrderType      = Record.Col.value('OrderType[1]', 'TOrderType'),
         @PickingPallet  = Record.Col.value('PickingPallet[1]', 'TPallet'),
         @Warehouse      = Record.Col.value('Warehouse[1]', 'TWarehouse'),
         @BusinessUnit   = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
         @PickBatchNo    = nullif(Record.Col.value('PickBatchNo[1]', 'TPickBatchNo'), ''),
         @TaskId         = nullif(Record.Col.value('TaskId[1]', 'TRecordId'), ''),
         @DestZone       = nullif(Record.Col.value('DestZone[1]', 'TLookUpCode'), ''),
         @Operation      = Record.Col.value('Operation[1]', 'TOperation'),
         @PickType       = Record.Col.value('PickType[1]', 'TTypeCode')
  from @xmlInputparamsInfo.nodes('SelectionCriteria') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @TaskId, @PickBatchNo, 'TaskId-Wave',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* get the control variables */
  select @vIsOrderTasked = dbo.fn_Controls_GetAsBoolean('Picking', 'IsOrderTasked', 'N' /* No */, @BusinessUnit, @UserId),
         @vUserWarehouse  = dbo.fn_Users_LoggedInWarehouse(@DeviceId, @UserId, @BusinessUnit);

  /* Build the data for evaluation of rules to get pickgroup*/
  select @xmlRulesData = '<RootNode>' +
                           dbo.fn_XMLNode('Operation', @Operation) +
                           dbo.fn_XMLNode('PickType',  @PickType) +
                         '</RootNode>'

  /* Get the valid pickGroup here to find the task  */
  exec pr_RuleSets_Evaluate 'Task_GetValidTaskPickGroup', @xmlRulesData, @vPickGroup output;

  /* if the user enters both then we will go with taskid only --
     there may be a chance that user may enter wrong PT or batch..*/
  if ((@TaskId is not null) and
      ((@PickTicket is not null) or (@PickBatchNo is not null)))
    select  @PickTicket   = null,
            @PickBatchNo = null;

  /* if the operation is Replenishment then we need to suggest replenish wave picks only,
     or else we need to suggest normal picks */
  if (@vIsOrderTasked = 'Y' /* Yes */)
    begin
      /* call procedure here to get the next lpn pick for the task/order */
      exec pr_Picking_FindNextLPNPickForTaskOrWave @vPickGroup, @DestZone, @Warehouse, @DeviceId, @BusinessUnit,
                                                   @UserId, @PickBatchNo output, @TaskId output, @vTaskDetailId output,
                                                   @LPNIdToPick output, @LPNToPick output, @LocationToPick output, @PickZone output,
                                                   @SKUToPick output, @UnitsToPick output, @OrderId output, @OrderDetailId output;

      /* Get all necessary values here */
      select @vTaskStatus  = TaskStatus,
             @vTaskId      = TaskId,
             @vBatchType   = BatchType,
             @vTaskSubType = TaskSubType,
             @PickTicket   = PickTicket
      from vwPickTasks
      where (TaskId = @TaskId) and
            (TaskDetailId = @vTaskDetailId);
    end

  /* There are few transactions where Pallet is Mandatory like Replenishment Picking
     There are some transactions wher Pallet is Non-Mandatory like LPN Picking or Pallet Picking
     This validation is being handled on the RFConnect Side, and hence if Pallet is passed in, only
     then it is validated */
  if (@PickingPallet is not null) and
     (not exists (select *
                  from Pallets
                  where Pallet = @PickingPallet))
    begin
      set @MessageName = 'CartDoesNotExist';
    end
  else
  if (@vTaskId is null) and (@vIsOrderTasked = 'Y'/* Yes */) and (@TaskId is null)
     set @MessageName = 'NoTasksAvailableForPicking';
  else
  if (coalesce(@vTaskSubType, '') <> 'L' /* LPN Pick */) and (@vIsOrderTasked = 'Y'/* Yes */)
     set @MessageName = 'NotALPNTask_UseBatchPicking';
  else
  if (@vTaskId is not null) and (@vTaskStatus = 'O' /* Onhold */)
    set @MessageName = 'TaskNotReleasedForPicking';
  else
  if (@vTaskId is not null) and (@vTaskStatus = 'X' /* Canceled */)
    set @MessageName = 'TaskCanceled';
  else
  if (@vTaskId is not null) and (@vTaskStatus = 'C' /* Completed */)
     set @MessageName = 'TaskCompleted';
  else
  if (@vTaskId is not null) and (@vTaskSubType <> 'L' /* LPN */)
    set @MessageName = 'TaskIsInvalid';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Verify whether the given PickTicket is valid */
  if (@PickTicket is not null)
    exec pr_Picking_ValidatePickTicket @PickTicket,
                                       @OrderId         output,
                                       @ValidPickTicket output;

  /*If  the User Doesnt enter any PT value and it is of type Replenish then we need to
    Search for the top Priority PT of Replenish Type */
  if (@OrderType in ('R', 'RP', 'RU'/*Replenish*/))
    begin
      if (@PickTicket is null)
        begin
          exec pr_Picking_NextPickTicketToPick @DeviceId,
                                               @UserId,
                                               @PickZone,
                                               @OrderType,
                                               @vUserWarehouse,
                                               @OrderId    output,
                                               @PickTicket output;
        end

      /* Get Pallet info here */
      select  @vPickingPalletId = PalletId
      from Pallets
      where Pallet = @PickingPallet;
    end

  /* Verify whether the given PickZone is valid, if provided only */
  exec pr_ValidatePickZone @PickZone, @ValidPickZone output;

  /* if there are any LPN Pick tasks for the order then suggest the LPN pick
     Some times, we will have two LPN picks in a task, so we need to suggest the open one,
     but not the completed one -Some times task Detail Status is not proper so using UnitsToPick */
  /* call FindLPN if the order is not tasked */
  if (@vIsOrderTasked <> 'Y'/* Yes */)
    begin
      exec pr_Picking_FindLPN @OrderId,
                              @ValidPickZone,
                              'F', /* Full LPN Search */
                              default, /* SKU Id */
                              @LPNToPick       output,
                              @LPNIdToPick     output,
                              @LocationToPick  output,
                              @SKUToPick       output,
                              @UnitsToPick     output,
                              @OrderDetailId   output;
    end

  if (@LPNToPick is null)
    set @MessageName = 'NoLPNToPickForPickTicket';

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* Update TaskDetail to InProgress */
  If (@vTaskDetailId is not null)
    update TaskDetails
    set Status = 'I' /* InProgress */
    where (TaskDetailID = @vTaskDetailId);

  /* Update the task status and assign to user */
  if (@vTaskId is not null)
    exec @ReturnCode = pr_Tasks_SetStatus @vTaskId, @UserId, 'I' /* Inprogress */;

  /* if the order is of type Replenish then we need to update the pallet status to
     Picking */
  if (@OrderType in ('R', 'RP', 'RU' /* Replenish Cases, Units */))
    exec pr_Pallets_SetStatus @vPickingPalletId, 'C' /* Picking */, @UserId;

  /* On Success, return Order Info, the Details of LPN to Pick */
  /* select LPN Information */
  select @LPNLocationId  = LocationId,
         @LPNPalletId    = PalletId,
         @vLPNSKUId      = SKUId,
         @LPNQuantity    = Quantity,
         @vLPNInnerPacks = InnerPacks,
         @PickBatchNo   = coalesce(@PickBatchNo, PickBatchNo)
  from LPNs
  where (LPN = @LPNToPick);

  select @LPNSKU     = SKU,
         @LPNSKUDesc = Description
  from SKUs
  where (SKUId = @vLPNSKUId);

  if (@LPNSKU is null)
    select @LPNSKU    = SKU,
           @vLPNSKUId = SKUId
    from SKUs
    where (SKU = @SKUToPick);

  select @LPNLocation = Location
  from Locations
  where (LocationId = @LPNLocationId);

  /* select PickTicket Line Information */
  select @OrderLine             = OrderLine,
         @HostOrderLine         = HostOrderLine,
         @UnitsAuthorizedToShip = UnitsAuthorizedToShip,
         @UnitsAssigned         = UnitsAssigned,
         @vDestDropLoc          = Location,
         @PTForDisplay          = @PickBatchNo + coalesce('/' + @PickTicket, '')
  from OrderDetails
  where (OrderDetailId = @OrderDetailId);

  /* Get DestLocation, DropLocation */
  if (@vBatchType not in ('R', 'RU', 'RP' /* Replenishments */))
    select top 1 @vDestDropZone = DestZoneDescription,
                 @vDestDropLoc  = DestLocation
    from vwbatchingrules
    where (BatchType = @vBatchType) and
          (Warehouse = coalesce(@Warehouse, Warehouse));

  set @xmlResult =  (select @PickTicket       as PickTicket,
                            @OrderId          as OrderId,
                            @OrderDetailId    as OrderDetailId,
                            @UnitsAssigned    as OrderDetailUnitsAssigned,
                            @LPNToPick        as LPN,
                            coalesce(@LPNLocation, @LocationToPick)
                                              as LPNLocation,
                            @LPNPalletId      as LPNPallet,
                            coalesce(@LPNSKU, @SKUToPick)
                                              as SKU,
                            @LPNSKUDesc       as SKUDescription,
                            coalesce(@LPNQuantity, @UnitsToPick)
                                              as LPNQuantity,
                            convert(varchar(max), (@vLPNInnerPacks)) + ' CS '+ '(' + convert(varchar(max), @UnitsToPick) + ' EA)'
                                              as QuantityDescription,
                            @vTaskId          as TaskId,
                            @vTaskDetailId    as TaskDetailId,
                            @PickBatchNo      as PickBatchNo,
                            @PTForDisplay     as DisplayPickTicket,
                            @vDestDropZone    as DestDropZone,
                            @vDestDropLoc     as DestDropLocation,
                            @vPickGroup       as PickGroup
                     FOR XML RAW('LPNPICKINFO'), TYPE, ELEMENTS XSINIL, ROOT('LPNPICKDETAILS'));


  /* Save Device State */
  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'GetLPNPick', @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Update RFLog details  */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_GetLPNPick */

Go
