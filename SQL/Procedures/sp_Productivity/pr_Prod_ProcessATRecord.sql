/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/08/03  MS      pr_Prod_MainProcess, pr_Prod_ProcessATRecord,
  2020/01/02  SK      pr_Prod_ProcessATRecord, pr_Prod_ProcessUserActivity: Revisions post the new design discussion (CIMS-2871)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Prod_ProcessATRecord') is not null
  drop Procedure pr_Prod_ProcessATRecord;
Go
/*------------------------------------------------------------------------------
  Proc pr_Prod_ProcessATRecord: Productivity data of a particular user and date
    would be loaded into #ProductivitySubSet and categorized into assignments.
    This proc summarizes those assignments and create productvity header for
    each assignment with the corresponding details.
------------------------------------------------------------------------------*/
Create Procedure pr_Prod_ProcessATRecord
  (@BusinessUnit   TBusinessUnit,
   @UserId         TUserId = 'cimsdba',
   @Debug          TFlags  = 'N')
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          @Message          TDescription;

  declare @ttAudits Table (AuditId     TRecordId,
                           UserId      TUserId,
                           Assignment  TDescription);

  declare @ttOrders Table (OrderId     TRecordId,
                           PickTicket  TPickTicket);

  declare @ttLPNs   Table (LPNId       TRecordId,
                           LPN         TLPN);

