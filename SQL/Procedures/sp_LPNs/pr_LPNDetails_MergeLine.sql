/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/06/09  TD      Added pr_LPNDetails_MergeLine.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_MergeLine') is not null
  drop Procedure pr_LPNDetails_MergeLine;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_MergeLine: Merge any other line for the same order in the LPN
   with the given line and delete the other line

     Teja : Incomplete version..we are not using this now..
     we need it in future....
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_MergeLine
  (@LPNDetailId      TRecordId,

   @MergeInnerPacks  TInnerPacks = null,
   @MergeQuantity    TQuantity   = null,

   @OrderId          TRecordId,
   @OrderDetailId    TRecordId,

   @Operation        TDescription,
   ------------------------------------------
   @NewLPNDetailId   TRecordId output,
   @CreatedDate      TDateTime = null output,
   @ModifiedDate     TDateTime = null output,
   @CreatedBy        TUserId   = null output,
   @ModifiedBy       TUserId   = null output)
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessageName,

          @vLPNId             TRecordId,
          @vLPNStatus         TStatus,
          @vLPNOrderDetailId  TRecordId,
          @vLPNDetailId       TRecordId,
          @vLPNlineSKUId      TRecordId,
          @vNewLPNLine        TDetailLine,
          @vInnerPacks        TInnerPacks,
          @vQuantity          TQuantity,
          @vReceivedUnits     TQuantity,
          @vNewReceivedUnits  TQuantity,
          @vSplitRatio        float,
          @vUnitsPerPackage   TQuantity,
          @vNewOnhandStatus   TStatus,
          @vOnhandStatus      TStatus,
          @vMergeLPNDetailId  TRecordId;

  declare @Inserted table (LPNDetailId TRecordId, CreatedDate TDateTime, CreatedBy TUserId);
begin
  SET NOCOUNT ON;

  select @vReturnCode      = 0,
         @vMessageName     = null,
         @MergeInnerPacks  = coalesce(@MergeInnerPacks, 0),
         @MergeQuantity    = coalesce(@MergeQuantity,   0);

  /* Fetch the details of the Original LPN Detail */
  select @vLPNDetailId      = LPNDetailId,
         @vLPNId            = LPNId,
         @vNewOnhandStatus  = OnhandStatus,
         @vOnhandStatus     = OnhandStatus,
         @vInnerPacks       = InnerPacks,
         @vQuantity         = Quantity,
         @vReceivedUnits    = ReceivedUnits,
         @vUnitsPerPackage  = UnitsPerPackage,
         @vLPNOrderDetailId = OrderDetailId,
         @vLPNlineSKUId     = SKUId
  from LPNDetails
  where (LPNDetailId = @LPNDetailId);

  /* Get LPN Info */
  select @vLPNStatus = Status
  from LPNs
  where (LPNId = @vLPNId);

  /* If merging a reserved line, then find the line to merge with */
  if (@Operation = 'MergeReserve_Line')
    begin
      select @MergeInnerPacks   = InnerPacks,
             @MergeQuantity     = Quantity,
             @vMergeLPNDetailId = LPNDetailId
      from LPNDetails
      where (LPNId         = @vLPNId)            and
            (SKUId         = @vLPNlineSKUId)     and
            (OnhandStatus  = 'R' /* Reserved */) and
            (OrderId       = @OrderId)           and
            (OrderDetailId = @OrderDetailId);
    end

  /* Set Innerpacks here */
  if ((@MergeInnerPacks = 0) and coalesce(@vUnitsPerPackage, 0) > 0)
    select @MergeInnerPacks = (@MergeQuantity / @vUnitsPerPackage);

  /* set Quantity here if the user passes 0 as qty */
  if (coalesce(@MergeQuantity, 0) = 0) and (coalesce(@MergeInnerPacks, 0) > 0)
    set @MergeQuantity = @MergeInnerPacks * @vUnitsPerPackage ;

  if (@LPNDetailId is null)
    set @vMessageName = 'NoLPNDetailToMerge';
  else
  if (@vLPNDetailId is null)
    set @vMessageName = 'InvalidLPNDetail';
  else
  if (@vMergeLPNDetailId is null)
    set @vMessageName = 'InvalidMergeLPNDetail';
  /* Qty */
  if (coalesce(@MergeQuantity, 0) = 0)
    set @vMessageName = 'QuantityCantBeZeroOrNull';

  if (@vMessageName is not null)
    goto ErrorHandler;

  if (@Operation = 'MergeReserve_Line')
    begin
      /* Add the merge Line Quantity and relevant fields accordingly */
      update LPNDetails
      set
        InnerPacks      = InnerPacks + @MergeInnerPacks,
        Quantity        = Quantity +   @MergeQuantity,
        OnhandStatus    = @vNewOnhandStatus,
        --Weight          = Weight * (1 - @vSplitRatio),
        --Volume          = Volume * (1 - @vSplitRatio),
        @ModifiedDate   = ModifiedDate = current_timestamp,
        @ModifiedBy     = ModifiedBy   = coalesce(@ModifiedBy, System_User)
      where LPNDetailId = @LPNDetailId;
    end

  /* Recount LPN */
  exec @vReturnCode = pr_LPNs_Recount @vLPNId, @ModifiedBy;

  /* Delete LPNDetailId here which is merged to original lpn line  */
  exec pr_LPNDetails_Delete @vMergeLPNDetailId;

  set @NewLPNDetailId = @vLPNDetailId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNDetails_MergeLine */

Go
