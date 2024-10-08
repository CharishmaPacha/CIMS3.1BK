/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/29  NB      Renamed RuleSetType from CarrierInterface to CIMSSI_CarrierInterface,
                        changed rules to indicate CIMSSI interface for different carriers(CIMSV3-1738)
  2021/11/11  PHK     Initial version (FBV3-444)
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
/* Rules Evaluate to get CarrierInterface to be used by CIMSSI for processing Shipment Creation
   Rules_ShipLabel will determine whether to use CIMSSI or CIMSAPI (API Integration).
   This RuleSetType is purely for CIMSSI only */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'CIMSSI_CarrierInterface';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set UPS/FedEx/USPS Carrier */
/******************************************************************************/
select @vRuleSetName        = 'CIMSSI_CarrierInterface',
       @vRuleSetFilter      = '~Carrier~ in (''UPS'', ''FEDEX'', ''USPS'', ''DHL'', ''Generic'')',
       @vRuleSetDescription = 'Identify Carrier Interface for Shipping',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = null; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Carrier Interface for ShipVias of UPS  */
select @vRuleCondition   = '~Carrier~ in (''UPS'')',
       @vRuleDescription = 'UPS: Use CIMSSI for UPS integration',
       @vRuleQuery       = 'select ''DIRECT''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Carrier Interface for ShipVias of FEDEX */
select @vRuleCondition   = '~Carrier~ in (''FEDEX'')',
       @vRuleDescription = 'FEDEX: Use CIMSSI for FEDEX integration',
       @vRuleQuery       = 'select ''DIRECT''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Carrier Interface for ShipVias of USPS */
select @vRuleCondition   = '~Carrier~ in (''USPS'')',
       @vRuleDescription = 'USPS: Use CIMSSI for USPS integration',
       @vRuleQuery       = 'select ''DIRECT''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Carrier Interface for ShipVias of DHL */
select @vRuleCondition   = '~Carrier~ in (''DHL'')',
       @vRuleDescription = 'DHL: Use ADSI for DHL integration',
       @vRuleQuery       = 'select ''ADSI''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Carrier Interface Type for ADSI specific ShipVias of Generic carrier */
select @vRuleCondition   = '~Carrier~ in (''Generic'') and ~ShipVia~ like ''BEST%''',
       @vRuleDescription = 'Generic/Best*: Use ADSI for Generic Small package carriers like BEST*',
       @vRuleQuery       = 'select ''ADSI''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Final rule is to use the default CIMS Interface */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default; Use CIMSSI by default for all integration',
       @vRuleQuery       = 'select ''DIRECT''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
