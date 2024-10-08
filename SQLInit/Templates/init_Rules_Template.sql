/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  201?/??/??  ??      Initial version
------------------------------------------------------------------------------*/

Go

declare @vRecordId            TRecordId,
        @vRuleSetType         TRuleSetType,
        @vRuleSetName         TName,
        @vRuleSetDescription  TDescription,
        @vRuleSetFilter       TQuery,
        @vOwnership           TOwnership,
        @vWarehouse           TWarehouse,
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
/* Rules for : Describe the RuleSet Type here */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'RuleSet One';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* RuleSet - Description of this RuleSet */
/******************************************************************************/
select @vRuleSetName        = 'RuleSetName',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'RuleSet description',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0, -- Initialize for this set
       @vOwnership          = null,
       @vBusinessUnit       = null,
       @vWarehouse          = null;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, Ownership, Warehouse, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, @vOwnership, @vWarehouse, coalesce(@vSortSeq, 0), @vStatus,
         @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule ..... */
select @vRuleCondition   = null,
       @vRuleDescription = '',
       @vRuleQuery       = 'select top 1 ''Message''
                            from TableA
                            where (Field1 is null) and
                                  (Field2 = ~PickBatchNo~)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule ..... */
select @vRuleCondition   = null,
       @vRuleDescription = '',
       @vRuleQuery       = '' ,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* RuleSet - Description of this RuleSet */
/******************************************************************************/
select @vRuleSetName        = 'RuleSetName',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'RuleSet description',
       @vSortSeq            = 0, -- Initialize for this set
       @vStatus             = 'A', /* Active */
       @vOwnership          = null,
       @vBusinessUnit       = null,
       @vWarehouse          = null;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, Ownership, Warehouse, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, @vOwnership, @vWarehouse, coalesce(@vSortSeq, 0), @vStatus,
         @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule ..... */
select @vRuleCondition   = null,
       @vRuleDescription = '',
       @vRuleQuery       = '' ,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
