/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/17  KBB/TK  Initial version (HA-2674)
------------------------------------------------------------------------------*/

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

/* Rule Conditions and Queries are validated on Insert.
   These Temp Tables are created such that the validations are done correctly */
declare @ttSelectedEntities  TEntityValuesTable;
if (object_id('tempdb..#ttSelectedEntities') is null)
  select * into #ttSelectedEntities from @ttSelectedEntities;

/******************************************************************************/
/******************************************************************************/
/* Rule Set : Evaluate whether to process a report in real time or to process it via Rules */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Reports_ProcessMode';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Shipping Manifest and Shipping Manifest Summary Report */
/******************************************************************************/
select @vRuleSetName        = @vRuleSetType + '_ShippingManifest',
       @vRuleSetFilter      = '~Action~ in (''Loads_Rpt_ShippingManifest'', ''Loads_Rpt_ShipManifestSummary'')',
       @vRuleSetDescription = 'Loads: Evaluate process mode for Shipping Manifest Report',
       @vSortSeq            =  10,  /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Evaluate Process Mode of Load Shipping Manifest
   When there are more than 10 orders in a Load, it is possible that UI may take time to process and generate the PDF
   Therefore, consider all such requests to be processed in background via Print Jobs */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Process Mode for Load Shipping Manifest',
       @vRuleQuery       = 'select ''B''
                            from Loads L
                              join #ttSelectedEntities tt on (L.LoadId = tt.EntityId)
                              where (tt.EntityType = ''Load'') and
                                    (L.NumOrders   > 10)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I'/* InActive */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Default rule is to process report in real time */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Process Mode: By default process reports in Realtime',
       @vRuleQuery       = 'select ''R''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/******************************************************************************/
/* Rule Set : Evaluate to return report name */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Reports_ReportName';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Shipping Manifest and Shipping Manifest Summary Report */
/******************************************************************************/
select @vRuleSetName        = @vRuleSetType + '_ShippingManifest',
       @vRuleSetFilter      = '~Action~ in (''Loads_Rpt_ShippingManifest'', ''Loads_Rpt_ShipManifestSummary'')',
       @vRuleSetDescription = 'Loads: Evaluate report name for Shipping Manifest Report',
       @vSortSeq            =  20,  /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Evaluate Report Name of Load Shipping Manifest
   return the Transfer specific report name */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Report Name: Print Shipping Manifest Transfer for Transfer Loads',
       @vRuleQuery       = 'select ''Loads_Rpt_ShippingManifest_Transfer''
                            from Loads L
                              join #ttSelectedEntities tt on (L.LoadId = tt.EntityId)
                            where (tt.EntityType = ''Load'') and
                                  (L.LoadType    = ''Transfer'')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Default rule to return the default report name */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Report Name: By default it is same as action',
       @vRuleQuery       = 'select ~Action~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set - Default Rules to evaluate Report Name */
/******************************************************************************/
select @vRuleSetName        = @vRuleSetType + '_Default',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Default Rules to evaluate Report Name',
       @vSortSeq            = 99,  /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Default rule to return the default report name */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Default Report Name: By default it is same as action',
       @vRuleQuery       = 'select ~Action~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
