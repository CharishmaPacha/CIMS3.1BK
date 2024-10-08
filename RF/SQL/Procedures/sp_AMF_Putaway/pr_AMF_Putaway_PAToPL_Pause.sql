/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/24  RIA     Added pr_AMF_Putaway_PAToPL_Pause (CIMSV3-656)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Putaway_PAToPL_Pause') is not null
  drop Procedure pr_AMF_Putaway_PAToPL_Pause;
Go
/*------------------------------------------------------------------------------
  Proc pr_AMF_Putaway_PAToPL_Pause: This proc is called when user tries to pause/stop
    putaway.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Putaway_PAToPL_Pause
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
          @vRFFormAction             TMessageName,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vActivityLogId            TRecordId,
          @vSuccessMessage           TMessage;
begin /* pr_AMF_Putaway_PAToPL_Pause */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  select @vDeviceId             = Record.Col.value('(SessionInfo/DeviceId)[1]',                 'TDeviceId'    ),
         @vUserId               = Record.Col.value('(SessionInfo/UserName)[1]',                 'TUserId'      ),
         @vBusinessUnit         = Record.Col.value('(SessionInfo/BusinessUnit)[1]',             'TBusinessUnit'),
         @vPalletId             = Record.Col.value('(Data/m_PalletInfo_PalletId)[1]',           'TRecordId'    ),
         @vPallet               = Record.Col.value('(Data/m_PalletInfo_Pallet)[1]',             'TPallet'      ),
         @vRFFormAction         = Record.Col.value('(Data/RFFormAction)[1]',                    'TMessageName' )
  from @vxmlInput.nodes('Root') as Record(Col);

  select @DataXML = (select 0 PalletId
                     for Xml Raw(''), elements, Root('Data'));

  /* fn_Messages_Build can also be used */
  select @InfoXML = dbo.fn_AMF_BuildSuccessXML('Pallet '+ @vPallet + ' Paused Successfully');
  return (0);

end /* pr_AMF_Putaway_PAToPL_Pause */

Go

