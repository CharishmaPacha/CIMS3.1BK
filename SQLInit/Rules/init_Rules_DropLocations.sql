/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/08  RKC     Made changes to does not suggest the previous Pause drop location for PTS waves (HA-2577)
  2020/11/24  VS      Suggest Respective WH drop locations (HA-1683)
  2020/05/28  TK      Consider WaveWarehouse as well (HA-655)
  2020/05/13  TK      Revised drop rules (HA-503)
  2019/08/31  VS/AY   Direct VAS tasks to drop in VAS location for PTS (CID-924)
  2019/08/05  RIA     Changes to correct the syntax errors (CID-136)
  2019/08/01  SPP     Added new rules for Packing area & picking area (CID-136) (Ported from Prod)
  2019/07/17  AY      Include LTL Wave in rules (CID-GoLive)
  2019/07/11  RV      LTL: Included LTL waves to suggest Drop location and Zone (CID-784)
  2019/06/14  VS      Made the changes to drop the VAS Orders and PTC Orders in to VASDrop location (CID-570)
  2019/05/30  AY      Corrected rule to update find VAS Locations (CID-451)
  2019/05/03  VS      Added Rule to suggest the VAS Location for VAS Orders(CID-206)
  2019/03/26  VS      Initial version(CID-220)
  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2015/06/25  RV      Added BPP to the RuleSet "Wave_BulkPT".
  2015/02/27  AK      Changes made to control data using procedure.
                      Splitted Rules,RuleSets(Init_Rules) based on RuleSetType.
  2015/02/27  TK      Initial version
------------------------------------------------------------------------------*/

declare  @vRecordId           TRecordId,
         @vRuleSetId          TRecordId,
         @vRuleSetName        TName,
         @vRuleSetDescription TDescription,
         @vRuleSetFilter      TQuery,

         @vBusinessUnit       TBusinessUnit,

         @vRuleCondition      TQuery,
         @vRuleQuery          TQuery,
         @vRuleQueryType      TTypeCode,
         @vRuleDescription    TDescription,

         @vSortSeq            TSortSeq,
         @vStatus             TStatus;

declare @RuleSets             TRuleSetsTable,
        @Rules                TRulesTable;

/*******************************************************************************
  Drop Locations should typically be suggested in this order (there will be exceptions
   from client to client and for some wave types)
  a. Direct to the drop Location of the Wave, if there is one.
  b. Direct to the Location where LPNs were previously dropped for this Wave.
  c. Find an empty location in the designated area for the Wave Type being processed
  d. Find any location in the designated area for the Wave Type being processed
*******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'DropLocations';

delete from @RuleSets;
delete from @Rules;

/*----------------------------------------------------------------------------*/
/* Rule Set #1 - Drop Locations */
/*----------------------------------------------------------------------------*/
select @vRuleSetName        = 'DropLocations_OtherThanReplenishWaves',
       @vRuleSetFilter      = '~WaveType~ not in (''RU'', ''RP'', ''R'')',
       @vRuleSetDescription = 'Rules for Drop Locations for other than Replenish Wave Types',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 10;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* For all PTL waves suggest conveyor locations */
