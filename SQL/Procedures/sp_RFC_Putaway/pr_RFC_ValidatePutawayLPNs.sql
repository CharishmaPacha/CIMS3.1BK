/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/22  VS      pr_RFC_ValidatePutawayLPN, pr_RFC_ValidatePutawayLPNs, pr_RFC_ConfirmPutawayLPN: Added Validation for QCLPN Putaway (CID-110)
  2018/10/28  VS      pr_RFC_ValidatePutawayLPNs, pr_RFC_CancelPutawayLPNs: Added Logging
  2017/04/12  TK      pr_RFC_PA_CompleteVAS & pr_RFC_ValidatePutawayLPNs:
                        Changes to Validate Scanned LPN signature (HPI-1490)
  2016/02/25  TK      pr_RFC_ValidatePutawayLPNs: Initial Revision
                      pr_RFC_CancelPutawayLPNs: Initial Revision
                      pr_RFC_PutawayLPNsGetNextLPN: InitialRevision (GNC-1247)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ValidatePutawayLPNs') is not null
  drop Procedure pr_RFC_ValidatePutawayLPNs;
Go
/*------------------------------------------------------------------------------
  pr_RFC_ValidatePutawayLPNs: This Proc will validate the scanned LPN, on success it
                                would generate a pallet and scanned LPN onto that Pallet

   @xmlInput structure:
   <VALIDATEPALPNS>
      <LPN></LPN>
      <Pallet></Pallet>
      <Operation>ValidateLPNs</Operation>
      <DeviceId></DeviceId>
      <BusinessUnit></BusinessUnit>
      <UserId></UserId>
   </VALIDATEPALPNS>

   @xmlOutput structure:
   <VALIDATEPALPNDETAILS>
      <LPN></LPN>
      <Pallet></Pallet>
      <SKU></SKU>
      <Qty></Qty>
      <Options>
        <SubOperation></SubOperation>
        <ConfirmScanLPN></ConfirmScanLPN>
      </Options>
   </VALIDATEPALPNDETAILS>

Assumptions:
  1. LPNs are Single SKU LPNs
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ValidatePutawayLPNs
  (@xmlInput   TXML,
   @xmlResult  TXML          output)
as
  declare @ReturnCode          TInteger,
          @vMessageName        TMessageName,
          @vNote1              TNote,
          @Message             TDescription,

          @Operation           TOperation,
          @BusinessUnit        TBusinessUnit,
          @UserId              TUserId,
          @DeviceId            TDeviceId,
          @vLoggedInWarehouse  TWarehouse,

          @LPN                 TLPN,
          @vLPN                TLPN,
          @vLPNId              TRecordId,
          @vLPNType            TTypeCode,
          @vLPNQty             TQuantity,
          @vLPNReservedQty     TQuantity,
          @vLPNSKUId           TRecordId,
          @vLPNPalletId        TRecordId,
          @vLPNOrderId         TRecordId,
          @vLPNStatus          TStatus,
          @vLPNPutawayClass    TPutawayClass,
          @vInnerPacks         TQuantity,

          @vLPNSKU             TSKU,
          @vLPNSKUPAClass      TPutawayClass,
          @vLPNWH              TWarehouse,
          @vLPNDestZone        TLookupCode,
          @vLPNDestLocation    TLocation,
          @vDestLocStorageType TTypeCode,

          @Pallet              TPallet,
          @vPallet             TPallet,
          @vPalletId           TRecordId,

          @vOrderType          TTypeCode,

          @vValidLPNStatus     TControlValue,
          @vSKUPAClassRequired TControlValue,
          @vConfirmScanLPN     TControlValue,

          @vSKUPAClassCount    TCount,
          @vDestZoneCount      TCount,
          @vLPNStatusCount     TCount,
          @vNumLPNs            TCount,
          @vSubOperation       TOperation,

          @xmlInputInfo        xml,
          @xmlOptions          TXML,
          @xmlRulesData        TXML,
          @vReturnCode         TInteger,
          @vxmlResult          xml,
          @vActivityLogId      TRecordId;

  declare @ttLPNsOnPallet table (LPN             TLPN,
                                 LPNStatus       TTypeCode,
                                 DestZone        TLookupCode,
                                 SKU             TSKU,
                                 SKUPutawayClass TPutawayClass,
                                 RecordId        TRecordId identity (1, 1));
begin
begin try
  SET NOCOUNT ON;

  /* convert into xml */
  select @xmlInputInfo     = convert(xml, @xmlInput),
         @vNumLPNs         = 0,
         @vSKUPAClassCount = 0,
         @vDestZoneCount   = 0,
         @vLPNStatusCount  = 0,
         @vOrderType       = '';

  /* Get the XML User inputs into the local variables */
  select @LPN          = Record.Col.value('LPN[1]'                  , 'TLPN'),
         @Pallet       = nullif(Record.Col.value('Pallet[1]'        , 'TPallet'), ''),
         @Operation    = Record.Col.value('Operation[1]'            , 'TOperation'),
         @BusinessUnit = Record.Col.value('BusinessUnit[1]'         , 'TBusinessUnit'),
         @UserId       = Record.Col.value('UserId[1]'               , 'TUserId'),
         @DeviceId     = Record.Col.value('DeviceId[1]'             , 'TDeviceId')
  from @xmlInputInfo.nodes('VALIDATELPNS') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInputInfo, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      null, @LPN, 'LPN',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* get the scanned LPN details */
  select @vLPNId           = LPNId,
         @vLPN             = LPN,
         @vLPNType         = LPNType,
         @vLPNStatus       = Status,
         @vLPNQty          = Quantity,
         @vLPNReservedQty  = ReservedQty,
         @vLPNSKUId        = SKUId,
         @vLPNSKU          = SKU,
         @vLPNOrderId      = OrderId,
         @vLPNPalletId     = PalletId,
         @vLPNPutawayClass = PutawayClass,
         @vLPNWH           = DestWarehouse,
         @vLPNDestZone     = DestZone,
         @vLPNDestLocation = DestLocation
  from vwLPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@LPN, @BusinessUnit, default /* Options */));

  /* Get the Pallet details */
  select @vPalletId = PalletId,
         @vPallet   = Pallet,
         @vNumLPNs  = NumLPNs
  from Pallets
  where (Pallet       = @Pallet      ) and
        (BusinessUnit = @BusinessUnit);

  /* Get details of Order of the LPN */
  select @vOrderType = OrderType
  from OrderHeaders
  where (OrderId = @vLPNOrderId);

  /* If this is not the first LPN i.e. there is Pallet already, then get details of
     LPNs on Pallet to validate later */
  if (@vPalletId is not null)
    begin
      /* Get the PA class of LPN SKU */
      select @vLPNSKUPAClass = PutawayClass
      from SKUs
      where (SKUId = @vLPNSKUId);

      /* Get all the LPNs already on the pallet and the one just scanned into a temp table */
      insert into @ttLPNsOnPallet
        select L.LPN, L.Status, L.DestZone, S.SKU, S.PutawayClass
        from LPNs L join SKUs S on (S.SKUId = L.SKUId)
        where (L.PalletId = @vPalletId)
        union
        select @vLPN, @vLPNStatus, @vLPNDestZone, @vLPNSKU, @vLPNSKUPAClass;

      /* Get the distinct counts to validate */
      select @vSKUPAClassCount = count(distinct(SKUPutawayClass)),
             @vDestZoneCount   = count(distinct(DestZone)),
             @vLPNStatusCount  = count(distinct(LPNStatus))
      from @ttLPNsOnPallet;
    end

  /* Putaway LPNs is designed for two scenarios only i.e. to Putaway LPNs received and
     to putaway LPNs being replenished, so determine the sub operation and validate it later */
  select @vSubOperation = case when @vLPNStatus = 'R' then 'ReceivingPA'
                               when @vOrderType in ('R', 'RU', 'RP') then 'ReplenishPA'
                               else 'InvalidPALPNs'
                          end;

  /* Get the controls values */
  select @vSKUPAClassRequired = dbo.fn_Controls_GetAsString('Putaway', 'SKUPAClassRequired', 'N' /* No */, @BusinessUnit, @UserId),
         @vConfirmScanLPN     = dbo.fn_Controls_GetAsString('PutawayLPNs_'+@vSubOperation, 'ConfirmScanLPN', 'N', @BusinessUnit, @UserId),
         @vValidLPNStatus     = dbo.fn_Controls_GetAsString('ReplenishPutaway', 'ValidLPNStatus', 'K' /* Picked */,  @BusinessUnit, @UserId);

  /* Get user logged in Warehouse */
  select @vLoggedInWarehouse = dbo.fn_Users_LoggedInWarehouse(@DeviceId, @UserId, @BusinessUnit);

  /* Build the XML for custom validations */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Operation',  'ValidatePutawayLPNs') +
                           dbo.fn_XMLNode('LPNId',      @vLPNId) +
                           dbo.fn_XMLNode('PalletId',   @vPalletId));

  /* Validations */
  if (@vLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (@vLPNPalletId = @vPalletId)
    set @vMessageName = 'PALPNs_LPNAlreadyScanned';
  else
  if (@vLPNType =  'L' /* Picklane - Zcase */)
    set @vMessageName = 'LPNTypeCannotbePickLane';
  else
  if ((@vLPNStatus not in ('N' /* New */, 'R' /* Received */, 'P' /* Putaway */)) and   /* Valid LPN statuses for Putaway */
      (@vOrderType not in ('RU', 'RP', 'R' /* Replenish Orders */)))
    set @vMessageName = 'LPNStatusIsInvalid';
  else
  if ((@vOrderType in ('RU', 'RP', 'R' /* Replenish Orders */)) and
      (charindex(@vLPNStatus, @vValidLPNStatus) = 0))
    set @vMessageName = 'LPNStatusIsInValid';
  else
  if (@vLPNWH is null)
    set @vMessageName = 'PALPNNoDestWarehouse';
  else
  /* Validate if LPN belongs to user logged in Warehouse */
  if (@vLPNWH not in (select TargetValue
                                 from dbo.fn_GetMappedValues('CIMS', @vLoggedInWarehouse,'CIMS', 'Warehouse', 'Putaway', @BusinessUnit)))
   select @vMessageName = 'PA_ScannedLPNIsOfDifferentWH', @vNote1 = @vLPNWH;
  else
  if (coalesce(@vLPNReservedQty, 0) > 0) and
     (@vOrderType not in ('RU', 'RP', 'R' /* Replenish Orders */))
    set @vMessageName = 'LPNPA_LPNIsAllocated';
  else
  if ((@vSKUPAClassRequired = 'Y') and coalesce(@vLPNSKUPAClass, '') = '')
    set @vMessageName = 'PA_SKUPAClassNotDefined';
  else
  if (@vLPNPutawayClass = 'Err') and (@vLPNWH is null)
    set @vMessageName = 'PA_LPNPAClassHasNoRules';
  else
  /* Scenario 1: For first scan lets assume User Scan LPN1
      LPN      SKUPAClass      DestZone
      LPN1       A              D1
      LPN2       A              D2  -- Allow
      LPN3       B              D1  -- Don't Allow
      LPN4       A              D1/D2/D3 -- Allow
    In the above scenario, LPN2 added is same SKUPA class then we would allow and there on we would
    consider SKUPA class as key factor and LPN3 scanned matches with the DestZone we won't allow as we would
    compare only with SKU PA Class'

    Scanario 2: For first scan lets assume User Scan LPN1
      LPN      SKUPAClass      DestZone
      LPN1       A              D1
      LPN2       B              D1  -- Allow
      LPN3       A              D2  -- Don't Allow
      LPN4       A/B/C          D1  -- Allow
    In the above scenario, LPN2 added is same LPN DestZone then we would allow and there on we would
    consider LPN DestZone as key factor and LPN3 scanned matches with the SKUPA class we won't allow as we would
    compare only with LPN DestZone'
    */
  if (@vDestZoneCount > 1) and (@vSKUPAClassCount > 1)
    set @vMessageName = 'PALPNs_DestZoneSKUPutawayClassMismatch';
  else
  if (@vLPNStatusCount > 1)
    set @vMessageName = 'PALPNs_ScannedLPNsWithDiffStatuses';
  else
  if (@vSubOperation = 'InvalidPALPNs')
    set @vMessageName = 'PALPNs_NotImplementedForAlreadyPALPNs';
  else
    /* Other custom validations */
    exec pr_RuleSets_Evaluate 'Putaway_Validations', @xmlRulesData, @vMessageName output;

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Find Location for LPN if there is no Dest Location */
  if (@vLPNDestLocation is null)
    begin
      exec @ReturnCode = pr_Putaway_FindLocationForLPN @vLPNId,
                                                       null, /* SKUId */
                                                       'L'   /* PA Type - LPN */,
                                                       @BusinessUnit,
                                                       @UserId,
                                                       @DeviceId,
                                                       @vLPNDestZone        output,
                                                       @vLPNDestLocation    output,
                                                       @vDestLocStorageType output,
                                                       @vLPNSKUId           output,
                                                       @vInnerPacks         output,
                                                       @vLPNQty             output,
                                                       @vMessageName        output;

      /* Update the Destination on the LPN */
      if (@vLPNDestLocation is not null)
        exec pr_LPNs_SetDestination @vLPNId, default /* Operation */, null /* LocId */,
                                    @vLPNDestLocation, @vLPNDestZone;
      else
        begin
          set @vMessageName = 'NoLocationsToPutaway';
          goto ErrorHandler;
        end
    end

  /* We use the Pallet to tie all the scanned LPNs together, so if a Pallet has not been
     passed in, generate one */
  if (@vPalletId is null)
    exec @ReturnCode = pr_Pallets_GeneratePalletLPNs 'U'           /* PalletType - Putaway Pallet */,
                                                     1             /* NumPalletsToCreate */,
                                                     null          /* PalletFormat */,
                                                     0             /* NumLPNs */ ,
                                                     null          /* LPNType */,
                                                     null          /* LPNFormat */ ,
                                                     @vLPNWH       /* DestWarehouse */,
                                                     @BusinessUnit /* BusinessUnit */,
                                                     @UserId       /* UserId */,
                                                     @vPalletId  output,
                                                     @vPallet    output;

  if (@vReturnCode > 0)
    goto ErrorHandler;

  /* Add scanned LPN to Pallet */
  exec pr_LPNs_SetPallet @vLPNId, @vPalletId, @UserId;

  /* Update Package Sequence No */
  update LPNs
  set PackageSeqNo = coalesce(@vNumLPNs, 0) + 1
  where (LPNId = @vLPNId);

  /* No need to show generated pallet in UI */
  update Pallets
  set Archived = 'Y' /* Yes */
  where (PalletId = @vPalletId);

  /* Build XML Result */
  set @xmlOptions = (select @vSubOperation    as  SubOperation,
                            @vConfirmScanLPN  as  ConfirmScanLPN
                     for XML raw('OPTIONS'), elements );

  set @xmlResult = (select '<VALIDATELPNSDETAILS>' +
                               dbo.fn_XMLNode('LPN'    ,  @vLPN) +
                               dbo.fn_XMLNode('Pallet' ,  @vPallet) +
                               dbo.fn_XMLNode('SKU'    ,  @vLPNSKU) +
                               dbo.fn_XMLNode('Qty'    ,  @vLPNQty) +
                               dbo.fn_XMLNode('NumLPNs',  coalesce(@vNumLPNs, 0) + 1) +
                               coalesce(@xmlOptions, '') +
                           '</VALIDATELPNSDETAILS>');

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @vMessageName, @vLPN, @vNote1;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @Result = @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_ValidatePutawayLPNs */

Go
