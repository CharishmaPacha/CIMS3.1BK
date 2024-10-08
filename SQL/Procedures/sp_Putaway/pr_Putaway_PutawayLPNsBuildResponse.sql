/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/02/25  TK      pr_Putaway_PutawayLPNsBuildResponse: Return Confirm Qty required & Scan Option control values (CIMS-790)
  2016/02/22  TK      pr_Putaway_PutawayLPNsBuildResponse: Initial Revision (GNC-1247)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Putaway_PutawayLPNsBuildResponse') is not null
  drop Procedure pr_Putaway_PutawayLPNsBuildResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_Putaway_PutawayLPNsBuildResponse: This Procedure will retrieve all the LPNs
    on given Pallet and Gives response in the required sequence.

  Sequence can be of any of the following:
  FIFO: In order of Package Seq No i,e. the order the user scanned in.
         Ex: If user scanned L1, L2 and L3, we would suggest L1 first, followed by L2 and then L3
  LIFO: In reverse order of Package Seq No i.e. in the reverse order of the user scanned:
         Ex: if user scanned LPN L1, L2, L3 then we would suggest L3 first, L2 and then L1
  PP:   In the order of Putaway Path. This works when the LPNs have dest Location. And we order by the
          Putaway Path of those locations and suggest LPNs one after
  REVPP: Suggest LPNs in reverse order of Putaway Path

  Scan Option: Y - User is allowed to PA the LPNs in any order by scanning the LPN again
               N - User is directly taken to the PA LPN screen with the next LPN i.e. user does
                   not have choice to pick and choose LPNs to putaway.
------------------------------------------------------------------------------*/
Create Procedure pr_Putaway_PutawayLPNsBuildResponse
  (@PalletId            TRecordId,
   @Pallet              TPallet,
   @Operation           TOperation,
   @BusinessUnit        TBusinessUnit,
   @UserId              TUserId,
   @xmlResult           xml        output)
as
  declare @ReturnCode         TInteger,
          @ConfirmMessage     TMessage,

          @vPutawaySequence   TControlValue,
          @vPAAllowScan       TControlValue,
          @ScanOption         TControlValue,
          @ConfirmQtyRequired TControlValue,

          @vLPNId             TRecordId,
          @vLPN               TLPN,
          @vLPNType           TTypeCode,
          @vQuantity          TQuantity,
          @vDestZone          TLookUpCode,
          @vDestZoneDesc      TDescription,
          @vDestLocation      TLocation,

          @vSKU               TSKU,
          @vSKUDescription    TDescription,
          @vSKUUoM            TUoM,
          @vSKUPutawayClass   TPutawayClass,
          @vUPC               TUPC,

          @vNumLPNsOnPallet   TCount,

          @vXMLResult         xml;

  declare @ttLPNsToPutaway Table
          (LPNId                 TRecordId,
           LPN                   TLPN,
           LPNType               TTypeCode,
           Quantity              TQuantity,
           SKUId                 TRecordId,
           SKU                   TSKU,
           SKUDesc               TDescription,
           SKUUoM                TUoM,
           UPC                   TUPC,
           SKUPutawayClass       TCategory,
           LPNPutawayClass       TCategory,
           DestZone              TLookUpCode,
           DestZoneDesc          TDescription,
           DestLocation          TLocation,
           PickPath              TLocationPath,

           RecordId              TRecordId  identity (1,1));

