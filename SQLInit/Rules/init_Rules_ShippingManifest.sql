/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/12  RT      Rules to update Shipping Manifest Details and LPNDetails (HA-2572)
  2020/09/04  RKC     Standardize the format with template (HA-1304)
  2020/08/13  MS      Initial version
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
/* Rules for : Describe the RuleSet Type here */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'ShippingManifest';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - ShippingMainfest Report */
/******************************************************************************/
select @vRuleSetName        = 'Shipping Manifest Report',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Get the Shipping Manifest Report',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 10; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule 1.1 - Default Shipping Manifest Report name */
select @vRuleCondition   = null,
       @vRuleDescription = 'ShippingMainfest',
       @vRuleQuery       = 'select ''ShippingManifestMaster''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules to make Updates on Shippping Manifset LPNDetails */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'ShippingManifest_LPNDetails';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set to  update Shipping Mainfest LPN Details */
/******************************************************************************/
select @vRuleSetName        = 'Shipping Manifest LPN Details',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Get the Shipping Manifest LPN Details',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 20; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to post update the Shipping Manifest LPNDetails */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'ShippingMainfestLPNDetails',
       @vRuleQuery       = 'Update SLD
                            set UDF1 = ''
                            from #ShipmentLPNDetails SLD',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;


/******************************************************************************/
/* Rules to make updates on Shipping Manifest Details */
/******************************************************************************/
select @vRuleSetType = 'ShippingManifest_ManifestDetails';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Shipping Mainfest Details */
/******************************************************************************/
select @vRuleSetName        = 'Shipping Manifest Details',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Get the Shipping Manifest Details',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 30; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to update any customized details for Shipping Manifest details */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'ShippingManifestDetails: Update custom feilds on Shipping Manifest Details',
       @vRuleQuery       = 'Update SMD
                            set UDF2 = OH.UDF16 /* LotReference */
                            from #ShippingManifestDetails SMD
                              join OrderHeaders OH on (OH.OrderId = SMD.OrderId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
