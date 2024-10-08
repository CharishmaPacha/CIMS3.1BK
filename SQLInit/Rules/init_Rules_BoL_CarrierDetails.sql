/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/02  RT      Initial version (FB-2225)
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
/* Rules for : BoL Carrier Details */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'BoLCarrierDetails';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* BoL Carrier Details - Generate if standard generation is not applicable only */
/******************************************************************************/
select @vRuleSetName        = 'BoL_CarrierDetailsGenerate',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Get BoL Carrier Details',
       @vSortSeq            = 100, -- Initialize for this set
       @vStatus             = 'NA' /* A-Active , I-InActive , NA-Not applicable */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Generate BoL Carrier Details - if there is a need to do different than standard version */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '(not exists(select * from BoLCarrierDetails where BoLId = ~BoLId~))',
       @vRuleDescription = 'BoLCarrierDetails: If no details found for the given BoLId then we need to insert those details into the BoLOrderDetails Table',
       @vRuleQuery       = 'insert into #BoLCarrierDetails(BoLId, HandlingUnitQty, HandlingUnitType, PackageQuantity, PackageType,
                                                           TotalVolume, TotalWeight, Hazardous)
                              select ~BoLId~, count(distinct L.PalletId), ''plts'',
                                    sum(LI.InnerPacks) /* Packages */, ''ctns'',
                                    sum(L.LPNVolume) + (count(distinct L.PalletId) * ~PalletTareVolume~),
                                    sum(L.LPNWeight) + (count(distinct L.PalletId) * ~PalletTareWeight~),
                                    ''N'' /* Hazardous - No for TD by default */
                              from LPNs L
                                join #ttLPNInfo   LI on (L.LPNId = LI.LPNId)
                                join OrderHeaders OH on (OH.OrderId   = L.OrderId)
                              where (coalesce(L.LoadId, 0) <> 0)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* BoL Carrier Details - Update additional fields */
/******************************************************************************/
select @vRuleSetName        = 'BoLCarrierDetails_Updates',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Rule Set to update fields on BoL Carrier Details',
       @vStatus             = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq            = 200;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Update NMFC info */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update with default NFMC values',
       @vRuleQuery       = 'Update #BoLCarrierDetails
                            set NMFCCode          = dbo.fn_Controls_GetAsString(''VICSBoL'', ''NMFCCode'',          '''', ~BusinessUnit~, ~UserId~),
                                NMFCClass         = dbo.fn_Controls_GetAsString(''VICSBoL'', ''NMFCClass'',         '''', ~BusinessUnit~, ~UserId~),
                                NMFCCommodityDesc = dbo.fn_Controls_GetAsString(''VICSBoL'', ''NMFCCommodityDesc'', '''', ~BusinessUnit~, ~UserId~);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
