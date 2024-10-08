/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/03  VM      pr_AMF_Misc_ChangeWarehouse: Added (HA-79)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Misc_ChangeWarehouse') is not null
  drop Procedure pr_AMF_Misc_ChangeWarehouse;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Misc_ChangeWarehouse: To update the Warehouse on user logged in device.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Misc_ChangeWarehouse
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
          @vSelectedWarehouse        TWarehouse;
begin /* pr_AMF_Misc_ChangeWarehouse */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit       = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vDeviceId           = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vUserId             = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vSelectedWarehouse  = Record.Col.value('(Data/SelectedWarehouse)[1]',          'TWarehouse'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Update device with selected Warehouse */
  exec pr_Device_AddOrUpdate @vDeviceId, null /* @vDeviceType */, @vUserId, @vSelectedWarehouse, null /* Printer */,
                             @vBusinessUnit, 'ChangeWarehouse' /* @vCurrentOperation */;

  /* Above procedure raises an exception, when successful returns nothing */
  select @vMessage = dbo.fn_Messages_Build('AMF_ChangeWarehouse_Successful', @vSelectedWarehouse, null, null, null, null);

  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  /* If successfully updated, do not return any data as it would revert to prior screen.
     However, send Warehouse updated to have UI updates latest Warehouse in session variable */
  select @DataXML = (select 'Done'              Resolution,
                            @vSelectedWarehouse SessionKey_Warehouse
                     for Xml Raw(''), elements, Root('Data'));

end /* pr_AMF_Misc_ChangeWarehouse */

Go

