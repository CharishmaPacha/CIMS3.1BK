/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/03  PK      pr_CC_CompleteLPNCC: Bug fix to handle adjustments of New or Lost status LPNs while CCing in location (HA-2099)
  2021/02/15  PK      pr_CC_CompleteLPNCC: Bug fix to send exports when there is a quantity change in the LPNs which belongs to different or same Location (HA-1999)
  2021/01/05  SK      pr_CC_CompleteLPNCC: changes to include inventoryclass fields based on HA-1794 (HA-1841)
  2020/09/18  SK      pr_CC_CompleteLPNCC: Clear pallet for Location of storage type LA if pallet is not scanned along with it (HA-1428)
  2020/09/09  SK      pr_CC_CompleteLPNCC: Pass in values to Error message handler (HA-1371)
  2018/02/23  OK      pr_CC_CompleteLPNCC: Included InTransit and Received Status LPNs to get the LPNDetailId for proper updates on CC (S2G-270)
  2018/02/02  OK      pr_CC_CompleteLPNCC: Bugfix to update the proper quantity if New Status LPN found in location with different qty (S2G-197)
  2016/12/07  TK      pr_CC_CompleteLPNCC: Do not pass in LPNStatus to LPNs_Move proc, as we would validate the current LPN status (HPI-1102)
  2016/12/04  PK      pr_CC_CompleteLPNCC: Fetching Location info after adding the LPN to the pallet to avoid duplicate exports.
  2016/12/02  OK      pr_CC_CompleteLPNCC: Bug Fix to allow Void, New, Received status LPNs to cycle count in Location (FB-830)
  2016/11/10  ??      pr_CC_CompleteLPNCC: Corrected check condition included missing and condition (HPI-GoLive)
  2016/11/09  PK      pr_CC_CompleteLPNCC: Bug fix to raise error only for the partial/fully allocated LPNs
  2015/11/09  TK      pr_CC_CompleteLPNCC: Corrected/Enhanced Validations (HPI-1027)
  2015/08/07  RV      pr_CC_CompleteLPNCC: Clear the Pallet if Pallet is null (FB-233).
  2015/07/24  OK      pr_CC_CompleteLPNCC: Made the corrections against FB-232 to accept New status LPN.
  2015/04/03  TK      pr_CC_CompleteLPNCC: Consider unavailable line to update with latest quantity when LPN status is Lost/Voided
  2015/03/26  DK      pr_CC_CompleteLPNCC: Ignore setting LPN pallet if there is no scanned pallet
  2014/08/19  NY      pr_CC_CompleteLPNCC: We should not do cycle counting of allocated line.(CIMS-314)
  2014/03/20  TD      pr_CC_CompleteLPNCC:Changes to handle InnerPacks.
  2014/03/04  PK      pr_CC_CompleteLPNCC: Updating the scanned quantity by subtracting the reserved qty.
  2014/02/28  PK      pr_CC_CompleteLPNCC: Unallocating the allocated LPN and continuing the
  2014/01/23  NY      pr_CC_CompleteLPNCC: Added condition to log AT for LPN move and adjust.
  2014/01/08  PK      pr_CC_CompleteLPNCC: Returning only available lines in LPN.
  2013/11/22  PK      pr_CC_CompleteLPNCC: changed the callers by passing in new parameters.
  2012/08/04  AY      pr_CC_CompleteLPNCC: Enhance for Audit trail
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CC_CompleteLPNCC') is not null
  drop Procedure pr_CC_CompleteLPNCC;
Go
/*------------------------------------------------------------------------------
  Proc pr_CC_CompleteLPNCC:

     1. If the Scanned Location was equal to the LPNs Location and if the LPN
         Status is Putaway, then Move the LPN to the Scanned Location first and
         then do the adjustments for the LPN.

     2. If the LPNs Previous Quantity is greater than zero and the Scanned New
         Quantity is Zero them Mark the LPN as Lost.

     3. If the LPNs Previous Quantity for the SKU is Zero and LPNs DetailId
          is null for the SKU, then Add the SKU to LPN.

     4. If the LPNs Previous Quantity is not eqaul to Scanned New Quantity for
         the SKU, Then Adjust the LPN.

     5. If the Scanned Location and LPNs Locations are not equal then Move the
        LPN to the Scanned Location.

Note: We will generate the exports for LPN Adjustments only when the Scanned
      Location and LPNs Location are equal.

------------------------------------------------------------------------------*/
Create Procedure pr_CC_CompleteLPNCC
  (@LPNId              TRecordId,
   @LocationId         TRecordId,
   @PalletId           TRecordId,
   @xmLPNCCSummary     xml,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   ----------------------------------
   @LPNMoved           TFlag output,
   @LPNAdjusted        TFlag output,
   @LPNSKUAdded        TFlag output,
   @LPNLost            TFlag output,
   @LPNPalletChanged   TFlag output)
