/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/20  RIA     Added pr_AMF_Inventory_ManagePicklane_GetInvClasses (HA-652)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_ManagePicklane_GetInvClasses') is not null
  drop Procedure pr_AMF_Inventory_ManagePicklane_GetInvClasses;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_ManagePicklane_GetInvClasses: If Inventory classes
  are being used and user chooses to add a SKU, then after the scan of the SKU
  user would need to be directed to the Add Inventory Class, so this procedure
  is invoked to get the inventory classes before we navitage to AddSKUwithInvClasses
  form
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_ManagePicklane_GetInvClasses
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
          @vLocation                 TLocation,
          @vSKU                      TSKU,
          @vConfirmAddSKU            TFlags,
          @vConfirmRemoveSKU         TFlags,
          @vConfirmSetupPicklane     TFlags,
          @vConfirmAddInventory      TFlags,
          @vInventoryClasses         TInventoryClass,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vPrevDataXML              TXML,
          @vAdditionalInfoXML        TXML,
          @vInvClass1XML             TXML,
          @vInvClass2XML             TXML,
          @vInvClass3XML             TXML,
          @vInvClassXML              TXML;
begin /* pr_AMF_Inventory_ManagePicklane_GetInvClasses */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML         = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML       = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML        = null,
         @InfoXML         = null,
         @vInvClassXML    = '';

  /*  Read inputs from InputXML */
  select @vBusinessUnit         = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'  ),
         @vUserId               = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'        ),
         @vDeviceId             = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'      ),
         @vLocation             = Record.Col.value('(Data/ScannedPicklane)[1]',            'TLocation'      ),
         @vSKU                  = Record.Col.value('(Data/SKU)[1]',                        'TSKU'           ),
         @vConfirmAddSKU        = Record.Col.value('(Data/ConfirmAddSKU)[1]',              'TFlags'         ),
         @vConfirmRemoveSKU     = Record.Col.value('(Data/ConfirmRemoveSKU)[1]',           'TFlags'         ),
         @vConfirmSetupPicklane = Record.Col.value('(Data/ConfirmSetupPicklane)[1]',       'TFlags'         ),
         @vConfirmAddInventory  = Record.Col.value('(Data/ConfirmAddInventory)[1]',        'TFlags'         ),
         @vInventoryClasses     = Record.Col.value('(Data/m_InventoryClasses)[1]',         'TInventoryClass'),
         @vOperation            = Record.Col.value('(Data/Operation)[1]',                  'TOperation'     )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get the prev dataxml. Everything else is the same, except the InvClasses, so
     we take the PrevDataXML and plug in the needed info */
  select @vPrevDataXML = DataXML
  from Devices
  where (DeviceId = (@vDeviceId + '@' + @vUserId));

  /* Fetch the InventoryClass1/LabelCode */
  if (@vInventoryClasses like '%1%')
    exec pr_AMF_BuildLookUpList 'InventoryClass1' /* Look up Category */, 'InventoryClass1',
                                'select Label Code', @vBusinessunit, @vInvClass1XML output;

  /* Fetch the InventoryClass2/LabelCode */
  if (@vInventoryClasses like '%2%')
    exec pr_AMF_BuildLookUpList 'InventoryClass2' /* Look up Category */, 'InventoryClass2',
                                'select Label Code', @vBusinessunit, @vInvClass2XML output;

  /* Fetch the InventoryClass3/LabelCode */
  if (@vInventoryClasses like '%3%')
    exec pr_AMF_BuildLookUpList 'InventoryClass3' /* Look up Category */, 'InventoryClass3',
                                'select Label Code', @vBusinessunit, @vInvClass3XML output;

  /* Build the Additional Info required. This will be a combinaton of the user
     selected options, inputs retreived from previous forms if any and or info like
     qty or descriptions to show in the next form */
  select @vAdditionalInfoXML = dbo.fn_XMLNode('ConfirmAddSKU',        @vConfirmAddSKU) +
                               dbo.fn_XMLNode('ConfirmSetupPicklane', @vConfirmSetupPicklane) +
                               dbo.fn_XMLNode('ConfirmAddInventory',  @vConfirmAddInventory) +
                               dbo.fn_XMLNode('SKU', @vSKU);

  select @vInvClassXML  = coalesce(@vInvClass1XML, '');
  select @vInvClassXML += coalesce(@vInvClass2XML, '');
  select @vInvClassXML += coalesce(@vInvClass3XML, '');

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLAddNode(@vPrevDataXML, 'Data',
                                                     coalesce(@vAdditionalInfoXML, '') +
                                                     coalesce(@vInvClassXML, '') +
                                                     dbo.fn_XMLNode('InventoryClassRequired', 'Y'));
end /* pr_AMF_Inventory_ManagePicklane_GetInvClasses */

Go

