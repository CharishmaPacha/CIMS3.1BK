/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/24  TK      pr_AMF_Info_GetOrderInfoXML, pr_AMF_Info_GetWaveInfoXML & pr_AMF_Info_GetLPNReservationInfoXML:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Info_GetWaveInfoXML') is not null
  drop Procedure pr_AMF_Info_GetWaveInfoXML;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Info_GetWaveInfoXML: In V3, we display lot of info in several
    screens and we do not want to depend upon V2 returning the same, so we have
    to fetch all necessary info for presentation
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Info_GetWaveInfoXML
  (@WaveId                 TRecordId,
   @IncludeDetails         TFlags     = 'WD',
   @Operation              TOperation = null,
   @WaveInfoXML            TXML       = null output,
   @WaveDetailsXML         TXML       = null output,
   @xmlWaveInfo            XML        = null output,
   @xmlWaveDetails         XML        = null output)

as
  declare @vRecordId         TRecordId,
          @vxmlWaveInfo      xml,

          @vWaveId           TRecordId;
begin /* pr_AMF_Info_GetWaveInfoXML */

  /* Delete if there are any existing records from hash tables */
  delete from #DataTableSKUDetails;

  /* Capture Wave Information */
  select @vxmlWaveInfo = (select WaveId, WaveNo, WaveType, WaveTypeDesc, WaveStatusDesc,
                                 Ownership, Warehouse,
                                 Account, AccountName, SoldToName, PickTicket
                          from vwWaves
                          where (WaveId = @WaveId)
                          for xml raw('WaveInfo'), Elements);

 select @WaveInfoXML = '';
 ;with FlatXML as
  (
    select dbo.fn_XMLNode('WaveInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlWaveInfo.nodes('/WaveInfo/*') as t(c)
  )
  select @WaveInfoXML = @WaveInfoXML + DetailNode from FlatXML;

  select @xmlWaveInfo = convert(xml, coalesce(@WaveInfoXML, ''));

  /* Get the Wave Details  */
  if (@IncludeDetails = 'WD')
    begin
      insert into #DataTableSKUDetails(SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3, InnerPacks, Quantity, Quantity1, Quantity2)
        select SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3, IPsToReserve, QtyOrdered, QtyReserved, QtyToReserve
        from dbo.fn_Reservation_GetWaveInventoryInfo(@vWaveId, null, null, null, null)
        where (QtyToReserve > 0);

      update DTSD
      set DisplaySKU     = S.DisplaySKU,
          DisplaySKUDesc = S.DisplaySKUDesc,
          SortOrder      = coalesce(S.SKUSortOrder, '') + S.SKU
      from #DataTableSKUDetails DTSD join SKUs S on DTSD.SKUId = S.SKUId;

      select @xmlWaveDetails = (select *
                                from #DataTableSKUDetails
                                order by Case when Quantity > 0 then 1 else 9 end, SortOrder
                                for Xml Raw('WaveDetailRecord'), elements XSINIL, Root('WAVEDETAILS'));
    end

  select @WaveDetailsxml = coalesce(convert(varchar(max), @xmlWaveDetails), '');

end /* pr_AMF_Info_GetWaveInfoXML */

Go

