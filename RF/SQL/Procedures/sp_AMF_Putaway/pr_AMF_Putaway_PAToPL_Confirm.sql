/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/10  RIA     pr_AMF_Putaway_PAToPL_Validate, pr_AMF_Putaway_PAToPL_Confirm, pr_AMF_Putaway_PAToPL_SkipSKU: CleanUp (OB2-1197)
  2020/05/06  RIA     pr_AMF_Putaway_PAToPL_Confirm: Changes to call pr_Putaway_LPNContentsToPicklane (HA-425)
  2020/01/27  RIA     pr_AMF_Putaway_PAToPL_Confirm: clean up (CIMSV3-656)
  2020/01/22  RIA     pr_AMF_Putaway_PAToPL_Confirm: Changes to log audit trail (CID-1264)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Putaway_PAToPL_Confirm') is not null
  drop Procedure pr_AMF_Putaway_PAToPL_Confirm;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Putaway_PAToPL_Confirm:

  Processes the requests for confirm pallet Putaway to picklane
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Putaway_PAToPL_Confirm
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vxmlInput                 xml,
          @vxmlOutput                xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vPalletId                 TRecordId,
          @vPallet                   TPallet,
          @vPALPN                    TLPN,
          @vPAScannedLocation        TLocation,
          @vPASKU                    TSKU,
          @vPAScannedSKU             TSKU,
          @vPAInnerPacks             TInnerPacks,
          @vPAQuantity               TQuantity,
          @vPutawaySequence          TControlValue,
          @vRFFormAction             TMessageName,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vxmlPalletDetails         xml,
          @vPalletInfoXML            TXML,
          @vPADetailsXML             TXML,
          @vPalletDetailsXML         TXML,
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vLPNDetailId              TRecordId,
          @vPALPNId                  TRecordId,
          @vPASKUId                  TRecordId,
          @vPASKUUnitsPerIP          TInteger,
          @vPAScannedLocationId      TRecordId,
          @vSKUId                    TRecordId,
          @vSKU                      TSKU,
          @vDestLocation             TLocation,
          @vAllowedOperations        TFlags,
          @vLPNLocation              TLocation,
          @vLPNStatus                TStatus,
          @vLPNType                  TTypeCode,
          @vLPNDestWarehouse         TWarehouse,
          @vLPNOrderId               TRecordId,
          @vLPNPalletId              TRecordId,
          @vToLPNDetailId            TRecordId,
          @vLPNLocationId            TRecordId,
          @vLocationType             TLocationType,
          @vStorageType              TLocationType,
          @vLocationStatus           Tstatus,
          @vValidPALPNStatus         TControlValue,
          @vOrderType                TTypeCode,
          @vValidReplenishLPNStatus  TControlValue,
          @vPALPNType                TTypeCode,
          @vToLPNId                  TRecordId,
          @vPALocationTypes          TControlValue,
          @vSKUUoM                   TUoM,
          @vActivityLogId            TRecordId,
          @vSuccessMessage           TMessage;
