/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/24  RKC     pr_Picking_ValidateSubstitution: Added validations for Substitutions process
  2020/10/26  PK      pr_Picking_ValidateSubstitution: Added validation to not to allow substitution of different owner inventory (S2GCA-1353)
  2019/09/24  MS      pr_Picking_ValidateSubstitution: Validate not to allow inventory substituted from PickLane Location (OB2-976)
  2019/09/24  MS      pr_Picking_ValidateSubstitution: Validate not to allow inventory sustituted from PickLane Location (OB2-976)
  2015/09/15  TK      pr_Picking_ValidateSubstitution: Changed validation message (ACME-319)
                      pr_Picking_ValidateSubstitution: Validate the substituted LPN exists or not.
  2015/02/04  VM      pr_Picking_SwapLPNsDataForSubstitution, pr_Picking_ValidateSubstitution: Introduced
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ValidateSubstitution') is not null
  drop Procedure pr_Picking_ValidateSubstitution;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_ValidateSubstitution:

  1. Both LPNs should be in the same location
  2. Both LPNs should have the same SKU and have a single SKU
  3. If it's an LPN pick then both the LPNs should have the same quantity - if not replenishment
  4. If it's an LPN pick for replenish then subsitution LPN can have more qty as we may overallocate
     for replenishments. However, since the reservations need to be swapped, the reserved qty in that
     LPN cannot be more than that of the actual LPN
  5. If it's a unit Pick then both LPNs should have same qty - with some exceptions below
  5a.  If both LPNs have a reserved line with same qty, then we can swap the lines, so we can allow that.
  5b.  If both LPNs have same total reserved qty, then we can swap all those liens, so we can allow that.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_ValidateSubstitution
  (@ActualLPNId           TRecordId,
   @SubstitutedLPNId      TRecordId,
   @TaskDetailId          TRecordId,
   @PickMode              TControlValue,
   @ValidLPNToSubstitute  TLPN output,
   @SubstitutionScenario  TString = null output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,

          @vActualLPNId               TRecordId,
          @vActualLPN                 TLPN,
          @vActualLPNLocationId       TRecordId,
          @vActualLPNSKUId            TRecordId,
          @vActualLPNTotalQty         TQuantity,
          @vActualLPNWaveId           TRecordId,
          @vActualLPNWaveNo           TWaveNo,
          @vActualLPNOwnership        TOwnership,
          @vActualLPNWarehouse        TWarehouse,
          @vActualLPNTotalAQty        TQuantity,
          @vActualLPNTotalRQty        TQuantity,

          @vWaveId                    TRecordId,
          @vWaveNo                    TWaveNo,
          @vWavetype                  TTypeCode,

          @vTaskSubType               TTypeCode,
          @vTDQuantity                TQuantity,

          @vSubstitutedLPNId          TRecordId,
          @vSubstitutedLPN            TLPN,
          @vSubstitutedLPNType        TTypeCode,
          @vSubstititedLPNStatus      TStatus,
          @vSubstitutedLPNLocationId  TRecordId,
          @vSubstitutedLPNOwnership   TOwnership,
          @vSubstitutedLPNWarehouse   TWarehouse,
          @vSubstitutedLPNSKUId       TRecordId,
          @vSubstitutedLPNTotalQty    TQuantity,
          @vSubstitutedLPNTaskSubType TTypeCode,
          @vSubstitutedLPNTotalAQty   TQuantity,
          @vSubstitutedLPNTotalRQty   TQuantity,

          @vCrossWarehouseSubstitution TControlValue,
          @vCrossLocationSubstitution  TControlValue,
          @vSameQtyWithRLineExists     TControlValue,
          @vBusinessUnit               TBusinessUnit;
begin /* pr_Picking_ValidateSubstitution */

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* 1. 1. Identify the detail for Actual LPN */
  select @vActualLPNId           = LPNId,
         @vActualLPNLocationId   = LocationId,
         @vActualLPNSKUId        = SKUId,
         @vActualLPNTotalQty     = Quantity,
         @vActualLPNWaveNo       = PickBatchNo,
         @vActualLPNOwnership    = Ownership,
         @vActualLPNWarehouse    = DestWarehouse,
         @vBusinessUnit          = BusinessUnit
  from LPNs
  where (LPNId = @ActualLPNId);

  /* Get the Actuval LPNDetails QTy's */
  select @vActualLPNTotalRQty = sum(iif(OnhandStatus in ('R'/* Reserved  */), Quantity, 0)),
         @vActualLPNTotalAQty = sum(iif(OnhandStatus in ('A'/* Available */), Quantity, 0))
  from LPNDetails
  where (LPNId = @ActualLPNId);

  /* Get the current pick TaskType */
  select @vTaskSubType = PickType,
         @vWaveId      = WaveId,
         @vTDQuantity  = Quantity
  from TaskDetails
  where (TaskDetailId = @TaskDetailId);

  /* Get the Wave info */
  select @vWaveNo   = WaveNo,
         @vWavetype = WaveType
  from Waves
  where (WaveId = @vWaveId);

  /* 2. Identify Details for Substituted LPN */
  select @vSubstitutedLPNId           = LPNId,
         @vSubstitutedLPN             = LPN,
         @vSubstitutedLPNType         = LPNType,
         @vSubstitutedLPNLocationId   = LocationId,
         @vSubstititedLPNStatus       = Status,
         @vSubstitutedLPNSKUId        = SKUId,
         @vSubstitutedLPNTotalQty     = Quantity,
         @vSubstitutedLPNOwnership    = Ownership,
         @vSubstitutedLPNWarehouse    = DestWarehouse
  from LPNs
  where LPNId = @SubstitutedLPNId;

  /* Get the Substituted LPN associated TaskType */
  select @vSubstitutedLPNTaskSubType  = T.TaskSubType
  from Tasks T
    join TaskDetails TD on (T.TaskId = TD.TaskId) and
                           (TD.Status not in ('C','X'))
  where (TD.LPNId = @SubstitutedLPNId);

  /* Get the Sub LPNDetails QTy's */
  select @vSubstitutedLPNTotalRQty = sum(iif(OnhandStatus in ('R'/* Reserved */),  Quantity, 0)),
         @vSubstitutedLPNTotalAQty = sum(iif(OnhandStatus in ('A'/* Available */), Quantity, 0))
  from LPNDetails
  where (LPNId = @SubstitutedLPNId);

  /* Both the LPNDetail Reserved Line Qty Match then we need to set the Variable to Y for Skip the validations */
  select @vSameQtyWithRLineExists = 'Y'
  from LPNDetails ALD
   join LPNDetails SLD on (ALD.Quantity     = SLD.Quantity) and
                          (ALD.Onhandstatus = SLD.Onhandstatus) and
                          (ALD.Onhandstatus= 'R') and (SLD.Onhandstatus = 'R')
  where ALD.LPNId = @vActualLPNId and SLD.LPNId = @vSubstitutedLPNId

  /* Get the values from controls */
  select @vCrossWarehouseSubstitution = dbo.fn_Controls_GetAsBoolean('BatchPicking', 'CrossWarehouseSubstitution', 'N'/* No */, @vBusinessUnit, null /* UserId*/),
         @vCrossLocationSubstitution  = dbo.fn_Controls_GetAsBoolean('BatchPicking', 'CrossLocationSubstitution',  'N'/* No */, @vBusinessUnit, null /* UserId*/);

  if (@vSubstitutedLPNId is null)
    select @vMessageName = 'LPNIsRequired';
  else
  if (@PickMode = 'Consolidated')
    select @vMessageName = 'Substitution_InvalidPickMode';
  else
  if (@vSubstitutedLPNType = 'L')
    select @vMessageName = 'Substitute_LogicalLPNCannotBeSubstituted';
  else
  if  (@vCrossWarehouseSubstitution = 'N') and (@vActualLPNWarehouse <> @vSubstitutedLPNWarehouse)
    select @vMessageName = 'Substitute_WarehouseMismatch';
  else
  if (@vActualLPNOwnership <> @vSubstitutedLPNOwnership)
    select @vMessageName = 'Substitute_OwnershipMismatch';
  else
  if (@vSubstititedLPNStatus = 'N'/* New */)
    select @vMessageName = 'Substitute_NewLPNCannotBeSubstituted';
  else
  if (@vSubstititedLPNStatus = 'K'/* Picked */)
    select @vMessageName = 'Substitute_PickedLPNCannotBeSubstituted';
  else
  if (@vSubstititedLPNStatus not in ('P', 'A' /* Putaway, Allocated */))
    select @vMessageName = 'Substitute_InvalidLPNStatus';
  else
  if (@vCrossLocationSubstitution = 'N') and (@vActualLPNLocationId <> coalesce(@vSubstitutedLPNLocationId, ''))
    set @vMessageName = 'Substitute_LPNsLocationsDifferent';
  else
  if (nullif(@vActualLPNSKUId, '') is null) or (nullif(@vSubstitutedLPNSKUId,'') is null)
    set @vMessageName = 'Substitute_NotAllowedBetweenMultiSKULPNs';
  else
  if (@vActualLPNSKUId <> @vSubstitutedLPNSKUId)
    set @vMessageName = 'Substitute_LPNsHasDifferentSKUs';
  else
  if (coalesce(@vSubstitutedLPNTaskSubType, '') <> '') and
     (coalesce(@vTaskSubType, '') <> '') and
     (@vSubstitutedLPNTaskSubType <> @vTaskSubType)
    set @vMessageName = 'Substitute_TaskSubTypeMismatch';
  else
  /* if both LPNs have a reserved line, then we can just swap the lines and their quantities
     do not matter, so allow it */
  if (@vTaskSubType = 'U' /* Unit Pick */) and (@vSameQtyWithRLineExists = 'Y')
    select @vMessageName         = null,
           @SubstitutionScenario = 'SwapTDwithReservedLine';
  else
  /* If both LPNs have same Reserved Qty, then we can swap the reservations even if the LPNs
     have diff. qty, so allow it */
  if (@vTaskSubType = 'U' /* Unit Pick */) and (@vActualLPNTotalRQty = @vSubstitutedLPNTotalRQty)
    select @vMessageName         = null,
           @SubstitutionScenario = 'SwapAllReservedLines';
  else
  /* if substituted LPN has enough available qty to pick this task, then we can just move
     this TD to the other LPN */
  if (@vTaskSubType = 'U' /* Unit Pick */) and
     (coalesce(@vSubstitutedLPNTotalAQty, 0) > @vTDQuantity)
    select @vMessageName         = null,
           @SubstitutionScenario = 'MoveTD';
  else
  if (@vTaskSubType = 'U' /* Unit Pick */) and
     (@vActualLPNTotalQty <> @vSubstitutedLPNTotalQty)
    set @vMessageName = 'Substitute_LPNsQuantityMismatch';
  else
  /* If Picking LPN, then other LPN should be of same qty, else we cannot swap, for replenish waves
     we can over pick, so the rule is different and validated later */
  if (@vWavetype not in ('R','RU'))  and
     (@vTaskSubType = 'L' /* LPN Pick */) and
     (@vActualLPNTotalQty <> @vSubstitutedLPNTotalQty)
    set @vMessageName = 'Substitute_LPNsQuantityMismatch';
  else
  /* For replenishment picking allow to pick more than required Qty but should not allow less than quantity
     so if we are to pick LPN with 10 units and want to substitute for an LPN with 8 units, it is not possible
     but if we want to substitute with an LPN of 12 units, then it is possible only if the other LPN does
     not have reserved qty more than the 10 units. */
  if (@vWavetype in ('R','RU')) and
     ((@vActualLPNTotalQty > @vSubstitutedLPNTotalQty) or
      (@vSubstitutedLPNTotalRQty < @vActualLPNTotalQty))
    set @vMessageName = 'Substitute_LPNsQuantityMismatch';

  if (@vMessageName is null)
    select @ValidLPNToSubstitute = @vSubstitutedLPN,
           @SubstitutionScenario = coalesce(@SubstitutionScenario, 'SwapLPNs');

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_ValidateSubstitution */

Go