as
  declare @vLPNId                 TRecordId,
          @vLPN                   TLPN,
          @vLPNDetailId           TRecordId,
          @vLPNStatus             TStatus,
          @vLPNLocationId         TRecordId,
          @vLPNLocation           TLocation,
          @vInventoryClass1       TInventoryClass,
          @vInventoryClass2       TInventoryClass,
          @vInventoryClass3       TInventoryClass,
          @vPalletId              TRecordId,
          @vPallet                TPallet,
          @vScannedLocationId     TRecordId,
          @vScannedLocation       TLocation,
          @vScannedLocStorageType TStorageType,
          @vSKUId                 TRecordId,
          @vSKU                   TSKU,
          @vCount                 TCount,
          @vScannedInnerPacks     TQuantity,
          @vScannedQuantity       TQuantity,
          @vPreviousInnerPacks    TQuantity,
          @vPreviousQuantity      TQuantity,
          @vScannedSKUQty         TQuantity,
          @vPreviousSKUQty        TQuantity,
          @vInnerPacks            TInnerPacks,
          @vLPNReservedQty        TQuantity,
          @vLPNDReservedQty       TQuantity,
          @vUnitsPerPkg           TQuantity,
          @vNumResLineCount       TCount,
          @vNumAvailLineCount     TCount,
          @vTotalResQty           TQuantity,
          @vTotalAvailQty         TQuantity,
          @vExportOption          TFlag,
          @vAuditActivity         TActivityType,

          @vLPNMoved              TFlag,
          @vLPNAdjusted           TFlag,
          @vLPNLost               TFlag,
          @vLPNFound              TFlag,
          @vLPNSKUAdded           TFlag,
          @vLPNPalletChanged      TFlag,

          @vCCReasonCode          TReasonCode,
          @vCCDefaultReasonCode   TReasonCode,
          @vCCLostReasonCode      TReasonCode,
          @vCCMoveReasonCode      TReasonCode,
          @vCCAdjustReasonCode    TReasonCode,
          @vMessageName           TMessageName,
          @vValue1                TString,
          @vValue2                TString,
          @vRecordId              TRecordId,
          @vReturnCode            TInteger;

  declare @LPNSKUDetails as Table
          (RecordId            TRecordId  identity (1,1),
           LPN                 TLPN,
           SKU                 TSKU,
           PreviousInnerPacks  TInnerPacks,
           PreviousQty         TQuantity,
           NewInnerPacks       TInnerPacks,
           NewQty              TQuantity,
           ProcessFlag         TFlag);

