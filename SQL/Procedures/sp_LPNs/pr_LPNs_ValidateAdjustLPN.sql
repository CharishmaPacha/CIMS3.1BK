/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/20  MS      pr_LPNs_ValidateAdjustLPN: Use LPNStatusDesc in vwLPNs (HA-604)
  2018/09/24  TK      pr_LPNs_ValidateAdjustLPN: User should be able to adjust an empty LPN if the SKU is set up (S2GCA-302)
  2018/03/09  MJ      pr_LPNs_ValidateAdjustLPN: Bugfix to allow alpha numeric values in Reference field instead of integer (S2G-320)
  2016/11/21  VM      pr_LPNs_ValidateAdjustLPN: Do not allow to adjust any replenish LPN (HPI-1069)
                      pr_LPNs_ValidateAdjustLPN: Included additonal validations.
  2014/03/27  PK      Added pr_LPNs_UI_AdjustLPN, pr_LPNs_ValidateAdjustLPN.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_ValidateAdjustLPN') is not null
  drop Procedure pr_LPNs_ValidateAdjustLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_ValidateAdjustLPN:
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_ValidateAdjustLPN
  (@LPNId         TRecordId,
   @LPN           TLPN,
   @ReasonCode    TReasonCode,
   @Reference     TReference,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vMsgParam1           TDescription,

          @vLPN                 TLPN,
          @vLPNId               TRecordId,
          @vLPNStatus           TStatus,
          @vLPNStatusDesc       TDescription,
          @vLPNQuantity         TQuantity,
          @vLPNType             TTypeCode,
          @vLPNOrderType        TTypeCode,
          @vLPNPalletId         TRecordId,
          @vLPNReservedQty      TQuantity,
          @vLPNLocation         TLocation,
          @vLostLocation        TLocation,
          @vAdjustAllocatedLPN  TFlag,
          @vSKUCount            TCount,
          @vInvalidLPNStatuses  TStatus;
begin
  select @vReturnCode  = 0,
         @vMessageName = null,
         @Reference    = nullif(@Reference, '');

  /* Fetch LPN info */
  select @vLPNId          = LPNId,
         @vLPN            = LPN,
         @vLPNStatus      = Status,
         @vLPNStatusDesc  = LPNStatusDesc,
         @vLPNQuantity    = Quantity,
         @vLPNType        = LPNType,
         @vLPNOrderType   = OrderType,
         @vLPNPalletId    = PalletId,
         @vLPNReservedQty = ReservedQty,
         @vLPNLocation    = Location
  from  vwLPNs
  where ((LPNId = @LPNId) or (LPN = @LPN)) and
        (BusinessUnit = @BusinessUnit);

  /* Get the SKU count */
  select @vSKUCount = count(distinct(SKUId))
  from LPNDetails
  where (LPNId = @vLPNId);

  /* Get the control variables */
  select @vLostLocation       = dbo.fn_Controls_GetAsString('ShortPick', 'MoveToLocation', 'LOST',
                                                            @BusinessUnit, @UserId),
         @vAdjustAllocatedLPN = dbo.fn_Controls_GetAsBoolean('Inventory', 'AdjustAllocatedLPN',
                                                             'N' /* No */, @BusinessUnit, @UserId),
         @vInvalidLPNStatuses = dbo.fn_Controls_GetAsString('LPN_Adjust', 'LPNInvalidStatus', 'SOCVT',
                                                            @BusinessUnit, @UserId);

  /* Validations */
  if (@vLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  /* User should be able to adjust an Picklane LPN if the SKU is set up even though Quantity is zero */
  if (@vSKUCount = 0) and (@vLPNType = 'L'/* Picklane */)
    set @vMessageName = 'LPNAdjust_EmptyLPN';
  else
  if (@vLPNQuantity <= 0) and (@vLPNType <> 'L'/* Picklane */)
    set @vMessageName = 'LPNAdjust_EmptyLPN';
  else
  if (charindex(@vLPNStatus, @vInvalidLPNStatuses) <> 0)
    select @vMessageName = 'LPNAdjust_InvalidStatus',
           @vMsgParam1   = @vLPNStatusDesc;
  else
  if (@vLPNLocation = @vLostLocation)
    select @vMessageName = 'LPNAdjust_CannotAdjustLOSTLPN';
  else
  --if (@vLPNType = 'L' /* Picklane */)
  --  set @vMessageName = 'LogicalLPN_InvalidOperation';
  --else
  if ((@vLPNStatus = 'A' /* Allocated */) and (@vAdjustAllocatedLPN = 'N' /* No */))
    set @vMessageName = 'LPNAdjust_CannotAdjustAllocatedLPN';
  else
  /* Do not allow adjust any replenish LPN as its destination location DR line Qty mis-matches */
  if (@vLPNOrderType in ('R', 'RU', 'RP' /* Replenish orders */))
    select @vMessageName = 'LPNAdjust_CannotAdjustReplenishLPN';
  else
  if (@ReasonCode = '199' /* Reverse Receipt */) and (@Reference is null)
    set @vMessageName = 'LPNAdjust_ReferenceCannotbeEmpty';

ErrorHandler:
  /* If there are any errors, then set return code appropriately */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vMsgParam1;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_ValidateAdjustLPN */

Go
