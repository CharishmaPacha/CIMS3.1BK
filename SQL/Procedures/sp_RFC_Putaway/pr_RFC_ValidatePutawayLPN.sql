/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/26  SAK     pr_RFC_ConfirmPutawayLPN and pr_RFC_ValidatePutawayLPN changes to send message with LPNDesc on error message (HA-2435)
  2020/11/29  RIA     pr_RFC_ValidatePutawayLPNOnPallet: Changes to validate PalletStatuses (CIMSV3-727)
  2020/04/14  VM      pr_RFC_ValidatePutawayLPN: Call pr_LPNs_ValidateInventoryMovement for more validations (HA-161)
  2020/02/17  RKC     pr_RFC_ConfirmPutawayLPN: Added validation not to allow putaway LPN, if Location is invalid
                      pr_RFC_ValidatePutawayLPN: Added coalesce statement for LPNIsAlreadyInSameLocation (JL-107)
  2019/08/02  RKC     pr_RFC_ValidatePutawayLPN: Added validation not to allow putaway LPN, if SKU is InActive (HPI-2683)
  2019/02/22  VS      pr_RFC_ValidatePutawayLPN, pr_RFC_ValidatePutawayLPNs, pr_RFC_ConfirmPutawayLPN: Added Validation for QCLPN Putaway (CID-110)
  2018/11/09  TK      pr_Putaway_MinimumQtyToPA -> pr_Putaway_SuggestedQtyToPA (HPI-2115)
                      pr_RFC_ConfirmPutawayLPN & pr_RFC_ValidatePutawayLPN:
                        Changes to display min primary location qty and max secondary location quantities (HPI-2115)
  2018/10/28  VS      pr_RFC_ValidatePutawayLPNs, pr_RFC_CancelPutawayLPNs: Added Logging
  2018/05/22  TK      pr_RFC_ValidatePutawayLPN: Validate SKU attributes (S2GCAN-26)
  2018/06/12  RV      pr_RFC_ValidatePutawayLPN: Restricted to putaway inventory before close receiver based upon the control variable (S2GCA-25)
  2018/03/15  TD/AY   pr_RFC_ValidatePutawayLPN,pr_RFC_ConfirmPutawayLPN:Changes to suggest proper values in RF based on the innerpacks (S2G-432)
  2018/03/09  AY/OK   pr_RFC_ValidatePutawayLPN, pr_RFC_ConfirmPutawayLPN: Made changes to allow putaway for InTransit LPNs (S2G-331)
  2018/03/01  RV/VM   pr_RFC_ValidatePutawayLPN: Changed display quantity to display in case if case quantity available (S2G-315)
  2017/08/24  TK      pr_RFC_ValidatePutawayLPN & pr_RFC_ConfirmPutawayLPN: Return Default Qty (HPI-1626)
  2017/08/17  TK      pr_RFC_ValidatePutawayLPN & pr_RFC_ConfirmPutawayLPN: Invoke proc to build response for RF (HPI-1626)
  2017/08/15  TK      pr_RFC_ValidatePutawayLPN: Changed proc signature to accpet Txml parameters
                                                 Changes to return DisplayQty & PartialPutaway flag
                      pr_RFC_ConfirmPutawayLPN: Changed proc signature to accpet Txml parameters
                                                Changes to consider ReplenishClass if LPN is putaway paritally (HPI-1626)
  2017/07/07  RV      pr_RFC_CancelPutawayLPN, pr_RFC_ConfirmPutawayLPN, pr_RFC_ValidatePutawayLPN: Procedure id
                        is passed to logging procedure to determine this procedure required to logging or not from debug options (HPI-1584)
  2017/04/12  TK      pr_RFC_PA_CompleteVAS & pr_RFC_ValidatePutawayLPNs:
                        Changes to Validate Scanned LPN signature (HPI-1490)
  2016/12/02  TK      pr_RFC_ValidatePutawayLPN: Changed to return Message Information if any (HPI-1105)
  2016/10/15  RV      pr_RFC_ValidatePutawayLPN: Made changes to disable the quantity dropdown to avoid the entering quantity (HPI-868)
  2016/07/15  VM      pr_RFC_ValidatePutawayLPN: Allow Intransit LPN also to be Putaway.
  2016/02/25  TK      pr_RFC_ValidatePutawayLPNs: Initial Revision
                      pr_RFC_CancelPutawayLPNs: Initial Revision
                      pr_RFC_PutawayLPNsGetNextLPN: InitialRevision (GNC-1247)
  2015/12/07  AY      pr_RFC_ValidatePutawayLPN: Handle duplicate UPCs i.e. diff SKUs having same UPC (SRI-422)
  2015/10/30  RV      pr_RFC_ValidatePutawayLPN: Decide Validation of SKUPAClass is required or not from control value (FB-474)
  2015/10/29  RV      pr_RFC_ConfirmPutawayLPN: Re count the Replenished LPNs and update the LPN Detail's OnhandStatus (FB-475)
                      pr_RFC_ValidatePutawayLPN: Allow replenish LPNs to Putaway with Picked (K) status (FB-475)
  2015/09/25  TK      pr_RFC_ValidatePutawayLPN: Changes made to consider Pallet while validating LPN(ACME-349)
  2015/09/22  TK      pr_RFC_ConfirmPutawayLPN & pr_RFC_ValidatePutawayLPN: Introduced new control variable to verify whether they need any
                       confirmation to Putaway to different Location than the suggested (ACME-343)
  2015/08/31  TK      pr_RFC_ValidatePutawayLPN: Consider Confirm Qty Required value
  2015/05/05  OK      pr_RFC_ConfirmPutawayLPN, pr_RFC_ValidatePutawayLPN, pr_RFC_ValidatePutawayByLocation,
                        pr_RFC_PA_ConfirmPutawayPallet: Made system compatable to accept either Location or Barcode.
  2014/11/18  PKS     pr_RFC_ValidatePutawayLPN: Logging of Activity is set based on Control Variable.
  2014/08/14  PK      pr_RFC_ValidatePutawayLPN, pr_RFC_ConfirmPutawayLPN: Included logging mechanism for Putaway operations.
  2014/07/21  PK      pr_RFC_ValidatePutawayLPN: Included a validation to validate LPNPutawaClass (Err).
  2014/07/04  AY      pr_RFC_ValidatePutawayLPN: Changes to update Destlocation on LPN
  2014/05/14  AY      pr_RFC_ValidatePutawayLPN: Direct LPN to DestLocation if there is one
  2013/12/12  TD      pr_RFC_ValidatePutawayLPN:Changes to validate the given LPN is allocated for any order/line.
  2013/03/25  PK      pr_RFC_ConfirmPutawayLPN, pr_RFC_ConfirmPutawayLPNOnPallet, pr_RFC_ValidatePutawayLPNOnPallet:
                       Changes related to Putaway MultiSKU LPNs
  2012/08/21  VM/NY   pr_RFC_ValidatePutawayLPNOnPallet: Allow Receiving/Inventory pallets to PA.
  2011/09/26  PK      pr_RFC_ValidatePutawayLPN: Changes related PutawayByLocation - validate if LPN is placed in same Location again.
  2011/07/26  DP      pr_RFC_ValidatePutawayLPN: Changed MessageName PALPNInvalidStatus =>  LPNStatusIsInValid
  2011/07/13  DP      pr_RFC_ValidatePutawayLPN: Implemented the functionality
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ValidatePutawayLPN') is not null
  drop Procedure pr_RFC_ValidatePutawayLPN;
