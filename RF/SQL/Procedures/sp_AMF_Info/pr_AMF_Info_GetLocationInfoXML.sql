/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/14  RIA     pr_AMF_Info_GetLocationInfoXML, pr_AMF_Info_GeLPNInfoXML: Changes to build DataTable from separate procedures (HA-2938)
  2021/06/21  RIA     pr_AMF_Info_GetLocationInfoXML: Changes to get numrows (HA-2878)
  2021/05/20  RIA     pr_AMF_Info_GetLocationInfoXML: Changes to get each available line (OB2-1764)
  2021/04/19  RIA     pr_AMF_Info_GetLocationInfoXML: Changes to update ReservedQty in Quantity2 field (OB2-1767)
  2021/03/07  RIA     pr_AMF_Info_GetLocationInfoXML: Changes to build datatable with only 10 records for ManagePicklane (HA-1688)
  2020/12/16  RIA     pr_AMF_Info_GetLocationInfoXML, pr_AMF_Info_GetLPNInfoXML: Changes to include LPNDetailId (CIMSV3-1236)
  2020/09/03  RIA     pr_AMF_Info_GetLocationInfoXML: Changes to fetch min and max quantities and not show reserved lines for AdjustQty (OB2-1199)
  2020/08/25  RIA     pr_AMF_Info_GetLocationInfoXML: Included NumPallets and LastCycleCounted (CIMSV3-773)
  2020/08/20  RIA     pr_AMF_Info_GetLocationInfoXML: Changes to fetch the label code (HA-527)
  2020/07/30  RIA     pr_AMF_Info_GetLocationInfoXML: Changes to send SKUId and LPNId (HA-652)
  2020/07/24  RIA     pr_AMF_Info_GetLocationInfoXML, pr_AMF_Info_GetLPNInfoXML: Changes to not show reserved lines (OB2-1199)
  2020/06/26  RIA     pr_AMF_Info_GetLocationInfoXML: Changes to send 0 if Min/Max Replenish does not have values (HA-998)
  2020/05/15  RIA     pr_AMF_Info_GetLocationInfoXML, pr_AMF_Info_GetLPNInfoXML: Get DisplaySKU and DisplaySKUDesc (HA-431)
  2020/05/04  RIA     pr_AMF_Info_GetLocationInfoXML, pr_AMF_Info_GetLPNInfoXML: Changes to get values from LPNDetails (CIMSV3-756)
  2019/11/20  RIA     pr_AMF_Info_GetLocationInfoXML: Minor changes (CIMSV3-647)
  2019/10/20  RIA     Added: pr_AMF_Info_GetLocationInfoXML (CID-1080)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Info_GetLocationInfoXML') is not null
  drop Procedure pr_AMF_Info_GetLocationInfoXML;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Info_GetLocationInfoXML: Gets all the information about a
    Location to be used in several functions like Location Inquiry, Manage Picklane
    etc.

  The details to be returned may vary depending upon the request. Currently supported
  options for IncludeLocDetails are
  None:       No details are returned
  LPNList:    To show the List of LPNs in the Location (show SKU = multiple if it is a multi SKU LPN)
  LPNDetails: To show the list of LPNDetails for all LPNs in the Location (Suitable for picklanes)
  SKUOnhand:  To summarize by SKU & Onhandstatus (but listing available lines)
  SKU-Pallet: To summarize by SKU & Pallet
  LPN-SKU:    To summarize by LPN & SKU (collapsing multiple Reserved lines)
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Info_GetLocationInfoXML
  (@LocationId          TRecordId,
   @IncludeLocDetails   TFlags     = null,
   @Operation           TOperation = null,
   @LocationInfoXML     TXML       = null output, -- var char in XML format
   @LocationDetailsXML  TXML       = null output,
   @xmlLocationInfo     XML        = null output,
   @xmlLocationDetails  XML        = null output
   ) -- true xml data type
