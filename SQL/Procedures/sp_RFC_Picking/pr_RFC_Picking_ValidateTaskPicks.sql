/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/06  RBV     pr_RFC_Picking_ValidateTaskPicks: Displayed the Correct message Description, while validating the Scan Invalid Tote at the time of Confirm Picks (CID-673)
  2019/06/10  RIA     pr_RFC_Picking_ValidateTaskPicks: Return additional info to show in V3 RF Confirm PickTasks (CID-518)
  2019/06/06  VS      pr_RFC_Picking_ValidateTaskPicks: Made changes to show only Outstanding Picks (CID-519)
  2018/04/30  OK      pr_RFC_Picking_ValidateTaskPicks: included OnHold status for Tasks to restrict the confirming picks (S2G-Support)
  2018/02/19  TD      pr_RFC_Picking_ValidateTaskPicks:Changes to suggest picks based on the pickgroup - S2G- 218
  2017/10/10  CK      pr_RFC_Picking_ValidateTaskPicks: Removed CONCAT command since SQL 2008 doesn't support it (HPI-1060)
  2017/05/12  CK      pr_RFC_Picking_ValidateTaskPicks: Shown pick from as either LPN or Location while pick from picklane location (HPI-1060)
  2017/04/12  TK      pr_RFC_Picking_ValidateTaskPicks, pr_RFC_Picking_ConfirmBatchPick & pr_RFC_Picking_ConfirmBatchPick_2
  2017/03/15  CK      pr_RFC_Picking_ValidateTaskPicks: Combined PickfromLocation and pickfrom LPN display in PickFrom (HPI-1060)
  2017/01/25  TK      pr_RFC_Picking_ValidateTaskPicks: Consider TempLabelDetailId instead of OrderDetailId as we may have issues with Temp Label details not voiding properly (HPI-1274)
  2016/11/09  OK      pr_RFC_Picking_ValidateTaskPicks, pr_RFC_Picking_ConfirmTaskPicks: Added (HPI-1008)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_ValidateTaskPicks') is not null
  drop Procedure pr_RFC_Picking_ValidateTaskPicks;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_ValidateTaskPicks:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_ValidateTaskPicks
  (@xmlInput             xml,
   @xmlResult            xml  output)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vRecordId             TRecordId,
          /* Input params */
          @ToLPN                 TLPN,
          @FromLPN               TLPN,
          @TaskId                TRecordId,
          @PickTicket            TPickTicket,
          @DropLocation          TLocation,
          @Operation             TOperation,
          @PickType              TTypeCode,
          @DeviceId              TDeviceId,
          @UserId                TUserId,
          @BusinessUnit          TBusinessUnit,

          /* Local vars */
          @vToLPNId              TRecordId,
          @vToLPN                TLPN,
          @vToLPNStatus          TStatus,
          @vToLPNTaskId          TRecordId,
          @vToLPNOrderId         TRecordId,
          @vToLPNPickTicket      TPickTicket,

          @vFromLPNId            TRecordId,
          @vToLPNQuantity        TQuantity,
          @vTaskStatus           TStatus,
          @vDependencyFlag       TFlags,
          @vOrderId              TRecordId,
          @vOrderStatus          TStatus,
          @vShipToId             TShipToId,
          @vShipToName           TName,
          @vShipToCSZ            TCityStateZip,
          @vWaveType             TTypeCode,
          @vWaveNo               TWaveNo,
          @vLocationId           TRecordId,
          @vDropLocationId       TRecordId,
          @vInvalidLPNStatuses   TControlValue,
          @vValidLPNStatuses     TControlValue,
          @vUnitsRemainingToPick TQuantity,

          @vTaskId               TRecordId,
          @vPickGroup            TPickGroup,
          @vActivityLogId        TRecordId,

          @xmlRulesData          TXML,

          @vTaskPickHeaderInfo   xml,
          @vTaskPickDetailsInfo  xml;

  declare @ttLPNContents table (RecordId         TRecordId  identity (1,1),
                                SKU              TSKU,
                                Description      TDescription,
                                Quantity         TQuantity,
                                TaskDetailId     TRecordId,
                                PickFrom         TLocation);

  /* As per RF Design we should use FOR XML AUTO in order to convert XML to objext in RF but to use this we should have atleaset one table.
     though there is one record we re using temptable to use FOR XML AUTO */
  declare @ttLPNInfo table (RecordId      TRecordId  identity (1,1),
                            ToLPN         TLPN,
                            LPNQuantity   TQuantity,
                            PickTicket    TPickTicket,
                            ShipTo        TVarchar,
                            TaskId        TRecordId);
