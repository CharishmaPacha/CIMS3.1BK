/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/25  SK      Migrate rules under Init_Rules_PickingScanEntityOption to this file (BK-452)
  2021/01/29  RKC     Made changes to use fn_OrderHeaders_IsInternationalOrder (BK-136)
  2021/01/12  PK      Ported changes done by Pavan (HA-1897)
  2020/09/09  TK      Picking configuration for replenish Unit pick (HA-1398)
  2020/08/06  MS      Added rule for Transfers Picking Configuration (HA-1273)
  2020/07/02  AY      Corrected standard rules for Picking_CoOConfirmations (HA-427)
  2020/05/15  TK      Migrated from CID (HA-543)
  2019/05/15  SV      Added Picking_CoOConfirmations (CID-135)
  2018/04/06  AY/RV   Refactor the pickcing configuration rules (S2G-579)
  2018/03/30  RV      Added BatchPicking_SingleOrderPick (S2G-534)
  2018/03/21  RV      Added rules BatchPicking for ReplenishWaves (S2G-421)
  2016/05/08  TK      Initial version
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
/* Rules for identify Picking Configurations */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'PickingConfigurations';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set- Default set of rules that are applicable for Replenish waves */
/******************************************************************************/
select @vRuleSetName        = 'PickingConfig_ReplenishWaves',
       @vRuleSetFilter      = '~WaveType~ in (''RU'', ''RP'', ''R'')',
       @vRuleSetDescription = 'RuleSet to get Picking Options For Replenish',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 10; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Pick Cases for Replenish */
select @vRuleCondition   = '~TaskType~ = ''CS'' and ~PalletType~ = ''P''',
       @vRuleDescription = 'Configuration for picking Cases for Replenish Wave onto a Pallet',
       @vRuleQuery       = 'select ''PickingConfig_CasePick_Multiple''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Pick LPNs for Replenish */
select @vRuleCondition   = '~TaskType~ = ''L'' and ~PalletType~ = ''P''',
       @vRuleDescription = 'Configuration for picking LPNs for Replenish Wave onto a Pallet',
       @vRuleQuery       = 'select ''PickingConfig_LPNPickToPallet''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Replenish Unit Pick to Pallet scanning each item */
select @vRuleCondition   = '~TaskType~ = ''U'' and ~PalletType~ = ''P''',
       @vRuleDescription = 'Replenish Unit Pick to Pallet scanning each item',
       @vRuleQuery       = 'select ''PickingConfig_UnitPickSingleScan''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #3 - Pick Units with respect to Order for some waves */
/******************************************************************************/
select @vRuleSetName        = 'PickingConfig_SingleCartonPick',
       @vRuleSetFilter      = '~WaveType~ in (''XYZ'')',
       @vRuleSetDescription = 'RuleSet to get Picking Options when picking all items for one carton only',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 20;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Pick Units with respect to Order */
select @vRuleCondition   = '~TaskType~ in (''U'', ''CS'')',
       @vRuleDescription = 'Pick Cases/Units  by scanning each item once',
       @vRuleQuery       = 'select ''PickingConfig_PicksForSingleCarton''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #99 - Default set of rules that are applicable for most waves */
/******************************************************************************/
select @vRuleSetName        = 'PickingConfig_DefaultWaves',
       @vRuleSetFilter      = '~WaveType~ not in (''RU'', ''RP'', ''R'')',
       @vRuleSetDescription = 'RuleSet to get Picking Options',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 30;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Pick Units to Generate Temp Label for Transfer Wave */
select @vRuleCondition   = '~TaskType~ = ''U'' and ~WaveType~ in (''XFER'', ''BPP'', ''BCP'')',
       @vRuleDescription = 'Pick Units to Generate Temp Label for Transfer Wave',
       @vRuleQuery       = 'select ''PickingConfig_UnitPickSingleScanGenTempLabel''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Pick Units to Cart/Pallet scanning each item */
select @vRuleCondition   = '~TaskType~ = ''U''', -- and ~PalletType~ = ''C''',
       @vRuleDescription = 'Pick Units to Cart/Temp Label by scanning each item once',
       @vRuleQuery       = 'select ''PickingConfig_UnitPickSingleScan''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Pick units to cart/pallet by scanning each and every unit */
select @vRuleCondition   = '~TaskType~ = ''U'' and ~PalletType~ = ''C''',
       @vRuleDescription = 'Pick Units to cart by scanning each individual unit',
       @vRuleQuery       = 'select ''UnitPick_MultiScan''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Pick LPNs to Pallet */
select @vRuleCondition   = '~TaskType~ = ''L'' and ~PalletType~ <> ''C''',
       @vRuleDescription = 'Pick LPNs to Pallet',
       @vRuleQuery       = 'select ''PickingConfig_LPNPickToPallet''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Pick LPNs to Cart */
select @vRuleCondition   = '~TaskType~ = ''L'' and ~PalletType~ = ''C''',
       @vRuleDescription = 'Pick LPNs to Cart w/ LPNs being moved onto Cart',
       @vRuleQuery       = 'select ''LPNPickToCart''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Pick LPNs to Cart positions/bins */
select @vRuleCondition   = '~TaskType~ = ''L'' and ~PalletType~ = ''C''',
       @vRuleDescription = 'Pick LPNs to Cart Positions with inventory transferred into Cart bins',
       @vRuleQuery       = 'select ''LPNPickToCartPositions''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;


