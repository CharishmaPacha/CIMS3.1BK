/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_CC_ConfirmLocationCC') is not null
  drop Procedure pr_RFC_CC_ConfirmLocationCC;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_CC_ConfirmLocationCC: This procedure will evaluate the counting level of CC based on the Qty scanned
       and user permissions.
       1. If user doesn't have permissions for supervisor counts:
          a.If user scanned right qty then we will confirm the Location and display the confirmation message. in case of directed cc then we will suggest the next pick.
          b.If user scanned wrong qty then we will upgrade the CC to supervisor counts and send proper message to user. in case of directed CC we will upgrade the CC and suggest next pick.
       2. If user has permissions for supervisor counts:
          a.If user scanned the right qty then we will confirm the counts. in case of directed CC we will suggest the next pick.
          b.If user scanned wrong qty then we will suggest the same pick, and hence RF will take care if navigating screen to take further level counts.
       3. If UpgradeCCLevelForAnyUser is set to Yes then we will allow user to CC location next location even user doesn't have permissions for supervisor counts
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_CC_ConfirmLocationCC
  (@xmlInput         xml,
   @xmlResult        xml  output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vMessage                TDescription,

          @vLocation               TLocation,
          @vLocationId             TRecordId,
          @vLocationType           TTypeCode,
          @vStorageType            TTypeCode,
          @vNumPallets             TCount,
          @vNumLPNs                TCount,
          @vNumInnerPacks          TCount,
          @vNumUnits               TCount,

          @vSubTaskType            TFlag,
          @vBatchNo                TTaskBatchNo,
          @vTaskId                 TRecordId,
          @vTaskDetailId           TRecordId,

          @vConfirmedPalletsCount  TCount,
          @vConfirmedLPNsCount     TCount,
          @vConfirmedIPsCount      TCount,
          @vConfirmedUnitsCount    TCount,
          @vRequestedCCLevel       TTypeCode,
          @vSupervisorTaskCreated  TRecordId,

          @vControlCategory        TCategory,
          @vValidEntityToConfirmCC TControlValue,
          @vDisplayCCEntityMode    TControlValue, --Future Use
          @vAllowSupervisorCount   TControlValue,
          @vUpgradeCCLevelForUser  TControlValue,
          @vTransaction            TDescription,
          @xmlResultvar            TXML,

          @vBusinessUnit           TBusinessUnit,
          @vUserId                 TUserId,
          @vDeviceId               TDeviceId,
          @vActivityLogId          TRecordId;
begin
begin try
  SET NOCOUNT ON;

  /* fetch Location and LocationId from XML and store it in variable @vLocation and @vLocationId */
  select @vLocation              = Record.Col.value('Location[1]',          'TLocation'),
         @vConfirmedPalletsCount = Record.Col.value('NumPallets[1]',        'TCount'),
         @vConfirmedLPNsCount    = Record.Col.value('NumLPNs[1]',           'TCount'),
         @vConfirmedIPsCount     = Record.Col.value('NumInnerPacks[1]',     'TCount'),
         @vConfirmedUnitsCount   = Record.Col.value('NumEaches[1]',         'TCount'),
         @vSubTaskType           = Record.Col.value('SubTaskType[1]',       'TFlag'),
         @vBatchNo               = Record.Col.value('BatchNo[1]',           'TTaskBatchNo'),
         @vTaskId                = Record.Col.value('TaskId[1]',            'TRecordId'),
         @vTaskDetailId          = Record.Col.value('TaskDetailId[1]',      'TRecordId'),
         @vRequestedCCLevel      = Record.Col.value('RequestedCCLevel[1]',  'TTypeCode'),
         @vUserId                = Record.Col.value('UserId[1]',            'TUserId'),
         @vDeviceId              = Record.Col.value('DeviceId[1]',          'TDeviceId'),
         @vBusinessUnit          = Record.Col.value('BusinessUnit[1]',      'TBusinessUnit')
  from @xmlInput.nodes('CONFIRMCYCLECOUNTDETAILS') as Record(Col)

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      @vTaskDetailId, @vLocation, 'TaskDetailId-Location',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get the Location info */
  select @vLocationId = LocationId,
         @vLocation = Location,
         @vLocationType = LocationType,
         @vStorageType = StorageType,
         @vNumPallets = NumPallets,
         @vNumLPNs = NumLPNs,
         @vNumInnerPacks = InnerPacks,
         @vNumUnits = Quantity
  from Locations
  where (Location     = @vLocation) and
        (BusinessUnit = @vBusinessUnit);

  /* Get the task info */
  if (@vTaskDetailId is null) and (@vTaskId is not null)
    select @vTaskDetailId     = TaskDetailId,
           @vRequestedCCLevel = RequestedCCLevel
    from TaskDetails
    where (TaskId     = @vTaskId) and
          (LocationId = @vLocationId);

  select @vControlCategory = 'CycleCount_' + @vLocationType + @vStorageType;

  select @vValidEntityToConfirmCC = dbo.fn_Controls_GetAsString(@vControlCategory, 'ValidEntityToConfirmCC', 'I' /* IPs */, @vBusinessUnit, @vUserId),
         @vDisplayCCEntityMode    = dbo.fn_Controls_GetAsString(@vControlCategory, 'DisplayCCEntityMode', 'I' /* IPs */, @vBusinessUnit, @vUserId),
         @vAllowSupervisorCount   = case when dbo.fn_Permissions_IsAllowed(@vUserId, 'AllowCycleCount_L2') = '1' then 'Y' else 'N' end,
         @vUpgradeCCLevelForUser  = dbo.fn_Controls_GetAsString(@vControlCategory, 'UpgradeCCLevelForUser', 'N' /* No */, @vBusinessUnit, @vUserId);

  /* Verify the scanned qty based on valid Entity to confirm*/
  if ((charindex('P' /* Pallets */,    @vValidEntityToConfirmCC) > 0) and (@vNumPallets    = @vConfirmedPalletsCount)) or
     ((charindex('L' /* LPNs */,       @vValidEntityToConfirmCC) > 0) and (@vNumLPNs       = @vConfirmedLPNsCount))    or
     ((charindex('I' /* InnerPacks */, @vValidEntityToConfirmCC) > 0) and (@vNumInnerPacks = @vConfirmedIPsCount))     or
     ((charindex('U' /* Units */,    @vValidEntityToConfirmCC) > 0) and (@vNumUnits      = @vConfirmedUnitsCount))
    begin
      /* If user scanned correct count then complete the Location CC. If user doing directed CC then below procedure will take care
         of suggesting next pick */
      exec pr_RFC_CC_CompleteLocationCC @xmlInput, @xmlResult output;
    end
  else
    begin
      /* If user doesn't have permissions for Supervisor counts and UpgradeCCLevelForAnyUser is set to No then create the Supervisor count
           and suggest next location in case of Directed CC */
      if (@vAllowSupervisorCount = 'N' /* No */) and (@vUpgradeCCLevelForUser = 'N' /* No */)
        begin
          /* If user doesn't have permissions for Supervisor counts then upgrade the count to supervisor count */
          exec pr_CycleCount_UpgradeToSupervisorCount @vTaskId, @vLocationId, @vUserId, @vBusinessUnit, @vSupervisorTaskCreated output;

          /* Call 'pr_CycleCount_FindNextLocFromBatch' in case of directed CycleCount */
          if (@vSubTaskType = 'D' /* Directed */)
            begin
              exec pr_CycleCount_GetNextLocFromBatch @vBatchNo,
                                                     @vUserId,
                                                     @vLocation     output,
                                                     @vTaskDetailId output;


              /* Call pr_RFC_CC_StartLocationCC with returned Location
                 - which return all the details of the Location fetched as @xmlResult */
              if (@vLocation is not null)
                exec pr_RFC_CC_StartLocationCC @vLocation,
                                               @vTaskDetailId,
                                               @vBusinessUnit,
                                               @vUserId,
                                               @vDeviceId,
                                               @xmlResult  output;
              else
                begin
                  /* XmlMessage to RF, after Location is Cycle Counted */
                  exec pr_BuildRFSuccessXML 'CCBatchCompletedSuccessfully' /* @MessageName */, @xmlResult output, @vLocation;
                end
            end
          else
            /* If Supervisor count task is created then display the proper message to user */
            exec pr_BuildRFSuccessXML 'CC_SupervisorTaskCreated' /* @MessageName */, @xmlResult output, @vLocation;
        end
      else
        begin
          /* If Supervisor doing CC and scanned wrong counts or if it is user and CCLevel can be upgraded,
             then allow user to scan next level i,e all Pallets/LPNs.
             Hence send the same Location details to RF */
          exec @vReturnCode = pr_RFC_CC_StartLocationCC @vLocation,
                                                        @vTaskDetailId,
                                                        @vBusinessUnit,
                                                        @vUserId,
                                                        @vDeviceId,
                                                        @xmlResult  output;
        end
    end

  /* Update Devices table with transaction detail */
  set @xmlResultvar = convert(varchar(max), @xmlResult)
  exec pr_Device_Update @vDeviceId, @vUserId, @vTransaction, @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Mark the end of the transaction */
  exec pr_RFLog_End @xmlResultvar /* xmlResult */, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;
  exec @vReturnCode = pr_BuildRFErrorXML @xmlResult output;

  /* Mark the end of the transaction */
  exec pr_RFLog_End @xmlResult /* xmlResult */, @@ProcId, @ActivityLogId = @vActivityLogId output;

end catch;

  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_CC_ConfirmLocationCC */

Go
