/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/11  TK      Initial version (HA-1238)
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
/* Rules for : Custom Validations for creating inventory LPNs */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType   = 'CreateLPNs_Validations';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Custom validations for creating inventory LPNs */
/******************************************************************************/
select @vRuleSetName        = 'CreateLPNs_Validations',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Rule Sets to validate the inventory while creating LPNs',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 10; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Create Kits: Check if there is enough component inventory to make kits */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~Operation~ = ''Orders_CreateKits''',
       @vRuleDescription = 'Create Kits: Check if there is enough component inventory to make kits ',
       @vRuleQuery       = 'declare @vMaxKitsToCreate TCount,
                                    @vKitsToCreate    TCount;

                            select @ResultParam = null;

                            /* Procedure to Get the Max Kits to Create */
                            exec pr_LPNs_CreateLPNs_MaxKitsToCreate ~BusinessUnit~, ~UserId~, @vMaxKitsToCreate output;

                            select @vKitsToCreate = ~NumLPNsToCreate~ * Quantity from #CreateLPNDetails;
                            
                            /* CreateLPNs: No Inventory in Location to Create Kits */
                            if (not exists(select * from #InventoryToConsume)) or (@vMaxKitsToCreate = 0)
                              select @ResultParam = ''CreateLPNs_NoInventoryToCreateKits''
                            else
                            /* CreateLPNs: Short of Inventory to Create Kits */
                            if (@vMaxKitsToCreate < @vKitsToCreate)
                              select @ResultParam = ''CreateLPNs_NotEnoughInventoryToCreateKits''

                            insert into #ErrorInfo (Note1) select @vMaxKitsToCreate',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
