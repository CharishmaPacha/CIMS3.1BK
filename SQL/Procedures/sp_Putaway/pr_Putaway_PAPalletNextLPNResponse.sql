/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/13  AY      pr_Putaway_PAPalletNextLPNResponse: Corrections (CID-57)
  2016/01/12  TD      pr_Putaway_PAPalletNextLPNResponse:Changes to consider active rules.
  2015/11/17  TK      pr_Putaway_PAPalletNextLPNResponse: Enhanced not to consider LPNPutawayClass if it is null in PutawayRules(ACME-402)
  2015/10/06  TK      pr_Putaway_PAPalletNextLPNResponse: Suggest LPNs to be Putaway in the order of LPN (ACME-354)
  2015/09/22  TK      pr_Putaway_PAPalletNextLPNResponse: Introduced new control variable to verify whether they need any
  2014/08/31  TK      pr_Putaway_PAPalletNextLPNResponse: Consider Confirmed Quantity Required value
  2014/07/24  PK      pr_Putaway_PAPalletNextLPNResponse: Changed PutawayClass to SKUPutawayClass and added
                      pr_Putaway_PAPalletNextLPNResponse: Code refactoring.
  2014/07/16  PK      pr_Putaway_PAPalletNextLPNResponse: Bug fix to display DestZone and DestLocation.
  2014/07/08  PK      pr_Putaway_PAPalletNextLPNResponse: Passed in the input parameters to the procedure
  2103/06/06  TD      pr_Putaway_PAPalletNextLPNResponse: Sending UPC in responce.
  2103/06/04  TD      pr_Putaway_PAPalletNextLPNResponse: Issue fixed using coalesc with PAClass
  2013/05/29  TD      pr_Putaway_PAPalletNextLPNResponse:  Added new params to pr_Putaway_FindLocationForLPN.
  2013/03/25  PK      pr_Putaway_FindLocationForLPN, pr_Putaway_PAPalletNextLPNResponse:
  2013/02/19  PKS     pr_Putaway_PAPalletNextLPNResponse: Framing of Error XML was removed and raise SQL exception.
  2011/12/08  YA      pr_Putaway_PAPalletNextLPNResponse: For PutawayPallets.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Putaway_PAPalletNextLPNResponse') is not null
  drop Procedure pr_Putaway_PAPalletNextLPNResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_Putaway_PAPalletNextLPNResponse: Given the pallet that is being putaway
   using Putaway LPNs on the pallet, we need to determine the next LPN to be
   Putaway. To do that, first we need to determine the destination of each LPN
   so that we can then sort them in the order of pick path and suggest the next
   LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_Putaway_PAPalletNextLPNResponse
  (@PalletId            TRecordId,
   @LastPALPNId         TRecordId,
   @LastPASKUId         TRecordId,
   @PAType              TFlag,
   @BusinessUnit        TBusinessUnit,
   @UserId              TUserId,
   @DeviceId            TDeviceId,
   @xmlResult           xml        output)
as
  /*declare variables here..*/
  declare @ReturnCode            TInteger,
          @vPalletId             TRecordId,
          @vPallet               TPallet,
          @vNumLPNs              TCount,
          @vPalletType           TTypeCode,
          @vPalletLocation       TLocation,
          @vPalletStatus         TStatus,
          @vPalletQuantity       TQuantity,

          @vLPNId                TRecordId,
          @vNextPALPNId          TRecordId,
          @vLPN                  TLPN,
          @vLPNType              TTypeCode,
          @vSKUId                TRecordId,
          @vSKU                  TSKU,
          @vSKUDescription       TDescription,
          @vSKU4                 TSKU,
          @vUPC                  TUPC,
          @vLPNQuantity          TQuantity,
          @vPAQuantity           TQuantity,
          @vPutawayClass         TCategory,
          @vDestZone             TLookUpCode,
          @vDestLocation         TLocation,
          @vDestStorageType      TTypeCode,
          @PASKUId               TRecordId,
          @PAInnerPacks          TInnerPacks,
          @PAQuantity            TQuantity,
          @vMessageName          TMessageName,
          @vPrevPutawayZone      TLookUpCode,
          @sDestZoneDesc         TDescription,

          @vCurrentPutawayZone   TLookUpCode,
          @vPALPNRecordId        TRecordId,
          @vPAZoneRecordId       TRecordId,
          @vCount                TCount,
          @vConfirmQtyRequired   TFlag,
          @vConfirmPAToDiffLoc   TFlag,
          @ConfirmMessage        TMessageName;

  declare @ttPutawayLPNs Table
          (RecordId              TRecordId  identity (1,1),
           LPNId                 TRecordId,
           LPN                   TLPN,
           SKUId                 TRecordId,
           SKUPutawayClass       TCategory,
           LPNPutawayClass       TCategory,
           PutawayZone           TLookUpCode,
           DestZone              TLookUpCode,
           DestLocation          TLocation,
           Unique (LPNId, RecordId),
           Unique (DestLocation, DestZone, RecordId)
          )

