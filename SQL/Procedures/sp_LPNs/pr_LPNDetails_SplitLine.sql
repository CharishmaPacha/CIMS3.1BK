/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/17  TK      pr_LPNDetails_SplitLine: Bug fix to update reserved quantity on the source LPN detail line (HA-GoLive)
  2018/04/02  TK      pr_LPNDetails_SplitLine: Changes to set Innserpacks on line to '0'
                      pr_LPNDetails_AddOrUpdate & pr_LPNDetails_SplitLine: Changes to update ReservedQty
  2017/11/08  YJ      pr_LPNDetails_AddDirectedQty, pr_LPNDetails_SplitLine: Changes to update ReplenishPickTicket when add directed quantity
              SV      pr_LPNDetails_SplitLine: Providing AT over the Location/LPN during the picking the replenish order (HPI-684)
  2016/04/22  AY      pr_LPNDetails_SplitLine: Minor fix to copy ReplenishOrderId to DR line
  2015/10/29  OK      pr_LPNDetails_SplitLine: Restricted to insert negetive innerpacks after allocating the inventory(FB-477)
  2014/04/06  TD      pr_LPNDetails_SplitLine:Changes to insert innerpacks.
  2011/01/23  AY      pr_LPNDetails_SplitLine: Migrated from RFConnect
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_SplitLine') is not null
  drop Procedure pr_LPNDetails_SplitLine;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_SplitLine: This procedure splits an existing line by
    moving the Split InnerPacks/Qty to a new line. Optionally, if Order info is
    given, the new line is associated with that.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_SplitLine
  (@LPNDetailId      TRecordId,

   @SplitInnerPacks  TInnerPacks,
   @SplitQuantity    TQuantity,

   @OrderId          TRecordId,
   @OrderDetailId    TRecordId,
   ------------------------------------------
   @NewLPNDetailId   TRecordId output,
   @CreatedDate      TDateTime = null output,
   @ModifiedDate     TDateTime = null output,
   @CreatedBy        TUserId   = null output,
   @ModifiedBy       TUserId   = null output)
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessageName,

          @vSKUId             TRecordId,
          @vLPNId             TRecordId,
          @vLPNDetailId       TRecordId,
          @vLocStorageType    TTypeCode,
          @vNewLPNLine        TDetailLine,
          @vInnerPacks        TInnerPacks,
          @vQuantity          TQuantity,
          @vDirectedQty       TQuantity,
          @vReceivedUnits     TQuantity,
          @vNewReceivedUnits  TQuantity,
          @vSplitRatio        float,
          @vUnitsPerPackage   TQuantity,
          @vNewOnhandStatus   TStatus,
          @vOnhandStatus      TStatus;

  declare @Inserted table (LPNDetailId TRecordId, CreatedDate TDateTime, CreatedBy TUserId);