begin /* pr_AMF_Putaway_PAToPL_Confirm */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML       = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML     = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML      = null,
         @InfoXML       = null,
         @vPAInnerPacks = 0; -- V3 screens are not yet ready for IPs

  select @vBusinessUnit      = Record.Col.value('(SessionInfo/BusinessUnit)[1]',          'TBusinessUnit'),
         @vUserId            = Record.Col.value('(SessionInfo/UserName)[1]',              'TUserId'      ),
         @vDeviceId          = Record.Col.value('(SessionInfo/DeviceId)[1]',              'TDeviceId'    ),
         @vPallet            = Record.Col.value('(Data/m_PalletInfo_Pallet)[1]',          'TPallet'      ),
         @vPalletId          = Record.Col.value('(Data/m_PalletInfo_PalletId)[1]',        'TRecordId'    ),
         @vPALPN             = Record.Col.value('(Data/m_PADetails_LPN)[1]',              'TLPN'         ),
         @vPAScannedLocation = Record.Col.value('(Data/PALocation)[1]',                   'TLocation'    ),
         --@vPADestLocation    = Record.Col.value('(Data/m_PADetails_Location)[1]',         'TLocation'    ),
         @vPASKU             = Record.Col.value('(Data/m_PADetails_SKU)[1]',              'TSKU'         ),
         @vPAScannedSKU      = Record.Col.value('(Data/PASKU)[1]',                        'TSKU'         ),
         @vDeviceId          = Record.Col.value('(SessionInfo/DeviceId)[1]',              'TDeviceId'    ),
         @vRFFormAction      = Record.Col.value('(Data/RFFormAction)[1]',                 'TAction'      ),
         @vPutawaySequence   = Record.Col.value('(Data/m_PADetails_PutawaySequence)[1]',  'TControlValue'),
         @vPAQuantity        = Record.Col.value('(Data/PutawayUnits)[1]',                 'TQuantity'    )
  from @vxmlInput.nodes('/Root')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Fetch the LPN info */
  select @vPALPNId          = LPNId,
         @vLPNStatus        = Status,
         @vLPNPalletId      = nullif(PalletId, 0),
         @vLPNLocationId    = LocationId,
         @vLPNLocation      = Location,
         @vLPNOrderId       = OrderId,
         @vLPNDestWarehouse = DestWarehouse
  from LPNs
  where (LPN          = @vPALPN) and
        (BusinessUnit = @vBusinessUnit);

  /* If the LPN is a position on the Cart, then use the Pallet Type as
     LPN Type for Directed Putaway */
  if (@vLPNType = 'A' /* Cart */)
    select @vPALPNType = PalletType
    from Pallets
    where (PalletId = @vLPNPalletId);

  /* Get the SKU related info */
  select @vPASKUId         = S.SKUId,
         @vPASKUUnitsPerIP = S.UnitsPerInnerPack,
         @vSKUUoM          = S.UoM
  from SKUs S
    join LPNDetails LD on (LD.SKUId = S.SKUId)
    cross apply dbo.fn_SKUs_GetScannedSKUs(@vPAScannedSKU, @vBusinessUnit) SS
  where (S.SKUId = SS.SKUId) and
        (LD.LPNId = @vPALPNId);

  /* Get scanned Location related info */
  select @vPAScannedLocationId = LocationId,
         @vLocationStatus      = Status,
         @vLocationType        = LocationType,
         @vStorageType         = StorageType,
         @vAllowedOperations   = AllowedOperations
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @vPAScannedLocation,  @vDeviceId, @vUserId, @vBusinessUnit));

  /* Get Order Info */
  if (@vLPNOrderId is not null)
    select @vOrderType = OrderType
    from OrderHeaders
    where (OrderId = @vLPNOrderId);

  if (@vOrderType in ('RU' , 'RP', 'R' /* Replenish Orders */))
    select @vValidReplenishLPNStatus  = dbo.fn_Controls_GetAsString('ReplenishPutaway', 'ValidLPNStatus', 'K' /* Picked */,  @vBusinessUnit, @vUserId);
  else
    select @vValidPALPNStatus  = dbo.fn_Controls_GetAsString('Putaway', 'ValidLPNStatus', 'TNRP' /* InTransit/New/Received/Putaway */,  @vBusinessUnit, @vUserId);

  /* Get the control vars to determine if PA to a pick lane is allowed if it is not setup for the SKU */
  select @vPALocationTypes  = dbo.fn_Controls_GetAsString('Putaway', 'LocationTypes', 'RBKSI', @vBusinessUnit, @vUserId);

  /* Calculate the InnerPack quantity */
  select @vPAInnerPacks = case
                            when (@vPASKUUnitsPerIP > 0) then (@vPAQuantity / @vPASKUUnitsPerIP)
                            else 0
                          end;

  /* Validations */
  if (nullif(@vPALPN, '') is null)
    set @vMessageName = 'LPNIsRequired';
  else
  if (@vPALPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (@vLPNStatus = 'C' /* Consumed */)
    set @vMessageName = 'PA_LPNAlreadyPutaway';
  else
  if (charindex(@vLPNStatus, @vValidPALPNStatus) = 0) and /* Valid LPN statuses for Putaway */
      (@vOrderType not in ('RU', 'RP', 'R' /* Replenish Orders */))
    set @vMessageName = 'LPNPA_LPNStatusIsInvalid';
  else
  if ((@vOrderType in ('RU', 'RP', 'R' /* Replenish Orders */)) and
      (charindex(@vLPNStatus, @vValidReplenishLPNStatus) = 0))
    set @vMessageName = 'LPNPA_ReplenishLPNStatusIsInvalid';
  else
  if (@vLocationStatus in ('I' /* Inactive */))
    set @vMessageName = 'PALocationIsInactive'
  else
  if (charindex(@vLocationType, @vPALocationTypes) = 0)
    set @vMessageName = 'LocationTypeIsInvalid'
  else
  if ((charindex(@vPALPNType, @vStorageType) = 0) and
      (@vLocationType in ('R' /* Reserve */, 'B'/* Bulk */, 'K'/* PickLane */)))
    set @vMessageName = 'LPNAndStorageTypeMismatch'
  else
  if (@vLPNLocation is not null) and (@vLPNLocation = coalesce(@vPAScannedLocation, ''))
    set @vMessageName = 'LPNIsAlreadyInSameLocation';
  else
  /* Restrict the putaway if Location was OnHold and not allowed for Putaway */
  if ((@vOrderType not in ('RU' ,'RP')) and (coalesce(@vAllowedOperations, '') <> '') and
     (charindex('P' /* Putaway */, @vAllowedOperations) = 0))
    set @vMessageName = 'PA_LocOnHoldCannotPutaway';
  else
  /* Restrict the putaway if Location was OnHold and not allowed for Replenishments */
  if ((@vOrderType in ('RU' , 'RP')) and (coalesce(@vAllowedOperations, '') <> '') and
     (charindex('R' /* Replenish */, @vAllowedOperations) = 0))
    set @vMessageName = 'PA_LocOnHoldCannotReplenish';
  else
  if (@vLPNDestWarehouse is null)
    set @vMessageName = 'PALPNNoDestWarehouse'

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Call the V2 proc */
  exec pr_Putaway_LPNContentsToPicklane @vPALPNId,
                                        @vPASKUId,
                                        @vPAInnerPacks,
                                        @vPAQuantity,
                                        @vPAScannedLocationId,
                                        @vBusinessUnit,
                                        @vUserId,
                                        @vToLPNId output,
                                        @vToLPNDetailId output;

  select @vRFCProcInputxml = coalesce(convert(varchar(max), @vxmlRFCProcInput), '');

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'PutawayLPNToPicklane', @vUserId, null /* ActivityTimestamp */,
                            @LPNId        = @vPALPNId,
                            @ToLPNId      = @vToLPNId,
                            @PalletId     = @vLPNPalletId,
                            @SKUId        = @vPASKUId,
                            @InnerPacks   = @vPAInnerPacks,
                            @Quantity     = @vPAQuantity,
                            @ToLocationId = @vPAScannedLocationId,
                            @LocationId   = @vLPNLocationId;

  /* Success Message */
  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(dbo.fn_Messages_Build('PALPN_PutawayComplete', @vPAQuantity, @vSKUUoM, @vPALPN, @vPAScannedLocation, null));

  /* Get the putaway SKU info to show */
  exec pr_Putaway_PAtoPL_GetSKUToPutaway @vPalletId, @vDeviceId, @vUserId, @vRFFormAction, @vBusinessUnit, @vPADetailsXML output;

  select @vxmlPalletDetails = convert(xml, @vPADetailsXML); /* convert into xml */

  /* Pallet Details xml has the list of all SKUs, we need to suggest the first SKU to the user */
  select top 1 @vLPN = Record.Col.value('LPN[1]',         'TLPN'     )
  from @vxmlPalletDetails.nodes('/PALLETLPNDETAILS/LPNDetail') as Record(Col);

  /* If putaway has been complete, then there is not a next LPN to putaway */
  if (@vLPN is null)
    begin
      select @DataXML = (select 0 LPNId
                         for Xml Raw(''), elements, Root('Data'));
      return (0);
    end

  /* Get Pallet Info */
  exec pr_AMF_Info_GetPalletInfoXML @vPalletId, 'N' /* LPNDetails */, null, @vPalletInfoXML output, @vPalletDetailsXML output;

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', coalesce(convert(varchar(max), @vPalletInfoXML), '') + @vPalletDetailsXML + @vPADetailsXML);

end /* pr_AMF_Putaway_PAToPL_Confirm */

Go

