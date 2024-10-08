/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/07  PK/YJ   Get return label for FEDEX RuleQuery changed as'select ''N': Ported changes done by Pavan (HA-2569)
  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2015/12/30  DK/VM   Initial version
------------------------------------------------------------------------------*/

declare @vRuleSetType  TRuleSetType = 'ReturnLabels';

Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
delete from RuleSets where RuleSetType = @vRuleSetType;

  declare  @vRecordId           TRecordId,
           @vRuleSetId          TRecordId,
           @vRuleSetName        TName,
           @vRuleSetDescription TDescription,
           @vRuleSetFilter      TQuery,

           @vBusinessUnit       TBusinessUnit,

           @vRuleCondition      TQuery,
           @vRuleQuery          TQuery,
           @vRuleDescription    TDescription,

           @vSortSeq            TSortSeq,
           @vStatus             TStatus;

  declare @RuleSets             TRuleSetsTable,
          @Rules                TRulesTable;

/*----------------------------------------------------------------------------*/
/* Rule Set #1 - Required return label */
/*----------------------------------------------------------------------------*/
select @vRuleSetName        = 'RequiredReturnLabel',
       @vRuleSetDescription = 'Get all active return labels',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A'  /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule 1.1 - Required return label for FEDEX */

select @vRuleDescription = 'Get return label for FEDEX',
       @vRuleCondition   = '~ShipVia~ like ''FEDEX%''',
       @vRuleQuery       = 'select ''N''',
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule 1.2 - Required return label for UPS */

select @vRuleDescription = 'Get return label for UPS',
       @vRuleCondition   = '~ShipVia~ like ''UPS%''',
       @vRuleQuery       = 'select ''N''',
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule 1.3 - Required return label - DEFAULT */

select @vRuleDescription = 'Get default return label Requirement',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''N''',
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

exec pr_Rules_Setup @RuleSets, @Rules;

Go
