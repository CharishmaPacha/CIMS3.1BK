/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/20  AY      update thresholds of LPNs on Pallet for deferred Loading (HA Support)
  2021/01/23  TK      When Pallet has LoadId then load all LPNs on pallet immediately (HA-1947)
  2020/06/16  OK      Rule change to do not differ updates if Pallet has less than 50 LPNs (HA-967)
  2019/10/28  TK      Initial Revision (S2GCA-970)
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
/* Rules required to Load Pallet/LPN */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Loading_LoadPalletOrLPN';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Pallet or LPN Loading */
/******************************************************************************/
select @vRuleSetName        = 'LoadPalletOrLPN',
       @vRuleSetDescription = 'Load Pallet or LPN',
       @vRuleSetFilter      = null,
       @vSortSeq            = 100, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule - Load Pallet: if Pallet is already loaded or LPNs on pallet count is less than 50 then load immediately otherwise defer loading */
select @vRuleCondition   = '~EntityType~ = ''Pallet''',
       @vRuleDescription = 'Load Pallet: if Pallet is already loaded or LPNs on pallet count is less than 50 then load immediately otherwise defer loading',
       @vRuleQuery       = 'select case when ~PalletLoadId~ is not null             then ''I'' /* Immediate */
                                        when cast(~PalletNumLPNs~ as integer) < 200 then ''I'' /* Immediate */
                                        when (~EntityStatus~ = ''L'' /* Loaded */)  then ''I'' /* Immediate */
                                        else ''D''/* Defer */
                                   end',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Load LPN: Load immediately if it is an LPN */
select @vRuleCondition   = '~EntityType~ = ''LPN''',
       @vRuleDescription = 'Load LPN: Load immediately if it is an LPN',
       @vRuleQuery       = 'select ''I''/* Immediate */',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
