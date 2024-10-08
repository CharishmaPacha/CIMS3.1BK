/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/14  VS      BKPP: Do not Drop pallet other than suggested location (BK-800)
  2021/07/30  RV      DropPallet_ConvertToSetSKUs: Initial version (OB2-1986)
  2020/09/02  TK      Rules to validate dropping to Hold drop zone (HA-1175)
  2020/06/02  RKC     Disabled the customer specific rules (HA-719)
  2020/05/15  TK      Drop pallet for Rework waves & corrected Unload option to be Unload All (HA-543)
  2019/08/31  VS/AY   Force VAS tasks to drop in VAS only for PTS (CID-924)
  2019/08/02  TD      Droppallet decision for Replenishment tasks (CID_GolIve)
  2019/07/24  AY      Revamped rules to allow dropping at any of the zones (CID-GoLive)
  2019/07/20  SPP     Added RuleSetname inBatchPicking_DropPallet LTL in SLB related rules only (CID-136) (Ported from prod)
  2019/07/17  AY      Included LTL wave in drop rules (CID-GoLive)
                      For SLB, unload completed or incomplete totes into drop-SLB
  2019/06/09  AY      Allow to drop in Pause Location at any time during picking
  2019/06/06  VS      Added Condition to do not drop VAS Orders into VAS Zone and
                        PTS Orders into PTS Drop Zone if Order is Picked Partially (CID-486)
  2019/05/31  VS      PTC and SLB Picked Pallet need to drop Totes instead of Pallet (CID-486)
  2018/09/20  AY      Added Drop Location Validation rules (S2GCA-252)
  2018/09/18  TK      Pallet drop is mandatory for CP, CPRW, PTS & PCPK waves (S2GCA-252)
  2018/09/06  AY      Change rules for LTL to CP and add CPRW Wave (S2GCA-239/S2GCA-240)
  2018/06/19  TK      Unload LPNs from Pallet/Cart for Piece Pick and PTS waves (S2GCA-66)
  2018/06/11  TK      Force Pallet drop for Dynamic Replenishment Waves (S2GCA-63)
  2018/06/06  PK      LTL LPN & CS Picks will be picked on to the pallets without dropping the pallet.
  2018/04/16  OK      Added seperate rule for LTL case picks (S2G-656)
  2018/04/06  AY      LPN Picks to be unloaded after picking (S2G-578)
              OK      PTL Picks to be unloaded after picking (S2G-534)
  2018/03/30  RV      Made changes to drop units if wave is PTL (S2G-534)
  2018/03/22  RV      Added rules for Case picks and default rules
                        Change the wave types, which are not exists in CIMS(S2G-459)
  2018/02/20  AY      pr_RFC_Picking_DropPickedPallet: Change rules to prevent cartons being unloaded from cart when dropped
                        in Hold/Pause Locations (HPI-1810)
  2016/12/09  OK      Included the ForcePalletToDrop related Rules (HPI-1070)
  2016/05/05  TK      Initial version
------------------------------------------------------------------------------*/

Go

declare @vRecordId            TRecordId,
        @vRuleSetType         TRuleSetType,
        @vRuleSetName         TName,
        @vRuleSetDescription  TDescription,
        @vRuleSetFilter       TQuery,

        @vBusinessUnit        TBusinessUnit,

        @vRuleCondition       TQuery,
        @vRuleQuery           TQuery,
        @vRuleQueryType       TTypeCode,
        @vRuleDescription     TDescription,

        @vSortSeq             TSortSeq,
        @vStatus              TStatus;

declare @RuleSets             TRuleSetsTable,
        @Rules                TRulesTable;

/******************************************************************************/
/******************************************************************************/
/* Rules to decide unload option for drop pallet */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'DropOrUnloadPickedPallet';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Determine if LPNs on Pallet have to be dropped or unloaded into the drop
   location. These are default rules only. Based upon the wave type it may change
*/
/******************************************************************************/
select @vRuleSetName        = 'BatchPicking_DropPallet',
       @vRuleSetFilter      = '~Operation~ =''BatchPicking_DropPallet''',
       @vRuleSetDescription = 'Scenarios where Pallet/Cart has to be dropped after picking',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 10;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: If dropping into Picklane, then transfer into the Location */
select @vRuleCondition   = '~LocationType~ = ''K''',
       @vRuleDescription = 'If destination Location is picklane, then transfer',
       @vRuleQuery       = 'select ''T''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: If dropping onto Conveyor, then unload onto the Location */
