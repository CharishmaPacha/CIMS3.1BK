/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/10/23  TK      pr_Picking_ConfirmUnitPick: Bug fix in identifying correct from LPNId from task detail (S2GCA-390)
  2018/08/12  TK      pr_Picking_ConfirmUnitPick: Reduce Original UnitsPicked when picking into cart (OB2-549)
                      pr_Picking_ConfirmUnitPick: Bug fix to reduce UnitsToPick (S2G-GoLive)
  2018/06/09  RV      pr_Picking_ConfirmUnitPick: Made changes to update InnerPack while partial cases pick (S2G-913)
  2018/05/20  TK      pr_Picking_ConfirmUnitPick: Changes to update Locations counts after confirm pick (S2G-475)
  2018/05/16  SV/VM   pr_Picking_ConfirmUnitPick: Do not create LPND lines over the ToLPN if the same SKU exists for the same PT (FB-1115)
  2016/07/30  TK      pr_Picking_BatchPickResponse & pr_Picking_ConfirmUnitPick: Changes made to return ToLPN based on the packing group (HPI-380)
  2016/06/30  TK      pr_Picking_ConfirmUnitPick: Remove IsAllocated flag as it is appropriate i,e because temp labels
  2016/04/22  TK      pr_Picking_ConfirmUnitPick: Update counts on the picking pallet appropriately (NBD-407)
  2015/11/07  VM      pr_Picking_ConfirmUnitPick: Allow to pick units from multi-SKU LPNs as well (FB-502)
  2015/08/22  NY      pr_Picking_ConfirmUnitPick: Calculate Pallet counts (SRI-366)
  2015/06/08  TD      pr_Picking_ConfirmUnitPick, pr_Picking_OnPicked: Changes update orderdetails, and other fields
  2015/03/05  VM      pr_Picking_ConfirmUnitPick: Do not transfer LPN detail directly from FromLPN to ToLPN as
  2014/06/08  TD      pr_Picking_ConfirmUnitPick:updating FromLocation, PickedBy, PickedOn on ToLPN.
  2014/06/06  TD      pr_Picking_ConfirmUnitPick:bug fix: updating pallet on LPNs while picking.
                      pr_Picking_ConfirmUnitPick:Changes to update PickBatchNo, DestZone on the ToLPN.
  2014/04/25  TD      pr_Picking_ConfirmUnitPick:Changes to call tasks update temp Label.
                      pr_Picking_ConfirmLPNPick, pr_Picking_ConfirmUnitPick: Moved the logic to the new procedure pr_Picking_OnPicked.
  2013/12/09  TD      pr_Picking_ConfirmUnitPick: pr_Picking_ConfirmLPNPick: Changes to update PickBatchId, PickBatchNo on LPNs.
  2013/11/27  TD      pr_Picking_ConfirmUnitPick: Log the details of Pallet in unitPicking.
  2013/11/18  TD      pr_Picking_ConfirmUnitPick: Update Lcoation coutnts in unitpick.
  2013/11/14  TD      pr_Picking_ConfirmUnitPick:Passing FromLPNId to log Audit Trail.
  2013/11/11  TD      pr_Picking_ConfirmUnitPick:small fix to pass ToLPNDetailId.
                      pr_Picking_ConfirmUnitPick: Fix in loging audit trail.
  2013/10/02  PK      pr_Picking_ConfirmUnitPick: Added TaskId and TaskDetailId params to verify and confirm
  2012/09/06  VM      pr_Picking_ConfirmUnitPick/pr_Picking_ConfirmLPNPick:
  2012/08/30  YA      pr_Picking_ConfirmUnitPick: Add LPN to Load if not already on one.
  2012/07/23  YA      pr_Picking_ConfirmUnitPick: Bug-fix: Update LPNs status based on Order new Status not Old status
  2012/07/19  AY      pr_Picking_ConfirmUnitPick, pr_Picking_ConfirmLPNPick : Modified to
  2012/07/05  PK      pr_Picking_ConfirmUnitPick: Included a check for marking picked LPNs as picked if the Passed Pallet or Pallet on LPN is null.
  2011/12/08  PKS     pr_Picking_ConfirmUnitPick:Variable @FromLocation is added again to update reference location
  2011/11/10  TD      pr_Picking_ConfirmLPNPick and pr_Picking_ConfirmUnitPick:
  2011/10/07  AY      pr_Picking_ConfirmUnitPick: ToLPN is to have similar attributes
  2011/10/07  VM      pr_Picking_ConfirmUnitPick: Create To LPN Details as many as Qty picked - only for Serialized SKUs.
  2011/04/08  VM      pr_Picking_ConfirmUnitPick, pr_Picking_ConfirmLPNPick:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ConfirmUnitPick') is not null
  drop Procedure pr_Picking_ConfirmUnitPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_ConfirmUnitPick: New version to confirm multiple Unit picks at once

  PickingMode: MultipleOrderDetails - We would be confirming multiple unit picks
    at the same time. i.e. all Picks for the same Order to the same ToLPN would all
    be pick confirmed at once.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_ConfirmUnitPick
  (@PickTicket      TPickTicket,
   @OrderDetailId   TRecordId,
   @FromLPN         TLPN,
   @ToLPN           TLPN,
   @SKUIdPicked     TRecordId,
   @UnitsPicked     TInteger,
   @TaskId          TRecordId,
   @TaskDetailId    TRecordId,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @ActivityType    TActivityType = 'UnitPick',
   @PickingPalletId TRecordId     = null,
   @PickingMode     TDescription  = null)
