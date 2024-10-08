/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/24  RIA     pr_AMF_Putaway_ConfirmPutawayLPN, pr_AMF_Putaway_ValidatePutawayLPN: Variable declarations (CIMSV3-631)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Putaway_ConfirmPutawayLPN') is not null
  drop Procedure pr_AMF_Putaway_ConfirmPutawayLPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Putaway_ConfirmPutawayLPN:

  Processes the requests for confirm Putaway LPN
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Putaway_ConfirmPutawayLPN
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
          @vLPN                      TLPN,
          @vScannedLocation          TLocation,
          @vPAMode                   TFlags,
          @vNewQuantity              TQuantity,
          @vPrevQuantity             TQuantity,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLPNInfoXML               TXML,
          @vLPNId                    TRecordId,
          @vCurrentQty               TQuantity,
          @vLPNQuantity              TQuantity,
          @vLPNDisplayQty            TDescription,
          @vLPNDefaultQty            TQuantity,
          @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vCurrentLocation          TLocation,
          @vDestLocation             TLocation,
          @vLPNStatus                TStatus,
          @vLocationType             TLocationType,
          @vNewLocation              TLocation,
          @vRFFormAction             TMessageName,
          @vMessage                  TMessage,
          @vTaskId                   TRecordId,
          @vActivityLogId            TRecordId,
          @vSuccessMessage           TMessage;
begin /* pr_AMF_Putaway_ConfirmPutawayLPN */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Build the input for V2 procedure */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(Data/m_LPNInfo_LPN)[1]',              'TLPN'         ) as LPN,
                                     Record.Col.value('(Data/m_LPNInfo_SKU)[1]',              'TSKU'         ) as SKU,
                                     Record.Col.value('(Data/m_DestZone)[1]',                 'TZone'        ) as DestZone,
                                     Record.Col.value('(Data/m_DestLocation)[1]',             'TLocation'    ) as DestLocation,
                                     Record.Col.value('(Data/ScannedLocation)[1]',            'TLocation'    ) as ScannedLocation,
                                     Record.Col.value('(Data/NewQuantity)[1]',                'TQuantity'    ) as PAQuantity
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('CONFIRMPUTAWAYLPN'), elements);

  select @vRFCProcInputxml = coalesce(convert(varchar(max), @vxmlRFCProcInput), '');

  select @vBusinessUnit     = Record.Col.value('(SessionInfo/BusinessUnit)[1]',     'TBusinessUnit'),
         @vDeviceId         = Record.Col.value('(SessionInfo/DeviceId)[1]',         'TDeviceId'    ),
         @vUserId           = Record.Col.value('(SessionInfo/UserName)[1]',         'TUserId'      ),
         @vLPN              = Record.Col.value('(Data/m_LPNInfo_LPN)[1]',           'TLPN'         ),
         @vScannedLocation  = Record.Col.value('(Data/ScannedLocation)[1]',         'TLocation'    ),
         @vNewQuantity      = Record.Col.value('(Data/NewQuantity)[1]',             'TQuantity'    ),
         @vPrevQuantity     = Record.Col.value('(Data/m_Quantity)[1]',              'TQuantity'    ),
         @vPAMode           = Record.Col.value('(Data/m_PutawayMode)[1]',           'TFlags'       )
  from @vxmlInput.nodes('/Root')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get the Location Type */
  select @vLocationId   = LocationId,
         @vLocation     = Location,
         @vLocationType = LocationType
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @vScannedLocation, @vDeviceId, @vUserId, @vBusinessUnit));

  /* Should not allow user to PA partial units to Reserve */
  if ((@vLocationType <> 'K') and (@vPAMode = 'U') and (@vNewQuantity <> @vPrevQuantity))
    set @vMessageName = 'AMF_CannotPAPartialUnitsToNonPicklane';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to RF */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Call the V2 proc and get the info */
  exec pr_RFC_ConfirmPutawayLPN @vRFCProcInputxml, @vRFCProcOutputxml output;

  -- V2 Proc raises an error on exception, so if we are here, the operation was successful

  select @vxmlRFCProcOutput = cast(@vRFCProcOutputxml as xml);

  /* Get the info to check whether the operation was success or not */
  select @vSuccessMessage  = Record.Col.value('(MESSAGE/ConfirmationMsg)[1]',     'TMessage'    ),
         @vLPNQuantity     = Record.Col.value('(LPNINFO/Quantity)[1]',            'TQuantity'   ),
         @vLPNDisplayQty   = Record.Col.value('(LPNINFO/DisplayQty)[1]',          'TDescription'),
         @vLPNDefaultQty   = Record.Col.value('(LPNINFO/DefaultQty)[1]',          'TQuantity'   ),
         @vDestLocation    = Record.Col.value('(LPNINFO/DestLocation)[1]',        'TLocation'   )
  from @vxmlRFCProcOutput.nodes('/PUTAWAYLPNDETAILS')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlRFCProcOutput = null));

  /* Get the LPNId */
  select @vLPNId            = LPNId,
         @vLPN              = LPN,
         @vCurrentLocation  = Location,
         @vLPNStatus        = Status,
         @vCurrentQty       = Quantity
  from  vwLPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@vLPN, @vBusinessUnit, 'LTU'));

  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vSuccessMessage);

  /* Evaluate to see if we are done with Putaway, if so, do not return the LPNId anymore
     so that the screen is preseented with no info for the next LPN, else send the LPN Info */
  if (@vCurrentQty > 0 and @vLPNStatus <> 'C') and (@vLocationType = 'K')
    begin
      exec pr_AMF_Info_GetLPNInfoXML @vLPNId, @LPNInfoXML = @vLPNInfoXML output;

      /* Read the values from V2 to show */
      select @DataXML = '';
      with ResponseDetails as
      (
        select dbo.fn_XMLNode('' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
        from @vxmlRFCProcOutput.nodes('/PUTAWAYLPNDETAILS/LPNINFO/*') as t(c)
        union
        select dbo.fn_XMLNode('' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
        from @vxmlRFCProcOutput.nodes('/PUTAWAYLPNDETAILS/OPTIONS/*') as t(c)
        union
        select dbo.fn_XMLNode('' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
        from @vxmlRFCProcOutput.nodes('/PUTAWAYLPNDETAILS/MESSAGE/*') as t(c)
      )
      select @DataXML = @DataXML + ResponseDetail from ResponseDetails;

      /* Add the additional LPN Info - to be used to display info that is not being returned by V2 proc */
      select @DataXml = dbo.fn_XmlNode('Data', @DataXML + coalesce(@vLPNInfoXML, ''));
    end
  else
    select @DataXML = (select 0 LPNId for Xml Raw(''), elements, Root('Data'));
end /* pr_AMF_Putaway_ConfirmPutawayLPN */

Go

