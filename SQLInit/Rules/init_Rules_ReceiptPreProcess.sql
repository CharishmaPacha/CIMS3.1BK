/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/13  SV      Managed the Returns ReceiptType (OB2-1794)
  2020/04/14  TK      Inventory Classes to empty if they send null (HA-84)
  2020/04/14  VM      Standard version corrections (HA-118)
  2019/02/12  TD      Initial version(CID-102)
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
/* Rules for Receipt Header Updates to be done on Preprocess */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'ReceiptHdr_PreprocessUpdates';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set to update with defaults */
/******************************************************************************/
select @vRuleSetName        = 'RH_UpdateWithDefaults',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'On import of RH, some fields may have to be initialized',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule update Receiving Warehouse of RH */
select @vRuleCondition   = null,
       @vRuleDescription = 'Receiving Warehouse: Change Warehouse of Receipt to receiving Warehouse',
       @vRuleQuery       = 'Update RH
                            set Warehouse = dbo.fn_GetMappedValue(''HOST'', RH.Warehouse, ''CIMS'', ''Warehouse'', ''RHImport'', RH.BusinessUnit)
                            from ReceiptHeaders RH
                            where (RH.ReceiptId = ~ReceiptId~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule update PrepareRecvFlag of RH */
select @vRuleCondition   = null,
       @vRuleDescription = 'PrepareRecvFlag: By default ignore',
       @vRuleQuery       = 'Update ReceiptHeaders
                            set PrepareRecvFlag = ''I'' /* Ignore */
                            where (ReceiptId = ~ReceiptId~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule update Returns ReceiptType 'R' to 'RMA' */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update Returns ReceiptType R to RMA',
       @vRuleQuery       = 'Update ReceiptHeaders
                            set ReceiptType = ''RMA'' /* Receiving Returns */
                            where (ReceiptId = ~ReceiptId~) and (~ReceiptType~ = ''R'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */

/******************************************************************************/
/******************************************************************************/
/* Rules for Receipt Detail Updates to be done on Preprocess */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'ReceiptDtl_PreprocessUpdates';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set to update PutawayClass */
/******************************************************************************/
select @vRuleSetName        = 'RD_UpdateWithDefaults',
       @vRuleSetFilter      = '~Operation~ like ''Import_ROD''',
       @vRuleSetDescription = 'Default some fields on import of Receipt details',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule update ExtrQtyAllowed */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update ExtraQtyAllowed on import Receipt Details',
       @vRuleQuery       = 'Update ReceiptDetails
                            set ExtraQtyAllowed = cast((QtyOrdered * coalesce(~OverReceiptPercent~, 5))/100 as Int),
                                InventoryClass1 = coalesce(InventoryClass1, ''''),
                                InventoryClass2 = coalesce(InventoryClass2, ''''),
                                InventoryClass3 = coalesce(InventoryClass3, ''''),
                                ModifiedDate    = current_timestamp,
                                ModifiedBy      = ''CIMSAgent''
                            where (ReceiptId = ~ReceiptId~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
