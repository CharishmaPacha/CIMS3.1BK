/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/24  MS      Changes to return valid LPN Status for CasePick of BPP Wave (BK-223) 
  2020/10/20  TK      Corrected rules to export pick transactions to Host (HA-1516)
  2020/10/07  AY      Setup rules for ExportPick data to Host (HA-1516)
  2018/07/13  OK      Added rule for LTL to mark ToLPNs as picking (S2G-1039)
  2018/04/11  AY      Migrated the condition to Mark temp label as picked if there are no more picks to it.
  2018/04/09  OK      Added rules for Router instructions (S2G-587)
  2018/03/28  RV      Initial version (S2G-503)
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
/* Rules to determine status of ToLPN when inventory is picked to it */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OnPicked_ToLPN_Status';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Determine the status of the ToLPN while picking */
/******************************************************************************/
select @vRuleSetName        = 'OnPicked_ToLPN_Status',
       @vRuleSetDescription = 'Determine pick ToLPN status',
       @vRuleSetFilter      = null,
       @vSortSeq            = 10,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Replenish Waves */
select @vRuleCondition   = '~WaveType~ in (''R'', ''RU'', ''RP'')',
       @vRuleDescription = 'On Picked ToLPN mark as Picked if wave type is Replenish',
       @vRuleQuery       = 'select ''K''' /* Picked */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: LPN Pick */
select @vRuleCondition   = '~PickType~ = ''L'' /* LPN Pick */',
       @vRuleDescription = 'On Picked ToLPN mark as Picked if pick type is LPN',
       @vRuleQuery       = 'select ''K''' /* Picked */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: If picking each case individually as a ShipCarton, then mark the LPN as picked */
select @vRuleCondition   = '~WaveType~ in (''PTLC'')',
       @vRuleDescription = 'On Picked ToLPN mark as Picked if wave type is Pick To Label/Case',
       @vRuleQuery       = 'select ''K''' /* Picked */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: if wave type is LTL then mark ToLPN as Picking enabling picking multiple SKUs to same LPN.
         We will mark those LPNs as picked on dropping */
select @vRuleCondition   = '~WaveType~ in (''LTL'')',
       @vRuleDescription = 'On Picked ToLPN mark as Picking if wave type is LTL',
       @vRuleQuery       = 'select ''U''' /* Picking */,
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: if there are no more picks for the temp label, then mark it picked */
select @vRuleCondition   = '~OpenPicks~ = ''0'' and ~WaveType~ = ''PTS''', /* if we pass Zero without quots then this rule will pass alway if null sent as OpenPicks */
       @vRuleDescription = 'On Picked ToLPN mark as Picked if there are no more picks into the temp label',
       @vRuleQuery       = 'select ''K''' /* Picked */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: When picking to a shipping carton, then mulitple Cases and Units can be picked to a Carton */
select @vRuleCondition   = '~WaveType~ in (''PTS'') and ~PickType~ in (''CS'', ''U'')' /* Case/Unit */,
       @vRuleDescription = 'On Picked ToLPN mark as Picking if wave type is Pick & Pack and for Unit and Case Picks',
       @vRuleQuery       = 'select ''U''' /* Picking */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

  /*----------------------------------------------------------------------------*/
/* Rule: Default rule to mark pick ToLPN as Picking */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default rule to mark pick ToLPN as Picking',
       @vRuleQuery       = 'select ''U''' /* Picking */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;


/******************************************************************************/
/******************************************************************************/
/* Rules for export Router instructions */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OnPicked_ToLPN_ExportToRouter';

/******************************************************************************/
/* Insert Router instructions for some Waves where WCS is involved */
/******************************************************************************/
select @vRuleSetName        = 'OnPicked_ToLPN_ExportToRouter',
       @vRuleSetDescription = 'Insert Router instructions',
       @vRuleSetFilter      = null,
       @vSortSeq            = 20,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: For some waves, after LPN is picked we may need to send information to Router */
select @vRuleCondition   = '~WaveType~ in (''X'', ''Y'')',
       @vRuleDescription = 'For X/Y waves, insert the Router instructions after Picking',
       @vRuleQuery       = 'select ''Y''' /* Picked */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Default rules to send information to Router */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default rule is to not insert the Router instructions for Picked LPNs',
       @vRuleQuery       = 'select ''N''' /* Picked */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;


/******************************************************************************/
/******************************************************************************/
/* Rules for exporting to Sorter */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OnPicked_ToLPN_ExportToSorter';

/******************************************************************************/
/*  Send picked LPN details to Sorter */
/******************************************************************************/
select @vRuleSetName        = 'OnPicked_ToLPN_ExportToSorter',
       @vRuleSetDescription = 'Export Picked LPN Details to Sorter',
       @vRuleSetFilter      = null,
       @vSortSeq            = 30,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: For some waves, after LPN is picked we may need to send information to Panda */
select @vRuleCondition   = '~WaveType~ in (''X'', ''Y'')',
       @vRuleDescription = 'For X/Y waves, when LPN is picked, send information to Sorter',
       @vRuleQuery       = 'select ''Y''' /* Picked */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Default rules to send information to Sorter */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default rule is to not send any Picked LPN info to Sorter',
       @vRuleQuery       = 'select ''N''' /* No */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;


/******************************************************************************/
/******************************************************************************/
/* Rules for exporting to Panda */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OnPicked_ToLPN_ExportToPanda';

/******************************************************************************/
/*  Send picked LPN details to Panda */
/******************************************************************************/
select @vRuleSetName        = 'OnPicked_ToLPN_ExportToPanda',
       @vRuleSetDescription = 'Export Picked LPN Details to Panda',
       @vRuleSetFilter      = null,
       @vSortSeq            = 40,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: For some waves, after LPN is picked we may need to send information to Panda */
select @vRuleCondition   = '~WaveType~ in (''X'', ''Y'')',
       @vRuleDescription = 'For X/Y waves, when LPN is picked, send information to Panda',
       @vRuleQuery       = 'select ''Y''' /* Picked */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Default rules to send information to Panda */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default rule is to not send any Picked LPN info to Panda',
       @vRuleQuery       = 'select ''N''' /* No */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;


/******************************************************************************/
/******************************************************************************/
/* Rules for exporting to Host */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OnPicked_ToLPN_ExportToHost';

/******************************************************************************/
/*  Send picked LPN details to Panda */
/******************************************************************************/
select @vRuleSetName        = 'OnPicked_ToLPN_ExportToHost',
       @vRuleSetDescription = 'Export Picked LPNs to Host',
       @vRuleSetFilter      = null,
       @vSortSeq            = 50,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: For X/Y waves, Export pick transactions to Host for each pick to an LPN */
select @vRuleCondition   = '~WaveType~ in (''X'', ''Y'')',
       @vRuleDescription = 'For X/Y waves, Export pick transactions to Host for each pick to an LPN',
       @vRuleQuery       = 'select ''DuringPicking''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: For X/Y waves, Export pick transactions to Host when all picks are completed for an LPN */
select @vRuleCondition   = '~WaveType~ in (''XX'', ''YY'') and ~OpenPicks~ = 0',
       @vRuleDescription = 'For X/Y waves, Export pick transactions to Host when all picks are completed for an LPN',
       @vRuleQuery       = 'select ''OnPickingComplete''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: By default do not send any information to Host */
select @vRuleCondition   = null,
       @vRuleDescription = 'By default do not send any information to Host',
       @vRuleQuery       = 'select ''NotRequired''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
