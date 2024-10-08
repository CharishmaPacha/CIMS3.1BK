/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/15  TK      pr_RFC_AdjustLocation & pr_RFC_AdjustLPN: Validation to restrict user adjusting quantity less than reserved quantity (CID-1724)
  2021/02/05  TK      pr_RFC_AdjustLocation: Bug fix SKUId on LPN Detail is being updated with LPNDetailId (BK-159)
  2020/11/24  RIA     pr_RFC_AdjustLocation: Changes to consider LPNDetailId (CIMSV3-1236)
  2018/11/28  DK      pr_RFC_AdjustLocation: Bug fix to raise error if user tries to cc with zero qty if reserve qty exists in location (HPI-2178)
  2016/12/08  VM      pr_RFC_TransferInventory: Calling procedure switch to handle adding inventory to location in a different way (HPI-1113)
                      pr_RFC_AdjustLocation: Code clean-up
  2015/09/07  OK      pr_RFC_AdjustLocation: Made changes to display total Qty in Audit Trail Log (FB-339).
  2015/05/05  OK      pr_RFC_AddSKUToLocation, pr_RFC_AdjustLocation, pr_RFC_ConfirmCreateLPN, pr_RFC_Inv_DropBuildPallet,
                      pr_RFC_Inv_MovePallet, pr_RFC_MoveLPN, pr_RFC_RemoveSKUFromLocation, pr_RFC_TransferInventory,
                      pr_RFC_ValidateLocation: Made system compatable to accept either Location or Barcode.
  2015/03/10  DK      pr_RFC_AdjustLocation: Validation added to not to adjust down the reserved inventory.
              AY      pr_RFC_AdjustLocation: Allow to adjust up a location even if everything is reserved in the Location
  2015/01/12  VM/PV   pr_RFC_AdjustLocation: Changes to use param changes of pr_RFC_ValidateLocation
  2014/07/19  PKS     pr_RFC_AdjustLocation: ReasonCode added in logging AT record
  2014/07/15  PK      pr_RFC_AdjustLocation: On confirmation returning the updated information to the user.
  2014/05/19  TD      pr_RFC_AdjustLocation: Ignore validating location same quantity while cycle counting.
  2014/04/22  TD      pr_RFC_AdjustLocation/pr_RFC_AdjustLPN: Ensure user gives ReasonCode when adjusting Quantity.
  2014/03/18  TD      pr_RFC_TransferInventory:Changes to handle with innerpacks/Quantity.
                      pr_RFC_AddSKUToLocation, pr_RFC_AdjustLocation: Validations for Picklane case storage.
                      pr_RFC_ValidateLocation: Changes to pass default UoM to RF.
  2103/04/16  TD      pr_RFC_AdjustLocation: Getting SKU based on the description.
  2013/03/27  AY      pr_RFC_AdjustLocation & pr_RFC_AdjustLPN: Used function to fetch SKUs
  2012/06/04  AY      pr_RFC_AdjustLocation: Restrict to Picklane
  2011/11/02  AY      pr_RFC_AdjustLocation: Bug fix - Multiple-SKU picklanes was not handled properly.
  2010/11/24  PK      Implemented Functionality for pr_RFC_AddSKUToLocation, pr_RFC_AdjustLocation,
  2010/11/19  PK      Created pr_RFC_MoveLPN, pr_RFC_AddSKUToLocation, pr_RFC_AdjustLocation
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_AdjustLocation') is not null
  drop Procedure pr_RFC_AdjustLocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_AdjustLocation: When we adjust a Location, the user is giving the
   final quantity in the location. This includes both Available and reserved as
   user cannot distinguish between the two. For example, when Cycle counting,
   user specified say 20 cases - it means there are 20 cases in the Location
   user does not know that 3 cases may be reserved and 17 available. As we do
   not allow change to reserved cases/qty. So, we have to decrement the reserved
   and only update the available qty.

   This procedure is used directly by RF - Adjust Location as well as by Cycle count
   process. The above explanation of user giving total qty in the location is
   applicable during cycle count process, but not during RF Adjust Location. In RF
   adjust location, user is able to select the available line only and adjust
   that line, so we don't need to deduct the ReservedQty.
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_AdjustLocation
  (@LocationId       TRecordId,
   @Location         TLocation,
   @CurrentSKUId     TRecordId,
   @CurrentSKU       TSKU,
   @NewInnerPacks    TInnerPacks, /* Future Use */
   @NewQuantity      TQuantity,
   @ReasonCode       TReasonCode = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vMessage              TDescription,
          @DeviceId              TDeviceId,

          @vLocationId           TRecordId,
          @vLocationType         TTypeCode,
          @vLPNId                TRecordId,
          @vLPNDetailId          TRecordId,
          @vLPNInnerPacks        TInnerPacks,
          @vLPNQuantity          TQuantity,
          @vLPNReservedQuantity  TQuantity,
          @vCurrentSKUId         TRecordId,
          @vCurrentSKU           TSKU,
          @vStorageType          TTypeCode,
          @vNumLines             TCount,
          @vNumLPNs              TCount,
          @vReservedCases        TInnerPacks,
          @vReservedQty          TQuantity,
          @vCasesToUpdate        TInnerPacks,
          @vQtyToUpdate          TQuantity,

          @vMsgParam1            TDescription,
          @vActivityLogId        TRecordId,
          @xmlResult             TXML;
begin
begin try

  SET NOCOUNT ON;

  select @CurrentSKUId  = nullif(@CurrentSKUId, 0),
         @NewInnerPacks = coalesce(@NewInnerPacks, 0),
         @NewQuantity   = coalesce(@NewQuantity, 0),
         @ReasonCode    = nullif(@ReasonCode, '');

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @vLocationId, @Location, 'Location',
                      @Value1 = @CurrentSKUId, @Value2 = @CurrentSKU, @Value3 = @NewQuantity,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get Location Info */
  select @LocationId    = LocationId,
         @vLocationId   = LocationId,
         @Location      = Location,
         @vLocationType = LocationType,
         @vStorageType  = left(StorageType, 1),
         @vNumLPNs      = NumLPNs
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (@LocationId, @Location,  null /* DeviceId */, @UserId, @BusinessUnit));

  /* If caller has passed an LPN Detail, then use treat input CurrSKUId as LPNDetailId
     We had to do this so that the signature of the procedure would not change and */
  if (@CurrentSKU = 'LPNDETAIL')
    select @vLPNDetailId   = LPNDetailId,
           @vLPNId         = LPNId,
           @CurrentSKUId   = SKUId,
           @vLPNInnerPacks = InnerPacks,
           @vLPNQuantity   = Quantity
    from LPNDetails
    where (LPNDetailId = @CurrentSKUId);

  /* Get SKU Info */
  if (@CurrentSKUId is not null)
    select @vCurrentSKUId = SKUId,
           @vCurrentSKU   = SKU
    from SKUs
    where (SKUId = @CurrentSKUId);
  else
    select @vCurrentSKUId = SKUId,
           @vCurrentSKU   = SKU
    from dbo.fn_SKUs_GetScannedSKUs (@CurrentSKU, @BusinessUnit);

  /* Get LPN of the Location */
  if (@vLPNId is null)
    select @vLPNId = LPNId
    from LPNs
    where (LocationId = @vLocationId) and
          (SKUId      = @vCurrentSKUId) and
          (Status <> 'I' /* Inactive */);

  /* select LPNDetail, LPNLine and SKU on selected LPN from Location */
  if (@vLPNDetailId is null)
    select @vLPNDetailId   = LPNDetailId,
           @vLPNInnerPacks = InnerPacks,
           @vLPNQuantity   = Quantity
    from LPNDetails
    where (LPNId = @vLPNId) and
          (SKUId = @vCurrentSKUId) and
          (OnhandStatus = 'A' /* Available */);

  /* Get reserved qty on the lpn */
  /* For a picklane, we need to consider total Reserved qty on all the lines not only on reserved lines.
     Even available lines will have reserved quantity when there are pending reserve lines from the LPN */
  select @vReservedCases = sum(case when UnitsPerPackage > 0 then ReservedQty / UnitsPerPackage else 0 end),
         @vReservedQty   = sum(ReservedQty)
  from LPNDetails
  where (LPNId = @vLPNId) and
        (SKUId = @vCurrentSKUId);

  /* Compute the qty to update by reducing the reserved Cases/Qty as we only update the Available Qty.
     See notes above for more detailed explanation. Also, we expect only Cases or Units based upon storage
     type and let the AdjustQty procedure compute */
  if (@ReasonCode = '100' /* Cycle Count */)
    begin
      select @vCasesToUpdate = case when @NewInnerPacks > 0 then @NewInnerPacks - @vReservedCases else 0 end,
             @vQtyToUpdate   = case when @NewQuantity >= 0 then @NewQuantity   - @vReservedQty else 0 end;
    end
  else
    begin
      select @vCasesToUpdate = case when @NewInnerPacks > 0 then @NewInnerPacks else 0 end,
             @vQtyToUpdate   = case when @NewQuantity > 0 then @NewQuantity else 0 end;
    end

  /* Get the LPNdetails line count */
  select @vNumLines = count(*)
  from LPNDetails
  where (LPNId = @vLPNId);

  if (@vLocationId is null)
    set @vMessageName = 'LocationDoesNotExist';
  else
  if (@vLocationType <> 'K' /* Picklane */)
    set @vMessageName = 'LocationAdjust_NotAPicklane';
  else
  if ((Left(@vStorageType, 1) <> 'U' /* Units */) and (@NewQuantity > 0) and
      (@NewInnerPacks = 0))
    set @vMessageName = 'LocationAdjust_NotAUnitPicklane';
  else
  if ((Left(@vStorageType, 1) <> 'P' /* Packages/Cases */) and (@NewInnerPacks > 0) and
      (@NewQuantity = 0))
    set @vMessageName = 'LocationAdjust_NotACasePicklane';
  else
  if (@vCurrentSKUId is null)
    set @vMessageName = 'SKUDoesNotExist';
  else
  if (@vLPNDetailId is null) and
     (not exists (select *
                 from LPNDetails
                 where (LPNId = @vLPNId) and
                       (SKUId = @vCurrentSKUId)))
    set @vMessageName = 'LocationDoesnotHaveSKUToAdjust';
  else
  /* Allow an available line to be added, if QtyToUpdate < 0 then it would be caught below */
  if ((@vLPNDetailId is null) and (@NewQuantity < @vLPNReservedQuantity))
    set @vMessageName = 'NoAvailableInventoryToAdjust';
  else
  /* Validate Quantity */
  if (@NewInnerPacks < 0)
    set @vMessageName = 'InvalidInnerPacks';
  else
  if (@NewQuantity < 0)
    set @vMessageName = 'InvalidQuantity';
  else
  if (@vCasesToUpdate < 0) or (@vQtyToUpdate < 0)
    begin
      select @vMessageName = 'LocationAdjust_' + @vStorageType + '_CannotAdjustReservedQty',
             @vMsgParam1   = case when @vStorageType = 'P' then @vReservedCases else @vReservedQty end;
    end
  else
  if (@NewInnerPacks = @vLPNInnerPacks) and (@vLPNInnerPacks > 0) and
     (@ReasonCode <> '100' /* Cycle counting */) /* we do allow the same qty adjustment while doing cycle count */
    set @vMessageName = 'LocationAdjust_SameQuantity';
  else
  if (@NewQuantity = @vLPNQuantity) and (@vLPNQuantity > 0) and
     (@ReasonCode <> '100' /* cycle counting */) /* we do allow the same qty adjustment while doing cycle count */
    set @vMessageName = 'LocationAdjust_SameQuantity';
  else
  if (coalesce(@ReasonCode, '') = '')
    set @vMessageName = 'LocationAdjust_ReasonCodeRequired';
  else
  if (@vQtyToUpdate < @vReservedQty)
    select @vMessageName = 'LocationAdjust_CannotAdjustReservedQty', @vMsgParam1 = @vReservedQty;

  if (@vMessageName is not null)
     goto ErrorHandler;

  /* Calling Core procedure */
  exec @vReturnCode = pr_LPNs_AdjustQty @vLPNId,
                                        @vLPNDetailId,
                                        @vCurrentSKUId,
                                        @vCurrentSKU,
                                        @vCasesToUpdate output,
                                        @vQtyToUpdate   output,
                                        '=' /* Update Option - Exact Qty */,
                                        'Y' /* Export? Yes */,
                                        @ReasonCode,  /* Reason Code - in future accept reason from User */
                                        null, /* Reference */
                                        @BusinessUnit,
                                        @UserId;

  /* Mark the Location as updated */
  update Locations
  set ModifiedBy   = @UserId,
      ModifiedDate = current_timestamp
  where (LocationId = @vLocationId);

  /* if the Location/LPN has multiple lines then show the updated information back to the user in RF */
  if ((@vNumLines > 1) or (@vNumLPNs > 1))
    begin
      set @xmlResult = convert(varchar(max), (select @vLocationId LocationId, @Location Location,
                              'AdjustLocation' Operation, @BusinessUnit BusinessUnit, @UserId UserId
                       FOR XML RAW('ValidateLocation'), TYPE, ELEMENTS));

      exec pr_RFC_ValidateLocation @xmlResult;
    end

  /* Audit Trail */
  if (@vReturnCode = 0)
    begin
      exec pr_AuditTrail_Insert 'LocationAdjustQty', @UserId, null /* ActivityTimestamp */,
                                @LPNId        = @vLPNId,
                                @SKUId        = @vCurrentSKUId,
                                @LocationId   = @vLocationId,
                                @InnerPacks   = @vCasesToUpdate,
                                @Quantity     = @NewQuantity,
                                @ReasonCode   = @ReasonCode;
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vMsgParam1;

  /* Log the Result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @vMessageName, @EntityId = @vLocationId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  /* Log the Error */
  exec pr_RFLog_End null, @@ProcId, @vMessageName, @EntityId = @vLocationId, @ActivityLogId = @vActivityLogId output;

  exec @vReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_AdjustLocation */

Go
