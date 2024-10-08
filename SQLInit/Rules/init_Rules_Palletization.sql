/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/31  MS      Bug fixes to Palletize the LPNs based on volume (JL-280)
  2020/09/13  MS      Made changes to consider ReceiptDetails aswell for Sortation (JL-236)
  2020/01/07  MS      Initial version (JL-58)
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
/* Rules to do required updates for Palletization */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'PalletizationUpdates';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Description of this RuleSet */
/******************************************************************************/
select @vRuleSetName        = 'PalletizationUpdates',
       @vRuleSetDescription = 'Do required updates for Palletization',
       @vRuleSetFilter      = null,
       @vSortSeq            = 0, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to select LPNs for Palletization */
select @vRuleCondition   = null,
       @vRuleDescription = 'Palletization: select Intransit LPNs of selected Receipts',
       @vRuleQuery       = 'insert into #LPNsToSort(ReceiptId, LPNId, PalletId, SKUId, SKU, Quantity,
                                                    CartonVolume, PalletGroup, Palletized)
                              select L.ReceiptId, L.LPNId, L.PalletId, coalesce(L.SKUId, -1), L.SKU, L.Quantity,
                                     L.ActualVolume, L.UDF10, ''N''
                              from LPNs L
                                join #LPNsInTransit LIT on (L.LPNId  = LIT.EntityId)
                              where (L.PalletId is null)
                              order by L.UDF10, L.Quantity;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Identify the Pallet groups and the SKU, count and volume of LPNs in each group */
select @vRuleCondition   = null,
       @vRuleDescription = 'Palletization: Get all the Pallet Groups and their respective SKUs',
       @vRuleQuery       = 'insert into #PalletGroups(PalletGroup, SKUId, NumLPNsInGroup, TotalCartonVolume)
                              select LTS.PalletGroup, case when count(distinct LTS.SKUId) > 0 then min(LTS.SKUId) else null end,
                                     count(*), sum(LTS.CartonVolume)
                              from #LPNsToSort LTS
                              group by PalletGroup',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to Insert info into #temp table which has Carton Dimensions */
select @vRuleCondition   = null,
       @vRuleDescription = 'Palletization: Get Pallet Tie/High if PalletGroup has single SKUs',
       @vRuleQuery       = 'Update #PalletGroups
                            set SKU              = S.SKU,
                                PalletTie        = S.PalletTie,
                                PalletHigh       = S.PalletHigh,
                                NumLPNsPerPallet = S.PalletTie * S.PalletHigh
                            from #PalletGroups PG join SKUs S on (PG.SKUId = S.SKUId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update the Seq no for each LPN in the group */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update SeqIndex/Volume, for LPNs',
       @vRuleQuery       = 'with SeqIndexUpdate (LPNId, PalletGroup, SeqIndex)
                            as
                             (
                               select LTS.LPNId, LTS.PalletGroup, row_number() over(partition by LTS.PalletGroup order by LTS.SKU, newid()) As SeqIndex
                               from #LPNsToSort LTS join #PalletGroups PG on LTS.PalletGroup = PG.PalletGroup
                             )
                            update #LPNsToSort
                            set SeqIndex  = SI.SeqIndex
                            from SeqIndexUpdate SI
                              join #LPNsToSort LTS on LTS.LPNId = SI.LPNId',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update the Pallet Number for Pallets with NumLPNsPerPallet */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update Pallet number for the ones we know the NumLPNsPerPallet',
       @vRuleQuery       = 'Update LTS
                            set PalletNumber = ceiling(LTS.SeqIndex * 1.0 /PG.NumLPNsPerPallet),
                                Palletized   = ''Y''
                            from #LPNstoSort LTS join #PalletGroups PG on LTS.PalletGroup = PG.PalletGroup
                            where LTS.Palletized = ''N'' and PG.NumLPNsPerPallet > 0',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update the Pallet Number for LPNs with volume */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update Pallet number for the LPNs with volume which have not been palletized before',
       @vRuleQuery       = 'exec pr_Receipts_PalletizeLPNsByVolume ~PalletVolume~, ~BusinessUnit~, ~UserId~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update the Pallet Number for remaining LPNs using Std LPNs per Pallet */
select @vRuleCondition   = '~StdLPNsPerPallet~ > 0',
       @vRuleDescription = 'Update Pallet number for remaining LPNs using Std LPNsPerPallet',
       @vRuleQuery       = 'Update LTS
                            set PalletNumber = ceiling(LTS.SeqIndex * 1.0 / ~StdLPNsPerPallet~)
                            from #LPNstoSort LTS join #PalletGroups PG on LTS.PalletGroup = PG.PalletGroup
                            where LTS.Palletized = ''N''',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
