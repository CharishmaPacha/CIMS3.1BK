/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/08/22  GAG     pr_AMF_Inventory_ValidateSKU: Made changes to get control for Inventory Class and added BuildInventory for Operation (CIMSV3-3035)
  2023/08/24  VKN     pr_AMF_Inventory_ValidateSKU: Changes to get the dropdown list for labelformats (CIMSV3-3034) 
  pr_AMF_Inventory_ValidateSKU: Made changes(HA-1839)
  2020/11/13  RIA     Added pr_AMF_Inventory_ModifySKU, pr_AMF_Inventory_ValidateSKU (CIMSV3-1108)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_ValidateSKU') is not null
  drop Procedure pr_AMF_Inventory_ValidateSKU;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_ValidateSKU: We will check whether it is valid SKU or not
    and return data set with SKUInfo built in V3 format. This is used in Modify SKU
    and could be used elsewhere in future.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_ValidateSKU
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
          @SKU                       TSKU,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vDataXML                  TXML,
          @vScannedEntityXML         TXML,
          @vSKUInfoXML               TXML,
          @vSKUDetailsXML            TXML,
          @vInvClass1XML             TXML,
          @vOwnershipXML             TXML,
          @vWarehouseXML             TXML,
          @vReasonCodesXML           TXML,
          @vLabelFormatXML           TXML,
          @vSKUId                    TRecordId,
          @vSKU                      TSKU,
          @vStatus                   TStatus,
          @Pallet                    TPallet,
          @Location                  TLocation,
          @vWorkFlowSkipped          TFlags,
          @vInventoryClassesUsed     TControlValue;
  declare @ttLabelFormats            TAMFNameValueOptions;
begin /* pr_AMF_Inventory_ValidateSKU */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit    = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId          = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId        = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @SKU              = Record.Col.value('(Data/SKU)[1]',                        'TSKU'         ),
         @vWorkFlowSkipped = Record.Col.value('(Data/WorkFlowSkipped)[1]',            'TFlags'       ),
         @vOperation       = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get InventoryClass used from Controls */
  select @vInventoryClassesUsed = dbo.fn_Controls_GetAsString(@vOperation, 'InventoryClassesUsed', '' /* default */, @vBusinessUnit, @vUserId);

  /* Return and do nothing if skipped and came to new workflow */
  if (@vWorkFlowSkipped = 'Y')
    begin
      select @DataXML = (select '' SKU
                         for Xml Raw(''), elements, Root('Data'));
      return;
    end

  /* Fetch the SKUId and SKU */
  select top 1 @vSKUId  = SKUId,
               @vSKU    = SKU,
               @vStatus = Status
  from dbo.fn_SKUs_GetScannedSKUs(@SKU, @vBusinessUnit);

  if (@vSKUId is null)
    set @vMessageName = 'SKUIsInvalid';
  else
  if (@vStatus = 'I' /* Inactive */)
    set @vMessageName = 'SKUIsInactive';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    exec pr_Messages_ErrorHandler @vMessageName;

  /* Get the SKU Info */
  exec pr_AMF_Info_GetSKUInfoXML @vSKUId, 'N', @vOperation,
                                 @vSKUInfoXML output, @vSKUDetailsXML output;

  /* Build LookUps based on Operation */
  if (@vOperation in ('CreateInvLPN', 'BuildInvLPN'))
    begin

      /* Fetch the InventoryClass1 values */
      exec pr_AMF_BuildLookUpList 'InventoryClass1' /* Look up Category */, 'InventoryClass1',
                                  'select Label Code', @vBusinessunit, @vInvClass1XML output;

      /* Fetch the Ownerships */
      exec pr_AMF_BuildLookUpList 'Owner' /* Look up Category */, 'Ownership',
                                  'select Owner', @vBusinessunit, @vOwnershipXML output;

      /* Fetch the warehouses */
      exec pr_AMF_BuildLookUpList 'Warehouse' /* Look up Category */, 'Warehouse',
                                  'select Warehouse', @vBusinessunit, @vWarehouseXML output;

      /* Fetch the reason codes for creating inventory */
      exec pr_AMF_BuildLookUpList 'RC_LPNCreateInv' /* Look up Category */, 'ReasonCodes',
                                  'select a reason', @vBusinessunit, @vReasonCodesXML output;

     /* Creating #table for inserting label format name and desc */
     select * into #LabelFormats from @ttLabelFormats

     /* Get the list of Label Formats to show in dropdown */
     insert into #LabelFormats(Name, Value)
       select LabelFormatDesc, LabelFormatName
       from LabelFormats
       where (EntityType = 'LPN') and (BusinessUnit = @vBusinessUnit) and (Status = 'A')
       order by SortSeq, LabelFormatDesc;

     /* get the list of Label Formats to show in dropdown */
     exec pr_AMF_BuildDropDownList 'LabelFormats', 'LabelFormatToPrint', 'select Label Format', @vBusinessUnit, @vLabelFormatXML out;

    end

  /* Build the DataXML */
  select @DataXML = dbo.fn_XmlNode('Data', coalesce(@vSKUInfoXML, '') + coalesce(@vSKUDetailsXML, '') +
                                   coalesce(@vInvClass1XML, '') + coalesce(@vOwnershipXML, '') +
                                   coalesce(@vWarehouseXML, '') + coalesce(@vReasonCodesXML,'') +
                                   dbo.fn_XMLNode('InventoryClassesUsed', @vInventoryClassesUsed) +
                                   coalesce(@vLabelFormatXML, ''));

end /* pr_AMF_Inventory_ValidateSKU */

Go