select @vRuleCondition   = '~LocationType~ = ''C''',
       @vRuleDescription = 'If drop Location is conveyor, then move LPN off Picking pallet onto Conveyor',
       @vRuleQuery       = 'select ''U''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Cart should be dropped if Pause Location */
select @vRuleCondition   = '~PalletType~ = ''C'' and ~LocationType~ <> ''K'' and (~LocPutawayZone~ = ''Drop-Pause'')',
       @vRuleDescription = 'Drop the Cart if user scanned Location in drop-Pause zone',
       @vRuleQuery       = 'select ''D''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Cart should be dropped if hold Location as is, except for PTS */
select @vRuleCondition   = '~PalletType~ = ''C'' and ~LocationType~ <> ''K'' and (~WaveType~ not in (''PTS'')) and (~LocPutawayZone~ = ''Drop-Hold'')',
       @vRuleDescription = 'Other than PTS, any drop into Hold, leave the totes on the cart to continue picking',
       @vRuleQuery       = 'select ''D''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: PTS Wave: If dropping to a hold zone, unload dis-qualified orders only */
select @vRuleCondition   = '~PalletType~ = ''C'' and ~LocationType~ <> ''K'' and (~WaveType~ in (''PTS'')) and
                           (~LocPutawayZone~ = ''Drop-Hold'') and ~DisQualifiedOrderCount~ > 0',
       @vRuleDescription = 'PTS Wave: If dropping to a hold zone, unload dis-qualified orders only',
       @vRuleQuery       = 'select ''UD''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: If dropping to a hold zone, unload the Templabels/Totes that are incomplete */
select @vRuleCondition   = '~PalletType~ = ''C'' and ~LocationType~ <> ''K'' and (~WaveType~ in (''PTS'')) and (~LocPutawayZone~ = ''Drop-Hold'')',
       @vRuleDescription = 'Unload incomplete Templabels/Totes if user is dropping Cart to a Hold Location',
       @vRuleQuery       = 'select ''UI''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Unload completed tasks if dropped in packing area */
select @vRuleCondition   = '(~WaveType~ in (''PTS'')) and
                            (~LocPutawayZone~ like ''Drop%'')',
       @vRuleDescription = 'PTS Waves: Unload Completed LPN/TempLabels/Totes at any Drop Location other than Hold',
       @vRuleQuery       = 'select ''UC''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rework & Transfer Waves: Drop Pallet */
select @vRuleCondition   = '~WaveType~ in (''RW'', ''XFER'')',
       @vRuleDescription = 'Drop Pallet into Location for Rework & Transfer waves',
       @vRuleQuery       = 'select ''D''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* SLB/LTL/PTC: Unload completed or incomplete totes in Packing area */
select @vRuleCondition   = '(~WaveType~ in (''SLB'', ''LTL'', ''PTC'')) and
                            (~LocPutawayZone~ like ''Drop%'')',
       @vRuleDescription = 'SLB/LTL/PTC Waves: Unload Incomplete LPN/TempLabels/Totes at any Drop Location other than hold',
       @vRuleQuery       = 'select ''UA''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Task Type Unit Picks picking into Pallets other than Picking Cart */
select @vRuleCondition   = '~TaskType~ = ''U'' and ~PalletType~ not in (''C'')',
       @vRuleDescription = 'Drop LPNs, if unit picks are picked into pallets other than Picking Cart',
       @vRuleQuery       = 'select ''D''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Task Type Case & LPN Picks - Drop pallet for LTL waves */
select @vRuleCondition   = '~TaskType~ in (''CS'', ''L'') and ~LocationType~ <> ''K'' and ~WaveType~ in (''CP'', ''CPRW'')' /* Case & LPN Picks */,
       @vRuleDescription = 'Case & LPN picks picked onto Pallet for Case Pick/Case Pick Rework wave: Drop the Pallet',
       @vRuleQuery       = 'select ''D''' /* Drop */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Task Type Case Picks picking into Pallets */
select @vRuleCondition   = '~TaskType~ in (''CS'') /* Case Pick */ and ~LocationType~ <> ''K''' /* Picklane */,
       @vRuleDescription = 'Case picks picked onto Pallet: Unload the Pallet',
       @vRuleQuery       = 'select ''UA''' /* Unload */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Task Type - LPN Pick for replenishments */
select @vRuleCondition   = '~TaskType~ in (''L'') and ~LocationType~ <> ''K'' and ~WaveType~ in (''RU'', ''RP'')',
       @vRuleDescription = 'Drop into Location, if it is a LPN pick for Replenish waves',
       @vRuleQuery       = 'select ''D''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Task Type - LPN Pick */
