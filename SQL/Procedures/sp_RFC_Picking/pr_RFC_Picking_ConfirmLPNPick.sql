/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/20  VS      pr_RFC_Picking_ConfirmLPNPick: Raise proper validation message when we do LPN Pick (BK-111)
                      pr_RFC_Picking_ConfirmLPNPick: Use reason codes from control vars
  2018/09/14  TK      pr_RFC_Picking_ConfirmLPNPick: Corrected XML node to retrieve PickedFromLocation (S2GCA-245)
  2018/03/20  OK      pr_RFC_Picking_ConfirmLPNPick: Enhanced to suggest the dest zone based on dest location
  2018/03/12  TD      pr_RFC_Picking_ConfirmLPNPick:Changes to handle error message in failure cases (S2G-398)
  2018/02/05  TD      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_ConfirmBatchPick, pr_RFC_Picking_ConfirmBatchPick, pr_RFC_Picking_ConfirmLPNPick:
  2017/02/10  OK      pr_RFC_Picking_ConfirmLPNPick: Enhanced to restrict the Picking on OnHold Locations
  2016/09/02  SV      pr_RFC_Picking_ConfirmUnitPick, pr_RFC_Picking_ConfirmLPNPick: Passed new param to pr_Exports_OrderData (HPI-566)
  2015/10/15  RV      pr_RFC_Picking_ConfirmLPNPick: Modified procedure to handle as flag changes in pr_LPNs_Unallocate
  2015/02/27  DK      pr_RFC_Picking_ConfirmLPNPick: Bug fix to get the PickBatchNo
  2014/11/15  TD      pr_RFC_Picking_ConfirmLPNPick: Temporary fix to mark LPN task as completed.
  2014/07/12  TD      pr_RFC_Picking_GetLPNPick, pr_RFC_Picking_ConfirmLPNPick:Changes to
  2014/06/13  TD      pr_RFC_Picking_GetLPNPick, pr_RFC_Picking_ConfirmLPNPick: Changes to display Quantity,
  2014/05/09  PK      pr_RFC_Picking_GetLPNPick, pr_RFC_Picking_ConfirmLPNPick:
  2014/04/09  PV      pr_RFC_Picking_ConfirmBatchPick,pr_RFC_Picking_ConfirmLPNPick, pr_RFC_Picking_ConfirmUnitPick
                      validating UnitsPerCarton in pr_RFC_Picking_ConfirmLPNPick
  2012/08/07  AY      pr_RFC_Picking_ConfirmLPNPick: Additional validations to ensure
  2012/07/25  YA      pr_RFC_Picking_ConfirmLPNPick: Implemented ShortPick of LPNs.
  2012/06/29  YA      pr_RFC_Picking_ConfirmLPNPick: Added BusinessUnit as i/p param, as it is to be used on sub procedure call.
  2012/06/23  PK      pr_RFC_Picking_ConfirmLPNPick, pr_RFC_Picking_ConfirmUnitPick: Updating PickBatch Status.
  2012/05/24  PK      pr_RFC_Picking_ConfirmLPNPick: Added parameter Pallet.
                      pr_RFC_Picking_ConfirmLPNPick(pr_Picking_ConfirmLPNPick) added
  2011/04/06  VM      pr_RFC_Picking_ConfirmUnitPick, pr_RFC_Picking_ConfirmLPNPick:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_ConfirmLPNPick') is not null
  drop Procedure pr_RFC_Picking_ConfirmLPNPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_ConfirmLPNPick:

  ShortPickActions: L Mark LPN as Lost, U - Unallocate, H - Put location on Hold, C - Cycle Count

  1. On picking we will consider AllowedOperations field value on Location. If AllowOperations value contains 'P' then we will allow picking on those locations.
  2. If user short picked any LPN on any location then we will put that Location OnHold, we cannot allow any operations like
     Picking, Putaway and Replenishments on that Location. for this we will update the AllowedOperation field to 'N' in Locations table.
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_ConfirmLPNPick
  (@xmlInput           TXML,
   @xmlResult          TXML  output)
