/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/09  SV      pr_CC_CompletePalletCC: Bug fix to update Pallet's LocationId during Pallet CC (HA-2149)
  2020/12/29  AY      pr_CC_CompletePalletCC: Changed signature for pr_Pallets_Lost (HA-1837)
  2012/08/13  NY/AY   pr_CC_CompletePalletCC: Added variable 'PalletConfirmed.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CC_CompletePalletCC') is not null
  drop Procedure pr_CC_CompletePalletCC;
Go
/*------------------------------------------------------------------------------
  Proc pr_CC_CompletePalletCC:

  This proc should work in two modes
  a. User Scans Pallet and enters NumLPNs - does not scan LPNs at all. In this
     scenario if the NumLPNs entered matches the NumLPNs in the system, then
     we mark the Location counted. If Pallet was not in the location, we move into the location.
     if NumLPNs do not match and user did not scan the LPNs, then error out and force user to scan the LPNs/

  b. For one reason or the other user scans Pallets, LPNs on Pallet but does not verify the qty.
     Is this handled? If so, how?

     -- After scanning the Pallet and NumLPNs we are retriving the qty of the Pallet and displaying in the grid
        for the Pallet

  c. User scans Pallet, scans LPNs on Pallet, Enters qty for some or all of the LPNs.
     Is this handled? If so, how?

     -- User Scan's Pallet and NumLPNs and if the entered NumLPNs on the Pallet doesnot match the with the system NumLPNs,
        then User will be directed to scan each LPN with the Qty and once they confirm the LPNs on the Pallet, then the
        Count of the LPNs and its qty will be counted and will fill in the first grid(Pallet, NumLPNs, Qty)
------------------------------------------------------------------------------*/
Create Procedure pr_CC_CompletePalletCC
  (@PalletId           TRecordId,
   @LocationId         TRecordId,
   @xmPalletCCSummary  xml,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   ----------------------------------
   @PalletLost         TFlag output,
   @PalletMoved        TFlag output,
   @LPNMoved           TFlag output,
   @LPNAdjusted        TFlag output,
   @LPNSKUAdded        TFlag output,
   @LPNLost            TFlag output,
   @LPNPalletChanged   TFlag output,
   @PalletConfirmed    TFlag output)
as
  declare @vPalletId              TRecordId,
          @vPallet                TPallet,
          @vLPNId                 TRecordId,
          @vLPN                   TLPN,
          @vSKU                   TSKU,
          @vScannedLocationId     TRecordId,
          @vScannedLocation       TLocation,

          @vPalletNumLPNs         TCount,
          @vPalletLocationId      TRecordId,
          @vPalletLocation        TLocation,
          @vPalletStatus          TStatus,
          @vPalletQuantity        TQuantity,

          @vCount                 TCount,
          @vInnerPacks            TInnerPacks,
          @vScannedNumLPNs        TCount,
          @vConfirmedLPNs         TCount,
          @vScannedQuantity       TQuantity,
          @vPreviousQuantity      TQuantity,
          @vAuditRecordId         TRecordId,

          @LPNCCDetails           xml,
          @ttPalletLPNs           TEntityKeysTable,
          @vAuditActivity         TActivityType,
          @vPalletScanOnly        TFlag,

          @vCCReasonCode          TReasonCode,
          @vCCLostReasonCode      TReasonCode,
          @vMessageName           TMessageName,
          @ReturnCode             TInteger;

  declare @PalletLPNDetails as Table
          (RecordId            TRecordId  identity (1,1),
           Pallet              TPallet,
           LPN                 TLPN,
           SKU                 TSKU,
           NumLPNs             TCount,
           PreviousInnerPacks  TInnerPacks,
           PreviousQty         TQuantity,
           NewInnerPacks       TInnerPacks,
           NewQty              TQuantity,
           Deleted             TFlag);

