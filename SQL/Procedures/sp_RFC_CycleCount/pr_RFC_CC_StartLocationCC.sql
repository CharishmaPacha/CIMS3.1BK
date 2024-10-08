/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/10  OK      pr_RFC_CC_StartLocationCC: Bug fix to send the TaskDetailId to RF for InProgress tasks (HA-2238)
  2021/03/08  RIA     pr_RFC_CC_StartLocationCC: Changes to validate only Static Picklanes (HA-2199)
  2021/02/16  RIA     pr_RFC_CC_StartLocationCC: Changes to add InventoryClass to SKUDesc (HA-1994)
  2021/02/03  PK      pr_RFC_CC_StartLocationCC: Added LocationBarcode in outputxml to consider in RF (HA-1971)
  2021/01/07  SK      pr_RFC_CC_StartLocationCC: Consider Task sub type to fetch existing CC tasks (HA-1892)
  2021/01/05  SK      pr_RFC_CC_StartLocationCC: realignment (HA-1841)
  2020/11/11  SK      pr_RFC_CC_StartLocationCC: Introduce flag for blind or default CC,
                      Also added Display SKU field to the data set (HA-1567)
  2020/08/31  AY      pr_RFC_CC_StartLocationCC, pr_RFC_CC_CompleteLocationCC: Several fixes to update tasks (CIMSV3-1064)
  2020/08/22  RIA     pr_RFC_CC_StartLocationCC: Added SKU Descriptions in output for Picklane CC (CIMSV3-773)
  2020/07/11  SK      pr_RFC_CC_StartLocationCC: Adding more data when CC Pallet storage type Location (HA-1077)
  2018/03/08  OK      pr_RFC_CC_CompleteLocationCC, pr_RFC_CC_StartLocationCC: Enhanced to complete the open cycle count task if user did Non directed CC and Location has any open task (S2G-335)
  2018/03/06  OK      pr_RFC_CC_StartLocationCC: Changes to bypass the validation even SKU is not yet setup for the next suggested Picklane location for Directed CC (S2G-333)
  2016/08/18  SV      pr_RFC_CC_StartDirectedLocCC, pr_RFC_CC_StartLocationCC: Changes to show the actual error message which occured in internal procedure call
                      pr_RFC_CC_ValidateEntity: Added validation when entering the SKU instead of Location (HPI-453)
  2016/03/02  TK      pr_RFC_CC_StartLocationCC: Allow CC Staging Locations based upon control variable (FB-599)
  2015/10/30  TK      pr_RFC_CC_StartLocationCC & pr_RFC_CC_ValidateEntity: Enhanced to allow user enter Cases,
                        Inner Packs and Units(ACME-379)
  2015/10/06  TK      pr_RFC_CC_StartLocationCC: Added Validations to check PickingZone on the scanned Location(ACME-363)
  2015/08/10  RV      pr_RFC_CC_StartLocationCC: Get Location Default UOM from control variable (FB-296).
  2015/05/05  OK      pr_RFC_CC_StartLocationCC,pr_RFC_CC_ValidateEntity: Made system compatable to accept either Location or Barcode
  2014/05/19  TD      pr_RFC_CC_StartLocationCC:Changes to pass UoMEnabled.
  2012/09/06  PK      pr_RFC_CC_StartLocationCC: Fetching the InProgress task details as well.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_CC_StartLocationCC') is not null
  drop Procedure pr_RFC_CC_StartLocationCC;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_CC_StartLocationCC:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_CC_StartLocationCC
  (@Location           TLocation,
   @TaskDetailId       TRecordId,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @DeviceId           TDeviceId,
   @xmlResult          xml       output)
