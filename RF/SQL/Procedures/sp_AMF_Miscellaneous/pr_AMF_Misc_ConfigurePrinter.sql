/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/03  RIA     pr_AMF_Misc_ConfigurePrinter: Changes to build message (HA-2113)
  2021/02/25  AY      pr_AMF_Misc_ConfigurePrinter: Bug fix with printer name being truncated (HA Mock-GoLive)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Misc_ConfigurePrinter') is not null
  drop Procedure pr_AMF_Misc_ConfigurePrinter;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Misc_ConfigurePrinter: to configure printer for user logged in device.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Misc_ConfigurePrinter
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TDescription,
          @vMessage                  TMessage,
          @vxmlInput                 xml,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vSelectedPrinter          TName;
begin /* pr_AMF_Misc_ConfigurePrinter */

  /* Convert input into xml var */
  select @vxmlInput = convert(xml, @InputXML);

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit       = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId             = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId           = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vSelectedPrinter    = Record.Col.value('(Data/SelectedPrinter)[1]',            'TName'        )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Update device with selected printer */
  exec pr_Device_AddOrUpdate @vDeviceId, null /* @vDeviceType */, @vUserId, null /* Warehouse */, @vSelectedPrinter,
                             @vBusinessUnit, 'ConfigurePrinter' /* @vCurrentOperation */;

  /* Above procedure raises an exception, when successful returns nothing */
  select @vMessage = dbo.fn_Messages_Build('AMF_ConfigurePrinter_Successful', @vSelectedPrinter, null, null, null, null);

  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  /* If successfully updated, do not return data as it would revert to prior screen */
  select @DataXML = (select 'Done' Resolution
                     for Xml Raw(''), elements, Root('Data'));

end /* pr_AMF_Misc_ConfigurePrinter */

Go