begin
begin try
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Fetch details from tables/views */
  if (@xmlInput is not null)
    begin
      /* We are supposed to validate same things on confirming task picks as there might be chance to change the things
         in between scanning and confirming task picks.
         This should be able to read the data from XML which is sent to confirm Pick Task Procedure */
      if (@xmlInput.exist('/ConfirmTaskPickInfo/TaskPickHeaderInfoDto/TaskPickHeaderInfo') = 1)
        select @ToLPN                = Record.Col.value('ToLPN[1]',        'TLPN'),
               @FromLPN              = Record.Col.value('FromLPN[1]',      'TLPN'), --Future use
               @TaskId               = nullif(Record.Col.value('TaskId[1]',       'TRecordId'), 0),
               @PickTicket           = Record.Col.value('PickTicket[1]',   'TPickTicket'),
               @DropLocation         = Record.Col.value('DropLocation[1]', 'TLocation'),
               @Operation            = Record.Col.value('Operation[1]',    'TOperation'),
               @PickType             = Record.Col.value('PickType[1]',     'TTypeCode'),
               @DeviceId             = Record.Col.value('DeviceId[1]',     'TDeviceId'),
               @UserId               = Record.Col.value('UserId[1]',       'TUserId'),
               @BusinessUnit         = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit')
          from @xmlInput.nodes('ConfirmTaskPickInfo/TaskPickHeaderInfoDto/TaskPickHeaderInfo') as Record(Col);
      else
        select @ToLPN                = Record.Col.value('ToLPN[1]',        'TLPN'),
               @FromLPN              = Record.Col.value('FromLPN[1]',      'TLPN'), --Future use
               @TaskId               = nullif(Record.Col.value('TaskId[1]',       'TRecordId'), 0),
               @PickTicket           = Record.Col.value('PickTicket[1]',   'TPickTicket'),
               @DropLocation         = Record.Col.value('DropLocation[1]', 'TLocation'),
               @Operation            = Record.Col.value('Operation[1]',    'TOperation'),
               @PickType             = Record.Col.value('PickType[1]',     'TTypeCode'),
               @DeviceId             = Record.Col.value('DeviceId[1]',     'TDeviceId'),
               @UserId               = Record.Col.value('UserId[1]',       'TUserId'),
               @BusinessUnit         = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit')
        from @xmlInput.nodes('ValidateTaskPick') as Record(Col);
    end

  /* Add to RF Log */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @TaskId, @PickTicket, 'TaskId-PickTicket',
                      @Value1 = @ToLPN, @Value2 = @FromLPN, @Value3 = @DropLocation,
                      @ActivityLogId = @vActivityLogId output;

  /* Get the Invalid LPN Statuses for TaskPick from control var */
  select @vInvalidLPNStatuses = dbo.fn_Controls_GetAsBoolean('ConfirmTaskPick', 'InvalidLPNStatuses', 'UKGDELVO', @BusinessUnit, @UserId),
         @vValidLPNStatuses   = dbo.fn_Controls_GetAsBoolean('ConfirmTaskPick', 'ValidLPNStatuses', 'FN'/* New Temp, New (cart position)) */, @BusinessUnit, @UserId);

  /* Fetch the TempLabel/ShipCarton Details details */
  select @vToLPNId         = LPNId,
         @vToLPN           = LPN,
         @vToLPNStatus     = Status,
         @vToLPNQuantity   = Quantity,
         @vToLPNOrderId    = OrderId,
         @vToLPNPickTicket = PickTicket,
         @vToLPNTaskId     = TaskId  -- Our assumption is TempLabel should have only one task  , don't make assumptions, verify
  from vwLPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@ToLPN, @BusinessUnit, 'ILTU' /* Options */));

  /* Build the data for evaluation of rules to get pickgroup */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Operation',  @Operation) +
                           dbo.fn_XMLNode('PickType',   @PickType));

  /* Get the valid PickGroup here to find the task  */
  exec pr_RuleSets_Evaluate 'Task_GetValidTaskPickGroup', @xmlRulesData, @vPickGroup output;

  /* Get the Task Details. If TaskId is not given by user, use the task from scanned ToLPN */
  select @vTaskStatus     = Status,
         @vWaveType       = WaveType,
         @vWaveNo         = WaveNo,
         @vDependencyFlag = DependencyFlags,
         @vTaskId         = TaskId
  from vwTasks
  where (TaskId = coalesce(@TaskId, @vToLPNTaskId)) and
        (PickGroup like coalesce(@vPickGroup, PickGroup) + '%');

  select @vOrderStatus  = Status
  from OrderHeaders
  where (OrderId = @vToLPNOrderId);

  select @vDropLocationId = LocationId
  from Locations
  where (Location     = @DropLocation) and
        (BusinessUnit = @BusinessUnit);

  /* Validations */
  if (@vTaskId is null)
    set @vMessageName = 'ConfirmTaskPicks_InValidTaskId';
  else
  if (coalesce(@ToLPN, '') = '')
    set @vMessageName = 'ConfirmTaskPicks_ToLPNRequired';
  else
  if (@vToLPNId is null)
    set @vMessageName = 'ConfirmTaskPicks_InvalidToLPN';
  else
  /* As of now we are just considering LPN status for PickToShip waves. In Future we will enhace this to use other type waves
     Then we should consider LPNDetail OnHandStatus too */
  if (@vToLPNStatus = 'S')  /* Shipped*/
    set @vMessageName = 'ConfirmTaskPicks_ToLPNAlreadyShipped';
  else
  if (@vToLPNStatus in ('K', 'D', 'E', 'L' /* Picked, packed, staged, loaded */))
    set @vMessageName = 'ConfirmTaskPicks_ToLPNAlreadyPicked';
  else
  if (@vToLPNStatus in ( 'C', 'V', 'O'/* Consumed, Voided, Lost */))
    set @vMessageName = 'ConfirmTaskPicks_ToLPNInvalidStatus';
  else
  if ((charindex(@vToLPNStatus, @vValidLPNStatuses) = 0) or (@vToLPNOrderId is null))
    set @vMessageName = 'ConfirmTaskPicks_InValidToLPNStatus'; -- Need to give Proper messagename
  else
  if (charindex(@vToLPNStatus, @vInvalidLPNStatuses) > 0 /* Picked to Shipped, Voided, Lost... */)
    set @vMessageName = 'ConfirmTaskPicks_InValidToLPNStatus';
  else
  if (coalesce(@PickTicket, '' ) <> '') and (@PickTicket <> @vToLPNPickTicket)
    set @vMessageName = 'ConfirmTaskPicks_LPNPTMismatch';
  else
  if (exists (select * from TaskDetails where TaskId = @vToLPNTaskId and TempLabelId = @vToLPNId and status = 'I' /* InProgress */))
    set @vMessageName = 'ConfirmTaskPicks_TaskHasAlreadyStarted';
  else
  if (@vTaskStatus in ( 'C', 'X', 'O'/* Completed, Cancelled, OnHold */))
    set @vMessageName = 'ConfirmTaskPicks_InvalidTaskStatus';
  else
  if (@vOrderStatus in ('S', 'X' /* Shipped, Cancelled */))
    set @vMessageName = 'ConfirmTaskPicks_OrderShippedOrCancelled';
  else
  /* Validating whether User has permissions to do Task Picks. */
  if (dbo.fn_Permissions_IsAllowed(@UserId, 'RFConfirmTaskPicks') <> '1' /* 1 - True, 0 - False */)
    select @vMessageName = 'ConfirmTaskPicks_UserDoesNotHavePermissions';
  else
  if (coalesce(@vDependencyFlag, '') = 'R' /* Replenishment */)
    select @vMessageName = 'ConfirmTaskPicks_InventoryIsDependentOnReplenish';

