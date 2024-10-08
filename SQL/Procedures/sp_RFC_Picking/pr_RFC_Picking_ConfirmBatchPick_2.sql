/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/09  RKC     pr_RFC_Picking_ConfirmBatchPick, pr_RFC_Picking_ConfirmBatchPick_2: Passed TaskDetailId param to pr_Picking_ValidateSubstitution (BK-819)
  2018/03/20  AY      pr_RFC_Picking_ConfirmBatchPick_2 & pr_RFC_Picking_ConfirmBatchPick: Invalid SKU Error in Case Picking resolved (S2G-445)
  2017/04/12  TK      pr_RFC_Picking_ValidateTaskPicks, pr_RFC_Picking_ConfirmBatchPick & pr_RFC_Picking_ConfirmBatchPick_2
  2017/02/07  VM/PK   pr_RFC_Picking_ConfirmBatchPick: Do not use pr_RFC_Picking_ConfirmBatchPick_2 (multi unit pick) for Namebadges (HPI-PostGoLive)
  2016/11/15  TD      pr_RFC_Picking_ConfirmBatchPick_2: Passing ToLPNId to pr_Tasks_MarkAsCompleted.
  2016/10/28  ??      pr_RFC_Picking_ConfirmBatchPick_2: Added check condition to use LPNDetailId, and more cosmetic changes (HPI-865)
                      pr_RFC_Picking_ConfirmBatchPick_2: Removed check condition (@ShortPick = 'Y') To Avoid Short picking
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_ConfirmBatchPick_2') is not null
  drop Procedure pr_RFC_Picking_ConfirmBatchPick_2;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_ConfirmBatchPick_2: New version to allow confirming multiple
   unit pick task details at once i.e. for the same FromLPN-Task-Order-SKU
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_ConfirmBatchPick_2
  (@xmlInput             xml,
   @xmlResult            xml  output)
As
  declare @DeviceId                            TDeviceId,
          @UserId                              TUserId,
          @BusinessUnit                        TBusinessUnit,
          @PickBatchNo                         TPickBatchNo,
          @vWaveType                           TTypeCode,
          @PickZone                            TZoneId,
          @PickTicket                          TPickTicket,
          @SuggestedLPNPickingClass            TPickingClass,
          @PickedLPNPickingClass               TPickingClass,
          @PickingPallet                       TPallet,
          @vPalletType                         TTypeCode,
          @OrderDetailId                       TRecordId,
          @FromLPN                             TLPN,
          @vFromLPNId                          TRecordId,
          @FromLPNId                           TRecordId,
          @LPNDetailId                         TRecordId,
          @PickType                            TLookUpCode,
          @OrgPickType                         TLookUpCode,
          @TaskId                              TRecordId,
          @vTaskId                             TRecordId,
          @TaskDetailId                        TRecordId,
          @ToLPN                               TLPN,
          @SKUPicked                           TSKU,
          @LPNPicked                           TLPN,
          @PickUoM                             TUoM,
          @vShipPack                           TInteger,
          @UnitsPicked                         TInteger,
          @PickedFromLocation                  TLocation,
          @ShortPick                           TFlag,
          @EmptyLocation                       TFlags,
          @ConfirmEmptyLocation                TFlags,
          @DestZone                            TLookUpCode,
          @Operation                           TOperation,
          @PickGroup                           TPickGroup,

          @ValidPickZone                       TZoneId,
          @LPNLocationId                       TLocation,
          @PickedLocationId                    TLocation,
          @LPNLocation                         TLocation,
          @LPNPalletId                         TPallet,
          @SKUId                               TRecordId,
          @PickedSKUId                         TRecordId,
          @PickedLPNId                         TRecordId,
          @vOrderSKUId                         TRecordId,
          @LPNSKUId                            TSKU,
          @LPNSKU                              TSKU,
          @LPNInnerPacks                       TInteger,
          @LPNQuantity                         TInteger,
          @ValidFromLPN                        TLPN,
          @vLPNType                            TTypeCode,
          @vToLPNType                          TTypeCode,
          @vToLPNPalletId                      TRecordId,
          @vLPNStatus                          TStatus,
          @ValidToLPN                          TLPN,
          @vToLPNId                            TRecordId,
          @ToLPNOrderId                        TRecordId,
          @ToLPNPalletId                       TRecordId,
          @ToLPNType                           TTypeCode,
          @ToLPNStatus                         TStatus,
          @PickingPalletId                     TRecordId,
          @PickedLPNSKUId                      TRecordId,
          @NextLPNToPickFrom                   TLPN,
          @NextLPNIdToPickFrom                 TRecordId,
          @NextLPNDetailId                     TRecordId,
          @NextLocationToPick                  TLocation,
          @SKUToPick                           TSKU,
          @UnitsToPick                         TInteger,
          @vUnitsPicked                        TInteger,
          @ValidPickTicket                     TPickTicket,
          @OrderId                             TRecordId,
          @vOrderId                            TRecordId,
          @OrderStatus                         TStatus,
          @ValidPickBatchNo                    TPickBatchNo,
          @PickBatchId                         TRecordId,
          @ValidPickingPallet                  TPallet,
          @vBusinessUnit                       TBusinessUnit,
          @ActivityType                        TActivityType,
          @vBatchStatus                        TStatus,
          @vSetBatchStatusToPickedOnNoMoreInv  TFlag,
          @vPickBatchId                        TRecordId,
          @vLDReservedQty                      TQuantity,
          @vNumPicksCompleted                  TCount,
          /* Tasks Related */
          @vTaskLPNId                          TRecordId,
          @vTaskDetailSKUId                    TRecordId,
          @vTaskDetailStatus                   TStatus,
          @vTaskSubType                        TTypeCode,
          @vIsTaskAllocated                    TFlag,
          @vValidTempLPNId                     TRecordId,
          @vTaskDestZone                       TZoneId,
          @vTaskLocationId                     TRecordId,
          @vTaskPickZone                       TZoneId,
          @vTaskCategory1                      TCategory,

          @vActivityLogId                      TRecordId,
          @vConfirmBatchPick                   TFlag,

          /* Substitution related */
          @vAllowSubstitution                  TFlag,
          @vOrgFromLPNId                       TRecordId,
          @vOrgValidFromLPN                    TLPN,
          @ValidLPNToSubstitute                TLPN,
          @vSubstituteLPNId                    TRecordId,
          @vSubstituteLPN                      TLPN,

          /* @OrderDetailId                    TRecordId, */
          @UnitsAuthorizedToShip               TInteger,
          @UnitsAssigned                       TInteger,
          @vUnitsToAllocate                    TInteger,
          @vUnitsPerInnerPack                  TInteger,
          @ConfirmBatchPickMessage             TVarchar,
          @LocToPick                           TLocation,
          @vPickType                           TLookUpCode,

          @vWarehouse                          TWarehouse,
          @vGenerateTempLabel                  TControlValue,
          @vConfirmedAllCases                  TFlags,

          @vTDUnitsCompleted                   TQuantity,
          @vTDUnitsToPick                      TQuantity,
          @vTDUnitToPickForOD                  TQuantity,

          @vIsBatchAllocated                   TFlag,
          @vIsTempLabelGenerated               TFlag,
          @vPickMultiSKUCategory               TCategory,
          @vIsMultiSKUTote                     TFlags,
          @vAllowPickMultipleSKUsintoLPN       TControlValue,
          @vCCOperation                        TDescription,
          @xmlRulesData                        TXML,
          @vValidToLPNTypesToPick              TDescription,
          @ttPickedLPNs                        TEntityKeysTable,
          @vPickPosition                       TLPN,

          @vPickingMode                        TVarChar,
          @SKUIdPicked                         TRecordId;


  declare @ReturnCode                          TInteger,
          @MessageName                         TMessageName,
          @CCMessage                           TDescription,
          @Message                             TDescription,
          @xmlResultvar                        TVarchar;
