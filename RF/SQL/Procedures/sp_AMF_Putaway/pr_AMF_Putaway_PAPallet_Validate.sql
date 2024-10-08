/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/07  RIA     pr_AMF_Putaway_PAPallet_Validate: Changes to get the LPNs on Pallet (CIMSV3-623)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Putaway_PAPallet_Validate') is not null
  drop Procedure pr_AMF_Putaway_PAPallet_Validate;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Putaway_PAPallet_Validate: Calls the V2 procedure and Validates
   the scanned entity either LPNOnPallet/Pallet and if exists returns appropriate
   info else raises an error
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Putaway_PAPallet_Validate
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vxmlInput                 xml,
          @vxmlOutput                xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vReturnCode               TInteger,
          @vTransactionFailed        TBoolean,
          @vMessageName              TMessageName,
          /* Inputs */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vPallet                   TPallet,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vPalletInfoXML            TXML,
          @vPalletDetailsXML         TXML,
          @vPalletId                 TRecordId,
          @vNumLPNsonPallet          TCount,
          @vDestZone                 TZone,
          @vDestLocation             TLocation;
begin /* pr_AMF_Putaway_PAPallet_Validate */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @InfoXML   = null,
         @ErrorXML  = null

  /* Read inputs from InputXML */
  select @vDeviceId      = Record.Col.value('(SessionInfo/DeviceId)[1]',     'TDeviceId'    ),
         @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @vUserId        = Record.Col.value('(SessionInfo/UserName)[1]',     'TUserId'      ),
         @vPallet        = Record.Col.value('(Data/Pallet)[1]',              'TPallet'      )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Getting NumLPNs to make sure we did not get any errors */
  -- the idea is the have the user enter the number of LPNs or Cases or Qty to ensure we validate it.
  -- if this validation is not required we have control var vValidateLPNsOnPallet, please use that and remove this code
  -- select @vNumLPNsonPallet  = NumLPNs
  -- from  Pallets
  -- where (PalletId = dbo.fn_Pallets_GetPalletId (@vPallet, @vBusinessUnit));

  /* Call the V2 proc and get the info */
  exec pr_RFC_PA_ValidatePutawayPallet @vPallet, @vNumLPNsonPallet, @vBusinessUnit, @vUserId, @vDeviceId, @vxmlRFCProcOutput output;

  /* Verify whether there are any errors or not */
  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output, @ErrorXML = @ErrorXML output;

  /* If there is an error, return */
  if (@vTransactionFailed > 0) return (@vTransactionFailed);

  /* Get PalletId from the output of V2 procedure */
  select @vPalletId = Record.Col.value('PalletId[1]',      'TRecordId')
  from @vxmlRFCProcOutput.nodes('/PAPalletDetails/PutawayPallet')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlRFCProcOutput = null));

  /* Get Pallet Info */
  exec pr_AMF_Info_GetPalletInfoXML @vPalletId, 'L' /* LPNs */, @vOperation,
                                    @vPalletInfoXML output, @vPalletDetailsXML output;

  /* Read the values from V2 to show */
  select @DataXML = '';
  with ResponseDetails as
  (
    select dbo.fn_XMLNode('' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
    from @vxmlRFCProcOutput.nodes('/PAPalletDetails/PutawayPallet/*') as t(c)
  )
  select @DataXML = @DataXML + ResponseDetail from ResponseDetails;

  /* Add the additional LPN Info */
  select @DataXml = dbo.fn_XmlNode('Data', @DataXML + coalesce(@vPalletInfoXML, '') +
                                                      coalesce(@vPalletDetailsXML, ''));
end /* pr_AMF_Putaway_PAPallet_Validate */

Go

