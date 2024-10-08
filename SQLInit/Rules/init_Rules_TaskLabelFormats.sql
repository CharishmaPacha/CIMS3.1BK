/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/08/03  RT      Added Rule Description and Rules for WaveType Pick To Cart to print Task_4x6HeaderLabel_PTC (OB2-394)
  2016/07/28  TK/AY   Added rules for Task detail labels
  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2015/07/12  AY      Initial version
------------------------------------------------------------------------------*/

declare @vRuleSetType  TRuleSetType = 'TaskLabelFormats';

Delete R from Rules R join RuleSets RS on (R.RuleSetId = RS.RuleSetId) where (RS.RuleSetType = @vRuleSetType);
delete from RuleSets where RuleSetType = @vRuleSetType;

  declare  @vRecordId            TRecordId,
           @vRuleSetId           TRecordId,
           @vRuleSetName         TName,
           @vRuleSetDescription  TDescription,
           @vRuleSetFilter       TQuery,

           @vBusinessUnit        TBusinessUnit,

           @vRuleCondition       TQuery,
           @vRuleQuery           TQuery,
           @vRuleDescription     TDescription,

           @vSortSeq             TSortSeq,
           @vStatus              TStatus;

  declare @RuleSets              TRuleSetsTable,
          @Rules                 TRulesTable;

/*******************************************************************************/
/* Rule Set #1 - Task Label Formats for Replenishmnet */
/*******************************************************************************/
select @vRuleSetName        = 'ReplenishPicks',
       @vRuleSetDescription = 'To verify for valid Replenish tasks for task label printing',
       @vRuleSetFilter      = '~WaveType~ in (''R'', ''RP'', ''RU'')',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* For Replenish Tasks, print the 4x3 Header label*/
select @vRuleDescription = 'Header label to print for replenish tasks',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''Task_4x3HeaderLabel''',
       @vSortSeq         =  0,
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, @vSortSeq, @vStatus;

/*******************************************************************************/
/* Rule Set #2 - Task Label Formats for Bulk Pull or Customer Orders */
/*******************************************************************************/
/* Rule Set #2 Rule for Task Label for all other wave types other than
   Replenish. Note that for most clients both of these may be the same, but
   none the less the rules are setup to allow to use different formats if so
   desired */

select @vRuleSetName        = 'AllOtherPicks',
       @vRuleSetDescription = 'To verify for valid bulk or customer orders for task label printing',
       @vRuleSetFilter      = '~WaveType~ not in (''R'', ''RP'', ''RU'')',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* For Bulk Pull Tasks, print the 4x3 Header label*/
select @vRuleDescription = '4x3 Header label for Bulk Pull Tasks label printing',
       @vRuleCondition   = '~DestZone~ in (''SORT-RETAIL'', ''SORT-ECOM'', ''PTL'')',
       @vRuleQuery       = 'select ''Task_4x3HeaderLabel''',
       @vSortSeq         =  0,
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* For Wave Type Pick To cart, we would print specific 4x6 UCC Labels so print 4x6 Header label*/
select @vRuleDescription = 'Task Label Header specific to Pick To Cart',
       @vRuleCondition   = '~WaveType~ = ''PTC''',
       @vRuleQuery       = 'select ''Task_4x6HeaderLabel_PTC''',
       @vSortSeq         =  0,
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* For all other Picks, the cases are going to Customer and we would print 4x6 UCC Labels so print 4x6 Header label*/
select @vRuleDescription = '4x6 UCC Labels to print for all Customer orders',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''Task_4x6HeaderLabel''',
       @vSortSeq         =  0,
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

/******************************************************************************/
/* Employee Label Format */
/******************************************************************************/
select  @vRuleSetType = 'TaskDetailLabelsToPrint';

Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
delete from RuleSets where RuleSetType = @vRuleSetType;
delete from @RuleSets;
delete from @Rules;

/*----------------------------------------------------------------------------*/
/* Rule Set #1 - Employee labels */
/*----------------------------------------------------------------------------*/
select @vRuleSetName        = 'EmployeeLabelToPrint',
       @vRuleSetDescription = 'Verify wave type for printing Employee Labels',
       @vRuleSetFilter      = '~WaveType~ in (''PC'')',
       @vSortSeq            = 0,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Generic */
select @vRuleDescription = 'To print Employee Labels for TDL LabelType',
       @vRuleCondition   = '~LabelType~ = ''TDL''',
       @vRuleQuery       = 'select ''Task_4x3_EmployeeLabel''',
       @vSortSeq         = 0,
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, @vSortSeq, @vStatus;

/*******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

Go
