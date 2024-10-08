/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/07  RIA     Added pr_AMF_Inventory_ManagePicklane_AddInventory, pr_AMF_Inventory_ManagePicklane_SetupPicklane,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_ManagePicklane_SetupPicklane') is not null
  drop Procedure pr_AMF_Inventory_ManagePicklane_SetupPicklane;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_ManagePicklane_SetupPicklane: When user attempts to
    setup the picklane i.e. the min/max levels of the picklane this procedure
    is invoked to accomplish the same.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_ManagePicklane_SetupPicklane
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
          @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vSKU                      TSKU,
          @vSKUDescription           TDescription,
          @vMinQty                   TQuantity,
          @vMaxQty                   TQuantity,
          @vReplenishUoM             TUoM,
          @vConfirmAddInventory      TFlags,
          @vWarehouse                TWarehouse,
          @vInventoryClasses         TInventoryClass,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vUoMsXML                  TXML,
          @vSKUId                    TRecordId,
          @vSKUQty                   TQuantity,
          @vDefaultUoM               TUoM,
          @vStorageType              TTypeCode,
          @vNewSKUAdded              TFlags,
          @vReasonCodesXML           TXML,
          @vxmlLocationDetails       xml,
          @vxmlLocSKUInventory       xml,
          @vLocSKUInventorysXML      TXML,
          @vDisplayOptions           TXML,
          @vLocationInfoXML          TXML,
          @vLocationDetailsXML       TXML,
          @vAdditionalInfoXML        TXML;
