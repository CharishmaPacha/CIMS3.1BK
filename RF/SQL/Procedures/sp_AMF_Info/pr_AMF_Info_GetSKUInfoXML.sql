/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/09  RIA     pr_AMF_Info_GetSKUInfoXML: Added (CIMSV3-1108)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Info_GetSKUInfoXML') is not null
  drop Procedure pr_AMF_Info_GetSKUInfoXML;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Info_GetSKUInfoXML: In V3, we display lot of info in several
    screens and we do not want to depend upon V2 returning the same, so we have
    to fetch all necessary info for presentation
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Info_GetSKUInfoXML
  (@SKUId               TRecordId,
   @IncludeSKUDetails   TFlags = 'N',
   @Operation           TOperation = null,
   @SKUInfoXML          TXML       = null output, -- var char in XML format
   @SKUDetailsXML       TXML       = null output,
   @xmlSKUInfo          xml        = null output,
   @xmlLocationDetails  xml        = null output
   ) -- true xml data type
as
  declare @vRecordId          TRecordId,
          @vxmlSKUInfo        xml,
          @vxmlSKUDetails     xml;
begin /* pr_AMF_Info_GetSKUInfoXML */

  /* Delete if there are any existing records from hash tables */
  delete from #DataTableSKUDetails;

  /* Capture SKU Information */
  select @vxmlSKUInfo = (select SKUId, SKU, Status, StatusDescription,
                                SKU1, SKU2, SKU3, SKU4, SKU5, UPC, Barcode,
                                Description, SKU1Description, SKU2Description,
                                SKU3Description, SKU4Description, SKU5Description,
                                DisplaySKU, DisplaySKUDesc, SKUImageURL,
                                InnerPacksPerLPN, UnitsPerInnerPack, UnitsPerLPN,
                                cast(UnitWeight as decimal(10, 4)) UnitWeight, cast(UnitLength as decimal(6, 2)) UnitLength,
                                cast(UnitWidth as decimal(6, 2)) UnitWidth, cast(UnitHeight as decimal(6, 2)) UnitHeight,
                                cast(UnitVolume as decimal(10, 4)) UnitVolume, UnitDimensions, UnitPrice, UnitCost,
                                UoM, InventoryUoM, ProdCategory, ProdCategoryDesc,
                                ProdSubCategory, ProdSubCategoryDesc, PutawayClass,
                                PutawayClassDesc, PutawayClassDisplayDesc, ABCClass,
                                ReplenishClass, ReplenishClassDesc, ReplenishClassDisplayDesc,
                                PrimaryLocationId, PrimaryLocation, Ownership, BusinessUnit,
                                CreatedDate, ModifiedDate, CreatedBy, ModifiedBy
                         from vwSKUs
                         where (SKUId = @SKUId)
                         for xml raw('SKUInfo'), Elements);

  select @SKUInfoXML = '';
  with FlatXML as
  (
    select dbo.fn_XMLNode('SKUInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlSKUInfo.nodes('/SKUInfo/*') as t(c)
  )
  select @SKUInfoXML = @SKUInfoXML + DetailNode from FlatXML;

  select @xmlSKUInfo = convert(xml, @SKUInfoXML);

  /* Get the SKUs in the Location/LPN with Details */
  --if (@IncludeSKUDetails = 'Y')
  --  select @vxmlSKUDetails = (select LPN, SKU, SKUDescription, Quantity,
  --                                   SKU1, SKU2, SKU3, SKU4, SKU5
  --                            from vwLPNDetails
  --                            where (SKUId = @SKUId)
  --                            for Xml Raw('SKUDetail'), elements XSINIL, Root('SKUDetails'));

  --select @SKUDetailsxml = coalesce(convert(varchar(max), @vxmlSKUDetails), '');
end /* pr_AMF_Info_GetSKUInfoXML */

Go

