/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/04/23  AY      Initial version
------------------------------------------------------------------------------*/

declare @vRuleSetType  TRuleSetType = 'Router_GetDestination';

Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
delete from RuleSets where RuleSetType = @vRuleSetType;

declare @vRecordId            TRecordId,
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

declare @RuleSets             TRuleSetsTable,
        @Rules                TRulesTable;

/******************************************************************************/
/* Rule Set - Identify the destination for the LPN */
/******************************************************************************/
select @vRuleSetName        = 'Router_GetDestination',
       @vRuleSetDescription = 'Get the destination for the LPN',
       @vRuleSetFilter      = null,
       @vSortSeq            = null, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: For S2G, always route to the Wave.DropLocation */
select @vRuleCondition   = null,
       @vRuleDescription = 'Route the LPN to the Drop Location of the Wave',
       @vRuleQuery       = 'select DropLocation
                            from PickBatches
                            where (RecordId = ~WaveId~)',
       @vSortSeq         = 1,
       @vStatus          = 'A'; /* A-Active, I-In-Active, NA-Not applicable */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

Go

/******************************************************************************/
/******************************************************************************/
/* Rule Set - Determine the LPN to be used for Routing */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'Router_GetRouteLPN';

Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
delete from RuleSets where RuleSetType = @vRuleSetType;

declare @vRecordId            TRecordId,
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

declare @RuleSets             TRuleSetsTable,
        @Rules                TRulesTable;

/******************************************************************************/
/* Rule Set - Determine the LPN to be used for Routing */
/******************************************************************************/
select @vRuleSetName        = 'Router_GetRouteLPN',
       @vRuleSetDescription = 'Determine if the routing is to be done using LPN/UCCBarcode/TrackingNo',
       @vRuleSetFilter      = null,
       @vSortSeq            = null, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: For S2G, always route using LPN */
select @vRuleCondition   = null,
       @vRuleDescription = 'Route the LPN to the destination using LPN number',
       @vRuleQuery       = 'select ~LPN~',
       @vSortSeq         = 1,
       @vStatus          = 'A'; /* A-Active, I-In-Active, NA-Not applicable */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Use this rule when we want to route by TrackingNo */
select @vRuleCondition   = null,
       @vRuleDescription = 'Use TrackingNo to Route the LPN',
       @vRuleQuery       = 'select TrackingNo
                            from LPNs
                            where (LPNId = ~LPNId~)',
       @vSortSeq        += 1,
       @vStatus          = 'NA'; /* A-Active, I-In-Active, NA-Not applicable */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Use this rule when we want to route by UCCBarcode */
select @vRuleCondition   = null,
       @vRuleDescription = 'Use UCCBarcode of the LPN to Route it',
       @vRuleQuery       = 'select UCCBarCode
                            from LPNs
                            where (LPNId = ~LPNId~)',
       @vSortSeq        += 1,
       @vStatus          = 'NA'; /* A-Active, I-In-Active, NA-Not applicable */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

Go

/******************************************************************************/
/******************************************************************************/
/* Rule Set - Determine the WorkId to be used for Routing */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'Router_GetWorkId';

Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
delete from RuleSets where RuleSetType = @vRuleSetType;

declare @vRecordId            TRecordId,
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

declare @RuleSets             TRuleSetsTable,
        @Rules                TRulesTable;

/******************************************************************************/
/* Rule Set - Determine the WorkId to be used for Routing */
/******************************************************************************/
select @vRuleSetName        = 'Router_GetWorkId',
       @vRuleSetDescription = 'Determine the WorkId for Routing',
       @vRuleSetFilter      = null,
       @vSortSeq            = null, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'NA' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: At S2G we don't use work Ids */
select @vRuleCondition   = null,
       @vRuleDescription = '',
       @vRuleQuery       = null,
       @vSortSeq         = 1,
       @vStatus          = 'NA'; /* A-Active, I-In-Active, NA-Not applicable */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

Go
