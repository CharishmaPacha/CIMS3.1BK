/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/06  RIA     pr_AMF_Picking_LPNReservation_Confirm, pr_AMF_Picking_LPNReservation_GetAvailableLPNs,
  2020/07/01  RIA     pr_AMF_Picking_LPNReservation_GetAvailableLPNs: Changes to build Available LPNs (HA-789)
  2020/06/25  RIA     pr_AMF_Picking_LPNReservation_Confirm, pr_AMF_Picking_LPNReservation_GetAvailableLPNs,
  2020/05/29  RIA     Added: pr_AMF_Picking_LPNReservation_GetAvailableLPNs (HA-521)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_LPNReservation_GetAvailableLPNs') is not null
  drop Procedure pr_AMF_Picking_LPNReservation_GetAvailableLPNs;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_LPNReservation_GetAvailableLPNs: During LPN reservation
    user is given the provision to select/scan another SKU (other than the suggested one)
    an we would need to show the available inventory for the selected SKU. This procedure
    returns the updated inventory for the selected SKU.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_LPNReservation_GetAvailableLPNs
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
          @vBusinessUnit              TBusinessUnit,
          @vUserId                    TUserId,
          @vDeviceId                  TDeviceId,
          @vEntityToReserve           TEntity,
          @vWaveId                    TRecordId,
          @vWaveNo                    TWaveNo,
          @vOrderId                   TRecordId,
          @vPickTicket                TPickTicket,
          @vSelectedSKU               TSKU,
          @vOrderWH                   TWarehouse,
          @vWaveWH                    TWarehouse,
          @vFilterValue               TEntity,
          @vInventoryClass1           TInventoryClass,
          @vInventoryClass2           TInventoryClass,
          @vInventoryClass3           TInventoryClass,
          @vOperation                 TOperation;
          /* Functional variables */
  declare @vxmlSKUDetails             xml,
          @vxmlInput1                 xml,
          @vxmlPrevData               xml,
          @vxmlWaveOrPTInfo           xml,
          @vxmlAvailableLPNs          xml,
          @vSKUInfoXML                TXML,
          @vPrevDataXML               TXML,
          @vWaveOrPTInfoXML           TXML,
          @vAvailableLPNsXML          TXML,
          @vWarehouse                 TWarehouse,
          @vSKUId                     TRecordId,
          @vSKU                       TSKU;
begin /* pr_AMF_Picking_LPNReservation_GetAvailableLPNs */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Fetch the input values */
  select @vBusinessUnit    = Record.Col.value('(SessionInfo/BusinessUnit)[1]',                  'TBusinessUnit'  ),
         @vUserId          = Record.Col.value('(SessionInfo/UserName)[1]',                      'TUserId'        ),
         @vDeviceId        = Record.Col.value('(SessionInfo/DeviceId)[1]',                      'TDeviceId'      ),
         @vEntityToReserve = Record.Col.value('(Data/m_LPNReservationInfo_EntityToReserve)[1]', 'TEntity'        ),
         @vWaveId          = Record.Col.value('(Data/m_WaveInfo_WaveId)[1]',                    'TRecordId'      ),
         @vWaveNo          = nullif(Record.Col.value('(Data/m_WaveInfo_WaveNo)[1]',             'TWaveNo'), ''   ),
         @vOrderId         = Record.Col.value('(Data/m_OrderInfo_OrderId)[1]',                  'TRecordId'      ),
         @vOrderWH         = nullif(Record.Col.value('(Data/m_OrderInfo_Warehouse)[1]',         'TWarehouse'), ''),
         @vWaveWH          = nullif(Record.Col.value('(Data/m_WaveInfo_Warehouse)[1]',          'TWarehouse'), ''),
         @vPickTicket      = nullif(Record.Col.value('(Data/m_OrderInfo_PickTicket)[1]',        'TPickTicket'), ''),
         @vSelectedSKU     = Record.Col.value('(Data/SelectedSKU)[1]',                          'TSKU'           ),
         @vFilterValue     = Record.Col.value('(Data/FilterValue)[1]',                          'TEntity'        ),
         @vInventoryClass1 = Record.Col.value('(Data/InventoryClass1)[1]',                      'TInventoryClass'),
         @vInventoryClass2 = Record.Col.value('(Data/InventoryClass2)[1]',                      'TInventoryClass'),
         @vInventoryClass3 = Record.Col.value('(Data/InventoryClass3)[1]',                      'TInventoryClass')
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlInput = null ) );

  /* Get the Warehouse */
  select @vWarehouse = coalesce(@vWaveWH, @vOrderWH)

  /* Get the valid SKUId for the SKU scanned */
  select @vSKUId = SKUId,
         @vSKU   = SKU
  from dbo.fn_SKUs_GetScannedSKUs (@vSelectedSKU, @vBusinessUnit);

  /* Get the prev dataxml. Everything else is the same, except the inventory, so
     we take the PrevDataXML and plug in the new inventory info */
  select @vPrevDataXML = DataXML
  from Devices
  where (DeviceId = (@vDeviceId + '@' + @vUserId));

  /* Convert the previously returned data set to xml */
  select @vxmlPrevData = convert(xml, @vPrevDataXML);
  select @vxmlWaveOrPTInfo = @vxmlPrevData; -- Doing this as need to replace Available LPNs
  --select @vxmlSKUDetails = @vxmlPrevData.query('/Data/SKUDetailsToReserve');

  /* Delete the xml nodes for which we need the new set  */
  set @vxmlWaveOrPTInfo.modify('delete /Data /LPNs');
  set @vxmlWaveOrPTInfo.modify('delete /Data /LPNReservationInfo_SKU');
  set @vxmlWaveOrPTInfo.modify('delete /Data /LPNReservationInfo_FilterValue');
  /* Doing this to delete the LPN, if already validated and user intentionally clicked
     on SKUs to get the Available LPNs */
  set @vxmlWaveOrPTInfo.modify('delete /Data /LPNReservationInfo_LPNId');
  set @vxmlWaveOrPTInfo.modify('delete /Data /LPNReservationInfo_LPN');
  set @vxmlWaveOrPTInfo.modify('delete /Data /LPNReservationInfo_AllocableQty');

  /* Build the available LPNs */
  select @vxmlAvailableLPNs = (select Location, LPN, SKU, SKUDescription, AllocableQty
                               from vwLPNs
                               where (SKUId = @vSKUId) and
                                     (InventoryClass1 = @vInventoryClass1) and
                                     (InventoryClass2 = @vInventoryClass2) and
                                     (InventoryClass3 = @vInventoryClass3) and
                                     (AllocableQty > 0) and
                                     (DestWarehouse = @vWarehouse)  -- Suggest LPNs from Wave/PT Warehouse
                               order by Location /* change to pick path */
                               for Xml Raw('AvailableLPNs'), elements XSINIL, Root('LPNs'));

  select @vAvailableLPNsXML = convert(varchar(max), @vxmlAvailableLPNs);
  select @vWaveOrPTInfoXML  = convert(varchar(max), @vxmlWaveOrPTInfo);

  select @DataXml = dbo.fn_XmlAddNode(@vWaveOrPTInfoXML, 'Data', coalesce(@vAvailableLPNsXML, '') +
                                                          dbo.fn_XMLNode('LPNReservationInfo_SKU', @vSKU) +
                                                          dbo.fn_XMLNode('LPNReservationInfo_FilterValue', @vFilterValue));

end /* pr_AMF_Picking_LPNReservation_GetAvailableLPNs */

Go

