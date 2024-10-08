/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/14  RIA     pr_RFC_AddSKUToLocation: Added output parameter (HA-1688)
  2020/07/29  TK      pr_RFC_AddSKUToLocation & pr_RFC_TransferInventory: Changes to consider InventoryClass (HA-1246)
  2020/07/20  RIA     pr_RFC_AddSKUToLocation: Changes to add Inv Class (HA-652)
                      pr_RFC_AddSKUToLocation: Changes to pr_Locations_AddSKUToPicklane signature (S2GCA-216)
  2018/06/01  TK      pr_RFC_AddSKUToLocation: Bug fix to compute quantity if user is adding inventory in cases (S2G-888)
  2018/03/30  TK      pr_RFC_AddSKUToLocation: Do not allow user to set up SKU in case storage location is SKU configs are missing (S2G-426)
  2018/03/21  RT/AY   pr_RFC_AddSKUToLocation: Corrected Inactive SKU validation (S2G-454)
  2015/12/11  SV      pr_RFC_AddSKUToLocation, pr_RFC_RemoveSKUFromLocation, pr_RFC_UpdateSKUAttributes, pr_RFC_ValidateLocation,
  2015/05/05  OK      pr_RFC_AddSKUToLocation, pr_RFC_AdjustLocation, pr_RFC_ConfirmCreateLPN, pr_RFC_Inv_DropBuildPallet,
  2015/01/09  PKS     pr_RFC_AddSKUToLocation: Validation added to void removing SKU when location has Reserved or Directed Lines
  2014/10/29  DK      pr_RFC_AddSKUToLocation: Added new parameter 'Operation'
  2014/08/18  TK      pr_RFC_AddSKUToLocation: Updated not to allow user to add Inactive SKU to Location.
  2014/07/21  PK      pr_RFC_AddSKUToLocation: Validating Inactive SKUs based on control variable.
  2014/07/09  PK      pr_RFC_AddSKUToLocation: Allowing to add SKU to location even with zero quantity if the location
  2014/05/04  AY      pr_RFC_AddSKUToLocation: Changed validations to be in sync with messages
                      pr_RFC_AddSKUToLocation, pr_RFC_AdjustLocation: Validations for Picklane case storage.
  2014/03/17  TD      pr_RFC_AddSKUToLocation:Changes to differentiate validations for picklanes.
  2013/04/08  AY      pr_RFC_AddSKUToLocation: Allow to enter zero or -1 for qty for Static Locations
  2013/03/15  PKS     pr_RFC_AddSKUToLocation & pr_RFC_AddSKUToLPN: Used function fn_SKUs_GetSKU to fetch SKU Information
  2013/03/05  PKS     pr_RFC_AddSKUToLocation & pr_RFC_AddSKUToLPN: Validation added to avoid adding Inactive SKU to Location
  2012/10/06  YA      pr_RFC_AddSKUToLocation: Modified to show Audittrail under LPNs.
              PK      pr_RFC_AddSKUToLocation: Bug fix verifying left char of location storage type.
                      pr_RFC_AddSKUToLocation: Do not allow adding SKUs except to Unit Storage Picklane.
  2012/08/30  AY      pr_RFC_AddSKUToLocation: Bug fix, was setting new units and not adding.
  2011/08/18  TD      pr_RFC_AddSKUToLocation, pr_RFC_TransferInventory: Enhanced to
  2011/01/22  VM      pr_RFC_AddSKUToLocation: AllowMulitpleSKUs validation corrected
  2010/11/24  PK      Implemented Functionality for pr_RFC_AddSKUToLocation, pr_RFC_AdjustLocation,
  2010/11/19  PK      Created pr_RFC_MoveLPN, pr_RFC_AddSKUToLocation, pr_RFC_AdjustLocation
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_AddSKUToLocation') is not null
  drop Procedure pr_RFC_AddSKUToLocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_AddSKUToLocation:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_AddSKUToLocation
  (@LocationId      TRecordId,
   @Location        TLocation,
   @NewSKUId        TRecordId,
   @NewSKU          TSKU,
   @NewInnerPacks   TInnerPacks,
   @NewQuantity     TQuantity,
   @ReasonCode      TReasonCode = null,
   @Operation       TOperation = null, /* Future Use */
   @InventoryClass1 TInventoryClass = '',
   @InventoryClass2 TInventoryClass = '',
   @InventoryClass3 TInventoryClass = '',
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @LPNId           TRecordId    = null output)
as
  declare @vLocationType         TLocationType,
          @vLocationSubType      TLocationType,
          @vStorageType          TStorageType,
          @LPN                   TLPN,
          @DeviceId              TDeviceId,

          @ReturnCode            TInteger,
          @MessageName           TMessageName,
          @Message               TDescription,
          @vLocationId           TRecordId,
          @vNewSKUId             TRecordId,
          @vSKUStatus            TStatus,
          @vUnitsPerCase         TQuantity,
          @vAuditActivity        TActivityType,
          @vValidateInactiveSKU  TSKU,

          @vActivityLogId        TRecordId,
          @xmlResult             xml;
