/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/12  PK      Ported changes done by Pavan (HA-1897)
  2020/11/11  OK      Initial version (HA-1645)
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
/* Rule Set : Print all selected LPN Labels and associated Pallet Labels */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'PrintList_PalletAndLPNs';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Print labels for the LPNs generated */
/******************************************************************************/
select @vRuleSetName        = 'PrintList_PalletAndLPNs',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Print Pallet and LPN Labels',
       @vSortSeq            =  0,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Print LPN Labels */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Print LPN Labels',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType,
                                                    DocumentFormat, PrinterName, SortSeqNo, PrintDataFlag)
                              select EntityType, EntityId, EntityKey, ''Label'', ''ZPL'', ''LPN'',
                                     DocumentFormat, LabelPrinterName, 1, ''Required''
                              from #EntitiesToPrint ETP
                              where (ETP.EntityType = ''LPN'')
                              order by ETP.SortOrder, EntityKey',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Print Pallet Labels */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Print Pallet Labels',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType,
                                                    DocumentFormat, PrinterName, SortSeqNo, PrintDataFlag)
                              select EntityType, EntityId, EntityKey, ''Label'', ''ZPL'', ''Pallet'',
                                     DocumentFormat, LabelPrinterName, 2, ''Required''
                              from #EntitiesToPrint ETP
                              where (ETP.EntityType = ''Pallet'')
                              order by ETP.SortOrder, EntityKey',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/*  update SortOrder to print the Pallet labels followed by LPNs on that pallet */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Sort Order for the labels to print the Pallet labels followed by LPNs on that pallet',
       @vRuleQuery       = 'Update PL
                            set PL.SortOrder   = case when PL.DocumentType = ''Pallet'' then PL.EntityKey + ''-'' + ''0000''
                                                      when PL.DocumentType = ''LPN''    then coalesce(L.Pallet, '''') + ''-'' + PL.EntityKey
                                                 else
                                                   PL.SortOrder
                                                 end
                            from #PrintList PL
                              join #EntitiesToPrint ETP on (PL.EntityId = ETP.EntityId) and  (PL.EntityType = ETP.EntityType)
                              left outer join LPNs L on L.LPNId = ETP.EntityId',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