begin
  SET NOCOUNT ON;

  select @MessageName     = null,
         @ReturnCode      = 0;

  /* Create a temporary table with the same definition of the original table without data copy */
  select * into #Productivity from Productivity where (1 = 2);
  create index itx_ProdTemp_Key on #Productivity (UserId, Assignment, BusinessUnit);

  /* Insert Productivity Header info
     Assumptions: Each assignment would be for one Warehouse only. However each assignment may or may not
     be for same Ownership and so we just use the min of Ownership - which may not be dependable in all cases */
  insert into #Productivity (UserId, Assignment, BusinessUnit, Warehouse, Ownership, StartDateTime, EndDateTime, Operation,
                             DurationInSecs, ActivityDate)
    select  UserId, Assignment, BusinessUnit, min(Warehouse), min(Ownership), min(ActivityDateTime), max(ActivityDateTime), min(Operation),
            datediff(s, min(ActivityDateTime), max(activitydatetime)), min(ActivityDate)
    from #ProductivitySubSet
    group by UserId, Assignment, BusinessUnit
    order by UserId, Assignment, BusinessUnit;

  /* Summarize details of the Productivity header */
  insert into @ttAudits (AuditId, UserId, Assignment)
    select distinct AuditId, UserId, Assignment from #ProductivitySubSet;

  if (charindex('M', @Debug) > 0) exec pr_Markers_Save 'ProcessAudits-Inserted', @@ProcId;

  /* Aggregate with respect to AuditId */
  with cte_AuditSummary
  as (
      select TT.UserId                        as UserId,
             TT.Assignment                    as Assignment,
             count(distinct AD.WaveId)        as NumWaves,
             case when count(distinct AD.WaveId) = 1 then min(AD.WaveId) else null end
                                              as WaveId,
             count(distinct AD.OrderId)       as NumOrders,
             case when count(distinct AD.OrderId) = 1 then min(AD.OrderId) else null end
                                              as OrderId,
             count(distinct nullif(AD.Location, ''))
                                              as NumLocations, --Temp: Need to change to LocationId when all activitytypes are updated with LocationId
             case when count(distinct AD.LocationId) = 1 then min(AD.LocationId) else null end
                                              as LocationId,
             count(distinct AD.PalletId)      as NumPallets,
             case when count(distinct AD.PalletId) = 1 then min(AD.PalletId) else null end
                                              as PalletId,
             case when count(distinct AD.PalletId) = 1 then min(AD.Pallet) else null end
                                              as Pallet,
             count(distinct AD.LPNId)         as NumLPNs,
             case when count(distinct AD.LPNId) = 1 then min(AD.LPNId) else null end
                                              as LPNId,
             case when count(distinct AD.LPNId) = 1 then min(AD.LPN) else null end
                                              as LPN,
             case when count(distinct AD.TaskId) = 1 then min(AD.TaskId) else null end
                                              as TaskId,
             count(distinct AD.TaskId)        as NumTasks,
             sum(AD.InnerPacks)               as NumInnerPacks,
             sum(AD.Quantity)                 as NumUnits,
             sum(case when AD.SKUId is not null and PSS.ActivityType like '%Pick%' then 1 else 0 end) --each pick would be associated with a SKUId
                                              as NumPicks,
             count(distinct AD.SKUId)         as NumSKUs,
             sum(S.UnitWeight * AD.Quantity)  as Weight,
             sum(S.UnitVolume * AD.Quantity)  as Volume
      from @ttAudits TT
        left join AuditDetails          AD on TT.AuditId =  AD.AuditId
        left join #ProductivitySubSet  PSS on AD.AuditId = PSS.AuditId
        left join SKUs                   S on AD.SKUId   =   S.SKUId
      group by TT.UserId, TT.Assignment
    ) /* Aggregate with respect to UserId & Assignment */
  update P
  set P.NumWaves      = TT.NumWaves,
      P.WaveId        = TT.WaveId,
      P.OrderId       = TT.OrderId,
      P.NumOrders     = TT.NumOrders,
      P.NumLocations  = TT.NumLocations,
      P.LocationId    = TT.LocationId,
      P.NumPallets    = TT.NumPallets,
      P.PalletId      = TT.PalletId,
      P.Pallet        = TT.Pallet,
      P.NumLPNs       = TT.NumLPNs,
      P.LPNId         = TT.LPNId,
      P.LPN           = TT.LPN,
      P.TaskId        = TT.TaskId,
      P.NumInnerPacks = TT.NumInnerPacks,
      P.NumUnits      = coalesce(TT.NumUnits, 0),
      P.NumTasks      = coalesce(TT.NumTasks, 0),
      P.NumPicks      = coalesce(TT.NumPicks, 0),
      P.NumSKUs       = TT.NumSKUs,
      P.Weight        = TT.Weight,
      P.Volume        = TT.Volume
  from #Productivity P
    left join cte_AuditSummary TT on (P.UserId = TT.UserId) and (P.Assignment = TT.Assignment);

  if (charindex('M', @Debug) > 0) exec pr_Markers_Save 'ProcessAudits-update Counts', @@ProcId;

  /* Rules to update other remaining missing entity details */
  exec pr_RuleSets_ExecuteRules 'Productivity_UpdateEntityInfo', null /* xml input - NA */;

  /* insert into Productivity */
  insert into Productivity (UserId, Assignment, BusinessUnit, Warehouse, Ownership,
                            StartDateTime, EndDateTime, Operation,
                            DurationInSecs, ActivityDate, WaveId, WaveNo, WaveType, WaveTypeDesc,
                            OrderId, PickTicket, LocationId, PalletId, Pallet, LPNId, LPN, TaskId,
                            NumLocations, NumPallets, NumLPNs, NumInnerPacks, NumUnits,
                            NumWaves, NumOrders, NumTasks, NumPicks, NumSKUs, Weight, Volume)
    select UserId, Assignment, BusinessUnit, Warehouse, Ownership,
           StartDateTime, EndDateTime, Operation,
           DurationInSecs, ActivityDate, WaveId, WaveNo, WaveType, WaveTypeDesc,
           OrderId, PickTicket, LocationId, PalletId, Pallet, LPNId, LPN, TaskId,
           NumLocations, NumPallets, NumLPNs, NumInnerPacks, NumUnits,
           NumWaves, NumOrders, NumTasks, NumPicks, NumSKUs, Weight, Volume
    from #Productivity;

  /* insert into Productivity Details to identify which AuditId are related to each of the Productivity records */
  insert into ProductivityDetails (ProductivityId, Assignment, AuditId, Warehouse, Ownership, BusinessUnit)
    select distinct P.ProductivityId, PSS.Assignment, PSS.AuditId, PSS.Warehouse, PSS.Ownership, PSS.BusinessUnit
    from #ProductivitySubSet PSS
      join Productivity P on PSS.UserId = P.UserId and PSS.Assignment = P.Assignment
    order by P.ProductivityId, PSS.Assignment, PSS.AuditId, PSS.BusinessUnit;

  if (charindex('M', @Debug) > 0) exec pr_Markers_Save 'ProcessAudits-Done', @@ProcId;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Prod_ProcessATRecord */

Go
