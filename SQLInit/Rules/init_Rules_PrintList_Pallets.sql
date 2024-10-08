/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/05  MS      Added PrintDataFlag to print the labels (HA-1822)
  2020/07/15  MS      Bug fix to print PalletLabels from LPNsPalletize action (HA-1144)
  2020/06/17  MS      Corrections to PrinterName (HA-853)
  2020/05/15  AY      Initial version (HA-445)
------------------------------------------------------------------------------*/

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
/* Rule Set : Determine which Pallet labels to print when printing from List.Pallets */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'PrintList_Pallets';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Print labels for the LPNs generated */
/******************************************************************************/
select @vRuleSetName        = 'PrintList_Pallets_GeneratePallets',
       @vRuleSetFilter      = '(~Operation~ in (''GeneratePallets'', ''PalletizeLPNs''))',
       @vRuleSetDescription = 'Pallets: Determine which labels to print when generating Pallets',
       @vSortSeq            =  0,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* When LPN are generated, by default print the user selected label to the user selected printer */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Generate Pallets: Print the user selected format',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType,
                                                    DocumentFormat, PrinterName, SortSeqNo, PrintDataFlag)
                              select EntityType, EntityId, EntityKey, ''Label'', ''ZPL'', ''Pallet'',
                                     DocumentFormat, LabelPrinterName, 1, ''Required''
                              from #EntitiesToPrint ETP
                              where (ETP.EntityType = ''Pallet'')
                              order by SortOrder, EntityKey',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
