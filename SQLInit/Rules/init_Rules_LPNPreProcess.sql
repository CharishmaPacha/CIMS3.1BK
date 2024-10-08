/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/08  MS      Initial version (JL-58)
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
/* Rules for LPN(s) Updates to be done on Preprocess */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'LPN_PreprocessUpdates';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set to update cross docked LPNs info on LPNs not yet received */
/******************************************************************************/
select @vRuleSetName        = 'LPN_PreprocessLPNsNotReceived',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'On import of ASN LPN or creation of LPN, some fields may have to be initialized',
       @vStatus             = 'I' /* Inactive */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule update cross docked LPNs info on UDF6, with Appending SKU */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update cross docked LPNs info on UDF6, with Appending SKU ',
       @vRuleQuery       = 'Update L
                            set L.UDF6 = coalesce(L.UDF4, ''N'') + ''-'' + coalesce(L.UDF5, '''') + ''-'' + S.SKU
                            from LPNs L
                              join SKUs S on (L.SKUId = S.SKUId)
                            where (LPNId = ~LPNId~) and
                                  (Status = ''T'' /* In Transit */)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule update cross docked LPNs info on UDF6, with Appending MULTISKU */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update cross docked LPNs info on UDF6, with Appending SKU if LPN is multi SKU ',
       @vRuleQuery       = 'Update L
                            set L.UDF6 = coalesce(L.UDF4, ''N'') + ''-'' + coalesce(L.UDF5, '''') + ''-'' + ''MULTISKU''
                            from LPNs L
                            where (LPNId = ~LPNId~) and
                                  (coalesce(SKUId, '''') = '''') and
                                  (NumLines <> 0) and
                                  (Status = ''T'' /* In Transit */)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */

Go
