/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/15  VS      Added ChangeSKU Operation to Print the LPN Label (HA-2673)
  2021/01/12  PK      Ported changes done by Pavan (HA-1897)
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
/* Rule Set : Determine which LPNs labels to print when printing from List.LPNs */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'PrintList_LPNs';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Print labels for the LPNs generated */
/******************************************************************************/
select @vRuleSetName        = 'PrintList_LPNs_GenerateLPNs',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'LPNs: Determine which labels to print for LPNs',
       @vSortSeq            =  100,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* When LPN are generated, by default print the user selected label to the user selected printer */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'LPNs Labels: Print the user selected format',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType,
                                                    DocumentFormat, PrinterName, SortSeqNo, PrintDataFlag)
                              select EntityType, EntityId, EntityKey, ''Label'', ''ZPL'', ''LPN'',
                                     DocumentFormat, LabelPrinterName, 1, ''Required''
                              from #EntitiesToPrint ETP
                              where (ETP.EntityType = ''LPN'') and (DocumentFormat is not null)
                              order by SortOrder, EntityKey',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* When printing LPN labels, if a user format is not chosen, then print the default format */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'LPNs Labels: Print the default format',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType,
                                                    DocumentFormat, PrinterName, SortSeqNo, PrintDataFlag)
                              select EntityType, EntityId, EntityKey, ''Label'', ''ZPL'', ''LPN'',
                                     ''LPN_4x6_SKUPOQty_MF'', LabelPrinterName, 1, ''Required''
                              from #EntitiesToPrint ETP
                              where (ETP.EntityType = ''LPN'') and (DocumentFormat is null)
                              order by SortOrder, EntityKey',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