as
  declare @ReturnCode            TInteger,
          @MessageName           TMessageName,
          @Message               TDescription,
          @vControlCategory      TCategory,
          @AllowStagingLoctionsToCC
                                 TControlValue,
          /* Task info */
          @vTaskId               TRecordId,
          @vTaskSubType          TTypeCode,
          @vBatchNo              TTaskBatchNo,

          /* Loc info */
          @vPickZone             TZoneId,
          @vLocationId           TRecordId,
          @vLocation             TLocation,
          @vLocationType         TTypeCode,
          @vLocationStatus       TStatus,
          @vLocationStorageType  TLookUpCode,
          @vLocationSubType      TTypeCode,
          @vLocationBarcode      TBarcode,
          @vLocPickZone          TLookUpCode,
          @vNumLPNs              TCount,
          @vNumSKUs              TCount,
          @vNumPallets           TCount,
          @vLPNType              TTypeCode,
          @vNumUnits             TCount,
          @vNumInnerPacks        TQuantity,

          @vConfirmLPNContents   TDescription,
          @vScanPalletLPNs       TFlag,
          /* CC Options */
          @vDefaultQty           TControlValue,
          @vQtyEnabled           TControlValue,
          @vSKUPrompt            TControlValue,
          @vScanSKU              TControlValue,
          @vAllowEntity          TFlag,
          @vUoMEnabled           TControlValue,
          @vConfirmQtyMode       TControlValue,
          @vLocationDefaultUOM   TUoM,

          @vRequestedCCLevel     TTypeCode,
          @vInputQtyPrompt       TControlValue,
          @vDisplayCCEntityMode  TControlValue,
          @xmlLocationInfo       varchar(max),
          @xmlLocationDetails    varchar(max),
          @xmlOptions            varchar(max),
          @xmlInput              xml,
          @xmlResultvar          varchar(max),
          @vActivityLogId        TRecordId;

          /* Variables will be declared here */