as
  declare @OrderId                 TRecordId,
          /* @OrderDetailId           TRecordId, */
          @FromLPNId               TRecordId,
          @FromLPNBusinessUnit     TBusinessUnit,
          @FromLPNLine             TDetailLine,
          @FromLPNDetailId         TRecordId,
          @FromLPNQuantity         TInteger,
          @vFromLPNUnitsPerPackage TInteger,
          @FromLocationId          TRecordId,
          @FromLocation            TLocation,
          @vFromLocSubType         TTypeCode,
          @vFromLPNType            TTypeCode,
          @vDeleteFromLPNLine      TFlag,
          @vSKUSerialized          TFlag,
          @ToLPNId                 TRecordId,
          @ToLPNBusinessUnit       TBusinessUnit,
          @ToLPNLine               TDetailLine,
          @ToLPNPalletId           TRecordId,
          @ToLPNDetailId           TRecordId,
          @ToLPNQuantity           TInteger,
          @ToLPNType               TTypeCode,
          @ToLPNStatus             TStatus,
          @ToLocationId            TRecordId,
          @vToLPNDetailIPs         TInteger,
          @vToLPNDetailQty         TInteger,
          @vTempLabelId            TRecordId,
          @vTempLPNQty             TQuantity,
          @vNumLPNDetailsToAdd     TInteger,
          @vReturnCode             TInteger,
          @vDefaultDropLocationId  TRecordId,
          @vDefaultDropLocation    TLocation,
          @vFromPalletId           TRecordId,
          @vPickingPalletId        TRecordId,
          @vPackingGroup           TCategory,
          /* Shipments and Load */
          @vLPNShipmentId          TRecordId,
          @vLPNLoadId              TRecordId,
          /* Order */
          @vOrderType              TTypeCode,
          @vOrderStatus            TStatus,
          @vNewOrderStatus         TStatus,
          @vPickBatchId            TRecordId,
          @vPickBatchNo            TPickBatchNo,
          @vOrderWarehouse         TWarehouse,
          /* Activity */
          @ActivityDate            TDatetime,
           /* TaskInfo */
          @vTaskLPNId              TRecordId,
          @vTaskLPNDetailId        TRecordId,
          @vTaskQuantityToPick     TQuantity,
          @vTaskSKUId              TRecordId,
          @vTaskOrderId            TRecordId,
          @vTaskOrderDetailId      TRecordId,
          @vLPNLine                TCount,
          @vIsLabelGenerated       TFlags,
          @vDestZone               TZoneId,
          @vLPNTaskRecordId        TRecordId,
          @vIsTaskAllocated        TFlags,
          @vTaskSubType            TTypeCode,
          /* temp task detail info */
          @vTaskRecordId           TRecordId,
          @vRemQtyToPick           TQuantity,
          @vUnitsToConfirm         TQuantity,
          @vIPsToConfirm           TQuantity,

          /* Controls */
          @vOrderTypesToExportToPanda TFlags,
          @vWarehousesToExportToPanda TFlags,
          @ttOrders                   TEntityKeysTable,

          @ttOrderTaskDetails        TEntityKeysTable;

