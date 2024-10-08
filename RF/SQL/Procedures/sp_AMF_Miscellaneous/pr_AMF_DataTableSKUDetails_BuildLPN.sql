/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/23  RIA     pr_AMF_DataTableSKUDetails_BuildLPN: Included onhandstatus unavailable as well for new temp LPNs (HA-2902)
  2021/06/23  RIA     Added: pr_AMF_DataTableSKUDetails_Build, pr_AMF_DataTableSKUDetails_BuildLocation, pr_AMF_DataTableSKUDetails_BuildLPN (HA-2878)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_DataTableSKUDetails_BuildLPN') is not null
  drop Procedure pr_AMF_DataTableSKUDetails_BuildLPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_DataTableSKUDetails_BuildLPN: Based on the DetailLevel passed
    we will be inserting the necessary information in DataTable and build xml accordingly
    to display  it in the screen.

  DetailLevel: LPNDetails - LPN Details in the LPN
               SKUOnhand  - Summarize by SKU and OnhandStatus (collapsing Reserved/Unavaiable lines)
                            used primarily for Adjustments/Transfers as R/U lines cannot be touched
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_DataTableSKUDetails_BuildLPN
  (@LPNId               TRecordId,
   @DetailLevel         TFlags     = null,
   @Operation           TOperation,
   @RowsToSelect        TInteger,
   @SKUFilter           TSKU,
   @BusinessUnit        TBusinessUnit,
   @LPNDetailsXML       TXML       = null output
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
  declare @vxmlLPNDetails            xml,
          @vLPNDetailsXML            TXML,
          @vLocationDetailsXML       TXML,
          @vSKUId                    TRecordId,
          @vSKUSearch                TSKU;
begin /* pr_AMF_DataTableSKUDetails_BuildLPN */

  /* Build Search SKU to use it while fetching the details */
  select @vSKUSearch = coalesce('%'+ @SKUFilter, '') + '%';

  if (@DetailLevel in ('LPNDetails'))
    begin
      /* insert values into hash table */
      insert into #DataTableSKUDetails (SKUId, InnerPacks, Quantity,
                                        UnitsPerInnerPack, InnerPacksPerLPN, UnitsPerLPN, LPNDetailId)
        select top (@RowsToSelect) S.SKUId, LD.InnerPacks, LD.Quantity,
               coalesce(LD.UnitsPerPackage, 0) UnitsPerInnerPack,
               coalesce(LD.InnerPacks, 0) InnerPacksPerLPN,
               coalesce(LD.Quantity, 0) UnitsPerLPN, LD.LPNDetailId
        from LPNDetails LD
          join SKUs S on LD.SKUId = S.SKUId
        where (LD.LPNId = @LPNId) and
              ((S.SKU1 like @vSKUSearch) or (S.SKU2 like @vSKUSearch) or
               (S.SKU like @vSKUSearch) or (S.Description like @vSKUSearch))
    end

    /* Get the summary by SKU - used for LPN Adjustment, Transfers
       Currently we are grouping this by onhandstatus. However, if LPN has multiple Available lines
       we want to show each of them, but summarize all Reserved Lines */
  if (@DetailLevel = 'SKUOnhand')
    begin
      insert into #DataTableSKUDetails (SKUId, InnerPacks, Quantity, ReservedQty, Quantity1,
                                        UnitsPerInnerPack, InnerPacksPerLPN, LPNDetailId)
        select top (@RowsToSelect) LD.SKUId, min(LD.InnerPacks),
               sum(case when LD.OnhandStatus in ('A', 'R', 'U') then (LD.Quantity) else 0 end),  -- Actual Qty
               sum(LD.ReservedQty),                                                         -- ReservedQty
               sum(case when LD.OnhandStatus = 'R' then (LD.Quantity) else 0 end),          -- Hard ReservedQty
               min(coalesce(LD.UnitsPerPackage, 0)) UnitsPerInnerPack,
               min(coalesce(LD.InnerPacks, 0)) InnerPacksPerLPN, min(LD.LPNDetailId)
        from LPNDetails LD
          join SKUs S on LD.SKUId = S.SKUId
        where (LD.LPNId = @LPNId) and
              ((S.SKU1 like @vSKUSearch) or (S.SKU2 like @vSKUSearch) or
               (S.SKU like @vSKUSearch) or (S.Description like @vSKUSearch))
        group by LD.SKUId, LD.OnhandStatus, case when LD.Onhandstatus = 'A' then LPNDetailid else null end

      update #DataTableSKUDetails
        set UnitsPerLPN = Quantity,    -- doing this as we are using this as input qty for user
            Quantity2   = ReservedQty,
            MinQty      = Quantity1,   -- The hard reserved qty is the MinQty in case of Adjustment/Transfers
            MaxQty      = 99999;       -- this will be used as max qty
    end

  /* When SKU is passed and no data set is built */
  if (@SKUFilter is not null) and (not exists (select * from #DataTableSKUDetails))
    set @vMessageName = 'AMF_NoMatchingItemsForFilteredValue';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    exec pr_Messages_ErrorHandler @vMessageName;

  /* Fill in the SKU related info in the data table */
  if (exists (select * from #DataTableSKUDetails))
    exec pr_AMF_DataTableSKUDetails_UpdateSKUInfo;

  select @vxmlLPNDetails = (select * from #DataTableSKUDetails
                            for Xml Raw('LPNDetail'), elements XSINIL, Root('LPNDETAILS'));

  select @LPNDetailsXML = coalesce(convert(varchar(max), @vxmlLPNDetails), '');
end /* pr_AMF_DataTableSKUDetails_BuildLPN */

Go