begin /* pr_Putaway_PAPalletNextLPNResponse */
  /* Initialize the variable */
  select @vPALPNRecordId      = 0,
         @vPAZoneRecordId     = 0,
         @vConfirmQtyRequired = dbo.fn_Controls_GetAsString('Putaway', 'ConfirmQtyRequired', 'N', @BusinessUnit, @UserId),
         @vConfirmPAToDiffLoc = dbo.fn_Controls_GetAsString('Putaway', 'ConfirmPAToDiffLoc', 'Y', @BusinessUnit, @UserId);

  /* Retrieve all the LPNs on the Pallets into a temporary table with
     the corresponding PA information like Putaway Class and Putaway Zone

     TODO NOTE: We need to get the rules as well and loop through rules, We are
                not passing in rules info to find the destination location and
                destination zone, we are currenly looping with PutawayZones.
  */
  insert into @ttPutawayLPNs (LPNId, LPN, SKUId, SKUPutawayClass, LPNPutawayClass,
                              PutawayZone, DestZone, DestLocation)
    select L.LPNId, L.LPN, L.SKUId, S.PutawayClass, L.PutawayClass, PR.PutawayZone,
           L.DestZone, L.DestLocation
    from LPNs L join SKUs S          on S.SKUId        = L.SKUId
                join PutawayRules PR on (coalesce(S.PutawayClass, '') = coalesce(PR.SKUPutawayClass, S.PutawayClass, '')) and
                                        (coalesce(L.PutawayClass, '') = coalesce(PR.LPNPutawayClass, L.PutawayClass, '')) and
                                        (coalesce(L.DestZone, PR.PutawayZone, '') = coalesce(PR.PutawayZone, ''))
    where (L.PalletId = @PalletId) and
          (L.Quantity > 0) and
          (PR.Status = 'A' /* Active */) and
          (coalesce(PR.PAType, '') = (coalesce(@PAType, PR.PAType, '')))
    order by PR.SequenceNo, L.LPN;

  /* For each of the LPNs to be putaway into the PAZone execute 'FindLocation'
     and update the temp table with the Destination. The LPN may already have a
     DestZone, so consider all LPNs that do not have a DestLocation */
  while (exists(select * from @ttPutawayLPNs where (RecordId     > @vPALPNRecordId) and
                                                   --(DestZone     is null) and
                                                   (DestLocation is null)))
    begin
      /* Find the first LPN in Putaway sequence to process */
      select top 1 @vPALPNRecordId = RecordId,
                   @vLPNId         = LPNId,
                   @vSKUId         = SKUId
      from @ttPutawayLPNs
      where --(DestZone     is null) and
            (DestLocation is null) and
            (RecordId     > @vPALPNRecordId)
      order by RecordId;

      /* Find the destination location for the selected LPN */
      exec pr_Putaway_FindLocationForLPN @vLPNId,
                                         @vSKUId,
                                         @PAType,
                                         @BusinessUnit,
                                         @UserId,
                                         @DeviceId,
                                         @vDestZone        output,
                                         @vDestLocation    output,
                                         @vDestStorageType output,
                                         @PASKUId          output,
                                         @PAInnerPacks     output,
                                         @PAQuantity       output,
                                         @vMessageName     output;

      /* Update temp table with the DestZone, Location etc. */
      update @ttPutawayLPNs
      set DestLocation = @vDestLocation,
          DestZone     = @vDestZone
      where (LPNId = @vLPNId);

      /* Update LPNs with DestLocation and DestZone */
      update LPNs
      set DestLocation = @vDestLocation,
          DestZone     = @vDestZone
      where (LPNId = @vLPNId);
    end

  --select * from @ttPutawayLPNs;

  /* Now that we have established Locations for all LPNs in the selected PA Zone,
     find the first LPN i.e. the first one when sorted in Location Sequence */
  select top 1 @vNextPALPNId = LPNId
  from @ttPutawayLPNs PL left outer join Locations L on PL.DestLocation = L.Location
  where (PL.DestLocation is not null)
  order by L.PutawayPath, PL.LPN;

  /* From the LPNs to be Putaway in the PAZone order by the Location and direct
     user to PA the first LPN */

  /* select Pallet and LPN info to Build Response */
  select @vPalletId          = P.PalletId,
         @vPallet            = P.Pallet,
         @vPalletType        = P.PalletType,
         @vPalletLocation    = L.Location,
         @vPalletStatus      = P.Status,
         @vPalletQuantity    = P.Quantity
  from Pallets P left outer join Locations L on P.LocationId = L.LocationId
  where (P.PalletId = @PalletId)

  /* Count of Non-empty LPNs on Pallet */
  select @vNumLPNs = count(*)
  from LPNs
  where ((Quantity > 0) and
         (PalletId = @PalletId));

  /* If there are no more LPNs on the Pallet to Putaway, then return a message */
  if (@vNumLPNs = 0)
    begin
      select @ConfirmMessage = 'PutawayPalletComplete';

      set @xmlResult = (select 0               as ErrorNumber,
                               @ConfirmMessage as ErrorMessage
                       FOR XML RAW('PutawayPallet'), TYPE, ELEMENTS XSINIL, ROOT('PALPNDetails'));

      return;
    end

  if (@vNextPALPNId is null)
    begin
      /* When all LPNs are PA with few remaining with no locations found,
         lets consider this as PA Complete (Confirmation), but show a
         different message on RF
      */
      select @ConfirmMessage = 'LPNsonPalletButNoLocations';

      set @xmlResult = (select 0               as ErrorNumber,
                               @ConfirmMessage as ErrorMessage
                       FOR XML RAW('PutawayPallet'), TYPE, ELEMENTS XSINIL, ROOT('PALPNDetails'));

      return;
    end

  /* Fetching LPN and SKU details for the first record */
  select @vLPN                = L.LPN,
         @vLPNType            = L.LPNType,
         @vSKU                = S.SKU,
         @vSKUDescription     = S.Description,
         @vSKU4               = S.SKU4,
         @vUPC                = S.UPC,
         @vPutawayClass       = S.PutawayClass,
         @vPAQuantity         = L.Quantity,
         @vDestStorageType    = L.LPNType,
         @vDestZone           = L.DestZone,
         @vDestLocation       = L.DestLocation
  from LPNs L left outer join SKUs S on L.SKUId = S.SKUId
  where (L.LPNId = @vNextPALPNId);

  /* Get the DestinationZone description */
  select @sDestZoneDesc = ZoneDesc
  from vwPutawayZones
  where (ZoneId = @vDestZone) and (Status = 'A' /* Active */);

  set @xmlResult = ( select @vPalletId                    as PalletId,
                            @vPallet                      as Pallet,
                            @vNumLPNs                     as NumCasesOnPallet,
                            @vPalletType                  as PalletType,
                            @vPalletLocation              as PalletLocation,
                            @vPalletStatus                as PalletStatus,
                            @vPalletQuantity              as PalletQuantity,
                            /* Confirm LPN Putaway Params */
                            @vNextPALPNId                 as LPNId,
                            @vLPN                         as LPN,
                            @vLPNType                     as LPNType,
                            @vSKU                         as SKU,
                            @vSKUDescription              as SKUDescription,
                            @vSKU4                        as SKUUoM,
                            @vUPC                         as UPC,
                            @vPutawayClass                as PutawayClass,
                            @vPAQuantity                  as Quantity,
                            Left(@vDestStorageType, 1)    as DestStorageType,
                            coalesce(@sDestZoneDesc, @vDestZone)
                                                          as DestZone,
                            @vDestLocation                as DestLocation,
                            @vConfirmQtyRequired          as ConfirmQtyRequired,
                            @vConfirmPAToDiffLoc          as ConfirmPAToDiffLoc,
                            'L'                           as ScanOption
                     FOR XML RAW('PutawayPallet'), TYPE, ELEMENTS XSINIL, ROOT('PALPNDetails'));

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Putaway_PAPalletNextLPNResponse */

Go
