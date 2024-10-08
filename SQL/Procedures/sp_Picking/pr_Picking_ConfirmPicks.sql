/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/03/16  RKC     pr_Picking_ConfirmPicks: Added coalesce value for Lot field to update not null value (BK-759)
  2021/03/02  RKC     pr_Picking_OnPicked, pr_Picking_ConfirmPicks: Made changes to update the TaskId on the picked LPNs (HA-2105)
  2021/02/17  TK      pr_Picking_BatchPickResponse & pr_Picking_ConfirmPicks:
  2021/02/10  TK      pr_Picking_ConfirmPicks: Changes to update picked by  if there are multiple picks received in single transaction (CID-1704)
  2020/12/29  AY      pr_Picking_ConfirmPicksAsShort, pr_Picking_ShortPickLPN: Use reason codes from control var (HA-1837)
  2020/11/30  TK      pr_Picking_ConfirmPicksAsShort: Initial Revision (CID-1545)
  2020/11/27  VS      pr_Picking_ConfirmPicks_LogAuditTrail: Corrected the Wave level Activity (HA-1684)
  2020/11/11  MS      pr_Picking_ConfirmPicks: Bug fix for Datatype conversion error (HA-1414)
              TK      pr_Picking_ConfirmPicks: Changes to export pick transactions while picking (HA-1516)
  2020/10/15  TK      pr_Picking_ConfirmPicks: Bug fix to initialize ToLPNDetailId during partial picking (HA-1572)
                      pr_Picking_ConfirmPicks_LogAuditTrail: Code to insert entries into audit details (CIMS-2967)
  2020/06/10  TK      pr_Picking_ConfirmPicks: Update InventoryClass on Picked LPNs (HA-880)
  2019/08/19  TK      pr_Picking_ConfirmPicks: Changes to consolidate picks in destnination LPN (CID-281)
  2019/08/14  VS      pr_Picking_ConfirmPicks: While picking if label is generated updating.ReservedQty updated as Quantity (CID-941)
  2019/04/12  TK      pr_Picking_ConfirmPicks: Changes to update Wave info on picked LPNs (S2GCA-591)
  2019/04/11  TK      pr_Picking_ConfirmPicks: Changes to split task detail on partial picking (S2GCA-590)
  2019/03/22  TK      pr_Picking_ConfirmPicks: Changes to update From LPNOwnership on Picked LPNs
  2019/02/20  TK      pr_Picking_ConfirmTaskPicks renamed to pr_Picking_ConfirmPicks
                      pr_Picking_ConfirmTaskPicks_LogAuditTrail renamed to pr_Picking_ConfirmPicks_LogAuditTrail (S2GCA-469)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ConfirmPicks') is not null
  drop Procedure pr_Picking_ConfirmPicks;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_ConfirmPicks:
    The intent of this core procedure that could be used to accomplish picking in different scenarios.
    The scope of this procedure is for Unit Picks only to begin with and MAY be expanded later.

  Assumptions therefore are:
    - From LPN would always have a reserved line.
    - Task Detail would always be present. To LPN may always exist when it comes here (either temp label or cart pos).
    - Task is allocated

  RecordAction:
    ERR_FromLPNQtyLess        - From LPN Qty is Less than Qty Picked
    ERR_TDQtyLess             - Task Detail Qty Less than Qty Picked
    ERR_TLQtyLess             - Temp label Qty Less than QTy Picked
    PROCESS                   - Process on success
    ERR_ErrorOnFromLPNOrToLPN - Either an error on FromLPNAction or ToLPNAction
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_ConfirmPicks
  (@TaskPicksInfo    TTaskDetailsInfoTable READONLY,
   @Operation        TDescription,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @Debug            TFlags = null)
As
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,

          @vPalletId            TRecordId,
          @vPickBatchNo         TPickBatchNo,

          @vWaveId              TRecordId,
          @vWaveNo              TPickBatchNo,
          @vOrderId             TRecordId,
          @vOrderType           TTypeCode,
          @vOrderDetailId       TRecordId,

          @vFromLocation        TLocation,
          @vFromLPNId           TRecordId,
          @vFromLPNDetailId     TRecordId,
          @vFromLDUnitsPerPackage
                                TUnitsPerPack,
          @vPickedSKUId         TRecordId,
          @vPickedQty           TQuantity,
          @vPickedIPs           TInnerPacks,
          @vPickedBy            TUserId,

          @vToLPNId             TRecordId,
          @vToLPNDetailId       TRecordId,
          @vCoO                 TCoO /* This the CoO which is sent from @TaskPicksInfo */,
          @vToLPNDtlIPs         TInnerpacks,
          @vToLPNDtlQty         TQuantity,
          @vToLPNNewDetailId    TRecordId,
          @vToLPNNewStatus      TStatus,
          @vLPNDetailIdToUpdate TRecordId,

          @vIsLabelGenerated    TFlags,

          @vPickType            TTypeCode,
          @vTaskDetailId        TRecordId,
          @vTaskId              TRecordId,
          @vNewTaskDetailId     TRecordId,
          @vTDInnerPacks        TInnerpacks,
          @vTDQuantity          TQuantity,
          @vSplitIPs            TInnerpacks,
          @vSplitQty            TQuantity,

          @vRecalcWave          TFlags,
          @vRecalcOrder         TFlags,

          @vRecordId            TRecordId,
          @vActivityDate        TDateTime,
          @vDebug               TFlags,
          @vTranCount           TCount,
          @vActivityLogId       TRecordId,
          @vXMLData             TXML,
          @vXMLResult           TXML,
          @xmlRulesData         TXML,
          @vExportToHost        TResult;

  declare @ttTaskPicksInfo      TTaskDetailsInfoTable,
          @ttFromLPNs           TRecountKeysTable,
          @ttTasks              TRecountKeysTable;
