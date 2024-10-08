/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/15  MS      pr_AMF_Info_GetLPNReservationInfoXML: Display WaveNo in Second Screen (HA-1096)
  2020/06/25  RIA     pr_AMF_Info_GetLPNReservationInfoXML: Code refactoring (HA-789)
  2020/06/21  TK      pr_AMF_Info_GetLPNReservationInfoXML: Code Revamp (HA-820)
  2020/06/16  RIA     pr_AMF_Info_GetLPNReservationInfoXML: Changes to suggest LPNs from Wave/PT Warehouse only (HA-911)
  2020/06/11  RIA     pr_AMF_Info_GetLPNReservationInfoXML: Removed XSINIL (HA-789)
  2020/06/01  RIA     pr_AMF_Info_GetLPNReservationInfoXML: Changes to return values with QtyToReserve (HA-735)
  2020/05/29  RIA     pr_AMF_Info_GetLPNReservationInfoXML: Changes to fetch label code and suggested SKU (HA-521)
  2020/05/27  RIA     pr_AMF_Info_GetLPNReservationInfoXML: Changes to return Wave and Order Info (HA-521)
  2020/05/25  RIA     pr_AMF_Info_GetLPNReservationInfoXML: Changes to get LPNs based on SKU (HA-521)
  2020/05/24  TK      pr_AMF_Info_GetOrderInfoXML, pr_AMF_Info_GetWaveInfoXML & pr_AMF_Info_GetLPNReservationInfoXML:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Info_GetLPNReservationInfoXML') is not null
  drop Procedure pr_AMF_Info_GetLPNReservationInfoXML;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Info_GetLPNReservationInfoXML: In LPN Reservation screen,
    we show the list of SKUs that are needed for the Wave or PickTicket and
    the available inventory for the first SKU or the selected SKU.

  In one scenario, the SKUDetails are passed in i.e. when the user is wanting
  to see available inventory for a different SKU, in which case the SKUId is
  also passed in. So, if xmlSKUDetails is passed in, it is included as is.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Info_GetLPNReservationInfoXML
  (@xmlInput          xml,
   @SKUId             TRecordId = null,
   @DataXML           TXML output)
as
  declare @vRecordId          TRecordId,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vOperation                TOperation,
          @vEntityToReserve          TEntity,
          @vWarehouse                TWarehouse,

          @vOrderId                  TRecordId,
          @vPickTicket               TPickTicket,
          @vPTOwnership              TOwnership,
          @vPTWarehouse              TWarehouse,

          @vWaveId                   TRecordId,
          @vWaveNo                   TWaveNo,
          @vWaveOwnership            TOwnership,
          @vWaveWarehouse            TWarehouse,

          @vSKUId                    TRecordId,
          @vSKU                      TSKU,
          @vInventoryClass1          TInventoryClass,
          @vInventoryClass2          TInventoryClass,
          @vInventoryClass3          TInventoryClass,

          @vWaveInfoXML              TXML,
          @vOrderInfoXML             TXML,
          @vSKUDetailsXML            TXML,
          @vAvailableLPNsXML         TXML,
          @vxmlSKUDetails            xml,
          @vxmlAvailableLPNs         xml;
begin /* pr_AMF_Info_GetLPNReservationInfoXML */

  /* Read input xml */
  select @vEntityToReserve = Record.Col.value('EntityToReserve[1]',   'TEntity'),
         @vWaveId          = Record.Col.value('WaveId[1]',            'TRecordId'),
         @vWaveNo          = Record.Col.value('WaveNo[1]',            'TWaveNo'),
         @vOrderId         = Record.Col.value('OrderId[1]',           'TRecordId'),
         @vPickTicket      = Record.Col.value('PickTicket[1]',        'TPickTicket')
  from @xmlInput.nodes('/LPNReservationInfo') as Record(Col);

  /* Get Order Info */
  if (@vOrderId is not null)
    select @vOrderId   = OrderId,
           @vWarehouse = Warehouse
    from OrderHeaders
    where (OrderId = @vOrderId);
  else
  /* Get Wave Info */
  if (@vWaveId is not null)
    select @vWaveId    = WaveId,
           @vWarehouse = Warehouse
    from Waves
    where (WaveId = @vWaveId);

  /* Get the Wave info to show in display, along with the details of the Wave i.e. List of SKUs
     and qty needed for each of those. The SKUs are returned in #DataTableSKUDetails
     Even if Reserving against PT, we need to get WaveInfo for display purposes */
  if (@vEntityToReserve = 'Wave')
    exec pr_AMF_Info_GetWaveInfoXML @vWaveId, 'WD' /* SKU Details */, 'LPNReservation', @vWaveInfoXML out;
  else
    exec pr_AMF_Info_GetWaveInfoXML @vWaveId, '' /* No Details */, 'LPNReservation', @vWaveInfoXML out;

  /* Get the Order info to show in display and the order details in #DataTableSKUDetails */
  if (@vEntityToReserve = 'PickTicket')
    exec pr_AMF_Info_GetOrderInfoXML @vOrderId, 'OD' /* SKU Details */, 'LPNReservation', @vOrderInfoXML out;

  /* Update Required information on SKUs */
  update DTSD
  set DisplaySKUDesc = dbo.fn_AppendStrings(DisplaySKUDesc, ' / ', InventoryClass1)
  from #DataTableSKUDetails DTSD;

  select @vxmlSKUDetails = (select * from #DataTableSKUDetails
                            order by Case when Quantity2 > 0 then 1 else 9 end, SortOrder, SKU
                            for Xml Raw('SKUInfo'), elements XSINIL, Root('SKUDetailsToReserve'));

  /* Get the first SKU in the list to show the inventory for it */
  if (@SKUId is null)
    select top 1 @SKUId = SKUId from #DataTableSKUDetails where Quantity2 > 0 order by SortOrder;

  /* get the details of the SKU to show the available inventory for the SKU */
  select top 1 @vSKUId           = SKUId,
               @vSKU             = SKU,
               @vInventoryClass1 = InventoryClass1,
               @vInventoryClass2 = InventoryClass2,
               @vInventoryClass3 = InventoryClass3
  from #DataTableSKUDetails
  where (SKUId = @SKUId);

  /* Build the available LPNs */
  select @vxmlAvailableLPNs = (select Location, LPN, SKU, SKUDescription, AllocableQty
                               from vwLPNs
                               where (SKUId = @vSKUId) and
                                     (InventoryClass1 = @vInventoryClass1) and
                                     (InventoryClass2 = @vInventoryClass2) and
                                     (InventoryClass3 = @vInventoryClass3) and
                                     (AllocableQty > 0) and
                                     (DestWarehouse = @vWarehouse)  -- Suggest LPNs from Wave/PT Warehouse
                               order by Location /* change to pick path */ -- when will we do this?
                               for Xml Raw('AvailableLPNs'), elements XSINIL, Root('LPNs'));

  select @vSKUDetailsXML    = convert(varchar(max), @vXMLSKUDetails);
  select @vAvailableLPNsXML = convert(varchar(max), @vxmlAvailableLPNs);

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', coalesce(@vWaveInfoXML, '') + coalesce(@vOrderInfoXML, '') +
                                           coalesce(@vSKUDetailsXML, '') + coalesce(@vAvailableLPNsXML, '') +
                                           dbo.fn_XMLNode('LPNReservationInfo_SKU', @vSKU) +
                                           dbo.fn_XMLNode('LPNReservationInfo_EntityToReserve', @vEntityToReserve));
end /* pr_AMF_Info_GetLPNReservationInfoXML */

Go

