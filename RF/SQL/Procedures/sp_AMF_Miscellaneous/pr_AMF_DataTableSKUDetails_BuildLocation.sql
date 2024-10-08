/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/23  RIA     Added: pr_AMF_DataTableSKUDetails_Build, pr_AMF_DataTableSKUDetails_BuildLocation, pr_AMF_DataTableSKUDetails_BuildLPN (HA-2878)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_DataTableSKUDetails_BuildLocation') is not null
  drop Procedure pr_AMF_DataTableSKUDetails_BuildLocation;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_DataTableSKUDetails_BuildLocation: For several operations, where
    we are operating against a Location, we would need to show the contents of the
    Location as well and this procedure builds the DataTableSKUDetails for the
    Location at the given detail level and returns the xml.

  DetailLevel: LPNList    - List of LPNs in the Location - use for LPN storage locations
               SKUDetails - LPN Details in the Location - used for Picklanes
               SKUOnhand  - Summarize by SKU and OnhandStatus (collapsing Reserved/Unavaiable lines)
                            used primarily for Adjustments/Transfers as R/U lines cannot be touched
               SKU-Pallet - Summarized by SKU & Pallet - usage?
               LPN-SKU    - Summarized by LPN & SKU

  SKUFilter : This is the filter given by user and we only return the SKUs that
              match this filter.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_DataTableSKUDetails_BuildLocation
  (@LocationId          TRecordId,
   @DetailLevel         TFlags     = null,
   @Operation           TOperation,
   @RowsToSelect        TInteger,
   @SKUFilter           TSKU,
   @BusinessUnit        TBusinessUnit,
   @LocationDetailsXML  TXML       = null output
   )
as
  /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TDescription,
          @vMessage                  TMessage,
          @vxmlInput                 xml,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vxmlLocLPNs               xml,
          @vxmlLocSKUDetails         xml,
          @vLocationDetailsXML       TXML,
          @vSKUId                    TRecordId,
          @vSKUSearch                TSKU;
