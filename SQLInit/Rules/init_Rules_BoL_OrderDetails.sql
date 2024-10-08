/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/24  RV      Inactive the rule update shipper info (HA-2390)
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
/* Rules for : PackingList Details */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'BoLOrderDetails';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Generate BoL Order details if different from standard */
/******************************************************************************/
select @vRuleSetName        = 'BoL_OrderDetailsGenerate',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Generate BoL Customer Order Details',
       @vSortSeq            = 100, -- Initialize for this set
       @vStatus             = 'NA' /* A-Active , I-InActive , NA-Not applicable */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule - Get BoL Order Details - The counts have to calculated for Palletized and Non-Palletized Inventory */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'BoLOrderDetails: If no details found for the given BoLid then we need to insert those details into the BoLOrderDetails Table',
       @vRuleQuery       = 'if (not exists(select * from BoLOrderDetails where (BoLId = ~BoLId~))
                              insert into #BoLOrderDetails
                                   (BoLId, CustPO, NumPallets, NumLPNs, NumInnerPacks, NumUnits,
                                    NumPackages, TotalVolume, TotalWeight)
                              select ~BoLId~, OH.CustPO, count(distinct L.PalletId), count(L.LPNId), sum(LI.InnerPacks), sum(LI.Quantity),
                                    sum(LI.Packages), sum(L.LPNVolume), sum(L.LPNWeight)
                              from #ttLPNInfo LI
                                join LPNs          L on (L.LPNId      = LI.LPNId )
                                join OrderHeaders OH on (OH.OrderId   = L.OrderId)
                              group by OH.CustPO',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Update Bol Order Details */
/******************************************************************************/
select @vRuleSetName        = 'BoLOrderDetails_Updates',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update the fields on BoL Order Details',
       @vStatus             = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq            = 200;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Update Order Detail info */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update any customized details for BoL Order details',
       @vRuleQuery       = 'Update BOD
                            set BOD.ShipperInfo = ''DEPT: '' + BOD_Reference1 +
                                                  '' DC: '' + BOD_Reference2 +
                                                  '' DTL: '' + BOD_Reference3 -- right(B.VICSBoLNumber, 7)
                            from #BoLOrderDetails BOD join BoLs B on BoD.BoLId = B.BoLId',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