/******************************************************************************/
/******************************************************************************/
/* Rules for Picking Scan Entity option */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'PickingScanEntityOption';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - Picking scan Entity Option */
/******************************************************************************/
select @vRuleSetName        = 'Picking_ScanEntityOption',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Allowed scan entities for picking',
       @vStatus             = 'A',
       @vSortSeq            = 100;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule - If user has permissions, then allow user to scan any option to pick */
select @vRuleCondition   = 'dbo.fn_Permissions_IsAllowed(~UserId~, ''RFAllowScanAllOptionsToPick'') <> ''0''',
       @vRuleDescription = 'If user has permission, allow to scan SKU (or attributes), Location or LPN to confirm',
       @vRuleQuery       = 'select ''*SUCABOL;Scan SKU/Loc/LPN''' /* SKU (or attributes), LPN, Location */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Scan options for LPN pick from Reserve or Bulk */
select @vRuleCondition   = '~TaskDetailPickType~ = ''L'' and ~FromLocationType~ in (''R'', ''B'')', /* Reserve/Bulk */
       @vRuleDescription = 'Picking LPNs from Reserve or Bulk, confirm by scanning LPN only',
       @vRuleQuery       = 'select ''L;Scan LPN''' /* LPN */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Scan options for Case pick from Reserve or Bulk */
select @vRuleCondition   = '~TaskDetailPickType~ = ''CS'' and ~FromLocationType~ in (''R'', ''B'')', /* Reserve/Bulk */
       @vRuleDescription = 'Picking Cases from Reserve or Bulk, confirm by scanning LPN only',
       @vRuleQuery       = 'select ''L;Scan LPN''', /* LPN */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Scan options for Unit pick from Reserve or Bulk */
select @vRuleCondition   = '~TaskDetailPickType~ = ''U'' and ~FromLocationType~ in (''R'', ''B'')', /* Reserve/Bulk */
       @vRuleDescription = 'Picking Units from Reserve or Bulk, confirm by scanning LPN only',
       @vRuleQuery       = 'select ''L;Scan LPN''', /* LPN */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Scan options for Unit pick from Reserve or Bulk */
select @vRuleCondition   = '~TaskDetailPickType~ = ''U'' and ~FromLocationType~ in (''R'', ''B'')', /* Reserve/Bulk */
       @vRuleDescription = 'Picking Units from Reserve or Bulk, confirm by scanning SKU attributes or LPN',
       @vRuleQuery       = 'select ''SUCABL;Scan SKU/LPN'' ', /* SKU/UPC/CaseUPC/AlternateSKU/Barcode/LPN */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Scan options for PTL Case Picks */
select @vRuleCondition   = '~WaveType~ in (''PTL'') and ~TaskDetailPickType~ = ''CS'' and ~FromLocationType~ = ''K''', /* Picklane */
       @vRuleDescription = 'Picking Cases for PTL, allow scanning CaseUPC only',
       @vRuleQuery       = 'select ''C;Scan CaseUPC'' ', /* CaseUPC */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Scan options for PTL Unit Picks */
select @vRuleCondition   = '~WaveType~ in (''PTL'') and ~TaskDetailPickType~ = ''U'' and ~FromLocationType~ = ''K''', /* Picklane */
       @vRuleDescription = 'Picking Units for PTL, allow scanning UPC only',
       @vRuleQuery       = 'select ''U;Scan UPC'' ', /* UPC */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Scan options for Case pick from Picklane */
select @vRuleCondition   = '~WaveType~ in (''PTLC'') and ~TaskDetailPickType~ = ''CS'' and ~FromLocationType~ = ''K''', /* Picklane */
       @vRuleDescription = 'Picking Cases for PTLC, allow scanning CaseUPC only',
       @vRuleQuery       = 'select ''C;Scan CaseUPC'' ', /* CaseUPC */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Scan options for Case pick from Picklane */
select @vRuleCondition   = '~TaskDetailPickType~ = ''CS'' and ~FromLocationType~ = ''K''', /* Picklane */
       @vRuleDescription = 'Picking Cases from Picklane, allow scanning any of SKU attributes or Location',
       @vRuleQuery       = 'select ''SUCAB;Scan SKU/UPC'' ', /* SKU/UPC/CaseUPC/AlternativeSKU/SKUBarcode */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 98;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule 1.5 - Scan options for Unit pick from Picklane */
select @vRuleCondition   = '~TaskDetailPickType~ = ''U'' and ~FromLocationType~ = ''K''', /* Picklane */
       @vRuleDescription = 'Picking Units from Picklane, allow scanning any of SKU attributes or Location',
       @vRuleQuery       = 'select ''SUCAB;Scan SKU/UPC'' ', /* SKU/UPC/CaseUPC/AlternativeSKU/SKUBarcode */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;


/******************************************************************************/
/******************************************************************************/
/* Rules for : Rules to determine if CoO is required */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Picking_CoOConfirmations';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set: Determine if CoO capture is required during picking */
/******************************************************************************/
select @vRuleSetName        = 'CoORequired',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'RuleSet to identify whether CoO Capture is required during picking',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 100;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: CoO is required for an international order */
select @vRuleCondition   = null,
       @vRuleDescription = 'CoO require: If International Order or Shipping to PR',
       @vRuleQuery       = 'select dbo.fn_OrderHeaders_IsInternationalOrder (~OrderId~)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: CoO is not required by default */
select @vRuleCondition   = null,
       @vRuleDescription = 'CoO required: Not required by default',
       @vRuleQuery       = 'select ''N''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
