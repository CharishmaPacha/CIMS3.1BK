/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/16  RIA     Added: pr_AMF_Inventory_ManagePicklane_RefreshDT, pr_AMF_Inventory_ManagePicklane_GetSKUs: Changes (HA-1688)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_ManagePicklane_RefreshDT') is not null
  drop Procedure pr_AMF_Inventory_ManagePicklane_RefreshDT;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_ManagePicklane_RefreshDT: When user clicks on cancel/refresh
  button in any of the ManagePicklane screen, this gets executed. Here we will be
  calling the location info proc and send the info with top 30 Loc LPNs details
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_ManagePicklane_RefreshDT
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
          @vOperation                TOperation;
          /* Functional variables */
  declare @vInvClass                 TInventoryClass,
          @vDisplayOptions           TXML,
          @vLocationInfoXML          TXML,
          @vLocationDetailsXML       TXML;
begin /* pr_AMF_Inventory_ManagePicklane_RefreshDT */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML         = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML       = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML        = null,
         @InfoXML         = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit         = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'  ),
         @vUserId               = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'        ),
         @vDeviceId             = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'      ),
         @vLocationId           = Record.Col.value('(Data/m_LocationInfo_LocationId)[1]',  'TRecordId'      ),
         @vLocation             = Record.Col.value('(Data/m_LocationInfo_Location)[1]',    'TLocation'      ),
         @vOperation            = Record.Col.value('(Data/Operation)[1]',                  'TOperation'     )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get Location Info */
  exec pr_AMF_Info_GetLocationInfoXML @vLocationId, 'LPNList', @vOperation, @vLocationInfoXML output, @vLocationDetailsXML output;

  /* Call the proc to validate and get all possible options */
  exec pr_Inventory_ManagePicklane_GetValidOptions @vLocationId, @vBusinessUnit, @vDisplayOptions output;

  /* We will give user an option to add inv class while Adding SKU to picklane,
     and it is completely dependent on whether client needed it or not. It is handled
     based on the below control variable */
  select @vInvClass = dbo.fn_Controls_GetAsString(@vOperation, 'InventoryClasses', '' /* default */, @vBusinessUnit, @vUserId);

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', @vLocationInfoXML + @vLocationDetailsXML +
                                           coalesce(@vDisplayOptions, '') +
                                           dbo.fn_XMLNode('InventoryClasses', @vInvClass));
end /* pr_AMF_Inventory_ManagePicklane_RefreshDT */

Go