Go
/*------------------------------------------------------------------------------
  pr_RFC_ValidatePutawayLPN

  This is now enhanced to accept PAType.
  PAType L  - to find a Location for an LPN
  PAType LD - to find a Location for the LPN Contents

  XMLInput Structure:
    <VALIDATEPUTAWAYLPN>
       <LPN></LPN>
       <SKU></SKU>
       <Pallet></Pallet>
       <Location></Location>
       <PAType></PAType>
       <DeviceId></DeviceId>
       <UserId></UserId>
       <BusinessUnit></BusinessUnit>
    </VALIDATEPUTAWAYLPN>

  XMLResult Structure:
    <PUTAWAYLPNDETAILS>
       <LPNINFO>
          <LPN></LPN>
          <SKU></SKU>
          <SKUDescription></SKUDescription>
          <SKUUoM></SKUUoM>
          <InnerPacks></InnerPacks>
          <Quantity></Quantity>
          <DisplayQty></DisplayQty>
          <DefaultQty></DefaultQty>
          <DestZone></DestZone>
          <DestLocation></DestLocation>
          <PutawayMode></PutawayMode>
       </LPNINFO>
       <OPTIONS>
          <ConfirmQtyRequired></ConfirmQtyRequired>
          <ConfirmQtyRequiredForUnitsPA></ConfirmQtyRequiredForUnitsPA>
          <ConfirmPAToDiffLoc></ConfirmPAToDiffLoc>
          <PartialPutaway></PartialPutaway>
       </OPTIONS>
       <MESSAGE>
          <MsgInformation></MsgInformation>
          <ConfirmationMsg></ConfirmationMsg>
       </MESSAGE>
    </PUTAWAYLPNDETAILS>
----------------------------------------------------------------------------*/
Create Procedure pr_RFC_ValidatePutawayLPN
  (@XMLInput         TXML,
   @XMLResult        TXML = null output)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vMessage            TDescription,
          @vErrorMsg           TMessage,
          @vMsgInfo            TMessage,
          @vConfirmationMsg    TMessage,
          @vUserId             TUserId,
          @vDeviceId           TDeviceId,
          @vBusinessUnit       TBusinessUnit,

          @vLPNId              TRecordId,
          @vLPNSKUId           TRecordId,
          @vScannedLPN         TLPN,
          @vLPN                TLPN,
          @vLPNLocation        TLocation,
          @vLPNType            TLocationType,
          @vLPNStatus          TStatus,
          @vInnerPacks         TInnerPacks,
          @vQuantity           TQuantity,
          @vLPNDestWarehouse   TWarehouse,
          @vLPNDestLocation    TLocation,
          @vLPNOrderId         TRecordId,
          @vLPNStatusDesc      TDescription,
          @vOrdertype          TTypeCode,
          @vValidPALPNStatus   TControlValue,
          @vValidReplenishLPNStatus
                               TControlValue,
          @vLPNPutawayClass    TPutawayClass,

          @vLPNPalletId        TRecordId,
          @vPalletId           TRecordId,
          @vPallet             TPallet,
          @vPAType             TTypeCode,

          @vSKUId              TRecordId,
          @vSKU                TSKU,
          @vSKUStatus          TStatus,
          @vSKU4               TSKU,
          @vSKUDescription     TDescription,
          @vSKUUoM             TUoM,
          @vSKUPutawayClass    TPutawayClass,
          @vSKUPAClassRequired TControlValue,

          @vConfirmQtyRequired  TFlag,
          @vConfirmQtyRequiredForUnitsPA
                                TFlag,
          @vConfirmPAToDiffLoc  TFlag,
          @vPartialPutaway      TFlag,
          @vPromptResponse      TFlag,
          @vPALocationId        TRecordId,
          @vPALocation          TLocation,
          @vDestZone            TLocation,
          @vDestLocationId      TRecordId,
          @vDestLocation        TLocation,
          @vDestLocationType    TLocationType,
          @vDestLocStorageType  TStorageType,
          @vDestLocationStatus  TStatus,
          @vLPNReservedQty      TQuantity,
          @vTotalLocQty         TQuantity,
          @vPrimaryLocPAQty     TQuantity,
          @vSecondaryLocPAQty   TQuantity,
          @vLocMaxUnits         TQuantity,
          @vDisplayQty          TString,
          @vPASKUId             TRecordId,
          @vPAInnerPacks        TInnerPacks,
          @vDefaultQty          TQuantity,
          @vPAQuantity          TQuantity,
          @vLoggedInWarehouse   TWarehouse,
          @vNote1               TDescription,
          @vActivityOption      TControlValue,
          @xmlResultvar         TXML,
          @vXmlInput            xml,
          @xmlRulesData         TXML,
          @vActivityLogId       TRecordId;
