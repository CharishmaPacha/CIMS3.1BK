/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/17  RIA     Added: pr_AMF_Misc_ReworkOrder_Validate, pr_AMF_Misc_ReworkOrder_Pause and
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Misc_ReworkOrder_Pause') is not null
  drop Procedure pr_AMF_Misc_ReworkOrder_Pause;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Misc_ReworkOrder_Pause: While processing the reworkorders, if
    users wants to stop the process and start with another order or something
    else, they would use the Pause button which takes them back to the previous screen.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Misc_ReworkOrder_Pause
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
begin /* pr_AMF_Misc_ReworkOrder_Pause */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit   = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId         = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId       = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vRFFormAction   = Record.Col.value('(Data/RFFormAction)[1]',               'TMessageName' )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  select @DataXML = (select 'Pause' Resolution
                     for Xml Raw(''), elements, Root('Data'));

end /* pr_AMF_Misc_ReworkOrder_Pause*/

Go