begin
begin try
  SET NOCOUNT ON;

  /* If the TaskDetailId from the caller is 0 then make the parameter as null */
  select @TaskDetailId = nullif(@TaskDetailId, 0);

  /* 1. Get Location Info
     2. Validate Location
     3. Get Location Contents
     4. Get Options from Controls
     5. Build XML and return   */

  set @xmlInput = (select @Location        as Location,
                          @TaskDetailId    as TaskDetailId,
                          @BusinessUnit    as BusinessUnit,
                          @DeviceId        as DeviceId,
                          @UserId          as UserId
                   for XML raw('CC_StartLocationCount'), type, elements);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @TaskDetailId, @Location, 'TaskDetailId-Location',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  select @AllowStagingLoctionsToCC = dbo.fn_Controls_GetAsBoolean('CycleCount', 'AllowStagingLocations', 'N' /* No */,
                                                                  @BusinessUnit, @UserId);

  /* If user has privilege to do supervisor count then we can assign any task otherwise we can only assign user tasks */
  select @vTaskSubType     = case
                               when dbo.fn_Permissions_IsAllowed(@UserId, 'AllowCycleCount_L2') <> 1 then 'L1'
                               else null
                             end;

  /* 1. Get Locations Info */
  select @vLocationId          = LocationId,
         @vLocation            = Location,
         @vLocationType        = case when LocationType in ('S'/* Staging */, 'D'/* Dock */) and (@AllowStagingLoctionsToCC = 'Y'/* Yes */)
                                        then 'R'/* Reserve */
                                      else LocationType
                                 end,
         @vLocationStorageType = StorageType,
         @vLocationSubType     = LocationSubType,
         @vLocationStatus      = Status,
         @vLocationBarcode     = Barcode,
         @vNumPallets          = NumPallets,
         @vNumLPNs             = NumLPNs,
         @vNumUnits            = Quantity,
         @vNumInnerPacks       = InnerPacks,
         @vLocPickZone         = nullif(PickingZone, '')
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @Location, @DeviceId, @UserId, @BusinessUnit));

  /* Get the Location Default UOM from Control Values */
  select @vLocationDefaultUOM = dbo.fn_Controls_GetAsString('Location_UoM_' + @vLocationStorageType, 'LocationDefaultUOM', 'EA' /* Eaches */,
                                                            @BusinessUnit, @UserId)

  /* Get total lpns in scanned location */
  select @vNumLPNs = count(*)
  from LPNs
  where (LocationId = @vLocationId);

  /* 2. Validations */
  if (@vLocationId is null)
    select @MessageName = 'LocationDoesNotExist'
  else
  if (@vLocationStatus = 'I' /* Inactive */)
    select @MessageName = 'LocationIsInactive'
  else
  if (@vLocPickZone is null)
    select @MessageName = 'CC_PickZoneNotConfigured';
  else
  if (@vLocPickZone is not null) and (not exists(select *
                                                 from vwPickingZones
                                                 where (ZoneId = @vLocPickZone) and
                                                       (Status = 'A'/* Active */)))
    select @MessageName = 'CC_PickZoneIsInvalid';
  else
  if (@vLocationType not in ('K' /* Picklane */, 'R' /* Reserve */, 'B' /* Bulk */))
    set @MessageName = 'CycleCountInvalidLocationType';
  else
  /* For directed cycle count, bypass the below validation and suggest the next picklane location that has SKU setup */
  if (coalesce(@TaskDetailId, 0) = 0) and (@vLocationType = 'K' /* picklane */) and (@vLocationSubType = 'S') and (@vNumLPNs = 0)
    set @MessageName = 'CC_LocationNotAssignedAnySKU'

  if (@MessageName is not null)
      goto ErrorHandler;

   /* If it is directed cycle count, then get the details of the task/task details
      if any of the task details (Inprogress) are already started by the User */
  select @vTaskId               = TaskId,
         @TaskDetailId          = TaskDetailId, --Need to change this to local varialble
         @vBatchNo              = BatchNo,
         @vPickZone             = PickZone,
         @vRequestedCCLevel     = RequestedCCLevel
  from vwTaskDetails
  where (LocationId   = @vLocationId) and
        (TaskType     = 'CC' /* Cycle Count */) and
        (TaskDetailId = coalesce(@TaskDetailId, TaskDetailId)) and
        (BusinessUnit = @BusinessUnit) and
        (ModifiedBy   = @UserId) and
        (Status in ('I' /* InProgress */));

  /* If taskId is null and TaskDetailId is not null, then find the tasksdetails
     which are not in Inprogress Status */
  if (@vTaskId is null) and (@TaskDetailId is not null)
    select @vTaskId               = TaskId,
           @vBatchNo              = BatchNo,
           @vPickZone             = PickZone,
           @vRequestedCCLevel     = RequestedCCLevel
    from vwTaskDetails
    where (LocationId   = @vLocationId) and
          (TaskType     = 'CC' /* Cycle Count */) and
          (TaskDetailId = coalesce(@TaskDetailId, TaskDetailId)) and
          (BusinessUnit = @BusinessUnit) and
          (Status in ('N' /* Not yet started */));

  /* In case of Non-Directed cycle count, if there is any cc tasks are open for the Location, then complete that task */
  if (@vTaskId is null) and (@TaskDetailId is null)
    select @vTaskId               = TaskId,
           @TaskDetailId          = TaskDetailId,
           @vBatchNo              = BatchNo,
           @vPickZone             = PickZone,
           @vRequestedCCLevel     = RequestedCCLevel
    from vwTaskDetails
    where (LocationId   = @vLocationId) and
          (TaskType     = 'CC' /* Cycle Count */) and
          --(TaskSubType  = coalesce(@vTaskSubType, TaskSubType)) and
          (BusinessUnit = @BusinessUnit) and
          (Status       = 'N') /* Not yet started */
    order by TaskSubType desc;  --If user has privilege to do supervisor counts then suggest the supervisor task first

  /* If No tasks found and sent then create one */
  if (@vTaskId is null)
    exec pr_CycleCount_CreateTaskForNonDirectedCount @vLocationId, @vLocation, @vPickZone,
                                                     @BusinessUnit, @UserId,
                                                     @vTaskId output, @TaskDetailId output, @vRequestedCCLevel output;

  /* Update status of Task Detail & Task */
  update TaskDetails
  set Status     = 'I' /* In progress */,
      ModifiedBy = @UserId
  where (TaskDetailId = @TaskDetailId);

  exec pr_Tasks_SetStatus @vTaskId, @UserId, @Recount = 'Y';

  select @vControlCategory = 'CycleCount_' + @vLocationType + @vLocationStorageType;

  /* Fetching ControlValues as string and storing it in another xml variable 'xmlOptions' */
  /* Default Quantity    : The quantity to be shown by default on the RF Screen.
                           Possible values are 1 (when each unit would be scanned) or
                           ''/blank (when user is expected to count and enter it.
     Qty Enabled         : Determines whether the quantity is enabled or not on the
                           RF screen. To force the user to scan every single unit,
                           Qty would be defaulted to 1 and QtyEnabled would be set to 'N'
     SKU Prompt          : If yes, RF would show the SKUs in the Location - BUT THIS DOES NOT WORK COMPLETELY
     Confirm LPN Contents: This is applicable only when cycle counting an LPN
                           into the location. If 'Y' then on scan of LPN, user
                           would be required to count the contents of the LPN by
                           scanning the SKUs and entering the quantity
     ScanPalletLPNs      : Allow User to Force Scan the LPNs on the Pallet, if it is a PalletCC
  */
  select @vQtyEnabled          = dbo.fn_Controls_GetAsString(@vControlCategory, 'QtyEnabled', 'N',
                                                             @BusinessUnit, @UserId),
         @vSKUPrompt           = dbo.fn_Controls_GetAsString(@vControlCategory, 'SKUPrompt', 'Scan',
                                                             @BusinessUnit, @UserId),
         @vConfirmLPNContents  = dbo.fn_Controls_GetAsString(@vControlCategory, 'AllowSKU', 'Y',
                                                             @BusinessUnit, @UserId),
         @vAllowEntity         = dbo.fn_Controls_GetAsString(@vControlCategory, 'AllowEntity', 'LS',
                                                             @BusinessUnit, @UserId),
         @vScanPalletLPNs      = dbo.fn_Controls_GetAsString(@vControlCategory, 'ScanPalletLPNs', 'N',
                                                             @BusinessUnit, @UserId),
         @vUoMEnabled          = dbo.fn_Controls_GetAsString(@vControlCategory, 'UoMEnabled', 'N',
                                                             @BusinessUnit, @UserId),
         @vConfirmQtyMode      = dbo.fn_Controls_GetAsString(@vControlCategory, 'ConfirmQtyMode', 'D' /* Default */,
                                                             @BusinessUnit, @UserId),
         @vDisplayCCEntityMode = dbo.fn_Controls_GetAsString(@vControlCategory, 'DisplayCCEntityMode', 'IU' /* Eaches */,
                                                             @BusinessUnit, @UserId),
         /* Flag to determins whether to force user to show quantity input panel or not */
         @vInputQtyPrompt      = dbo.fn_Controls_GetAsString('CycleCount_'+@vRequestedCCLevel, 'InputQtyPrompt', 'N' /* No */,
                                                             @BusinessUnit, @UserId),
         /* Confirm the default quantity to be shown on quantity box for user to confirm */
         @vDefaultQty          = dbo.fn_Controls_GetAsString('CycleCount_'+@vRequestedCCLevel, 'DefaultQty', '' /* Empty */,
                                                             @BusinessUnit, @UserId);

  /* Location status will be sent as an xml o/p Paramenter and in case the Status
     is 'E' RF will handle and navigates to second screen else will be navigated
     to the third screen. */

  /* Storing Location information into an XML */
  set @xmlLocationInfo = (select @vLocationId           as LocationId,
                                 @vLocation             as Location,
                                 @vLocationType         as LocationType,
                                 @vLocationStoragetype  as LocationStorageType,
                                 @vLocationStatus       as LocationStatus,
                                 @vLocationBarcode      as LocationBarcode,
                                 @vLocationDefaultUOM   as DefaultUOM,
                                 @vNumPallets           as NumPallets,
                                 @vNumLPNs              as NumLPNs,
                                 @vNumLPNs              as NumSKUs,   /* Currently NumSKUs are considered as many as NumLPNs */
                                 @vNumUnits             as NumUnits,
                                 @vNumInnerPacks        as InnerPacks,
                                 @vTaskId               as TaskId,
                                 @TaskDetailId          as TaskDetailId,
                                 @vBatchNo              as BatchNo,
                                 @vPickZone             as PickZone,
                                 @vRequestedCCLevel     as RequestedCCLevel,
                                 @vDisplayCCEntityMode  as DisplayCCEntityMode
                          FOR XML raw('LOCATIONINFO'), elements );

  if (@vLocationType = 'K' /* Picklane */)
    begin
      /* 3. Fetch PickLane Location Contents directly in to XML*/
      set @xmlLocationDetails = (select SKUId           as SKUId,
                                        SKU             as SKU,
                                        SKU1            as SKU1,
                                        SKU2            as SKU2,
                                        SKU3            as SKU3,
                                        SKU4            as SKU4,
                                        SKU5            as SKU5,
                                        dbo.fn_AppendStrings(SKUDescription, ' / ', InventoryClass1)
                                                        as SKUDescription,
                                        SKU1Desc        as SKU1Desc,
                                        SKU2Desc        as SKU2Desc,
                                        SKU3Desc        as SKU3Desc,
                                        SKU4Desc        as SKU4Desc,
                                        SKU5Desc        as SKU5Desc,
                                        UoM             as UoM,
                                        Quantity        as Quantity
                                 from vwLPNs
                                 where (LocationId = @vLocationId)
                                 for XML raw('PICKLANE'), elements );

      /* 4. Get Options from Controls */
      set @xmlOptions = (select @vDefaultQty      as DefaultQuantity,
                                @vQtyEnabled      as QuantityEnabled,
                                @vSKUPrompt       as SKUPrompt,
                                @vAllowEntity     as AllowEntity,
                                'S'               as ShowLocationContents,
                                @vUoMEnabled      as UoMEnabled,
                                @vConfirmQtyMode  as ConfirmQtyMode,
                                @vInputQtyPrompt  as InputQtyPrompt
                                for XML raw('PICKLANE'), elements );
    end
  else
  if (@vLocationType in ('B', 'R' /* Bulk/Reserve */)) and (@vLocationStorageType = 'A' /* Pallets */)
    begin /* 3. Fetch Reserve Location Contents directly in to XML*/

       select @vNumSKUs = count(distinct(SKU))
       from vwPallets
       where (LocationId = @vLocationId);

       set @xmlLocationDetails = (select P.PalletId           as PalletId,
                                         P.Pallet             as Pallet,
                                         L.LPNId              as LPNId,
                                         L.LPN                as LPN,
                                         L.SKUId              as SKUId,
                                         S.SKU                as SKU,
                                         S.DisplaySKU         as DisplaySKU,
                                         dbo.fn_AppendStrings(S.Description, ' / ', L.InventoryClass1)
                                                              as SKUDesc,
                                         S.SKU1               as SKU1,
                                         S.SKU2               as SKU2,
                                         S.SKU3               as SKU3,
                                         S.SKU4               as SKU4,
                                         S.SKU5               as SKU5,
                                         S.UPC                as UPC,
                                         S.UoM                as UoM,
                                         P.NumLPNs            as NumLPNs,
                                         @vNumSKUs            as NumSKUs,
                                         L.InnerPacks         as InnerPacks,
                                         L.Quantity           as Quantity,
                                         coalesce(S.InnerPacksPerLPN, 0)
                                                              as UnitsPerInnerPack
                                  from Pallets P
                                    left outer join LPNs L on P.PalletId = L.PalletId
                                    left outer join SKUs S on L.SKUId = S.SKUId
                                  where (P.LocationId = @vLocationId)
                                  for XML raw('RESERVE'), elements );

      /* 4. Get Options from Controls */
      set @xmlOptions = (select @vDefaultQty         as DefaultQuantity,
                                @vQtyEnabled         as QuantityEnabled,
                                @vConfirmLPNContents as ScanSKU,
                                @vScanPalletLPNs     as ScanPalletLPNs,
                                @vAllowEntity        as AllowEntity,
                                'P'                  as ShowLocationContents,
                                @vConfirmQtyMode     as ConfirmQtyMode,
                                @vUoMEnabled         as UoMEnabled,
                                @vInputQtyPrompt     as InputQtyPrompt
                                for XML raw('RESERVE'), elements );
    end
  else
  if  (@vLocationType in ('B', 'R' /* Bulk/Reserve */))
    begin /* 3. Fetch Reserve Location Contents directly in to XML*/

      set @xmlLocationDetails = (select L.LPNId             as LPNId,
                                        L.LPN               as LPN,
                                        L.PalletId          as PalletId,
                                        L.Pallet            as Pallet,
                                        L.SKUId             as SKUId,
                                        L.SKU               as SKU,
                                        S.DisplaySKU        as DisplaySKU,
                                        L.SKU1              as SKU1,
                                        L.SKU2              as SKU2,
                                        L.SKU3              as SKU3,
                                        L.SKU4              as SKU4,
                                        L.SKU5              as SKU5,
                                        dbo.fn_AppendStrings(L.SKUDescription, ' / ', L.InventoryClass1)
                                                            as SKUDesc,
                                        L.SKU1Desc          as SKU1Desc,
                                        L.SKU2Desc          as SKU2Desc,
                                        L.SKU3Desc          as SKU3Desc,
                                        L.SKU4Desc          as SKU4Desc,
                                        L.SKU5Desc          as SKU5Desc,
                                        L.UoM               as UoM,
                                        L.InnerPacks        as InnerPacks,
                                        L.Quantity          as Quantity,
                                        coalesce(L.UnitsPerInnerPack, 0)
                                                            as UnitsPerInnerPack
                                 from vwLPNs L
                                   left outer join SKUs S on L.SKUId = S.SKUId
                                 where (LocationId = @vLocationId)
                                 for XML raw('RESERVE'), elements );

      /* 4. Get Options from Controls */
      set @xmlOptions = (select @vDefaultQty         as DefaultQuantity,
                                @vQtyEnabled         as QuantityEnabled,
                                @vConfirmLPNContents as ScanSKU,
                                @vAllowEntity        as AllowEntity,
                                'L'                  as ShowLocationContents,
                                @vUoMEnabled         as UoMEnabled,
                                @vConfirmQtyMode     as ConfirmQtyMode,
                                @vInputQtyPrompt     as InputQtyPrompt
                                for XML raw('RESERVE'), elements );
    end

  /* 5. Build XML, The return dataset is used for RF to show Locations info, Location Details and Options in seperate nodes */
  set @xmlresult = (select '<CYCLECOUNTDETAILS>' +
                               coalesce(@xmlLocationInfo, '') +
                               '<LOCATIONDETAILS>' +
                                 coalesce(@xmlLocationDetails, '') +
                               '</LOCATIONDETAILS>' +
                               '<OPTIONS>' +
                                 coalesce(@xmlOptions, '') +
                               '</OPTIONS>' +
                           '</CYCLECOUNTDETAILS>')

  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'StartLocationCC', @xmlResultvar, @@ProcId;

  /* Mark the end of the transaction */
  exec pr_RFLog_End @xmlResultvar /* xmlResult */, @@ProcId, @ActivityLogId = @vActivityLogId output;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_BuildRFErrorXML @xmlResult output;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_CC_StartLocationCC */

Go