begin
begin try
  SET NOCOUNT ON;

  set @vXmlInput = cast(@XMLInput as xml);

  if (@vXmlInput is not null)
    select @vScannedLPN   = Record.Col.value('LPN[1]',           'TLPN'),
           @vSKU          = Record.Col.value('SKU[1]',           'TSKU'),
           @vPallet       = Record.Col.value('Pallet[1]',        'TPallet'),
           @vPALocation   = Record.Col.value('Location[1]',      'TLocation'),
           @vPAType       = Record.Col.value('PAType[1]',        'TFlags'),
           @vDeviceId     = Record.Col.value('DeviceId[1]',      'TDeviceId'),
           @vUserId       = Record.Col.value('UserId[1]',        'TUserId'),
           @vBusinessUnit = Record.Col.value('BusinessUnit[1]',  'TBusinessUnit')
    from @vxmlInput.nodes('VALIDATEPUTAWAYLPN') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @vxmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      null, @vScannedLPN, 'LPN',
                      @Value1 = @vPALocation, @Value2 = @vSKU, @Value3 = @vPallet, @Value4 = @vPAType,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get Control variable value of SKUPAClassRequired of Putaway from Controls table. */
  select @vSKUPAClassRequired = dbo.fn_Controls_GetAsString('Putaway', 'SKUPAClassRequired', 'N' /* No */, @vBusinessUnit, @vUserId);

  /* If PAType is not sent from the caller, then assume it is Putaway of LPN */
  select @vPAType     = coalesce(nullif(@vPAType, ''), 'L' /* LPN */),
         @vPALocation = nullif(@vPALocation, ''),
         @vPallet     = nullif(@vPallet, ''),
         @vReturnCode = 0,
         @vOrderType  = '';

  /* Get LPN Info into local variables */
  select @vLPNId            = LPNId,
         @vLPN              = LPN,
         @vLPNLocation      = Location,
         @vLPNSKUId         = SKUId,
                              /* If we are putting away entire LPN, then use LPN SKU */
         @vSKU              = case when @vPAType = 'L' then coalesce(SKU, 'Mixed') else @vSKU end,
         @vLPNPalletId      = PalletId,
         @vLPNType          = LPNType,
         @vLPNStatus        = Status,
         @vInnerPacks       = InnerPacks,
         @vQuantity         = Quantity,
         @vLPNDestWarehouse = DestWarehouse,
         @vLPNReservedQty   = ReservedQty,
         @vLPNDestLocation  = DestLocation,
         @vLPNOrderId       = OrderId,
         @vLPNPutawayClass  = PutawayClass
  from vwLPNs
  where (LPN = @vScannedLPN) and
        (BusinessUnit = @vBusinessUnit);

  /* Get Order Details here */
  select @vOrderType = OrderType
  from OrderHeaders
  where (OrderId = @vLPNOrderId);

  /* Get PA Location Id */
  if (@vPALocation is not null)
    select @vPALocationId = LocationId
    from Locations
    where (Location = @vPALocation) and (BusinessUnit = @vBusinessUnit);

  if (@vOrderType in ('RU' , 'RP', 'R' /* Replenish Orders */))
    select @vValidReplenishLPNStatus  = dbo.fn_Controls_GetAsString('ReplenishPutaway', 'ValidLPNStatus', 'K' /* Picked */,  @vBusinessUnit, @vUserId);
  else
    select @vValidPALPNStatus  = dbo.fn_Controls_GetAsString('Putaway', 'ValidLPNStatus', 'TNRP' /* InTransit/New/Received/Putaway */,  @vBusinessUnit, @vUserId);

  /* Assume user has given SKU - order by Status so we
     will find an Active SKU first */
  if (@vSKU is not null)
    begin
      /* If the user has scanned a UPC and there are multiple SKUs with the same UPC
         then we may not identify the right SKU, so join with LPNDetails and we can
         narrow down to the SKU */
      select top 1 @vSKUId      = SS.SKUId,
                   @vInnerPacks = LD.InnerPacks,
                   @vQuantity   = LD.Quantity
      from dbo.fn_SKUs_GetScannedSKUs (@vSKU, @vBusinessUnit) SS
        join vwLPNDetails LD on (SS.SKUId = LD.SKUId) and (LD.LPNId = @vLPNId)
      order by Status;
    end

  /* Get SKU Details from vwSKU - SKU, Description, UoM */
  select @vSKU             = SKU,
         @vSKUStatus       = Status,
         @vSKUDescription  = Description,
         @vSKUUoM          = UoM,
         @vSKU4            = SKU4,
         @vSKUPutawayClass = PutawayClass
  from vwSKUs
  where (SKUId = @vSKUId);

  if (@vPallet is not null)
    select @vPalletId = PalletId
    from Pallets
    where (Pallet       = @vPallet      ) and
          (BusinessUnit = @vBusinessUnit);

  /* Get user logged in Warehouse */
  select @vLoggedInWarehouse = dbo.fn_Users_LoggedInWarehouse(@vDeviceId, @vUserId, @vBusinessUnit);

  /* If the LPN has DestLocation set, check if it is a valid Location
     and if so putaway to it */
  if (@vLPNDestLocation is not null)
    select @vDestLocationId     = LocationId,
           @vDestZone           = PutawayZone,
           @vDestLocation       = Location,
           @vDestLocationType   = LocationType,
           @vDestLocStorageType = StorageType,
           @vDestLocationStatus = Status
    from Locations
    where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @vLPNDestLocation, @vDeviceId, @vUserId, @vBusinessUnit));

  /* Build the XML for custom validations */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Operation',     'ValidatePutawayLPN') +
                           dbo.fn_XMLNode('LPNId',          @vLPNId) +
                           dbo.fn_XMLNode('DestLocationId', @vDestLocationId));

  /* Validate i/p params */
  /* Valid LPN, LPN cannot be a Zcase, Valid statuses, Not reserved etc. */
  if (@vLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (@vLPNType =  'L' /* Picklane - Zcase */)
    set @vMessageName = 'LPNTypeCannotbePickLane';
  else
  if (@vPallet is not null) and (@vPalletId is null)
    set @vMessageName = 'InvalidPallet'
  else
  if (@vPallet is not null) and (@vPalletId <> coalesce(@vLPNPalletId, 0))
    set @vMessageName = 'LPNNotOnaPallet';
  else
  if (charindex(@vLPNStatus, @vValidPALPNStatus) = 0) and /* Valid LPN statuses for Putaway */
      (@vOrderType not in ('RU', 'RP', 'R' /* Replenish Orders */))
    begin
      select @vLPNStatusDesc = dbo.fn_Status_GetDescription ('LPN', @vLPNStatus, @vBusinessUnit);
      select @vMessageName = 'LPNPA_LPNStatusIsInvalid', @vNote1 = @vLPNStatusDesc;
    end
  else
  if ((@vOrderType in ('RU', 'RP', 'R' /* Replenish Orders */)) and
      (charindex(@vLPNStatus, @vValidReplenishLPNStatus) = 0))
    set @vMessageName = 'LPNPA_ReplenishLPNStatusIsInValid';
  else
  if (@vSKUStatus     = 'I' /* InActive */)
    set @vMessageName = 'PALPN_InvalidSKUStatus';
  else
  if (@vLPNDestWarehouse is null)
    set @vMessageName = 'PALPNNoDestWarehouse';
  else
  /* Validate if LPN belongs to user logged in Warehouse */
  if (@vLPNDestWarehouse not in (select TargetValue
                                 from dbo.fn_GetMappedValues('CIMS', @vLoggedInWarehouse,'CIMS', 'Warehouse', 'Putaway', @vBusinessUnit)))
   select @vMessageName = 'PA_ScannedLPNIsOfDifferentWH', @vNote1 = @vLPNDestWarehouse;
  else
  if (coalesce(@vLPNLocation,'') <> '') and (@vLPNLocation = coalesce(@vPALocation, ''))
    set @vMessageName = 'LPNIsAlreadyInSameLocation';
  else
  if (coalesce(@vLPNReservedQty, 0) > 0) and
     (@vOrderType not in ('RU', 'RP', 'R' /* Replenish Orders */))
    set @vMessageName = 'LPNPA_LPNIsAllocated';
  else
  if ((@vSKU is not null) and (@vSKUId is null))
    set @vMessageName = 'SKUDoesNotExistInLPN';
  else
  if ((@vSKUPAClassRequired = 'Y') and coalesce(@vSKUPutawayClass, '') = '')
    set @vMessageName = 'PA_SKUPAClassNotDefined';
  else
  if (@vLPNPutawayClass = 'Err') and (@vLPNDestLocation is null)
    set @vMessageName = 'PA_LPNPAClassHasNoRules';
  else
  if (@vPALocation <> @vDestLocation) and (charindex(@vLPNStatus, @vValidReplenishLPNStatus) > 0)
    begin
      select @vMessageName = 'PA_ToDestinationOnly',
             @vNote1       = @vDestLocation;
    end
  else
    set @vMessageName = dbo.fn_SKUs_IsOperationAllowed(@vSKUId, 'PutawayLPN');

  if (@vMessageName is not null)
     goto ErrorHandler;

  /* More validations - if there are any exceptions, catch block catches to raise the error */
  exec @vReturnCode = pr_LPNs_ValidateInventoryMovement @vLPNId, null /* PalletId */, @vPALocationId, 'Putaway', @vBusinessUnit, @vUserId;

  /* Other custom validations */
  exec pr_RuleSets_Evaluate 'Putaway_Validations', @xmlRulesData, @vMessageName output;

  if (@vMessageName is not null)
     goto ErrorHandler;

  /* If PA is by Location, then user has already determined the Location, or
     the LPN could already has a Destination determined - in both of these
     scenarios we don't need to find a location for the LPN
  */
  if (@vPALocation is null) and (@vDestLocation is null)
    begin
      /* LPN is valid, now determine the DestZone and DestLocation */
      exec @vReturnCode = pr_Putaway_FindLocationForLPN @vLPNId,
                                                        @vSKUId, /* PASKUId   */
                                                        @vPAType, /* PA Option */
                                                        @vBusinessUnit,
                                                        @vUserId,
                                                        @vDeviceId,
                                                        @vDestZone           output,
                                                        @vDestLocation       output,
                                                        @vDestLocStorageType output,
                                                        @vPASKUId            output,
                                                        @vInnerPacks         output,
                                                        @vQuantity           output,
                                                        @vMessageName        output;

      if (@vMessageName is not null)
         goto ErrorHandler;

      /* Update the Destination of the Case to ensure it gets there */
      if (@vDestLocation is not null) and (@vLPNPutawayClass in ('1', '2', '3'))
        exec pr_LPNs_SetDestination @vLPNId, default /* Operation */, default /* DestLocId */,
                                    @vDestLocation, @vDestZone;

      /* Get SKU Details from vwSKU - SKU, Description, UoM */
      if (@vPASKUId is not null)
        select @vSKU            = SKU,
               @vSKUDescription = Description,
               @vSKUUoM         = UoM,
               @vSKU4           = SKU4
        from vwSKUs
        where (SKUId = @vPASKUId);

    end
  else
  /* If there is a pre-determined PA Location, then consider that the destination of the LPN */
  if (@vPALocation is not null)
    select @vDestLocation   = @vPALocation,
           @vDestLocationId = @vPALocationId;

  /* Get Dest Location info */
  select @vDestLocationId     = LocationId,
         @vDestZone           = PutawayZone,
         @vDestLocation       = Location,
         @vDestLocStorageType = StorageType,
         @vDestLocationType   = LocationType
  from Locations
  where (Location     = @vDestLocation) and
        (BusinessUnit = @vBusinessUnit);

  /* If the DestLocation is a picklane & it is Replenish PA */
  if (@vDestLocationType = 'K'/* Picklane */) and (@vOrderType in ('R', 'RU', 'RP'))  -- DestLocationtype would be null if LPN does not alreaady have destination
    begin
      /* get the Min Qty that can be putaway */
      exec pr_Putaway_SuggestedQtyToPA @vLPNId, @vDestLocationId, @vSKUId,
                                       @vPrimaryLocPAQty output, @vSecondaryLocPAQty output, @vMsgInfo output;

      /* If MinToPA & LPNQty are different then it should be a partial putaway and
         display min qty that should be putaway to Location */
      if (@vPrimaryLocPAQty > 0) and (@vPrimaryLocPAQty <= @vQuantity)
        select @vPartialPutaway = 'Y' /* Yes */,
               @vDisplayQty     = dbo.fn_Messages_Build('PAReplenishLPN_DisplayQty', @vPrimaryLocPAQty, @vQuantity, @vSKUUoM, null, null);
      else
      if (@vPrimaryLocPAQty = 0)
        /* If there is no Min qty to putaway then just display LPN Qty */
        select @vDisplayQty = dbo.fn_Messages_Build('PALPN_DisplayQty', @vQuantity, @vSKUUoM, null, null, null);
    end
  else
    select @vDisplayQty = dbo.fn_Messages_Build('PALPN_DisplayQty', @vQuantity, @vSKUUoM, null, null, null);

  select @vDefaultQty = coalesce(@vPrimaryLocPAQty, @vQuantity);

  /* Build response to RF */
  exec pr_Putaway_PALPNResponse @vLPNId, @vSKUId, @vDestLocationId, @vDisplayQty, @vDefaultQty, default /* Prompt Response */, @vPartialPutaway,
                                @vMsgInfo, @vConfirmationMsg, @vBusinessUnit, @XMLResult output;

  exec pr_Device_Update @vDeviceId, @vUserId, 'ValidateLPNPutaway', @XMLResult, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vLPN, @vNote1;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  exec @vReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_ValidatePutawayLPN */

Go