begin /* pr_CC_CompletePalletCC */
  select @vAuditActivity  = 'CCPallet',
         @PalletConfirmed = 'N';

  /* Get Reason codes for cycle counting */
  select @vCCReasonCode     = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'CCDefault', '100' /* CIMS Default */, @BusinessUnit, @UserId);
  select @vCCLostReasonCode = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'CCLost',    null /* CIMS Default */, @BusinessUnit, @UserId);
  select @vCCLostReasonCode = coalesce(@vCCLostReasonCode, @vCCReasonCode);

  /* Get the Pallet info */
  select @vPalletId          = PalletId,
         @vPallet            = Pallet,
         @vPalletNumLPNs     = NumLPNs,
         @vPalletLocationId  = LocationId,
         @vPalletLocation    = Location,
         @vPalletStatus      = Status,
         @vPalletQuantity    = Quantity
  from vwPallets
  where (PalletId     = @PalletId) and
        (BusinessUnit = @BusinessUnit);

  /* Get the Scanned Location and LocationId */
  select @vScannedLocationId = LocationId,
         @vScannedLocation   = Location
  from Locations
  where (LocationId   = @LocationId) and
        (BusinessUnit = @BusinessUnit);

  /* Insert the XML result into a temp table */
  insert into @PalletLPNDetails (Pallet, LPN, SKU, NumLPNs, PreviousQty, NewQty, Deleted)
    select Record.Col.value('Pallet[1]',          'TPallet'),
           Record.Col.value('LPN[1]',             'TLPN'),
           Record.Col.value('SKU[1]',             'TSKU'),
           Record.Col.value('NumLPNs[1]',         'TCount'),
           Record.Col.value('PreviousQty[1]',     'TQuantity'),
           Record.Col.value('NewQty[1]',          'TQuantity'),
           Record.Col.value('Deleted[1]',         'TFlag')
    from @xmPalletCCSummary.nodes('CYCLECOUNTLOCATION/LOCATIONPALLETINFO') as Record(Col);

  /* Get the details of the Previous and Scanned Quantities of the Pallet */
  select  @vPreviousQuantity = sum(PreviousQty),
          @vScannedQuantity  = sum(NewQty),
          @vConfirmedLPNs    = sum(Case
                                     when NewQty = 0 then
                                       NumLPNs
                                     else 0
                                   end)
  from @PalletLPNDetails;

  /* Determine if the only pallet has been scanned and no LPNs have been scanned */
  if (@vScannedQuantity = 0) and (@vConfirmedLPNs > 0)
    select @vPalletScanOnly = 'Y';

  if (@vPalletScanOnly = 'Y') and
     (@vConfirmedLPNs  <> @vPalletNumLPNs)
    begin
      set @vMessageName = 'PalletLPNsMismatch';
      goto ErrorHandler;
    end

  /* If only pallet has been scanned and the NumLPNs confirmed is correct and Pallet
     is in same Location, then nothing to update, just log audit trail */
  if (@vPalletScanOnly  = 'Y') and
     (@vConfirmedLPNs   = @vPalletNumLPNs) and
     (@vScannedLocation = @vPalletLocation)
    begin
      select @vAuditActivity  = 'CCPalletScanOnly',
             @PalletConfirmed = 'Y';
      goto AuditTrail;
    end

  /* If Pallet has been scanned and LPNs matches, but Pallet is now in new Location,
     then move pallet and LPNs and then exit. This is true for Lost Pallets as well as
     there is nothing more to do when a Lost Pallet has been found intact */
  if (@vPalletScanOnly  = 'Y') and
     (@vConfirmedLPNs   = @vPalletNumLPNs) and
     (@vPalletStatus in ('P' /* Putaway */, 'O'/* Lost */, 'R'/* Received */)) and
     (@vScannedLocation <> coalesce(@vPalletLocation, ''))
    begin
      exec pr_Pallets_SetLocation @vPalletId, @vScannedLocationId, default /* @UpdateLPNLocation */,
                                  @BusinessUnit, @UserId;

      select @PalletMoved     = Case
                                  when (@vPalletStatus = 'O' /* Lost */) then
                                    'PF' /* Pallet Found */
                                  else
                                    'PM' /* PalletMoved */
                                end,
             @PalletConfirmed = 'Y',
             @vAuditActivity  = Case
                                  when (@vPalletStatus = 'O' /* Lost */) then
                                    'CCPalletFound'
                                  else
                                    'CCPalletMoved'
                                end;

      goto AuditTrail;
    end

  /* Move the Pallet if the Scanned and Pallet Location's are not null and also Pallet Location
     and Scanned Location are not the same */
  if ((@vScannedLocation <> @vPalletLocation) and
      (@vPalletStatus in ('P' /* Putaway */,  'A'/* Allocated */))) or
     ((@vScannedLocation <> coalesce(@vPalletLocation, '')) and
      (@vPalletStatus = 'E' /* Empty */))
    begin
      /* We are updating Pallet Location Counts in pr_Pallets_SetLocation, but for each LPN
         we are how ever updating Locations count, and more over we are only updating the
         Pallet Location here, So used the direct script to update Location */
      /* This comment is only for Pallets with EMPTY status.
         While confirming CC LPNs on EMPTY Pallet, LocationId over the Pallet is not going to set with the below call.
         Because, LPN is not yet CCed over the Pallet and hence in pr_Pallets_UpdateCount, LocationId gets cleared as
         @vQuantity = 0 and @vNumCartons = 0. So, need to take care such that pr_Pallets_SetLocation gets called after
         pr_CC_CompleteLPNCC gets executed. */
      exec @ReturnCode = pr_Pallets_SetLocation @vPalletId,
                                                @vScannedLocationId,
                                                'N', /* @vUpdateLPNLocation */
                                                @BusinessUnit,
                                                @UserId;

      /* Setting PalletLocation = ScannedLocation becasue we already Moved
         the Pallet to the Scanned Location */
      select @PalletMoved     = case
                                  when (@vPalletStatus = 'P'/* Putaway */) then 'PM' /* PalletMoved */
                                  when (@vPalletStatus = 'E'/* Empty */) then  'PL' /* PalletLocated */
                                end,
             /* For Empty Pallet, @vPalletLocation needs to set null for updating LocationId over the Pallet
                by passing thru the validation and get called pr_Pallets_SetLocation in the further steps. */
             @vPalletLocation = case
                                  when (@vPalletStatus = 'E'/* Empty */) then null
                                  else @vScannedLocation
                                end,
             @vAuditActivity  = case
                                  when (@vPalletStatus = 'P'/* Putaway */) then 'CCPalletMoved'
                                  when (@vPalletStatus = 'E'/* Empty */) then 'CCPalletLocated'
                                end;
    end

  /* Mark Pallet as Lost if the Pallet Previous Quantity is greater than zero
      and Scanned Pallet Quantity is eqaul to zero */
  if ((@vPreviousQuantity > 0) and (@vScannedQuantity = 0))
    begin
      exec pr_Pallets_Lost @PalletId, @vCCLostReasonCode /* @ReasonCode */, @BusinessUnit, @UserId;

      select @PalletLost     = 'PL' /* Pallet Lost */,
             @vAuditActivity = 'CCPalletLost';
      goto AuditTrail;
    end

  /* Process each of the LPNs on the Pallet */
  while (exists (select *
                 from @PalletLPNDetails
                 where (Deleted = 'N')))
    begin
      /* Initialize parameters */
      select @vLPN         = null,
             @vLPNId       = null;

      /* Pick the first LPN & its Id */
      select Top 1 @vLPN           = PLD.LPN,
                   @vLPNId         = L.LPNId
      from @PalletLPNDetails PLD
        join LPNs L on (PLD.LPN = L.LPN)
      where Deleted = 'N'
      order by PLD.LPN;

      if (@vLPNId is not null)
        begin
          select @LPNCCDetails = (select *
                                  from @PalletLPNDetails
                                  where (LPN = @vLPN)
                                  FOR XML RAW('LOCATIONLPNINFO'), TYPE, ELEMENTS XSINIL, ROOT('CYCLECOUNTLOCATION'));

          exec @ReturnCode = pr_CC_CompleteLPNCC @vLPNId,
                                                 @LocationId,
                                                 @vPalletId,
                                                 @LPNCCDetails,
                                                 @BusinessUnit,
                                                 @UserId,
                                                 @LPNMoved         output,
                                                 @LPNAdjusted      output,
                                                 @LPNSKUAdded      output,
                                                 @LPNLost          output,
                                                 @LPNPalletChanged output;
        end

      /* Delete the LPN that is processed */
      update @PalletLPNDetails
      set Deleted = 'Y'
      where (LPN = @vLPN);
    end

  if (@vScannedLocation <> coalesce(@vPalletLocation, ''))
    begin
      /* We are updating Pallet Location Counts in pr_Pallets_SetLocation, but for each LPN
         we are how ever updating Locations count, and more over we are only updating the
         Pallet Location here, So used the direct script to update Location */
      exec @ReturnCode = pr_Pallets_SetLocation @vPalletId,
                                                @vScannedLocationId,
                                                'N', /* @vUpdateLPNLocation */
                                                @BusinessUnit,
                                                @UserId;

      select @PalletMoved    = 'PM' /* PalletMoved */,
             @vAuditActivity = 'CCPalletMoved';
    end

  /* Insert the LPNs which are on the Pallet into temp table */
  insert into @ttPalletLPNs(EntityId, EntityKey)
    select LPNId, LPN
    from LPNs
    where (PalletId     = @vPalletId) and
          (BusinessUnit = @BusinessUnit);

AuditTrail:
  /* Audit Trail */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @PalletId      = @vPalletId,
                            @Quantity      = @vScannedQuantity,
                            @LocationId    = @vPalletLocationId,
                            @ToLocationId  = @vScannedLocationId,
                            @AuditRecordId = @vAuditRecordId output;

  /* Now insert all the LPNs into Audit Entities i.e link above Audit Record
     to all the LPNs on Pallet which are cycle counted */
  if (@vPalletScanOnly  = 'Y')
    exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'LPN', @ttPalletLPNs, @BusinessUnit;

ErrorHandler:
  if (@vMessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end   /* pr_CC_CompletePalletCC */

Go