begin /* pr_CC_CompleteLPNCC */
  select @vAuditActivity    = 'CCLPN',
         @vLPNMoved         = null,
         @vLPNAdjusted      = null,
         @vLPNLost          = null,
         @vLPNFound         = null,
         @vLPNSKUAdded      = null,
         @vLPNPalletChanged = null,
         @vValue1           = null,
         @vValue2           = null,
         @vRecordId         = 0;

  /* Get Reason codes for cycle counting */
  select @vCCDefaultReasonCode = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'CCDefault', '100' /* CIMS Default */, @BusinessUnit, @UserId);
  select @vCCLostReasonCode    = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'CCLost', null /* Default */, @BusinessUnit, @UserId);
  select @vCCMoveReasonCode    = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'CCMove', null /* Default */, @BusinessUnit, @UserId);
  select @vCCAdjustReasonCode  = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'CCAdjust', null /* Default */, @BusinessUnit, @UserId);
  /* Set to default CC reason if specific ones are not setup */
  select @vCCLostReasonCode    = coalesce(@vCCLostReasonCode,   @vCCDefaultReasonCode);
  select @vCCMoveReasonCode    = coalesce(@vCCMoveReasonCode,   @vCCDefaultReasonCode);
  select @vCCAdjustReasonCode  = coalesce(@vCCAdjustReasonCode, @vCCDefaultReasonCode);

  /* Get the LPN info */
  select @vLPNId          = LPNId,
         @vLPN            = LPN,
         @vLPNLocationId  = LocationId,
         @vLPNLocation    = coalesce(Location, ''), -- In case of LPN created using CreateInvLPNs action with selecting GeneratePallet option, LPN gets generated with Pallet but not on Location. @vLPNLocation is being compared further.
         @vPalletId       = PalletId,
         @vPallet         = Pallet,
         @vLPNStatus      = Status,
         @vLPNReservedQty = ReservedQty
  from LPNs
  where (LPNId = @LPNId);

  /* Get the Scanned LocationId and Location */
  select @vScannedLocationId      = LocationId,
         @vScannedLocation        = Location,
         @vScannedLocStorageType  = StorageType
  from Locations
  where (LocationId = @LocationId);

  /* Insert the XML result into a temp table */
  insert into @LPNSKUDetails (LPN, SKU, PreviousInnerPacks, PreviousQty, NewInnerPacks, NewQty, ProcessFlag)
    select Record.Col.value('LPN[1]',                'TLPN'),
           Record.Col.value('SKU[1]',                'TSKU'),
           Record.Col.value('PreviousInnerPacks[1]', 'TQuantity'),
           Record.Col.value('PreviousQty[1]',        'TQuantity'),
           Record.Col.value('NewInnerPacks[1]',      'TQuantity'),
           Record.Col.value('NewQty[1]',             'TQuantity'),
           Record.Col.value('Deleted[1]',            'TFlag')
    from @xmLPNCCSummary.nodes('CYCLECOUNTLOCATION/LOCATIONLPNINFO') as Record(Col)
    order by 2;

  /* Get row count */
  select @vCount = @@rowcount;

  /* Get the details of the Previous and Scanned Quantities of the LPN */
  select @vPreviousinnerPacks = sum(PreviousInnerPacks),
         @vPreviousQuantity   = sum(PreviousQty),
         @vScannedInnerPacks  = sum(NewInnerPacks),
         @vScannedQuantity    = sum(NewQty)
  from @LPNSKUDetails;

  /* Get the number of reserve lines to determine if the
     allocate LPN is case/unit pick, thus we can add the available quantity */
  select @vNumResLineCount   = sum(case when OnhandStatus = 'R' /* Reserve */   then 1        else 0 end),
         @vTotalResQty       = sum(case when OnhandStatus = 'R' /* Reserve */   then Quantity else 0 end),
         @vNumAvailLineCount = sum(case when OnhandStatus = 'A' /* Available */ then 1        else 0 end),
         @vTotalAvailQty     = sum(case when OnhandStatus = 'A' /* Available */ then Quantity else 0 end)
  from LPNDetails
  where (LPNId = @vLPNId);

  /* Mark LPN as Lost if the LPN Previous Quantity is greater than zero
      and Scanned LPN Quantity is equal to zero */
  if (@vLPNReservedQty = 0) and
     ((@vPreviousQuantity > 0) and (@vScannedQuantity = 0))
    begin
      exec pr_LPNs_Lost @LPNId, @vCCLostReasonCode, @UserId, Default /* Clear Pallet */, null /* Audit Activity */;

      select @vLPNLost = 'LL' /* LPN Lost */;
      goto AuditTrail;
    end

  /* If the LPN fully allocated then we cannot increment/decrement its Qty  */
  if (@vLPNStatus = 'A' /* Allocated */) and (@vScannedQuantity <> @vPreviousQuantity)
    set @vMessageName = 'CannotCCLessOrMorethanReservedQty';
  else
  /* If LPN is partially allocated, we cannot decrement down the reserved Qty  */
  if (@vLPNStatus <> 'A' /* Allocated */) and (@vNumResLineCount > 0) and
     (@vScannedQuantity < @vTotalResQty)
    set @vMessageName = 'CannotCCLessthanReservedQty';
  else
  /* If LPN is partially allocated, we cannot increment Qty unless we have an AvailableLine */
  if (@vLPNStatus <> 'A' /* Allocated */) and (@vNumAvailLineCount = 0) and (@vLPNReservedQty > 0) and
     (@vScannedQuantity > @vTotalResQty)
    set @vMessageName = 'NoAvailableLineToAdjustQty';

  if (@vMessageName is not null)
    begin
      select @vValue1  = @vLPN,
             @vValue2  = cast(@vLPNReservedQty as varchar(2));

      goto ErrorHandler;
    end

  /* Move the LPN if the Scanned and LPN Location's are not null and also LPN Location
     and Scanned Location are not the same. If the LPN is on a Pallet, then  we cannot
     do this as we have to set the Pallet of the LPN as well. */
  if (@vScannedLocation <> @vLPNLocation) and
     (@vLPNStatus in ('P', 'R', 'N', 'O' /* Putaway, New, Lost */)) and (@PalletId is null) and (@vScannedQuantity = @vPreviousQuantity)
    begin
      /* If LPN was in New status then it is an adjust */
      select @vCCReasonCode = case when (@vLPNStatus = 'N') then @vCCAdjustReasonCode else @vCCMoveReasonCode end;

      /* Clear the Pallet on LPN if Pallet Id is null */
      exec pr_LPNs_SetPallet @vLPNId, null /* Clear the pallet */, @UserId;

      exec @vReturnCode = pr_LPNs_Move @vLPNId,
                                       null,    /* LPN */
                                       null,    /* LPNStatus */   -- LPN Status would have been changed, while setting LPN on to Pallet, so don't pass in. Latest LPN status would be evaluated in proc
                                       @vScannedLocationId,
                                       @vScannedLocation,
                                       @BusinessUnit,
                                       @UserId,
                                       default, /* Update Option */
                                       @vCCReasonCode;

      select @vLPNMoved    = 'LM' /* LPN Moved */,
             /* Setting LPNLocation = ScannedLocation becasue we already Moved
                the LPN to the Scanned Location and to avoid moving LPN again
                at the end */
             @vLPNLocation = @vScannedLocation;
    end
  else
  /* For Storage type LA (Pallets & LPN), there is possibility that an LPN is in a Location
     with no Pallet associated with it even in case when there is no Location change */
  if (@vScannedLocStorageType = 'LA' /* Pallets & LPNs */) and (@PalletId is null)
    begin
      exec pr_LPNs_SetPallet @vLPNId, null /* Clear the pallet */, @UserId;
    end

  /* If the LPN was New or Lost, we would have already market it as Putaway and exported all
     LPN details when we did the move into the location. We don't need to do any further
     adjustments */
  if (@vLPNStatus in ('R', 'N', 'O' /* Received, New or Lost */)) and (@vScannedQuantity = @vPreviousQuantity)
    update @LPNSKUDetails set ProcessFlag = 'I' where ProcessFlag = 'N';

  /* Process the SKUs in the LPN which need to be processed */
  while (exists (select * from @LPNSKUDetails where RecordId > @vRecordId and ProcessFlag = 'N'))
    begin
      /* Initialize parameters */
      select @vSKU         = null,
             @vSKUId       = null,
             @vLPNDetailId = null;

      /* Pick the first SKU & its Id */
      select Top 1 @vSKUId    = S.SKUId,
                   @vSKU      = LSD.SKU,
                   @vRecordId = RecordId
      from @LPNSKUDetails LSD join SKUs S on (LSD.SKU = S.SKU)
      where ProcessFlag = 'N'
      order by RecordId;

      /* Determine how much of the SKU was in the Location before and now */
      select @vPreviousSKUQty = sum(PreviousQty),
             @vScannedSKUQty  = sum(NewQty),
             @vInnerPacks     = sum(NewInnerPacks)
      from @LPNSKUDetails
      where (SKU = @vSKU);

      /* Get LPNDetailId of the SKU in this LPN - in case SKU already exists in the LPN */
      select @vLPNDetailId     = LPNDetailId,
             @vPreviousSKUQty  = Quantity,
             @vUnitsPerPkg     = UnitsPerPackage,
             @vInventoryClass1 = InventoryClass1,
             @vInventoryClass2 = InventoryClass2,
             @vInventoryClass3 = InventoryClass3
      from vwLPNDetails
      where (LPNId        = @vLPNId            ) and
            (SKUId        = @vSKUId            ) and
            --(OnhandStatus = 'A' /* Available */);
             (OnhandStatus = (case when LPNStatus not in ('V'/* Void */, 'O'/* Lost */, 'N'/* New */, 'T'/* InTransit */, 'R' /* Received */) then 'A'/* Available */ -- LPN Status will be changed if new/received LPN got moved to location. Hence consider the new status
                                   else  'U' /* Un-Available */
                              end));

      /* Get the total reserved qty on the LPN */
      select @vLPNDReservedQty = sum(Quantity)
      from vwLPNDetails
      where (LPNId   = @vLPNId  ) and
            (SKUId   = @vSKUId  ) and
            (OrderId is not null);

      /* If the particular SKU was not in the Location before and there is no LPN Detail
         either, then add the SKU. Note that PrevQty could be zero and LPNDetailId is not
         null for a Static Picklane - in which case we would need to Adjust instead of
         adding a new SKU */
      if (@vPreviousSKUQty = 0) and (@vLPNDetailId is null)
        begin
          exec @vReturnCode = pr_LPNs_AddSKU @vLPNId,
                                             @vLPN,
                                             null, /* SKUId */
                                             @vSKU,
                                             @vInnerPacks,
                                             @vScannedSKUQty,
                                             @vCCAdjustReasonCode, /* Reason Code - Cycle Count */
                                             @vInventoryClass1,
                                             @vInventoryClass2,
                                             @vInventoryClass3,
                                             @BusinessUnit,
                                             @UserId;

          select @vLPNSKUAdded = 'LAS' /* LPN Add SKU */;
        end
      else
      /* If the Previous and NewQty are different, then adjust the LPN */
      if (@vPreviousSKUQty <> @vScannedSKUQty)
        begin
          /* If the LPN Detail qty is changed, we would always export */
          set @vExportOption = 'Y' /* Yes */

          /* Updating the Scanned quantity by reducing the reserved qty.
             Also calculate the InnerPacks based on scaneed Qty */
          if (@vScannedSKUQty >= @vLPNDReservedQty)
            begin
              select @vScannedSKUQty = @vScannedSKUQty - @vLPNDReservedQty;
              select @vInnerPacks = coalesce( @vScannedSKUQty/nullif(@vUnitsPerPkg, 0),0);
            end

          exec @vReturncode = pr_LPNs_AdjustQty @vLPNId,
                                                @vLPNDetailId,
                                                @vSKUId,
                                                @vSKU,
                                                @vInnerPacks,
                                                @vScannedSKUQty,
                                                default, /* = update Option */
                                                @vExportOption,
                                                @vCCAdjustReasonCode, /* Cycle count */
                                                null,    /* Reference */
                                                @BusinessUnit,
                                                @UserId;
          select @vLPNAdjusted = 'LA' /* LPN Adjusted */;
        end

      /* Delete the LPN-SKU that is processed */
      update @LPNSKUDetails
      set ProcessFlag = 'Y'
      where (SKU = @vSKU);
    end

  /* Set Pallet for the LPNs, if the Location is of Pallet Storage Type */
  if ((coalesce(@PalletId, '') <> '') and (coalesce(@PalletId, '')  <> coalesce(@vPalletId, '')))
    begin
      exec pr_LPNs_SetPallet @vLPNId, @PalletId, @UserId;

      select @vLPNPalletChanged = 'LPM'/* LPN Pallet Move */;

      /* Get the LPN Location after adding LPN to the pallet */
      select @vLPNLocation = Location
      from vwLPNs
      where (LPNId = @vLPNId);
    end

  /* Move the LPN if the LPN Location and the Scanned Location are not equal */
  if (@vScannedLocation <> coalesce(@vLPNLocation, ''))
    begin
      exec @vReturnCode = pr_LPNs_Move @vLPNId,
                                       @vLPN,
                                       null /* LPNStatus */,  -- LPN Status would have been changed, while setting LPN on to Pallet, so don't pass in. Latest LPN status would be evaluated in proc
                                       @vScannedLocationId,
                                       @vScannedLocation,
                                       @BusinessUnit,
                                       @UserId,
                                       default, /* Update Option */
                                       @vCCMoveReasonCode; /* ReasonCode */

      select @vLPNMoved  = 'LM'/* LPN Moved */,
             @vLPNFound  = case when @vLPNStatus = 'O' /* Lost */ then 'LF' else null end;
    end

