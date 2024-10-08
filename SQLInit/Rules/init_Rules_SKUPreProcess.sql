/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/25  AY      Added rule to setup default SKUImageURL (CIMSV3-733)
  2020/05/15  MS      Added default rule to update DisplaySKU (HA-545)
  2020/04/06  TK      Rules to update UoM & InventoryUoM (HA-124)
  2020/02/20  AY      Correct rule for SKUSortOrder to use Size Scale
                      update rule to initialize UnitsPerLPN - moving away from code in SKUs_Preprocess
  2019/05/09  AY      Initialize ShipPack to 1 if zero is passed in (CID-357)
  2019/01/31  AY      Added default rules (CID-51)
  2019/01/30  MS      Initial version (CID-51)
------------------------------------------------------------------------------*/

Go

declare @vRecordId            TRecordId,
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
/* Rules for Updates to be done on Preprocess */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'SKU_PreprocessUpdates';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set to update PutawayClass */
/******************************************************************************/
select @vRuleSetName        = 'SKU_UpdatePutawayClass',
       @vRuleSetFilter      = '~Operation~ like ''UpdatePAClass''',
       @vRuleSetDescription = 'Update SKU Putaway Class on SKU Preprocess',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule update PutawayClass as ABC Class */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update PutawayClass as ABC Class',
       @vRuleQuery       = 'Update S
                            set PutawayClass = ABCClass
                            from SKUs S
                              join #SKUsToProcess STP on (S.SKUId = STP.EntityId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule update PutawayClass to Ownership by default for some clients */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update PutawayClass to Ownership',
       @vRuleQuery       = 'Update S
                            set PutawayClass = coalesce(nullif(S.Ownership, '''') , ~Ownership~)
                            from SKUs S
                              join #SKUsToProcess STP on (S.SKUId = STP.EntityId) and
                                                         (coalesce(S.PutawayClass, '''') = '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule update PutawayClass to 01 by default */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update PutawayClass to default',
       @vRuleQuery       = 'Update S
                            set PutawayClass = ''01''
                            from SKUs S
                              join #SKUsToProcess STP on (S.SKUId = STP.EntityId) and
                                                         (coalesce(S.PutawayClass, '''') = '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set to update SKU defaults */
/******************************************************************************/
select @vRuleSetName        = 'SKU_UpdateDefaults',
       @vRuleSetFilter      = '~Operation~ like ''UpdateDefaults''',
       @vRuleSetDescription = 'Update SKU with defaults on SKU Preprocess',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule update UoM for Prepack SKUs by default */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update SKUs UoM as PP if the SKU exists in SKUPrePacks table',
       @vRuleQuery       = 'Update S
                            set S.UoM = ''PP''
                            from SKUs S
                              join SKUPrePacks SPP on (S.SKUId = SPP.MasterSKUId) and
                                                      (SPP.Status = ''A''/* Active */)
                              join #SKUsToProcess STP on (SPP.MasterSKUId = STP.EntityId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update UnitsPerInnerpack for Prepack SKUs */
select @vRuleCondition   = null,
       @vRuleDescription = 'Prepack SKUs: Update UnitsPerInnerPack to be sum of ComponentQty',
       @vRuleQuery       = ';with SKUUnitsPerIP as
                            (
                              select SPP.MasterSKUId, sum(SPP.ComponentQty) UnitsPerInnerPack
                              from SKUPrePacks SPP
                                join #SKUsToProcess STP on (SPP.MasterSKUId = STP.EntityId) and (SPP.Status = ''A''/* Active */)
                              group by SPP.MasterSKUId
                            )
                            update S
                            set S.UnitsPerInnerPack = SUIP.UnitsPerInnerPack
                            from SKUs S join SKUUnitsPerIP SUIP on (S.SKUId = SUIP.MasterSKUId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update InventoryUoM for prepack SKUs */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update SKUs InventoryUoM as CS for prepacks',
       @vRuleQuery       = 'Update S
                            set InventoryUoM = ''CS''
                            from SKUs S
                              join #SKUsToProcess STP on (S.SKUId = STP.EntityId) and (S.UoM = ''PP'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update default values */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update SKUs with default ones when they are not defined',
       @vRuleQuery       = 'Update S
                            set InnerPacksPerLPN = coalesce(InnerPacksPerLPN, 0),
                                UnitsPerLPN      = case
                                                     when coalesce(InnerPacksPerLPN, 0) > 0 and
                                                          coalesce(UnitsPerInnerPack, 0) > 0 then
                                                       InnerPacksPerLPN * UnitsPerInnerPack
                                                     else
                                                       coalesce(nullif(UnitsPerLPN, 0),
                                                                coalesce(nullif(InnerPacksPerLPN, 0), 1) *
                                                                  coalesce(nullif(UnitsPerInnerPack, 0), 1),
                                                                UnitsPerLPN)
                                                   end,
                                UoM              = coalesce(nullif(UoM, ''''), ''EA''),
                                InventoryUoM     = coalesce(nullif(InventoryUoM, ''''), ''EA''),
                                ReplenishClass   = coalesce(nullif(ReplenishClass, ''''), ''FC'' /* Full Case */),
                                NestingFactor    = coalesce(nullif(NestingFactor, 0), 1),
                                ShipPack         = coalesce(nullif(ShipPack, 0), 1),
                                Ownership        = coalesce(Ownership, ~Ownership~)
                            from SKUs S
                              join #SKUsToProcess STP on (S.SKUId = STP.EntityId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule update SKU Sort Order */
select @vRuleCondition   = null,
       @vRuleDescription = 'SKUs SortOrder: Update considering SKU5 is the size',
       @vRuleQuery       = 'Update S
                            set SKUSortOrder = coalesce(SKU1, '''') +
                                               coalesce(SKU2, '''') +
                                               coalesce(SKU3, '''') +
                                               coalesce(nullif(SKUSortOrder, ''''), M.TargetValue, '''')
                            from SKUs S
                              join #SKUsToProcess STP on (S.SKUId = STP.EntityId)
                              left outer join Mapping M on (M.EntityType = ''Sizes'') and (M.SourceValue = S.SKU5)
                            where (S.SKUSortOrder is null) or (len(S.SKUSortOrder) <= 6)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule update DisplaySKU */
select @vRuleCondition   = null,
       @vRuleDescription = 'SKUs DisplaySKU/DisplaySKUDesc',
       @vRuleQuery       = 'Update S
                            set DisplaySKU     = SKU,
                                DisplaySKUDesc = Description
                            from SKUs S
                              join #SKUsToProcess STP on (S.SKUId = STP.EntityId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule update SKUImageURL */
select @vRuleCondition   = null,
       @vRuleDescription = 'SKUs: Update Image URL (file name)',
       @vRuleQuery       = 'Update S
                            /* SKU Image suffix part which is dynamic and we add this to static path in form */
                            set SKUImageURL = SKU + ''.png''
                            from SKUs S
                              join #SKUsToProcess STP on (S.SKUId = STP.EntityId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
