/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/24  AY      Disabled all rules as they are not defaults.
  2019/09/19  RIA     Fixed Issue (CID-1029)
  2019/09/10  MS      Initial version (CID-1029)
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
/* Rules to update ShipVia to send to exports */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Export_GetShipVia';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Description of this RuleSet */
/******************************************************************************/
select @vRuleSetName        = 'Export_ShipVia',
       @vRuleSetDescription = 'Return the ShipVia to send to Exports',
       @vRuleSetFilter      = '~TransType~ = ''Ship''',
       @vSortSeq            = 0, -- Initialize for this set
       @vStatus             = 'I' /* In-Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to Get the ShipVia */
select @vRuleCondition   = null,
       @vRuleDescription = 'Export ShipVia: Use Load Ship Via if MasterTrackingNo exists',
       @vRuleQuery       = 'select ShipVia
                            from Loads
                            where (LoadId = ~LoadId~) and
                                  (coalesce(MasterTrackingNo, '''') <> '''')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to Get the ShipVia when on a Load */
select @vRuleCondition   = '~LoadId~ > 0',
       @vRuleDescription = 'Export ShipVia: If on Load, Export Shipment ShipVia',
       @vRuleQuery       = 'select ~ShipVia~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to Get the ShipVia when on a Load */
select @vRuleCondition   = '~LoadId~ = 0',
       @vRuleDescription = 'Export ShipVia: If not on Load, Export Order ShipVia',
       @vRuleQuery       = 'select OH.ShipVia
                            from OrderHeaders OH
                            where (OH.OrderId = ~OrderId~)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