As
  declare @DeviceId                     TDeviceId,
          @UserId                       TUserId,
          @PickTicket                   TPickTicket,
          @OrderDetailId                TRecordId,
          @PickZone                     TZoneId,
          @LPNPicked                    TLPN,
          @LPNPickedLocation            TLocation,
          @PickingPallet                TPallet,
          @ShortPick                    TFlag,
          @TaskId                       TRecordId,
          @TaskDetailId                 TRecordId,
          @DestZone                     TZoneId,
          @Operation                    TOperation,
          @PickGroup                    TPickGroup,
          @PickType                     TTypeCode,

          @vLPNWarehouse                TWarehouse,
          @ValidPickZone                TZoneId,
          @LPNLocationId                TLocation,
          @LPNLocation                  TLocation,
          @LPNPalletId                  TPallet,
          @LPNSKUId                     TRecordId,
          @LPNSKU                       TSKU,
          @LPNQuantity                  TInteger,
          @LPNDetailId                  TRecordId,
          @vLPNStatus                   TStatus,
          @vLocationId                  TRecordId,
          @vLocAllowedOperations        TFlags,
          @ValidLPN                     TLPN,
          @LPNPickedId                  TRecordId,
          @NextLPNToPick                TLPN,
          @NextLPNIdToPick              TRecordId,
          @NextLocationToPick           TLocation,
          @SKUToPick                    TSKU,
          @UnitsToPick                  TInteger,
          @ValidPickTicket              TPickTicket,
          @OrderId                      TRecordId,
          @OrderStatus                  TStatus,
          @vOrderType                   TTypeCode,
          @PickingPalletId              TRecordId,
          @vPickBatchId                 TRecordId,
          @vPickBatchNo                 TPickBatchNo,
          @vUnitsPerCarton              TQuantity,
          @vValidateUnitsPerCarton      TFlag,
          @vUoM                         TUoM,

          @vIsBatchAllocated            TFlag,
          @vLPNTaskId                   TRecordId,
          @vLPNTaskDetailId             TRecordId,
          @vTaskId                      TRecordId,
          @vTaskDetailId                TRecordId,
          @vTaskLPNId                   TRecordId,
          @vActivityLogId               TRecordId,
          @vIsOrderTasked               TFlag,
          @LPNSKUDesc                   TDescription,
          @vLPNInnerPacks               TInnerPacks,
          @PTForDisplay                 TDescription,
          @vDestDropZone                TZoneId,
          @vDestDropLoc                 TLocation,
          @vBatchType                   TTypeCode,
          @vWarehouse                   TWarehouse,
          @vReasonCodeForLPNShortPick   TControlValue,

          /* @OrderDetailId         TRecordId, */
          @UnitsAuthorizedToShip        TInteger,
          @UnitsAssigned                TInteger,
          @ConfirmLPNMessage            TMessageName,
          @vBusinessUnit                TBusinessUnit,
          @vOnShortPickActions          TControlValue,

          @xmlRulesData                 TXML,
          @vxmlInput                    xml,
          @vTranCount                   TCount,
          @vxmlResult                   xml;

  declare @ReturnCode                   TInteger,
          @MessageName                  TMessageName,
          @CCMessage                    TDescription,
          @Message                      TDescription;