begin /* pr_RFC_Picking_ConfirmBatchPick */
begin try
  begin transaction;

  SET NOCOUNT ON;

  if (@xmlInput is not null)
    select @DeviceId             = Record.Col.value('DeviceId[1]',             'TDeviceId'),
           @UserId               = Record.Col.value('UserId[1]',               'TUserId'),
           @BusinessUnit         = Record.Col.value('BusinessUnit[1]',         'TBusinessUnit'),
           @PickBatchNo          = nullif(Record.Col.value('PickBatchNo[1]',   'TPickBatchNo'), ''),
           @PickZone             = nullif(Record.Col.value('PickZone[1]',      'TZoneId'), ''),
           @PickTicket           = nullif(Record.Col.value('PickTicket[1]',    'TPickTicket'), ''),
           @PickingPallet        = Record.Col.value('PickingPallet[1]',        'TPallet'),
           @OrderDetailId        = Record.Col.value('OrderDetailId[1]',        'TRecordId'),
           @FromLPN              = Record.Col.value('FromLPN[1]',              'TLPN'),
           @FromLPNId            = Record.Col.value('FromLPNId[1]',            'TRecordId'),
           @LPNDetailId          = Record.Col.value('FromLPNDetailId[1]',      'TRecordId'),
           @PickType             = Record.Col.value('PickType[1]',             'TTypeCode'),
           @TaskId               = Record.Col.value('TaskId[1]',               'TRecordId'),
           @TaskDetailId         = Record.Col.value('TaskDetailId[1]',         'TRecordId'),
           @ToLPN                = nullif(Record.Col.value('ToLPN[1]',         'TLPN'), ''),
           @SKUPicked            = nullif(Record.Col.value('SKUPicked[1]',     'TLPN'), ''),
           @LPNPicked            = Record.Col.value('LPNPicked[1]',            'TLPN'),
           @UnitsPicked          = Record.Col.value('UnitsPicked[1]',          'TInteger'),
           @PickedFromLocation   = Record.Col.value('PickedFromLocation[1]',   'TLocation'),
           @PickUoM              = Record.Col.value('PickUoM[1]',              'TUoM'),
           @ShortPick            = Record.Col.value('ShortPick[1]',            'TFlag'),
           @EmptyLocation        = Record.Col.value('LocationEmpty[1]',        'TFlags'),
           @ConfirmEmptyLocation = Record.Col.value('ConfirmLocationEmpty[1]', 'TFlags'),
           @DestZone             = Record.Col.value('DestZone[1]',             'TLookUpCode'),
           @Operation            = Record.Col.value('Operation[1]',            'TOperation'),
           @PickType             = Record.Col.value('PickType[1]',             'TOperation')
    from @xmlInput.nodes('ConfirmBatchPick') as Record(Col);

  /* Make null if empty strings are passed */
  select @ActivityType       = 'BatchUnitPick' /* BatchUnitPick */,
         @vConfirmedAllCases = 'N' /* No */,
         @vIsMultiSKUTote    = 'N' /* No */,
         @vNumPicksCompleted = 0,
         @ShortPick          = coalesce(@ShortPick, 'N'),
         @vAllowSubstitution = dbo.fn_Controls_GetAsBoolean('BatchPicking', 'AllowSubstitution', 'N'/* No */, @BusinessUnit, @UserId),
         @vPickingMode       = 'MultipleOrderDetails';

  /* Validate PickBatchNo if given by user */
  if (@PickBatchNo is not null)
    exec pr_Picking_ValidatePickBatchNo @PickBatchNo,
                                        @PickingPallet,
                                        @ValidPickBatchNo output,
                                        @vWaveType        output;

  /* Verify whether the given PickZone is valid, if provided only */
  exec pr_ValidatePickZone @PickZone, @ValidPickZone output;

  /* Validating the Pallet */
  exec pr_Picking_ValidatePallet @PickingPallet, 'U' /* Pallet in Use */,
                                 @PickBatchNo,
                                 @ValidPickingPallet output,
                                 @TaskId, @TaskDetailId;

  /* Validating whether User has permissions to do short pick. */
  if ((@ShortPick = 'Y'/* Yes */) and
    (dbo.fn_Permissions_IsAllowed(@UserId, 'RFAllowShortPick') <> '1' /* 1 - True, 0 - False */))
    select @MessageName = 'CannotShortPick';

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get OrderId for the picked order */
  select @OrderId = OrderId
  from OrderHeaders
  where (PickTicket   = @PickTicket) and
        (BusinessUnit = @BusinessUnit);

  /* Verify whether the given LPN is the same as suggested */
  /* Verify whether the given LPN Location is the proper, as per the system */

  /* select LPN Information */
  select @LPNLocationId  = LocationId,
         @LPNPalletId    = PalletId,
         @vFromLPNId     = LPNId,
         @LPNSKUId       = SKUId,
         @LPNSKU         = SKU,
         @LPNInnerPacks  = InnerPacks,
         @SuggestedLPNPickingClass
                         = PickingClass,
         @LPNQuantity    = Quantity,
         @ValidFromLPN   = LPN,
         @vLPNType       = LPNType,
         @LPNLocation    = Location,
         @vLPNStatus     = Status,
         @vBusinessUnit  = BusinessUnit,
         @vWarehouse     = DestWarehouse
  from vwLPNs
  where ((LPNId        = @FromLPNId) and
         (BusinessUnit = @BusinessUnit));

  /* Get the Substitute LPN info */
  select @vSubstituteLPNId  = LPNId,
         @vSubstituteLPN    = LPN
  from LPNs
  where (LPN = @LPNPicked) and
        (BusinessUnit = @BusinessUnit)

  /* We want to give the option to the user to scan LPN or SKU for Unit Picking, hence we need to map it correctly now */

  /* If PickType is Unit Pick and if User scans LPN instead of SKU then update Picked SKU variable with the LPN SKU,
     assuming that all inventory LPNs are single SKU LPNs */
  if (@PickType = 'U' /* Unit Pick */) and (@SKUPicked is not null) and (@SKUPicked = @ValidFromLPN)
    select @SKUPicked = @LPNSKU;
  else
  /* If PickType is LPN Pick and if User scans SKU instead of LPN then update Picked LPN variable with the From LPN,
     assuming that all inventory LPNs are single SKU LPNs */
  if ((@PickType = 'L' /* LPN Pick */) or (@OrgPickType = 'L' /* LPN Pick */)) and (@LPNPicked is not null) and (@LPNPicked = @LPNSKU)
    select @LPNPicked = @ValidFromLPN;

  /* Get SKUId of the scanned SKUs */
  if (@SKUPicked is not null)
    select @PickedSKUId = SS.SKUId,
           @SKUIdPicked = SS.SKUId,
           @SKUPicked   = SS.SKU
    from dbo.fn_SKUs_GetScannedSKUs (@SKUPicked, @BusinessUnit) SS
      join vwLPNDetails LD on (LD.LPNId = @vFromLPNId);

  /* If SKUId is null then get the SKUId from OrderDetails */
  if (@SKUIdPicked is null)
    select @SKUIdPicked = SKUId
    from OrderDetails
    where (OrderDetailId = @OrderDetailId);

  /* temporary, for the moment, do not allow substitution when picking from multi-SKU LPNs - we need to re-evaluate this */
  if (@LPNSKUId is null) set @vAllowSubstitution = 'N';

  /* If From LPNDetailId is given, then use it */
  if (@LPNDetailId is not null) and (@LPNSKU is null) and
     (@PickType = 'U') and (@vLPNType <> 'L')
    select @LPNSKUId      = SKUId,
           @LPNSKU        = SKU,
           @LPNInnerPacks = InnerPacks,
           @LPNQuantity   = Quantity
    from vwLPNDetails
    where (LPNId = @FromLPNId) and
          (LPNDetailId = @LPNDetailId);

  /* If Units are from Multiple SKU line LPNs (not logical - logical will have one LPN each for each SKU),
     We need to get the SKU from LPNDetails */
  if (@LPNSKU is null) and
     (@PickType = 'U' /* Units */) and  --> To be safe
     (@vLPNType <> 'L' /* Logical */)   -- May be multi-SKU LPN (not logical)
    select @LPNSKUId      = SKUId,
           @LPNSKU        = SKU,
           @LPNInnerPacks = InnerPacks,
           @LPNQuantity   = Quantity
    from vwLPNDetails
    where (LPNId = @FromLPNId) and
          (SKU   = @SKUPicked);
  /* Below task sku id and this skuid are validated, hence there is no issue, if users scans another existing sku
     on the same LPN */

  /* If there is an Alternate LPN present, then use it */
  /* We might need to add conditions here */
  select @ToLPN          = coalesce(nullif(AlternateLPN, ''), LPN),
         @vToLPNType     = LPNType,
         @vToLPNPalletId = PalletId
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@ToLPN, @BusinessUnit, 'ILTU' /* Options */));

  /* select OrderId, SKUId to validate while picking and placing
      the Order into LPN */
  select @vOrderId         = OD.OrderId,
         @vOrderSKUId      = OD.SKUId,
         @vUnitsToAllocate = OD.UnitsToAllocate
  from OrderDetails OD
  where (OD.OrderDetailId = @OrderDetailId);

  /* Picking multiple order details at once, then get the sum of all UnitsToAllocate */
  if (@vPickingMode = 'MultipleOrderDetails')
    select @vUnitsToAllocate = sum(OD.UnitsToAllocate)
    from OrderDetails OD
    where (OD.OrderId = @OrderId) and
          (OD.SKUId   = @SKUIdPicked);

  /*** Below is not applicable for MultipleOrderDetails picking ***/
  /* Substitution
     - Assumption - User scans substituted LPN only, not SKU even when to pick units from LPN */
  /* For Units picks, RF sends scanned LPN/SKU in @SKUPicked not @LPNPicked, hence set @LPNPicked as
     user might be scanning substituted LPN and we are getting it in @SKUPicked
     -- Do this only when picking units from LPN and not from Picklane */
  if ((@vLPNType <> 'L' /* <-From LPN Type - LPN Pick or Units from LPN pick */) and (@ShortPick = 'N'/* No */))
    begin
      if (@LPNPicked is null) and (@SKUPicked is not null) and
         (@SKUPicked <> @ValidFromLPN) and (@SKUPicked <> @LPNSKU /* FromLPN SKU */)
        select @LPNPicked = @SKUPicked;

      /* 1. VM: Now, any LPN Pick or Units from LPN pick are eligible for Substitution - (2015/2/25) */
      if (@ValidFromLPN /* Suggested */ <> @LPNPicked /* Scanned */) and (@vAllowSubstitution = 'Y' /* Yes */)
          -- and (@LPNSKU <> @LPNPicked) - What if they scan SKU. Can be worked on later.
        begin
          exec pr_Picking_ValidateSubstitution @FromLPNId, @vSubstituteLPNId, @TaskDetailId, @ValidLPNToSubstitute output;

          if (@ValidLPNToSubstitute is not null)
            begin
              exec pr_Picking_SwapLPNsDataForSubstitution @ValidFromLPN, @ValidLPNToSubstitute, @TaskDetailId /* Picking Task detail */, @UserId;

              /* Keep original data - can be used for future - may be for Audit trail */
              select @vOrgFromLPNId        = @FromLPNId,
                     @vOrgValidFromLPN     = @ValidFromLPN;
                     --@vOrgFromLPNDetailId  = @LPNDetailId;

              /* Get Substituted LPN Information further validations (regular for picking)
                 after it is confirmed as valid candiate for substitution */
              select @FromLPNId      = LPNId, -- This is for further validations and process
                     @LPNLocationId  = LocationId,
                     @LPNPalletId    = PalletId,
                     @LPNSKUId       = SKUId,
                     @LPNSKU         = SKU,
                     @LPNInnerPacks  = InnerPacks,
                     @LPNQuantity    = Quantity,
                     @ValidFromLPN   = LPN,
                     @vLPNType       = LPNType,
                     @LPNLocation    = Location,
                     @vLPNStatus     = Status,
                     @vBusinessUnit  = BusinessUnit,
                     @vWarehouse     = DestWarehouse
              from vwLPNs
              where ((LPN          = @ValidLPNToSubstitute) and
                     (BusinessUnit = @BusinessUnit));
            end
          else
            begin
              /* Though, pr_Picking_ValidateSubstitution throws an error. Handling validation once again here, just in case */
              set @MessageName = 'Substitution_LPNNotAValidCandidate'; /* we are not allowing to Pick LPN other than Suggested LPn for now */

              /* If Error, then return Error Code/Error Message */
              if (@MessageName is not null)
                goto ErrorHandler;
            end
        end
    end /* Substitution */

  /*** MultipleOrderDetails mode would not work with Tasks having specific Pickpositions ***/

  /* Get the Task Details */
  select @vTDUnitsToPick        = (Quantity - coalesce(UnitsCompleted, 0)),
         @vTaskLPNId            = LPNId,
         @vTaskDetailSKUId      = SKUId,
         @vIsTempLabelGenerated = IsLabelGenerated,
         @vTaskDestZone         = DestZone,
         @vPickMultiSKUCategory = 'PickMultiSKUIntoSameTote_' + coalesce(DestZone, ''),
         @vTaskLocationId       = LocationId,
         @vPickPosition         = case when @vPickingMode = 'MultipleOrderDetails' then null else PickPosition end
  from TaskDetails
  where (TaskId       = @TaskId) and
        (TaskDetailId = @TaskDetailId) and
        (BusinessUnit = @BusinessUnit);

  if (@vPickingMode = 'MultipleOrderDetails')
    select @vTDUnitsToPick = sum(UnitsToPick)
    from TaskDetails
    where (TaskId  = @TaskId) and
          (LPNId   = @vFromLPNId) and
          (OrderId = @OrderId) and
          (SKUId   = @SKUIdPicked);

  /* Get the Task Info */
  select @vTaskId          = T.TaskId,
         @vTaskSubType     = T.TaskSubType,
         @vIsTaskAllocated = T.IsTaskAllocated,
         @vWaveType        = PB.BatchType,
         @vTaskPickZone    = T.PickZone,
         @vTaskCategory1   = T.TaskCategory1
  from Tasks T
    join PickBatches PB on (PB.BatchNo = T.BatchNo)
  where (T.TaskId       = @TaskId) and
        (T.BusinessUnit = @BusinessUnit);

  /*** Below is not applicable for MultipleOrderDetails picking ***/
  if (@vTaskSubType = 'CS') and
     (@ToLPN        = 'LocationLPN')
    begin
      select @vTDUnitsToPick = sum(Quantity - coalesce(UnitsCompleted, 0))
      from TaskDetails
      where (TaskId = @TaskId) and
            (LPNId  = @vTaskLPNId) and
            (SKUId  = @vOrderSKUId);
    end

  select @PickingPalletId = PalletId,
         @vPalletType     = PalletType
  from Pallets
  where (Pallet       = @PickingPallet) and
        (BusinessUnit = @BusinessUnit);

  /* If the user was asked to Pick the LPN, but only decides to pick part of it then
     change it to a Unit Pick */
  if ((@vWaveType <> 'RU' /* Replenish Units */) and
      (((@PickType = 'L' /* LPN Pick */) and ((@UnitsPicked < @LPNQuantity) or (@vPalletType = 'C' /* Cart */))) or
      (@vLPNType = 'L' /* picklane */)))
    select @OrgPickType = @PickType,
           @PickType    = 'U' /* Unit Pick */;

  /* Set value here to that confirmed all the units at a time or not
    there is no point if the task subtype is unit pick and the user scans ALL.
    because we will not generate labels for unit pick sub task type  */
  if (@ToLPN in ('TaskDetail', 'LocationLPN')) and (@vTaskSubType <> 'U' /* unitpick */)
    begin
      select @vConfirmedAllCases = 'Y' /* Yes */,
             @ValidToLPN         = @ToLPN
    end

  /* If the to scan LPN is null then we need to get the control varibale here */
  select @vGenerateTempLabel = dbo.fn_Controls_GetAsString('BatchPicking', 'GenerateTempLabel', 'N',
                                                           @BusinessUnit, @UserId);

  /* If the user forced to pick all temp labels at one time then we no need to get to lpn details */
  if (@vConfirmedAllCases <> 'Y')
    begin
      /* Here we need to create a new LPN if the User does not scan the ToLPN and  Generatetemp Label is Yes */
      if ((@ShortPick  = 'N' /* No */) and
         (coalesce(@ToLPN, '') = '')  and
         (@PickType = 'U' /* Unit Pick */) and
         (@vGenerateTempLabel in ('C', 'S' /* Carton, Ship Carton */)) and
         (@vIsTempLabelGenerated <> 'Y' /* Yes */))
        begin
          exec @ReturnCode = pr_LPNs_Generate @vGenerateTempLabel,   /* @LPNType C or S    */
                                              1,                     /* @NumLPNsToCreate   */
                                              null,                  /* @LPNFormat         */
                                              @vWarehouse,
                                              @BusinessUnit,
                                              @UserId,
                                              @vToLPNId     output,
                                              @ToLPN        output;
        end

      /* Set @ToLPN as last cart position (desc by modifieddate) used by the order earlier */
      if ((@PickType = 'L' /* LPN Pick */) or (@OrgPickType = 'L' /* LPN */)) and (@ShortPick = 'N' /* No */) and
         (/* @vXferUnitsFromFullLPNToCartPosition */ 'Y' = 'Y' /* Yes */) and (@vPalletType = 'C' /* Picking Cart */)
        begin
          /* Get the cart position for which the current order is taken to or set it to first cart position, which is empty */
          if (@ToLPN is null)
            select @ToLPN = LPN
            from LPNs
            where (PalletId = @PickingPalletId) and
                  (OrderId  = @vOrderId)        and
                 (LPNType  = 'A' /* Cart */) /* select the cart postion instead of LPN which is picked onto a cart */
            order by ModifiedDate desc  /* to get the last cart position used by order */;

          /* if the order does not associate with any cart position, pick the units to any new cart position */
          if (@ToLPN is null)
            select top 1 @ToLPN = LPN
            from LPNs
            where (PalletId = @PickingPalletId) and
                  (Status   = 'N' /* New */)
            order by LPN
        end

      /* Get the npick to LPN details here
         User may scan tote/ TempLabel LPN number / UCCBarcode of the LPN ...*/
      select @vToLPNId      = LPNId,
             @ValidToLPN    = LPN,
             @ToLPNPalletId = PalletId,
             @ToLPNOrderId  = OrderId,
             @SKUId         = SKUId,
             @ToLPNType     = LPNType,
             @ToLPNStatus   = Status
      from LPNs
      where (((LPN         = @ToLPN) or
              (UCCBarcode  = @ToLPN))and
             (BusinessUnit = @BusinessUnit));

      /* we need to ensure that user scans the pre generated labels for
         the Case/LPN task subtypes
         So we need to get the LPNId from the LPNTasks to validate */
      if (@vIsTempLabelGenerated = 'Y' /* yes */)
        begin
          select @vValidTempLPNId = LPNId
          from LPNTasks
          where (TaskDetailId = @TaskDetailId) and
                (LPNId        = @vToLPNId);
        end
    end

  /* Todo: Need to validate based on LOT as well */
  /* User will pick all cases at once and will confirm one time, so they will
     scan as ALL instead of each label */
  if (@LPNPicked is not null)
    select @PickedLPNId           = LPNId,
           @PickedSKUId           = SKUId,
           @PickedLocationId      = LocationId,
           @PickedLPNPickingClass = PickingClass
    from LPNs
    where ((LPN          = @LPNPicked) and
           (BusinessUnit = @BusinessUnit));

  if (@PickTicket is not null)
    select @ValidPickTicket = PickTicket
    from OrderHeaders
    where (PickTicket   = @PickTicket) and
          (BusinessUnit = @BusinessUnit);

  /* Get whether the batch is allocated or not */
  select @vIsBatchAllocated = IsAllocated,
         @vPickBatchId      = WaveId
  from PickBatches
  where (BatchNo      = @ValidPickBatchNo) and
        (BusinessUnit = @BusinessUnit);

  /* Get the UnitsPerInnerPack of SKU */
  select @vUnitsPerInnerPack = case when InnerPacks = 0 then 0
                               else coalesce(nullif(UnitsPerPackage, 0), 1)
                               end,
         @vLDReservedQty     = Quantity
  from LPNDetails
  where (LPNDetailId = @LPNDetailId);

  /*** Get total Qty to pick from the FROM_LPN ***/
  if (@vPickingMode = 'MultipleOrderDetails')
    select @vLDReservedQty = sum(Quantity)
    from LPNDetails
    where (LPNId        = @vFromLPNId) and
          (OrderId      = @OrderId) and
          (SKUId        = @SKUIdPicked) and
          (Onhandstatus = 'R' /* Reserved */);

  /* Get the SKU ShipPack */
  select @vShipPack = ShipPack
  from SKUs
  where (SKUId = @PickedSKUId);

  /* Build the data for evaluation of rules */
  select @xmlRulesData = '<RootNode>' +
                           dbo.fn_XMLNode('WaveType',      @vWaveType) +
                           dbo.fn_XMLNode('TaskSubType',   @vTaskSubType) +
                           dbo.fn_XMLNode('TaskPickZone',  @vTaskPickZone) +
                           dbo.fn_XMLNode('TaskCategory1', @vTaskCategory1) +
                        '</RootNode>'

  /* Return the value of valid ToLPNTypes to pick into based on the batchtype,
    if it returns value as ALL then there is no need to validate   */
  exec pr_RuleSets_Evaluate 'ValidLPNTypesToPickTo', @xmlRulesData, @vValidToLPNTypesToPick output;

  /* Compute the real UnitsPicked as the user entered PickedQty could be Cases or Units */
  select @vUnitsPicked = case when (@ShortPick = 'Y')    then 0 /* Zero */
                              when (@vTaskSubType = 'U' /* Unit Pick */) and (@PickUoM = 'IP' /* InnerPacks */) then (@UnitsPicked * coalesce(nullif(@vShipPack, 0), 1))
                              when (@vTaskSubType = 'U' /* Unit Pick */) then @UnitsPicked
                              when (@vTaskSubType = 'L' /* LPN Pick  */) and ('N' /* UseInnerPacks  - Use control var */ = 'N') then @UnitsPicked
                              else (@UnitsPicked * coalesce(nullif(@vUnitsPerInnerPack, 0), 1))
                         end;

  if (@vTaskDestZone = 'PTL') and (@vTaskSubType = 'U' /* Unit pick */)
    begin
      /* Get the control value to pick the multiple SKUs into single tote or not */
      select @vAllowPickMultipleSKUsintoLPN = dbo.fn_Controls_GetAsString('BatchPicking', @vPickMultiSKUCategory, 'Y'/* Default -Y */,
                                                                          @BusinessUnit, @UserId);

      if (@vAllowPickMultipleSKUsintoLPN = 'N' /* No */)
         /* check if the  user picked other SKUs into the scanned tote/label  */
        if (exists (select * from
                    LPNDetails
                    where (LPNId = @vToLPNId and
                          (SKUId <> @PickedSKUId))))
          select @vIsMultiSKUTote = 'Y' /* Yes */;
    end

  /* As we know that, for short pick there is no need to scan any thing like sku,location..*/
  if (@ShortPick = 'N')
    begin
      /* Why to validate From LPN only when Short Pick = 'N' - Please see below comments in else condition (ShortPick = 'Y') */
      if (@ValidFromLPN is null)
        set @MessageName = 'InvalidFromLPN';
      else
      /* If Picking to a cart and there is no ToLPN given, then raise an error. ToLPN is required for unit picking */
      if (nullif(@ToLPN, 'LocationLPN') is null) and
         (nullif(@ValidToLPN, 'LocationLPN') is null) and
         (@vPalletType ='C' /* Picking Cart */) and
         (@PickType = 'U' /* Unit Pick */)
        set @MessageName = 'InvalidToLPN';
      else
      /* Picking LPNs to Pallet, would not have ToLPN, so skip the validation in that scenario */
      if ((((@ToLPN is not null) and (@ValidToLPN is null)) or
           ((@vGenerateTempLabel = 'N') and (@ValidToLPN is null))) and
          (@vConfirmedAllCases = 'N' /* No */) and
          ((@PickType <> 'L') or (@vPalletType ='C' /*Picking Cart */)))
        set @MessageName = 'InvalidToLPN';
      /* If to LPN is Cart position then ensure that the picking Pallet should be CartType and that should be on same pallet */
      if ((@vToLPNType = 'A' /* Cart Position */) and (@vPalletType <> 'C' /* Picking Cart */))
        set @MessageName = 'Picking_ScanToCartPositionInvalid';
      else
      /* Validate if user scanned different Cart Position than Picking cart */
      if ((@vToLPNType = 'A' /* Cart Position */) and
          (coalesce(@vToLPNPalletId, 0) <> @PickingPalletId))
        set @MessageName = 'ScannedPositionFromAnotherCart';
      else
      /* Need to ensure user scans generated temp Label */
      if (@vIsTempLabelGenerated = 'Y' /* yes */) and
         (@vConfirmedAllCases <> 'Y') and
         (@vValidTempLPNId is null)
        set @MessageName = 'Picking_ScanValidTempLabel';
      else
      /* NFU - New, New Temp, Picking */
      if (dbo.fn_LPNs_ValidateStatus(@vToLPNId, @ToLPNStatus, 'NFU') <> 0) and
         (@ToLPNType <> 'A'/* Cart */)
        set @MessageName = 'LPNClosedForPicking';
      else
      if (@LPNPicked is not null) and (@PickedLPNId is null)
        set @MessageName = 'InvalidPickingLPN';
      else
      if (@PickedSKUId is null)
        set @MessageName = 'InvalidPickingSKU';
      else
      if ((@ToLPN is not null) and (@ToLPNType = 'L' /* PickLane */))
        set @MessageName = 'CannotPickToPickLane';
      else
      /* validating ToLPN, if we did not setup rule then rule will return as ALL,
         then no need to validate , we do not want to break existing functionality for other clients */
      if (@vTaskSubType = 'U' /* Unit pick */) and
         (coalesce(@vValidToLPNTypesToPick, 'ALL') <> 'ALL') and
         (charindex(@ToLPNType, @vValidToLPNTypesToPick) = 0)
        set @MessageName = 'InvalidToLPN';
      else
      if ((@PickType  = 'L' /* LPN */) and (@vTaskLPNId <> @PickedLPNId) and
          (@vIsBatchAllocated <> 'N' /* No */))
        set @MessageName = 'LPNDiffFromSuggested';
      else
      if ((@SuggestedLPNPickingClass = 'OL' or @PickedLPNPickingClass = 'OL' /* Opened LPN */) and (@SuggestedLPNPickingClass <> @PickedLPNPickingClass))
        set @MessageName = 'CannotSubstituteAnyLPNWithAOpenLPN';
      else
      if (@LPNLocation <> coalesce(@PickedFromLocation, @LPNLocation))
        set @MessageName = 'LocationDiffFromSuggested';
      else
      if (@vUnitsPicked > @LPNQuantity)
        set @MessageName = 'PickedUnitsGTLPNQty';
      else
      if (@vLDReservedQty > @vTDUnitsToPick) and
         (@vIsBatchAllocated = 'Y') and (@vTaskSubType = 'U') and
         (@vIsTaskAllocated = 'Y'/* Yes */)
        set @MessageName = 'AllocatedQtyIsGreaterThanRequiredQty';
      else
      if (@vUnitsPicked > @vUnitsToAllocate) and (@vIsBatchAllocated = 'N')
        set @MessageName = 'PickedUnitsGTRequiredQty';
      else
      if ((@ToLPNOrderId is not null) and
          (@vOrderId <> coalesce(@ToLPNOrderId, @vOrderId)))
        set @MessageName = 'PickingToWrongOrder';
      else
      if ((@PickedSKUId is not null) and ((@PickedSKUId <> @vOrderSKUId) or (@PickedSKUId <> @LPNSKUId)))
        set @MessageName = 'PickingSKUMismatch';
      else
      if (@PickingPalletId <> @ToLPNPalletId)
        set @MessageName = 'PickingToAnotherPallet';
      else
      if (@vUnitsPicked > @vTDUnitsToPick)
        begin
          select @MessageName = 'PickedQtyIsGreaterThanRequiredQty';--,
                 --@vNote1      = dbo.fn_Str(@vTDUnitsToPick);
        end
      else
      if (@vTaskSubType = 'CS') and
         (@ToLPN = 'LocationLPN') and (@vUnitsPicked <> @vTDUnitsToPick)
        set @MessageName = 'PickedQtyIsdiffThanRequiredQty';
      else
      if (dbo.fn_LPNs_ValidateStatus(@FromLPNId, @vLPNStatus, 'KES') = 0)
        set @MessageName = 'LPNAlreadyPicked';
      else
      if (@vIsTempLabelGenerated = 'Y') and
         (@vTaskSubType = 'CS' /* Case Pick */) and
         (@UnitsPicked >  1) and
         (@ToLPN not in ('TaskDetail', 'LocationLPN'))
        set @MessageName = 'CannotPickAllInvIntoOneLabel';
      else
      if (@vTaskSubType = 'U' /* Unit Pick */) and
         (@vAllowPickMultipleSKUsintoLPN = 'N' /* No */) and
         (@vIsMultiSKUTote = 'Y' /* Yes */)
        set @MessageName = 'ToLPNAlreadyPickedForOtherSKU';
      else
      if (@LPNLocationId <> @PickedLocationId)
        set @MessageName = 'PickLPNFromSuggestedLocationOnly'; /* we are not allowing to Pick LPN other than Suggested LPn for now */
      else
      if ((@PickType = 'L'/* LPN Pick */) and (@UnitsPicked <> @vTDUnitsToPick))
        set @MessageName = 'CannotPickUnitsFromLPN';
      else
      if (@vPickPosition is not null) and (@ValidToLPN <> (@PickingPallet + '-' + @vPickPosition))
        set @MessageName = 'ELCannotPickIntoDiffPosition';
      else
      /* check if user scanned position which is associated for an employee */
      if (@vPickPosition is null) and (@ValidToLPN in (select @PickingPallet + '-' + PickPosition
                                                        from TaskDetails
                                                        where (TaskId = @TaskId)))
        set @MessageName = 'ScannedPosIsReservedForEL';

      /* If Error, then return Error Code/Error Message */
      if (@MessageName is not null)
        goto ErrorHandler;
    end

  /* If PickTicket is null, get the PickTicket from the OrderDetails table with the
     given OrderDetailId */
  if (@ValidPickTicket is null)
    select @ValidPickTicket = OH.PickTicket
    from OrderHeaders OH
      join OrderDetails OD on (OH.OrderId = OD.OrderId)
    where (OD.OrderDetailId = @OrderDetailId);

  if (@PickType = 'L' /* LPN */) and (@ShortPick = 'N')
    begin
      /* Call ConfirmLPNPick */
      exec @ReturnCode = pr_RFC_Picking_ConfirmLPNPick @DeviceId, @UserId, @PickTicket,
                                                       @OrderDetailId, @ValidPickZone, @LPNPicked,
                                                       @PickedFromLocation, @PickingPallet, @ShortPick,
                                                       @TaskId, @TaskDetailId,
                                                       @xmlResult output;
    end
  else
  if (@PickType = 'L' /* LPN */) and (@ShortPick = 'Y')
    begin
      /* Call ConfirmLPNPick */
      /* ConfirmLPNPick will create cycle count task if required */
      exec @ReturnCode = pr_RFC_Picking_ConfirmLPNPick @DeviceId, @UserId, @PickTicket,
                                                       @OrderDetailId, @ValidPickZone, @ValidFromLPN,
                                                       @PickedFromLocation, @PickingPallet, @ShortPick,
                                                       @TaskId, @TaskDetailId,
                                                       @xmlResult output;
      if (@ReturnCode > 0)
        begin
          select @Message = @CCMessage;
          goto ErrorHandler;
        end
    end
  else
  if (@ShortPick = 'N') -- and PickType = 'U'
    begin
      /* Call ConfirmUnitPick */
      if (@vPickingMode = 'MultipleOrderDetails')
        exec pr_Picking_ConfirmUnitPick @ValidPickTicket, @OrderDetailId,
                                        @ValidFromLPN, @ValidToLPN, @LPNSKUId,
                                        @vUnitsPicked, @TaskId, @TaskDetailId,
                                        @BusinessUnit, @UserId, @ActivityType,
                                        @PickingPalletId, @vPickingMode;

      /* Temporary fix - This is not right ** TODO - Need to identify the right place and fix it. However, this wont harm now */
      update LPNs
      set PickingClass = 'OL' /* Open LPN */
      where (LPN = @ValidFromLPN) and
            (LPNType <> 'L' /* Logical Picklane */);
    end
  else
  if (@ShortPick = 'Y') -- and PickType = 'U'
    begin
      /* There are some situations, where 2 or more pickers are suggested to pick
         from the same location and if the first picker (who reaches the location first),
         picked the required (lets say he requires all available in this situation) and
         when the 2nd or other pickers comes to this location to pick and found there
         is no available inventory by that time, they need to be able to choose 'ShortPick'
         option and go ahead with remaining batch order(s) picks.
         (12/5) - Currently not allowing to Short Pick and showing message "Invalid From LPN"
         - This is due to the first picker picks all inventory, the LPN (logical) is deleted
           along with its detail lines, hence for the second or other pickers, the LPN is not available.

         ** Other situation could be - Location is adjusted by some user while the picker is directed to pick just before that

         Solution: Check the From LPN, if not null then adjust, else proceed with other picks in the batch
      */
      if (@ValidFromLPN is not null)
        begin
          /* Update OrderHeaders by setting ShortPick flag to 'Y' if it is ShortPicked */
          update OrderHeaders
          set ShortPick = 'Y'
          where (OrderId = @vOrderId);

          /* currently @vUnitsToAllocate is untsToAllocate value on the line, if the total units
            allocated then UntisToallcoate is 0, so we need to send remaig units to pick for the task line if
            the batch is allocated  */
          if (@vIsBatchAllocated <> 'N' /* No */)
            set @vUnitsToAllocate = @vTDUnitsToPick
          else
            set @vUnitsToAllocate = @LPNQuantity;

          /* System thinks there is inventory in a location and directed user to pick it,
             but the user did not find any inventory to pick, so clear the LPN */

          if (@vPickingMode = 'MultipleOrderDetails')
            begin
              /* call picking short picking */
              exec pr_Picking_ShortPickLPN @FromLPNId, @SKUIdPicked, @OrderId, @vBusinessUnit, @UserId;
            end
          else
            begin
              /* call the LPN to short pick */
              exec pr_Picking_ShortPickLPN @FromLPNId, @LPNDetailId, @LPNSKUId, @vBusinessUnit, @UserId;
            end

          /* Log audit here */
          exec pr_AuditTrail_Insert 'OrderShortPicked', @UserId, null /* ActivityTimestamp */,
                                    @OrderId       = @vOrderId,
                                    @OrderDetailId = @OrderDetailId,
                                    @LocationId    = @LPNLocationId,
                                    @Quantity      = @vUnitsToAllocate,
                                    @LPNId         = @FromLPNId,
                                    @PickBatchId   = @vPickBatchId,
                                    @PalletId      = @PickingPalletId;

          if (@ReturnCode > 0)
            begin
              select @MessageName = @CCMessage;
              goto ErrorHandler;
            end
        end
    end

  /* update the task if there is one */
  if (@TaskId is not null) and (@vPickingMode = 'MultipleOrderDetails')
    begin
      exec pr_Tasks_MarkAsCompleted @TaskId, @TaskDetailId, @vPickBatchId, @FromLPNId, @SKUIdPicked, @OrderId, @OrderDetailId,
                                    @UnitsPicked, @vPickingMode, @UserId, @vToLPNId;
    end
  else if (@TaskId is not null)
    begin
      update TD
      set @vTDUnitsCompleted      =
          TD.UnitsCompleted       = case  /* if the picker confirms at location level, then we need to update all*/
                                      when (@vTaskSubType = 'CS') and (@ToLPN = 'LocationLPN') then
                                       coalesce(TD.UnitsCompleted, 0) + (TD.Quantity - coalesce(TD.UnitsCompleted, 0))
                                      when (@PickType <> 'L' /* LPN Pick */) then /* For LPN picks we are updated Units Completed in pr_RFC_Picking_ConfirmLPNPick */
                                       coalesce(TD.UnitsCompleted, 0) + @vUnitsPicked
                                      else
                                       @vUnitsPicked
                                    end,
          TD.InnerpacksCompleted  = case
                                      when @vTaskSubType <> 'U' /* Unit pick */ then (coalesce(TD.InnerpacksCompleted, 0) + @UnitsPicked)
                                      else 0
                                    end,
          @vTaskDetailStatus      =
          TD.Status               = Case
                                      when (@vIsTaskAllocated = 'Y' /* Yes */) and
                                           ((@ShortPick = 'Y') and (@vTDUnitsCompleted = 0)) then 'X' /* Canceled */
                                      when (@vIsTaskAllocated = 'Y' /* Yes */) and
                                           (@ShortPick = 'Y')                               then 'C' /* Completed */
                                      when (@vTDUnitsCompleted = TD.Quantity)               then 'C' /* Completed */
                                      when (@vTDUnitsCompleted > 0) then 'I' /* In Progress */
                                      else TD.Status
                                    end,
          TD.PalletId             = case when  @ToLPN = 'LocationLPN'    then @PickingPalletId
                                      else TD.PalletId
                                    end,
          TD.ModifiedDate         = current_timestamp,
          TD.ModifiedBy           = @UserId
      from TaskDetails TD
      where (TD.TaskId     = @TaskId) and
            ((coalesce(@ToLPN, '') not in ('TaskDetail', 'LocationLPN') and  /* User may Short Pick without scanning ToLPN */
             (TD.TaskDetailId = @TaskDetailId)) or
             ((@ToLPN in ('TaskDetail', 'LocationLPN') and
              (TD.LocationId = @vTaskLocationId) and
              (TD.LPNId      = @FromLPNId))))

      /* set updated count as picked count here */
      set @vNumPicksCompleted = @@rowcount;

      /* if the */
      if (@vTaskDetailStatus in ('C', 'X') and ((@vConfirmedAllCases <> 'Y')))
         set @vNumPicksCompleted = 1;

      /* Update the counts of the tasks */
      exec pr_Tasks_SetStatus @TaskId, @UserId, null /* Status */, 'Y' /* Recount */;

      /* update num picks completed here */
      If ((@vTaskDetailStatus in ('C' /* Completed */, 'X' /* Cancelled */)) and
         (@PickType <> 'L' /* LPN Pick */)) /* We will update num picks completed for LPN picks in ConfirmLPNPick proc */
        update Pickbatches
        set NumPicksCompleted = NumPicksCompleted + @vNumPicksCompleted
        where (RecordId = @vPickBatchId);
    end

  /* If the location was supposed to empty after the pick, then mark the location as counted or
     issue a cycle count based upon users' confirmation */
  if (@ShortPick = 'N'/* No */) and
     (@EmptyLocation = 'Y')
    begin
      select @vCCOperation = case
                               when @ConfirmEmptyLocation = 'Y' then 'ConfirmEmpty'
                               when @ConfirmEmptyLocation = 'N' then 'ConfirmNonEmpty'
                             end

      /* call the procedure here to update Location as cc or create a task for that */
      /* @vTaskLocationId -> @LPNLocationId : Both are the same, but in case if Task is not
         Allocated then LocationId on the Task will be null so passing Picked LPN LocationId*/
      exec pr_Picking_CCPickedLocation  @LPNLocationId, @vCCOperation, @BusinessUnit,
                                        @UserId, @DeviceId;
    end

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  if (@vIsBatchAllocated = 'Y')
    begin
      if (coalesce(@PickGroup, '') <> '')
        begin
          /* Build the data for evaluation of rules to get pickgroup*/
          select @xmlRulesData = '<RootNode>' +
                                   dbo.fn_XMLNode('Operation',  @Operation) +
                                   dbo.fn_XMLNode('PickType',   @PickType) +
                                 '</RootNode>';

          /* Get the valid pickGroup here to find the task  */
          exec pr_RuleSets_Evaluate 'Task_PickGroup', @xmlRulesData, @PickGroup output;
        end

      /* Find the next Pick Task or Pick from Task for the Batch */
      exec pr_Picking_FindNextTaskToPickFromBatch @UserId,
                                                  @DeviceId,
                                                  @BusinessUnit,
                                                  @PickBatchNo,
                                                  @PickTicket,
                                                  @ValidPickZone,
                                                  @DestZone,
                                                  @PickGroup,
                                                  'P' /* Partial Picks - Units */,
                                                  null,
                                                  @PickingPalletId,
                                                  @NextLPNToPickFrom   output,
                                                  @NextLPNIdToPickFrom output,
                                                  @NextLPNDetailId     output,
                                                  @OrderDetailId       output,
                                                  @UnitsToPick         output,
                                                  @LocToPick           output,
                                                  @vPickType           output,
                                                  @TaskId              output,
                                                  @TaskDetailId        output;

      /* Update taskDetail Status here */
      if (coalesce(@TaskDetailId, 0) <> 0)
        update TaskDetails
        set Status   = 'I' /* InProgress */,
            PalletId = @PickingPalletId
        where (TaskDetailId = @TaskDetailId);
    end
  else
    begin
      /* Find the next Pick from the Batch */
      exec pr_Picking_FindNextPickFromBatch @PickBatchNo,
                                            @ValidPickZone,
                                            'P' /* Partial Picks - Units */,
                                            null,
                                            @NextLPNToPickFrom   output,
                                            @NextLPNIdToPickFrom output,
                                            @NextLPNDetailId     output,
                                            @OrderDetailId       output,
                                            @UnitsToPick         output,
                                            @LocToPick           output,
                                            @vPickType           output;
    end

  /* if there are more units to pick, then build response for next pick to send to device */
  if (@NextLPNToPickFrom is not null)
    begin
      /* Prepare response for the Pick to send to RF Device */
      exec pr_Picking_BatchPickResponse @ValidPickingPallet,
                                        null /* @PalletId */,
                                        null /* @Pallet */,
                                        @NextLPNIdToPickFrom,
                                        @NextLPNToPickFrom,
                                        @NextLPNDetailId,
                                        @OrderDetailId,
                                        @UnitsToPick,
                                        @LocToPick,
                                        @vPickType,
                                        @PickGroup,
                                        @TaskId,
                                        @TaskDetailId,
                                        @BusinessUnit,
                                        @UserId,
                                        @xmlResult output;
    end
  else
    begin
      /* When last pick is done, it say "completed' which is not correct.
         There may be more picks in the task in that case we should not say completed,
         we should say that no more picks in current zone. */
      if exists (select *
                 from TaskDetails
                 where (TaskId = @vTaskId) and
                       (Status not in ('C', 'X' /* Completed/Canceled */)))
        set @ConfirmBatchPickMessage = dbo.fn_Messages_Build('PicksCompletedInScannedZone', @PickZone, @PickBatchNo, @vTaskId, default, default);
      else
        set @ConfirmBatchPickMessage = dbo.fn_Messages_Build('BatchPickComplete', @PickZone, @PickBatchNo, @vTaskId, default, default);

      /* Valid Batch Statuses */
      select @vSetBatchStatusToPickedOnNoMoreInv = dbo.fn_Controls_GetAsBoolean('BatchPicking', 'SetBatchStatusToPickedOnNoMoreInv', 'N'/* No */, @BusinessUnit, @UserId);

      /* Set the status of the batch by considering the control variable
         ex for loehmanns if the inventory is not available then we have to mark the batch as Picked, So we will include picked status in control variable
         and in case of topsondowns we will verify the control variable whether the picked status is included in it or not and will pass in the batch status
         as null to Batch set Status procedure, as it will compute the status of the batch and will update the batch status */
      if (@vSetBatchStatusToPickedOnNoMoreInv = 'Y' /* Yes */)
        set @vBatchStatus = 'K' /* Picked */;
      else
        set @vBatchStatus = null;

      /* Update the LPNs Status to Picked once after the Batch Picking is done */
      update LPNs
      set Status = 'K' /* Picked */
      output Deleted.LPNId, Deleted.LPN into @ttPickedLPNs
      where (PalletId = @PickingPalletId) and
            (Status   = 'U' /* Picking */) and
            (Quantity > 0) and
            (LPNId not in (select distinct LPNId from vwLPNDetails where PalletId = @PickingPalletId and OnhandStatus = 'U' /* Unavailable */));

      /* Update the Pallet status to Picked only if all the LPNs on the Pallet are
         in Picked Status */
      if not exists (select *
                     from LPNs
                     where (PalletId = @PickingPalletId) and
                           (Quantity > 0               ) and
                           (Status <> 'K'/* Picked */ ))
        exec pr_Pallets_SetStatus @PickingPalletId, 'K' /* Picked */, @UserId;

      /* Updating Status for Batch if the picking is Complete for the Batch */
      exec pr_PickBatch_SetStatus @PickBatchNo, @vBatchStatus, @UserId, @PickBatchId output;

      /* if there are any LPNs are updated as marked then we need to export them */
      if (exists (select * from @ttPickedLPNs))
        begin
          exec pr_Picking_ExportDataOnLPNPicked @PickBatchId, null /* LPNId */, @ttPickedLPNs,
                                                @BusinessUnit, @UserId;
        end

      /* Log the Audit Trail once after the Batch is Picked */
      exec pr_AuditTrail_Insert 'PickBatchCompleted', @UserId, null /* ActivityTimestamp */,
                                @PickBatchId = @PickBatchId,
                                @PalletId    = @PickingPalletId;

      set @xmlResult = (select 0                        as ErrorNumber,
                               @ConfirmBatchPickMessage as ErrorMessage
                        FOR XML RAW('BATCHPICKINFO'), TYPE, ELEMENTS XSINIL, ROOT('BATCHPICKDETAILS'));
    end

  /* Save Device State */
  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, @ActivityType, @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;--, @vNote1, @vNote2;

  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;

end try
begin catch
  /* Handling transactions in case if it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_ConfirmBatchPick_2 */

Go
