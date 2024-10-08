/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/22  RIA     pr_AMF_Info_GetROInfoXML: Changes to get LPNsInTransit, LPNsReceived (JL-271)
  2020/09/30  RIA     pr_AMF_Info_GetROInfoXML: Cleanup and called UpdateSKUInfo proc (CIMSV3-1110)
  2020/07/20  AY      pr_AMF_Info_GetROInfoXML: Show QtyOrdered and QtyReceived
  2020/06/07  RIA     pr_AMF_Info_GetROInfoXML: Changes to insert SortOrder in temp table (HA-491)
  2020/06/05  YJ      pr_AMF_Info_GetROInfoXML: DataTableSKUDetails 'AvailableQty', 'ReservedQty' Added changes
  2020/06/03  YJ      pr_AMF_Info_GetROInfoXML: Added fields to return from xmlReceiptInfo (CIMSV3-828)
  2020/05/22  YJ      pr_AMF_Info_GetROInfoXML: Used fn_AppendStrings to bind the value of Description, InventoryClass1 with Delimiter (HA-527)
  2020/05/13  AY      pr_AMF_Info_GetROInfoXML/pr_AMF_Info_GetLPNInfoXML: Return InvClasses
  2020/05/11  RIA     pr_AMF_Info_GetROInfoXML: Changes to get SKU and Quantity to suggest to user (HA-491)
  2020/03/18  RIA     Added: pr_AMF_Info_GetROInfoXML (CIMSV3-652)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Info_GetROInfoXML') is not null
  drop Procedure pr_AMF_Info_GetROInfoXML;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Info_GetROInfoXML: In V3, we display lot of info in several
    screens and we do not want to depend upon V2 returning the same, so we have
    to fetch all necessary info for presentation. This proc returns data set needed
    for Receiving.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Info_GetROInfoXML
  (@ReceiptId           TRecordId,
   @IncludeDetails      TFlags = 'N',
   @Operation           TOperation = null,
   @ReceiptInfoXML      TXML       = null output, -- var char in XML format
   @ReceiptDetailsXML   TXML       = null output,
   @xmlReceiptInfo      XML        = null output,
   @xmlReceiptDetails   XML        = null output
   ) -- true xml data type
as
  declare @vRecordId          TRecordId,
          @vxmlReceiptInfo    xml,
          @vxmlReceiptDetails xml;
begin /* pr_AMF_Info_GetROInfoXML */

  /* Delete if there are any existing records from hash tables */
  delete from #DataTableSKUDetails;

  /* Capture Receipt Information */
  select @vxmlReceiptInfo = (select ReceiptId, ReceiptNumber, ReceiptTypeDesc, ReceiptStatusDesc,
                                    VendorId, VendorName, Ownership, Warehouse, NumLPNs, NumUnits,
                                    LPNsInTransit, UnitsInTransit, LPNsReceived, UnitsReceived, QtyToReceive,
                                    BillNo, SealNo, InvoiceNo, ContainerNo, ContainerSize, Vessel,
                                    ETAWarehouse, AppointmentDateTime, PickTicket
                             from vwReceiptHeaders
                             where (ReceiptId = @ReceiptId)
                             for xml raw('ReceiptInfo'), Elements);

  select @ReceiptInfoXML = '';
  with FlatXML as
  (
    select dbo.fn_XMLNode('ReceiptInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlReceiptInfo.nodes('/ReceiptInfo/*') as t(c)
  )
  select @ReceiptInfoXML = @ReceiptInfoXML + DetailNode from FlatXML;

  select @xmlReceiptInfo = convert(xml, @ReceiptInfoXML);

  /* Get the ReceiptDetails along with SKU info */
  if (@IncludeDetails = 'Y')
    insert into #DataTableSKUDetails (SKUId, Quantity, Quantity1, Quantity2,
                                      InventoryClass1, InventoryClass2, InventoryClass3,
                                      UnitsPerInnerPack, InnerPacksPerLPN, UnitsPerLPN,
                                      QtyOrdered, QtyReceived, SortOrder,
                                      DisplayUDF1, DisplayUDF2, DisplayUDF3)
      select S.SKUId, RD.QtyOrdered, RD.QtyReceived, RD.QtyToLabel,
             RD.InventoryClass1, RD.InventoryClass2, RD.InventoryClass3,
             coalesce(S.UnitsPerInnerPack, 0) UnitsPerInnerPack,
             coalesce(S.InnerPacksPerLPN, 0) InnerPacksPerLPN,
             coalesce(S.UnitsPerLPN, 0) UnitsPerLPN,
             QtyOrdered, QtyReceived, (coalesce(convert(varchar(20), RD.ReceiptDetailId), '') +
             coalesce(convert(varchar(20), RD.HostReceiptLine), '') + coalesce(convert(varchar(50), S.SKU), '')),
             LPNsInTransit, LPNsReceived, QtyToReceive
      from ReceiptDetails RD
        join SKUs S on RD.SKUId = S.SKUId
      where (RD.ReceiptId = @ReceiptId)
      order by RD.ReceiptDetailId, RD.HostReceiptLine, S.SKU

    /* Fill in the SKU related info in the data table */
    exec pr_AMF_DataTableSKUDetails_UpdateSKUInfo;

  select @xmlReceiptDetails = (select * from #DataTableSKUDetails
                               for Xml Raw('ReceiptDetail'), elements XSINIL, Root('ReceiptDetails'));

  select @ReceiptDetailsxml = coalesce(convert(varchar(max), @xmlReceiptDetails), '');
end /* pr_AMF_Info_GetROInfoXML */

Go