begin /* pr_Putaway_PutawayLPNsBuildResponse */
  SET NOCOUNT ON;

  /* Get the control values */
  select @vPutawaySequence   = dbo.fn_Controls_GetAsString('PutawayLPNs_'+ @Operation, 'PutawaySequence', 'LIFO', @BusinessUnit, @UserId),
         @vPAAllowScan       = dbo.fn_Controls_GetAsBoolean('PutawayLPNs_'+@Operation, 'ConfirmScanLPN', 'Y', @BusinessUnit, @UserId),
         @ConfirmQtyRequired = dbo.fn_Controls_GetAsBoolean('PutawayLPNs_'+@Operation, 'ConfirmQtyRequired', 'N', @BusinessUnit, @UserId),
         @ScanOption         = dbo.fn_Controls_GetAsString('Putaway', 'ScanOption', 'LS' /* LPN/SKU */, @BusinessUnit, @UserId);

  /* Get Num LPNs on Pallet */
  select @vNumLPNsOnPallet = count(*)
  from LPNs
  where (PalletId = @PalletId);

  /* Get all the LPNs that needs to be putaway in required Sequence */
  insert into @ttLPNsToPutaway
    select top 1 L.LPNId, L.LPN, L.LPNType, L.Quantity,
           L.SKUId, S.SKU, S.Description, S.UoM, S.UPC, S.PutawayClass, L.PutawayClass,
           L.DestZone, LU.LookUpDescription, L.DestLocation, LOC.PickPath
    from LPNs L
      left outer join SKUs      S   on (S.SKUId = L.SKUId)
      left outer join Locations LOC on (L.DestLocation = LOC.Location)
      left outer join vwLookUps LU  on (LU.LookUpCategory = 'PutawayZones' ) and
                                       (LU.LookUpCode     = LOC.PutawayZone)
    where (L.PalletId = @PalletId) and
          (L.DestLocation is not null)  -- we would not suggest LPNs if there is no Dest Location on it
    order by case when @vPutawaySequence = 'FIFO'  then L.PackageSeqNo
                  when @vPutawaySequence = 'PP'    then LOC.PickPath end asc,
             case when @vPutawaySequence = 'LIFO'  then L.PackageSeqNo
                  when @vPutawaySequence = 'REVPP' then LOC.PickPath end desc;

  /* If there are no more LPNs on the Pallet to Putaway, then return a message */
  if (@@rowcount = 0)
    begin
      /* Update device and build result xml
      exec pr_BuildRFSuccessXML 'PutawayLPNsComplete', @vXMLResult output;
      We cannot do this because in RF we are using an existing service which expects the below format.
      */

      select @ConfirmMessage = 'PutawayLPNsComplete';

      set @xmlResult = (select 0               as ErrorNumber,
                               @ConfirmMessage as ErrorMessage
                       FOR XML RAW('PALPNDETAILS'), TYPE, ELEMENTS XSINIL, ROOT('PUTAWAYLPNS'));

      return;
    end

  /* Fetching LPN and SKU details for the first record */
  select top 1 @vLPN                = LPN,
               @vLPNType            = LPNType,
               @vSKU                = SKU,
               @vSKUDescription     = SKUDesc,
               @vSKUUoM             = SKUUoM,
               @vUPC                = UPC,
               @vSKUPutawayClass    = SKUPutawayClass,
               @vQuantity           = Quantity,
               @vDestZone           = DestZone,
               @vDestZoneDesc       = DestZoneDesc,
               @vDestLocation       = DestLocation
  from @ttLPNsToPutaway
  order by RecordId;

  set @xmlResult = ( select @PalletId                     as PalletId,
                            @Pallet                       as Pallet,
                            @vNumLPNsOnPallet             as NumCasesOnPallet,
                            /* Confirm LPN Putaway Params */
                            @vLPNId                       as LPNId,
                            @vLPN                         as LPN,
                            @vLPNType                     as LPNType,
                            @vSKU                         as SKU,
                            @vSKUDescription              as SKUDescription,
                            @vSKUUoM                      as SKUUoM,
                            @vUPC                         as UPC,
                            @vSKUPutawayClass             as PutawayClass,
                            @vQuantity                    as Quantity,
                            coalesce(@vDestZoneDesc, @vDestZone)
                                                          as DestZone,
                            @vDestLocation                as DestLocation,
                            @vPAAllowScan                 as AllowScan,
                            @Operation                    as SubOperation,
                            @ScanOption                   as ScanOption,
                            @ConfirmQtyRequired           as ConfirmQtyRequired
                     FOR XML RAW('PALPNDETAILS'), TYPE, ELEMENTS XSINIL, ROOT('PUTAWAYLPNS'));

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Putaway_PutawayLPNsBuildResponse */

Go
