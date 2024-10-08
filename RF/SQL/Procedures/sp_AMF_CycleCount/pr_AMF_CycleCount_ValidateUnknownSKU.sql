/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/08  RIA     pr_AMF_CycleCount_ValidateUnknownSKU: Added and made changes to pr_AMF_CycleCount_ConfirmPicklaneCC (HA-2199)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_CycleCount_ValidateUnknownSKU') is not null
  drop Procedure pr_AMF_CycleCount_ValidateUnknownSKU;
Go
/*----------------------------------------------------------------------------------
  Procedure pr_AMF_CycleCount_ValidateUnknownSKU: This procedure gets called when
    user scans a SKU which is not associated with the Location.
-----------------------------------------------------------------------------------*/
Create Procedure pr_AMF_CycleCount_ValidateUnknownSKU
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
          @vScannedSKU               TSKU;
          /* Functional variables */
  declare @vDeviceName               TName,
          @vxmlData                  xml,
          @vTempXML                  TXML;
begin /* pr_AMF_CycleCount_ValidateUnknownSKU */

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
         @vLocationId     = Record.Col.value('(Data/m_LocationInfo_LocationId)[1]',  'TRecordId'    ),
         @vLocation       = Record.Col.value('(Data/Location)[1]',                   'TLocation'    ),
         @vScannedSKU     = Record.Col.value('(Data/SKU)[1]',                        'TSKU'         )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* For the new SKU scanned, remove the empty nodes taken from Data Table */
  set @vxmlInput.modify('delete /Root/Data/CCData/CCTable/*[not(node())]');
  set @vxmlInput.modify('delete /Root/Data/m_SKU');

  /* For the new SKU scanned, remove the SKU node */
  set @vxmlInput.modify('delete /Root/Data/CCData/CCTable[SKU = sql:variable("@vScannedSKU")]')

  /* Fetch the DataXML after above clean up */
  select @DataXML = convert(varchar(max), @vxmlInput.query('Root/Data'));

  /* set value for DeviceName to replace current data set to Devices table */
  select @vDeviceName = @vDeviceId + '@' + @vUserId;

  /* Input to validate Entity */
  select @vxmlRFCProcInput = convert(xml, dbo.fn_XMLNode('ValidateCCEntity',
                                              dbo.fn_XMLNode('Location',       @vLocation) +
                                              dbo.fn_XMLNode('ScannedEntity',  @vScannedSKU) +
                                              dbo.fn_XMLNode('ValidateOption', 'S' /* SKU */) +
                                              dbo.fn_XMLNode('BusinessUnit',   @vBusinessUnit) +
                                              dbo.fn_XMLNode('UserId',         @vUserId) +
                                              dbo.fn_XMLNode('DeviceId',       @vDeviceId)));

  /* Validate SKU */
  exec pr_RFC_CC_ValidateEntity @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  /* Evaluate the output for errors */
  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output, @ErrorXML output;

  /* If scanned SKU is invalid exit since error is captured under @ErrorXML */
  if (coalesce(@vTransactionFailed, 0) <> 0)
    begin
      /* Before we exit we would like to store the LPNs scanned so far since when this
         validation is invoked, there may be LPN scans done at the client end that
         were not saved anytime before */

      /* We will be deleting the previous SKU and CCData as this would result in
         issues when unknown scan SKU is not valid one */
      select @vxmlData = convert(xml, @DataXML);
      set @vxmlData.modify('delete /Data/SKU');
      set @vxmlData.modify('delete /Data/RFFormAction');
      set @vxmlData.modify('delete /Data/m_CCData');
      select @DataXML = convert(varchar(max), @vxmlData);

      update Devices
      set DataXML = @DataXML
      where (DeviceId = @vDeviceName);

      return @vTransactionFailed;
    end

  /* Include the new SKU details into the CC table to be shown on the RF Data Table */
  select @vTempXML = (select SKUId                  as SKUId,
                             SKU                    as SKU,
                             dbo.fn_AppendStrings(Description, ' / ', 1)
                                                    as SKUDesc,
                             UoM                    as UoM
                      from dbo.fn_SKUs_GetScannedSKUs (@vScannedSKU, @vBusinessUnit)
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
end /* pr_AMF_CycleCount_ValidateUnknownSKU */

Go

