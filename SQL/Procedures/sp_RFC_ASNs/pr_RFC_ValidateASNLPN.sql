/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/10  RIA     pr_RFC_ValidateASNLPN:Used ReceiptDetails instead of vwReceiptDetails (JL-283)
  2020/10/27  RIA     pr_RFC_ValidateASNLPN: Changes to get suggested Location (JL-211)
  2019/03/11  AY      pr_RFC_ValidateASNLPN: Changes to show existing pallet of Intransit LPNs (CIMSV3-743)
  2019/06/18  VS      pr_RFC_ValidateASNLPN: Made changes to show Zone as well for the suggested pallet (CID-584)
  2019/06/07  RT      pr_RFC_ValidateASNLPN: Validate whther the Receipt is ready to Receive or not (CID-510)
  2014/04/11  PV      pr_RFC_ValidateASNLPN: Issue fix with AllowMultiSKUPallet is set to 'N' and receiving
                        Pallet is not scanned.
  2014/04/05  PV      pr_RFC_ValidateASNLPN, pr_RFC_ReceiveASNLPN:
                        Enhanced for multiple sku lpns.
  2014/03/20  PKS     pr_RFC_ReceiveASNLPN pr_RFC_ValidateASNLPN: Made changes in XML Structure and
  2014/03/18  PKS     pr_RFC_ValidateASNLPN: CustPO, Location and Pallet added to Input XML for validation purpose.
                      ResultXML splits into header and detail nodes.
  2014/03/14  PKS     pr_RFC_ValidateASNLPN, pr_RFC_ReceiveASNLPN: Signatures changed, such that these two procedures will
                      have two XML parameters as Input and output.
  2011/02/17  PK      pr_RFC_ValidateASNLPN : Validating Status,
                       ReceiptId exists for the given LPN.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ValidateASNLPN') is not null
  drop Procedure pr_RFC_ValidateASNLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ValidateASNLPN: This is the second step of the ASN Receiving process,
   the first being the user identifies the ASN being received and the Pallet/Location
   the LPNs are being received to.

   The ReceiveToLocation and ReceivedToPallet are the Pallet and Location that are
   being used and both are optional i.e. users do not have to predecide the Pallet
   and Location and instead determine them after the LPNs are scanned.

  Input XML
  <ValidateASNLPNInput>
    <LPNId>3</LPNId>
    <LPN>C0000123</LPN>
    <ReceiverNumber>R01</ReceiverNumber>
    <ReceiptId>123</ReceiptId>
    <ReceiptNumber>R001</ReceiptNumber>
    <CustPO></CustPO>
    <Location></Location>
    <Pallet></Pallet>
    <BusinessUnit>CIMS</BusinessUnit>
    <UserId>rfcadmin</UserId>
  </ValidateASNLPNInput>

  output XML
  <ValidateASNLPNResult>
    <Header>
      <LPNId>11<LPNId>
      <LPN>C0000123</LPN>
      <ReceiverNumber>R001</ReceiverNumber>
      <ReceiptNumber>RH001</ReceiptNumber>
      <DefaultQty>10</DefaultQty>
      <QtyEnabled>Y</QtyEnabled>
      <AllowMultiSKULPN>Y</AllowMultiSKULPN>
      <ConfirmQtyRequired>Y</ConfirmQtyRequired>
      <ConfirmSKURequired>Y</ConfirmSKURequired>
    </Header>
    <Details>
      <Detail>
        <SKU>2008-09-85228-99-S-S</SKU>
        <SKU1>2008-09</SKU1>
        <SKU2>85228</SKU2>
        <SKU3>99</SKU3>
        <SKU4>S</SKU4>
        <SKU5>S</SKU5>
        <InnerPacks>20</InnerPacks>
        <Quantity>8</Quantity>
        <UoM>Ea</UoM>
      </Detail>
    </Details>
<ValidateASNLPNResult>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ValidateASNLPN
  (@xmlInput   xml,
   @xmlResult  xml output)
