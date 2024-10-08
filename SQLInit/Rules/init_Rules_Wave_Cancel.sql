/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/18  VS      Consider NumPicks to cancel the Wave (CIMSV3-1078)
  2020/09/25  VS      Initial Revision (CIMSV3-1078)
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
/* Rules required to Cancel the Wave */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Wave_DeferCancelWave';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set to determine if WaveCancel should be deferred or not */
/******************************************************************************/
select @vRuleSetName        = 'Wave_DeferCancelWave',
       @vRuleSetDescription = 'Determine if the Wave cancel is to be processsed immediately or in background',
       @vRuleSetFilter      = null,
       @vSortSeq            = 0, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule - Wave Cancel: if Wave has more than 50 picks then update the BackgroundProcessFlag as Y */
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave Cancel: if Wave has more than 50 or 50 picks then update the BackgroundProcessFlag as Y',
       @vRuleQuery       = 'Update #WavesToCancel
                            set BackgroundProcessFlag = ''Y''
                            from #WavesToCancel TPB
                              join Waves W on W.RecordId = TPB.EntityId
                            where (W.NumTasks >= 50) or (W.NumPicks >= 150);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
