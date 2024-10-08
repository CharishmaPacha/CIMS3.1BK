/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/25  RIA     Added pr_AMF_Common_StopOrPause (CIMSV3-812)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Common_StopOrPause') is not null
  drop Procedure pr_AMF_Common_StopOrPause;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Common_StopOrPause: While performing any operation if
    they want to stop the process and start with new entity, they would use the
    Pause/Stop/Done button which takes them back to the previous screen.

    Using Resolution as Done.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Common_StopOrPause
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
          @vRFFormAction             TMessageName,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vDataXML                  TXML;
begin /* pr_AMF_Common_StopOrPause */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */ -- This is also not needed
  select @vBusinessUnit   = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId         = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId       = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vRFFormAction   = Record.Col.value('(Data/RFFormAction)[1]',               'TMessageName' )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  select @DataXML = (select 'Done' as Resolution
                     for Xml Raw(''), elements, Root('Data'));

end /* pr_AMF_Common_StopOrPause */

Go