as
  declare @vRecordId          TRecordId,
          @vxmlLocationInfo   xml,
          @vxmlLocLPNs        xml,
          @vxmlLocSKUDetails  xml,
          @vSKUId             TRecordId,
          @vLPNQuantity       TQuantity,
          @vReservedQty       TQuantity,
          @vDirectedQty       TQuantity,
          @vSKU               TSKU,
          @vDisplaySKU        TSKU,
          @vBusinessUnit      TBusinessUnit,
          @vDisplaySKUDesc    TDescription,
          @vRowsToSelect      TInteger,

          @vNumLines          TCount,
          @vTotalLPNs         TCount,
          @vInventoryUoM      TUoM;
begin /* pr_AMF_Info_GetLocationInfoXML */

  /* Delete if there are any existing records from hash tables */
  delete from #DataTableSKUDetails;

  /* Get the Quantity, ReservedQty and DirectedQty Information */
  select @vTotalLPNs   = count(*),
         @vLPNQuantity = sum(Quantity),
         @vReservedQty = sum(ReservedQty),
         @vDirectedQty = sum(DirectedQty),
         @vSKUId       = min(SKUId) -- used only when it is a single SKU Location
  from LPNs
  where (LocationId = @LocationId) and (Status <> 'I');

  /* Get the BusinessUnit */
  select @vBusinessUnit = BusinessUnit
  from Locations
  where (LocationId = @LocationId);

  /* fetch SKU & Inventory UoM, which are for a single SKU Location
     For multi-SKU Location, these are invalid and would be overwritten on user scanning the SKU */
  select @vSKU            = SKU,
         @vInventoryUoM   = InventoryUoM,
         @vDisplaySKU     = DisplaySKU,
         @vDisplaySKUDesc = DisplaySKUDesc
  from SKUs
  where (SKUId = @vSKUId);

  /* Capture Location Information */
  select @vxmlLocationInfo = (select LocationId, Location, LocationType, LocationTypeDesc,
                                     LocationStatus, LocationStatusDesc,
                                     StorageType, LocationSubType, StorageTypeDesc,
                                     NumPallets, NumLPNs, InnerPacks, Quantity, NumLPNs as NumSKUs,
                                     coalesce(MinReplenishLevel, 0) MinReplenishLevel,
                                     coalesce(MaxReplenishLevel, 0) MaxReplenishLevel, ReplenishUOM,
                                     AllowMultipleSKUs, @vReservedQty as ReservedQty,
                                     @vDirectedQty as DirectedQty, PickingZone, PutawayZone,
                                     PickingZoneDesc, PutawayZoneDesc, @vInventoryUoM as InventoryUoM,
                                     'Location' as EntityType, @vSKU as SKU, Warehouse,
                                     @vDisplaySKU as DisplaySKU, @vDisplaySKUDesc as DisplaySKUDesc,
                                     LastCycleCounted
                              from vwLocations
                              where (LocationId = @LocationId)
                              for xml raw('LocationInfo'), Elements);

  select @LocationInfoXML = '';
  with FlatXML as
  (
    select dbo.fn_XMLNode('LocationInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlLocationInfo.nodes('/LocationInfo/*') as t(c)
  )
  select @LocationInfoXML = @LocationInfoXML + DetailNode from FlatXML;

  select @xmlLocationInfo = convert(xml, @LocationInfoXML);

  -- /* If include details is passed then use it */
  -- if (@IncludeLocDetails <> 'None')
  --   select @vDetailLevel = @IncludeLocDetails;
  -- else
  --   /* get the value of detail level if set in controls */
  --   select @vDetailLevel = dbo.fn_Controls_GetAsString('DT_'+ @Operation, 'DetailLevel', 'None', @vBusinessUnit, null /* UserId */);

  /* Build the Data table */
  exec pr_AMF_DataTableSKUDetails_Build @LocationId, null /* LPNId */, @IncludeLocDetails, @Operation,
                                        null /* SKU */, @vBusinessUnit, @LocationDetailsXML out, @xmlLocationDetails out;

end /* pr_AMF_Info_GetLocationInfoXML */

Go

