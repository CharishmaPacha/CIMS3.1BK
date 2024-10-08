/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/05/31  RKC     pr_LPNDetails_AddOrUpdate, pr_LPNs_CreateLPNs: Made changes to get the update the lot as empty instead of null (Onsite support)
  2021/01/19  TK      pr_LPNDetails_AddOrUpdate & pr_LPNs_CreateLPNs: Consider SKU.DefaulCoO if nothing passed in (HA-1912)
  2020/05/01  RIA     pr_LPNDetails_AddOrUpdate, pr_LPNs_AddSKU: Changes to update InnerPacks (CIMSV3-812)
  2019/01/07  AY      pr_LPNDetails_AddOrUpdate/pr_LPNs_AdjustQty: Reset Units/pkg (FB-1671)
  2018/05/09  CK      pr_LPNDetails_AddOrUpdate : Made Changes to set unitperPackage while createLPns to receive (S2G-791)
  2018/04/16  AY      pr_LPNDetails_AddOrUpdate: Use UnitVolume/Weight when InnerPack info is not available (S2G-655)
  pr_LPNDetails_AddOrUpdate: If LPN detail line is converted from R to A then reset Reserved qty on it (S2G-480)
  2018/02/18  TD      pr_LPNDetails_AddOrUpdate:Changes to update weight and voulme based on the innerpacks (S2G-107)
  pr_LPNDetails_AddOrUpdate & pr_LPNDetails_SplitLine: Changes to update ReservedQty
  2016/03/10  AY      pr_LPNDetails_AddOrUpdate: When updating LPNDetail, use the Qty on the LPNDetail
  2014/07/21  TD      pr_LPNDetails_AddOrUpdate, pr_LPNs_AdjustQty: Changes to update Quantity
  2014/07/04  NY      pr_LPNDetails_AddOrUpdate: Added coalesce to UnitsPerPackage.
  AY      pr_LPNDetails_AddOrUpdate: Code optimization, enchance to set Onhandstatus on
  2014/05/23  PV      pr_LPNDetails_AddOrUpdate: Reset inner packs value for Picklane units storage location.
  2014/04/01  TD      pr_LPNDetails_AddOrUpdate:Changes to handle innerpacks.
  2014/03/28  TD      pr_LPNDetails_AddOrUpdate:Changes to set Quantity and InnerPacks while Allocating
  2014/03/13  TD      pr_LPNDetails_AddOrUpdate:Changes to calculate Quantity based on the Innerpacks.
  2014/03/11  TD      pr_LPNDetails_AddOrUpdate: Changes to read innerpacks. If there is no
  2014/02/26  PK      pr_LPNDetails_AddOrUpdate: Passing in SKU.UnitsPerInnerPacks if Innerpacks is null or zero.
  2014/01/08  PK      pr_LPNDetails_AddOrUpdate: Considering Allocated Status to build OnhandStatus.
  pr_LPNs_Recount/pr_LPNDetails_AddOrUpdate: Calculate Estimated Weight/Volume
  2013/10/05  AY      pr_LPNDetails_AddOrUpdate: Compute InnerPacks
  2013/04/09  PK      pr_LPNDetails_AddOrUpdate: Fix to allow adding SKU with quantity 0 for static locations
  2013/03/27  AY/PK   pr_LPNs_AdjustQty, pr_LPNDetails_AddOrUpdate: Enhance to handle Static vs Dynamic picklanes
  2012/08/20  AY      pr_LPNDetails_AddOrUpdate: Optimization to reduce queries
  2011/09/26  AY      pr_LPNDetails_AddOrUpdate: Bug fix - SKUId cleared on LPNPicking
  2011/08/29  TD      pr_LPNDetails_AddOrUpdate: Set SKUId to null when Qty becomes zero
  2011/07/25  AY/VM   pr_LPNDetails_AddOrUpdate: Calculate OnhandStatus properly
  2011/07/20  VM      pr_LPNDetails_AddOrUpdate:
  pr_LPNDetails_AddOrUpdate: OnhandStatus was not updated on LPNDetail update
  2011/01/22  VM      pr_LPNDetails_AddOrUpdate: Remvoed unnecessary code
  pr_LPNDetails_AddOrUpdate: Insert OnhandStatus as well while inserting a detail.
  2010/11/24  VM      pr_LPNDetails_AddOrUpdate: Modified to generate an LPNLine, if a new detail has to be inserted
  2010/11/04  PK      Created pr_LPNDetails_AddOrUpdate, pr_LPNDetails_Delete,
  if object_id('dbo.pr_LPNDetails_AddOrUpdate') is null
  exec('Create Procedure pr_LPNDetails_AddOrUpdate as begin return; end')
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_AddOrUpdate') is not null
  drop Procedure pr_LPNDetails_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_AddOrUpdate:
  Important: Changed to not clear the SKU on LPN Details if the LPN is in Received state
             and ReceivedUnits > 0. If we delete the LPNDetail with Received Units, then
             we would not have accurate count on RODetail if that were to be ever recounted/recalculated.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_AddOrUpdate
  (@LPNId            TRecordId,
   @LPNLine          TDetailLine,

   @CoO              TCoO,
   @SKUId            TRecordId,
   @SKU              TSKU,
   @InnerPacks       TInnerPacks,
   @Quantity         TQuantity,

   @ReceivedUnits    TQuantity,

   @ReceiptId        TRecordId,
   @ReceiptDetailId  TRecordId,

   @OrderId          TRecordId,
   @OrderDetailId    TRecordId,

   @OnhandStatus     TStatus = null,
   @Operation        TOperation = null,

   @Weight           TWeight,
   @Volume           TVolume,
   @Lot              TLot,

   @BusinessUnit     TBusinessUnit,
   ------------------------------------------
   @LPNDetailId      TRecordId        output,
   @CreatedDate      TDateTime = null output,
   @ModifiedDate     TDateTime = null output,
   @CreatedBy        TUserId   = null output,
   @ModifiedBy       TUserId   = null output)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @Message             TDescription,

          @vUserId             TUserId,
          @vSKUId              TRecordId,
          @vInventoryUoM       TUoM,
          @vCoO                TCoO,
          @vUnitsPerInnerPack  TInteger,
          @vUnitsPerPackage    TUnitsPerPack,
          @vUnitWeight         TWeight,
          @vUnitVolume         TVolume,
          @vInnerPackVolume    TVolume,
          @vInnerPackWeight    TWeight,
          @vCalcWeight         TWeight,
          @vCalcVolume         TVolume,
          @vOnhandStatus       TStatus,
          @vLPNId              TRecordId,
          @vLPNType            TTypeCode,
          @vLPNStatus          TStatus,
          @vLPNInnerPacks      TQuantity,
          @vLPNOwnership       TOwnership,
          @vLocationId         TRecordId,
          @vLocationType       TLocationType,
          @vLocStorageType     TStorageType,
          @vLocationSubType    TTypeCode,
          @vWeightVolCalcMethod
                               TControlValue,
          @vLD_OnhandStatus    TStatus,
          @vLD_ReceiptDetailId TRecordId,
          @vLD_OrderDetailId   TRecordId,
          @vQuantity           TQuantity,
          @vInnerPacks         TInteger,

          @vAddNewLine         TFlag;

  declare @Inserted table (LPNDetailId TRecordId, CreatedDate TDateTime, CreatedBy TUserId);
