/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  fn_LPNs_AllowNewInventory: Commented
  fn_LPNs_AllowNewInventory: Some callers passing in LocationId and some Location - fixed it.
  2018/06/12  RV      fn_LPNs_AllowNewInventory: Initial Version (S2GCA-25)
------------------------------------------------------------------------------*/

--Go

--if object_id('dbo.fn_LPNs_AllowNewInventory') is not null
  --  drop Function fn_LPNs_AllowNewInventory() returns TFlags as begin return 0 end')
--Go
--/*------------------------------------------------------------------------------
--  Function fn_LPNs_AllowNewInventory: Returns flag whether operations on Inventory are allowed or not
--------------------------------------------------------------------------------*/
--Create Function fn_LPNs_AllowNewInventory
--  (@LPNId         TRecordId,
--   @ToLocationId  TRecordId,
--   @Operation     TOperation)
--  -----------------------------------------------------------------
--  returns TFlags
--as
--begin
--  declare @vLPN            TLPN,
--          @vLPNStatus      TStatus,
--          @vToLocationType TTypeCode,
--          @vReceiverNumber TReceiverNumber,
--          @vReceiverStatus TStatus,
--          @vAllowNewInvBeforeReceiverClose
--                           TControlValue,
--          @vValidLocationTypesToMoveInvBeforeReceiverClose
--                           TControlValue,
--          @vAllowPutaway   TFlags,
--
--          @vBusinessUnit   TBusinessUnit,
--          @vUserId         TUserId;
--
--  select @vLPN            = LPN,
--         @vLPNStatus      = Status,
--         @vReceiverNumber = ReceiverNumber,
--         @vBusinessUnit   = BusinessUnit
--  from LPNs
--  where (LPNId = @LPNId);
--
--  if (@ToLocationId is not null)
--    select @vToLocationType = LocationType
--    from Locations
--    where (LocationId = @ToLocationId);
--
--  select @vAllowNewInvBeforeReceiverClose                 = dbo.fn_Controls_GetAsString('Inventory', 'AllowNewInvBeforeReceiverClose', 'N' /* No */, @vBusinessUnit, @vUserId),
--         @vValidLocationTypesToMoveInvBeforeReceiverClose = dbo.fn_Controls_GetAsString('TransferInventory', 'ValidLocationTypesToMoveInvBeforeReceiverClose', 'SD' /* Staging/Dock */, @vBusinessUnit, @vUserId);
--
--  select @vReceiverStatus = Status
--  from Receivers
--  where (ReceiverNumber = @vReceiverNumber);
--
--  /* Do not allow cycle counting before receiver close */
--  if (@Operation = 'CycleCount') and (@vAllowNewInvBeforeReceiverClose = 'N') and (@vReceiverStatus = 'O' /* Open */)
--    set @vAllowPutaway = 'N' /* No */;
--  else
--  /* Allow Move/Putaway LPN between Staging/Dock locations before Receiver close */
--  if (@vLPNStatus in ('T', 'R' /* InTransit/Received */)) and (charindex(@vToLocationType, @vValidLocationTypesToMoveInvBeforeReceiverClose) > 0) and
--     (@Operation in ('Move', 'Transfer'))
--    set @vAllowPutaway = 'Y' /* Yes */;
--  else
--  if (@vAllowNewInvBeforeReceiverClose = 'N' /* No */) and (@vReceiverStatus = 'O' /* Open */) and
--     (@vLPNStatus in ('T', 'R' /* InTransit/Received */))
--    set @vAllowPutaway = 'N' /* No */;
--  else
--    set @vAllowPutaway = 'Y'/* Yes */;
--
--  return (@vAllowPutaway);
--end /* fn_LPNs_AllowNewInventory */
--
--Go
