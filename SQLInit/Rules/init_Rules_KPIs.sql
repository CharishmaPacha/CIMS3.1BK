/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/27  TK      Initial version (HA-3028)
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
/* Rules to finalize KPI records */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'KPIs_Finalize';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set to finalize KPI records */
/******************************************************************************/
select @vRuleSetName        = 'KPIs_Finalize',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Rule Set to finalize KPI records ',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 10; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to KPI Type & other Operations */
select @vRuleCondition   = null,
       @vRuleDescription = 'Rule to KPI Class & other Operations',
       @vRuleQuery       = 'Update KPIs
                            set KPIClass      = ~KPIClass~,
                                SubOperation1 = dbo.fn_EntityTypes_GetDescription(''Wave'', SubOperation1, ~BusinessUnit~),
                                Operation     = case when Operation = ''Activation'' then ''Production''
                                                     else Operation
                                                end
                            from KPIs
                            where (ActivityDate = ~ActivityDate~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update Sort Order */
select @vRuleCondition   = null,
       @vRuleDescription = 'Rule to update Sort Order',
       @vRuleQuery       = 'Update KPIs
                            set SortOrder = case when Operation = ''Receiving''                                       then ''100''
                                                 when Operation = ''Putaway''                                         then ''200''
                                                 when Operation = ''Reservation'' and SubOperation1 = ''Case Pick''   then ''301''
                                                 when Operation = ''Reservation'' and SubOperation1 = ''Pick & Pack'' then ''302''
                                                 when Operation = ''Reservation''                                     then ''399''
                                                 when Operation = ''Picking'' and SubOperation1 = ''Pick To Ship''    then ''400''
                                                 when Operation = ''Picking'' and SubOperation1 = ''Transfer''        then ''401''
                                                 when Operation = ''Picking''                                         then ''499''
                                                 when Operation = ''Production'' and SubOperation1 = ''Case Pick''    then ''501''
                                                 when Operation = ''Production'' and SubOperation1 = ''Pick & Pack''  then ''502''
                                                 when Operation = ''Production'' and SubOperation1 = ''Transfer''     then ''503''
                                                 when Operation = ''Production''                                      then ''599''
                                                 when Operation = ''Loading''                                         then ''600''
                                                 when Operation = ''Cycle Counting''                                  then ''700''
                                                 when Operation = ''Shipping''                                        then ''900''
                                            end
                            from KPIs
                            where (ActivityDate = ~ActivityDate~)' ,
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