begin
  SET NOCOUNT ON;

  select @ReturnCode    = 0,
         @MessageName   = null,
         @vOnhandStatus = null,
         @vQuantity     = @Quantity,
         @vInnerPacks   = @InnerPacks,
         @vUserId       = coalesce(@ModifiedBy, @CreatedBy, System_User);

  /* WeightVolCalcMethod: Possible values:
       UnitsOnly:          Calculate only considering Unit weights
       UnitsAndInnerPacks: Calcuate based upon the Inner packs and Unit weights*/
  select @vWeightVolCalcMethod = dbo.fn_Controls_GetAsString('LPN', 'WeightVolCalcMethod', 'UnitsOnly', @BusinessUnit, @vUserId);

  if (@LPNDetailId is null) or
     (not exists(select *
                 from LPNDetails
                 where (LPNDetailId = @LPNDetailId)))
    set @vAddNewLine = 'Y' /* This means New LPN Line to be inserted */
  else
    set @vAddNewLine = 'N'; /* Existing line is being updated */

  if (@vAddNewLine = 'N')
    select @vLD_OnhandStatus    = OnhandStatus,
           @vLD_ReceiptDetailId = ReceiptId,
           @vLD_OrderDetailId   = OrderDetailId,
           @vUnitsPerPackage    = UnitsPerPackage,
           @vQuantity           = coalesce(@Quantity, Quantity)
    from LPNDetails
    where (LPNDetailId = @LPNDetailId);

  -- /* Generate an LPNLine, if inserting a new Line */
  -- if (@vAddNewLine = 'Y')
  --   select @LPNLine = coalesce(Max(LPNLine) + 1, 1)
  --   from LPNDetails
  --   where (LPNId = @LPNId);

  select @vLPNId         = LPNId,
         @vLPNType       = LPNType,
         @vLPNStatus     = Status,
         @vLocationId    = LocationId,
         @vLPNInnerPacks = InnerPacks,
         @vLPNOwnership  = Ownership
  from LPNs
  where (LPNId = @LPNId);

  /* Get the Location info */
  if (@vLPNType = 'L' /* Logical */)
    select @vLocationSubType = LocationSubType,
           @vLocationType    = LocationType,
           @vLocStorageType  = StorageType
    from Locations
    where (LocationId = @vLocationId);

  /* If caller has specified both Quantity and InnerPacks then use them
     to compute UnitsPerPackage */
  if ((coalesce(@vInnerPacks, 0) > 0) and (@vQuantity > 0))
    set @vUnitsPerPackage = (@vQuantity / @vInnerPacks);

  /* Validate SKU if adding a new line or SKU is being updated */
  if (@vAddNewLine = 'Y') or ((@SKUId is null) and (@SKU is not null))
    select @SKUId = SKUId
    from dbo.fn_SKUs_GetScannedSKUs(@SKU, @BusinessUnit)
    where (Ownership = @vLPNOwnership);

  select @vSKUId           = SKUId,
         @vInventoryUoM    = InventoryUoM,
         @vUnitsPerPackage = case when InventoryUoM = 'EA' then 0
                                  else coalesce(@vUnitsPerPackage, UnitsPerInnerPack)
                             end,
         @vUnitWeight      = UnitWeight,
         @vUnitVolume      = UnitVolume,
         @vInnerPackVolume = InnerPackVolume,
         @vInnerPackWeight = InnerPackWeight,
         @vCoO             = coalesce(@CoO, DefaultCoO)
  from SKUs
  where (SKUId = @SKUId);

  /* If the caller has given either Quantity or InnerPacks, then compute
     the other one */
  if ((coalesce(@vQuantity, 0) = 0) and (@vInnerPacks > 0) and
      (coalesce(@vUnitsPerPackage, 0) > 0))
    set @vQuantity = (@vInnerPacks * @vUnitsPerPackage);
  else
  if (@InnerPacks is null) and (@Quantity > 0) and
      (coalesce(@vUnitsPerPackage, 0) > 0)
    set @vInnerPacks = (@vQuantity / @vUnitsPerPackage)
  else
  if ((@InnerPacks is null) and (@Quantity > 0))
    set @vInnerPacks = 0;

  if (@vLPNId is null)
    set @MessageName = 'LPNDoesNotExist';
  else
  if ((@vAddNewLine = 'Y') or (@SKUId is not null) or (@SKU is not null)) and
      (@vSKUId is null)
    set @MessageName = 'SKUDoesNotExist';
  else
  /* Qty - Quantity can be updated to zero */
  if (@LPNDetailId is null) and
     (@vLPNType = 'L' /* Logical */) and
     ((@vLocationSubType = 'D') and (coalesce(@Quantity, 0) <= 0) or
     ((@vLocationSubType = 'S') and (coalesce(@Quantity, 0) < -1))) and
     (@vLocStorageType <> 'U-')
    set @MessageName = 'QuantityCantBeZeroOrNull';
  else
  /* Validate ReceiptId only for new line or it is changed */
  if (@ReceiptDetailId is not null) and
     ((@vAddNewLine = 'Y') or
      (coalesce(@vLD_ReceiptDetailId, 0) <> @ReceiptDetailId)) and
     (not exists(select *
                 from ReceiptDetails
                 where (ReceiptId       = @ReceiptId) and
                       (ReceiptDetailId = @ReceiptDetailId)))
    set @MessageName = 'ReceiptDetailDoesNotExist';
  else
  /* Validate OrderId only for a new line or when it being changed */
  if (@OrderDetailId is not null) and
     ((@vAddNewLine = 'Y') or
      (coalesce(@vLD_OrderDetailId, 0) <> @OrderDetailId)) and
     (not exists(select *
                 from OrderDetails
                 where (OrderId       = @OrderId) and
                       (OrderDetailId = @OrderDetailId)))
    set @MessageName = 'OrderDetailDoesNotExist';
  else
  if (@BusinessUnit is null)
    set @MessageName = 'BusinessUnitIsInvalid';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Calculate Weight/Volume
     TD- If the line has multiples of innerpacks then we need to take the case weight/volume to calculate the weight/volume on the carton
         and also if the line has some cases and a few units then we need to calculate seperately and summarize it */
  select @vCalcWeight   = case
                            when (@vWeightVolCalcMethod = 'UnitsAndInnerPacks') and (coalesce(@vUnitsPerPackage, 0) > 0) and (coalesce(@vInnerPacks, 0) > 0)  and (coalesce(@vInnerPackWeight, 0) > 0)
                              then (@vInnerPacks * @vInnerPackWeight) + ((@vQuantity % @vUnitsPerPackage) * @vUnitWeight)
                            when (@vWeightVolCalcMethod = 'UnitsAndInnerPacks') and (coalesce(@vUnitsPerPackage, 0) > 0) and (coalesce(@vInnerPackWeight, 0) > 0)
                              then ((@vQuantity / @vUnitsPerPackage) * @vInnerPackWeight) + ((@vQuantity % @vUnitsPerPackage) * @vUnitWeight)
                            else @vQuantity * @vUnitWeight
                          end,
         @vCalcVolume   = case
                            when (@vWeightVolCalcMethod = 'UnitsAndInnerPacks') and (coalesce(@vUnitsPerPackage, 0) > 0) and (coalesce(@vInnerPacks, 0) > 0) and coalesce(@vInnerPackVolume, 0) > 0
                              then (@vInnerPacks * @vInnerPackVolume) + ((@vQuantity % @vUnitsPerPackage) * @vUnitVolume)
                            when (@vWeightVolCalcMethod = 'UnitsAndInnerPacks') and (coalesce(@vUnitsPerPackage, 0) > 0) and (coalesce(@vInnerPackVolume, 0) > 0)
                              then ((@vQuantity / @vUnitsPerPackage) * @vInnerPackVolume) + ((@vQuantity % @vUnitsPerPackage) * @vUnitVolume)
                            else @vQuantity * @vUnitVolume
                          end,
         @ReceivedUnits = case
                            when @vLPNStatus = 'T' /* InTransit */ then 0
                            else @ReceivedUnits
                          end;

  /* Reset InnerPacks quantity if the location storage type is units */
  /* When SKU inventory UoM doesn't specify Cases (CS), then do not compute Innerpacks */
  if (((@vLocationType = 'K'/* PickLane */) and (@vLocStorageType = 'U'/* Units */)) or
      (charindex('CS', @vInventoryUoM) = 0))
    select @vInnerPacks = 0;

  /* Validates LPNDetails whether it is exists, if it then it updates or inserts  */
  if (@vAddNewLine = 'Y')
    begin
      /* Calculate OnhandStatus of Detail */
      set @vOnhandStatus = case
                             when (@OrderId is not null) and (@OrderDetailId is not null) then
                               coalesce(@OnhandStatus, 'R' /* Reserved */)
                             when (@vLPNType = 'L' /* Logical */) or
                                  (@vLPNStatus in ('P', 'A' /* Putaway, Allocated */)) then
                               'A' /* Available */
                             else
                               'U' /* Unavailable */
                           end;

      /* ##TODO: Need to check for 'Allocated' status and
           if LPN Location is pickable set to 'Available' else 'Unavailable' */

      insert into LPNDetails(LPNId,
                             LPNLine,
                             OnhandStatus,
                             CoO,
                             SKUId,
                             InnerPacks,
                             Quantity,
                             ReservedQty,
                             UnitsPerPackage,
                             ReceivedUnits,
                             ReceiptId,
                             ReceiptDetailId,
                             OrderId,
                             OrderDetailId,
                             Weight,
                             Volume,
                             Lot,
                             BusinessUnit,
                             CreatedBy)
                      output inserted.LPNDetailId, inserted.CreatedDate, inserted.CreatedBy
                        into @Inserted
                      select @LPNId,
                             @LPNLine,
                             @vOnhandStatus,
                             @vCoO,
                             @SKUId,
                             coalesce(@vInnerPacks, 0),
                             coalesce(@vQuantity,   0),
                             case when (@vOnhandStatus = 'R'/* Reserved */) then @vQuantity else 0 end,
                             coalesce(@vUnitsPerPackage, 0),
                             coalesce(@ReceivedUnits, 0),
                             @ReceiptId,
                             @ReceiptDetailId,
                             @OrderId,
                             @OrderDetailId,
                             coalesce(@Weight, @vCalcWeight, 0),
                             coalesce(@Volume, @vCalcVolume, 0),
                             coalesce(@Lot, ''),
                             @BusinessUnit,
                             coalesce(@CreatedBy, System_User);

      select @LPNDetailId = LPNDetailId,
             @CreatedBy   = CreatedBy,
             @CreatedDate = CreatedDate
      from @Inserted;
    end
  else
    begin
      /* Calculate OnhandStatus of Detail */
      select @vOnhandStatus = case
                                when (@OrderId is not null) and (@OrderDetailId is not null) and
                                     (@vLD_OnhandStatus  = 'A' /* Available */) then
                                  'R' /* Reserved */
                                when (@OrderId is not null) and (@OrderDetailId is not null) and
                                     (@vLD_OnhandStatus = 'D' /* Directed */) then
                                  'DR'  /* Directed Reserved */
                                when (@vLD_OnhandStatus = 'R' /* Reserved */) and
                                     (@Quantity = 0) and
                                     (@vLocationSubType = 'S' /* Static */) then
                                  'A' /* available */
                              end

      update LPNDetails
      set
        CoO             = coalesce(@vCoO, CoO),
        SKUId           = case
                            when coalesce(@Quantity, Quantity) <> 0 then
                              coalesce(@SKUId, SKUId)
                            when (@vLocationSubType = 'S' /* Static */) and (coalesce(@Quantity, Quantity) = 0)
                              then coalesce(@SKUId, SKUId)
                            when (@vLPNStatus = 'R' /* Received */) and (ReceivedUnits > 0)
                              then coalesce(@SKUId, SKUId)
                            else null
                          end,
        InnerPacks      = coalesce(@vInnerPacks, InnerPacks, 0),
        Quantity        = coalesce(@vQuantity, Quantity, 0),
        /* Do not reset reserved qunatity if it is greater than zero */
        ReservedQty     = case when (coalesce(@vOnhandStatus, OnhandStatus) = 'R'/* Reserved */) then @vQuantity
                               when (OnHandStatus = 'R'/* Reserved */) and (@vOnHandStatus = 'A'/* Available */) then 0   -- R line converted to A
                               when (ReservedQty > 0) then ReservedQty
                               else 0
                          end,
        OnhandStatus    = coalesce(@vOnhandStatus, OnhandStatus),
        UnitsPerPackage = coalesce(@vUnitsPerPackage, UnitsPerPackage),
        ReceivedUnits   = coalesce(@ReceivedUnits, ReceivedUnits),
        ReceiptId       = coalesce(@ReceiptId, ReceiptId),
        ReceiptDetailId = coalesce(@ReceiptDetailId, ReceiptDetailId),
        OrderId         = case when @vOnhandStatus = 'A' then null
                               else coalesce(@OrderId, OrderId)
                          end,
        OrderDetailId   = case when @vOnhandStatus = 'A' then null
                               else coalesce(@OrderDetailId, OrderDetailId)
                          end,
        Weight          = coalesce(@Weight, @vCalcWeight, Weight),
        Volume          = coalesce(@Volume, @vCalcVolume, Volume),
        Lot             = coalesce(@Lot, Lot),
        @ModifiedDate   = ModifiedDate = current_timestamp,
        @ModifiedBy     = ModifiedBy   = coalesce(@ModifiedBy, System_User)
      where LPNDetailId = @LPNDetailId
    end

  /* Recount LPN */
  exec @ReturnCode = pr_LPNs_Recount @LPNId, @vUserId;

  if (@ReturnCode > 0)
    goto ExitHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LPNDetails_AddOrUpdate */

Go
