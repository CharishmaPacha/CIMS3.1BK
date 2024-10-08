/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/04  MS      pr_AMF_Info_GetPalletInfoXML: Made changes to show values in UDF on RF Screen (JL-289)
  2020/07/10  RIA     pr_AMF_Info_GetPalletInfoXML: Included DisplaySKU, DisplaySKUDesc (HA-426)
  2020/05/07  RIA     pr_AMF_Info_GetPalletInfoXML: Build the SKU info (CIMSV3-623)
  2019/11/17  AY      pr_AMF_Info_GetPalletInfoXML: Retrieve distinct counts on Pallet
  2019/10/14  RIA     pr_AMF_Info_GetPalletInfoXML: Changes to show DestZone, NumLPNsWithQty (CID-911)
  2019/09/17  VS      pr_AMF_Info_GetPalletInfoXML: Show the Location based on Putawaypath (CID-1039)
  2019/08/14  RIA     pr_AMF_Info_GetPalletInfoXML: Changes to return putaway list (CID-910)
  2019/08/12  RIA     Added: pr_AMF_Info_GetPalletInfoXML (CID-911)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Info_GetPalletInfoXML') is not null
  drop Procedure pr_AMF_Info_GetPalletInfoXML;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Info_GetPalletInfoXML: In V3, we display lot of info in several
    screens and we do not want to depend upon V2 returning the same, so we have
    to fetch all necessary info for presentation
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Info_GetPalletInfoXML
  (@PalletId               TRecordId,
   @IncludePalletDetails   TFlags = 'L',
   @Operation              TOperation = null,
   @PalletInfoXML          TXML       = null output, -- var char in XML format
   @PalletDetailsXML       TXML       = null output,
   @xmlPalletInfo          XML        = null output,
   @xmlPalletDetails       XML        = null output
   ) -- true xml data type
as
  declare @vRecordId          TRecordId,
          @vNumLPNsWithQty    TCount,
          @vSKUCount          TCount,
          @vOrderCount        TCount,

          @vLPNsIntransit     TCount,
          @vLPNsReceived      TCount,
          @vxmlPalletInfo     xml;

begin /* pr_AMF_Info_GetPalletInfoXML */

  /* Get the NumLPNs count having quantity */
  select @vNumLPNsWithQty = count(*),
         @vLPNsIntransit  = sum(case when Status = 'T' then 1 else 0 end),
         @vLPNsReceived   = sum(case when Status <> 'T' then 1 else 0 end)
  from LPNs
  where (PalletId = @PalletId) and (Quantity > 0);

  /* Get Stats */
  if (charindex('C' /* counts */, @IncludePalletDetails) > 0)
    select @vSKUCount   = count(distinct LD.SKUId),
           --@vLPNCount   = count(distinct LPNId), should be same as @vNumLPNsWithQty above
           --@vTotalQty   = sum(Quantity), should be same as Pallet.Quantity retrieved below
           @vOrderCount = count(distinct LD.OrderId)
    from LPNs L join LPNDetails LD on L.LPNId = LD.LPNId
    where (L.PalletId = @PalletId);

  /* Capture Pallet Information */
  select @vxmlPalletInfo = (select PalletId, Pallet, Status PalletStatus, StatusDesc PalletStatusDesc,
                                   coalesce(Location, 'None') Location, NumLPNs, @vNumLPNsWithQty as NumLPNsWithQty, Quantity,
                                   ReceiptNumber, ReceiverNumber,
                                   PickTicket, OrderId, SalesOrder, PickBatchNo WaveNo,
                                   case when Quantity > 0 and SKU is null then 'Multiple' else SKU end SKU,
                                   SKUDescription, UPC, SKU1, SKU2, SKU3, SKU4,
                                   DisplaySKU, DisplaySKUDesc,
                                   @vSKUCount SKUCount, @vOrderCount OrderCount, Warehouse,
                                   coalesce(@vLPNsIntransit, 0) LPNsIntransit, coalesce(@vLPNsReceived, 0) LPNsReceived,
                                   DestZone, DestLocation,
                                   PAL_UDF1, PAL_UDF2, PAL_UDF3, PAL_UDF4, PAL_UDF5
                            from vwPallets
                            where (PalletId = @PalletId)
                            for xml raw('PalletInfo'), Elements);

  select @PalletInfoXML = '';
  with FlatXML as
  (
    select dbo.fn_XMLNode('PalletInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlPalletInfo.nodes('/PalletInfo/*') as t(c)
  )
  select @PalletInfoXML = @PalletInfoXML + DetailNode from FlatXML;

  select @xmlPalletInfo = convert(xml, coalesce(@PalletInfoXML, ''));

  /* Get the LPNDetails */
  if (@IncludePalletDetails = 'LD')
    select @xmlPalletDetails = (select L.LPN, S.SKU, S.Description SKUDescription,
                                       LD.Quantity, LD.LPNId, LD.LPNDetailId, S.SKUId
                                from LPNDetails LD
                                  join SKUs S  on LD.SKUId = S.SKUId
                                  join LPNs L  on L.LPNId = LD.LPNId
                                  left outer join Locations LOC on LOC.LocationId = S.PrimaryLocationId
                                where (L.PalletId = @PalletId)
                                for Xml Raw('LPNDetail'), elements XSINIL, Root('PALLETLPNDETAILS'));

  /* Get the Pallet/Cart LPNs, but don't need to show empty positions */
  if (@IncludePalletDetails = 'L')
    select @xmlPalletDetails = (select LPN, SKU, SKUDescription, Quantity, replace(right(AlternateLPN, 3), '-', '') as Position,
                                       PickTicket,
                                       SKU1, SKU2, SKU3, SKU4, SKU5
                                from vwLPNs
                                where (PalletId = @PalletId) and
                                      ((LPNType  <> 'A') or (Quantity > 0))
                                order by LPN
                                for Xml Raw('LPN'), elements XSINIL, Root('PALLETLPNS'));

  select @PalletDetailsXML = coalesce(convert(varchar(max), @xmlPalletDetails), '');
end /* pr_AMF_Info_GetPalletInfoXML */

Go

