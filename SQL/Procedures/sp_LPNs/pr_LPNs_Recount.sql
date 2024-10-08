/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/16  SV      pr_LPNs_Recount: Clear PackingGroup for empty LPNs (BK-573)
  2021/09/15  RIA     pr_LPNs_Recount: Changes to update SKUId for Logical LPNs when SKU is added without quantity (BK-588)
  2021/07/07  TK      pr_LPNs_Recount: Changes to update picking class on putaway LPNs if there is none (HA-2904)
  2021/04/27  SJ      pr_LPNs_Recount: Made changes to get PickedDate (HA-2704)
  2021/02/24  TK      pr_LPNs_Recount: Compute EstimatedWeight & Volume for STD_BOX & STD_UNIT
  2021/02/21  TK      pr_LPNs_Recount: Do not preprocess new temp LPNs (HA-2033)
  2020/10/19  TK      pr_LPNs_Recount: Do not reset input variable - Status (HA-1588)
  2019/12/11  RT      pr_LPNs_Recount: Included SKU to update on the LPNs
  2019/09/03  MJ/AY   pr_LPNs_Recount: Made changes to not to clear the SKUId on the consumed LPNs (OB2-528 & CID-1004)
  2019/06/17  VM      pr_LPNs_Recount: Clean up of redundant code and callers modified accordingly (CID-CodeCorrections)
  2018/08/22  MJ      pr_LPNs_Recount: Made changes to not to clear the SKUId on the consumed LPNs (OB2-528)
  2018/01/31  TK      pr_LPNs_Recount: Changes to update directed quantity on LPN (S2G-179)
  2018/01/29  TK      pr_LPNs_Recount: Reserved quantity on LPN should be sum of reserved quantity on LPNDetails
  2017/01/17  TK      pr_LPNs_Recount: Don't update Order & Wave info on Logical LPNs (HPI-1168)
  2016/12/22  KL      pr_LPNs_Recount: Fixed the bug to update the OrderId on LPNDetail (HPI-1114)
  2016/10/04  AY      pr_LPNs_Recount: Bug fix - should not clear SKUId on Logical LPN (HPI-GoLive)
  2016/09/27  AY      pr_LPNs_Recount: Bug fix with clearing SKU on Picklane with only D/DR Lines (HPI-GoLive)
                      pr_LPNs_Recount: Do not recount Lot on LPN (HPI-437)
  2016/07/19  TK      pr_LPNs_Recount: Reset PickBatchId and PickBatchNo on Empty LPNs (HPI-327)
  2016/07/01  AY      pr_LPNs_Recount: Pre-process Intransit LPN as well (HPI-213)
  2016/05/05  TK      pr_LPNs_Recount: Enhanced to update SKU1 - SKU5 on LPNs
  2016/01/12  TD      pr_LPNs_Recount:Changes to update Ownership on LPNs.
  2015/11/27  DK      pr_LPNs_Recount: Bug fix to clear SKU on consumed LPN (FB-530).
  2015/07/24  TK      pr_LPNs_Recount: Update PickBatchId and PickBatchNo on the Allocated LPN (FB-265)
  2015/07/18  AY      pr_LPNs_Recount: Set Estimated weight/volume of carton considering carton type(acme-231.11)
  2014/06/12  TD      pr_LPNs_Recount:chnages tpo ignore  Directed,Directed Reserved Qty  on the LPN.
  2014/04/25  TD      pr_LPNs_Recount:Changes to call LPN pre process.
  2014/04/03  TD      pr_LPNs_Recount:Updating Picking Class.
  2014/01/03  TD      pr_LPNs_Recount: updating LoadId, ShipmentId.
                      pr_LPNs_Recount: Update reservedQty to LPNs.
                      pr_LPNs_Recount/pr_LPNDetails_AddOrUpdate: Calculate Estimated Weight/Volume
  2013/05/21  PK      pr_LPNs_Recount: Updating ReceiptId on the LPN.
  2013/05/03  PK      pr_LPNs_Recount: Updating Pallet, Location.
  2012/08/27  AY      pr_LPNs_Recount: Changed params - Added UserId for updating ModifiedBy,
  2011/02/28  YA      pr_LPNs_Recount: Clear the LPN, if all units are consumed
  2011/11/01  VM      pr_LPNs_Recount, pr_LPNs_SetStatus:
  2011/01/25  VM      pr_LPNs_Recount: Set LPN to Consumed, if LPN is not logical
  2010/11/22  VM      pr_LPNs_AdjustQty, pr_LPNs_AddSKU, pr_LPNs_Generate, pr_LPNs_Recount: Procedures completed
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Recount') is not null
  drop Procedure pr_LPNs_Recount;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Recount:
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Recount
  (@LPNId     TRecordId,
   @UserId    TUserId = null,
   @Status    TStatus = null output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,

          @vLPNType           TTypeCode,
          @vLPNStatus         TStatus,
          @vPrevSKUId        TRecordId,
          @vSKUId             TRecordId,
          @vSKU               TSKU,
          @vSKU1              TSKU,
          @vSKU2              TSKU,
          @vSKU3              TSKU,
          @vSKU4              TSKU,
          @vSKU5              TSKU,
          @vPickingClass      TPickingClass,

          @vUnitWeight        TWeight,
          @vUnitVolume        TVolume,
          @vInnerpackWeight   TWeight,
          @vInnerpackVolume   TVolume,

          @vTotalSKUs         TCount,
          @vTotalInnerPacks   TInnerPacks,
          @vTotalQuantity     TQuantity,
          @vTotalOrders       TCount,
          @vTotalReceipts     TCount,
          @vOrderId           TRecordId,
          @vReceiptId         TRecordId,
          @vPickBatchId       TRecordId,
          @vPickBatchNo       TPickBatchNo,
          @vContentWeight     TWeight,
          @vContentVolume     TVolume,
          @vEstimatedWeight   TWeight,
          @vEstimatedVolume   TVolume,
          @vReservedQty       TQuantity,
          @vDirectedQty       TQuantity,
          @vUnReservedLines   TInteger,
          @vLot               TLot,
          @vTotalLots         TCount,
          @vPickedDate        TDateTime,
          @vBusinessUnit      TBusinessUnit,
          @vPrevQty           TQuantity,
          @vPrevNumLines     TCount,
          @vNumLines          TCount,
          @vIPsInLPN          TInnerPacks,
          @vQtyInLPN          TQuantity,
          @vUnavailableLines  TControlValue,
          @vSumQtyAllLines    TFlags,
          @vCartonType        TCartonType,
          @vCartonVolume      TVolume,
          @vEmptyCartonWeight TWeight;

  declare @ttSKUAttributes table (SKU      TSKU,
                                  SKU1     TSKU,
                                  SKU2     TSKU,
                                  SKU3     TSKU,
                                  SKU4     TSKU,
                                  SKU5     TSKU);
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Clear SKU entities table */
  delete from @ttSKUAttributes;

  /* Get the LPNId, if not passed */
  select @LPNId          = LPNId,
         @vLPNType       = LPNType,
         @vLPNStatus     = Status,
         @vPrevQty       = Quantity,
         @vBusinessUnit  = BusinessUnit,
         @vCartonType    = CartonType,
         @vPrevNumLines  = NumLines,
         @vPrevSKUId     = coalesce(SKUId, 0),
         @vSKU           = SKU,
         @vSKU1          = SKU1,
         @vSKU2          = SKU2,
         @vSKU3          = SKU3,
         @vSKU4          = SKU4,
         @vSKU5          = SKU5,
         @vPickingClass  = PickingClass
  from LPNs
  where (LPNId = @LPNId);

  /* Get the Counts from LPNDetails
     SKUId   - Count distinct so even if multiple lines have same SKU LPN would
                 reflect the SKU
     OrderId - Count distinct and have to coalesce as some lines have OrderId and
                 some wouldn't. Even if all lines have same OrderId except one
                 which is null, then LPN OrderId would be null */
  select @vSKUId           = coalesce(Min(SKUId), 0),
         @vTotalSKUs       = count(distinct SKUId),
         @vTotalInnerPacks = coalesce(sum(InnerPacks), 0),
         @vTotalQuantity   = coalesce(sum(Quantity), 0),
         @vTotalOrders     = count(distinct coalesce(OrderId, '')),
         @vTotalReceipts   = count(distinct coalesce(ReceiptId, '')),
         @vOrderId         = Min(OrderId),
         @vReceiptId       = Min(ReceiptId),
         @vContentWeight   = sum(coalesce(Weight, 0)),
         @vContentVolume   = sum(coalesce(Volume, 0)),
         @vLot             = Min(Lot),
         @vTotalLots       = count(distinct Lot),
         @vPickedDate      = Max(PickedDate),
         @vNumLines        = count(*)
  from LPNDetails
  where (LPNId = @LPNId) and
        (OnhandStatus not in ('D', 'DR', 'PR' /* Directed, Directed Reserved, Pending Resv. */));

  select @vReservedQty = sum(ReservedQty),
         @vDirectedQty = sum(case when OnhandStatus in ('D', 'DR'/* Directed/Directed Reserve */) then Quantity else 0 end)
  from LPNDetails
  where (LPNId = @LPNId);

  /* if it is a picklane, then it should always have a SKU, even if there are only D and DR Lines,
     so check again, only need to compute some fields */
  if  (@vLPNType = 'L' /* Logical */) and (coalesce(@vSKUId, 0) = 0)
    select @vSKUId     = Min(SKUId),
           @vTotalSKUs = count(distinct SKUId),
           @vLot       = Min(Lot),
           @vTotalLots = count(distinct Lot),
           @vNumLines  = count(*)
    from LPNDetails
    where (LPNId = @LPNId);

  /* Clear SKUId (and related info) on the LPN when LPN becomes empty but not for logical LPN */
  select @vSKUId = case when (@vLPNtype = 'L' /* Logical */) then coalesce(nullif(@vPrevSKUId, 0), @vSKUId)
                        when (@Status   = 'C' /* Consumed */) then @vPrevSKUId
                        when (@vTotalSKUs > 1) then null
                        when (@vTotalQuantity = 0) and (@vLPNType not in ('L' /* Logical */)) or (@vTotalSKUs = 0) then -1 -- clear
                        else coalesce(@vSKUId, @vPrevSKUId)
                   end;

  /* If NumLines has changed or if SKU changed, then recompute the SKU* fields on LPN */
  if (@vPrevNumLines <> @vNumLines) or
     ((@vPrevSKUId <> @vSKUId) and (@vSKUId > 0))
    begin
      if (@vNumLines = 1) and (@vSKUId > 0)
        select @vSKU  = SKU,
               @vSKU1 = SKU1,
               @vSKU2 = SKU2,
               @vSKU3 = SKU3,
               @vSKU4 = SKU4,
               @vSKU5 = SKU5
        from SKUs
        where (SKUId = @vSKUId);
      else
      if (@vNumLines > 1)
        begin
  /* Get the consolidated SKU attributes to update on the LPN */
  insert into @ttSKUAttributes(SKU, SKU1, SKU2, SKU3, SKU4, SKU5)
    select * from fn_LPNs_GetConsolidatedSKUAttributes (@LPNId, null /* Pallet Id */);

  select @vSKU  = coalesce(SKU,  'Mixed'),
         @vSKU1 = coalesce(SKU1, 'Mixed'),
         @vSKU2 = coalesce(SKU2, 'Mixed'),
         @vSKU3 = coalesce(SKU3, 'Mixed'),
         @vSKU4 = coalesce(SKU4, 'Mixed'),
         @vSKU5 = coalesce(SKU5, 'Mixed')
  from @ttSKUAttributes;
        end
    end

  /* If LPN has a cartontype then add Carton info to weight/volume */
  if (@vCartonType is not null) and (@vPrevQty <> @vTotalQuantity)
    begin
      /* Get the item weight and volume */
      select @vInnerpackWeight = coalesce(InnerpackWeight, 0),
             @vInnerpackVolume = coalesce(InnerpackVolume, 0),
             @vUnitWeight      = coalesce(UnitWeight, 0),
             @vUnitVolume      = coalesce(UnitVolume, 0)
      from SKUs
      where (SKUId = @vSKUId);

      /* For standard box always get the innerpack volume and weight and for standard Unit always get unitweight and unitvolume */
      if (@vCartonType in ('STD_BOX' /* Standard Box */, 'STD_UNIT'/* Standard Unit */))
        begin
          /* Re-compute the Estimated Weight and Volume */
          select @vEstimatedVolume = case
                                       when @vCartonType = 'STD_BOX' and @vInnerpackVolume > 0 then
                                         @vInnerpackVolume
                                       when @vCartonType = 'STD_BOX' and @vInnerpackVolume = 0 and @vTotalSKUs = 1 then
                                         @vUnitVolume * @vTotalQuantity
                                       when @vCartonType = 'STD_UNIT' then
                                         @vUnitVolume
                                     end,
                 @vEstimatedWeight = case
                                       when @vCartonType = 'STD_BOX' and @vInnerpackWeight > 0 then
                                         @vInnerpackWeight
                                       when @vCartonType = 'STD_BOX' and @vInnerpackVolume = 0 and @vTotalSKUs = 1 then
                                         @vUnitWeight * @vTotalQuantity
                                       when @vCartonType = 'STD_UNIT' then
                                         @vUnitWeight
                                     end;
        end
      else
        begin
          select @vCartonVolume      = OuterVolume,
                 @vEmptyCartonWeight = EmptyWeight
          from CartonTypes
          where (CartonType = @vCartonType) and
                (BusinessUnit = @vBusinessUnit);

          /* Re-compute the Estimated Weight and Volume */
          select @vEstimatedVolume = @vCartonVolume, -- no matter how much the volume of the contents, the carton volume is applicable
                 @vEstimatedWeight = @vContentWeight + @vEmptyCartonWeight;
        end
    end

  /* Updating LPN Status to Consumed based on TotalQuantity is moved before , to consider the Consumed status LPNs while updating the LPN latest counts so to not to clear the SKUId on Consumed LPNs. */

  /* Update LPN Status based on TotalQuantity */
  if (@vTotalQuantity = 0) and (@vLPNType not in ('L' /* Logical */, 'A' /* Cart */, 'TO' /* Tote */))
    select @Status = 'C' /* Consumed */;

  /* Update LPN with latest counts */
  update LPNs
  set SKUId           = case
                          /* We never need to change SKUId on Logical LPN, if SKU is removed LPN would be deleted */
                          when (LPNType = 'L') and (SKUId is not null) then
                            SKUId
                          /* Considering the Consumed status LPNs to not to clear the SKUId on Consumed LPNs */
                          when (@Status = 'C') then
                            SKUId
                          when (@vTotalSKUs <> 1) or ((@vTotalQuantity = 0) and (@vLPNType not in ('L' /* Logical */))) then
                            null
                          else
                            nullif(@vSKUId, -1)
                        end,
                        /* If SKUId = -1, that means we are clearing SKUId, then clear other SKU fields */
      SKU             = case when @vSKUId = -1 then null else @vSKU  end,
      SKU1            = case when @vSKUId = -1 then null else @vSKU1 end,
      SKU2            = case when @vSKUId = -1 then null else @vSKU2 end,
      SKU3            = case when @vSKUId = -1 then null else @vSKU3 end,
      SKU4            = case when @vSKUId = -1 then null else @vSKU4 end,
      SKU5            = case when @vSKUId = -1 then null else @vSKU5 end,
                        -- Don't update Order, Receipt or Wave info on Logical LPN
      OrderId         = case when (@vTotalOrders <> 1)   or (LPNType = 'L'/* Logical */) then null else @vOrderId   end,
      ReceiptId       = case when (@vTotalReceipts <> 1) or (LPNType = 'L'/* Logical */) then null else @vReceiptId end,
      PickBatchId     = case when (@vTotalQuantity = 0)  or (LPNType = 'L'/* Logical */) then null else PickBatchId end,
      PickBatchNo     = case when (@vTotalQuantity = 0)  or (LPNType = 'L'/* Logical */) then null else PickBatchNo end,
      InnerPacks      = coalesce(@vTotalInnerPacks, 0),
      Quantity        = coalesce(@vTotalQuantity,   0),
      ReservedQty     = coalesce(@vReservedQty,     0),
      DirectedQty     = coalesce(@vDirectedQty,     0),
      NumLines        = @vNumLines,
      EstimatedWeight = coalesce(@vEstimatedWeight, @vContentWeight),
      EstimatedVolume = coalesce(@vEstimatedVolume, @vContentVolume),
                        -- Do not change Location or Pallet info on Logical LPNs or Cart Positions
      LocationId      = case when ((@vTotalQuantity = 0) and (@vLPNType not in ('L', 'A'))) or (@vNumlines = 0) then null else LocationId end,
      Location        = case when ((@vTotalQuantity = 0) and (@vLPNType not in ('L', 'A'))) or (@vNumlines = 0) then null else Location   end,
      PalletId        = case when (@vTotalQuantity = 0) and (@vLPNType not in ('L', 'A'))                       then null else PalletId   end,
      Pallet          = case when (@vTotalQuantity = 0) and (@vLPNType not in ('L', 'A'))                       then null else Pallet     end,
      LoadId          = case when (@vTotalQuantity = 0) then null else LoadId       end,
      ShipmentId      = case when (@vTotalQuantity = 0) then null else ShipmentId   end,
      PackingGroup    = case when (@vTotalQuantity = 0) then null else PackingGroup end,
      Lot             = case when (@vTotalLots <> 1)    then null else @vLot        end,
      ModifiedBy      = @UserId
  where (LPNId = @LPNId);

  exec @vReturnCode = pr_LPNs_SetStatus @LPNId, @Status output;

  /* Call procedure here to update Putaway class and Picking Class. Neither one needs
     to be updated anymore once it is Allocated or when Status is putaway update only when picking class is null */
  if ((@vPrevQty <> @vTotalQuantity) and
      ((charindex(@Status, 'FAKGLS' /* NewTemp, Allocated, picked, Packing, Loaded, Shipped */) = 0))) or
     ((charindex(@Status, 'P' /* Putaway */) > 0) and (@vPickingClass is null))
    exec pr_LPNs_PreProcess @LPNId, default /* Update both */, @vBusinessUnit;
  else
  /* Any recount of Received LPN should update the PA class */
  if (@Status in ('T', 'R' /* InTransit, Received */))
    exec pr_LPNs_PreProcess @LPNId, 'PAC' /* Update PA Class */, @vBusinessUnit;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Recount */

Go
