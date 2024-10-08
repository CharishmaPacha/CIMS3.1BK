/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/11/27  RIA     pr_AMF_Putaway_PAByLoc_ConfirmLPN: Added validations (CIMSV3-647)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Putaway_PAByLoc_ConfirmLPN') is not null
  drop Procedure pr_AMF_Putaway_PAByLoc_ConfirmLPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Putaway_PAByLoc_ConfirmLPN: Validates for picklane locations
   and calls the V2 proc to putaway the LPN
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Putaway_PAByLoc_ConfirmLPN
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
          @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vScannedLPN               TLPN,
          @vLocationType             TLocationType,
          @vAllowMultipleSKUs        TFlag,
          @vScannedLPNs              TCount,
          @vRFFormAction             TMessageName,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLocationInfoXML          TXML,
          @vLocationDetailsXML       TXML,
          @vLPNId                    TRecordId,
          @vLPNSKUId                 TRecordId,
          @vLPNType                  TTypeCode,
          @vReservedQty              TQuantity,
          @vLPNLocation              TLocation,
          @vLPNNumLines              TCount,
          @vSKU                      TSKU,
          @vPAQuantity               TQuantity,
          @vActivityLogId            TRecordId,
          @vSuccessMessage           TMessage;
begin /* pr_AMF_Putaway_PAByLoc_ConfirmLPN */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read the inputs */
  select @vBusinessUnit       = Record.Col.value('(SessionInfo/BusinessUnit)[1]',              'TBusinessUnit'),
         @vUserId             = Record.Col.value('(SessionInfo/UserName)[1]',                  'TUserId'      ),
         @vDeviceId           = Record.Col.value('(SessionInfo/DeviceId)[1]',                  'TDeviceId'    ),
         @vLocation           = Record.Col.value('(Data/m_LocationInfo_Location)[1]',          'TLocation'    ),
         @vScannedLPN         = Record.Col.value('(Data/LPN)[1]',                              'TLPN'         ),
         @vLocationId         = Record.Col.value('(Data/m_LocationInfo_LocationId)[1]',        'TRecordId'    ),
         @vLocationType       = Record.Col.value('(Data/m_LocationInfo_LocationType)[1]',      'TLocationType'),
         @vAllowMultipleSKUs  = Record.Col.value('(Data/m_LocationInfo_AllowMultipleSKUs)[1]', 'TFlag'        ),
         @vRFFormAction       = Record.Col.value('(Data/RFFormAction)[1]',                     'TMessageName' ),
         @vOperation          = Record.Col.value('(Data/Operation)[1]',                        'TOperation'   ),
         @vScannedLPNs        = Record.Col.value('(Data/ScannedLPNs)[1]',                      'TCount'       )
  from @vxmlInput.nodes('/Root')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* If user chose to complete PA, then quit */
  if (@vRFFormAction = 'Completed')
    begin
      select @InfoXML = dbo.fn_AMF_BuildSuccessXML('AMF_PAByLoc_Done');
      select @DataXML = (select 0 LocationId for Xml Raw(''), elements, Root('Data'));
      return;
    end

  /* Get the info of the scanned LPN */
  select @vLPNId       = LPNId,
         @vLPNType     = LPNType,
         @vLPNLocation = Location,
         @vLPNNumLines = NumLines,
         @vLPNSKUId    = SKUId,
         @vPAQuantity  = Quantity,
         @vReservedQty = ReservedQty
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@vScannedLPN, @vBusinessUnit, 'LTU'));

  /* Fetch SKU */
  if (@vLPNSKUId is not null)
    select @vSKU = SKU
    from SKUs
    where SKUId = @vLPNSKUId;

  /* Validations */
  if (@vLPNLocation is not null) and (@vLPNLocation = coalesce(@vLocation, ''))
    set @vMessageName = 'LPNIsAlreadyInSameLocation';
  else
  if (@vLPNType =  'L' /* Logical LPN */)
    set @vMessageName = 'LPNTypeCannotbePickLane';
  else
  if (@vLocationType = 'K' /* Picklane */) and (@vLPNNumLines > 1) and (@vAllowMultipleSKUs = 'N')
    set @vMessageName = 'LocationDoesNotAllowMultipleSKUs';
  else
  if (@vLocationType = 'K' /* Picklane */) and (@vLPNNumLines > 1) and (@vAllowMultipleSKUs = 'Y')
    set @vMessageName = 'AMF_PAByLoc_CannotPAMultiSKULPNToPL';
  else
  if (@vReservedQty > 0) and (@vLocationType not in ('R', 'B', 'K' /* Pickable Locations */))
    set @vMessageName = 'AMF_PAByLoc_ReservedLPNNonPickableLoc';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to RF */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

   /* Build the input for V2 procedure */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(Data/LPN)[1]',                        'TLPN'         ) as LPN,
                                     @vSKU                                                                     as SKU,
                                     @vPAQuantity                                                              as PAQuantity,
                                     Record.Col.value('(Data/m_LocationInfo_Location)[1]',    'TLocation'    ) as ScannedLocation
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('CONFIRMPUTAWAYLPN'), elements);

  select @vRFCProcInputxml = convert(varchar(max), @vxmlRFCProcInput);

 /* Call the V2 proc and get the info */
  exec pr_RFC_ConfirmPutawayLPN @vRFCProcInputxml, @vRFCProcOutputxml output;

  -- V2 Proc raises an error on exception, so if we are here, the operation was successful

  select @vxmlRFCProcOutput = convert(xml, @vRFCProcOutputxml),
         @vScannedLPNs      = coalesce(@vScannedLPNs, 0) + 1; -- increment as we have just now added one

  /* Get the info to check whether the operation was success or not */
  select @vSuccessMessage = Record.Col.value('(MESSAGE/ConfirmationMsg)[1]',     'TMessage')
  from @vxmlRFCProcOutput.nodes('/PUTAWAYLPNDETAILS')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlRFCProcOutput = null));

  /* Build success message */
  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vSuccessMessage);

  /* Call Get Location info XML proc to get the location information */
  exec pr_AMF_Info_GetLocationInfoXML @vLocationId, null /* Location Details */, @vOperation,
                                      @vLocationInfoXML output, @vLocationDetailsXML output;

  /* Build the Location Info */
  select @DataXml = dbo.fn_XmlNode('Data', coalesce(@vLocationInfoXML, '') +
                                           coalesce(@vLocationDetailsXML, '') +
                                           dbo.fn_XMLNode('ScannedLPNs', @vScannedLPNs));
end /* pr_AMF_Putaway_PAByLoc_ConfirmLPN */

Go