begin /* pr_AMF_Inventory_ManagePicklane_SetupPicklane */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML          = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML        = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML         = null,
         @InfoXML          = null,
         @vUoMsXML         = '';

  /*  Read inputs from InputXML */
  select @vBusinessUnit         = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'  ),
         @vUserId               = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'        ),
         @vDeviceId             = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'      ),
         @vLocationId           = Record.Col.value('(Data/m_LocationInfo_LocationId)[1]',  'TRecordId'      ),
         @vLocation             = Record.Col.value('(Data/m_LocationInfo_Location)[1]',    'TLocation'      ),
         @vMinQty               = Record.Col.value('(Data/MinQuantity)[1]',                'TQuantity'      ),
         @vMaxQty               = Record.Col.value('(Data/MaxQuantity)[1]',                'TQuantity'      ),
         @vReplenishUoM         = Record.Col.value('(Data/UoM)[1]',                        'TUoM'           ),
         @vSKU                  = Record.Col.value('(Data/m_SKU)[1]',                      'TSKU'           ),
         @vSKUDescription       = Record.Col.value('(Data/m_SKUDescription)[1]',           'TDescription'   ),
         @vConfirmAddInventory  = Record.Col.value('(Data/m_ConfirmAddInventory)[1]',      'TFlags'         ),
         @vInventoryClasses     = Record.Col.value('(Data/m_InventoryClasses)[1]',         'TInventoryClass'),
         @vNewSKUAdded          = Record.Col.value('(Data/m_NewSKUAddedForDynamicLoc)[1]', 'TFlags'         ),
         @vOperation            = Record.Col.value('(Data/Operation)[1]',                  'TOperation'     )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get the Warehouse */
  select @vWarehouse   = Warehouse,
         @vStorageType = StorageType
  from Locations
  where (LocationId = @vLocationId);

  /* Build Input xml for setting up the min/max level */
  select @vrfcProcInputxml = (select Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(Data/m_LocationInfo_Location)[1]',    'TLocation'    ) as Location,
                                     Record.Col.value('(Data/MinQuantity)[1]',                'TQuantity'    ) as MinimumQuantity,
                                     Record.Col.value('(Data/MaxQuantity)[1]',                'TQuantity'    ) as MaximumQuantity,
                                     @vWarehouse                                                               as Warehouse,
                                     Record.Col.value('(Data/UoM)[1]',                        'TUoM'         ) as ReplenishUoM
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('ConfirmLocationSetUp'), elements);

  select @vxmlRFCProcInput = convert(xml, @vrfcProcInputxml);

  /* Call the V2 proc */
  exec pr_RFC_ConfirmLocationSetUp @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  /* Get the success message */
  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output, @InfoXML output;

  /* If there was an error, then return */
  if (@ErrorXML is not null) return;

  /* Get Location Info */
  exec pr_AMF_Info_GetLocationInfoXML @vLocationId, 'LPNList', @vOperation, @vLocationInfoXML output, @vLocationDetailsXML output;

  /* Call the proc to validate and get all possible options */
  exec pr_Inventory_ManagePicklane_GetValidOptions @vLocationId, @vBusinessUnit, @vDisplayOptions output;

  /* If user intends to add inventory, then build XML with extra info to facilitate that */
  if (@vConfirmAddInventory = 'Y')
    begin
      /* Fetch the UoMs */
      exec pr_AMF_BuildLookUpList 'UoM' /* Look up Category */, 'UoM', 'select UoM', @vBusinessunit, @vUoMsXML output;

      /* Fetch the reason codes for add inventory */
      exec pr_AMF_BuildLookUpList 'RC_LPNCreateInv', 'ReasonCodes', 'select a reason', @vBusinessunit, @vReasonCodesXML output;

      /* If picklane is unitstorage type then default UoM to eaches */
      if (@vStorageType like 'U%' /* Units */)
        select @vDefaultUoM = 'EA';
      else
        /* User will be forced to select the UoM */
        select @vDefaultUoM = '1';

      /* Get quantity of scanned SKU to default on screen when user is adding inventory */
      select @vSKUQty = Quantity
      from LPNs
      where (LocationId = @vLocationId) and (LPNType = 'L') and (SKU = @vSKU);

      /* Get the SKUs in the Location, based on user scanned input */
      select @vxmlLocSKUInventory = (select top 30 LPN, SKU, dbo.fn_AppendStrings(SKUDescription, ' / ', InventoryClass1) SKUDescription, Quantity,
                                            SKU1, SKU2, SKU3, SKU4, SKU5,
                                            InventoryClass1, InventoryClass2, InventoryClass3,
                                            LPNId, SKUId, Pallet, UPC
                                     from vwLPNs
                                             where (LocationId = @vLocationId) and
                                           ((SKU like '%'+ @vSKU + '%') or ((UPC like '%'+ @vSKU + '%')))
                                     order by LPN, SKUSortOrder
                                     for Xml Raw('LPN'), elements XSINIL, Root('LOCLPNS'));

      select @vLocSKUInventorysXML = coalesce(convert(varchar(max), @vxmlLocSKUInventory), '');

      /* Build the Additional Info required. This will be a combinaton of the user
         selected options, inputs retreived from previous forms if any and or info like
         qty or descriptions to show in the next form */
      select @vAdditionalInfoXML = dbo.fn_XMLNode('ConfirmAddInventory', @vConfirmAddInventory) +
                                   dbo.fn_XMLNode('SKU', @vSKU) +
                                   dbo.fn_XMLNode('SKUDescription', @vSKUDescription) +
                                   dbo.fn_XMLNode('SKUQty', coalesce(@vSKUQty, 0)) +
                                   dbo.fn_XMLNode('DefaultUoM', @vDefaultUoM) +
                                   dbo.fn_XMLNode('NewSKUAddedForDynamicLoc', @vNewSKUAdded);
    end

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', @vLocationInfoXML +
                                           coalesce(@vLocSKUInventorysXML, @vLocationDetailsXML, '') +
                                           coalesce(@vDisplayOptions, '') + coalesce(@vAdditionalInfoXML, '') +
                                           dbo.fn_XMLNode('InventoryClasses', @vInventoryClasses) +
                                           coalesce(@vUoMsXML, '') +
                                           coalesce(@vReasonCodesXML, ''));
end /* pr_AMF_Inventory_ManagePicklane_SetupPicklane */

Go

