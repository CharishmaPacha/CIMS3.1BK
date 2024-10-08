/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/10  RIA     pr_AMF_Putaway_PAToPL_Validate, pr_AMF_Putaway_PAToPL_Confirm, pr_AMF_Putaway_PAToPL_SkipSKU: CleanUp (OB2-1197)
  2019/11/26  RIA     pr_AMF_Putaway_ConfirmPalletPAToPicklane, pr_AMF_Putaway_PAToPL_SkipSKU,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Putaway_PAToPL_SkipSKU') is not null
  drop Procedure pr_AMF_Putaway_PAToPL_SkipSKU;
Go
/*------------------------------------------------------------------------------
  Proc pr_AMF_Putaway_PAToPL_SkipSKU:
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Putaway_PAToPL_SkipSKU
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
As
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
          @vSKU                      TSKU,
          @vPutawaySequence          TControlValue,
          @vRFFormAction             TMessageName,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vPalletInfoXML            TXML,
          @vPalletDetailsXML         TXML,
          @vPADetailsXML             TXML,
          @vActivityLogId            TRecordId,
          @vSuccessMessage           TMessage;
begin /* pr_AMF_Putaway_PAToPL_SkipSKU */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  select @vDeviceId             = Record.Col.value('(SessionInfo/DeviceId)[1]',                 'TDeviceId'    ),
         @vUserId               = Record.Col.value('(SessionInfo/UserName)[1]',                 'TUserId'      ),
         @vBusinessUnit         = Record.Col.value('(SessionInfo/BusinessUnit)[1]',             'TBusinessUnit'),
         @vPallet               = Record.Col.value('(Data/m_PalletInfo_Pallet)[1]',             'TPallet'      ),
         @vPalletId             = Record.Col.value('(Data/m_PalletInfo_PalletId)[1]',           'TRecordId'    ),
         @vPutawaySequence      = Record.Col.value('(Data/m_PADetails_PutawaySequence)[1]',     'TControlValue'),
         @vRFFormAction         = Record.Col.value('(Data/RFFormAction)[1]',                    'TMessageName' )
  from @vxmlInput.nodes('Root') as Record(Col);

  /* Update the device operations */
  update Devices
  set LastUsedDateTime = current_timestamp,
      PickSequence     = @vPutawaySequence
  where (DeviceId = (@vDeviceId + '@' + @vUserId) and
        (BusinessUnit = @vBusinessUnit));

  /* Get Pallet Info */
  exec pr_AMF_Info_GetPalletInfoXML @vPalletId, 'N' /* LPNDetails */, null, @vPalletInfoXML output, @vPalletDetailsXML output;

  /* Get the putaway SKU info to show */
  exec pr_Putaway_PAtoPL_GetSKUToPutaway @vPalletId, @vDeviceId, @vUserId, @vRFFormAction, @vBusinessUnit, @vPADetailsXML output;

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', coalesce(convert(varchar(max), @vPalletInfoXML), '') +
                                         @vPalletDetailsXML + @vPADetailsXML);

end /* pr_AMF_Putaway_PAToPL_SkipSKU */

Go

