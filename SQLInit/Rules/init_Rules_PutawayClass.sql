/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/16  MS      Added Default PA Class for HA (HA-209)
  2019/01/31  MS      Added rules (CID-52)
  2018/02/27  TK      Corrected rules (S2G-151)
  2018/01/14  AY      Ensure rules apply when no Flags are given (as it means both classes when Flags = '') S2G-74
  2016/07/12  YJ      Initial LL version
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
/* Rules for : LPN Putaway Class */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'LPN_PutawayClass';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - Putaway Class */
/******************************************************************************/
select @vRuleSetName         = 'LPN_PutawayClass',
       @vRuleSetDescription  = 'Determine Putaway Class of LPNs',
       @vRuleSetFilter       = '~PutawayClassType~ = ''LPN'' and (~Flags~ = ''PAC'' or ~Flags~ = '''')',
       @vSortSeq             = 0,
       @vStatus              = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '(~PAByWeight~ = ''Y'' and ((~UnitWeight~ >= ~MaxUnitWeight~) or (~LPNWeight~ >= ~MaxLPNWeight~)))',
       @vRuleDescription = 'Classify LPNs that are above weight thresholds as (H)eavy',
       @vRuleQuery       = 'select ''H''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~LPNHeight~ >= ''70''',
       @vRuleDescription = 'Putaway class = 1 if LPN is taller than 70 in.',
       @vRuleQuery       = 'select ''1''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~LPNInnerPacks~ <= ~PalletTie~',
       @vRuleDescription = 'Putaway class = 3 if LPN is single layer',
       @vRuleQuery       = 'select ''3''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~DestZone~ = ''QC''',
       @vRuleDescription = 'If DestZone is QC then Putaway Class is QC',
       @vRuleQuery       = 'select ''QC''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~DestLocationType~ =''K''',
       @vRuleDescription = 'If DestLocation on LPN is PickLane then Putaway Class is RC (Replenish Case)',
       @vRuleQuery       = 'select ''RC''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
select @vRuleCondition   = 'cast(~InnerPacksPerLPN~ as int) > 0 and cast(~LPNInnerPacks~ as int) >= cast(~InnerPacksPerLPN~ as int)',
       @vRuleDescription = 'Putaway class: FL - Full LPN when Cases > Std Cases per LPN',
       @vRuleQuery       = 'select ''FL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
select @vRuleCondition   = 'cast(~LPNQuantity~ as int) >= cast(~UnitsPerLPN~ as int)',
       @vRuleDescription = 'Putaway class rule based on LPNQuantity and units per LPN: FL - Full LPN',
       @vRuleQuery       = 'select ''FL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
select @vRuleCondition   = 'cast(~LPNQuantity~ as int) < cast(~UnitsPerLPN~ as int)',
       @vRuleDescription = 'Putaway class rule based on LPNQuantity and units per LPN: PL - Partial LPN',
       @vRuleQuery       = 'select ''PL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* If we don't have the SKU standards, then we have to assume it is a full LPN */
select @vRuleCondition   =  null,
       @vRuleDescription = 'Default Putaway class: FL - Full LPN',
       @vRuleQuery       = 'select ''FL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