as
  declare @vLPNId                 TRecordId,
          @vLPN                   TLPN,
          @vLPNStatus             TStatus,
          @vLPNSKUId              TRecordId,
          @vLPNReceiverNumber     TReceiverNumber,
          @vLPNReceiptId          TRecordId,
          @vLPNDestZone           TTypeCode,
          @vReceiptId             TRecordId,
          @vReceiptDetailId       TRecordId,
          @vReceiptNumber         TReceiptNumber,
          @vCustPO                TCustPO,
          @vReceiveToLocation     TLocation,
          @vLocationId            TRecordId,
          @vLocationType          TTypeCode,
          @vLocWarehouse          TWarehouse,
          @vReceiveToPallet       TPallet,
          @vPalletId              TRecordId,
          @vPalletStatus          TStatus,
          @vPalletLocationId      TRecordId,
          @vPalletSKUId           TRecordId,
          @vPalletDestZone        TTypeCode,
          @vReceiptType           TTypeCode,
          @vControlCategory       TCategory,
          @vDefaultQty            TQuantity,
          @vQtyEnabled            TControlValue,
          @vAllowMultiSKULPN      TControlValue,
          @vConfirmQtyRequired    TFlag,
          @vConfirmSKURequired    TFlag,
          @vAllowMultiSKUPallet   TControlValue,
          @vIsCustPORequired      TControlValue,
          @vIsLocationRequired    TFlag,
          @vPrepareRecvFlag       TFlag,
          @vIsPalletizationRequired
                                  TControlValue,
          @vValidatePalletLPNDestZone
                                  TControlValue,
          @vReceiverNumber        TReceiverNumber,
          @vSuggestedPalletId     TRecordId,
          @vSuggestedPallet       TPallet,
          @vReceivingLocation     TLocation,
          @vSuggestionDisplay     TDescription,
          @vHeaderXML             TXML,
          @vDetailXML             xml,
          @vBusinessUnit          TBusinessUnit,
          @vUserId                TUserId,
          @vLPNQty                TQuantity,
          @vLPNReceivedQty        TQuantity,
          @vActivityLogId         TRecordId,

          @ReturnCode             TInteger,
          @MessageName            TMessageName,
          @Message                TDescription;
