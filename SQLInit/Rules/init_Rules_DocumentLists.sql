/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2015/02/26  AK      Splitted Rules,RuleSets(Init_Rules) based on RuleSetType.
  2014/12/19  AK      Changes made to control data using procedure
  2014/05/13  SV      Initial version
------------------------------------------------------------------------------*/

declare @vRuleSetType  TRuleSetType = 'DocumentList';

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

           @vSortSeq            TSortSeq,
           @vStatus             TStatus;

  declare  @RuleSets TRuleSetsTable,
           @Rules    TRulesTable;

/*----------------------------------------------------------------------------*/
/* Rule Set #1 - Static Docs to print in Packing along with Packing list */
/*----------------------------------------------------------------------------*/
select @vRuleSetName        = 'PackingDocuments',
       @vRuleSetDescription = 'Verify the document type for printing Static Docs',
       @vRuleSetFilter      = '~DocumentType~ = ''ORD''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

exec pr_Rules_Setup @RuleSets, @Rules;

Go
