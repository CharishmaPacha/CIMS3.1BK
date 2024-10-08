/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/26  NB      Initial version (CIMSV3-963)
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
/* Rule Set : Determine Entity Types for Records in temp tables of TEntityValuesTable type without Entity Type value */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'IdentifyEntityType';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1     */
/******************************************************************************/
/* Rule Conditions and Queries are validated on Insert. This Temp Table is created such that the validations are done correctly */
declare @ttSelectedEntities  TEntityValuesTable;
if (object_id('tempdb..#ttSelectedEntities') is null)
  select * into #ttSelectedEntities from @ttSelectedEntities;

select @vRuleSetName        = 'EntityType_ttSelectedEntities',
       @vRuleSetFilter      = '(object_id(''tempdb..#ttSelectedEntities'') is not null)',
       @vRuleSetDescription = 'Identify Entity Type of #ttSelectedEntities Temp Table Records',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule : Verify LPN Entity Type  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '(exists (select RecordId from #ttSelectedEntities where EntityType is null))',
       @vRuleDescription = 'LPN : Verify for LPN Records in #ttSelectedEntities',
       @vRuleQuery       = 'Update SE
                            set EntityType = ''LPN'',
                                EntityId   = coalesce(nullif(SE.EntityId, 0), L.LPNId)
                            from #ttSelectedEntities SE
                            left outer join LPNs L on (L.LPN = SE.EntityKey) and (L.BusinessUnit = ~BusinessUnit~)
                            where (SE.EntityType is null) and (L.LPN is not null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule : Verify Order Entity Type  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '(exists (select RecordId from #ttSelectedEntities where EntityType is null))',
       @vRuleDescription = 'Order : Verify for Order Header Records in #ttSelectedEntities',
       @vRuleQuery       = 'Update SE
                            set EntityType = ''Order'',
                                EntityId   = coalesce(nullif(SE.EntityId, 0), OH.OrderId)
                            from #ttSelectedEntities SE
                            left outer join OrderHeaders OH on (OH.PickTicket = SE.EntityKey) and (OH.BusinessUnit = ~BusinessUnit~)
                            where (SE.EntityType is null) and (OH.PickTicket is not null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule : Verify Pallet Entity Type  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '(exists (select RecordId from #ttSelectedEntities where EntityType is null))',
       @vRuleDescription = 'Pallet : Verify for Pallet Records in #ttSelectedEntities',
       @vRuleQuery       = 'Update SE
                            set EntityType = ''Pallet'',
                                EntityId   = coalesce(nullif(SE.EntityId, 0), P.PalletId)
                            from #ttSelectedEntities SE
                            left outer join Pallets P on (P.Pallet = SE.EntityKey) and (P.BusinessUnit = ~BusinessUnit~)
                            where (SE.EntityType is null) and (P.Pallet is not null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule : Verify Wave Entity Type  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '(exists (select RecordId from #ttSelectedEntities where EntityType is null))',
       @vRuleDescription = 'Wave : Verify for Wave Records in #ttSelectedEntities',
       @vRuleQuery       = 'Update SE
                            set EntityType = ''Wave'',
                                EntityId   = coalesce(nullif(SE.EntityId, 0), W.RecordId)
                            from #ttSelectedEntities SE
                            left outer join Waves W on (W.BatchNo = SE.EntityKey) and (W.BusinessUnit = ~BusinessUnit~)
                            where (SE.EntityType is null) and (W.BatchNo is not null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule : Verify Load Entity Type  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '(exists (select RecordId from #ttSelectedEntities where EntityType is null))',
       @vRuleDescription = 'Load : Verify for Load Records in #ttSelectedEntities',
       @vRuleQuery       = 'Update SE
                            set EntityType = ''Load'',
                                EntityId   = coalesce(nullif(SE.EntityId, 0), LD.LoadId)
                            from #ttSelectedEntities SE
                            left outer join Loads LD on (LD.LoadNumber = SE.EntityKey) and (LD.BusinessUnit = ~BusinessUnit~)
                            where (SE.EntityType is null) and (LD.LoadNumber is not null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule : Verify UCC Sequence for LPN Entity Type

   It is possible the the input could be different value used instead of LPNId, in such a case, verify the value
   this is separated as this has performance implications  
  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '(exists (select RecordId from #ttSelectedEntities where EntityType is null))',
       @vRuleDescription = 'UCCSeqNo : Verify for UCCSeqNo Records in #ttSelectedEntities',
       @vRuleQuery       = 'Update SE
                            set EntityType = case when (L.LPN is not null) then ''LPN'' else SE.EntityType end,
                                EntityId   = coalesce(SE.EntityId, L.LPNId),
                                EntityKey  = L.LPN
                            from #ttSelectedEntities SE
                            left outer join LPNs L on (L.LPNId = dbo.fn_LPNs_GetScannedLPN(SE.EntityKey, ~BusinessUnit~, default /* Options */)) and (L.BusinessUnit = ~BusinessUnit~)
                            where (SE.EntityType is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

if (object_id('tempdb..#ttSelectedEntities') is not null)
  drop table #ttSelectedEntities;
/******************************************************************************/

Go
