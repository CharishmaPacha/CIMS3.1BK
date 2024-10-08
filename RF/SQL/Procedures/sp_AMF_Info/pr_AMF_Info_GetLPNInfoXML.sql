/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/21  RIA     pr_AMF_Info_GetLPNInfoXML: Changes to group by onhandstatus (OB2-1768)
  2020/12/16  RIA     pr_AMF_Info_GetLocationInfoXML, pr_AMF_Info_GetLPNInfoXML: Changes to include LPNDetailId (CIMSV3-1236)
  2020/11/11  RIA     pr_AMF_Info_GetLPNInfoXML: Included LPN_UDF6, LPN_UDF10 (JL-283)
  2020/10/23  RIA     pr_AMF_Info_GetLPNInfoXML: Cleanup and called proc to update SKU related info in DataTable (CIMSV3-812)
  2020/07/24  RIA     pr_AMF_Info_GetLocationInfoXML, pr_AMF_Info_GetLPNInfoXML: Changes to not show reserved lines (OB2-1199)
  2020/05/15  RIA     pr_AMF_Info_GetLocationInfoXML, pr_AMF_Info_GetLPNInfoXML: Get DisplaySKU and DisplaySKUDesc (HA-431)
  2020/05/13  AY      pr_AMF_Info_GetROInfoXML/pr_AMF_Info_GetLPNInfoXML: Return InvClasses
  2020/05/04  RIA     pr_AMF_Info_GetLocationInfoXML, pr_AMF_Info_GetLPNInfoXML: Changes to get values from LPNDetails (CIMSV3-756)
  2019/07/02  RIA     pr_AMF_Info_GetLPNInfoXML: Changes to get PickBatchNo and other values (CID-593)
  2019/06/23  AY      pr_AMF_Info_GetLPNInfoXML: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Info_GetLPNInfoXML') is not null
  drop Procedure pr_AMF_Info_GetLPNInfoXML;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Info_GetLPNInfoXML: In V3, we display lot of info in several
    screens and we do not want to depend upon V2 returning the same, so we have
    to fetch all necessary info for presentation
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Info_GetLPNInfoXML
  (@LPNId               TRecordId,
   @IncludeLPNDetails   TFlags     = null,
   @Operation           TOperation = null,
   @LPNInfoXML          TXML       = null output, -- var char in XML format
   @LPNDetailsXML       TXML       = null output,
   @xmlLPNInfo          XML        = null output,
   @xmlLPNDetails       XML        = null output
   ) -- true xml data type
as
  declare @vRecordId          TRecordId,
          @vxmlLPNInfo        xml,
          @vSKUId             TRecordId,
          @vDisplaySKU        TSKU,
          @vDisplaySKUDesc    TDescription,
          @vBusinessUnit      TBusinessUnit,

          @vNumLines          TCount,
          @vInventoryUoM      TUoM;
begin /* pr_AMF_Info_GeLPNInfoXML */

  /* Delete if there are any existing records from hash tables */
  delete from #DataTableSKUDetails;

  select @vNumLines     = NumLines,
         @vSKUId        = SKUId, -- used only if it is a single SKU LPN
         @vBusinessUnit = BusinessUnit
  from LPNs
  where (LPNId = @LPNId);

  /* fetch Inventory UoM */
  select @vInventoryUoM   = InventoryUoM,
         @vDisplaySKU     = DisplaySKU,
         @vDisplaySKUDesc = DisplaySKUDesc
  from SKUs
  where (SKUId = @vSKUId);

  /* Capture LPN Information */
  select @vxmlLPNInfo = (select LPNId, LPN, TrackingNo, UCCBarcode, LPNType,
                                Status LPNStatus, StatusDescription as LPNStatusDesc,
                                Location, Pallet, DestZone, DestLocation, DestWarehouse, Ownership,
                                OrderId, PickTicket, ReceiptId, ReceiptNumber, ReceiverNumber,
                                SKUId, SKU, SKUDescription, UPC, @vInventoryUoM as InventoryUoM,
                                coalesce(InnerPacks, 0) InnerPacks, Quantity,
                                coalesce(UnitsPerInnerPack, 0) UnitsPerInnerPack,
                                @vNumLines NumLines, PickBatchNo WaveNo,
                                InventoryClass1, InventoryClass2, InventoryClass3,
                                LoadNumber,
                                right(LPN, 10) LPNRight10, 'LPN' as EntityType,
                                @vDisplaySKU as DisplaySKU, @vDisplaySKUDesc as DisplaySKUDesc,
                                LPN_UDF6, LPN_UDF10
                         from vwLPNs
                         where (LPNId = @LPNId)
                         for xml raw('LPNInfo'), Elements);

  select @LPNInfoXML = '';
  with FlatXML as
  (
    select dbo.fn_XMLNode('LPNInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlLPNInfo.nodes('/LPNInfo/*') as t(c)
  )
  select @LPNInfoXML = @LPNInfoXML + DetailNode from FlatXML;

  select @LPNInfoXML = coalesce(@LPNInfoXML, '');
  select @xmlLPNInfo = convert(xml, @LPNInfoXML);

  -- /* get the value of detail level if set */
  -- select @vDetailLevel = nullif(dbo.fn_Controls_GetAsString('DT_'+ @Operation, 'DetailLevel', 'N', @vBusinessUnit, null /* UserId */), 'N');
  -- select @vDetailLevel = coalesce(@vDetailLevel, @IncludeLPNDetails);

  /* Build the Data table */
  exec pr_AMF_DataTableSKUDetails_Build null /* LocationId */, @LPNId, @IncludeLPNDetails, @Operation,
                                        null /* SKU */, @vBusinessUnit, @LPNDetailsXML out, @xmLLPNDetails out;

end /* pr_AMF_Info_GetLPNInfoXML */

Go

