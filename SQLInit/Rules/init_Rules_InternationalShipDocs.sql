/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/07/07  RV      Setup commercial invoice document for FEDEX international (HA-3531)
  2022/01/21  RKC     Added new rules for CN22 contents (FBV3-448)
  2020/10/13  RV      Made changes as per the standard and inactive the rules (HA-1541)
  2017/10/06  OK      Initial version (OB-618)
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
/* Rules for : InternationalShipDocs */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'InternationalShipDocs';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - Commercial Invoice */
/******************************************************************************/
select @vRuleSetName        = 'CommercialInvoice',
       @vRuleSetDescription = 'Commercial Invoice requirement for all International shipments',
       @vRuleSetFilter      = '~DocumentType~ = ''CommercialInvoice''',
       @vSortSeq            = 0,
       @vStatus             = 'A' /* In Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* UPS */
select @vRuleCondition   = '~Carrier~ = ''UPS'' and ~AddressRegion~ = ''I'' and ~ShipVia~ not in (''UPSMIEC'', ''UPSMIP'')',
       @vRuleDescription = 'UPS International services which require Commercial Invoice',
       @vRuleQuery       = 'select ''Y''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* FEDEX supports the following ETD Documents for customs clearance:
    COMMERCIALINVOICE, CERTIFICATEOFORIGIN, CUSTOMERSPECIFIEDLABELS, CUSTOMPACKAGEDOCUMENT, CUSTOMSHIPMENTDOCUMENT, DANGEROUSGOODSSHIPPERSDECLARATION,
    EXPORTDECLARATION, FREIGHTADDRESSLABEL, GENERALAGENCYAGREEMENT, LABEL, NAFTACERTIFICATEOFORIGIN, OP_900, PROFORMAINVOICE, RETURNINSTRUCTIONS.

    For now we have added for Commercial Invoice. If client requires other documents we need to add the document specific rules and call in the
    proc pr_Shipping_GetShipmentData to build the required document node under ADDITIONALSHIPPINGDOCS node.
    Ex: <ADDITIONALSHIPPINGDOCS><COMMERCIALINVOICE>Y</COMMERCIALINVOICE><CERTIFICATEOFORIGIN>Y</CERTIFICATEOFORIGIN></ADDITIONALSHIPPINGDOCS>
     */
select @vRuleCondition   = '~Carrier~ = ''FEDEX'' and ~AddressRegion~ = ''I'' and ~ShipVia~ in (''FEDXI1F'', ''FEDXI1P'', ''FEDXIE'', ''FEDXIEF'', ''FEDEXIPF'', ''FEDXIGC'')',
       @vRuleDescription = 'FEDEX International services which require Commercial Invoice',
       @vRuleQuery       = 'select ''Y''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I' /* In Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Commercial Invoice: Default rule */
select @vRuleCondition   = null /* Default */,
       @vRuleDescription = 'International services - default rule for Commercial Invoice',
       @vRuleQuery       = 'select ''N''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #2 - CN22 */
/******************************************************************************/
select @vRuleSetName        = 'CN22',
       @vRuleSetDescription = 'CN22 requirement for all UPS Mail Innovations',
       @vRuleSetFilter      = '~DocumentType~ = ''CN22''',
       @vSortSeq            = 0,
       @vStatus             = 'I' /* In Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* UPS */
select @vRuleCondition   = '~Carrier~ = ''UPS'' and ~AddressRegion~ = ''I'' and ~ShipVia~ in (''UPSMIEC'', ''UPSMIP'')',
       @vRuleDescription = 'UPS International services which require CN22',
       @vRuleQuery       = 'select ''Y''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* CN22: Default rule*/
select @vRuleCondition   = null,
       @vRuleDescription = 'International services - default rule for CN22',
       @vRuleQuery       = 'select ''N''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for : CN22 Info */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'CN22Info';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rules to get CN22 Details */
/******************************************************************************/
select @vRuleSetName        = 'PreUpdateCN22Info',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Get CN22 Details',
       @vStatus             = 'A' /* A-Active , I-InActive , NA-Not applicable */,
       @vSortSeq            = 100; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Update info */
/*----------------------------------------------------------------------------*/
/* Update required CN22 details */
select @vRuleCondition   = '~LPNId~ is not null',
       @vRuleDescription = 'Get required CN22 details',
       @vRuleQuery       = 'insert into #ttCN22Info (LPNId, OrderId, SKU, CoO, Description, Quantity, Weight, WeightUoM)
                              select L.LPNId, L.OrderId, L.SKU, coalesce(~DefaultCoO~, L.CoO), ''Apparel'',
                                     L.Quantity, L.LPNWeight, ''LBS''
                              from LPNs L
                              where (L.LPNId = ~LPNId~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
