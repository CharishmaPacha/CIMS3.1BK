/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/14  RIA     pr_AMF_Packing_BuildPackInfo: Made changes to proc signature and build PackingNotes (OB2-1882)
  2020/10/12  RIA     pr_AMF_Packing_BuildPackInfo: Changes to consider DisplaySKU and DisplaySKUDesc (CIMSV3-622)
  2020/09/29  RIA     pr_AMF_Packing_BuildPackInfo, pr_AMF_Packing_OrderPacking_ScanComplete: Did clean-up (CIMSV3)
  2019/12/20  RIA     Added: pr_AMF_Packing_BuildPackInfo (CIMSV3-622)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Packing_BuildPackInfo') is not null
  drop Procedure pr_AMF_Packing_BuildPackInfo;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Packing_BuildPackInfo:

  This proc accepts PickTicket and OrderId as input and builds the response in
  desired format for V3
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Packing_BuildPackInfo
  (@OrderId      TRecordId,
   @PickTicket   TPickTicket,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId,
   @DataXML      TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vxmlInput                 xml,
          @vxmlOutput                xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vRFFormAction             TMessageName,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vxmlPackDetails           xml,
          @vxmlOrderInfo             xml,
          @vxmlNotes                 xml,
          @vOrderInfoXML             TXML,
          @vUnitsToPack              TQuantity,
          @vActivityLogId            TRecordId,
          @vNotes                    TXML,
          @vNotesXML                 TXML,
          @vSuccessMessage           TMessage;

  declare @ttNotesToPrint Table(
    EntityId                 Integer,
    EntityKey                varchar(50),
    Note                     varchar(max),
    RecordId                 Integer        Identity(1,1));
begin /* pr_AMF_Packing_BuildPackInfo */

  /* Build temporary table */
  select * into #NotesToPrint from @ttNotesToPrint;

  /* Build xml for V2 proc */
  select @vrfcProcInputxml = (select 'OrderId' Name, @OrderId Value
                              for Xml Raw('ParamInfo'), elements XSINIL, Root('InputParams'));

  /* create the return table from vwOrderToPackDetails structure */
  if object_id('tempdb..#PackingDetails') is null
    select * into #PackingDetails from vwOrderToPackDetails where 1 = 2;

  /* Call the V2 proc which would provide the Details to pack in the # table created above */
  exec pr_Packing_GetDetailsToPack @vrfcProcInputxml;

  /* Form the XML to show the details of items to be packed */
  set @vxmlPackDetails = (select coalesce(DisplaySKU, SKU) DisplaySKU, coalesce(DisplaySKUDesc, SKUDesc) SKUDesc,
                                 SKU2Desc, LPN, PickedQuantity, 0 as PackedQuantity, UnitWeight,
                                 UPC, SKUBarcode, AlternateSKU, SKU1, SKU2, SKU3, SKU4, SKU5, SKUId, SKU,
                                 OrderId, OrderDetailId, LPNId, LPNDetailId, '' SKUImageURL
                          from #PackingDetails PackDetail
                          order by SKUSortOrder, SKU
                          FOR XML AUTO, ELEMENTS XSINIL, ROOT('PACKDETAILS'));

  /* Get the sun of units picked */
  select @vUnitsToPack = sum(PickedQuantity)
  from #PackingDetails;

  /* Fetch all the order related info */
  select @vxmlOrderInfo = (select OrderId, SalesOrder, PickTicket, OrderType, Status, OrderStatus,
                                  OrderTypeDescription, StatusDescription, CustomerName,
                                  ShipToId, ShipToName, ShipVia, CustPO, ShipToCityStateZip,
                                  ShipToAddressLine1, ShipToCity, ShipToState, ShipToCountry,
                                  ShipToZip, MarkForAddress, ShipToStore, DesiredShipDate, CancelDate
                           from vwOrderHeaders
                           where (OrderId = @OrderId)
                           for xml raw('OrderInfo'), Elements);

  select @vOrderInfoXML = '';
  with FlatXML as
  (
    select dbo.fn_XMLNode('PackInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlOrderInfo.nodes('/OrderInfo/*') as t(c)
  )
  select @vOrderInfoXML = @vOrderInfoXML + DetailNode from FlatXML;

  -- select @vShipViaDesc
  -- from vwShipVias
  --   where (...)

  -- also need to show the total unit of the order and units already packed in the summary of the data table

  if (@vUnitsToPack > 0)
    begin
      /* Get the PackingNotes to display */
      insert into #NotesToPrint(Note)
        select Note from dbo.fn_Notes_GetNotesForPT(@OrderId, null /* SoldToId */, null/* ShipToId */,
                                                    null /* Operation */, @BusinessUnit, @UserId);

      select @vNotesXML = (select Note
                           from #NotesToPrint
                           for xml path('DETAILS'), root('NOTES'));
    end

  select @DataXML = dbo.fn_XMLNode('Data', dbo.fn_XMLNode('OrderId',              @OrderId) +
                                           dbo.fn_XMLNode('PickTicket',           @PickTicket) +
                                           dbo.fn_XMLNode('UnitsToPack',          @vUnitsToPack) +
                                           coalesce(@vNotesXML, '') +
                                           @vOrderInfoXML + convert(varchar(max), @vxmlPackDetails));

end /* pr_AMF_Packing_BuildPackInfo */

Go

