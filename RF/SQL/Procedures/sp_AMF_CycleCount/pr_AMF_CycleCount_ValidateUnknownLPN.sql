/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/16  RIA     pr_AMF_CycleCount_ValidateUnknownLPN: Changes to add InventoryClass to SKUDesc (HA-1994)
  2021/02/15  RIA     pr_AMF_CycleCount_ValidateUnknownLPN: Changes to clear data nodes that are not needed (HA-1984)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_CycleCount_ValidateUnknownLPN') is not null
  drop Procedure pr_AMF_CycleCount_ValidateUnknownLPN;
Go
/*----------------------------------------------------------------------------------
  Procedure pr_AMF_CycleCount_ValidateUnknownLPN:
    This procedure gets called if an LPN is scanned which is not associated with the Location
-----------------------------------------------------------------------------------*/
Create Procedure pr_AMF_CycleCount_ValidateUnknownLPN
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
          @vDeviceId                 TDeviceId;
          /* Functional variables */
  declare @vDeviceName               TName,
          @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vPallet                   TPallet,
          @vScannedLPN               TLPN,
          @vxmlData                  xml,
          @vTempXML                  TXML;
begin /* pr_AMF_CycleCount_ValidateUnknownLPN */

  /* Convert input into xml var */
  select @vxmlInput = convert(xml, @InputXML);

  /* Initialize */
  select @DataXML     = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML   = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML    = null,
         @InfoXML     = null;

  /* Read inputs from InputXML */
  select @vBusinessUnit   = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId         = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId       = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vLocation       = Record.Col.value('(Data/Location)[1]',                   'TLocation'    ),
         @vPallet         = Record.Col.value('(Data/Pallet)[1]',                     'TPallet'      ),
         @vScannedLPN     = Record.Col.value('(Data/LPN)[1]',                        'TLPN'         )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* For the new LPN scanned, remove the empty nodes taken from Data Table */
  set @vxmlInput.modify('delete /Root/Data/CCData/CCTable/*[not(node())]');
  set @vxmlInput.modify('delete /Root/Data/m_LPN');

  /* For the new LPN scanned, remove the LPN node */
  set @vxmlInput.modify('delete /Root/Data/CCData/CCTable[LPN = sql:variable("@vScannedLPN")]')

  /* Fetch the DataXML after above clean up */
  select @DataXML = convert(varchar(max), @vxmlInput.query('Root/Data'));

  /* set value for DeviceName to replace current data set to Devices table */
  select @vDeviceName = @vDeviceId + '@' + @vUserId;

  /* Get the LocationId from the scanned location */
  select @vLocationId = LocationId
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation(null, @vLocation, @vDeviceId, @vUserId, @vBusinessUnit));

  /* Input to validate Entity */
  select @vxmlRFCProcInput = convert(xml, dbo.fn_XMLNode('ValidateCCEntity',
                                              dbo.fn_XMLNode('Location',       @vLocation) +
                                              dbo.fn_XMLNode('ScannedEntity',  @vScannedLPN) +
                                              dbo.fn_XMLNode('LPN',            @vScannedLPN) +
                                              dbo.fn_XMLNode('Pallet',         @vPallet) +
                                              dbo.fn_XMLNode('ValidateOption', 'L' /* LPN */) +
                                              dbo.fn_XMLNode('BusinessUnit',   @vBusinessUnit) +
                                              dbo.fn_XMLNode('UserId',         @vUserId) +
                                              dbo.fn_XMLNode('DeviceId',       @vDeviceId)));

  /* Validate LPN */
  exec pr_RFC_CC_ValidateEntity @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  /* Evaluate the output for errors */
  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output, @ErrorXML output;

  /* If scanned LPN is invalid exit since error is captured under @ErrorXML */
  if (coalesce(@vTransactionFailed, 0) <> 0)
    begin
      /* Before we exit we would like to store the LPNs scanned so far since when this
         validation is invoked, there may be LPN scans done at the client end that
         were not saved anytime before */

      /* We will be deleting the previous LPN and CCData as this would result in
         issues when unknown scan LPN is not valid one */
      select @vxmlData = convert(xml, @DataXML);
      set @vxmlData.modify('delete /Data/LPN');
      set @vxmlData.modify('delete /Data/m_CCData');
      select @DataXML = convert(varchar(max), @vxmlData);

      update Devices
      set DataXML = @DataXML
      where (DeviceId = @vDeviceName);

      return @vTransactionFailed;
    end

  /* Include the new LPN details into the CC table to be shown on the RF Data Table */
  select @vTempXML = (select nullif(@vPallet, '')   as Pallet,
                             LPN                    as LPN,
                             SKU                    as SKU,
                             dbo.fn_AppendStrings(SKUDescription, ' / ', InventoryClass1)
                                                    as SKUDesc,
                             InnerPacks             as NewInnerPacks,
                             Quantity               as NewUnits
                      from vwLPNs
                      where (LPN = @vScannedLPN) and (BusinessUnit = @vBusinessUnit)
                      for XML path('CCTable'));

  /* XML handling based on whether this is the first scan or later */
  if (nullif(convert(varchar(max), @vxmlInput.query('Root/Data/CCData/*')), '') is null)
    begin
      /* If the first scan CCData would not have any data within it */
      select @DataXML = replace(@DataXML, '<CCData/>', '');
      select @DataXML = dbo.fn_XMLAddNode(@DataXML, 'Data', dbo.fn_XMLNode('CCData', @vTempXML));
    end
  else
    /* Save the modified DataXML */
    select @DataXML = dbo.fn_XMLAddNode(@DataXML, 'CCData', @vTempXML);

  /* Getting issue with quotes in SKU Description */
  select @DataXML = replace(@DataXML, '''', '');

  /* Clean up old CCData node */
  exec pr_XMLModifyNode @DataXML, '/Data/m_CCData', 'D' /* Delete */, default, @vTempXML output

  select @DataXML = coalesce(@vTempXML, @DataXML);

  /* Would raise an exception if the LPN failed validation above */
  return(coalesce(@vReturnCode, 0));
end /* pr_AMF_CycleCount_ValidateUnknownLPN */

Go