begin
  /* We would want to first do basic validations i..e
     . to make sure that the From LPN details match i.e. Qty >= the Units picked,
     . the task details match the units (Qty >= units picked) and the ToLPN (if one exists) has units to confirm.
     We can have a validation procedure with the given inputs

     When a pick is confirmed, the changes that should happen are
     a. deduct the inventory from the From LPN
     b. we have to mark the task detail as completed or in progress.
     c. if To LPN is not already generated, then add the lines to the ToLPN and if generated, then flip the lines' onhand status from U to R
  */
  SET NOCOUNT ON;

  /* ------------------------------------------------------------------------*/
  /* Initialization */
  /* ------------------------------------------------------------------------*/
  select @vReturnCode      = 0,
         @vMessageName     = null,
         @vRecordId        = 0,
         @vActivityDate    = current_timestamp,
         @vFromLPNDetailId = 0,
         @vToLPNDetailId   = 0,
         @vTranCount       = @@trancount;

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;
  select @vDebug = coalesce(@Debug, @vDebug);

begin try
  if (@vTranCount = 0) begin transaction;

  /* Activity Log */
  if (charindex('L', @vDebug) > 0)
    begin
      select @vxmlData = (select * from @TaskPicksInfo for XML raw('TaskPicksInfo'), elements );
      exec pr_ActivityLog_AddMessage 'ConfirmTaskPicks_Inputs', null, null, 'TaskDetails',
                                     'Inputs' /* Message */, @@ProcId, @vxmlData, @BusinessUnit, @UserId;
    end

  /* ------------------------------------------------------------------------*/
  /* Validations */
  /* ------------------------------------------------------------------------*/

  /* Validate inputs: make sure whatever the passed in info matches with its related Task detail */
  if (exists(select * from @TaskPicksInfo TPI
               join TaskDetails TD on (TD.TaskDetailId   = TPI.TaskDetailId) and (TD.Status not in ('X' /* Canceled */, 'C' /* Completed */))
             where (coalesce(TPI.PickBatchNo,     TD.PickBatchNo,   '') <> coalesce(TD.PickBatchNo,   '')) or
                   (coalesce(TPI.OrderId,         TD.OrderId,       '') <> coalesce(TD.OrderId,       '')) or
                   (coalesce(TPI.OrderDetailId,   TD.OrderDetailId, '') <> coalesce(TD.OrderDetailId, '')) or
                   (coalesce(TPI.FromLPNId,       TD.LPNId,         '') <> coalesce(TD.LPNId,         '')) or
                   (coalesce(TPI.FromLPNDetailId, TD.LPNDetailId,   '') <> coalesce(TD.LPNDetailId,   '')) or
                   (coalesce(TPI.SKUId,           TD.SKUId,         '') <> coalesce(TD.SKUId,         '')) or
                   (coalesce(TPI.FromLocationId,  TD.LocationId,    '') <> coalesce(TD.LocationId,    '')) or
                   ((TD.IsLabelGenerated = 'Y' /* Yes */) and
                    (coalesce(TPI.ToLPNId,        TD.TempLabelId)       <> TD.TempLabelId))))
    select @vMessageName = 'ConfirmTaskPicks_MismatchInput';

  if (charindex('D', @vDebug) > 0)
    select TPI.PickBatchNo, TD.PickBatchNo, TPI.OrderId, TD.OrderId, TPI.OrderDetailId, TD.OrderDetailId,
           TPI.FromLPNId, TD.LPNId, TPI.FromLPNDetailId, TD.LPNDetailId, TPI.SKUId, TD.SKUId, TPI.FromLocationId, TD.LocationId, TPI.ToLPNId, TD.TempLabelId, TPI.CoO
    from @TaskPicksInfo TPI
      join TaskDetails TD  on (TD.TaskDetailId   = TPI.TaskDetailId) and (TD.Status not in ('X' /* Canceled */, 'C' /* Completed */))

  if (@vMessageName is not null) goto ErrorHandler;

  /* Input temp table may not have all the required information for processing.
     At the least it would have - TaskDetailId, ToLPNId and QtyPicked */
  insert into @ttTaskPicksInfo (TaskDetailId, TaskId, PickType, PickBatchId, PickBatchNo, OrderId, PickTicket, OrderDetailId,
                                FromLocationId, FromLocation, FromLPNId, FromLPN, FromLPNOwnership, FromLPNWarehouse,
                                FromLPNInventoryClass1, FromLPNInventoryClass2, FromLPNInventoryClass3,
                                FromLPNDetailId, FromLDOnhandStatus, FromLDQuantity, FromLDUnitsPerPackage,
                                SKUId, SKU, TDInnerPacks, TDQuantity,
                                PalletId, Pallet,
                                IsLabelGenerated, ToLPNId, ToLPN,
                                ToLPNDtlId, ToLPNDtlQty, CoO, QtyPicked, PickedBy,
                                ActivityType)
    select TPI.TaskDetailId, TD.TaskId, TD.PickType, OH.PickBatchId, TD.PickBatchNo, TD.OrderId,  OH.PickTicket, TD.OrderDetailId,
           -- It is possible for caller to pass in different From Location/LPN/LPNDetail than what is in TD, so use given values if passed in
           coalesce(TPI.FromLocationId, TD.LocationId), Loc.Location, coalesce(TPI.FromLPNId, TD.LPNId), coalesce(TPI.FromLPN, FL.LPN), FL.Ownership,
           FL.DestWarehouse, FL.InventoryClass1, FL.InventoryClass2, FL.InventoryClass3,
           coalesce(TPI.FromLPNDetailId, TD.LPNDetailId), FLD.OnhandStatus, FLD.Quantity, FLD.UnitsPerPackage,
           coalesce(TPI.SKUId, TD.SKUId), S.SKU, TD.InnerPacks, TD.Quantity,
           coalesce(TPI.PalletId, P.PalletId, TD.PalletId), coalesce(TPI.Pallet, P.Pallet),
           TD.IsLabelGenerated, coalesce(TPI.ToLPNId, TLD.LPNId, TL.LPNId), coalesce(TPI.ToLPN, TL.LPN),
           TLD.LPNDetailId, TLD.Quantity, TPI.CoO, TPI.QtyPicked, coalesce(TPI.PickedBy, @UserId),
           case when TD.PickType = 'U' then 'UnitPick'
                when TD.PickType = 'L' then 'LPNPick'
                else 'UnitPick'
           end /* ActivityType */
    from @TaskPicksInfo TPI
           join TaskDetails  TD  on (TD.TaskDetailId   = TPI.TaskDetailId) and (TD.Status not in ('X' /* Canceled */, 'C' /* Completed */))
           -- From LPNDetail
           join LPNDetails   FLD on (FLD.LPNDetailId   = coalesce(TPI.FromLPNDetailId, TD.LPNDetailId))
           join LPNs         FL  on (FLD.LPNId         = FL.LPNId)
           -- To LPNDetail, may or may not exist
      left join LPNDetails   TLD on (TLD.LPNId         = coalesce(TPI.ToLPNId, TD.TempLabelId))   and
                                    (TLD.LPNDetailId   = TD.TempLabelDetailId) and --Same Order Detail id may be repeated twice
                                    (TLD.OrderDetailId = TD.OrderDetailId) and
                                    (TLD.Onhandstatus  = 'U' /* Unavailable */) -- could there be multiple with same order detail?
      left join LPNs         TL  on (TL.LPNId          = coalesce(TPI.ToLPNId, TD.TempLabelId))
      left join Pallets      P   on (P.PalletId        = coalesce(TPI.PalletId, TL.PalletId, TD.PalletId))
      left join Locations    Loc on (Loc.LocationId    = coalesce(TPI.FromLocationId, TD.LocationId))
           join OrderHeaders OH  on (OH.OrderId        = TD.OrderId)
           join SKUs         S   on (S.SKUId           = coalesce(TPI.SKUId, TD.SKUId));

  if (charindex('D', @vDebug) > 0) select 'TaskPicksInfoStart' Message, * from @ttTaskPicksInfo;

  /* Activity Log */
  if (charindex('L', @vDebug) > 0)
    begin
      select @vxmlData = (select * from @ttTaskPicksInfo for XML raw('TaskPicksInfo'), elements );
      exec pr_ActivityLog_AddMessage 'ConfirmTaskPicks_BuiltInfo', null, null, 'TaskDetails',
                                     'BuiltInfo' /* Message */, @@ProcId, @vxmlData, @BusinessUnit, @UserId;
    end

  /* ------------------------------------------------------------------------*/
  /* Validations */
  /* ------------------------------------------------------------------------*/

  /* Validate QtyPicked in relation to FromLPN, ToLPN and Task Detail */
  update @ttTaskPicksInfo
  set RecordAction = case
                       /* Make sure From LPN details are in Reserved */
                       when (FromLDOnhandStatus <> 'R' /* Reserved */) then 'ERR_FromLPNLineUnreserved'
                       /* Make sure From LPN details Qty match */
                       when (FromLDQuantity < QtyPicked)               then 'ERR_FromLPNQtyLess'
                       /* Make sure Task Details Qty match */
                       when (TDQuantity < QtyPicked)                   then 'ERR_TDQtyLess'
                       /* Make sure, if TempLabel exists has enough units to confirm */
                       when (IsLabelGenerated = 'Y' /* Yes */) and
                            (ToLPNDtlQty < QtyPicked) then 'ERR_TLQtyLess'
                     else
                       'PROCESS'
                     end;

  if (charindex('D', @vDebug) > 0) select 'Errors' Message, * from @ttTaskPicksInfo where RecordAction like 'ERR_%';

  /* ------------------------------------------------------------------------*/
  /* Determine action to take on From LPN and To LPN. Earlier, when entire line was getting picked, we would
     transfer the line from FROM_LPN to TO_LPN. However, it could be that the FromLPN has the qty in eached
     but we would like it to be representd in IPs in ToLPN and hence instead of transferring lines, we are
     starting to decrement on FromLPN and increment on ToLPN to keep it simple */
  /* ------------------------------------------------------------------------*/
  update @ttTaskPicksInfo
  set FromLPNAction     = case
                            /* If partial qty picking, then we need to adjust it down */
                            when (QtyPicked < FromLDQuantity) then 'Qty_AdjustDown'
                            /* If full qty picking, but temp label (pre-generated) exists, then also adjust down */
                            when (IsLabelGenerated = 'Y' /* Yes */) and (QtyPicked = FromLDQuantity) then 'Qty_AdjustDown'
                            /* if picking to a new label (not pre-generated) or cart then adjust down the quantity */
                            when (IsLabelGenerated in ('N' /* No */, 'NR' /* Not Required */)) then 'Qty_AdjustDown'
                          else
                            'ERR_UnableToAdjustFromLPN'
                          end,
      ToLPNAction       = case
                            /* If full qty picking, but temp label (pre-generated) exists, then change OnhandStatus */
                            when (IsLabelGenerated = 'Y' /* Yes */) and (QtyPicked = ToLPNDtlQty) then 'OnhandStatus_Change' /* (U)navailable to (R)eserved */
                            /* If partial qty picking, but temp label (pre-generated) exists, then we need to split line */
                            when (IsLabelGenerated = 'Y' /* Yes */) and (QtyPicked < ToLPNDtlQty) then 'Line_Split'
                            /* Even though it is efficient way to transfer the line, this is not the right way to do it or understand it,
                               so decrement the quantity from source LPN and increment the qty in dest LPN */
                            --/* if picking to a new label (not pre-generated) or cart and complete From LPN Qty picked then transfer the line to ToLPN */
                            --when (IsLabelGenerated in ('N' /* No */, 'NR' /* Not Required */)) and (QtyPicked = FromLDQuantity) then 'Line_Xfer'
                            /* if picking to a new label (not pre-generated) or cart but partical Qty picked then add a line to ToLPN */
                            when (IsLabelGenerated in ('N' /* No */, 'NR' /* Not Required */)) then 'Line_AddOrUpdate'
                          else
                            'ERR_UnableToUpdateTempOrToLPN'
                          end
  where (RecordAction = 'PROCESS');

  /* If there are any errors in on any one of FromLPN or ToLPN action, update other action as well as error */
  update @ttTaskPicksInfo
  set FromLPNAction = case when (ToLPNAction like 'ERR_%')   then 'ERR_OnToLPN' + ' & ' + FromLPNAction else FromLPNAction end,
      ToLPNAction   = case when (FromLPNAction like 'ERR_%') then 'ERR_OnFromLPN' + ' & ' + ToLPNAction else ToLPNAction   end,
      RecordAction  = 'ERR_ErrorOnFromLPNOrToLPN'
  where (FromLPNAction like 'ERR_%') or (ToLPNAction like 'ERR_%');

  if (charindex('D', @vDebug) > 0) select 'Errors' Message, * from @ttTaskPicksInfo where RecordAction like 'ERR_%';

  /* ------------------------------------------------------------------------*/
  /* Validations */
  /* ------------------------------------------------------------------------*/
  if (select count(*) from @TaskPicksInfo) <> (select count(*) from @ttTaskPicksInfo)
    select @vMessageName = 'ConfirmTaskPicks_InvalidInput'
  else
  if (exists (select * from @ttTaskPicksInfo where (RecordAction like 'ERR_%')))
    select @vMessageName = 'ConfirmTaskPicks_Errors';

  if (@vMessageName is not null) goto ErrorHandler;

  if (charindex('D', @vDebug) > 0) select 'Actions' Message, * from @ttTaskPicksInfo;

  /* ------------------------------------------------------------------------*/
  /* FromLPN Updates */
  /* ------------------------------------------------------------------------*/

  /* From LPN: if picking partial quantity then
     - summarize all lines by FromLPNDetailId, QtyPicked and loop thru and then update each FromLPN */
  while (exists(select * from @ttTaskPicksInfo
                where (FromLPNAction = 'Qty_AdjustDown') and (FromLPNDetailId > @vFromLPNDetailId)))
    begin
      select top 1
             @vFromLPNId       = FromLPNId,
             @vFromLPNDetailId = FromLPNDetailId,
             @vPickedSKUId     = SKUId,
             @vPickedQty       = sum(QtyPicked),
             @vPickedBy        = min(PickedBy)
      from @ttTaskPicksInfo
      where (FromLPNAction = 'Qty_AdjustDown') and (FromLPNDetailId > @vFromLPNDetailId)
      group by FromLPNId, FromLPNDetailId, SKUId
      order by FromLPNDetailId;

      exec @vReturnCode = pr_LPNs_AdjustQty @vFromLPNId,
                                            @vFromLPNDetailId,
                                            @vPickedSKUId,
                                            null,
                                            null,
                                            @vPickedQty,   /* Quantity to Adjust */
                                            '-', /* Subtract Qty */
                                            'N', /* Export Option */
                                            0    /* Reason Code */,
                                            null /* Reference */,
                                            @BusinessUnit,
                                            @vPickedBy;
    end

  /* Reset used fields for safety measure as we are using few of them in multiple places */
  select @vRecordId = 0, @vFromLPNId = null, @vFromLPNDetailId = 0, @vPickedSKUId = null, @vPickedQty = null;

  /* ------------------------------------------------------------------------ */
  /* Temp/To LPN Updates */
  /* ------------------------------------------------------------------------ */
  while (exists(select * from @ttTaskPicksInfo
                where (ToLPNAction = 'OnhandStatus_Change') and (ToLPNDtlId > @vToLPNDetailId)))
    begin
      select @vLPNDetailIdToUpdate = null, @vToLPNDtlIPs = null, @vToLPNDtlQty = null;

      select top 1
             @vToLPNId               = ToLPNId,
             @vToLPNDetailId         = ToLPNDtlId,
             @vPickedSKUId           = SKUId,
             @vCoO                   = CoO,
             @vOrderId               = OrderId,
             @vOrderDetailId         = OrderDetailId,
             @vTaskDetailId          = TaskDetailId,
             @vTDInnerPacks          = TDInnerpacks,
             @vTDQuantity            = TDQuantity,
             @vFromLocation          = FromLocation,
             @vFromLDUnitsPerPackage = FromLDUnitsPerPackage,
             @vPickedQty             = QtyPicked,
             @vPickedBy              = PickedBy
      from @ttTaskPicksInfo
      where (ToLPNAction = 'OnhandStatus_Change') and (ToLPNDtlId > @vToLPNDetailId)
      order by ToLPNDtlId;

      /* Calculate InnerPacks to pick from units to pick and units per package */
      if (coalesce(@vFromLDUnitsPerPackage, 0) > 0) and ((@vPickedQty % @vFromLDUnitsPerPackage) = 0) /* Update InnerPacks on ToLPN when multiples of units per package */
        select @vPickedIPs = @vPickedQty / @vFromLDUnitsPerPackage;

      /* Find out LPN Detail to update */
      exec pr_LPNDetails_FindLDToUpdate @vToLPNId, 'R'/* OnHandStatus */, @vCoO, @vPickedSKUId, @vOrderId, @vOrderDetailId,
                                        @vFromLDUnitsPerPackage, @vPickedIPs, @vPickedQty,
                                        @vLPNDetailIdToUpdate output, @vToLPNDtlIPs output, @vToLPNDtlQty output;

      /* If there exists an Temp LPN detail for same order detail then just add picked quantity
         to the existing Temp LPN detail */
      if (@vLPNDetailIdToUpdate is not null)
        begin
          update LPNDetails
          set Quantity         += @vPickedQty,
              Innerpacks       += coalesce(@vPickedIPs, 0),
              ReservedQty      += @vPickedQty,
              ReferenceLocation = substring(dbo.fn_AppendStringValue(ReferenceLocation, @vFromLocation, ','), 1, 50),
              CoO               = @vCoO,
              Lot               = coalesce(@vCoO,  ''),
              PickedBy          = @vPickedBy,
              PickedDate        = @vActivityDate
          where (LPNDetailId = @vLPNDetailIdToUpdate);

          /* since the picked quantity has been updated to Temp LPN detail that is picked earlier
             the original Temp LPN detail should be deleted here */
          exec pr_LPNDetails_Delete @vToLPNDetailId;
        end
      /* If there no Temp LPN detail found to update then just change the OnhandStatus on the LPN detail to reserved */
      else
        update LPNDetails
        set OnhandStatus      = 'R', /* Reserved */
            ReservedQty       = Quantity,
            ReferenceLocation = substring(dbo.fn_AppendStringValue(ReferenceLocation, @vFromLocation, ','), 1, 50),
            CoO               = @vCoO,
            Lot               = coalesce(@vCoO,  ''),
            PickedBy          = @vPickedBy,
            PickedDate        = @vActivityDate
        where (LPNDetailId = @vToLPNDetailId);
    end /* end - OnhandStatus_Change */

  /* Reset used fields for safety measure as we are using few of them in multiple places */
  select @vRecordId = 0, @vFromLPNId = null, @vFromLPNDetailId = 0, @vPickedSKUId = null, @vPickedQty = null,
         @vToLPNDetailId = 0, @vOrderId = null, @vOrderDetailId = null, @vFromLocation = null,
         @vToLPNNewDetailId = null, @vLPNDetailIdToUpdate = null;

  /* TempLabel LPN: If partial qty picking, then we need to split line */
  while (exists(select * from @ttTaskPicksInfo
                where (ToLPNAction = 'Line_Split') and (ToLPNDtlId > @vToLPNDetailId)))
    begin
      select top 1
             @vToLPNId               = ToLPNId,
             @vToLPNDetailId         = ToLPNDtlId,
             @vPickedSKUId           = SKUId,
             @vCoO                   = CoO,
             @vOrderId               = OrderId,
             @vOrderDetailId         = OrderDetailId,
             @vTaskDetailId          = TaskDetailId,
             @vTDInnerPacks          = TDInnerpacks,
             @vTDQuantity            = TDQuantity,
             @vFromLocation          = FromLocation,
             @vFromLDUnitsPerPackage = FromLDUnitsPerPackage,
             @vPickedQty             = QtyPicked,
             @vPickedBy              = PickedBy
      from @ttTaskPicksInfo
      where (ToLPNAction = 'Line_Split') and (ToLPNDtlId > @vToLPNDetailId)
      order by ToLPNDtlId;

      /* Calculate InnerPacks to pick from units to pick and units per package */
      if (coalesce(@vFromLDUnitsPerPackage, 0) > 0) and ((@vPickedQty % @vFromLDUnitsPerPackage) = 0) /* Update InnerPacks on ToLPN when multiples of units per package */
        select @vPickedIPs = @vPickedQty / @vFromLDUnitsPerPackage;

      /* Compute Qty to split */
      select @vSplitQty = @vTDQuantity - @vPickedQty,
             @vSplitIPs = @vTDInnerPacks - @vPickedIPs;

      /* Split Task Detail and its associated LPN Detail */
      exec pr_TaskDetails_SplitDetail @vTaskDetailId, @vSplitIPs, @vSplitQty,
                                      'ConfirmPicks' /* Operation */, @BusinessUnit, @vPickedBy,
                                      @vNewTaskDetailId output;

      /* Find out LPN Detail to update */
      exec pr_LPNDetails_FindLDToUpdate @vToLPNId, 'R'/* OnHandStatus */, @vCoO, @vPickedSKUId, @vOrderId, @vOrderDetailId,
                                        @vFromLDUnitsPerPackage, @vPickedIPs, @vPickedQty,
                                        @vLPNDetailIdToUpdate output, @vToLPNDtlIPs output, @vToLPNDtlQty output;

      /* If there exists an Temp LPN detail for same order detail then just add picked quantity
         to the existing Temp LPN detail */
      if (@vLPNDetailIdToUpdate is not null)
        begin
          update LPNDetails
          set Quantity         += @vPickedQty,
              Innerpacks       += coalesce(@vPickedIPs, 0),
              ReservedQty      += @vPickedQty,
              ReferenceLocation = substring(dbo.fn_AppendStringValue(ReferenceLocation, @vFromLocation, ','), 1, 50),
              CoO               = @vCoO,
              Lot               = coalesce(@vCoO, ''),
              PickedBy          = @vPickedBy,
              PickedDate        = @vActivityDate
          where (LPNDetailId    = @vLPNDetailIdToUpdate);

          /* since the picked quantity has been updated to Temp LPN detail that is picked earlier
             the original Temp LPN detail should be deleted here */
          exec pr_LPNDetails_Delete @vToLPNDetailId;
        end
      /* If there no Temp LPN detail found to update then just change the OnhandStatus on the LPN detail to reserved */
      else
        update LPNDetails
        set OnhandStatus      = 'R',
            ReservedQty       = Quantity,
            ReferenceLocation = substring(dbo.fn_AppendStringValue(ReferenceLocation, @vFromLocation, ','), 1, 50),
            CoO               = @vCoO,
            Lot               = coalesce(@vCoO, ''),
            PickedBy          = @vPickedBy,
            PickedDate        = @vActivityDate
        where (LPNDetailId    = @vToLPNDetailId);
    end /* end - Line_Split */

  /* Reset used fields for safety measure as we are using few of them in multiple places */
  select @vRecordId = 0, @vFromLPNId = null, @vFromLPNDetailId = 0, @vPickedSKUId = null, @vPickedQty = null,
         @vToLPNDetailId = null, @vOrderId = null, @vOrderDetailId = null, @vFromLocation = null,
         @vToLPNNewDetailId = null, @vLPNDetailIdToUpdate = null;

  /* To LPN: if picking to a new label (not pre-generated) or cart and complete From LPN Qty picked then
       - transfer the line to ToLPN */
  /* We do not need to do it on ToLPN as while FromLPN 'Line_Xfer', ToLPN should be getting lines already */

  /* To LPN: if picking to a new label (not pre-generated) or cart but partial Qty picked then
       - add a line to ToLPN */
  while (exists (select * from @ttTaskPicksInfo
                 where (ToLPNAction = 'Line_AddOrUpdate') and (RecordId > @vRecordId)))
    begin
      select top 1
             @vToLPNId               = ToLPNId,
             @vCoO                   = CoO,
             @vPickedSKUId           = SKUId,
             @vPickedQty             = QtyPicked,
             @vOrderId               = OrderId,
             @vOrderDetailId         = OrderDetailId,
             @vFromLocation          = FromLocation,
             @vFromLDUnitsPerPackage = FromLDUnitsPerPackage,
             @vRecordId              = RecordId
      from @ttTaskPicksInfo
      where (ToLPNAction = 'Line_AddOrUpdate') and (RecordId > @vRecordId)
      order by RecordId;

      /* Calculate InnerPacks to pick from units to pick and units per package */
      if (coalesce(@vFromLDUnitsPerPackage, 0) > 0) and ((@vPickedQty % @vFromLDUnitsPerPackage) = 0) /* Update InnerPacks on ToLPN when multiples of units per package */
        select @vPickedIPs = @vPickedQty / @vFromLDUnitsPerPackage;

      /* Find out LPN Detail to update */
      exec pr_LPNDetails_FindLDToUpdate @vToLPNId, 'R'/* OnhandStatus */, @vCoO, @vPickedSKUId, @vOrderId, @vOrderDetailId,
                                        @vFromLDUnitsPerPackage, @vPickedIPs, @vPickedQty,
                                        @vToLPNDetailId output, @vToLPNDtlIPs output, @vToLPNDtlQty output;

      /* Compute quantities */
      select @vToLPNDtlQty = coalesce(@vToLPNDtlQty, 0) + @vPickedQty,
             @vToLPNDtlIPs = coalesce(@vToLPNDtlIPs, 0) + @vPickedIPs;

      /* Add a new LPN Detail for the picked  units to the ToLPN */
      exec pr_LPNDetails_AddOrUpdate @vToLPNId,
                                     null,                      /* LPNLine */
                                     @vCoO,                     /* CoO */
                                     @vPickedSKUId,             /* SKUId */
                                     null,                      /* SKU */
                                     @vToLPNDtlIPs,             /* InnerPacks */
                                     @vToLPNDtlQty,             /* Quantity */
                                     null,                      /* ReceivedUnits */
                                     null,                      /* ReceiptId */
                                     null,                      /* ReceiptDetailId */
                                     @vOrderId,                 /* OrderId */
                                     @vOrderDetailId,           /* OrderDetailId */
                                     null,                      /* OnHandStatus */
                                     null,                      /* Operation */
                                     null,                      /* Weight */
                                     null,                      /* Volume */
                                     @vCoO,                     /* Lot - Updating with CoO */
                                     @BusinessUnit,
                                     @vToLPNDetailId  output;

      /* Here we are updating the Ref location (Picked from location) for future ref.. if the batch is picked incorrectly. */
      update LPNDetails
      set ReferenceLocation = @vFromLocation,
          PickedBy          = @vPickedBy,
          PickedDate        = @vActivityDate
      where (LPNDetailId = @vToLPNDetailId);
    end /* end - Line_AddOrUpdate */

  /* Reset used fields for safety measure as we are using few of them in multiple places */
  select @vRecordId = 0, @vFromLPNId = null, @vFromLPNDetailId = 0, @vPickedSKUId = null, @vPickedQty = null,
         @vToLPNDetailId = null, @vOrderId = null, @vOrderDetailId = null, @vFromLocation = null,
         @vToLPNNewDetailId = null, @vToLPNId = null;

  /* Update Ownership on ToLPN from FromLPN */
  update L
  set L.PickBatchId     = TPI.PickBatchId,
      L.PickBatchNo     = TPI.PickBatchNo,
      L.Ownership       = TPI.FromLPNOwnership,
      L.DestWarehouse   = TPI.FromLPNWarehouse,
      L.InventoryClass1 = TPI.FromLPNInventoryClass1,
      L.InventoryClass2 = TPI.FromLPNInventoryClass2,
      L.InventoryClass3 = TPI.FromLPNInventoryClass3,
      L.PackingGroup    = OD.PackingGroup,
      L.TaskId          = case when OH.OrderType = 'T' then TPI.TaskId else L.TaskId end
  from LPNs L
               join @ttTaskPicksInfo TPI on (L.LPNId          = TPI.ToLPNId)
    left outer join OrderDetails     OD  on (OD.OrderDetailId = TPI.OrderDetailId)
    left outer join OrderHeaders     OH  on (OH.OrderId       = OD.OrderId);

  /* ------------------------------------------------------------------------ */
  /* Update task details */
  /* ------------------------------------------------------------------------ */

  update TD
  set TD.UnitsCompleted       = coalesce(TD.UnitsCompleted, 0) + TLP.QtyPicked,
      TD.InnerpacksCompleted  = case
                                  when TD.PickType = 'CS' then TD.InnerpacksCompleted + (TLP.QtyPicked / TLP.FromLDUnitsPerPackage)
                                  else 0
                                end,
      TD.Status               = Case
                                  when (TD.UnitsToPick = TLP.QtyPicked) then 'C' /* Completed */
                                  when (TLP.QtyPicked > 0) then 'I' /* In Progress */
                                  else TD.Status
                                end,
      TD.PalletId             = TLP.PalletId,
      TD.ModifiedDate         = current_timestamp,
      TD.ModifiedBy           = @vPickedBy
  output inserted.TaskId, 'Task' into @ttTasks (EntityId, EntityType)
  from TaskDetails TD
    join @ttTaskPicksInfo TLP on (TLP.TaskDetailId = TD.TaskDetailId);

  /* Recalculate Tasks */
  exec pr_Tasks_Recalculate @ttTasks, 'S' /* Set (S)tatus */, @UserId;

  /* Reset used fields for safety measure as we are using few of them in multiple places */
  select @vRecordId = 0, @vFromLPNId = null, @vFromLPNDetailId = 0, @vPickedSKUId = null, @vPickedQty = null,
         @vToLPNDetailId = null, @vToLPNDtlQty = null, @vPickBatchNo = null, @vOrderId = null, @vOrderDetailId = null,
         @vPalletId = null, @vFromLocation = null,
         @vToLPNNewDetailId = null, @vToLPNId = null, @vPickType = null, @vTaskDetailId = null;

  /* ------------------------------------------------------------------------ */
  /* Finally, accumulate the ToLPNs updated, OrderId, Waves and call OnPickedToLPN for each ToLPN */
  /* ------------------------------------------------------------------------ */
  while (exists(select * from @ttTaskPicksInfo where ToLPNId > coalesce(@vToLPNId, 0)))
    begin
      select @vRecalcWave = 'N', @vRecalcOrder = 'N';

      select top 1
             @vPickBatchNo      = PickBatchNo,
             @vOrderId          = OrderId,
             @vPalletId         = PalletId,
             @vToLPNId          = ToLPNId,
             @vIsLabelGenerated = min(IsLabelGenerated),
             @vToLPNDtlQty      = sum(ToLPNDtlQty),
             @vPickedQty        = sum(QtyPicked),
             @vPickedBy         = min(PickedBy)
       from @ttTaskPicksInfo
       where (ToLPNId > coalesce(@vToLPNId, 0))
       group by PickBatchNo, OrderId, PalletId, ToLPNId
       order by ToLPNId;

       /* If current wave is last in the loop, set for recalculation of status */
       if (not (exists(select * from @ttTaskPicksInfo where (ToLPNId > @vToLPNId) and (PickBatchNo = @vPickBatchNo))))
         select @vRecalcWave = 'Y' /* Yes */

       /* If current order is last in the loop, set for recalculation of status */
       if (not (exists(select * from @ttTaskPicksInfo where (ToLPNId > @vToLPNId) and (OrderId = @vOrderId))))
         select @vRecalcOrder = 'Y' /* Yes */

       /* Do everything that needs to be done once a Temp/To LPN has been picked */
       exec pr_Picking_OnPickedToLPN @vPickBatchNo, @vOrderId, @vPalletId,
                                     @vToLPNId, null /* LPNStatus */, -- LPN Status will be computed in OnPickedToLPN procedure
                                     @vPickedQty, @vRecalcWave,
                                     @vRecalcOrder, 'UnitPick', -- TODO: This should be decided based on temp/to lpn,
                                     @BusinessUnit, @vPickedBy;
    end

  /* ------------------------------------------------------------------------ */
  /* Export Pick Transactions */
  /* ------------------------------------------------------------------------ */
  select top 1 @vWaveId = PickBatchId,
               @vWaveNo = PickBatchNo
  from @ttTaskPicksInfo;

  /* Prepare XML for rules */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Operation',      'ConfirmPicks')   +
                           dbo.fn_XMLNode('WaveId',         @vWaveId) +
                           dbo.fn_XMLNode('WaveNo',         @vWaveNo));

  exec pr_RuleSets_Evaluate 'OnPicked_ToLPN_ExportToHost', @xmlRulesData, @vExportToHost output;

  /* Export pick transactions during picking, this proc will be invoked to confirm a single pick or to confirm
     multiple picks ss export all picks info at once */
  if (@vExportToHost = 'DuringPicking')
    begin
      /* Build temp table with the Result set of the procedure */
      create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
      exec pr_PrepareHashTable 'Exports', '#ExportRecords';

      /* Generate the transactional changes for all picks */
      insert into #ExportRecords (TransType, TransQty, LPNId, SKUId, LocationId, OrderId, OrderDetailId, Ownership,
                                  InventoryClass1, InventoryClass2, InventoryClass3,
                                  Warehouse, FromLPNId, FromLPN, FromLocationId, FromLocation, CreatedBy)
        /* Generate negative InvCh transactions for the Old SKU or Inventory Class(es) */
        select 'Pick', QtyPicked, ToLPNId, SKUId, FromLocationId, OrderId, OrderDetailId, FromLPNOwnership,
               FromLPNInventoryClass1, FromLPNInventoryClass2, FromLPNInventoryClass3,
               FromLPNWarehouse, FromLPNId, FromLPN, FromLocationId, FromLocation, PickedBy
        from @ttTaskPicksInfo TPI;

      /* Insert Records into Exports table */
      exec pr_Exports_InsertRecords 'Pick', 'LPN' /* TransEntity - LPN */, @BusinessUnit;
    end

  /* ------------------------------------------------------------------------ */
  /* Audit Trail */
  /* ------------------------------------------------------------------------ */
  update @ttTaskPicksInfo
  set ATComment = dbo.fn_Messages_BuildDescription('AT_' + ActivityType, 'ToLPN', ToLPN, 'LPN', ToLPN, 'DisplaySKU', SKU, 'Units', QtyPicked, 'Location', FromLocation, 'PTBatch', PickBatchNo + '/' + PickTicket);

  if (charindex('D', @vDebug) > 0) select 'WithAT' Message, * from @ttTaskPicksInfo;

  exec pr_Picking_ConfirmPicks_LogAuditTrail @ttTaskPicksInfo, @BusinessUnit, @UserId, @Debug;

  /* Activity Log */
  if (charindex('L', @vDebug) > 0)
    begin
      select @vxmlData = (select TD.*
                          from @ttTaskPicksInfo TPI
                            join TaskDetails TD on (TD.TaskDetailId = TPI.TaskDetailId)
                          for XML raw('TaskPicksInfo'), elements );

      /* Log activity */
      exec pr_ActivityLog_AddMessage 'ConfirmTaskPicks_End', null, null, 'TaskDetails',
                                     'AfterConfirmPicks' /* Message */, @@ProcId, @vxmlData, @BusinessUnit, @UserId;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If we have started the transaction then commit */
  if (@vTranCount = 0) commit transaction;
end try
begin catch
  /* If we have started the transaction then rollback, else let caller do it */
  if (@vTranCount = 0) rollback transaction;

  exec pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_ConfirmPicks */

Go
