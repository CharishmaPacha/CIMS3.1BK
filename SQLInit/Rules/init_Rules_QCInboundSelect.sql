/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/28  VS      Changed Rules to get selected LPNs based on SKU Color Size (CID-986)
  2019/02/08  RV      Initial version (CID-53)
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
/* Rules for selecting LPNs to be QC */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'QCInbound_AutoSelectLPNs';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* QC Groups setup */
/******************************************************************************/
select @vRuleSetName        = 'QCHold_SetupGroups',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'QC Groups: Setup groups for selecting LPNs',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to update #table to select the LPNs on Receipt for QC */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'QC Group: Update QCGroup on LPNs',
       @vRuleQuery       = 'Update #LPNsForQC
                            set QCGroup = SKU1 + SKU2 + SKU3',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update #table to select the LPNs on Receipt for QC */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'QC Group: Update QCIndex on LPNs',
       @vRuleQuery       = 'WITH QCIndexUpdate (LPNId, QCGroup, QCIndex)
                            AS
                             (
                               select LPNId, QCGroup, row_number() over(partition by QCGroup order by InvStatus desc, NEWID()) AS QCIndex
                               from #LPNsForQC
                             )
                            update #LPNsForQC
                            set QCIndex = LC.QCIndex
                            from QCIndexUpdate LC
                              join #LPNsForQC MU on MU.QCGroup = LC.QCGroup and MU.LPNId = LC.LPNId',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update #table to select the LPNs on Receipt for QC */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'QC Group: Build list of groups',
       @vRuleQuery       = 'insert into #QCGroups(QCGroup, NumLPNs, NumLPNsToSelect)
                              select LC.QCGroup, count(*), ceiling((count(*) * 6) /convert(decimal(8,2), 100))
                              from #LPNsForQC LC
                                join ReceiptHeaders RH on RH.ReceiptId = LC.ReceiptId
                              where RH.UDF1 not in (''AIR'')
                              group by LC.QCGroup',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set to update PutawayClass */
/******************************************************************************/
select @vRuleSetName        = 'AutoSelectLPNs_QCHold',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update LPNs for QC inbound',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to update #table to select the LPNs on Receipt for QC */
select @vRuleCondition   = null,
       @vRuleDescription = 'QC select: For AIR shipments, 100% QC',
       @vRuleQuery       = 'Update LFQ
                            set Selected = ''Y''
                            from #LPNsForQC LFQ join ReceiptHeaders RH on LFQ.ReceiptId = RH.ReceiptId
                            where (RH.UDF1 = ''AIR'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update #table to select the LPNs on Receipt for QC */
select @vRuleCondition   = null,
       @vRuleDescription = 'QC select: For non-AIR shipments, apply 6% QC for each Style-Color-Size',
       @vRuleQuery       = 'Update LC
                            set Selected = ''Y''
                            from #LPNsForQC LC
                              join #QCGroups QG on LC.QCGroup = QG.QCGroup
                            where LC.QCIndex <= QG.NumLPNsToSelect',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
