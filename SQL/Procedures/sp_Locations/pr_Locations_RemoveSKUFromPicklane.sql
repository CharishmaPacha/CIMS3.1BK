/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/15  VS      pr_Locations_RemoveSKUFromPicklane, pr_Locations_RemoveSKUs, pr_Locations_Action_RemoveSKUs:
  2016/11/24  RV      pr_Locations_RemoveSKUs: Calling pr_Locations_RemoveSKUFromPicklane instead of wraper
                      pr_Locations_RemoveSKUFromPicklane: Added validations and AT logs (HPI-1066)
  2016/11/10  TK      pr_Locations_RemoveSKUFromPicklane: If there are no details for the LPN then delete the LPN (HPI-1035)
  2016/06/04  TK      pr_Locations_AddSKUToPicklane & pr_Locations_RemoveSKUFromPicklane:
  2015/10/11  AY      pr_Locations_RemoveSKUFromPicklane: Bug fixes (SRI-390/CIMS-651).
  2015/09/09  RV      pr_Locations_RemoveSKUFromPicklane: Re calculate location count instead of subtract quantity two times (FB-343)
  2015/04/08  DK      pr_Locations_RemoveSKUFromPicklane: Bug fix to update Num LPN count on location.
  2015/02/14  DK      pr_Locations_RemoveSKUFromPicklane:Implemented functionality for operation 'RemoveAllSKUs'.
  2014/10/29  DK      pr_Locations_RemoveSKUFromPicklane: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_RemoveSKUFromPicklane') is not null
  drop Procedure pr_Locations_RemoveSKUFromPicklane;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_RemoveSKUFromPicklane: This procedure is to used to remove
  SKU from Picklane. If SKU already exists with some Qty then that LPN is adjusted
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_RemoveSKUFromPicklane
  (@SKUId       TRecordId,
   @LocationId  TRecordId,
   @LPNId       TRecordId,
   @InnerPacks  TInnerPacks,  -- Not used
   @Quantity    TQuantity,    -- Not used
   @Operation   TOperation = null,
   @UserId      TUserId,
   @ReasonCode  TReasonCode = null)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @Message           TDescription,
          @vRecordId         TInteger,

          @vLocation         TLocation,
          @vLocBusinessUnit  TBusinessUnit,
          @vLPNId            TRecordId,
          @vLPNDetailId      TRecordId,
          @vWarehouse        TWarehouse,
          @vSKUId            TRecordId,
          @vQuantity         TQuantity,
          @vSKU              TSKU,
          @vSKUStatus        TStatus,
          @vSKUBusinessUnit  TBusinessUnit,
          @vPrimaryLocId     TRecordId,
          @vPrimaryLoc       TLocation,
          @vPickingZone      TLookUpCode,
          @vAuditActivity    TActivityType;

  declare @ttLPNDetails Table
          (LPNId           TRecordId,
           LPNDetailId     TRecordId,
           SKUId           TRecordId,
           Quantity        TQuantity,
           OnhandStatus    TStatus,
           RecordId        TRecordId Identity(1,1),
           Primary Key     (RecordId));
