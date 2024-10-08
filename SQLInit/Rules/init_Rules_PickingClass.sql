/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/02/08  MS      Corrections in descriptions & added sortseq (CID-52)
  2018/02/06  AY      Status changed for unneccessary rules (CID-52)
  2018/01/14  AY      Ensure rules apply when no Flags are given (as it means both classes when Flags = '') S2G-74
  2016/09/02  TK      Added Default rule to update Picking Class to 'FL'
  2016/05/05  TK      Added rules for Break Pack (FB-648)
  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2015/09/08  TK      Revised rules (ACME-179)
  2015/03/13  AK      Changes made to control data using procedure.
                      Splitted Rules,RuleSets(Init_Rules) based on RuleSetType.
  2015/03/12  DK      Added rules to print Magento PackingList and ReturnPackingList.
  2015/03/11  DK      Added rules to print ReturnPackingLists
  2015/01/25  SV      Initial LL version
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
select @vRuleSetType = 'LPN_PickingClass';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - Picking Class */
/******************************************************************************/
select @vRuleSetDescription = 'Picking class Rule Set for LPN picking class',
       @vRuleSetName        = 'LPN_PickingClass',
       @vRuleSetFilter      = '~PickingClassType~ = ''LPN'' and (~Flags~ = ''PIC'' or ~Flags~ = '''')',
       @vSortSeq            = 0,
       @vStatus             = 'A' /* A-Active, I-In-Active, NA-Not applicable */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
select @vRuleDescription = 'Picking Rule for Picklane and Unit storage type',
       @vRuleCondition   = '~LocationType~ = ''K'' and ~LocStorageType~ = ''U''',
       @vRuleQuery       = 'select ''U''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription , @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
select @vRuleDescription = 'Picking Rule for Picklane and storage type UF',
       @vRuleCondition   = '~LocationType~ = ''K'' and ~LocStorageType~ = ''UF''',
       @vRuleQuery       = 'select ''U''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
select @vRuleDescription = 'Picking Rule for Picklane and storage type UH',
       @vRuleCondition   = '~LocationType~ = ''K'' and ~LocStorageType~ = ''UH''',
       @vRuleQuery       = 'select ''U''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
select @vRuleDescription = 'Picking class Rule for OL',
       @vRuleCondition   = '~PickingClass~ = ''OL''',
       @vRuleQuery       = 'select ''OL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
select @vRuleDescription = 'Picking class Rule for break pack',
       @vRuleCondition   = '~PickingClass~ = ''BP''',
       @vRuleQuery       = 'select ''BP''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription , RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
select @vRuleDescription = 'Picking Class for Picklane and Case/Inner Pack storage',
       @vRuleCondition   = '~LocationType~ = ''K'' and ~LocStorageType~ = ''P''',
       @vRuleQuery       = 'select ''CS''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Picking Class: LPNQuantity >= UnitsPerLPN = FL, if using SKU Std Qty */
select @vRuleDescription = 'Picking class rule based on LPNQuantity and units per LPN',
       @vRuleCondition   = 'cast(~LPNQuantity~ as int) >= cast(~UnitsPerLPN~ as int) and cast(~UnitsPerLPN~ as int) > 0 and ~UseSKUStandardQty~ = ''Y''',
       @vRuleQuery       = 'select ''FL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Picking Class: LPNQuantity < UnitsPerLPN = PL, if using SKU Std Qty */
select @vRuleDescription = 'Picking class rule based on LPNQuantity and units per LPN for Partial LPN',
       @vRuleCondition   = 'cast(~LPNQuantity~ as int) < cast(~UnitsPerLPN~ as int) and cast(~UnitsPerLPN~ as int) > 0 and ~UseSKUStandardQty~ = ''Y''',
       @vRuleQuery       = 'select ''PL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Picking Class: LPNPercentFull >= PercentFullPalletThreshold, if using the FL */
select @vRuleDescription = 'Picking class rule Full LPN',
       @vRuleCondition   = 'cast(~LPNPercentFull~ as int) >= cast(~PCFLThreshold~ as int) and ~UseFLThresholdQty~ = ''Y''',
       @vRuleQuery       = 'select ''FL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Picking Class: LPNPercentFull >= PercentPartialPallet Threshold, if using the threshold */
select @vRuleDescription = 'Picking class rule partial LPN',
       @vRuleCondition   = 'cast(~LPNPercentFull~ as int) >= cast(~PCPLThreshold~ as int) and ~UseFLThresholdQty~ = ''Y''',
       @vRuleQuery       = 'select ''PL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Picking Class: If LPN has inner packs then CS */
select @vRuleDescription = 'Picking class rule if LPN has innerpacks',
       @vRuleCondition   = 'cast(~LPNInnerPacks~ as int) > 0',
       @vRuleQuery       = 'select ''CS''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Picking Class: Default Rule */
select @vRuleDescription = 'Picking class rule for full LPN',
       @vRuleCondition   = 'cast(~LPNQuantity~ as int) > 0',
       @vRuleQuery       = 'select ''FL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

Go
