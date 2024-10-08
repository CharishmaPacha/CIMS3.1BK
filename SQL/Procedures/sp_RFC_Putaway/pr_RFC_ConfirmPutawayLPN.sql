/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/26  SAK     pr_RFC_ConfirmPutawayLPN and pr_RFC_ValidatePutawayLPN changes to send message with LPNDesc on error message (HA-2435)
  2020/11/18  AY      pr_RFC_ConfirmPutawayLPN: Bug fix, allowing to override location even if user does not have permission (CIMSV3-1226)
  2020/06/11  TK      pr_RFC_ConfirmPutawayLPN: Migrated changes from S2G to unallocate partial LPN based on control (HA-891)
  2020/05/05  RIA     pr_RFC_ConfirmPutawayLPN: Changes to call pr_Putaway_LPNContentsToPicklane (HA-414)
  2020/02/17  RKC     pr_RFC_ConfirmPutawayLPN: Added validation not to allow putaway LPN, if Location is invalid
                      pr_RFC_ValidatePutawayLPN: Added coalesce statement for LPNIsAlreadyInSameLocation (JL-107)
  2019/02/22  OK      pr_RFC_ConfirmPutawayLPN: Changes to do not allow putaway inventory into other static picklanes unless user has permissions (HPI-2457)
  2019/02/22  VS      pr_RFC_ValidatePutawayLPN, pr_RFC_ValidatePutawayLPNs, pr_RFC_ConfirmPutawayLPN: Added Validation for QCLPN Putaway (CID-110)
  2019/01/08  TK      pr_RFC_ConfirmPutawayLPN: Do not consider initial primary location qty to transfer reservations (HPI-2306)
  2018/12/17  TK      pr_RFC_ConfirmPutawayLPN: Changes to pass in OrderDetailId to transfer reservation (HPI-2248)
  2018/12/14  TK      pr_RFC_ConfirmPutawayLPN: Do not override the quantity that is being putaway as it is needed for displaying message (HPI-2251)
  2018/12/05  AY      pr_RFC_ConfirmPutawayLPN etc.: Logging changes and log AT against Replenish OrderId (HPI-Support)
  2018/11/21  TK      pr_RFC_ConfirmPutawayLPN: Log AT on Dest Location if user putaway replenish LPN to other than Dest Location (HPI-2166)
  2018/11/09  TK      pr_Putaway_MinimumQtyToPA -> pr_Putaway_SuggestedQtyToPA (HPI-2115)
                      pr_RFC_ConfirmPutawayLPN & pr_RFC_ValidatePutawayLPN:
                        Changes to display min primary location qty and max secondary location quantities (HPI-2115)
  2018/11/05  TK      pr_RFC_ConfirmPutawayLPN: Transfer reserved quantities if user is trying to putaway replenish picked LPN to a different location (HPI-2116)
  2018/11/04  TK      pr_RFC_ConfirmPutawayLPN: Allow putaway replenish picked LPN to different Location (HPI-2115)
  2018/03/15  TD/AY   pr_RFC_ValidatePutawayLPN,pr_RFC_ConfirmPutawayLPN:Changes to suggest proper values in RF based on the innerpacks (S2G-432)
  2018/03/13  TK      pr_RFC_ConfirmPutawayLPN: Unallocate partially putaway LPN based upon control variable (S2G-396)
  2018/03/09  AY/OK   pr_RFC_ValidatePutawayLPN, pr_RFC_ConfirmPutawayLPN: Made changes to allow putaway for InTransit LPNs (S2G-331)
  2018/01/10  SV      pr_RFC_ConfirmPutawayLPNOnPallet: Signature correction while calling pr_RFC_ConfirmPutawayLPN (S2G-72)
  2017/12/27  AY      pr_RFC_ConfirmPutawayLPN: Changed the order of validations for better user responses
  2017/02/10  OK      pr_RFC_ConfirmPutawayLPN: Enhanced to restrict the Putaway and replenishments
                       if location is OnHold and do not allow these operations (GNC-1426)
  2017/10/29  PK      pr_RFC_ConfirmPutawayLPN: Added IsReplenishable field and only unassociating order info when reserve location is replenishable (HPI-1730).
  2017/08/24  TK      pr_RFC_ValidatePutawayLPN & pr_RFC_ConfirmPutawayLPN: Return Default Qty (HPI-1626)
  2017/08/17  TK      pr_RFC_ValidatePutawayLPN & pr_RFC_ConfirmPutawayLPN: Invoke proc to build response for RF (HPI-1626)
  2017/08/15  TK      pr_RFC_ValidatePutawayLPN: Changed proc signature to accpet Txml parameters
                                                 Changes to return DisplayQty & PartialPutaway flag
                      pr_RFC_ConfirmPutawayLPN: Changed proc signature to accpet Txml parameters
                                                Changes to consider ReplenishClass if LPN is putaway paritally (HPI-1626)
  2017/07/07  RV      pr_RFC_CancelPutawayLPN, pr_RFC_ConfirmPutawayLPN, pr_RFC_ValidatePutawayLPN: Procedure id
                        is passed to logging procedure to determine this procedure required to logging or not from debug options (HPI-1584)
  2017/05/19  PSK     pr_RFC_ConfirmPutawayLPN: Validate if OrderType is null (HPI-1402)
  2017/01/23  AY      pr_RFC_ConfirmPutawayLPN: Do not allow PA to a Location that is not assigned for SKU (HPI-1307)
  2016/09/18  AY      pr_RFC_ConfirmPutawayLPN: Give appropriate error on consumed LPN confirmation (HPI-GoLive)
  2016/09/17  SV      pr_RFC_ConfirmPutawayLPN: Introduced the AT Log over the LPN upon confirming the Pick (HPI-684)
  2016/03/14  DK      pr_RFC_ConfirmPutawayLPNOnPallet, pr_RFC_ConfirmPutawayLPNOnPallet: Validate if LPN is on Pallet.(CIMS-807).
  2015/12/16  TK      pr_RFC_ConfirmPutawayLPN: Restrict user from scannning Location other than suggested Location when
                        LPN is allocated to a Replenish Order (ACME-419)
  2015/10/29  RV      pr_RFC_ConfirmPutawayLPN: Re count the Replenished LPNs and update the LPN Detail's OnhandStatus (FB-475)
                      pr_RFC_ValidatePutawayLPN: Allow replenish LPNs to Putaway with Picked (K) status (FB-475)
  2015/10/19  TK      pr_RFC_PA_ValidatePutawayPallet: Enhanced to prevent PA of multi SKU Pallet if
                        Allow multiple SKUs flag option is set to 'N' (ACME-375)
                      pr_RFC_ConfirmPutawayLPN: Clear Pallet on the LPN if it is being Putaway into Picklane Location(ACME-367)
  2015/10/15  TK      pr_RFC_ConfirmPutawayLPN: Enhanced to log AT on From Pallet and From Location(ACME-367)
  2015/10/06  TK      pr_RFC_ConfirmPutawayLPN: Do not allow user to add LPN to Pallet, if it is already on it(ACME-354)
  2015/09/25  TK      pr_RFC_CancelPutawayLPN & pr_RFC_ConfirmPutawayLPN: Added Activity Logs (ACME-348)
  2015/09/22  TK      pr_RFC_ConfirmPutawayLPN & pr_RFC_ValidatePutawayLPN: Introduced new control variable to verify whether they need any
                       confirmation to Putaway to different Location than the suggested (ACME-343)
  2015/09/04  TK      pr_RFC_ConfirmPutawayLPN: Allow If user Scans a Pallet instead of Location, and add LPN to that Pallet (ACME-332)
  2015/05/05  OK      pr_RFC_ConfirmPutawayLPN, pr_RFC_ValidatePutawayLPN, pr_RFC_ValidatePutawayByLocation,
                        pr_RFC_PA_ConfirmPutawayPallet: Made system compatable to accept either Location or Barcode.
  2105/01/21  TK      pr_RFC_ConfirmPutawayLPN: Permission given for Adminstrator
  2014/10/07  PKS     pr_RFC_ConfirmPutawayLPN: Logging of Activity is set based on Control Variable.
  2014/09/03  AK      pr_RFC_ConfirmPutawayLPN:Passed Innerpacks to audit trail for PutawayLPNToPicklane to show the cases and units.
  2014/09/01  TK      pr_RFC_ConfirmPutawayLPN: Updated to log audit trail for Putaway LPNs on a Pallet.
  2014/08/18  TK      pr_RFC_ConfirmPutawayLPNOnPallet: Updated not to update Audit Trail.
  2014/08/14  PK      pr_RFC_ValidatePutawayLPN, pr_RFC_ConfirmPutawayLPN: Included logging mechanism for Putaway operations.
  2014/07/16  PK      pr_RFC_ConfirmPutawayLPN, pr_RFC_ConfirmPutawayLPNOnPallet: Included TransCount for transactions.
  2014/07/04  TD      pr_RFC_ConfirmPutawayLPN:Changes to update Dest Location, DestZone on LPN.
  2014/05/26  TD      pr_RFC_ConfirmPutawayLPN:Changes to allow case storage(Packages) while doing putaway.
  2014/03/14  AY      pr_RFC_ConfirmPutawayLPN: Changed to allow Intransit Locations
  2014/03/14  PK      pr_RFC_ConfirmPutawayLPN: Bug Fix on updating pallet/Location on LPN.
  2013/08/30  TD      pr_RFC_ConfirmPutawayLPN:Changes about to validate Warehouse.
  2103/06/04  TD      pr_RFC_PA_ValidatePutawayPallet,pr_RFC_ConfirmPutawayLPNOnPallet: Allow LPNs to add  to Putaway type Pallet.
  2013/04/13  AY/PK   pr_RFC_ConfirmPutawayLPN: Allow users to override PA to a diff. Location or Zone
  2013/03/31  PK      pr_RFC_ConfirmPutawayLPNOnPallet: Changes for accepting UPC and SKU.
  2013/03/25  PK      pr_RFC_ConfirmPutawayLPN, pr_RFC_ConfirmPutawayLPNOnPallet, pr_RFC_ValidatePutawayLPNOnPallet:
                       Changes related to Putaway MultiSKU LPNs
  2012/12/24  NY      pr_RFC_ConfirmPutawayLPNOnPallet: Added Pallet type of Inventory.
  2012/08/24  VM      pr_RFC_ConfirmPutawayLPN: Clear pallet if putaway to LPN storage location
  2012/08/21  VM      pr_RFC_ConfirmPutawayLPN: Modified to set LPNType = 'L' for all normal LPNs to Putaway into LPN Storage locations
  2012/01/18  PK      pr_RFC_ConfirmPutawayLPN: Allowing to putaway based on the zones on putawayclass.
  2011/12/06  YA      pr_RFC_ValidatePutawayPallet,pr_RFC_ConfirmPutawayLPN: Changes for PalletPutaway.
  2011/11/27  TD      pr_RFC_ConfirmPutawayLPN: Enhanced to PA from Cart positions.
  2011/07/14  DP      pr_RFC_ConfirmPutawayLPN: Implemented the functionality
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ConfirmPutawayLPN') is not null
  drop Procedure pr_RFC_ConfirmPutawayLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ConfirmPutawayLPN:
    This proc does the necessary updates when an LPN has be putaway into a
    Reserve/Bulk Location or into a Picklane. If Putaway into a picklane,
    it could be a partial Putaway i.e. only some units of LPN are putaway.

  PAType - either it is passed in from RF based upon user selected
  menu context/selected option or is determined in FindLocationForLPN

  XMLInput Structure:
    <CONFIRMPUTAWAYLPN>
       <LPN></LPN>
       <SKU></SKU>
       <DestZone></DestZone>
       <DestLocation></DestLocation>
       <ScannedLocation></ScannedLocation>
       <PAInnerPacks></PAInnerPacks>
       <PAQuantity></PAQuantity>
       <PAType></PAType>
       <DeviceId></DeviceId>
       <UserId></UserId>
       <BusinessUnit></BusinessUnit>
    </CONFIRMPUTAWAYLPN>

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
          <PromptScreen>MoveLPN</PromptScreen>
       </OPTIONS>
       <MESSAGE>
          <MsgInformation></MsgInformation>
          <ConfirmationMsg></ConfirmationMsg>
       </MESSAGE>
    </PUTAWAYLPNDETAILS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ConfirmPutawayLPN
  (@XMLInput     TXML,
   @XMLResult    TXML = null output)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vMessage            TMessage,
          @vMsgInfo            TMessage,
          @vActualMsgInfo      TMessage,
          @vConfirmationMsg    TMessage,
          @vNote1              TDescription,
          @vUserId             TUserId,
          @vDeviceId           TDeviceId,
          @vBusinessUnit       TBusinessUnit,

          @vPALPNId            TRecordId,
          @vToLPNId            TRecordId,
          @vScannedLPN         TLPN,
          @vLPN                TLPN,
          @vLPNType            TTypeCode,
          @vLPNStatus          TStatus,
          @vLPNPalletId        TRecordId,
          @vLPNLocationId      TRecordId,
          @vPAType             TTypeCode,
          @vPALPNType          TTypeCode,
          @vLPNInnerPacks      TInnerPacks,
          @vLPNQuantity        TQuantity,
          @vDisplayQty         TDescription,
          @vLPNQtyAfterPA      TQuantity,
          @vLPNIPsAfterPA      TQuantity,
          @vDefaultQty         TQuantity,
          @vDefaultQtyStr      TControlValue,
          @vDRQty              TQuantity,
          @vUnitsPerInnerpacks TInteger,
          @vLPNPutawayClass    TPutawayClass,
          @vPALocationId       TRecordId,
          @vLPNDestWarehouse   TWarehouse,
          @vLPNOrderId         TRecordId,
          @vLPNStatusDesc      TDescription,
          @vLPNWaveNo          TWaveNo,
          @vLPNDestLocation    TLocation,
          @vLPNDestZone        TZoneId,
          @vLDOrderId          TRecordId,
          @vLDOrderDetailId    TRecordId,
          @vToLPNDetailId      TRecordId,
          @vOrderType          TTypeCode,
          @vValidPALPNStatus   TControlValue,
          @vUnallocatePartialLPN
                               TControlValue,
          @vValidReplenishLPNStatus
                               TControlValue,
          @vPAInnerPacks       TInnerPacks,
          @vPAQuantity         TQuantity,

          @vToPalletId         TRecordId,
          @vToPalletStatus     TStatus,
          @vToPalletWH         TWarehouse,
          @vToPalletLocationId TRecordId,

          @vSKU                TSKU,
          @vScannedSKU         TSKU,
          @vSKUCount           TCount,

          @vScannedLocationId  TRecordId,
          @vScannedLocation    TLocation,
          @vLocationType       TLocationType,
          @vLocationSubType    TLocationType,
          @vStorageType        TLocationType,
          @vPALocationTypes    TControlValue,
          @vIsReplenishable    TFlags,
          @vAllowedOperations  TFlags,
          @vLocPutawayZone     TLookUpCode,
          @vLocWarehouse       TWarehouse,
          @vLocationStatus     TStatus,
          @vDestZone           TLookUpCode,
          @vDestLocationId     TRecordId,
          @vDestLocation       TLocation,
          @vDestLocationType   TTypeCode,
          @vInitialPrimaryLocPAQty
                               TQuantity,
          @vInitialSecondaryLocPAQty
                               TQuantity,
          @vPrimaryLocPAQty    TQuantity,
          @vSecondaryLocPAQty  TQuantity,
          @vActualMinQtyToPA   TQuantity,

          @vAllowPAToUnassignedLoc  TControlvalue,
          @vAllowPAToInactiveLoc    TControlValue, /* future use */

          @vSKUId              TRecordId,
          @vSKU4               TSKU,
          @vSKUDescription     TDescription,
          @vSKUUoM             TUoM,
          @vPutawayClass       TCategory,
          @vReplenishClass     TCategory,
          @vConfirmQtyRequired TFlag,
          @vConfirmPAToDiffLoc TFlag,
          @vConfirmQtyRequiredForUnitsPA
                               TFlag,
          @vPartialPutaway     TFlag,
          @vAllowPAToDiffLoc   TFlag,
          @vPromptScreen       TDescription,
          @vDestLocStorageType TLocationType,
          @vPASKUId            TRecordId,
          @vActivityOption     TControlValue,
          @xmlResultvar        TXML,
          @vXmlInput           xml,
          @vActivityLogId      TRecordId,
          @vAuditRecordId      TRecordId,
          @vActivityType       TActivityType,

          @vOperation          TOperation,
          @xmlRulesData        TXML,
          @vInputParamsXml     TXML;
  declare @ttSuggLocations     TEntityKeysTable;