begin /* pr_Picking_ConfirmUnitsPick */
  select @vDeleteFromLPNLine      = 'Y' /* Yes */,
         @vRemQtyToPick           = 0,
         @vTaskRecordId           = 0,
         @vFromLPNUnitsPerPackage = 0,
         @vToLPNDetailIPs         = 0,
         @vIPsToConfirm           = 0;

  select @OrderId         = OrderId,
         @vOrderType      = OrderType,
         @vPickBatchNo    = PickBatchNo,
         @vOrderStatus    = Status,
         @vOrderWarehouse = Warehouse
  from OrderHeaders
  where (PickTicket   = @PickTicket) and
        (BusinessUnit = @BusinessUnit);

  /* Find OrderDetail to allocate against .. there may be multiple */
  if (@OrderDetailId is null)
    select @OrderDetailId = OrderDetailId
    from vwOrderDetails
    where (OrderId = @OrderId) and
          (SKUId = @SKUIdPicked) and
          (UnitsToAllocate >= @UnitsPicked);

  /* Get PickBatch details here */
  select @vPickBatchId = PickBatchId,
         @vPickBatchNo = PickBatchNo
  from vwPickBatchDetails
  where (OrderDetailId = @OrderDetailId);

  /* Get the LPNId from TaskDetail, Task detail will have accurate from LPNId */
  select @FromLPNId = LPNId
  from TaskDetails
  where (TaskDetailId = @TaskDetailId);

  /* ToLPNBusinessUnit would always be the same as From LPN.

     For an LPN default value for LoadId and ShipmentId are 0, Our condition will fail to update
     the load in below, So that we are making it null if the values of LoadId and ShipmentId on
     LPN is 0 */
  if (@FromLPNId is null)
    select @FromLPNId           = LPNId,
           @FromLPNBusinessUnit = BusinessUnit,
           @ToLPNBusinessUnit   = BusinessUnit,
           @FromLocationId      = LocationId,
           @FromLocation        = Location,
           @vLPNShipmentId      = nullif(ShipmentId, 0),
           @vLPNLoadId          = nullif(LoadId, 0),
           @vFromLPNType        = LPNType,
           @vFromPalletId       = PalletId
    from vwLPNs
    where (LPN          = @FromLPN) and
          (SKUId        = @SKUIdPicked) and
          (BusinessUnit = @BusinessUnit);
  else
    select @FromLPNId           = LPNId,
           @FromLPNBusinessUnit = BusinessUnit,
           @ToLPNBusinessUnit   = BusinessUnit,
           @FromLocationId      = LocationId,
           @FromLocation        = Location,
           @vLPNShipmentId      = nullif(ShipmentId, 0),
           @vLPNLoadId          = nullif(LoadId, 0),
           @vFromLPNType        = LPNType,
           @vFromPalletId       = PalletId
    from vwLPNs
    where (LPNId = @FromLPNId);

  /* VM_20151107 - Changes due to issue found in FB

     The above statement included SKUId in selection as there would be multiple LPNs i.e. same LPN
     for a picklane with multiple SKUs. However, for a regular multi-SKU LPN this causes an obstacle
     as the LPN would not have SKUId, yet we have to identify the LPN. To resolve that the below has
     been added to select the LPN without SKUId for regular LPNs.

     *** We could have added an OR condition (or SKUId is null) in 'SKUId where condtion' above but not to be
         in risk with Ecom orders at FB adding the following. Later, we can do that by removing the below and test rigoursly
  */
  if (@FromLPNId is null)
    select @FromLPNId           = LPNId,
           @FromLPNBusinessUnit = BusinessUnit,
           @ToLPNBusinessUnit   = BusinessUnit,
           @FromLocationId      = LocationId,
           @FromLocation        = Location,
           @vLPNShipmentId      = nullif(ShipmentId, 0),
           @vLPNLoadId          = nullif(LoadId, 0),
           @vFromLPNType        = LPNType,
           @vFromPalletId       = PalletId
    from vwLPNs
    where (LPN          =  @FromLPN) and
          (LPNType      <> 'L' /* Logical */) and
          (BusinessUnit =  @BusinessUnit);

    /* Get Serialized flag for Picked SKU */
    select @vSKUSerialized = Serialized
    from SKUs
    where (SKUId = @SKUIdPicked);

  if (@PickingMode = 'MultipleOrderDetails')
    select @vTaskQuantityToPick = sum(UnitsToPick)
    from TaskDetails
    where (TaskId  = @TaskId      ) and
          (LPNId   = @FromLPNId   ) and
          (OrderId = @OrderId     ) and
          (SKUId   = @SKUIdPicked );

  /* Get Task Header info here */
  select @vIsTaskAllocated = IsTaskAllocated,
         @vTaskSubType     = TaskSubType
  from Tasks
  where (TaskId = @TaskId);

  /* Load all task details here for the give SKU and Order - all open picks */
  insert into @ttOrderTaskDetails(EntityId)
    select TaskDetailId
    from TaskDetails
    where (TaskId    = @TaskId       and
           OrderId   = @OrderId      and
           SKUId     = @SKUIdPicked and
           LPNId     = @FromLPNId    and
           Status in ('N', 'I')) /* New or Inprogress */

  while (exists (select * from @ttOrderTaskDetails where RecordId > @vTaskRecordId) and
                (@UnitsPicked > 0))
    begin
      select top 1 @TaskDetailId  = EntityId,
                   @vTaskRecordId = RecordId
      from @ttOrderTaskDetails
      where (RecordId > @vTaskRecordId)
      order by RecordId;

      /* Get the task info */
      select @vTaskLPNId          = LPNId,
             @vTaskLPNDetailId    = LPNDetailId,
             @vTaskQuantityToPick = UnitsToPick,
             @vTaskSKUId          = SKUId,
             @vTaskOrderId        = OrderId,
             @OrderDetailId       = OrderDetailId, -- We need to override the passed-in OrderDetailId since we are picking multiple details at once
             @vTempLabelId        = TempLabelId,
             @vPickingPalletId    = coalesce(@PickingPalletId, PalletId),
             @vIsLabelGenerated   = IsLabelGenerated,
             @vDestZone           = DestZone,
             @vTaskOrderDetailId  = OrderDetailId
      from TaskDetails
      where (TaskId       = @TaskId) and
            (TaskDetailId = @TaskDetailId);

      /* get minimum qty to allocate */
      select @vUnitsToConfirm = dbo.fn_MinInt(@vTaskQuantityToPick, @UnitsPicked);

      if (@vFromLPNType = 'L' /* Logical */)
        begin
          /* Get Location Sub Type here */
          select @vFromLocSubType = LocationSubType
          from Locations
          where (LocationId = @FromLocationId);

            /* if the location is static Location and the lpn has one line then we
               do not need to delete that line */
            if (@vFromLocSubType = 'S' /* static */) and
               ((select count(*) from LPNDetails where LPNId = @FromLPNId) = 1)
              set @vDeleteFromLPNLine = 'N';
          end

      /* What is this for? sum of ALL unavailable lines? */
      select @vTempLPNQty = sum(Quantity)
      from LPNDetails
      where (LPNId = @vTempLabelId) and
            (OnhandStatus = 'U' /* Un-Available */)

      /* If the user scan each label then we need to get those details, or else we do not need
         to ge the single LPN detail here */
      if (@ToLPN not in ('TaskDetail', 'LocationLPN'))
        begin
          select @ToLPNId       = LPNId,
                 @ToLocationId  = LocationId,
                 @ToLPNType     = LPNType,
                 @ToLPNStatus   = Status,
                 @ToLPNPalletId = PalletId
          from LPNs
          where (LPN = @ToLPN);

          select @ToLPNDetailId = LPNDetailId
          from LPNDetails
          where (LPNId         = @ToLPNId) and
                (OrderDetailId = @OrderDetailId);
        end
      /* if the taskdetail has a temp label already generated and picking in full, then update
         the existing temp labels -we will call this when the user used option as ALL .
         Because some times if the detail has 1 temp label then taskdetail qty and units picked qty is equal,
         at that time we do not need to call this */
      if (@TaskDetailId is not null) and
         (coalesce(@vIsLabelGenerated, 'N' /* No */) = 'Y' /* Yes */) and
         (@vTaskSubType = 'CS' /* Case Pick */)
        begin
          exec pr_Tasks_MarkTempLabelAsPicked @TaskId, @TaskDetailId, 'Picking' /* Operation */,
                                              @ToLPN, 'K' /* Status - Picked */,
                                              'R' /* onHandStatus - Reserved */,
                                              @vPickingPalletId,
                                              @BusinessUnit, @UserId;
        end
      else
      if ((@TaskDetailId is not null) or (@PickingMode = 'MultipleOrderDetails')) and
         (coalesce(@vIsLabelGenerated, 'N' /* No */) = 'Y' /* Yes */)
        begin
          exec pr_Tasks_MarkUnitsAsPicked @TaskId, @TaskDetailId, 'Picking' /* Operation */,
                                            @ToLPN, 'K' /* Status - Picked */,
                                            'R' /* onHandStatus - Reserved */,
                                            @FromLPNId,
                                            @vUnitsToConfirm,
                                            @vPickingPalletId,
                                            @BusinessUnit, @UserId;

        /* reset here the remianing units to pick- user scanned units */
        set @UnitsPicked  = @UnitsPicked - @vUnitsToConfirm;
        end
      else
      /* If the user is picking already allocated inventory, then just move the reserved line
         from the FromLPN to the ToLPN. This can only be done if the user is picking the
         complete units of the taskdetail, if it is a partial pick, then continue to split
         the line
         If the LPN has already templabel generated then we do not need to this */
      if (@TaskDetailId is not null) and
         (@vTaskQuantityToPick = @vUnitsToConfirm) and
         (@vDeleteFromLPNLine = 'Y' /* Yes */) and (@ToLPNType <> 'A' /* Cart - VM_20150305: It should not be only Cart but for other ToLPN types as well. - See below comments */) and
         /* Cont... What is To LPN has already a line with same sku for same orderdetailid, we need to update, right? so we cannot add another line with same SKU
            Hence, I think we should always not do this below. Currently, I am doing it for Carts. Lets talk about others later */
         /* If there is a line of same SKU on ToLPN, Update the same line. So, exclude here */
         (@ToLPNDetailId is null)
        begin
          /* Get the last LPNLine no to update with the next number
             as LPNDetails table has UniqueKey Constraints on it */
          select top 1 @vLPNLine = LPNLine
          from LPNDetails
          where (LPNId = @ToLPNId)
          order by LPNLine desc;

          update LPNDetails
          set LPNId             = @ToLPNId,
              LPNLine           = coalesce(@vLPNLine, 0) + 1,
              @ToLPNDetailId    = LPNDetailId,
              @vToLPNDetailQty  = Quantity,
              ReferenceLocation = substring(coalesce(ReferenceLocation + ',' + rtrim(@FromLocation), rtrim(@FromLocation)), 1, 50),
              PickedBy          = @UserId,
              @ActivityDate     =
              PickedDate        = current_timestamp
          where (LPNId         = @vTaskLPNId) and
                (LPNDetailId   = @vTaskLPNDetailId) and
                (OrderDetailId = @vTaskOrderDetailId);

          /* Update To LPN Count and status */
          exec pr_LPNs_Recount @ToLPNId;

          set @UnitsPicked  = @UnitsPicked - @vToLPNDetailQty;

          /* Clear the variables */
          select @vFromLPNUnitsPerPackage = null, @vToLPNDetailQty = null;

          /* From LPN, FromPallet, ToPallet, FromLocation are all updated later */
        end
      else
        begin
          /* Find the LPNDetail if the TaskLPNDetailId is null to reduce the inventory against pick, or else */
          if (@vTaskLPNDetailId is null)
            begin
              select @FromLPNLine     = LPNLine,
                     @FromLPNDetailId = LPNDetailId,
                     @FromLPNQuantity = Quantity
              from LPNDetails
              where (LPNId = @FromLPNId) and (SKUId = @SKUIdPicked) and (OnhandStatus = 'A' /* Available */);
            end
          else
            select @FromLPNDetailId = @vTaskLPNDetailId;

          /* Adjust the existing detail down by the picked quantity */
          exec @vReturnCode = pr_LPNs_AdjustQty @FromLPNId,
                                                @FromLPNDetailId output,
                                                @SKUIdPicked,
                                                null,
                                                null,
                                                @vUnitsToConfirm,   /* Quantity to Adjust */
                                                '-', /* '=' - Exact Qty, '+' - Add Qty, '-' - Subtract Qty */
                                                'N',
                                                0    /* Reason Code */,
                                                null /* Reference */,
                                                @FromLPNBusinessUnit,
                                                @UserId;

          if (@vReturnCode > 0)
            goto ExitHandler;

          /* need to reset values here - if we do pick partial quantities then we will ended-up with the @toLPNDetailid
             from previous one in the loop ..

             Example - we have 3 picks with 2 ,3 and 5 units(total 10 units), and user confirmed with 2,3, 4 (total 7 or 8 for HPI case)
            then  we will delete 2 and 3 lines direclty from the location/lpn in the abouve if coniditon, and for the last one we will
            come to this conidtion because it is partial picking.So, i nthe loop we will still have tolpndetailid which system will trying to
            add to the same LPnDetailId... */

          select @ToLPNDetailId = null, @ToLPNLine = null, @vToLPNDetailQty = 0;

          /* Reduce UnitsPicked with the units confirmed */
          select @UnitsPicked = @UnitsPicked - @vUnitsToConfirm;

          /* Get the UnitsPerPackage from FromLPN to calculate the InnerPacks */
          select @vFromLPNUnitsPerPackage = UnitsPerPackage
          from LPNDetails
          where (LPNDetailId = @FromLPNDetailId);

          /* Calculate InnerPacks to pick from units to pick and units per package */
          if (coalesce(@vFromLPNUnitsPerPackage, 0) > 0)
            if ((@vUnitsToConfirm % @vFromLPNUnitsPerPackage) = 0) /* Update InnerPacks on ToLPN when multiples of units per package */
              select @vIPsToConfirm = @vUnitsToConfirm/@vFromLPNUnitsPerPackage;

          /* See if there is another detail for the same order line, if so, Update it */
          select @ToLPNLine       = LPNLine,
                 @ToLPNDetailId   = LPNDetailId,
                 @vToLPNDetailQty = Quantity,
                 @vToLPNDetailIPs = InnerPacks
          from LPNDetails
          where (LPNId         = @ToLPNId) and
                (OrderId       = @OrderId) and
                (OrderDetailId = @OrderDetailId);

          if (coalesce(@vSKUSerialized, 'N') = 'N' /* No */)
            select @vToLPNDetailQty     = coalesce(@vToLPNDetailQty, 0) + @vUnitsToConfirm,
                   @vToLPNDetailIPs     = coalesce(@vToLPNDetailIPs, 0) + @vIPsToConfirm,
                   @vNumLPNDetailsToAdd = 1;
          else
            select @ToLPNDetailId       = null, /* To add a new detail line every time for the same SKU as well */
                   @vToLPNDetailQty     = 1,
                   @vNumLPNDetailsToAdd = @vUnitsToConfirm,
                   @vToLPNDetailIPs     = @vIPsToConfirm;

          /* Create LPN Details as many as Qty - for Serialized SKUs (Gift Cards) */
          while (@vNumLPNDetailsToAdd >= 1) and (@ToLPNStatus <> 'F' /* new temp label */)
            begin
              /* Add a new LPN Detail for the picked  units to the ToLPN */
              exec @vReturnCode = pr_LPNDetails_AddOrUpdate @ToLPNId,
                                                            @ToLPNLine,                /* LPNLine */
                                                            null,                      /* CoO */
                                                            @SKUIdPicked,              /* SKUId */
                                                            null,                      /* SKU */
                                                            @vToLPNDetailIPs,          /* InnerPacks */
                                                            @vToLPNDetailQty,          /* Quantity */
                                                            null,                      /* ReceivedUnits */
                                                            null,                      /* ReceiptId */
                                                            null,                      /* ReceiptDetailId */
                                                            @OrderId,                  /* OrderId */
                                                            @OrderDetailId,            /* OrderDetailId */
                                                            null,                      /* OnHandStatus */
                                                            null,                      /* Operation */
                                                            null,                      /* Weight */
                                                            null,                      /* Volume */
                                                            null,                      /* Lot */
                                                            @ToLPNBusinessUnit,
                                                            @ToLPNDetailId  output;

              /* Here we are updating the Ref location (Picked from location) for future ref.. if the batch is picked incorrectly. */
              update LPNDetails
              set ReferenceLocation = substring(coalesce(ReferenceLocation + ',' + rtrim(@FromLocation), rtrim(@FromLocation)), 1, 50),
                  PickedBy          = @UserId,
                  @ActivityDate     =
                  PickedDate        = current_timestamp
              where (LPNDetailId = @ToLPNDetailId);

              select @vNumLPNDetailsToAdd = @vNumLPNDetailsToAdd - 1;

              /* If more LPN details are to be added, then clear the ToLPNDetailId */
              if (@vNumLPNdetailsToAdd > 0)
                select @ToLPNDetailId = null;

              /* Update counts on the Picking Pallet */
              exec pr_Pallets_UpdateCount @vPickingPalletId, @UpdateOption = '*';
            end;
        end

      if (@vReturnCode > 0)
        goto ExitHandler;

      /* If the TL was not generated earlier, then it must be generated above, so
         assign it to PickBatch and set DestZone */
      if (@vIsLabelGenerated <> 'Y' /* Yes */)
        begin
          /* Get the Packing Group */
          select @vPackingGroup = PackingGroup
          from OrderDetails
          where (OrderDetailId = @OrderDetailId);

          update LPNs
          set PickBatchId  = @vPickBatchId,
              PickBatchNo  = @vPickBatchNo,
              DestZone     = @vDestZone,
              PackingGroup = @vPackingGroup
          where (LPNId = @ToLPNId);

          /* insert into LPNTasks */
          exec pr_Tasks_AddLPNs @TaskId, @TaskDetailId,
                                @ToLPNId, @ToLPNDetailId,
                                @vLPNTaskRecordId output;
        end

      /* Update DestWarehouse, Ownership and LPNType on ToLPN from FromLPN */
      /* If LPN type is a reusable type (Flat or hanging) and it is new LPN, then
         ToLPN.LPNType = FromLPN.LPNType */
      if (@ToLPNStatus = 'N' /* New/Empty */)
        update L1
        set LPNType       = case when (charindex(L1.LPNType, 'FH') <> 0) then
                              L2.LPNType
                            else
                              L1.LPNType
                            end,
            Ownership     = L2.Ownership,
          --  CartonType    = 'T' /* Temp Label */ Cannot just set to any carton type
            DestWarehouse = L2.DestWarehouse,
            BusinessUnit  = L2.BusinessUnit
        from LPNs L1 join LPNs L2 on (L1.LPNId = @ToLPNId) and (L2.LPNId = @FromLPNId);

      /* Update PickTicket Hdr/ Detail */
      /* Set PickTicket Detail Allocated Quantity. If the Pick is of an already allocated
         task, then do not update as we would only be picking already assigned units */
      if (@TaskDetailId is null) or (coalesce(@vIsTaskAllocated, 'N') = 'N' /* No */)
        begin
          update OD
          set OD.UnitsAssigned = OD.UnitsAssigned + @vUnitsToConfirm
          from OrderDetails OD
          where (OD.OrderDetailId = @OrderDetailId);

          insert into @ttOrders(EntityId)
            select @OrderId;

          exec pr_OrderHeaders_Recalculate @ttOrders, 'S', @UserId;
       end

      /* On Unit Pick */
      /* If label is generated the we would call this procedure earlier */
      if (coalesce(@vIsLabelGenerated, 'N' /* No */) <> 'Y' /* Yes */)
          exec pr_Picking_OnPicked @vPickBatchNo, @OrderId, @PickingPalletId, @ToLPNId,
                                   'U'/* PickType - UnitPick */, 'U' /* LPNStatus - Picking */,
                                   @vUnitsToConfirm, @TaskDetailId, @ActivityType, @BusinessUnit, @UserId;
     end

  /* Update from LPN counts */
  exec pr_LPNs_Recount @FromLPNId;

  /* Update picking pallet Counts */
  exec pr_Pallets_UpdateCount @vPickingPalletId, @UpdateOption = '*';

  /* Update From pallet Counts */
  if (@vFromPalletId is not null)
    exec pr_Pallets_UpdateCount @vFromPalletId, @UpdateOption = '*';

  /* Update from Location counts  */
  exec pr_Locations_UpdateCount @LocationId   = @FromLocationId,
                                @UpdateOption = '$*' /* Recalculate */;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_ConfirmUnitPick */

Go
