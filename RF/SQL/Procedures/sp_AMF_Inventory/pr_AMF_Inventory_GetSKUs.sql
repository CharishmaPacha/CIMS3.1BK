/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/09  RIA     pr_AMF_Inventory_GetSKUs: Changes to consider operation (HA-2938)
  2021/06/21  RIA     Added: pr_AMF_Inventory_GetSKUs (HA-2878)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_GetSKUs') is not null
  drop Procedure pr_AMF_Inventory_GetSKUs;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_GetSKUs: Based on the user scanned entity or filter,
  fetch all the inventory for the matching skus with style/color/size in that location
  or LPN
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_GetSKUs
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
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vScannedSKU               TSKU,
          @vLPNOperation             TOperation,
          @vLocationOperation        TOperation,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vSKUId                    TRecordId,
          @vSKU                      TSKU,
          @vSKUSearch                TSKU,
          @vRowsToSelect             TInteger,
          @vxmlPrevData              xml,
          @vPrevDataXML              TXML,
          @vDetailsXML               TXML,
          @vDataXML                  TXML;
begin /* pr_AMF_Inventory_GetSKUs */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit         = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'  ),
         @vUserId               = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'        ),
         @vDeviceId             = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'      ),
         @vLocationId           = Record.Col.value('(Data/m_LocationInfo_LocationId)[1]',  'TRecordId'      ),
         @vLocation             = Record.Col.value('(Data/m_LocationInfo_Location)[1]',    'TLocation'      ),
         @vLPNId                = Record.Col.value('(Data/m_LPNInfo_LPNId)[1]',            'TRecordId'      ),
         @vLPN                  = Record.Col.value('(Data/m_LPNInfo_LPN)[1]',              'TLPN'           ),
         @vScannedSKU           = Record.Col.value('(Data/FilterValue)[1]',                'TSKU'           ),
         @vLPNOperation         = Record.Col.value('(Data/LPNOperation)[1]',               'TOperation'     ),
         @vLocationOperation    = Record.Col.value('(Data/LocationOperation)[1]',          'TOperation'     ),
         @vOperation            = Record.Col.value('(Data/Operation)[1]',                  'TOperation'     )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get the prev dataxml, if SKU scanned is valid then the xml will be replaced
     and sent back to UI*/
  select @vPrevDataXML = DataXML
  from Devices
  where (DeviceId = (@vDeviceId + '@' + @vUserId));

  if ((@vLocationId is not null) and (@vOperation in ('AdjustQty', 'TransferInventory')))
    select @vOperation  = @vLocationOperation;
  else
  if ((@vLPNId is not null) and (@vOperation in ('AdjustQty', 'TransferInventory')))
    select @vOperation  = @vLPNOperation;

  /* Build the Data table */
  exec pr_AMF_DataTableSKUDetails_Build @vLocationId, @vLPNId, null /* DetailLevel */, @vOperation, @vScannedSKU, @vBusinessUnit, @vDetailsXML output;

  /* Delete the RFFormAction and LOCLPNs */
  select @vxmlPrevData = convert(xml, @vPrevDataXML);
  --set @vxmlPrevData.modify('delete /Data/RFFormAction');
  set @vxmlPrevData.modify('delete /Data/SKUDETAILS');
  set @vxmlPrevData.modify('delete /Data/LPNDETAILS');

  /* Convert it */
  select @vPrevDataXML = coalesce(convert(varchar(max), @vxmlPrevData), '');

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLAddNode(@vPrevDataXML, 'Data',
                                                     coalesce(@vDetailsXML, ''));
end /* pr_AMF_Inventory_GetSKUs */

Go