begin
  SET NOCOUNT ON;

  select @vLPNDetailId = null,
         @vRecordId    = 0;

  /* Get the details from Locations */
  select  @vLocation        = Location,
          @vWarehouse       = Warehouse,
          @vLocBusinessUnit = BusinessUnit
  from Locations
  where (LocationId = @LocationId);

  /* Get SKU details from SKUs */
  select @vSKU             = SKU,
         @vSKUStatus       = Status,
         @vSKUBusinessUnit = BusinessUnit
  from SKUs
  where (SKUId = @SKUId);

  /* Get LPN in the Location which already has the SKU */
  select @vLPNId = LPNId
  from LPNs
  where (LPNId = @LPNId) and
        (SKUId = @SKUId);

  /* Validations */
  if (@vSKU is null)
    set @MessageName = 'InvalidSKU'
  else
  if (@vLocation is null)
    set @MessageName = 'InvalidLocation'
  else
  if (@vLPNId is null) and (@Operation = 'RemoveSKUs')
    set @MessageName = 'LocationRemoveSKU_SKUDoesNotExist';
  else
  /* If we have to skip this validation for any operation, then we need to exclude those operations, by default
     for any operation this check applies */
  if (@vQuantity > 0) --and (@Operation like 'RemoveSKU%')
    set @MessageName = 'SKURemove_InventoryExists_CannotRemove';
  else
  if (exists (select L.*
              from LPNs L
              where (L.LPNId = @vLPNId) and
                    (L.SKUId = @vSKUId) and
                    (L.OnhandStatus in ('R', 'D', 'DR' /* Reserved, Directed, Directed Reserved */))))
    set @MessageName = 'LocationRemoveSKU_DirRes_Lines';
  else
  if (@vLocBusinessUnit <> @vSKUBusinessUnit)
    set @MessageName = 'BusinessUnitMismatch'

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get all LPNDetails to zero out */
  insert into @ttLPNDetails (LPNId, LPNDetailId, SKUId, Quantity, OnhandStatus)
    select LPNId, LPNDetailId, SKUId, Quantity, OnhandStatus
    from LPNDetails
    where (LPNId        = @vLPNId) and
          (SKUId        = @SKUId) and
          (OnhandStatus = 'A' /* Available */);

  /* If there are no details for the LPN then delete the LPN */
  if (@@rowcount = 0) and not exists (select * from LPNDetails where LPNId = @vLPNId)
    exec pr_LPNs_Delete @vLPNId;

  /* Reduce the inventory from the LPN if there is quantity available in it */
  while (exists (select * from @ttLPNDetails where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId    = RecordId,
                   @vLPNId       = LPNId,
                   @vLPNDetailId = LPNDetailId,
                   @vQuantity    = Quantity
      from @ttLPNDetails
      where (RecordId > @vRecordId)
      order by RecordId;

      /* First zero out the qty and then remove the line */
      exec @Returncode = pr_LPNs_AdjustQty @vLPNId,
                                           @vLPNDetailId output,
                                           @SKUId,
                                           null /* SKU */,
                                           0,
                                           0, /* Zero out the qty */
                                           '=' /* Update Option - clear Qty */,
                                           'Y' /* Export Option */,
                                           @ReasonCode,
                                           null /* Reference */,
                                           @vLocBusinessUnit,
                                           @UserId;

      /* Next remove the line */
      exec @Returncode = pr_LPNs_AdjustQty @vLPNId,
                                           @vLPNDetailId output,
                                           @SKUId,
                                           null /* SKU */,
                                           0,
                                           -1, /* Remove the line */
                                           '=' /* Update Option - clear Qty */,
                                           'Y' /* Export Option */,
                                           @ReasonCode,
                                           null /* Reference */,
                                           @vLocBusinessUnit,
                                           @UserId;
    end

  /* check if the SKU is in any other Picklane Location and update Location Details on the SKU */
  select @vPrimaryLocId = min(LocationId)
  from vwLPNs
  where (SKUId   = @SKUId           )and
        (LPNType = 'L' /* Logical */);

  if (@vPrimaryLocId is not null)
    select @vPrimaryLoc  = Location,
           @vPickingZone = PickingZone
    from Locations
    where (LocationId = @vPrimaryLocId);

  /* Update Primary Location details on the SKU */
  /* if SKU exists in any of the PickLane Location then we would update those values else we will update null values */
  update SKUs
  set PrimaryLocationId = @vPrimaryLocId,
      PrimaryLocation   = @vPrimaryLoc,
      PrimaryPickZone   = @vPickingZone
  where (SKUId = @SKUId);

  /* In pr_LPNs_AdjustQty may or may not update Location Counts, So we need to re calculate locations quantity count */
  exec @ReturnCode = pr_Locations_UpdateCount @LocationId   = @LocationId,
                                              @UpdateOption = '*';

  /* Audit Trail */
  if (@Operation = 'RemoveAllSKUs')
    select @vAuditActivity = 'RemoveAllSKUsFromLocation';
  else
    select @vAuditActivity = 'RemoveSKUFromLocation';

  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @Quantity   = @vQuantity,
                            @SKUId      = @vSKUId,
                            @LPNId      = @vLPNId,
                            @LocationId = @LocationId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Locations_RemoveSKUFromPicklane */

Go