begin
begin try
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode      = 0,
         @vOrderType       = '',
         @vConfirmationMsg = null,
         @vOperation       = 'Putaway',
         @vXmlInput        = cast(@XMLInput as xml);

  if (@vXmlInput is not null)
    select @vScannedLPN      = Record.Col.value('LPN[1]',             'TLPN'),
           @vSKU             = Record.Col.value('SKU[1]',             'TSKU'),
           @vDestZone        = Record.Col.value('DestZone[1]',        'TLookUpCode'),
           @vDestLocation    = Record.Col.value('DestLocation[1]',    'TLocation'),
           @vScannedLocation = Record.Col.value('ScannedLocation[1]', 'TLocation'),
           @vPAInnerPacks    = Record.Col.value('PAInnerPacks[1]',    'TQuantity'),
           @vPAQuantity      = Record.Col.value('PAQuantity[1]',      'TQuantity'),
           @vScannedSKU      = Record.Col.value('ScannedSKU[1]',      'TSKU'),
           @vPAType          = Record.Col.value('PAType[1]',          'TFlags'),
           @vDeviceId        = Record.Col.value('DeviceId[1]',        'TDeviceId'),
           @vUserId          = Record.Col.value('UserId[1]',          'TUserId'),
           @vBusinessUnit    = Record.Col.value('BusinessUnit[1]',    'TBusinessUnit')
    from @vXmlInput.nodes('CONFIRMPUTAWAYLPN') as Record(Col);

  /* insert into activitylog details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId,  @vBusinessUnit, @vUserId, @vDeviceId,
                      null, @vScannedLPN, 'LPN', null /* Operation */, null /* Message */,
                      @vScannedLocation, @vPAQuantity, @vDestLocation, @vPAType, @vScannedSKU,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get LPN Info */
  select @vPALPNId          = LPNId,
         @vLPN              = LPN,
         @vLPNType          = LPNType,
         @vLPNStatus        = Status,
         @vLPNPalletId      = nullif(PalletId, ''),
         @vLPNLocationId    = LocationId,
         @vLPNQuantity      = Quantity,
         @vLPNInnerPacks    = InnerPacks,
         @vLPNDestWarehouse = DestWarehouse,
         @vLPNOrderId       = OrderId,
         @vLPNWaveNo        = PickBatchNo,
         @vLPNDestZone      = DestZone,
         @vLPNDestLocation  = DestLocation,
         @vLPNPutawayClass  = PutawayClass
  from LPNs
  where (LPN          = @vScannedLPN) and
        (BusinessUnit = @vBusinessUnit);

  select @vDestLocationId = LocationId
  from Locations
  where (Location     = @vLPNDestLocation) and
        (BusinessUnit = @vBusinessUnit);

  /* If the LPN is a position on the Cart, then use the Pallet Type as
     LPN Type for Directed Putaway */
  if (@vLPNType = 'A' /* Cart */)
    select @vPALPNType = PalletType
    from Pallets
    where (PalletId = @vLPNPalletId);

  /* Get Location Info */
  select  @vScannedLocationId = LocationId,
          @vScannedLocation   = Location,
          @vLocationType      = LocationType,
          @vLocationSubType   = LocationSubType,
          @vStorageType       = StorageType,
          @vIsReplenishable   = IsReplenishable,
          @vLocPutawayZone    = PutawayZone,
          @vLocationStatus    = Status,
          @vLocWarehouse      = Warehouse,
          @vAllowedOperations = AllowedOperations
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @vScannedLocation, @vDeviceId, @vUserId, @vBusinessUnit));

  /* User may Scan Pallet instead of Location, if so then allow user to add that LPN to that Pallet, so
     if the location is not found above, then check if the user scanned a Pallet */
  if (@vScannedLocationId is null)
    begin
      select @vToPalletId         = PalletId,
             @vToPalletStatus     = Status,
             @vToPalletLocationId = LocationId,
             @vToPalletWH         = Warehouse
      from Pallets
      where (Pallet       = @vScannedLocation) and /* User could have scanned Pallet in the Location */
            (BusinessUnit = @vBusinessUnit);

      /* Get Location from pallet and retrieve Location Details */
      if (@vToPalletLocationId is not null)
        select  @vScannedLocationId = LocationId,
                @vScannedLocation   = Location,
                @vLocationType      = LocationType,
                @vLocationSubType   = LocationSubType,
                @vStorageType       = StorageType,
                @vLocPutawayZone    = PutawayZone,
                @vLocationStatus    = Status,
                @vLocWarehouse      = Warehouse
        from Locations
        where (LocationId = @vToPalletLocationId);
   end

  /* Get SKU Info */
  select @vSKUId          = SKUId,
         @vSKUDescription = Description,
         @vSKUUoM         = UoM,
         @vSKU4           = SKU4,
         @vSKUId          = SKUId,
         @vPutawayClass   = PutawayClass,
         @vReplenishClass = ReplenishClass
  from vwSKUs
  where (SKU = @vSKU) and
        (BusinessUnit = @vBusinessUnit);

  select @vLPNQuantity        = Quantity,
         @vUnitsPerInnerpacks = UnitsPerPackage,
         @vLDOrderId          = OrderId,
         @vLDOrderDetailId    = OrderDetailId
  from LPNDetails
  where (LPNId = @vPALPNId) and
        (SKUId = @vSKUId);

  /* Get SKU count here */
  select @vSKUCount = count(distinct SKUId)
  from LPNDetails
  where (LPNId = @vPALPNId);

  /* Get Order Info */
  if (@vLPNOrderId is not null)
    select @vOrderType = OrderType
    from OrderHeaders
    where (OrderId = @vLPNOrderId);

  /* Calculate Quantity here */
  if (coalesce(@vUnitsPerInnerpacks, 0) > 0) and
     (coalesce(@vPAInnerPacks, 0) > 0) and
     (coalesce(@vPAQuantity, 0) = 0)
    set @vPAQuantity = @vPAInnerPacks * @vUnitsPerInnerpacks;

  if (@vOrderType in ('RU' , 'RP', 'R' /* Replenish Orders */))
    begin
      select @vValidReplenishLPNStatus  = dbo.fn_Controls_GetAsString('ReplenishPutaway', 'ValidLPNStatus', 'K' /* Picked */,  @vBusinessUnit, @vUserId),
             @vAllowPAToDiffLoc = dbo.fn_Controls_GetAsString('ReplenishPutaway', 'PAToDiffLoc', 'S,D' /* Static, Dynamic */,  @vBusinessUnit, @vUserId),
             @vDefaultQtyStr = dbo.fn_Controls_GetAsString('ReplenishPutaway', 'DefaultQtyStr', 'MinQtyToPA',  @vBusinessUnit, @vUserId);

      /* Evaluate min and max quantities that can be putaway to primary and secondary locations */
      exec pr_Putaway_SuggestedQtyToPA @vPALPNId, @vDestLocationId, @vSKUId,
                                       @vInitialPrimaryLocPAQty output, @vInitialSecondaryLocPAQty output, @vActualMsgInfo output;
    end
  else
    select @vValidPALPNStatus  = dbo.fn_Controls_GetAsString('Putaway', 'ValidLPNStatus', 'TNRP' /* InTransit/New/Received/Putaway */,  @vBusinessUnit, @vUserId);

  /* Get the control vars to determine if PA to a pick lane is allowed if it is not setup for the SKU */
  select @vPALocationTypes        = dbo.fn_Controls_GetAsString('Putaway', 'LocationTypes', 'RBKSI', @vBusinessUnit, @vUserId),
         @vUnallocatePartialLPN   = dbo.fn_Controls_GetAsString('Putaway', 'UnallocatePartialLPN', 'N'/* No */, @vBusinessUnit, @vUserId),
         @vAllowPAToUnassignedLoc = dbo.fn_Controls_GetAsString('Inventory', 'TransferToUnassignedLoc', 'Y'/* Yes */, @vBusinessUnit, @vUserId),
         @vAllowPAToInactiveLoc   = dbo.fn_Controls_GetAsString('Inventory', 'TransferToInactiveLoc', 'Y'/* Yes */, @vBusinessUnit, @vUserId);

  /* Build the XML for custom validations */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Operation',      'ConfirmPutawayLPN') +
                           dbo.fn_XMLNode('LPNId',          @vPALPNId) +
                           dbo.fn_XMLNode('PALocationId',   @vScannedLocationId) +
                           dbo.fn_XMLNode('PALocationType', @vLocationType));

  /* Validations */
  if (nullif(@vScannedLPN, '') is null)
    set @vMessageName = 'LPNIsRequired';
  else
  if (@vPALPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (@vScannedLocationId is null)
    set @vMessageName = 'LocationIsInvalid';
  else
  if (@vLPNStatus = 'C' /* Consumed */)
    set @vMessageName = 'PA_LPNAlreadyPutaway';
  else
  if ((@vLPNStatus not in ('T' /* Intransit */, 'N' /* New */, 'R' /* Received */, 'P' /* Putaway */)) and   /* Valid LPN statuses for Putaway */
      (@vOrderType not in ('RU', 'RP', 'R' /* Replenish Orders */)))
    set @vMessageName = 'LPNStatusIsInValid';
  else
  if (@vToPalletId is null) and (@vScannedLocationId is null)
    set @vMessageName = 'PA_ScanValidPalletOrLocation';
  else
  if (@vLPNPalletId is not null) and (@vLPNPalletId = coalesce(@vToPalletId, 0))
    set @vMessageName = 'PA_LPNAlreadyOnOPallet'
  else
  /* Restrict the putaway if Location was OnHold and not allowed for Putaway */
  if ((@vOrderType not in ('RU' ,'RP')) and (coalesce(@vAllowedOperations, '') <> '') and (charindex('P', @vAllowedOperations) = 0))
    set @vMessageName = 'PA_LocOnHoldCannotPutaway';
  else
  /* Restrict the putaway if Location was OnHold and not allowed for Replenishments */
  if ((@vOrderType in ('RU' , 'RP')) and (coalesce(@vAllowedOperations, '') <> '') and (charindex('R', @vAllowedOperations) = 0))
    set @vMessageName = 'PA_LocOnHoldCannotReplenish';
  else
  if (@vToPalletId is not null) and
     (@vToPalletWH not in (select TargetValue
                           from dbo.fn_GetMappedValues('CIMS', @vLPNDestWarehouse,'CIMS', 'Warehouse', 'Putaway', @vBusinessUnit)))
    set @vMessageName = 'PA_ScannedPalletIsOfDifferentWH'
  else
  if ((@vPAQuantity <= 0) and (@vPAInnerPacks <= 0)) or (@vPAQuantity > @vLPNQuantity)
    set @vMessageName = 'InvalidQuantity';
  else
  if (charindex(@vLocationType, @vPALocationTypes) = 0)
    set @vMessageName = 'LocationTypeIsInvalid'
  else
  if ((@vPAType = 'LD') and (@vLocationType not in ('K'/* PickLane */)))
    set @vMessageName = 'PA_CanPALinesToPicklaneOnly';
  else
  /* putaway multi SKU LPN into Picklanes only */
  if (@vPAType = 'L') and (@vSKUCount > 1) and (@vLocationType not in ('K'/* PickLane */))
     set @vMessageName = 'PA_CanPALinesToPicklaneOnly';
  else
  if (@vLocationStatus in ('I' /* Inactive */))
    set @vMessageName = 'PALocationIsInactive'
  else
  /* if PA to Location, then validate Storage Type of Location */
  if (@vToPalletId is null) and (Left(@vStorageType,1) not in ('L' /* LPNs */, 'U'/*Units */, 'P' /* packages/Cases */))
    set @vMessageName = 'StorageTypeIsInvalid'
  else
  if (@vLPNDestWarehouse is null)
    set @vMessageName = 'PALPNNoDestWarehouse'
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
  /* When putting away into Reserve/Bulk locations only allow user into directed Location unless
     user has authorization */
  if (coalesce(@vDestLocation, @vScannedLocation) <> @vScannedLocation) and
     (@vLocationType not in ('S', 'D', 'K' /* Staging, Dock or Picklane */)) /* Always allow Staging/Dock, Picklane checked next */ and
     (dbo.fn_Permissions_IsAllowed(@vUserId, 'AllowPAToDiffLocation') not in ('1', '2')) -- Unless user has permission to override
    set @vMessageName = 'ScanLocIsNotSuggestedLocation'
  else
  /* We only allow user to putaway inventory into dynamic picklnes other than Primary picklane unless user has
     permissions to putaway inventory to another static picklane */
  if (@vDestLocation <> @vScannedLocation) and
     (coalesce(@vDestLocation, '') <> '') and
     (@vLocationSubType <> 'D' /* Dynamic */) and
     (@vLocationType = 'K' /* Picklane */) and
     (dbo.fn_Permissions_IsAllowed(@vUserId, 'AllowPAToDiffLocation') not in ('1', '2')) -- Unless user has permission to override
    set @vMessageName = 'ScanLocIsNotSuggestedLocation'
  else
  if (@vDestLocation <> @vScannedLocation) and
     (@vLocPutawayZone <> @vDestZone) and
     (dbo.fn_Controls_GetAsString('Putaway', 'RestrictSKUToPAZone', 'N', @vBusinessUnit, @vUserId) = 'Y') and
     (dbo.fn_Permissions_IsAllowed(@vUserId, 'AllowPAToDiffZone') not in ('1', '2')) and -- Unless user has permission to override
     (@vLocPutawayZone not in (select distinct(PutawayZone)
                               from PutawayRules
                               where SKUPutawayClass = @vPutawayClass))
    set @vMessageName = 'ScanLocIsNotInDestZone'
  else
  if ((charindex(@vPALPNType, @vStorageType) = 0) and
      (@vLocationType in ('R' /* Reserve */, 'B'/* Bulk */, 'K'/* PickLane */)))
    set @vMessageName = 'LPNAndStorageTypeMismatch'
  else
  /* if there is an Order Id on the LPN then it says that LPN was allocated against an Order/Replenish Order
     So we need to restrict user scanning other than suggested Location */
  if (@vLPNOrderId is not null) and (@vDestLocation <> @vScannedLocation) and
     (dbo.fn_IsInList(@vLocationSubType, @vAllowPAToDiffLoc) = 0)
    set @vMessageName = 'PA_AllocatedLPNCanOnlyPutawayToASuggestedLoc';
  else
  /* If user putaway quantity from a replenished picked LPN to other than dest location(dest location)
     then restrict user not to putaway more units than max qty of secondary location */
  if (@vLPNOrderId is not null) and (@vDestLocation <> @vScannedLocation) and
     (dbo.fn_IsInList(@vLocationSubType, @vAllowPAToDiffLoc) > 0) and
     (@vPAQuantity > @vInitialSecondaryLocPAQty)
    set @vMessageName = 'PA_QtyExceedsSecondaryLocMaxQty';
  else
  /* GNC specific rules:
     a. There can only be only one Full LPN in a Location
     b. Broken Cases can only be PA into Picklane Unit storage
  */
  if (@vLPNPutawayClass = '1' /* Full LPN */) and
     (@vScannedLocation <> @vDestLocation) and
     (@vLocationType not in ('S', 'D', 'C' /* Staging, Dock, Conv */)) and
     (@vLocationStatus <> 'E' /* Empty */)
    set @vMessageName = 'LocationAlreadyFull';
  else
  if (@vLPNPutawayClass = '5' /* Broken Case i.e. Less than Case Qty */) and
     (@vLocationType <> 'K' or @vStorageType <> 'U')
    set @vMessageName = 'PA_CanOnlyPAtoPicklane';
  else
  if ((@vAllowPAToUnassignedLoc <> 'Y' /* Yes */) or
      (dbo.fn_Permissions_IsAllowed(@vUserId, 'RFTransferInventoryToUnassignedLoc') <> '1')) and
     (@vLocationType = 'K' /* Picklane */) and
     /* Location does not have the SKU in it already */
     (not exists (select *
                  from LPNs
                  where (LocationId = @vScannedLocationId) and (SKUId = @vSKUId)))
    set @vMessageName = 'PA_LocationIsNotSetupForSKU';
  else
   select @vMessageName = dbo.fn_Putaway_ValidateWarehouse(@vLocWarehouse, @vLPNDestWarehouse, 'LPNPutaway', @vBusinessUnit);

 /* Other custom validations */
 if (@vMessageName is null)
   exec pr_RuleSets_Evaluate 'Putaway_Validations', @xmlRulesData, @vMessageName output;

  if (@vMessageName is not null)
     goto ErrorHandler;

  /* if it is LPN storage, then move the LPN into the Location
     - this updates the LPN Status and
     - generates and upload if necessary */

  if (@vToPalletId is null) and (Left(@vStorageType, 1) = 'L' /* LPNS */)    /* Non picklane */
    begin
      /* If moving into LPN storage location, clear Pallet as LPN cannot be on a pallet anymore */
      if (@vLPNPalletId is not null) and (Left(@vStorageType, 1) = 'L' /* LPNS */)
        exec pr_LPNs_SetPallet @vPALPNId, null /* PalletId */, @vUserId;

      exec @vReturnCode = pr_LPNs_Move @vPALPNId,
                                       null, /* PA LPN */
                                       @vLPNStatus,
                                       @vScannedLocationId,
                                       null, /* PA Location */
                                       @vBusinessUnit,
                                       @vUserId;

      /* If a replenish LPN has been putaway into Reserve/Bulk then clear everything related to Replenishments */
      if (@vOrderType in ('RU', 'RP', 'R' /* Replenish Units, Cases, Replenish Orders */)) and
         (@vLocationType in ('R', 'B' /* Reserve, Bulk */) and
         (@vLPNPutawayClass = 'RC' /* Replenish Case */) and
         (@vIsReplenishable = 'Y' /* Yes */))
        begin
          /* Update Replenish order's LPN Details OnhandStatus to Available */
          update LPNDetails
          set OnhandStatus           = 'A', /* Available */
              ReplenishOrderId       = OrderId,
              ReplenishOrderDetailId = OrderDetailId,
              OrderId                = null,
              OrderDetailId          = null
          where (LPNId = @vPALPNId);

          exec pr_LPNs_Recount @vPALPNId;
        end

      /* Audit Trail */
      exec pr_AuditTrail_Insert 'PutawayLPNToLocation', @vUserId, null /* ActivityTimestamp */,
                                @LPNId        = @vPALPNId,
                                @PalletId     = @vLPNPalletId,
                                @Quantity     = @vPAQuantity,
                                @ToLocationId = @vScannedLocationId,
                                @LocationId   = @vLPNLocationId;
    end
  else
  if (@vToPalletId is null) and (Left(@vStorageType, 1) in ('U' /* Units */, 'P' /* Packages/Cases */))   /* Picklane */
    begin
      /* Clear Pallet on  the LPN, if we are moving it into Picklane Location as
         we would transfer units and LPN gets Consumed */
      if (@vLPNPalletId is not null) and (@vLPNQuantity = @vPAQuantity)
        exec pr_LPNs_SetPallet @vPALPNId, null /* PalletId */, @vUserId;

      select @vDRQty = Quantity
      from vwLPNDetails
      where (LPN = @vScannedLocation) and (SKU = @vSKU) and (OnhandStatus = 'DR');

      exec @vReturnCode = pr_Putaway_LPNContentsToPicklane @vPALPNId,
                                                           @vSKUId,
                                                           @vPAInnerPacks,
                                                           @vPAQuantity,
                                                           @vScannedLocationId,
                                                           @vBusinessUnit,
                                                           @vUserId,
                                                           @vToLPNId output,
                                                           @vToLPNDetailId output;

      if (@vDRQty > 0)
        exec pr_AuditTrail_Insert 'PutawayDRQtyToPicklane', @vUserId, null /* ActivityTimestamp */, @BusinessUnit = @vBusinessUnit,
                                  @ToLPNId      = @vToLPNId,
                                  @SKUId        = @vSKUId,
                                  @Quantity     = @vDRQty,
                                  @ToLocationId = @vScannedLocationId;

      /* Audit Trail */

      /* Build activity message */
      if (@vOrderType in ('R', 'RU', 'RP'/* Replenish */)) and (@vDestLocationId <> @vScannedLocationId)
        begin
          select @vActivityType = 'PutawayLPNToAlternatePicklane';

          /* capture Dest location info, this informational as to keep track of where the directed quantity has been putaway,
             if user putaway to a location other than scanned Location */
          insert into @ttSuggLocations(EntityId, EntityKey)
            select @vDestLocationId, @vLPNDestLocation;
        end
      else
        select @vActivityType = 'PutawayLPNToPicklane';

      exec pr_AuditTrail_Insert @vActivityType, @vUserId, null /* ActivityTimestamp */,
                                @LPNId         = @vPALPNId,
                                @ToLPNId       = @vToLPNId,
                                @PalletId      = @vLPNPalletId,
                                @SKUId         = @vSKUId,
                                @InnerPacks    = @vPAInnerPacks,
                                @Quantity      = @vPAQuantity,
                                @OrderId       = @vLPNOrderId,
                                @ToLocationId  = @vScannedLocationId,
                                @LocationId    = @vLPNLocationId,
                                @Note1         = @vLPNDestLocation,
                                @AuditRecordId = @vAuditRecordId output;

      /* If user did putaway as Replenish LPN into other than suggested location then link AT for suggested location as well */
      exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'Location', @ttSuggLocations, @vBusinessUnit;
    end
  else
  /* If user scans Pallet instead of Location then we need add scanned LPN to the Pallet */
  if (@vToPalletId is not null)
    begin
      exec @vReturnCode = pr_LPNs_SetPallet @vPALPNId, @vToPalletId, @vUserId, 'Putaway' /* Operation */;

      /* Audit Trail */
      if (@vReturnCode = 0)
        exec pr_AuditTrail_Insert 'PutawayLPNAddedToPallet', @vUserId, null /* ActivityTimestamp */,
                                  @LPNId        = @vPALPNId,
                                  @PalletId     = @vLPNPalletId,
                                  @ToPalletId   = @vToPalletId,
                                  @SKUId        = @vSKUId,
                                  @InnerPacks   = @vPAInnerPacks,
                                  @Quantity     = @vPAQuantity,
                                  @ToLocationId = @vScannedLocationId;
    end

  if (@vReturnCode <> 0)
    goto ErrorHandler;

  /* get the minimum qty that needs to be putaway if we need to display it or validate based upon that */
  if (@vLocationType = 'K' /* Picklane */) and
     (@vDefaultQtyStr = 'MinQtyToPA')
    exec pr_Putaway_SuggestedQtyToPA @vPALPNId, @vDestLocationId, @vSKUId,
                                     @vPrimaryLocPAQty output, @vSecondaryLocPAQty output, @vMsgInfo output;

  /* get the LPN Qty after putaway */
  select @vLPNIPsAfterPA = InnerPacks,
         @vLPNQtyAfterPA = Quantity
  from LPNs
  where (LPNId = @vPALPNId);

  /* If user doing partial putaway then unallocate LPN based upon control variable */
  if (@vUnallocatePartialLPN = 'Y'/* Yes */)
    begin
      /* If the SKU ReplenishClass is Partial Case and user putaway only partial units and if primary location putaway quantity
         is zero or there is enough quantity in secondary location then unallocate remaining units,
         so that LPN can be moved to some other location */
      if (@vLocationType = 'K'/* Picklane */) and (@vOrderType in ('RU', 'RP', 'R' /* Replenish */)) and
         (@vPAQuantity < @vLPNQuantity) and ((@vPrimaryLocPAQty = 0) or ((@vPrimaryLocPAQty > 0) and (@vSecondaryLocPAQty = 0)))
        begin
          /* Update LPNs PickingClass of the LPN */
          update LPNs
          set PickingClass = 'OL' /* Open LPN */
          where LPNId = @vPALPNId;

          exec pr_LPNs_Unallocate @vPALPNId, default /* ttLPNs */, default/* UnallocPallet */, @vBusinessUnit, @vUserId;

          /* confirmation to display to user */
          select @vConfirmationMsg = dbo.fn_Messages_Build('PALPN_ReqUnitsHaveBeenPAAndRestUnitsUnallocated', @vPrimaryLocPAQty, @vLPNQtyAfterPA, null, null, null),
                 @vPromptScreen = 'MoveLPN' /* Redirect to Move LPN */;  -- Just display confirmation msg
        end
    end
  else
  /* if partial => return same info as validate pr returns to find another location
     if the last putaway was to unit storage, and if there are some more units in the Putaway LPN,
     then attempt to find the next putaway location for the lpn contents */
  if ((@vPAQuantity < @vLPNQuantity) or
      ((left(@vStorageType, 1) in ('U', 'P' /* Units, Package */)) and (@vLPNQtyAfterPA > 0)))
    begin
      if (@vLPNDestLocation is null)
        begin
          select @vSKU            = null,
                 @vSKUDescription = null,
                 @vSKUUoM         = null,
                 @vSKU4           = null;

          /* LPN is valid, now determine the DestZone and DestLocation */
          exec @vReturnCode = pr_Putaway_FindLocationForLPN @vPALPNId,
                                                            null, /* PASKUId */
                                                            @vPAType,
                                                            @vBusinessUnit,
                                                            @vUserId,
                                                            @vDeviceId,
                                                            @vDestZone           output,
                                                            @vDestLocation       output,
                                                            @vDestLocStorageType output,
                                                            @vPASKUId            output,
                                                            @vPAInnerPacks       output,
                                                            @vPAQuantity         output,
                                                            @vMessageName        output;

          /* Get SKU Details from vwSKU - SKU, Description, UoM */
          if (@vPASKUId is not null)
            select @vSKUId          = SKUId,
                   @vSKU            = SKU,
                   @vSKUDescription = Description,
                   @vSKUUoM         = UoM,
                   @vSKU4           = SKU4
            from vwSKUs
            where (SKUId = @vPASKUId);
        end
      else
        begin /* if it is replenish putaway then we have already destlocation defined on the LPN */
          select @vDestZone     = @vLPNDestZone,
                 @vDestLocation = @vLPNDestLocation;
                -- @vPAQuantity   = @vLPNQuantity - @vPAQuantity;
        end

      if (@vMessageName is not null)
        goto ErrorHandler;

      /* get the Dest Loc Type */
      select @vDestLocationType = LocationType
      from Locations
      where (Location     = @vDestLocation) and
            (BusinessUnit = @vBusinessUnit);

      if (@vDestLocationType = 'K'/* PickLane */) and (@vOrderType in ('RU', 'RP', 'R' /* Replenish */)) and
         (@vPrimaryLocPAQty > 0) and (@vPrimaryLocPAQty <> @vLPNQuantity)
        begin
          /* If MinToPA & LPNQty are different then it should be a partial putaway and
             display min qty that should be putaway to Location */
          select @vPartialPutaway  = 'Y' /* Yes */,
                 @vDisplayQty      = dbo.fn_Messages_Build('PAReplenishLPN_DisplayQty', @vPrimaryLocPAQty, @vLPNQtyAfterPA, @vSKUUoM, null, null),
                 @vConfirmationMsg = dbo.fn_Messages_Build('PALPN_MinUnitsToCompletePA', @vPrimaryLocPAQty, @vSecondaryLocPAQty, @vLPNQtyAfterPA, @vSKUUoM, null);
        end
      else
        begin
          select @vConfirmationMsg = dbo.fn_Messages_Build('PALPN_PartialPutaway', @vPAQuantity, @vSKUUoM, @vLPN, @vScannedLocation, null),
                 @vDisplayQty      = dbo.fn_Messages_Build('PALPN_DisplayQty', @vLPNQtyAfterPA, @vSKUUoM, null, null, null);
        end
    end
  else
    begin
      /* They would have completely Putaway LPN so display success message */
      select @vConfirmationMsg = dbo.fn_Messages_Build('PALPN_PutawayComplete', @vPAQuantity, @vSKUUoM, @vLPN, @vScannedLocation, null),
             @vPromptScreen  = 'PALPN' /* Redirect to Putaway LPN Screen */;  -- Just display confirmation msg
    end

  /* If replenish picked LPN is being putaway in other than suggested Location, then we need to check the minimum
     required quantity to be putaway, if there is a demand for replenishment quantity in suggested Location
     then we need to transfer directed/directed reserve quantities to scanned picklane from suggested Location */
  if (@vLocationType = 'K'/* Picklane */) and (@vOrderType in ('RU', 'RP', 'R' /* Replenish */)) and
     (@vDestLocation <> @vScannedLocation)
    begin
      select @vInputParamsXml = dbo.fn_XMLNode('Root',
                                  dbo.fn_XMLNode('DestLocationId',    @vDestLocationId) +
                                  dbo.fn_XMLNode('ScannedLocationId', @vScannedLocationId) +
                                  dbo.fn_XMLNode('SKUId',             @vSKUId) +
                                  dbo.fn_XMLNode('ReplenishOrderId',  @vLDOrderId) +
                                  dbo.fn_XMLNode('ReplenishOrderDetailId',
                                                                      @vLDOrderDetailId) +
                                  dbo.fn_XMLNode('Quantity',          @vPAQuantity) +
                                  dbo.fn_XMLNode('BusinessUnit',      @vBusinessUnit) +
                                  dbo.fn_XMLNode('UserId',            @vUserId));

      /* If actual quantity to be putaway is greater than zero that means user transferred replenish picked LPN to other than suggested location,
         invoke ExecuteInBackGround to transfer reserved quantities */
      exec pr_Entities_ExecuteInBackGround @Entity       = 'Location',
                                           @EntityId     = @vDestLocationId,
                                           @EntityKey    = @vDestLocation,
                                           @ProcessClass = 'TRQ'/* ProcessCode - Transfer Reserved Qty */,
                                           @ProcId       = @@ProcId,
                                           @Operation    = 'ReplenishLPNPutawayToDiffLoc'/* Operation */,
                                           @BusinessUnit = @vBusinessUnit,
                                           @InputParams  = @vInputParamsXml;
    end

  select @vDefaultQty = coalesce(@vPrimaryLocPAQty, @vLPNQtyAfterPA);

  /* Build response to RF */
  exec pr_Putaway_PALPNResponse @vPALPNId, @vSKUId, @vDestLocationId, @vDisplayQty, @vDefaultQty, @vPromptScreen, @vPartialPutaway,
                                @vMsgInfo, @vConfirmationMsg, @vBusinessUnit, @XMLResult output;

  /* Save Device State */
  /* Update Device Current Operation Details, etc.,. */
  exec pr_Device_Update @vDeviceId, @vUserId, 'ConfirmLPNPutaway', @XMLResult, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Log the Result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPALPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPALPNId, @ActivityLogId = @vActivityLogId output;

  exec @vReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_ConfirmPutawayLPN */

Go