begin
  SET NOCOUNT ON;

  select @vReturnCode      = 0,
         @vMessageName     = null,
         @SplitInnerPacks  = coalesce(@SplitInnerPacks, 0),
         @SplitQuantity    = coalesce(@SplitQuantity,   0);

  /* Fetch the details of the Original LPN Detail */
  if (@LPNDetailId is not null)
    select @vLPNDetailId      = LPNDetailId,
           @vLPNId            = LPNId,
           @vSKUId            = SKUId,
           @vNewOnhandStatus  = OnhandStatus,
           @vOnhandStatus     = OnhandStatus,
           @vLocStorageType   = StorageType,
           @vInnerPacks       = InnerPacks,
           @vQuantity         = Quantity,
           @vReceivedUnits    = ReceivedUnits,
           @vUnitsPerPackage  = UnitsPerPackage
    from vwLPNDetails
    where (LPNDetailId = @LPNDetailId);

  /* If the line being split is being assigned to an order, then change it's Onhand Status
     to indicate it is reserved */
  if (@OrderId is not null)
    if (@vOnhandStatus = 'A' /* Available */)
      select @vNewOnhandStatus = 'R' /* Reserve */
    else
    if (@vOnhandStatus = 'D' /* Directed */)
      select @vNewOnhandStatus = 'DR' /* Directed Reserve */

  /* Set Innerpacks here */
  /* Update innerpacks only if from LPN detail has innerpacks and split quantity is in multiples of innerpacks */
  if (@vInnerPacks > 0) and (@SplitInnerPacks = 0) and
     (@vUnitsPerPackage > 0) and (@SplitQuantity % @vUnitsPerPackage = 0)
    select @SplitInnerPacks = (@SplitQuantity / @vUnitsPerPackage);

  /* set Quantity here if the user passes 0 as qty */
  if (coalesce(@SplitQuantity, 0) = 0) and (coalesce(@SplitInnerPacks, 0) > 0)
    set @SplitQuantity = @SplitInnerPacks * @vUnitsPerPackage ;

  if (@LPNDetailId is null)
    set @vMessageName = 'NoLPNDetailToSplit';
  else
  if (@vLPNDetailId is null)
    set @vMessageName = 'InvalidLPNDetail';
  else
  /* Qty */
  if (coalesce(@SplitQuantity, 0) = 0)
    set @vMessageName = 'QuantityCantBeZeroOrNull';
  else
  if (@SplitQuantity >= @vQuantity)
    set @vMessageName = 'InvalidQuantityToSplit';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Calculate what ratio of the line is being split based upon quantity
     - needed to compute Weight & Volume of new and original lines */
  set @vSplitRatio = cast(@SplitQuantity as float) / @vQuantity;

  /* Split the Received Units as well against both line */
  select @vNewReceivedUnits = dbo.fn_MinInt(@vReceivedUnits, @SplitQuantity);

  /* Reset InnerPacks quantity if the location storage type is units */
  if (@vLocStorageType like 'U%')
    set @SplitInnerPacks = 0;

  /* Generate an LPNLine, for new line to be inserted */
  select @vNewLPNLine = coalesce(Max(LPNLine) + 1, 1)
  from LPNDetails
  where (LPNId = @vLPNId);

  /* Create a new line from the existing LPN Detail */
  insert into LPNDetails(LPNId,
                         LPNLine,
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
                         ReplenishOrderId,
                         ReplenishPickTicket,
                         ReplenishOrderDetailId,
                         OnhandStatus,
                         Weight,
                         Volume,
                         Lot,
                         BusinessUnit,
                         CreatedBy)
                  output inserted.LPNDetailId, inserted.CreatedDate, inserted.CreatedBy
                    into @Inserted
                  select LPNId,
                         @vNewLPNLine,
                         CoO,
                         SKUId,
                         @SplitInnerPacks,
                         @SplitQuantity,
                         case when (@vNewOnhandStatus = 'R'/* Reserved */) then @SplitQuantity else 0 end,
                         UnitsPerPackage,
                         @vNewReceivedUnits,
                         ReceiptId,
                         ReceiptDetailId,
                         @OrderId,
                         @OrderDetailId,
                         ReplenishOrderId,
                         ReplenishPickTicket,
                         ReplenishOrderDetailId,
                         @vNewOnhandStatus,
                         Weight * @vSplitRatio,
                         Volume * @vSplitRatio,
                         Lot,
                         BusinessUnit,
                         coalesce(@CreatedBy, System_User)
                  from LPNDetails
                  where (LPNDetailId = @LPNDetailId)

  select @NewLPNDetailId = LPNDetailId,
         @CreatedBy      = CreatedBy,
         @CreatedDate    = CreatedDate
  from @Inserted;

  /* Reduce the Original Line Quantity and relevant fields accordingly */
  update LD
  set
    LD.InnerPacks      = dbo.fn_MaxInt(LD.InnerPacks - @SplitInnerPacks, 0),
    LD.Quantity        = LD.Quantity - @SplitQuantity,
    LD.ReservedQty     = case when OnhandStatus = 'R'/* Reserved */ then LD.ReservedQty - @SplitQuantity else LD.ReservedQty end,
    LD.UnitsPerPackage = case when LD.UnitsPerPackage = 0 then coalesce(S.UnitsPerInnerpack, 0) else LD.UnitsPerPackage end,
    LD.ReceivedUnits   = LD.ReceivedUnits - @vNewReceivedUnits,
    LD.Weight          = LD.Weight * (1 - @vSplitRatio),
    LD.Volume          = LD.Volume * (1 - @vSplitRatio),
    @ModifiedDate      = LD.ModifiedDate = current_timestamp,
    @ModifiedBy        = LD.ModifiedBy   = coalesce(@ModifiedBy, System_User)
  from LPNDetails LD
    join SKUs S on (LD.SKUId = S.SKUId)
  where LPNDetailId = @LPNDetailId;

  select @vDirectedQty = Quantity
  from LPNDetails
  where (LPNId = @vLPNId) and (OnHandStatus = 'DR') and (OrderDetailId = @OrderDetailId);

  /* We need to add the AT if only the a new directed reserved qty is created */
  if ((coalesce(@vDirectedQty, '') <> '') and (@vDirectedQty > 0))
    exec pr_AuditTrail_Insert 'InvAllocatedForDirectedLine', 'cIMSAgent', null /* ActivityTimestamp */,
                              @LPNId         = @vLPNId,
                              @SKUId         = @vSKUId,
                              @OrderId       = @OrderId,
                              @OrderDetailId = @OrderDetailId,
                              @Quantity      = @vDirectedQty;

  /* Recount LPN */
  exec @vReturnCode = pr_LPNs_Recount @vLPNId, @ModifiedBy;

  if (@vReturnCode > 0)
    goto ExitHandler;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNDetails_SplitLine */

Go