AuditTrail:
  /* Based upon the various combinations of changes, set the Audit Activity here */
  select @vAuditActivity = case
                             when ((@vLPNMoved is not null) and (@vLPNAdjusted is not null)) then
                               'CCLPNMovedAndAdjusted'
                             when @vLPNFound is not null then
                               'CCLPNFound'
                             when @vLPNMoved is not null then
                               'CCLPNMoved'
                             when @vLPNLost  is not null then
                               'CCLPNLost'
                             when @vLPNSKUAdded  is not null then
                               'CCLPNAddedSKU'
                             when @vLPNAdjusted is not null then
                               'CCLPNAdjusted'
                             when @vLPNPalletChanged is not null then
                               'CCLPNPalletChanged'
                             else
                               'CCLPN'
                           end;

  /* Create Audit Trail */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @LPNId        = @vLPNId,
                            @LocationId   = @vLPNLocationId,
                            @PalletId     = @vPalletId,
                            @Quantity     = @vScannedQuantity,
                            @ToLocationId = @vScannedLocationId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vValue1, @vValue2;

ExitHandler:
  select @LPNMoved         = coalesce(@LPNMoved,         @vLPNMoved),
         @LPNAdjusted      = coalesce(@LPNAdjusted,      @vLPNAdjusted),
         @LPNLost          = coalesce(@LPNLost,          @vLPNLost),
         @LPNSKUAdded      = coalesce(@LPNSKUAdded,      @vLPNSKUAdded),
         @LPNPalletChanged = coalesce(@LPNPalletChanged, @vLPNPalletChanged);

  return(coalesce(@vReturnCode, 0));
end /* pr_CC_CompleteLPNCC */

Go