select @vRuleCondition   = '~WaveType~ in (''XYZ'')',
       @vRuleDescription = 'Drop at any Conveyor Location',
       @vRuleQuery       = 'select top 1 Location
                            from Locations
                            where (LocationType = ''C'')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* If Wave has a drop location defined, then suggest that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Drop at the Location determined for the Wave',
       @vRuleQuery       = 'select DropLocation
                            from Waves
                            where (WaveNo = ~WaveNo~) and
                                  (coalesce(DropLocation, '''') <> '''')',
       @vRuleQueryType   = 'Select',
       @vStatus          =  'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule # Suggest the VAS Drop Locations for VAS Orders */
select @vRuleCondition   = '~WaveType~ in (''PTC'', ''PTS'')',
       @vRuleDescription = 'Suggest the VAS Drop Locations for VAS Orders',
       @vRuleQuery       = 'select top 1 LOC.Location from TaskDetails TD
                              left join Locations LOC on (LOC.BusinessUnit = TD.BusinessUnit)
                            where (TD.TaskId = ~TaskId~) and
                                  (TD.TDCategory2 like ''%-VAS%'') and
                                  (LOC.PutawayZone = ''Drop-VAS'') and
                                  (LOC.Warehouse = ~WaveWarehouse~)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Suggest the drop Location where the previous LPNs has been dropped for the Wave.
   This doesn't apply as all Carts of a Wave wouldn't end up at same locations for PTC/PTS */
select @vRuleCondition   = null,
       @vRuleDescription = 'Suggest to drop to Location where previous LPNs are for the Wave',
       @vRuleQuery       = 'select top 1 LOC.Location + ''|'' + LOC.PutawayZone
                            from Locations LOC
                              join LPNs L     on (LOC.LocationId    = L.LocationId ) and
                                                 (L.PickBatchNo     = ~WaveNo~) and
                                                 (LOC.PutawayZone   = ''Drop-'' + ~WaveType~)',
       @vRuleQueryType   = 'Select',
       @vStatus          =  'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Direct to an empty drop location designated for the WaveType */
select @vRuleCondition   = null,
       @vRuleDescription = 'Direct to an empty Location designated for the WaveType',
       @vRuleQuery       = 'select top 1 Location + ''|'' + PutawayZone
                            from Locations
                            where (PutawayZone = ''Drop-'' + ~WaveType~) and (Status = ''E'') and
                                  (Warehouse = ~WaveWarehouse~)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Direct to any drop location designated for the WaveType */
select @vRuleCondition   = null,
       @vRuleDescription = 'Direct to any Location designated for the WaveType',
       @vRuleQuery       = 'select top 1 Location + ''|'' + PutawayZone
                            from Locations
                            where (PutawayZone = ''Drop-'' + ~WaveType~) and
                                  (Warehouse = ~WaveWarehouse~)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Direct to Task Dest Zone */
select @vRuleCondition   = null,
       @vRuleDescription = 'Direct to Task Dest Zone',
       @vRuleQuery       = 'select ''|'' + T.DestZone
                            from Tasks T
                            where (T.TaskId = ~TaskId~)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Default - Direct to an Empty Location from the Drop Zones */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default - Direct to an Empty Location from the Drop Zones',
       @vRuleQuery       = 'select LOC.Location
                            from Locations LOC
                              join LookUps LU on (LOC.PutawayZone   = LU.LookUpCode) and
                                                 (LU.LookUpCategory = ''DropZones'')
                            where LOC.Status = ''E'' and
                                  LOC.Warehouse = ~WaveWarehouse~',
       @vRuleQueryType   = 'Select',
       @vStatus          =  'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 98;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Default - If no Location found then suggest at-least a Drop Zone */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default - If no Location found then suggest at-least a Drop Zone',
       @vRuleQuery       = 'select top 1 ''|'' + LookUpDescription
                            from LookUps
                            where (LookUpCategory = ''DropZones'')',
       @vRuleQueryType   = 'Select',
       @vStatus          =  'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #2 - Replenish Wave Drop Locations */
/******************************************************************************/
select @vRuleSetName        = 'DropLocations_ReplenishWaves',
       @vRuleSetFilter      = '~WaveType~ in (''RU'', ''RP'', ''R'')',
       @vRuleSetDescription = 'Rules for Drop Locations for Replenish Waves',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 20;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule # Replenish Wave Drop Location: If all the picks are for same dest location, then suggest that Location */
select @vRuleCondition   = null,
       @vRuleDescription = 'Suggest the DestLocation if all the picks have same destination',
       @vRuleQuery       = 'select Min(DestLocation)
                            from TaskDetails TD
                            where (TaskId = ~TaskId~)
                            group by TaskId
                            having count(distinct coalesce(DestLocation, '''')) = 1',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule # Replenish Wave Drop Location: If picks are for different Picklane locations then
           suggest any empty/available staging location with in the task zone */
select @vRuleCondition   = null,
       @vRuleDescription = 'If Picks are for different dest locations then suggest a Staging Location in the DestZone',
       @vRuleQuery       = 'select top 1 Location
                            from Tasks T
                              join Locations Loc on (Loc.PutawayZone = T.DestZone) and (Loc.Warehouse = T.Warehouse)
                            where (T.TaskId         = ~TaskId~) and
                                  (Loc.LocationType = ''S'' /* Staging */) and
                                  (Loc.Status not in (''D'', ''F'', ''I'' /* Deleted, Full, Inactive */))',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule # Replenish Wave Drop Location: If no empty/available staging locations found then suggest only Dest Zone */
select @vRuleCondition   = null,
       @vRuleDescription = 'By default, if we have not identified a drop location, suggest the DestZone of Task',
       @vRuleQuery       = 'select ''|'' + T.DestZone
                            from Tasks T
                            where (T.TaskId = ~TaskId~)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
