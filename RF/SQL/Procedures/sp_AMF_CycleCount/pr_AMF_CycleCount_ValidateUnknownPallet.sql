/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_AMF_CycleCount_ValidateUnknownPallet: New procedure to validate new Pallet scanned (HA-1077)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_CycleCount_ValidateUnknownPallet') is not null
  drop Procedure pr_AMF_CycleCount_ValidateUnknownPallet;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_CycleCount_ValidateUnknownPallet:
    Confirm Location - Pallet
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_CycleCount_ValidateUnknownPallet
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
          @vLocation                 TLocation,
          @vPalletId                 TRecordId,
          @vPallet                   TPallet,
          @vNumSKUs                  TCount,
          @vNewDataXML               TXML,
          @vTempXML                  TXML;
begin
  /* Convert input into xml var */
  select @vxmlInput = convert(xml, @InputXML);

  /* Initialize */
  select @DataXML     = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML   = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML    = null,
         @InfoXML     = null,
         @vNewDataXML = null;

  /* Read inputs from InputXML */
  select @vBusinessUnit   = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId         = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId       = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vLocation       = Record.Col.value('(Data/Location)[1]',                   'TLocation'    ),
         @vPallet         = Record.Col.value('(Data/Pallet)[1]',                     'TPallet'      )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* set value for DeviceName to replace current data set to Devices table */
  select @vDeviceName = @vDeviceId + '@' + @vUserId;

  /* Input to validate Entity */
  select @vxmlRFCProcInput = convert(xml, dbo.fn_XMLNode('ValidateCCEntity',
                                              dbo.fn_XMLNode('Location',       @vLocation) +
                                                  dbo.fn_XMLNode('ScannedEntity',  @vPallet) +
                                                  dbo.fn_XMLNode('Pallet',         @vPallet) +
                                                  dbo.fn_XMLNode('ValidateOption', 'P' /* Pallet */) +
                                                  dbo.fn_XMLNode('BusinessUnit',   @vBusinessUnit) +
                                                  dbo.fn_XMLNode('UserId',         @vUserId) +
                                                  dbo.fn_XMLNode('DeviceId',       @vDeviceId)));

  /* Validate Pallet */
  exec pr_RFC_CC_ValidateEntity @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  /* Evaluate the output for errors */
  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output, @ErrorXML output;

  /* Exit if the pallet scanned is not valid */
  if (coalesce(@vTransactionFailed, 0) <> 0)
    begin
      /* Clear the input Pallet value which then clears from the form to re-scan valid Pallet */
      exec pr_XMLModifyNode @DataXML, '/Data/Pallet', 'R' /* Replace */, '' /* Empty string */, @vNewDataXML output;

      /* Before we exit we would like to store scanned entties so far since when this
         validation is invoked, there may be scans done at the client end that
         were not saved anytime before */
      update Devices
      set DataXML = coalesce(@vNewDataXML, @DataXML)
      where (DeviceId = @vDeviceName);

      return @vTransactionFailed;
    end

  /* Clean up old CCData node & Pallet */
  exec pr_XMLModifyNode @DataXML, '/Data/m_CCData', 'D' /* Delete */, default, @vTempXML output
  select @DataXML = coalesce(@vTempXML, @DataXML);

  exec pr_XMLModifyNode @DataXML, '/Data/m_Pallet', 'D' /* Delete */, default, @vTempXML output
  select @DataXML = coalesce(@vTempXML, @DataXML);

  /* Would raise an exception if the LPN failed validation above */
  return(coalesce(@vReturnCode, 0));
end /* pr_AMF_CycleCount_ValidateUnknownPallet */

Go

