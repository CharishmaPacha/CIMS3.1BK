/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/19  RIA     pr_AMF_Inquiry_Location: Changes to build data based on control value (OB2-1767)
  2020/08/31  RIA     pr_AMF_Inquiry_Location: Changes to get different data tables (HA-527)
  2020/08/16  YJ      pr_AMF_Inquiry_Location: Made changes to call the v3 procedure instead of v2 (HA-527)
  2020/06/23  YJ      pr_AMF_Inquiry_Location: Changes to show SKUDescription & Label Code in one column (HA-527)
  2020/05/19  YJ      pr_AMF_Inquiry_Location: Added InventoryClass1 (HA-527)
  2020/05/18  RIA     pr_AMF_Inquiry_Location, pr_AMF_Inquiry_LPN: Used LPNs table instead of vwLPNs (HA-527)
  2020/05/15  YJ      pr_AMF_Inquiry_Location: Added InvClass1 (HA-527)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inquiry_Location') is not null
  drop Procedure pr_AMF_Inquiry_Location;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inquiry_Location: Processes the requests for Location Inquiry
    for Location Inquiry work flow.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inquiry_Location
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vMessage                  TMessage,
          @vxmlInput                 xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @Location                  TLocation,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vLocationType             TLocationType,
          @vLocDetails               TControlValue,
          @vIncludeLocDetails        TFlags,
          @vControlCategory          TCategory,
          @vxmlLocSKUDetails         xml,
          @vLocationInfoXML          TXML,
          @vLocationDetailsXML       TXML;
begin /* pr_AMF_Inquiry_Location */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read inputs from InputXML */
  select @vUserId       = Record.Col.value('(SessionInfo/UserName)[1]',     'TUserId'      ),
         @vDeviceId     = Record.Col.value('(SessionInfo/DeviceId)[1]',     'TDeviceId'    ),
         @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @Location      = Record.Col.value('(Data/Location)[1]',            'TLocation'    ),
         @vOperation    = Record.Col.value('(Data/Operation)[1]',           'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Fetch the Location to validate and LocationType for building the DataTable */
  select @vLocationId   = LocationId,
         @vLocation     = Location,
         @vLocationType = LocationType
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @Location, @vDeviceId, @vUserId, @vBusinessUnit));

  if (@vLocationId is null)
    set @vMessageName = 'InvalidLocation';

  /* This will raise an exception, and the caller ExecuteAction procedure would
     capture and return error to UI */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get the control value to build information to show LPNs list or Summary */
  select @vControlCategory = 'RFInquiry_Location_' + @vLocationType;
  select @vLocDetails      = dbo.fn_Controls_GetAsString(@vControlCategory, 'DetailLevel', 'SKU-Pallet', @vBusinessUnit, @vUserId);

  /* Get the location related info */
  exec pr_AMF_Info_GetLocationInfoXML @vLocationId, @vLocDetails, @vOperation,
                                      @vLocationInfoXML output, @vLocationDetailsXML output;

  select @DataXml = dbo.fn_XmlNode('Data', @vLocationInfoXML + coalesce(@vLocationDetailsXML, '') +
                                           dbo.fn_XMLNode('DetailLevel', @vLocDetails));

end /* pr_AMF_Inquiry_Location */

Go

