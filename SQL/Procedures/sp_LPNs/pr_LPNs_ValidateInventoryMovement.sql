/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/19  VS      pr_LPNs_ValidateInventoryMovement: Raise the Validations properly (HA-1595)
  2020/08/28  TK      pr_LPNs_Move & pr_LPNs_ValidateInventoryMovement: Changes to move reserved LPNs
  2020/05/28  VS      pr_LPNs_ValidateInventoryMovement: Prevent Rework LPN if order is not closed (HA-520)
  2020/04/16  VM      pr_LPNs_MoveLPN: Call pr_LPNs_ValidateInventoryMovement for more validations (HA-161)
  2020/04/14  VM      pr_LPNs_ValidateInventoryMovement: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_ValidateInventoryMovement') is not null
  drop Procedure pr_LPNs_ValidateInventoryMovement;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_ValidateInventoryMovement: Validates if the given given inventory (LPN/Pallet)
    can be moved to the given Location or not by processing some validations and rules
    and returns an error message, if not allowed.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_ValidateInventoryMovement
  (@LPNId         TRecordId,
   @ToPalletId    TRecordId,
   @ToLocationId  TRecordId,
   @Operation     TOperation,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,

          @vLPN                 TLPN,
          @vLPNStatus           TStatus,
          @vLPNOnhandStatus     TStatus,
          @vLPNLocationId       TRecordId,
          @vLPNLocation         TLocation,
          @vLPNWarehouse        TWarehouse,
          @vLPNReceiptId        TRecordId,
          @vLPNOrderId          TRecordId,

          @vPallet              TPallet,
          @vPalletStatus        TStatus,
          @vPalletWarehouse     TWarehouse,

          @vROWarehouse         TWarehouse,
          @vReceiverId          TRecordId,
          @vReceiverStatus      TStatus,

          @vToLocationType      TTypeCode,
          @vToLocWarehouse      TWarehouse,
          /* control vars */
          @vAllowNewInvBeforeReceiverClose             TControlValue,
          @vValidLocTypesToMoveInvBeforeReceiverClose  TControlValue,
          @vMoveReservedInvAcrossWHs                   TControlValue,

          @vRulesDataXML        TXML;
begin
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Fetch LPN info */
  select @vLPN             = LPN,
         @vLPNStatus       = Status,
         @vLPNOnhandStatus = OnhandStatus,
         @vLPNLocationId   = LocationId,
         @vLPNLocation     = Location,
         @vLPNWarehouse    = DestWarehouse,
         @vLPNReceiptId    = ReceiptId,
         @vReceiverId      = ReceiverId,
         @vLPNOrderId      = OrderId
  from LPNs
  where (LPNId = @LPNId);

  /* If LPN is being added to Pallet, then we check against the Location of the Pallet */
  if (@ToPalletId is not null) and (@ToLocationId is null)
    select @ToLocationId = LocationId
    from Pallets
    where (PalletId = @ToPalletId);

  if (@ToLocationId is not null)
    select @vToLocationType = LocationType,
           @vToLocWarehouse = Warehouse
    from Locations
    where (LocationId = @ToLocationId);

  select @vROWarehouse = Warehouse
  from ReceiptHeaders
  where (ReceiptId = @vLPNReceiptId);

  select @vReceiverStatus = Status
  from Receivers
  where (ReceiverId = @vReceiverId);

  /* Get the control variables */
  select @vAllowNewInvBeforeReceiverClose            = dbo.fn_Controls_GetAsString('Inventory', 'AllowNewInvBeforeReceiverClose', 'N' /* No */, @BusinessUnit, @UserId),
         /* Allowed location types for PA, Move, Transfer within the allowed Warehouses */
         @vValidLocTypesToMoveInvBeforeReceiverClose = dbo.fn_Controls_GetAsString('TransferInventory', 'ValidLocationTypesToMoveInvBeforeReceiverClose', 'SD' /* Staging/Dock */, @BusinessUnit, @UserId),
         @vMoveReservedInvAcrossWHs                  = dbo.fn_Controls_GetAsString('Inventory', 'MoveReservedInvAcrossWHs', 'N' /* No */, @BusinessUnit, @UserId);

  /* Build the xml for Rules */
  select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('LPNId',                     @LPNId) +
                            dbo.fn_XMLNode('LPNStatus',                 @vLPNStatus) +
                            dbo.fn_XMLNode('LPNOnhandStatus',           @vLPNOnhandStatus) +
                            dbo.fn_XMLNode('LPNLocationId',             @vLPNLocationId) +
                            dbo.fn_XMLNode('LPNWarehouse',              @vLPNWarehouse) +
                            dbo.fn_XMLNode('OrderId',                   @vLPNOrderId) +
                            dbo.fn_XMLNode('ToLocationId',              @ToLocationId) +
                            dbo.fn_XMLNode('ToLocationType',            @vToLocationType) +
                            dbo.fn_XMLNode('ToLocationWH',              @vToLocWarehouse) +
                            dbo.fn_XMLNode('ReceiptId',                 @vLPNReceiptId) +
                            dbo.fn_XMLNode('ReceiverId',                @vReceiverId) +
                            dbo.fn_XMLNode('MoveReservedInvAcrossWHs',  @vMoveReservedInvAcrossWHs));

  /* Validations */

  /* No matter which Operation it is, we do not want to allow inventory into a Pickable Location
     before the receiver is closed if AllowNewInvBeforeReceiverClose is Y */
  if (@vReceiverStatus = 'O') and
     (@vAllowNewInvBeforeReceiverClose = 'N') and
     (@vLPNStatus in ('T', 'R' /* InTransit/Received */)) and
     (@vToLocationType in ('R', 'B', 'K' /* Reserve/Bulk/Picklane */))
     select @vMessageName = 'LPNMove_BeforeReceiverClosed_NotAllowed';
  else
  /* Do not even allow start of Putaway or CC of the LPN when Receiver is not yet closed */
  if (@vReceiverStatus = 'O') and
     (@vAllowNewInvBeforeReceiverClose = 'N') and
     (@Operation in ('Putaway', 'CycleCount'))
     select @vMessageName = 'LPNMove_BeforeReceiverClosed_NotAllowed';
  else
  /* Do not allow Move/Transfer LPN to any location type other than allowed locations (Staging/Dock) before Receiver close */
  if (@vReceiverStatus = 'O') and
     (@vAllowNewInvBeforeReceiverClose = 'N') and
     (@vLPNStatus in ('T', 'R' /* InTransit/Received */)) and
     (charindex(@vToLocationType, @vValidLocTypesToMoveInvBeforeReceiverClose) = 0)
    select @vMessageName = 'LPNMove_BeforeReceiverClosed_InvalidLocationType';
  else
  /* While InTransit/Received, do not allow change of Warehouse to beyond RO WH */
  if (@vReceiverStatus = 'O') and
     (@vAllowNewInvBeforeReceiverClose = 'N') and
     (@vLPNStatus in ('T', 'R' /* InTransit/Received */)) and
     (@vToLocWarehouse not in (select TargetValue
                               from dbo.fn_GetMappedValues('CIMS', @vROWarehouse, 'CIMS', 'Warehouse', 'Receiving', @BusinessUnit)))
    select @vMessageName = 'LPNMove_BeforeReceiverClosed_InvalidWarehouse';
  else
    /* Other custom validations */
    exec pr_RuleSets_Evaluate 'LPN_ValidateInventoryMovement', @vRulesDataXML, @vMessageName output;

ErrorHandler:
  /* If there are any errors, then set return code appropriately */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_ValidateInventoryMovement */

Go
