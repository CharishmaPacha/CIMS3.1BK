/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/14  RIA     pr_AMF_Info_GetOutstandingPicks: Added HasOutStandingPicks (BK-587)
  2020/09/04  TK      pr_AMF_Info_GetOutstandingPicks: Changes to display orders violating ship complete rules (HA-1175)
  2020/06/01  RIA     pr_AMF_Info_GetOutstandingPicks: Changes to get PickList for other than carts (HA-649)
  pr_AMF_Info_GetOutstandingPicks, pr_AMF_Info_GetTaskInfoXML: Changes to get PalletType (HA-649)
  2019/11/05  RIA     pr_AMF_Info_GetOutstandingPicks: Made changes for Replenish picking (CID-836)
  2019/07/24  RIA     pr_AMF_Info_GetOutstandingPicks: Changes to consider pick to cart wave type (OB2-885)
  2019/06/18  RIA     Added : pr_AMF_Info_GetOutstandingPicks (CID-589)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Info_GetOutstandingPicks') is not null
  drop Procedure pr_AMF_Info_GetOutstandingPicks;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Info_GetOutstandingPicks: In V3, we display lot of info in several
    screens and we do not want to depend upon V2 returning the same, so we have
    to fetch all necessary info for presentation
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Info_GetOutstandingPicks
  (@TaskId       TRecordId,
   @TaskInfoXML  TXML       = null output, -- var char in XML format
   @xmlTaskInfo  XML        = null output) -- true xml data type
as
  declare @vRecordId               TRecordId,
          @vOutstandingPicksxml    xml,
          @vDisQualifiedOrdersxml  xml,

          @vLPNId                  TRecordId,
          @vLPN                    TLPN,
          @vPalletId               TRecordId,
          @vPallet                 TPallet,
          @vWaveType               TDescription,
          @vPalletType             TTypeCode;

begin /* pr_AMF_Info_GetOutstandingPicks */

  /* Fetch the PalletId and WaveType */
  select @vPalletId = PalletId,
         @vWaveType = WaveType
  from vwTasks
  where TaskId = @TaskId;

  /* Fetch the PalletType */
  select @vPalletType = PalletType
  from Pallets
  where PalletId = @vPalletId;

  /* For other than carts, build the picklist to show as the remaining picks */
  if (@vPalletType not like 'C%')
    begin
      /* Build Pick List */
      select @xmlTaskInfo = (select top 30
                                    case when min(LOC.LocationType) = 'K' then min(L.Location)        -- picking from picklane
                                         when min(TD.PickType) = 'L' then L.LPN                -- for LPN Pick, just show LPN
                                         else coalesce(min(L.Location) + ' / ', '') + L.LPN    -- case/unit picking from Reserve/Bulk, show Location/LPN
                                    end                                         Location, /* Need to show the PickList info by LPN */
                                    min(LOC.PickingZone)                        PickZone,
                                    S.SKU                                       SKU,
                                    min(S.Description)                          SKUDesc,
                                    count(*)                                    NumPicks,
                                    sum(TD.InnerPacks)                          TotaLIPs,
                                    sum(TD.Quantity)                            TotalQty,
                                    sum(TD.InnerPacks - TD.InnerPacksCompleted) IPsToPick,
                                    nullif(sum(TD.UnitsToPick), 0)              UnitsToPick
                             from TaskDetails TD
                               join SKUs S on TD.SKUId = S.SKUId
                               join LPNs L on TD.LPNId = L.LPNId
                               join Locations Loc on LOC.LocationId = TD.LocationId
                             where (TD.TaskId = @TaskId) and
                                   (TD.Status not in ('C', 'X' /* Cancelled */))
                             group by LOC.PickPath, L.LPN, S.SKUSortOrder, S.SKU
                             order by LOC.PickPath, L.LPN, S.SKUSortOrder, S.SKU
                             for xml raw('PICKLISTDTL'), elements, root('PICKLIST'));
    end
  else
  /* For PTS, get the picks by PickPosition */
  if (@vWaveType in ('PTS'))
    begin
      /* Get Outstanding picks xml */
      select @vOutstandingPicksxml = (select PickTicket, coalesce(PickPosition, Templabel, '') PickPosition, TaskDetailStatusDesc, sum(UnitsToPick) UnitsToPick
                                      from vwPickTasks
                                      where (TaskId = @TaskId) and TaskDetailStatus not in ('C' , 'X')
                                      group by PickTicket, coalesce(PickPosition, Templabel, ''), TaskDetailStatusDesc
                                      for Xml Raw('TaskDetail'), elements XSINIL, Root('OUTSTANDINGPICKS'));

      /* Get Disqualified orders to ship xml */
      select @vDisQualifiedOrdersxml = (select distinct OH.PickTicket, TD.PickPosition as Position, OH.NumUnits, OH.UnitsAssigned, OH.ShipCompletePercent
                                        from OrderHeaders OH
                                          join TaskDetails TD on (OH.OrderId = TD.OrderId)
                                        where (TD.TaskId = @TaskId) and
                                              (dbo.fn_OrderHeaders_OrderQualifiedToShip(OH.OrderId, null, default /* Validation Flags */)  = 'N')
                                        for Xml Raw('TaskDetail'), elements XSINIL, Root('DISQUALIFIEDORDERS'))

      /* Combine XMLs */
      select @xmlTaskInfo = cast(coalesce(@vOutstandingPicksxml, '') as varchar(max)) +
                            cast(coalesce(@vDisQualifiedOrdersxml, '') as varchar(max)) +
                            dbo.fn_XMLNode('ShowOutstandingPicks', case when @vOutstandingPicksxml is not null then 'Y' else 'N' end) +
                            dbo.fn_XMLNode('HasDisqualifiedOrders', case when @vDisQualifiedOrdersxml is not null then 'Y' else 'N' end)  -- This is used to hide or display Disqualified orders grid in drop pallet screen
    end
  else
  /* For PTC, show the Totes and their respective positions */
  if (@vWaveType in ('PTC','PC'))
    begin
      /* For PTC Cart, we have to show all the Totes/Cart Positions the Order is in */
      select @vOutstandingPicksxml = (select PT.PickTicket, replace(right(L.LPN + ' @ ' + coalesce(replace(right(L.AlternateLPN, 3), '-', ''), ''),1),'@','') PickPosition,
                                             PT.TaskDetailStatusDesc,
                                             case when PT.TaskDetailStatusDesc = 'Completed' then sum(PT.UnitsCompleted) else sum(PT.UnitsToPick) end UnitsDisplay
                                      from vwPickTasks PT
                                        left outer join LPNs L on (PT.OrderId = L.OrderId) and (PT.PalletId = L.PalletId) and (PT.TaskDetailStatus = 'C')
                                      where (PT.TaskId = @TaskId) and (PT.TaskDetailstatus not in ('X')) and
                                            /* Order still has some outstanding picks */
                                            (PT.OrderId in (select distinct OrderId from TaskDetails where TaskId = @TaskId and Status not in ('C', 'X')))
                                      group by PT.PickTicket, L.LPN, L.AlternateLPN, PT.TaskDetailStatusDesc
                                      for Xml Raw('TaskDetail'), elements XSINIL, Root('OUTSTANDINGPICKS'));

      select @xmlTaskInfo = cast(coalesce(@vOutstandingPicksxml, '') as varchar(max)) +
                            dbo.fn_XMLNode('ShowOutstandingPicks', case when @vOutstandingPicksxml is not null then 'Y' else 'N' end);
    end

  select @TaskInfoXML = convert(varchar(max), @xmlTaskInfo);
end /* pr_AMF_Info_GetOutstandingPicks */

Go

