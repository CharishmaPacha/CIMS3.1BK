/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/08/19  RV      pr_Packing_ReopenLPN: Made changes to calculate weight while re open the package (HPI-483)
                      pr_Packing_ReopenLPN: Inclue LPN's Picked status as valid to re open the LPN (NBD-390)
  2016/01/25  TK      pr_Packing_CloseLPN & pr_Packing_ReopenLPN: Enhanced to meet RF packing requirements (NBD-64)
  2013/05/16  PK      pr_Packing_ReopenLPN: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_ReopenLPN') is not null
  drop Procedure pr_Packing_ReopenLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_ReopenLPN

  For using the validations here in this procedure, we are calling it by action
  as "Validate"
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_ReopenLPN
  (@LPN           TLPN,
   @OrderId       TRecordId,
   @PackStation   TName,
   @Action        TAction,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @OutputXML     TXML          output)
as
  declare @MessageName TMessageName,
          @ReturnCode  TInteger,

          @vEmptyCartonWeight TWeight,
          @vLPNId             TRecordId,
          @vLPN               TLPN,
          @vQuantity          TQuantity,
          @vLPNCartonType     TCartonType,
          @vUnitsWeight       TWeight,
          @vLPNWeight         TWeight,
          @vLPNStatus         TStatus,
          @vLPNOrderId        TRecordId,
          @vOrderId           TRecordId,
          @vPickTicket        TPickTicket,
          @vPickBatchId       TRecordId,
          @vValidLPNStatuses  TControlValue,
          @vControlCategory   TCategory;
begin
SET NOCOUNT ON;

  select @MessageName = null,
         @vControlCategory = 'Packing' + coalesce('_' + @Action, '');

  /* Get the LPN info */
  select @vLPNId         = LPNId,
         @vLPN           = LPN,
         @vQuantity      = Quantity,
         @vLPNCartonType = CartonType,
         @vLPNWeight     = ActualWeight,
         @vLPNOrderId    = OrderId,
         @vLPNStatus     = Status,
         @vPickBatchId = PickBatchId
  from LPNs
  where (LPN          = @LPN) and
        (BusinessUnit = @BusinessUnit);

  /* Get the Order Info */
  select @vOrderId    = OrderId,
         @vPickTicket = PickTicket
  from OrderHeaders
  where (OrderId      = @OrderId) and
        (BusinessUnit = @BusinessUnit);

  /* Get the Valid LPN Statuses to reopen the Carton or Package */
  select @vValidLPNStatuses = dbo.fn_Controls_GetAsString(@vControlCategory, 'ValidLPNStatuses', 'KGDA' /* K:Picked, G:Packing,D:Packed,A:Allocated */, @BusinessUnit, @UserId);

  /* Validations */
  if (@LPN is null)
    set @MessageName = 'LPNIsInvalid';
  else
  if (@OrderId is null)
    set @MessageName = 'OrderIsInvalid';
  else
  if (@vLPN is null)
    set @MessageName = 'LPNDoesNotExist';
  else
  if (@vOrderId is null)
    set @MessageName = 'PickTicketDoesNotExist';
  else
  if (charindex(@vLPNStatus, @vValidLPNStatuses) = 0)
    set @MessageName = 'InvalidLPNStatus';
  else
  if (@vOrderId <> @vLPNOrderId)
    set @MessageName = 'CartonPackedForAnotherOrder';

  if (@MessageName is not null)
    goto ErrorHandler;

  select @vEmptyCartonWeight = EmptyWeight
  from CartonTypes with (NoLock)
  where CartonType = @vLPNCartonType;

  select @vUnitsWeight =  @vLPNWeight - @vEmptyCartonWeight;

  /* if the action is of ReopenCarton or ReopenPackage then, Build the
     output varibale with the values */
  if ((@Action = '$REOPENPACKAGE$') or (@Action = '$REOPENCARTON$'))
    select @OutputXML = (select @vLPN         as LPN,
                                @vOrderId     as OrderId,
                                @vPickTicket  as PickTicket,
                                @vQuantity    as Quantity,
                                @vUnitsWeight as UnitsWeight
                          for xml raw('PACKINGREOPENLPNINFO'), elements);

  /* AT log */
  exec pr_AuditTrail_Insert @ActivityType     = 'PackingReopenLPN',
                            @UserId           = @UserId,
                            @ActivityDateTime = null,
                            @PickBatchId      = @vPickBatchId,
                            @OrderId          = @vOrderId,
                            @LPNId            = @vLPNId,
                            @Quantity         = @vQuantity;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Packing_ReopenLPN */

Go

/*------------------------------------------------------------------------------
  Proc pr_Packing_ExecuteAction:
   Would be the primary procedure that would be called from packing screen to
   accomplish multiple actions. The Action would be specified as a parameter.

  Action: Action could be one of the following values -
          . CloseLPN: Packed and closed an LPN
          . PackLPN: Packed some units, but LPN is not yet closed and it can be repacked
          . UpdateLPN: Update Weight and CartonType of the LPN

  If LPN is closed, then the carton will be packed, and all documentation will
  be printed. If it is paused, then all units will be packed, but no documentation
  will be printed. That is the primary difference. Of course there are many other
  variations as well.
------------------------------------------------------------------------------*/