begin
begin try
  SET NOCOUNT ON;

  select @vLPNId             = nullif(Record.Col.value('LPNId[1]',          'TRecordId'), ''),
         @vLPN               = nullif(Record.Col.value('LPN[1]',            'TLPN'), ''),
         @vReceiverNumber    = nullif(Record.Col.value('ReceiverNumber[1]', 'TReceiverNumber'), ''),
         @vReceiptId         = nullif(Record.Col.value('ReceiptId[1]',      'TRecordId'), ''),
         @vReceiptNumber     = nullif(Record.Col.value('ReceiptNumber[1]',  'TReceiptNumber'), ''),
         @vCustPO            = nullif(Record.Col.value('CustPO[1]',         'TCustPO'),''),
         @vReceiveToLocation = nullif(Record.Col.value('Location[1]',       'TLocation'), ''),
         @vReceiveToPallet   = nullif(Record.Col.value('Pallet[1]',         'TPallet'),''),
         @vBusinessUnit      = nullif(Record.Col.value('BusinessUnit[1]',   'TBusinessUnit'), ''),
         @vUserId            = nullif(Record.Col.value('UserId[1]',         'TUserId'), '')
  from @xmlInput.nodes('/ValidateASNLPNInput') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, null /* DeviceId */,
                      @vLPNId, @vLPN, 'LPN',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get LPN Info. If an Intransit LPN is pre-palletized, then suggest the same pallet */
  select @vLPNId             = LPNId,
         @vLPN               = LPN,
         @vLPNStatus         = Status,
         @vLPNReceiverNumber = ReceiverNumber,
         @vLPNReceiptId      = ReceiptId,
         @vLPNSKUId          = SKUId,
         @vLPNQty            = Quantity,
         @vLPNDestZone       = DestZone,
         @vSuggestedPalletId = case when Status in ('T', 'R') then PalletId else null end,
         @vSuggestedPallet   = case when Status in ('T', 'R') then Pallet else null end
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@vLPN, @vBusinessUnit, 'LA' /* Options */));

  select @vLPNReceivedQty = sum(ReceivedUnits)
  from LPNDetails
  where ((LPNId        = @vLPNId) and
         (BusinessUnit = @vBusinessUnit));

  select @vReceiptId       = ReceiptId,
         @vPrepareRecvFlag = PrepareRecvFlag
  from ReceiptHeaders
  where (ReceiptNumber = @vReceiptNumber) and
        (ReceiptType   = 'A' /* ASN */) and
        (BusinessUnit  = @vBusinessUnit);

  select @vReceiptType = ReceiptType
  from ReceiptHeaders
  where (ReceiptId = @vLPNReceiptId);

    /* If CustPO is given, then get the details of CustPO to validate */
  if (@vCustPO is not null)
    select @vReceiptDetailId = Min(ReceiptDetailId),
           @vCustPO          = Min(CustPO)
    from ReceiptDetails
    where (ReceiptId = @vLPNReceiptId) and
          (CustPO    = @vCustPO);

  if (@vReceiveToLocation is not null)
    select @vLocationId   = LocationId,
           @vLocationType = LocationType,
           @vLocWarehouse = Warehouse
    from Locations
    where (Location = @vReceiveToLocation) and (BusinessUnit = @vBusinessUnit);

  if (@vReceiveToPallet is not null)
    select @vPalletId         = PalletId,
           @vPalletStatus     = Status,
           @vPalletLocationId = LocationId,
           @vPalletSKUId      = SKUId,
           @vPalletDestZone   = DestZone
    from Pallets
    where (Pallet = @vReceiveToPallet) and (BusinessUnit = @vBusinessUnit);

   /* set the control category based on the control type */
  select @vControlCategory = 'Receiving_' + @vReceiptType;

  /* if ConsiderExtraQty = N then we only show lines with QtyToReceive > 0  followed by QtyToReceive = 0 lines.
     if ConsiderExtraQty = Y then we show lines where MaxQtyAllowedToReceive > 0 */
  select @vDefaultQty                = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'DefaultQty',         '1', @vBusinessUnit, @vUserId),
         @vQtyEnabled                = dbo.fn_Controls_GetAsString(@vControlCategory,  'QtyEnabled',         'Y', @vBusinessUnit, @vUserId),
         @vAllowMultiSKULPN          = dbo.fn_Controls_GetAsString(@vControlCategory,  'AllowMultiSKULPN',   'Y', @vBusinessUnit, @vUserId),
         @vAllowMultiSKUPallet       = dbo.fn_Controls_GetAsString(@vControlCategory,  'AllowMultiSKUPallet','Y', @vBusinessUnit, @vUserId),
         @vConfirmQtyRequired        = dbo.fn_Controls_GetAsBoolean(@vControlCategory, 'ConfirmQtyRequired', 'Y', @vBusinessUnit, @vUserId),
         @vConfirmSKURequired        = dbo.fn_Controls_GetAsBoolean(@vControlCategory, 'ConfirmSKURequired', 'Y', @vBusinessUnit, @vUserId),
         @vIsCustPORequired          = dbo.fn_Controls_GetAsString (@vControlCategory, 'IsCustPORequired',   'O', @vBusinessUnit, @vUserId),
         @vIsLocationRequired        = dbo.fn_Controls_GetAsBoolean(@vControlCategory, 'IsLocationRequired', 'N', @vBusinessUnit, @vUserId),
         @vIsPalletizationRequired   = dbo.fn_Controls_GetAsString(@vControlCategory, 'IsPalletizationRequired', 'Y', @vBusinessUnit, @vUserId),
         @vValidatePalletLPNDestZone = dbo.fn_Controls_GetAsString(@vControlCategory, 'ValidatePalletLPNDestZone', 'N', @vBusinessUnit, @vUserId);

  if (@vLPNId is null)
    set @MessageName = 'LPNDoesNotExist';
  else
  if (@vReceiptId is null)
    set @MessageName = 'ReceiptDoesNotExist';
  else
  /* Validate whether the receipt is ready to Receive or not */
  if (@vPrepareRecvFlag = 'N')
    set @MessageName = 'ReceiptIsNotPrepared';
  else
  if (@vLPNReceiptId <> @vReceiptId)
    set @MessageName = 'LPNNotAssociatedWithASN';
  else
  if (@vLPNReceiverNumber is not null) and (@vLPNReceiverNumber <> @vReceiverNumber)
    set @MessageName = 'LPNAlreadyOnAnotherReceiver';
  else
  if ((@vLPNStatus <> 'T'/* In Transit */) and
     ((@vLPNStatus = 'R' /* Received */) and (@vLPNQty = @vLPNReceivedQty)))
    set @MessageName = 'ASNCaseStatusIsInvalid';
  else
    /* Get info about if there are multiple CustPOs in the shipment with the same SKU*/
  if ((@vCustPO is null) and (@vIsCustPORequired = 'R'/* Always Required */))
    set @MessageName = 'CustPOIsRequired';
  else
  if ((@vCustPO is not null) and (@vReceiptDetailId is null))
    set @MessageName = 'RODoesNothaveCustPO';
  else
  if (((@vReceiveToPallet is not null) and (@vAllowMultiSKUPallet = 'N' /* No */)) and
      ((exists (select LPNId
                from LPNDetails
                where (LPNId = @vLPNId)
                group by LPNId
                having count(LPNId) > 1)) or ((@vPalletStatus <> 'E' /* Empty */) and (@vLPNSKUId <> coalesce(@vPalletSKUId, '')))))
    set @MessageName = 'LPNSetPallet_NoMultipleSKUs';
  else
  if (@vReceiveToPallet is not null) and (@vPalletId is null)
    set @MessageName = 'InvalidPallet';
  else
  /* If Pallet has Destzone and LPN has different destzone then restrict to receive that ASN Case */
  if (@vValidatePalletLPNDestZone = 'Y') and
     (coalesce(@vPalletDestZone, '') <> '') and (coalesce(@vPalletDestZone, '') <> coalesce(@vLPNDestZone, ''))
    set @MessageName = 'ReceiveLPN_DestZoneIsDifferent';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* If Palletization is required and Pallet is scanned then we do not need to palletize the LPN again */
  if (@vIsPalletizationRequired = 'Y') and (@vReceiveToPallet is not null)
    select @vIsPalletizationRequired = 'N';

  /* If user has not scanned Pallet earlier, then suggest one to palletize.
     Suggest a Pallet that is going to the DestZone where LPN should be going */
  if (@vReceiveToPallet is null) and (@vSuggestedPallet is null)
    select @vSuggestedPalletId = PalletId,
           @vSuggestedPallet   = Pallet
    from Pallets
    where (LocationId = @vLocationId) and
          (DestZone   = @vLPNDestZone);

  select @vSuggestedPallet = coalesce(@vSuggestedPallet, 'New Pallet');

  /* If suggesting a Pallet, then give the Location of that pallet, else give the ReceiveToLocation */
  if (@vSuggestedPalletId is not null)
    select @vReceivingLocation = Location
    from Locations
    where LocationId = (select LocationId from Pallets where (PalletId = @vSuggestedPalletId));

  select @vReceivingLocation = coalesce(@vReceivingLocation, @vReceiveToLocation);

  /* Added Zone as well for suggested Pallet */
  select @vSuggestionDisplay = @vSuggestedPallet + coalesce(' (' + @vLPNDestZone + ')', '');

  /* The return dataset is used for RF to show Receipt details */
  set @vHeaderXML = (select LPN,
                            ReceiverNumber,
                            ReceiptNumber,
                            SKU,
                            Quantity,
                            @vDefaultQty              as DefaultQty,
                            @vQtyEnabled              as QtyEnabled,
                            @vAllowMultiSKULPN        as AllowMultiSKULPN,
                            @vConfirmQtyRequired      as ConfirmQtyRequired,
                            @vConfirmSKURequired      as ConfirmSKURequired,
                            @vIsPalletizationRequired as IsPalletizationRequired,
                            @vSuggestedPallet         as SuggestedPallet,
                            @vReceivingLocation       as ReceivingLocation,
                            @vSuggestionDisplay       as SuggestionDisplay
                      from vwLPNs
                      where (LPNId = @vLPNId)
                      for XML raw('Header'), elements);

  set @vDetailXML =  (select coalesce(SKU,'')             as SKU,
                             coalesce(SKU1,'')            as SKU1,
                             coalesce(SKU2,'')            as SKU2,
                             coalesce(SKU3,'')            as SKU3,
                             coalesce(SKU4,'')            as SKU4,
                             coalesce(SKU5,'')            as SKU5,
                             coalesce(SKUDescription, '') as SKUDescription,
                             coalesce(UPC,'')             as UPC,
                             coalesce(InnerPacks,0)       as InnerPacks,
                             coalesce(Quantity,0)         as Quantity,
                             coalesce(UOM,'')             as UoM
                      from vwLPNDetails
                      where (LPNId = @vLPNId) and (Quantity > 0)
                      for XML raw('Detail'), type, elements, root('Details'));

  set @XMLResult = dbo.fn_XMLNode('ValidateASNLPNResult', coalesce(@vHeaderXML, '') +
                                                          coalesce(convert(varchar(max), @vDetailXML), ''));

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  select @MessageName = ERROR_MESSAGE(),
         @ReturnCode  = 1;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;
end catch;

  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_ValidateASNLPN */

Go