begin /* pr_AMF_DataTableSKUDetails_BuildLocation */

  /* Build Search SKU to use it while fetching the details */
   select @vSKUSearch = coalesce('%'+ @SKUFilter, '') + '%';

  /* Get the LPNs in the Location with SKU Details */
  if (@DetailLevel = 'LPNList')
    begin
      select @vxmlLocLPNs = (select top (@RowsToSelect)
                                    LPN, SKU, dbo.fn_AppendStrings(SKUDescription, ' / ', InventoryClass1) SKUDescription, Quantity,
                                    SKU1, SKU2, SKU3, SKU4, SKU5,
                                    InventoryClass1, InventoryClass2, InventoryClass3,
                                    LPNId, SKUId, Pallet, UPC
                             from vwLPNs
                             where (LocationId = @LocationId) and
                                   ((SKU1 like @vSKUSearch) or (SKU2 like @vSKUSearch) or
                                    (SKU like @vSKUSearch) or (SKUDescription like @vSKUSearch))
                             order by LPN, SKUSortOrder
                             for Xml Raw('LPN'), elements XSINIL, Root('LOCLPNS'));
    end

  /* SKU Details is typically used for Picklanes to show all the SKUs in the Location */
  if (@DetailLevel = 'SKUDetails')
    begin
      /* insert values into hash table */
      insert into #DataTableSKUDetails (SKUId, InventoryClass1, InventoryClass2, InventoryClass3,
                                        InnerPacks, Quantity, Quantity2,
                                        UnitsPerInnerPack, InnerPacksPerLPN, UnitsPerLPN,
                                        AvailableQty, ReservedQty, LPNDetailId)
        select top (@RowsToSelect) LD.SKUId, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3,
               LD.InnerPacks, LD.Quantity, LD.ReservedQty,
               coalesce(LD.UnitsPerPackage, 0) UnitsPerInnerPack,
               coalesce(LD.InnerPacks, 0) InnerPacksPerLPN,
               coalesce(LD.Quantity, 0) UnitsPerLPN,
               LD.AllocableQty, LD.ReservedQty, LD.LPNDetailId
        from LPNs L
          join LPNDetails LD on LD.LPNId = L.LPNId
          left outer join SKUs S on S.SKUId = LD.SKUId
        where (L.LocationId = @LocationId) and
              ((S.SKU1 like @vSKUSearch) or (S.SKU2 like @vSKUSearch) or
               (S.SKU like @vSKUSearch) or (S.Description like @vSKUSearch))
        order by L.LPN;
    end

  /* List out the available LPN details in the Location and sum up the remaining lines to show the reservations
       but not confirmed - used for Location Adjustment, Transfers */
  if (@DetailLevel = 'SKUOnhand')
    begin
      /* Get summary by SKU & Inventory classes */
      insert into #DataTableSKUDetails (SKUId, InventoryClass1, InventoryClass2, InventoryClass3,
                                        InnerPacks, Quantity, ReservedQty, Quantity1,
                                        UnitsPerInnerPack, InnerPacksPerLPN, LPNDetailId)
        select top (@RowsToSelect) LD.SKUId, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3,
               sum(LD.InnerPacks),
               sum(case when LD.OnhandStatus in ('A', 'R') then (LD.Quantity) else 0 end),  -- Actual Qty in Location
               sum(LD.ReservedQty),                                                         -- ReservedQty
               sum(case when LD.OnhandStatus = 'R' then (LD.Quantity) else 0 end),          -- Hard ReservedQty
               coalesce(LD.UnitsPerPackage, 0),                                             -- UnitsPerInnerPack
               coalesce(LD.InnerPacks, 0), min(LD.LPNDetailId)
        from LPNs L
          join LPNDetails LD on LD.LPNId = L.LPNId
          left outer join SKUs S on S.SKUId = LD.SKUId
        where (L.LocationId = @LocationId) and (LD.Onhandstatus <> 'PR') and
              ((S.SKU1 like @vSKUSearch) or (S.SKU2 like @vSKUSearch) or
               (S.SKU like @vSKUSearch) or (S.Description like @vSKUSearch))
         group by LD.SKUId, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3, LD.UnitsPerPackage, LD.InnerPacks,
                  case when LD.Onhandstatus = 'A' then LPNDetailId else null end;

      update #DataTableSKUDetails
        set UnitsPerLPN = Quantity,    -- doing this as we are using this as input qty for user
            Quantity2   = ReservedQty,
            MinQty      = Quantity1,   -- The hard reserved qty is the MinQty in case of Adjustment/Transfers
            MaxQty      = 99999;       -- this will be used as max qty
    end

  /* summarize inventory in Location by SKU and Pallet */
  if (@DetailLevel = 'SKU-Pallet')
    begin
      /* Get summary by SKU-IC and then update with all SKU info */
      insert into #DataTableSKUDetails (SKUId, InventoryClass1, Pallet,
                                        InnerPacks, Quantity, ReservedQty, NumLPNs, NumPallets)
        select top (@RowsToSelect) LD.SKUId, L.InventoryClass1, L.Pallet,
               sum(LD.InnerPacks), sum(LD.Quantity), sum(LD.ReservedQty), count(distinct L.LPNId), count(distinct L.PalletId)
        from LPNs L
          join LPNDetails LD on LD.LPNId = L.LPNId
          left outer join SKUs S on S.SKUId = LD.SKUId
        where (L.LocationId = @LocationId) and
              ((S.SKU1 like @vSKUSearch) or (S.SKU2 like @vSKUSearch) or
               (S.SKU like @vSKUSearch) or (S.Description like @vSKUSearch))
         group by LD.SKUId, L.InventoryClass1, L.Pallet;

      /* doing this to show the info in data table, so that we need not hide most of the fields */
      update #DataTableSKUDetails
      set Quantity2   = ReservedQty
    end

  /* summarize inventory in Location by LPN & SKU */
  if (@DetailLevel = 'LPN-SKU')
    begin
      insert into #DataTableSKUDetails (SKUId, LPN, Pallet, Quantity, ReservedQty)
        select top (@RowsToSelect) LD.SKUId, L.LPN, min(coalesce(L.Pallet, '')), sum(LD.Quantity), sum(LD.ReservedQty)
        from LPNs L
          join LPNDetails LD on L.LPNId = LD.LPNId
          left outer join SKUs S on S.SKUId = LD.SKUId
        where (L.LocationId = @LocationId) and
              ((S.SKU1 like @vSKUSearch) or (S.SKU2 like @vSKUSearch) or
               (S.SKU like @vSKUSearch) or (S.Description like @vSKUSearch))
         group by L.LPN, LD.SKUId;

      /* doing this to show the info in data table, so that we need not hide most of the fields */
      update #DataTableSKUDetails
      set Quantity2   = ReservedQty
    end

  /* When SKU is passed and no data set is built */
  if ((@SKUFilter is not null) and
      ((not exists (select * from #DataTableSKUDetails)) and (@vxmlLocLPNs is null)))
    set @vMessageName = 'AMF_NoMatchingItemsForFilteredValue';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    exec pr_Messages_ErrorHandler @vMessageName;

  /* Fill in the SKU related info in the data table */
  if (exists (select * from #DataTableSKUDetails))
    exec pr_AMF_DataTableSKUDetails_UpdateSKUInfo;

  if (@DetailLevel in ('SKUDetails', 'SKUOnhand'))
    select @vxmlLocSKUDetails = (select * from #DataTableSKUDetails
                                 for Xml Raw('LPN'), elements XSINIL, Root('SKUDETAILS'));
  else
  /* Typically used with Reserve Locations */
  if (@DetailLevel in ('SKU-Pallet', 'LPN-SKU'))
    select @vxmlLocSKUDetails = (select LPN, DisplaySKU, DisplaySKUDesc,
                                        Quantity, ReservedQty, NumLPNs, Pallet
                                 from #DataTableSKUDetails
                                 for Xml Raw('LPN'), elements XSINIL, Root('SKUDETAILS'));

  select @LocationDetailsxml = coalesce(convert(varchar(max), @vxmlLocLPNs),
                                        convert(varchar(max), @vxmlLocSKUDetails), '');
end /* pr_AMF_DataTableSKUDetails_BuildLocation */

Go

