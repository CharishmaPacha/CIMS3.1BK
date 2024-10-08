/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/04  SAK     Added RuleSet for Receipts Entity Info (HA-2723)
  2021/04/28  NB      Added UIEntityInfo_PageTitle(HA-2705)
  2018/04/09  NB      Initial version(CIMSV3-151)
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
/* Rules for : Determine the header info for Orders */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OH_EntityInfo';

/******************************************************************************/
/* Rule: Header Info Form Name for Orders
   Header Info forms are defined different depending on the status of the Order
*/
/******************************************************************************/
select @vRuleSetName        = 'OH_EntityInfo_OrderHeader',      /* Context Name in UIEntityInfo Record */
       @vRuleSetDescription = 'Get Order Header EntityInfo FormName for Orders' ,
       @vRuleSetFilter      = '~EntityType~ = ''OH_EntityInfo'' and ~ContextName~=''OH_EntityInfo_OrderHeader''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Header Info Form for Packed and above status Orders */
select @vRuleDescription = 'Header Info form for Packed and above status Orders',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''OH_EntityInfo_HeaderForm_S'' from OrderHeaders
                            where OrderId = ~OrderId~ and Status in (''K'', ''R'', ''G'', ''L'',''S'')',
       @vSortSeq         =  0,
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, @vSortSeq, @vStatus;

/*----------------------------------------------------------------------------*/
/* Header Info Form for Orders in progress */
select @vRuleDescription = 'Header Info form for Orders in progress',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''OH_EntityInfo_HeaderForm_P'' from OrderHeaders
                            where OrderId = ~OrderId~ and Status in(''A'',''C'', ''P'') ',
       @vSortSeq         =  0,
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, @vSortSeq, @vStatus;

/*----------------------------------------------------------------------------*/
/* Header Info Form for Orders Yet to be Picked */
select @vRuleDescription = 'Order Header info form for Orders yet to be Picked',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''OH_EntityInfo_HeaderForm_W'' from OrderHeaders
                            where OrderId = ~OrderId~ and Status in(''D'', ''N'', ''W'')',
       @vSortSeq         =  0,
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, @vSortSeq, @vStatus;

/*----------------------------------------------------------------------------*/
/* Generic Header Info Form for Orders */
select @vRuleDescription = 'Order Header info form for remaining Orders',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''OH_EntityInfo_HeaderForm_Generic''',
       @vSortSeq         = 999, /* Generic should be last in the list becuase if no other rule satisfies,
                                 then we would use the generic form */
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;


/******************************************************************************/
/******************************************************************************/
/* Rules for : Page Title displayed as the browser tab name */
/******************************************************************************/
/******************************************************************************/
select  @vRuleSetType = 'UIEntityInfo_PageTitle';

delete from @RuleSets;
delete from @Rules;

/*----------------------------------------------------------------------------*/
/* Rule Set: Page Title for various Entity Info pages */
/*----------------------------------------------------------------------------*/
select @vRuleSetName        = 'UIEntityInfo_PageTitle',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Page Title for various Entity Info pages' ,
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 100; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Page Title for Order Header Entity Info */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~EntityType~ = ''OH_EntityInfo''',
       @vRuleDescription = 'Page Title for Order Header Entity Info',
       @vRuleQuery       = 'select ''PT '' + ~EntityKey~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Page Title for Load Entity Info */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~EntityType~ = ''Load_EntityInfo''',
       @vRuleDescription = 'Page Title for Load Entity Info',
       @vRuleQuery       = 'select ''Load '' + ~EntityKey~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule #1 Rules - Page Title for Wave Entity Info */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~EntityType~ = ''Wave_EntityInfo''',
       @vRuleDescription = 'Page Title for Wave Entity Info',
       @vRuleQuery       = 'select ''Wave '' + ~EntityKey~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Page Title for Receiver Entity Info */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~EntityType~ = ''RCV_EntityInfo''',
       @vRuleDescription = 'Page Title for Receiver Entity Info',
       @vRuleQuery       = 'select ''RC '' + ~EntityKey~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Page Title for Receipts Entity Info */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~EntityType~ = ''RH_EntityInfo''',
       @vRuleDescription = 'Page Title for Receipt Entity Info',
       @vRuleQuery       = 'select ''RO '' + ~EntityKey~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Default Page Title for Entity Info */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Page Title - Default for all entities',
       @vRuleQuery       = 'select ~EntityKey~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-insert, R-Replace */;

Go