select @vRuleCondition   = '~TaskType~ in (''L'') and ~LocationType~ <> ''K''',
       @vRuleDescription = 'Drop into Location, if it is a LPN pick',
       @vRuleQuery       = 'select ''UA''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Task Type - Pallet Picks */
select @vRuleCondition   = '~TaskType~ in (''P'') and ~LocationType~ <> ''K''',
       @vRuleDescription = 'Drop into Location, if it is a Pallet pick',
       @vRuleQuery       = 'select ''D''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Default rule to drop the Pallet */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default rule is to drop the Pallet/Cart',
       @vRuleQuery       = 'select ''D''' /* Drop */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules to Validate the dropped Location */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType  = 'DropPallet_ValidateLocation';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Validations to check whether the dropped location is valid or not */
/******************************************************************************/
select @vRuleSetName        = 'DropPallet_ValidateLocation',
       @vRuleSetDescription = 'Validate Drop Location',
       @vRuleSetFilter      = null,
       @vSortSeq            = 0,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Can only drop in Staging/Dock Locations */
select @vRuleCondition   = '~WaveCategory1~ <> ''DynamicReplenishments'' and ~LocationType~ = ''K''',
       @vRuleDescription = 'Cannot have Non-Replenish Waves drop into picklanes',
       @vRuleQuery       = 'select ''DropPallet_InvalidLocationType''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Dynamic Replenishment Waves to be dropped  */
select @vRuleCondition   = '~WaveCategory1~ = ''DynamicReplenishments'' and ~LocPutawayZone~ <> ''''',
       @vRuleDescription = 'Force Pallet drop for Dynamic Replenishment wave',
       @vRuleQuery       = 'select ''DropPallet_LocationFromDiffZone''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Can always drop in Pause Location */
select @vRuleCondition   = '(~LocPutawayZone~ in (''Drop-Pause''))',
       @vRuleDescription = 'Can always drop Pallet/Cart in Pause locations during picking',
       @vRuleQuery       = 'select ''''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: VAS Orders should be dropped in VAS zones only */
select @vRuleCondition   = '~WaveType~ in (''PTC'', ''PTS'')',
       @vRuleDescription = 'VAS Orders should be dropped in VAS Zones only',
       @vRuleQuery       = 'select ''DropPallet_InvalidZoneforVAS'' from TaskDetails
                            where (TaskId = ~TaskId~) and (TDCategory2 like ''%-VAS%'') and (~LocPutawayZone~ not in (''Drop-VAS'', ''Drop-Hold''))',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Cannot drop in Hold if there are no disqualified orders */
select @vRuleCondition   = '~WaveType~ in (''PTS'', ''PTC'') and ~LocPutawayZone~ = ''Drop-Hold'' and
                            ~DisQualifiedOrderCount~ = 0',
       @vRuleDescription = 'Cannot drop in Hold if there are no disqualified orders',
       @vRuleQuery       = 'select ''DropPallet_NoDisqualifiedOrdersToHold''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: CP, CPRW, PTS & PCPK waves should be dropped in suggested zones only */
select @vRuleCondition   = '~WaveType~ in (''CP'', ''CPRW'', ''PTS'', ''PCPK'', ''PTC'', ''BKPP'') and (~SuggDropZone~ <> ~ScannedLocZoneDesc~) and (~LocPutawayZone~ not in (''Drop-Hold''))',
       @vRuleDescription = 'Force Pallet drop for Case Pick, PickToShip, Pick To Cart and Piece Pick Waves',
       @vRuleQuery       = 'select ''DropPallet_LocationFromDiffZone''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Default */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default; No validation',
       @vRuleQuery       = 'select ''''' /* Valid */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules to apply after drop of the Pallet i.e. for any subsequent actions
   followed by drop */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType  = 'DropPallet_AfterDrop';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* On drop of picking pallet, if needed, convert to set SKUs */
/******************************************************************************/
select @vRuleSetName        = 'DropPallet_ConvertToSetSKUs',
       @vRuleSetDescription = 'Decide to convert to set SKUs',
       @vRuleSetFilter      = null,
       @vSortSeq            = 100,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Convert to set SKUs for waves PTC and PTS after drop pallet */
select @vRuleCondition   = '~WaveType~ in (''PTC'', ''PTS'')',
       @vRuleDescription = 'On Drop Pallet: Convert to set SKUs for waves PTC and PTS',
       @vRuleQuery       = 'select * into #LPNsToConvertSets from #PickedLPNs;
                            exec pr_LPNs_ConvertToSetSKUs default, ~BusinessUnit~, ~UserId~;
                           ',
       @vRuleQueryType   = 'update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
