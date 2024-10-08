/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/07/14  TK      pr_LPNDetails_ReserveQty: Bug fix in updating ReservedQty on source LPN ddetail when deferring allocation (OBV3-912)
  2022/03/13  TK      pr_LPNDetails_ReserveQty: Update InventoryClasses on reserved LPN detail (FBV3-967)
                      pr_LPNDetails_ReserveQty: Added TaskDetaild to proc signature (S2GCA-390)
  2018/02/23  TK      pr_LPNDetails_ReserveQty: Changes to update quantity on existing PR line for same order detail (S2G-151)
                      pr_LPNDetails_ReserveQty: Initial Revision (S2G-152)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_ReserveQty') is not null
  drop Procedure pr_LPNDetails_ReserveQty;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_ReserveQty: This procedure will consider the Inventory
   Reservation Model and do the necessary updates to Reserve the units for given
   Order/OrderDetail

  Inventory Reservation Model = D (Defer):
    Add a Pending Reserve line to the allocated LPN and update Reserved Qty on the source LPN Detail.
  Inventory Reservation Model = I (Immediate):
    If entire line is being allocated, then change it to Reserved
    If partial qty is being allocated from the line, then split the line.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_ReserveQty
  (@LPNId                 TRecordId,
   @SourceLPNDetailId     TRecordId,
   @UnitsToReserve        TQuantity,
   @OrderId               TRecordId,
   @OrderDetailId         TRecordId,
   @TaskDetailId          TRecordId,
   @SKUId                 TRecordId,
   @InvReservationModel   TControlValue,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId,
   ----------------------------------------
   @ReservedLPNDetailId   TRecordId output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,

          @vLPNDetailQuantity TQuantity;
begin
  SET NOCOUNT ON;

  select @vReturnCode      = 0,
         @vMessageName     = null;

  /* Update Reserved Qty on the Allocated LPN Detail */
  if (@InvReservationModel = 'D'/* Defer */)
    update LPNDetails
    set ReservedQty =  ReservedQty + @UnitsToReserve
    where (LPNDetailId = @SourceLPNDetailId);
  else
    select @vLPNDetailQuantity = Quantity
    from LPNDetails
    where (LPNDetailId = @SourceLPNDetailId);

  if (@InvReservationModel = 'D'/* Defer */)
    begin
      /* Find if there is already a reserved LPN Detail for same order detail to add inventory. This is not
         applicable if we are first creating tasks and then allocating after. In that scenario, we don't
         want to combine the lines by OrderDetail and keep them separate as per the TaskDetails already created */
      if (coalesce(@TaskDetailId, 0) = 0)
        select @ReservedLPNDetailId = LPNDetailId,
               @UnitsToReserve      += Quantity
        from LPNDetails
        where (OrderDetailId = @OrderDetailId) and
              (OnHandStatus  = 'PR'/* Pending Reservation */) and
              (LPNId         = @LPNId);

      /* Add new Pending Reserve line to the allocated LPN. If there was already a pending reserve
         line fetched above, then it would be updated with the new Qty */
      exec @vReturnCode = pr_LPNDetails_AddOrUpdate @LPNId, null /* LPNLine */, null /* CoO */,
                                                    @SKUId, null /* SKU */, null /* innerpacks */, @UnitsToReserve,
                                                    0 /* ReceivedUnits */, null /* ReceiptId */, null /* ReceiptDetailId */,
                                                    @OrderId, @OrderDetailId, 'PR' /* OnHandStatus */, null /* Operation */,
                                                    null /* Weight */, null /* Volume */, null /* Lot */, @BusinessUnit,
                                                    @ReservedLPNDetailId output, @CreatedBy = @UserId output;
    end
  else
  if (@InvReservationModel = 'I'/* Immediate */)
    begin
      /* If all available Units of LPN are being allocated, then just update the line
         with the OrderId and OrderDetailId, which will convert it to a Reserved Line */
      if (@UnitsToReserve = @vLPNDetailQuantity)
        begin
          exec @vReturnCode = pr_LPNDetails_AddOrUpdate @LPNId,
                                                        null,                      /* LPNLine */
                                                        null,                      /* CoO */
                                                        null,                      /* SKUId */
                                                        null,                      /* SKU  */
                                                        null,                      /* InnerPacks */
                                                        null,                      /* Quantity */
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
                                                        @BusinessUnit,
                                                        @SourceLPNDetailId  output;

          set @ReservedLPNDetailId = @SourceLPNDetailId;
        end
      else
        /* There could be some instances where there may not be LPN DetailId to Allocate,
           If there is an LPN detail line then split it into two and allocate the newly created line
           against the order */
        exec @vReturnCode = pr_LPNDetails_SplitLine @SourceLPNDetailId,
                                                    null,             /* Inner Packs */
                                                    @UnitsToReserve,  /* Units To Split */
                                                    @OrderId,
                                                    @OrderDetailId,
                                                    @ReservedLPNDetailId output;
    end /* InvReservationModel = Immediate */

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNDetails_ReserveQty */

Go
