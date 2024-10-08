/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/23  RIA     pr_AMF_Inventory_AddSKUToLPN, pr_AMF_Inventory_AddSKUToLPN_ValidateSKU : Changes to include InventoryClass1 (HA-1794)
  2020/09/13  RIA     Made changes to pr_AMF_Inventory_AddSKUToLPN_ValidateSKU (CIMSV3-812)
  2020/04/11  RIA     Added pr_AMF_Inventory_AddSKUToLPN_ValidateSKU, made changes to pr_AMF_Inventory_AddSKUToLPN (CIMSV3-812)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_AddSKUToLPN_ValidateSKU') is not null
  drop Procedure pr_AMF_Inventory_AddSKUToLPN_ValidateSKU;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_AddSKUToLPN_ValidateSKU:

  Validates the scanned SKU and returns the SKUInfo along with the previous succesful
  data xml from devices table.

  Also if user scanned a SKU then we are locking it and asking user to key in the
  qty. This method will be invoked after scanning an LPN and a SKU. Either it might
  be a 1st scan or only after completion of adding inventory for a SKU. As we are
  building the dataxml again after Adding Inventory to LPN there won't be any nodes
  with SKUInfo.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_AddSKUToLPN_ValidateSKU
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
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vDeviceId                 TDeviceId,
          @vUserId                   TUserId,
          @vSKU                      TSKU,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vPrevDataXML              TXML,
          @vLPNInfoXML               TXML,
          @vSKUInfoXML               TXML,
          @vSKUDetailsXML            TXML,
          @vLPNPrevInfoXML           TXML,
          @vInvClass1XML             TXML,
          @vxmlSKUInfo               xml,
          @vSKUId                    TRecordId,
          @vSKUUoMCaption            TDescription,
          @vAllowedInvClasses        TControlValue,
          @vDeviceName               TName;
begin /* pr_AMF_Inventory_AddSKUToLPN_ValidateSKU */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read the values from input */
  select @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vDeviceId      = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vUserId        = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vSKU           = Record.Col.value('(Data/SKU)[1]',                        'TSKU'         ),
         @vOperation     = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col);

  /* Get the valid SKUId for the SKU scanned */
  select @vSKUId = SKUId
  from dbo.fn_SKUs_GetScannedSKUs (@vSKU, @vBusinessUnit);

  if (@vSKUId is null)
    set @vMessageName = 'SKUIsInvalid';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Capture SKU Information */
  insert into #DataTableSKUDetails (SKUId, UnitsPerInnerPack, InnerPacksPerLPN,
                                    UnitsPerLPN)
    select SKUId, coalesce(UnitsPerInnerPack, 0), coalesce(UnitsPerInnerPack, 0),
           coalesce(UnitsPerLPN, 0)
    from SKUs
    where (SKUId = @vSKUId);

  /* This proc is used to update the SKU related info on the data table */
  exec pr_AMF_DataTableSKUDetails_UpdateSKUInfo;

  select @vxmlSKUInfo = (select * from #DataTableSKUDetails
                         for xml raw('SKUInfo'), Elements);

  select @vSKUInfoXML = '';
  with FlatXML as
  (
    select dbo.fn_XMLNode('SKUInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlSKUInfo.nodes('/SKUInfo/*') as t(c)
  )
  select @vSKUInfoXML = @vSKUInfoXML + DetailNode from FlatXML;

  /* set value for DeviceName to get value from Devices table */
  select @vDeviceName = @vDeviceId + '@' + @vUserId;

  /* Get the prev dataxml */
  select @vPrevDataXML = DataXML
  from Devices
  where (DeviceId = @vDeviceName);

  /* Fetch the values within the data node for the previous successful transaction.*/
  select @vLPNPrevInfoXML = dbo.fn_XMLGetValue(@vPrevDataXML, 'Data');

  /* Get the controlvalue for InvClasses */
  select @vAllowedInvClasses = dbo.fn_Controls_GetAsString(@vOperation, 'AllowedInventoryClasses', '' /* default */, @vBusinessUnit, @vUserId);

  /* Fetch the InventoryClass1/LabelCode */
  if (@vAllowedInvClasses like '%1%')
    exec pr_AMF_BuildLookUpList 'InventoryClass1' /* Look up Category */, 'InventoryClass1',
                                'select Label Code', @vBusinessunit, @vInvClass1XML output;

  /* The Data XML will not have the another SKU info as we are locking the SKU after user
     scanning it and asking them to confirm the inventory. So the DataXML will have the
     new/latest info without SKUInfo. So we will not end up with duplicate/multiple SKUs info */
  select @DataXML = dbo.fn_XmlNode('Data', coalesce(@vSKUInfoXML, '') +
                                           coalesce(@vLPNPrevInfoXML,'') +
                                           dbo.fn_XMLNode('InventoryClass', @vAllowedInvClasses) +
                                           coalesce(@vInvClass1XML, ''));

end /* pr_AMF_Inventory_AddSKUToLPN_ValidateSKU */

Go

