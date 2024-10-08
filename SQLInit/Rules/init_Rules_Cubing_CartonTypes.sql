/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/05  TK      Rule to use CartonGroup that is set up on the Order (BK-155)
  2020/10/06  TK      Changes to identify carton groups for multiple orders (HA-1487)
  2017/02/13  TD      S2G-107-GetCartonType based on the wavetype and picktypes.
  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2015/07/10  TK      Initial version
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
/* Rules for : select Carton Group based upon the rules */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Cubing_CartonGroups';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Update required info on the table to determine appropraite carton group */
/******************************************************************************/
select @vRuleSetName        = 'PopulateDataToDetermineCartonGroup',
       @vRuleSetDescription = 'Rules to populate data that is reqiured to determine Carton Group',
       @vRuleSetFilter      = null,
       @vSortSeq            = 10,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to prepare #OrdersToCube for evaluation of Carton Groups */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Pick counts for each Order',
       @vRuleQuery       = '/* Get the picktype counts here for the order from task details */
                           ;with PickCounts(OrderId, PackingGroup, LPNPicks, CasePicks, UnitPicks) as
                           (
                             select OrderId,
                                    PackingGroup,
                                    sum(case when PickType = ''L''  then 1 else 0 end),
                                    sum(case when PickType = ''CS'' then 1 else 0 end),
                                    sum(case when PickType = ''U''  then 1 else 0 end)
                             from TaskDetails
                             where (WaveId = ~WaveId~) and
                                   (Status <> ''X'' /* Cancelled */)
                             group by OrderId, PackingGroup
                           )
                           update OTC
                           set NumLPNPicks  = LPNPicks,
                               NumCasePicks = CasePicks,
                               NumUnitPicks = UnitPicks
                           from #OrdersToCube OTC join PickCounts PC on (OTC.OrderId = PC.OrderId) and (OTC.PackingGroup = PC.PackingGroup)
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set - Determine CartonGroups for the Orders */
/******************************************************************************/
select @vRuleSetName        = 'DetermineCartonGroup',
       @vRuleSetDescription = 'Rules to Determine Carton Group',
       @vRuleSetFilter      = null,
       @vSortSeq            = 20,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Condition based upon Order.Account */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Rule for account specific orders',
       @vRuleQuery       = 'Update OTC
                            set OrderCartonGroup = ''''
                            from #OrdersToCube OTC
                              join OrderHeaders OH on (OTC.OrderId = OH.OrderId)
                            where (OH.Account = '''') and
                                  (OrderCartonGroup is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition based upon wave type */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ = ''XYZ''',
       @vRuleDescription = 'Rule Condition based upon wave type',
       @vRuleQuery       = 'Update #OrdersToCube
                            set OrderCartonGroup = ''''
                            where (OrderCartonGroup is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Use Order Header Carton Group if one exists */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Use Order Header Carton Group if exists',
       @vRuleQuery       = 'Update OTC
                            set OrderCartonGroup = OH.CartonGroups
                            from #OrdersToCube OTC
                              join OrderHeaders OH on (OTC.OrderId = OH.OrderId)
                            where (OrderCartonGroup is null) and (OH.CartonGroups is not null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* BY default use ANYCARTON group which is all carton types */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Use ANYCARTON by default for all Customers',
       @vRuleQuery       = 'Update #OrdersToCube
                            set OrderCartonGroup = ''ANYCARTON''
                            where (OrderCartonGroup is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
