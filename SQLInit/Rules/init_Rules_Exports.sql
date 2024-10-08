/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/07  AY      Disable Pick Transactions by default (HA-1516)
  2019/02/25  OK      Initial version (CID-116)
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
/* Rules for : Export Status flag */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Export_StatusFlag';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set: Determine whethere exports send to HOST or not */
/******************************************************************************/
select @vRuleSetName        = 'Export_StatusDecision',
       @vRuleSetDescription = 'Rules to determine whether exports should be sent to HOST or not',
       @vRuleSetFilter      = null,
       @vStatus             = 'NA' /* Active */,
       @vSortSeq            = 0; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Ignore Recv transactions if receiver is not yet closed */
select @vRuleCondition   = '~TransType~ = ''Recv''',
       @vRuleDescription = 'Ignore Recv transactions if receiver is not yet closed',
       @vRuleQuery       = 'select ''I''
                            from Receivers
                            where (ReceiverNumber = ~ReceiverNumber~) and
                                  (BusinessUnit = ~BusinessUnit~) and
                                  (Status not in (''C''))', /* Ignore if receiver not closed */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Ignore Recv transactions for 999 Warehouse as Receipts are to be exported for 000 Warehouse */
select @vRuleCondition   = '~TransType~ = ''Recv'' and ~Warehouse~ = ''999''',
       @vRuleDescription = 'Ignore Recv transactions for 999 Warehouse',
       @vRuleQuery       = 'select ''I''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Ignore Pick transactions unless the client explictly asks for them */
select @vRuleCondition   = '~TransType~ = ''Pick''',
       @vRuleDescription = 'Ignore Pick transactions',
       @vRuleQuery       = 'select ''I''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Default all exports sends to host */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default - Exports send to host',
       @vRuleQuery       = 'select ''N''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
