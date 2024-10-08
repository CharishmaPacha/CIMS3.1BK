/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/15  RV      Initial version (CIMSV3-964)
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
/* Rule Set : Build the Shipping docs document selector to show in shipping docs page */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'DocumentSelector';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Build Document Selector for ShippingDocs request */
/******************************************************************************/
select @vRuleSetName        = 'ShippingDocs_DocumentSelector',
       @vRuleSetFilter      = '~Operation~ = ''ShippingDocs''',
       @vRuleSetDescription = 'Build document selector list for ShippingDocs',
       @vSortSeq            =  0,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Add record for the document class to show in document selector treeview   */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Add records for document class',
       @vRuleQuery       = 'insert into #DocumentSelectorList (KeyFieldName, KeyFieldValue, KeyFieldDescription, ParentKeyFieldName, SortSeq)
                                    select ''DocumentClass'', ''DocumentClass'', ''Document Classes'', null, 1
                              union select distinct ''DocumentClass'', DocumentClass, DocumentClass, ''DocumentClass'', 2
                              from #PrintList
                              where (DocumentClass is not null) and ((charindex(''P'', Action) > 0) or (charindex(''S'', Action) > 0))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/*-------------------------------------------------------------------------------------------------------------*/
/* Add record for the document type to show in document selector treeview */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Add records for document type',
       @vRuleQuery       = 'insert into #DocumentSelectorList (KeyFieldName, KeyFieldValue, KeyFieldDescription, ParentKeyFieldName, SortSeq)
                                    select ''DocumentType'', ''DocumentType'', ''Document Types'', null, 10
                              union select distinct ''DocumentType'', DocumentType, L.LookupDescription, ''DocumentType'', 11
                              from #PrintList PL
                                left join Lookups L on (L.LookupCode = PL.DocumentType) and (L.LookupCategory = ''LabelType'')
                              where (DocumentType is not null) and ((charindex(''P'', Action) > 0) or (charindex(''S'', Action) > 0))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/*-------------------------------------------------------------------------------------------------------------*/
/* Add record for the entity type to show in document selector treeview  */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Add records for entity type',
       @vRuleQuery       = 'insert into #DocumentSelectorList (KeyFieldName, KeyFieldValue, KeyFieldDescription, ParentKeyFieldName, SortSeq)
                                    select ''EntityType'', ''EntityType'', ''Entity Types'', null, 20
                              union select distinct ''EntityType'', EntityType, EntityType, ''EntityType'', 21
                              from #PrintList
                              where (EntityType is not null) and ((charindex(''P'', Action) > 0) or (charindex(''S'', Action) > 0))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/*-------------------------------------------------------------------------------------------------------------*/
/* Delete document selector records, which are not required  */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Delete document selector records, which are not required',
       @vRuleQuery       = 'delete from #DocumentSelectorList
                            where KeyFieldValue in (''Orders'', ''Labels'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 100;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
