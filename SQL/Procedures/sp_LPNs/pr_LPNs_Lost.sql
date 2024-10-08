/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/29  AY      pr_LPNs_Lost: Send -ve exports without depending upon reason codes (HA-1837)
                      pr_LPNs_Lost: Modified procedure to handle as flag changes in pr_LPNs_Unallocate.
  2014/01/20  TD      pr_LPNs_Lost, pr_LPNs_Move:Changes to move LPN into LOST location instead of mark the LPN as lost
  2013/12/17  TD      pr_LPNs_Lost:bug fix. Need to update Status of the LPN as Lost once the LPN is unallocated.
  2013/02/27  YA      pr_LPNs_Lost: Modified procedure to handle as signature changes in pr_LPNs_Unallocate.
              AY      pr_LPNs_Lost: Update ModifiedBy when LPN is marked as lost.
  2012/08/07  YA      pr_LPNs_Lost: Included audittrail, Reason code modification.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Lost') is not null
  drop Procedure pr_LPNs_Lost;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Lost: LPN could be lost during a cycle count or due to Short Pick.
  Both the reason code and AuditActivity give an indication as to which scenario
  it is.

  New changes: When an LPN is lost, XSC would not like to mark the LPN as Lost
  since it affects the inventory and instead would just like to move the LPN
  to a Lost location. However, since ERP should know that the inventory is not
  available for allocation, we would sent a transaction of InvMove to ERP.
  In essence, on Lost instead of sending an InvCh with -ve qty we just send
  an InvMove transaction to the host.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Lost
  (@LPNId          TRecordId,
   @ReasonCode     TReasonCode,
   @UserId         TUserId,
   @ClearPallet    TFlag         = 'Y',
   @AuditActivity  TActivityType = 'LPNLost',
   @Status         TStatus       = 'O' output,
   @OnhandStatus   TStatus       = 'U' output)
as
  declare @ReturnCode      TInteger,
          @MessageName     TMessageName,
          @Message         TDescription,

          @vNumLPNsChange  TCount,
          @vInnerPacks     TInnerpacks,
          @vLPNQuantity    TQuantity,
          @vLPNReservedQty TQuantity,
          @vLocationId     TRecordId,
          @vOrderId        TRecordId,
          @vBusinessUnit   TBusinessUnit,
          @vLPNLocationId  TRecordId,
          @vFromLocationId TRecordId,
          @vFromLocation   TLocation,
          @vToLocationId   TRecordId,
          @vToLocation     TLocation,
          @vLPN            TLPN,

          /* Audit info */
          @vTransType      TTypeCode,
          @vTransEntity    TEntity,

          @vMoveOnLost     TControlvalue,
          @vLostLocation   TLocation;
begin
  SET NOCOUNT ON;

  select @ReturnCode     = 0,
         @vLPNQuantity   = 0,
         @vNumLPNsChange = 0,
         @MessageName    = null;

  if (@LPNId is null)
    set @MessageName = 'InvalidLPN';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get LPN Details Here */
  select @vBusinessUnit   = BusinessUnit,
         @vLPNLocationId  = LocationId,
         @vFromLocation   = Location,
         @vLPN            = LPN,
         @vLPNQuantity    = Quantity,
         @vLPNReservedQty = ReservedQty
  from LPNs
  where (LPNId = @LPNId);

  /* Two variations here when an LPN is lost are:
     a. Move LPN to a Lost Location or
     b. Mark the LPN as Lost and take it out of inventory

     The control vars decide which option to consider and in the first case, also what the Lost Location is!
  */
  select @vMoveOnLost   = dbo.fn_Controls_GetAsString(@AuditActivity, 'MoveOnLost', 'N' /* No */, @vBusinessUnit, @UserId),
         @vLostLocation = dbo.fn_Controls_GetAsString(@AuditActivity, 'MoveToLocation', 'LOST',   @vBusinessUnit, @UserId);

  /* Clear from Pallet for the LPN */
  if (@ClearPallet = 'Y'/* Yes */)
    exec pr_LPNs_SetPallet @LPNId, null /* New Pallet */, @UserId;

  /* Unallocate LPN if it was allocated to an order */
  if (@vLPNReservedQty > 0)
    exec pr_LPNs_Unallocate @LPNId, default, 'P'/* PalletPick - Unallocate Pallet */, @vBusinessUnit, @UserId;

  if (@vMoveOnLost = 'Y' /* Yes */)
    begin
      /* Get LocationId of the LostLocation */
      select @vToLocationId   = LocationId,
             @vToLocation     = Location,
             @vFromLocationId = @vLPNLocationId
      from Locations
      where (Location = @vLostLocation);

      exec pr_LPNs_Move @LPNId, @vLPN, null /* status */, @vToLocationId,
                        @vLostLocation, @vBusinessUnit, @UserId;

      /* Setup to generate an InvMove with the From/To Locations */
      select @vTransType      = 'InvMove',
             @vTransEntity    = null,
             @vFromLocationId = @vLPNLocationId;
    end
  else
    begin
      /* Clear Location for the LPN */
      exec pr_LPNs_SetLocation @LPNId, null /* New Location */;

       /* Update LPNDetails */
      update LPNDetails
      set OnhandStatus = coalesce(@OnhandStatus, OnhandStatus)
      where (LPNId = @LPNId);

      /* Update LPN */
      update LPNs
      set @vLPNQuantity  = Quantity,
          @vBusinessUnit = BusinessUnit,
          @vOrderId      = OrderId,
          OnhandStatus   = coalesce(@OnhandStatus, OnhandStatus),
          Status         = coalesce(@Status, Status),
          ModifiedDate   = current_timestamp,
          ModifiedBy     = coalesce(@UserId, System_User)
      where (LPNId = @LPNId);

      /* Export InvCh for all the details in the LPN */
      select @vTransType    = 'InvCh', @vTransEntity    = 'LPNDetails',
             @vToLocationId = null,    @vFromLocationId = null;
    end

  /* Export the appropriate transaction with -ve quantity */
  exec pr_Exports_LPNData @vTransType /* TransType */,
                          @TransEntity    = @vTransEntity, /* Upload all details of LPN */
                          @TransQty       = @vLPNQuantity,
                          @QuantitySign   = -1,
                          @LPNId          = @LPNId,
                          @LocationId     = @vLPNLocationId,
                          @ReasonCode     = @ReasonCode,
                          @FromLocationId = @vFromLocationId,
                          @FromLocation   = @vFromLocation,
                          @ToLocationId   = @vToLocationId,
                          @ToLocation     = @vToLocation,
                          @CreatedBy      = @UserId;

  /* Audit Trail */
  if (@AuditActivity is not null)
    exec pr_AuditTrail_Insert @AuditActivity, @UserId, null /* ActivityTimestamp */,
                              @LPNId      = @LPNId,
                              @LocationId = @vLPNLocationId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LPNs_Lost */

Go