/* Lot more validations required
Pending Things:
all these validations have to be done on confirm again as things could change between scan and confirmation...

*/

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Get the ShipTo details */
  select @vShipToName = Name,
         @vShipToCSZ  = CityStateZip
  from fn_Contacts_GetShipToAddress(@vToLPNOrderId, null /* ShipToId, function will fetch it */);

  /* Build the LPN contents to show to user in the grid before confirming the picks */
   insert into @ttLPNContents (SKU, Description, Quantity, TaskDetailId, PickFrom)
    select S.SKU ,S.Description, TD.UnitsToPick, TD.TaskDetailId,
    case when (Loc.LocationType = 'K') then Loc.Location
         else (Loc.Location + '/' + L.LPN) end
    from LPNDetails LD
                 join SKUs        S   on (S.SKUId = LD.SKUId)
                 join TaskDetails TD  on (TD.TempLabelId       = LD.LPNId        ) and
                                         (TD.TempLabelDetailId = LD.LPNDetailId  ) and
                                         (TD.OrderDetailId     = LD.OrderDetailId)
      left outer join Locations   Loc on (Loc.LocationId = TD.LocationId)
      left outer join LPNs        L   on (L.LPNId = TD.LPNId)
    where (LD.LPNId = @vToLPNId) and (TD.Status not in ('C', 'X'));

  /* Compute the total units remaining to pick */
  select @vUnitsRemainingToPick = sum(Quantity)
  from @ttLPNContents;

  /* convert LPN contents to XML */
  select @vTaskPickDetailsInfo = (select * -- SKU, Description, Quantity, TaskDetailId
                                 from @ttLPNContents
                                 FOR XML AUTO, ELEMENTS XSINIL, ROOT('TaskPickDetailsInfoDto'));

  /* Build XML of LPN info to display to user for verification before confirming */
  select @vTaskPickHeaderInfo = (select @vToLPN                 ToLPN,
                                        @vUnitsRemainingToPick  LPNQuantity,
                                        @vToLPNPickTicket       PickTicket,
                                        @vShipToCSZ             ShipTo,
                                        @vToLPNTaskId           TaskId,
                                        @vUnitsRemainingToPick  UnitsRemainingToPick, -- for V3, we will use correct field names
                                        @vShipToName            ShipToName,
                                        @vShipToCSZ             ShipToCityStateZip,
                                        @vWaveType              WaveType,
                                        @vWaveNo                WaveNo
                                 from BusinessUnits
                                 FOR XML AUTO, ELEMENTS XSINIL, ROOT('TaskPickHeaderInfoDto'));

  select @XmlResult = convert(Xml, '<ConfirmTaskPickInfo>'                +
                      convert(nvarchar(max), coalesce(@vTaskPickHeaderInfo , '')) +
                      convert(nvarchar(max), coalesce(@vTaskPickDetailsInfo, '')) +
                      '</ConfirmTaskPickInfo>');

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

end try
begin catch

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_ValidateTaskPicks */

Go
