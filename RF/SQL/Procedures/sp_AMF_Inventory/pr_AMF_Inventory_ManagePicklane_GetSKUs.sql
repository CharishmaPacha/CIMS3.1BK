/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/16  RIA     Added: pr_AMF_Inventory_ManagePicklane_RefreshDT, pr_AMF_Inventory_ManagePicklane_GetSKUs: Changes (HA-1688)
  2021/03/07  RIA     Added pr_AMF_Inventory_ManagePicklane_GetSKUs (HA-1688)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_ManagePicklane_GetSKUs') is not null
  drop Procedure pr_AMF_Inventory_ManagePicklane_GetSKUs;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_ManagePicklane_GetSKUs: Based on the user scanned entity
  or filter, fetch all the inventory for the matching skus with style/color/size
  in that location
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_ManagePicklane_GetSKUs
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
          @vScannedSKU               TSKU,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vSKUId                    TRecordId,
          @vSKU                      TSKU,
          @vxmlLocLPNs               xml,
          @vxmlPrevData              xml,
          @vLocLPNsxml               TXML,
          @vPrevDataXML              TXML,
          @vAdditionalInfoXML        TXML,
          @vInvClass1XML             TXML,
          @vInvClass2XML             TXML,
          @vInvClass3XML             TXML,
          @vInvClassXML              TXML;
begin /* pr_AMF_Inventory_ManagePicklane_GetSKUs */

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
         @vScannedSKU           = Record.Col.value('(Data/FilterValue)[1]',                'TSKU'           ),
         @vOperation            = Record.Col.value('(Data/Operation)[1]',                  'TOperation'     )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get the prev dataxml, if SKU scanned is valid then the xml will be replaced
     and sent back to UI*/
  select @vPrevDataXML = DataXML
  from Devices
  where (DeviceId = (@vDeviceId + '@' + @vUserId));

  /* Fetch the SKU, if user scanned UPC/SKU/Barcode/AlternateSKU */
  select @vSKUId = SKUId,
         @vSKU   = SKU
  from dbo.fn_SKUs_GetScannedSKUs (@vScannedSKU, @vBusinessUnit);

  /* Get the LPNs in the Location along with SKU Details */
  if (@vSKUId is not null)
    /* When user scanned SKU and it is present in location, we will fetch related info */
    select @vxmlLocLPNs = (select top 30 LPN, SKU, dbo.fn_AppendStrings(SKUDescription, ' / ', InventoryClass1) SKUDescription, Quantity,
                                  SKU1, SKU2, SKU3, SKU4, SKU5,
                                  InventoryClass1, InventoryClass2, InventoryClass3,
                                  LPNId, SKUId, Pallet, UPC
                           from vwLPNs
                           where (LocationId = @vLocationId) and
                                 (SKUId = @vSKUId)
                                 --((SKU like '%'+ @vScannedSKU + '%') or ((UPC like '%'+ @vScannedSKU + '%')))
                           order by LPN, SKUSortOrder
                           for Xml Raw('LPN'), elements XSINIL, Root('LOCLPNS'));
  else
  /* When user has not given a complete and valid SKU, then search for all
     SKUs matching with SKU, SKU1, SKU2 or SKUDesc */
  if (@vxmlLocLPNs is null)
    select @vxmlLocLPNs = (select top 30 LPN, SKU, dbo.fn_AppendStrings(SKUDescription, ' / ', InventoryClass1) SKUDescription, Quantity,
                                  SKU1, SKU2, SKU3, SKU4, SKU5,
                                  InventoryClass1, InventoryClass2, InventoryClass3,
                                  LPNId, SKUId, Pallet, UPC
                           from vwLPNs
                           where (LocationId = @vLocationId) and
                                 ((SKU1 like '%'+ @vScannedSKU + '%') or (SKU2 like '%'+ @vScannedSKU + '%') or
                                  (SKU like '%'+ @vScannedSKU + '%') or (SKUDescription like '%'+ @vScannedSKU + '%'))
                           order by LPN, SKUSortOrder
                           for Xml Raw('LPN'), elements XSINIL, Root('LOCLPNS'));

  if (@vSKUId is null) and (@vxmlLocLPNs is null)
    set @vMessageName = 'AMF_NoMatchingItemsForFilteredValue';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    exec pr_Messages_ErrorHandler @vMessageName;

  /* Delete the RFFormAction and LOCLPNs */
  select @vxmlPrevData = convert(xml, @vPrevDataXML);
  set @vxmlPrevData.modify('delete /Data/RFFormAction');
  set @vxmlPrevData.modify('delete /Data/LOCLPNS');

  /* Convert it */
  select @vPrevDataXML = coalesce(convert(varchar(max), @vxmlPrevData), '');
  select @vLocLPNsxml = coalesce(convert(varchar(max), @vxmlLocLPNs), '');

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLAddNode(@vPrevDataXML, 'Data',
                                                     coalesce(@vLocLPNsxml, ''));
end /* pr_AMF_Inventory_ManagePicklane_GetSKUs */

Go