begin
begin try
  SET NOCOUNT ON;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @vLocationId, @Location, 'Location',
                      @Value1 = @NewSKU, @Value2 = @NewInnerPacks, @Value3 = @NewQuantity,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  select @NewSKUId      = nullif(@NewSKUId, 0),
         @NewInnerPacks = coalesce(@NewInnerPacks, 0),
         @NewQuantity   = coalesce(@NewQuantity , 0);

  /* Get control value to Validate Inactive SKU */
  select @vValidateInactiveSKU = dbo.fn_Controls_GetAsString('SKU_Inactive', 'SetupPickLane', 'N' /* No */,
                                                              @BusinessUnit, @UserId);

  /* Validate Location */
  select @Location         = Location,
         @vLocationId      = LocationId,
         @vLocationType    = LocationType,
         @vLocationSubType = LocationSubType,
         @vStorageType     = StorageType
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (@LocationId, @Location, null /* DeviceId */, @UserId, @BusinessUnit));

  /* Validate SKU */
  if (@NewSKUId is not null)
    select @vNewSKUId  = SKUId,
           @vSKUStatus = Status
    from SKUs
    where (SKUId = @NewSKUId);
  else
    /* Get the latest SKU Info */
    select top 1 @vNewSKUId  = SKUId,
                 @vSKUStatus = Status
    from dbo.fn_SKUs_GetScannedSKUs (@NewSKU, @BusinessUnit);

  if (@vNewSKUId is not null)
    select @vUnitsPerCase = UnitsPerInnerPack
    from SKUs
    where (SKUId = @vNewSKUId);

  /* If Quantity is zero and user trying to add inventory in cases then compute
     quantity using UnitsPerCase */
  if (@NewInnerPacks > 0) and (@NewQuantity = 0) and (@vUnitsPerCase > 0)
    select @NewQuantity = @NewInnerPacks * @vUnitsPerCase;

  /* Validations */
  if ((@vSKUStatus = 'I' /* Inactive */) and (@vValidateInactiveSKU = 'Y' /* Yes */))
    set @MessageName = 'LocationAddSKU_SKUIsInactive';
  else
  if (@vLocationId is null)
    set @MessageName = 'LocationDoesNotExist';
  else
  if (@vNewSKUId is null)
    set @MessageName = 'SKUDoesNotExist';
  else
  if (@vLocationType <> 'K'/* Picklane */)
    set @MessageName = 'LocationAdjust_NotAPicklane';
  else
  if ((Left(@vStorageType, 1) in ('U' /* Units */, 'P')) and
      (@NewQuantity = 0) and (@NewInnerPacks = 0) and
      (@vLocationSubType = 'D' /* Dynamic */))
    set @MessageName = 'LocationAddSKU_DynamicPicklane';
  else
  if ((Left(@vStorageType, 1) = 'U' /* Units */) and
      (@vLocationSubType = 'D' /* Dynamic */) and
      (@NewQuantity = 0))
    set @MessageName = 'LocationAddSKU_UnitPicklane';
  else
   if ((Left(@vStorageType, 1) = 'P' /* Packages/Cases */) and
       (@vLocationSubType = 'D' /* Dynamic */) and
       (@NewInnerPacks = 0))
    set @MessageName = 'LocationAddSKU_CasePicklane';
  else
  if ((Left(@vStorageType, 1) = 'P' /* Packages/Cases */) and
      (@vLocationSubType = 'S' /* Static */) and
      (@vUnitsPerCase = 0))
    set @MessageName = 'LocationAddSKU_InvaildSKUPackConfig';
  else
  /* Validate Quantity */
  if ((@vLocationSubType = 'D') and (@NewQuantity < 0)) or
     ((@vLocationSubType = 'S') and (@NewQuantity < -1))
    set @MessageName = 'InvalidQuantity';
  else
  if (coalesce(@ReasonCode, '') = '') and
     ((@NewInnerPacks > 0) or (@NewQuantity > 0))
    set @MessageName = 'LocationAddSKU_ReasonCodeRequired';

  if (@MessageName is not null)
     goto ErrorHandler;

   /* vNewSKUId and NewSkuId both are same.Now using vNewSKuid,because we are getting
      the skuid based on the sku or skuId send by the User.So it is not be the Exception cae.  */
   exec @Returncode = pr_Locations_AddSKUToPicklane @vNewSKUId,
                                                    @vLocationId,
                                                    @NewInnerPacks,
                                                    @NewQuantity,
                                                    null /* Lot */,
                                                    null /* Ownership */,
                                                    @InventoryClass1,
                                                    @InventoryClass2,
                                                    @InventoryClass3,
                                                    '+' /* Update Option */,
                                                    'Y' /* Export Option */,
                                                    @UserId,
                                                    @ReasonCode,
                                                    @LPNId output;

  /* set audit activity  */
  select @vAuditActivity = case
                             when (@Operation = 'AddSKU') then
                               'AddSKU'
                              else
                               'AddSKUAndInventory'
                           end
  from Locations
  where LocationId = @vLocationId;

  /* Audit Trail */
  if (@ReturnCode = 0)
    begin
      exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                @LPNId      = @LPNId,
                                @SKUId      = @vNewSKUId,
                                @InnerPacks = @NewInnerPacks,
                                @Quantity   = @NewQuantity,
                                @LocationId = @vLocationId;
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  /* Log the error */
  exec pr_RFLog_End null, @@ProcId, @ActivityLogId = @vActivityLogId output;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_AddSKUToLocation */

Go