begin /* pr_RFC_Picking_ConfirmLPNPick */
begin try
  SET NOCOUNT ON;
  /* Initialize values here */
  select @vxmlInput  = convert(xml, @xmlInput),
         @vTranCount = @@trancount;

  /* read all values from xml */
  select @DeviceId          = Record.Col.value('DeviceId[1]',                 'TDeviceId'),
         @UserId            = Record.Col.value('UserId[1]',                   'TUserId'),
         @PickTicket        = Record.Col.value('PickTicket[1]',               'TPickTicket'),
         @OrderDetailId     = Record.Col.value('OrderDetailId[1]',            'TRecordId'),
         @PickZone          = nullif(Record.Col.value('PickZone[1]',          'TZoneId'),     ''),
         @LPNPicked         = nullif(Record.Col.value('LPNPicked[1]',         'TLPN'),        ''),
         @LPNPickedLocation = nullif(Record.Col.value('PickedFromLocation[1]','TLocation'),   ''),
         @PickingPallet     = nullif(Record.Col.value('PickingPallet[1]',     'TPallet'),     ''),
         @ShortPick         = nullif(Record.Col.value('ShortPick[1]',         'TFlags'),      ''),
         @TaskId            = nullif(Record.Col.value('TaskId[1]',            'TRecordId'),   ''),
         @TaskDetailId      = nullif(Record.Col.value('TaskDetailId[1]',      'TRecordId'),   ''),
         @DestZone          = nullif(Record.Col.value('DestZone[1]',          'TLookUpCode'), ''),
         @Operation         = nullif(Record.Col.value('Operation[1]',         'TOperation'),  ''),
         @PickGroup         = nullif(Record.Col.value('PickGroup[1]',         'TPickGroup'),  ''),
         @PickType          = nullif(Record.Col.value('PickType[1]',          'TTypeCode'),  '')
  from @vxmlInput.nodes('ConfirmLPNPick') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @UserId, @DeviceId,
                      @TaskId, @LPNPicked, 'TaskId-LPNPicked', @Operation, @PickGroup,
                      @ActivityLogId = @vActivityLogId output;

  if (@@trancount = 0) begin transaction

  /* Verify whether the given PickTicket is valid */
  exec pr_Picking_ValidatePickTicket @PickTicket,
                                     @OrderId         output,
                                     @ValidPickTicket output;

  /* Verify whether the given PickZone is valid, if provided only */
  exec pr_ValidatePickZone @PickZone, @ValidPickZone output;

  /* Verify whether the given LPN is the same as suggested */
  /* Verify whether the given LPN Location is the proper, as per the system */
  /* select LPN Information */
  select @vLPNWarehouse   = L.DestWarehouse,
         @LPNLocationId   = L.LocationId,
         @LPNLocation     = L.Location,
         @LPNPalletId     = L.PalletId,
         @LPNSKUId        = L.SKUId,
         @LPNQuantity     = L.Quantity,
         @ValidLPN        = L.LPN,
         @vUoM            = S.UoM,
         @LPNPickedId     = L.LPNId,
         @vLPNStatus      = L.Status,
         @vBusinessUnit   = L.BusinessUnit
  from LPNs L
    join SKUs S on (L.SKUId = S.SKUId)
  where (L.LPN = @LPNPicked);

  /* Get the scanned location details */
  select @vLocationId           = LocationId,
         @vLocAllowedOperations = AllowedOperations
  from Locations
  where (Location     = @LPNPickedLocation) and
        (BusinessUnit = @vBusinessUnit);

  /* get the Task Info of the picked LPN */
  select @vLPNTaskId       = TD.TaskId,
         @vLPNTaskDetailId = TD.TaskDetailId,
         @vTaskLPNId       = TD.LPNId
  from TaskDetails TD
  join Tasks T on (TD.TaskId = T.TaskId)
  where (TD.TaskId       = @TaskId) and
        (TD.TaskDetailId = @TaskDetailId) and
        (TD.OrderId      = @OrderId) and
        (T.TaskSubType   = 'L' /* LPN */);

  /* temporary fix, some how we do not have  proper orderinfo so we will
    reassign the input taskid if the result is null in above statement */
  select @vLPNTaskId       = coalesce(@vLPNTaskId, @TaskId),
         @vLPNTaskDetailId = coalesce(@vLPNTaskDetailId, @TaskDetailId);

  /* Get the control variable to validate if the LPN Quantity is not equal to the UnitsPerCarton on Order */
  select @vValidateUnitsPerCarton    = dbo.fn_Controls_GetAsBoolean('Picking', 'ValidateUnitsperCarton', 'Y' /* Yes */, @vBusinessUnit, @UserId),
         @vIsOrderTasked             = dbo.fn_Controls_GetAsBoolean('Picking', 'IsOrderTasked', 'Y' /* Yes */, @vBusinessUnit, @UserId),
         @vOnShortPickActions        = dbo.fn_Controls_GetAsString('ShortPick', 'OnShortPick', 'HC' /* Hold and Cycle Count */, @vBusinessUnit, @UserId),
         @vReasonCodeForLPNShortPick = dbo.fn_Controls_GetAsString('ShortPick', 'ReasonCodeForLPNShortPick', '120', @vBusinessUnit, @UserId);

  /* select the Picking Pallet Info */
  select @PickingPalletId = PalletId
  from Pallets
  where (Pallet       = @PickingPallet) and
        (BusinessUnit = @vBusinessUnit);

  /* select the BatchNo on the Order */
  select @vPickBatchNo = PickBatchNo
  from PickBatchDetails
  where (OrderDetailId = @OrderDetailId) and
        (BusinessUnit  = @vBusinessUnit);

  /* Get Batch Info */
  select @vIsBatchAllocated = IsAllocated,
         @vBatchType        = BatchType,
         @vWarehouse        = Warehouse
  from PickBatches
  where (BatchNo      = @vPickBatchNo) and
        (BusinessUnit = @vBusinessUnit);

  /* select UnitsPerCarton on the Order line */
  select @vUnitsPerCarton = UnitsPerCarton
  from OrderDetails
  where (OrderDetailId = @OrderDetailId);

  if (@ShortPick = 'N' /* No */)
    begin
      if (@ValidLPN is null)
        select @MessageName = 'LPNDoesNotExist';
      else
      if (@vValidateUnitsPerCarton = 'Y'/* Yes */) and
         ((@vUoM <> 'PP'/* Prepack */) and (@vUnitsPerCarton <> @LPNQuantity))
        select @MessageName = 'LPNQtyMismatchWithUnitsPerCarton';
    /*
      else
      if (@LPNLocationId <> @LPNPickedLocation)
        set @MessageName = 'LocationDiffFromSuggested';
    */
      else
      /* If location is OnHold and not allowed for Picking then restrict the picking from this location until CC completed */
      if (coalesce(@vLocAllowedOperations, '') <> '') and (charindex('N' /* None - Onhold */, @vLocAllowedOperations) > 0)
        set @MessageName = 'Picking_LocationOnHold';
      else
      if (coalesce(@vLocAllowedOperations, '') <> '') and (charindex('K' /* Picking */, @vLocAllowedOperations) = 0)
        set @MessageName = 'Picking_LocationDoestNotAllow';
      else
      if (@PickingPallet is not null) and (@PickingPalletId is null)
        set @MessageName = 'InvalidPickingPallet';
      else
      if (@LPNPalletId = @PickingPalletId) and (@vLPNStatus = 'K'/* Picked */)
        set @Messagename = 'LPNAlreadyPicked';
      else
      if (@vLPNStatus <> 'A' /* Allocated */) and (@vIsBatchAllocated = 'Y')
        set @MessageName = 'InvalidPickingLPN';
      else
      if (@vTaskLPNId <> @LPNPickedId)
        set @MessageName = 'PickedLPNIsNotASuggestedLPN';

      /* If Error, then return Error Code/Error Message */
      if (@MessageName is not null)
        goto ErrorHandler;

      /* Call ConfirmLPNPick */
      exec pr_Picking_ConfirmLPNPick @OrderId, @OrderDetailId, @LPNPickedId,
                                     @vBusinessUnit, @UserId, @PickingPalletId;

      /* Updating Batch Status if the Order is associated with a Pick Batch */
      if (@vPickBatchNo is not null)
        exec pr_PickBatch_SetStatus @vPickBatchNo, null /* Status */, @UserId, @vPickBatchId output;

      select @ConfirmLPNMessage = dbo.fn_Messages_GetDescription('LPNConfirmSuccessful'),
             @OrderDetailId     = null /* To store next OrderDetailId */;
    end
  else
  if (@ShortPick = 'Y' /* Yes */)
    begin
      /* Update OrderHeaders by setting ShortPick flag to 'Y' if it is ShortPicked */
      update OrderHeaders
      set ShortPick = 'Y' /* Yes */
      where (PickTicket = @ValidPickTicket);

      /* Update LPNs set LPN as Lost and OnHandStatus to UnAvailable as picker did not
         find the LPN in the location. However, do this only if the system thinks the
         LPN should be in the Location - it could be that LPN has been moved since the
         user was directed to the Location, or someone else picked it already

         we need to clear the inventory when short pick based on the control value
         If controlvalue is defined as yes then we need to clear the inventiry from lpn,
         If the controilvalue is defined as No then we need to create ccbatch, we need
         cancel the task as well.

         If LPN has been short picked then we will put that location OnHold, and we cannot allow any operations untill that released.
         On performing the cycle counting we will clear/unallocate the Location and will release the Location as well.*/

      /*  If LPN has been moved since it has been allocated and is not in the Pick From Location
          anymore, then do not mark it as lost */
      if (@LPNLocation = @LPNPickedLocation) and (charindex('L' /* Lost */, @vOnShortPickActions) > 0)
        begin
          exec pr_LPNs_Lost @LPNPickedId, @vReasonCodeForLPNShortPick, @UserId,
                            Default /* Clear Pallet */, 'LPNShortPicked' /* Audit Activity */;
        end

      /* If control var is to unallocate it or could not mark as lost above because LPN was moved, then unallocate */
      if (charindex('U' /* Unallocate */, @vOnShortPickActions) > 0) or
         ((coalesce(@LPNLocation, '') <> @LPNPickedLocation) and (charindex('L' /* Lost */, @vOnShortPickActions) > 0))
        begin
          exec pr_LPNs_Unallocate @LPNPickedId, default, 'Y'/* Yes - Unallocate Pallet */, @vBusinessUnit, @UserId;
        end

      if (charindex('H', @vOnShortPickActions /* On Hold location */) > 0)
        begin
          /* Mark location as OnHold so that we cannot allow any operations on this location. */
          update Locations
          set AllowedOperations = coalesce(AllowedOperations, '') + 'N' /* Onhold */
          where (Location = @LPNPickedLocation);
        end

      select @ConfirmLPNMessage = dbo.fn_Messages_GetDescription('LPNShortPicked'),
             @OrderDetailId     = null /* To store next OrderDetailId */;

      if (charindex('C'/* Create CC */, @vOnShortPickActions) > 0)
        begin
          /* Create a cycle counting task */
          exec @ReturnCode = pr_Locations_CreateCycleCountTask @vLocationId,
                                                              'ShortPick',
                                                               @UserId,
                                                               @vBusinessUnit,
                                                               @CCMessage output;
        end

      if (@ReturnCode > 0)
        begin
          select @Message = @CCMessage;
          goto ErrorHandler;
        end
    end

  /* Update the tasks after the LPN is picked */
  if (@vLPNTaskId is not null)
    begin
      update TaskDetails
      set UnitsCompleted      = @LPNQuantity,
          InnerPacksCompleted = InnerPacks,
          Status              = 'C' /* Completed */
      where (TaskDetailId = @vLPNTaskDetailId) and
            (TaskId       = @vLPNTaskId);

      /* calculate and update the Task Status */
      exec pr_Tasks_SetStatus @vLPNTaskId, @UserId, null, 'Y'/* Yes */;

      /* Update numpicks completed on the pickbatches */
      update PickBatches
      set NumPicksCompleted += 1
      where (BatchNo      = @vPickBatchNo) and
            (BusinessUnit = @vBusinessUnit);
    end

  /* if there are any LPN Pick tasks for the order then suggest the next LPN to pick */
  if (@vIsOrderTasked = 'Y'/* Yes */)
    begin
      if (coalesce(@PickGroup, '') <> '')
        begin
          /* Build the data for evaluation of rules to get pickgroup*/
          select @xmlRulesData = '<RootNode>' +
                                   dbo.fn_XMLNode('Operation', @Operation) +
                                   dbo.fn_XMLNode('PickType',  @PickType)  +
                                 '</RootNode>';

          /* Get the valid pickGroup here to find the task  */
          exec pr_RuleSets_Evaluate 'Task_GetValidTaskPickGroup', @xmlRulesData, @PickGroup output;
        end

      /* Find the next LPN to Pick from existing task or a new task */
      exec pr_Picking_FindNextLPNPickForTaskOrWave @PickGroup, @DestZone, @vWarehouse,
                                                   @DeviceId, @vBusinessUnit, @UserId,
                                                   @vPickBatchNo output, @vTaskId output,
                                                   @vTaskDetailId output, @NextLPNIdToPick output,
                                                   @NextLPNToPick output, @NextLocationToPick output,
                                                   null /* Pickzone */, @SKUToPick output,
                                                   @UnitsToPick output, @OrderId output,
                                                   @OrderDetailId output;
    end
  else /* call FindLPN if order is not tasked */
    begin
      exec pr_Picking_FindLPN @OrderId,
                              @ValidPickZone,
                              'F', /* Full LPN Search */
                              default, /* SKU Id */
                              @NextLPNToPick      output,
                              @NextLPNIdToPick    output,
                              @NextLocationToPick output,
                              @SKUToPick          output,
                              @UnitsToPick        output,
                              @OrderDetailId      output;
    end

  if (@NextLPNToPick is not null)
    begin
      /* On Success, return Order Info, the Details of LPN to Pick */
      /* select LPN Information */
      select @LPNLocationId  = LocationId,
             @LPNLocation    = Location,
             @LPNPalletId    = PalletId,
             @LPNSKUId       = SKUId,
             @LPNQuantity    = Quantity,
             @vLPNInnerPacks = InnerPacks,
             @vPickBatchNo   = PickBatchNo
      from LPNs
      where (LPN = @NextLPNToPick);

      select @LPNSKU     = SKU,
             @LPNSKUDesc = Description
      from SKUs
      where (SKUId = @LPNSKUId);

       /* select PickTicket Information */
      select @ValidPickTicket = PickTicket,
             @OrderId         = OrderId,
             @PTForDisplay    = PickBatchNo + coalesce('/' + @PickTicket, '')
      from OrderHeaders
      where (PickTicket = @PickTicket);

      /* select PickTicket Line Information */
      select @UnitsAuthorizedToShip = UnitsAuthorizedToShip,
             @UnitsAssigned         = UnitsAssigned,
             @vDestDropLoc          = Location
      from OrderDetails
      where (OrderDetailId = @OrderDetailId);

      /* Get the DropZone based on the Drop Location if we have Location but not the zone */
      /* ?? We may need to use Rules for this */
      if (@vDestDropLoc is not null) and (nullif(@vDestDropZone, '') is null)
        select @vDestDropZone = LOC.PutawayZone
        from Locations LOC
        where LOC.Location = @vDestDropLoc;

      /* Get DestLocation, DropLocation -- Below code is obsolete now since we are not using PickBatchRules fro drop Locations */
      --if (@vBatchType not in ('R', 'RU', 'RP' /* Replenishments */))
      --  select top 1 @vDestDropZone = DestZoneDescription,
      --               @vDestDropLoc  = DestLocation
      --  from vwbatchingrules
      --  where (BatchType = @vBatchType) and
      --        (Warehouse = coalesce(@vWarehouse, Warehouse));

      set @vxmlResult = (select @PickTicket        as PickTicket,
                                @OrderId           as OrderId,
                                @OrderDetailId     as OrderDetailId,
                                @UnitsAssigned     as OrderDetailUnitsAssigned,
                                @NextLPNToPick     as LPN,
                                @LPNLocation       as LPNLocation,
                                @LPNPalletId       as LPNPallet,
                                @LPNSKU            as SKU,
                                @LPNSKUDesc        as SKUDescription,
                                @LPNQuantity       as LPNQuantity,
                                convert(varchar(max), (@vLPNInnerPacks)) + ' CS '+ '(' + convert(varchar(max), @UnitsToPick) + ' EA)'
                                                   as QuantityDescription,
                                @vTaskId           as TaskId,
                                @vTaskDetailId     as TaskDetailId,
                                @vPickBatchNo      as PickBatchNo,
                                @PTForDisplay      as DisplayPickTicket,
                                @vDestDropZone     as DestDropZone,
                                @vDestDropLoc      as DestDropLocation,
                                @PickGroup         as PickGroup,

                                0                  as ErrorNumber,
                                @ConfirmLPNMessage as ErrorMessage
                         FOR XML RAW('LPNPICKINFO'), TYPE, ELEMENTS XSINIL, ROOT('LPNPICKDETAILS'));
    end
  else
    begin
      set @vxmlResult =  (select 0                  as ErrorNumber,
                                 @ConfirmLPNMessage as ErrorMessage
                          FOR XML RAW('LPNPICKINFO'), TYPE, ELEMENTS XSINIL, ROOT('LPNPICKDETAILS'));

      /* Find the latest Status of the Order.
         If 'Picked', we need to export picked info to host */
      select @OrderStatus = Status,
             @vOrderType  = OrderType
      from OrderHeaders
      where OrderId = @OrderId;

      if (@OrderStatus = 'P' /* Picked */)
        begin
          exec @ReturnCode = pr_Exports_OrderData 'Pick' /* Picked */,
                                                  @OrderId       = @OrderId,
                                                  @OrderDetailId = null,
                                                  @LoadId        = null,
                                                  @BusinessUnit  = null,
                                                  @UserId        = @UserId;

          /* if the Order is of type Replenish , and the order is completely pciked
             the nwe need to update the pallet is picked */
          if (@vOrderType = 'R' /* Replenish */)
            exec pr_Pallets_SetStatus @PickingPalletId, 'K' /* Picked */, @UserId;
        end
    end

  /* Save Device State */
  /* Update Device Current Operation Details, etc.,. */
  set @xmlResult = convert(varchar(max), @vxmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'ConfirmLPNPick', @xmlResult, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  /* commit the transaction if it was begun above */
  if (@vTranCount = 0) commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML null, @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  exec @ReturnCode = pr_ReRaiseError;

end catch;
  return(coalesce(@ReturnCode /* ReturnCode */, 0));
end /* pr_RFC_Picking_ConfirmLPNPick */

Go
