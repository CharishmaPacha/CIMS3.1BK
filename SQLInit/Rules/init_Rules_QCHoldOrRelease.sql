/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/06  RKC     Changed the All rules status to NA ,this are all client specification (JL-193)
  2019/02/08  VS      Initial version (CID-68)
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
/* Rules for QC Hold and QC Release */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'QCInbound_LPNHoldorRelease';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set to updates on LPNs for UpdateQC Action */
/******************************************************************************/
select @vRuleSetName        = 'QC_PlaceLPNsOnQCHold',
       @vRuleSetFilter      = '~Action~ = ''QCHold''',
       @vRuleSetDescription = 'QCHold: Update LPNs for placing on QC Hold',
       @vStatus             = 'NA' /* Not applicable */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;
/*----------------------------------------------------------------------------*/
/* Rule to place Received and Intransit LPNs on hold */
select @vRuleCondition   =  null,
       @vRuleDescription = 'Place InTransit/Received LPNs on QC Hold',
       @vRuleQuery       = 'Update L
                            set InventoryStatus = ''QC'',
                                DestZone        = ''QC'',
                                PutawayClass    = ''QC'',
                                Reference       =  ~Reference~,
                                ReasonCode      =  ~ReasonCode~,
                                ModifiedDate    =  current_timestamp,
                                ModifiedBy      = ''CimsAgent''
                            from LPNs L
                              join #LPNsForQC QC on (L.LPNId = QC.LPNId)
                            where (L.Status in (''R'',''T'')) and (L.InventoryStatus <> ''QC'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to place Putaway LPNs on hold */
select @vRuleCondition   = null,
       @vRuleDescription = 'Place Putaway LPNs on QC Hold',
       @vRuleQuery       = 'Update L
                            set InventoryStatus = ''QC'',
                                Reference       =  ~Reference~,
                                ReasonCode      =  ~ReasonCode~,
                                ModifiedDate    = current_timestamp,
                                ModifiedBy      = ''CimsAgent''
                            from LPNs L
                              join #LPNsForQC QC on (L.LPNId = QC.LPNId)
                            where (L.Status = ''P'') and (L.InventoryStatus <> ''QC'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set to updates on LPNs for UpdateQC Action */
/******************************************************************************/
select @vRuleSetName        = 'QC_PlaceAutoSelectedLPNsOnQCHold',
       @vRuleSetFilter      = '~Action~ = ''AutoSelectedQCHold''',
       @vRuleSetDescription = 'AutoSelectedQCHold: Update LPNs for placing on QC Hold',
       @vStatus             = 'NA' /* Not applicable */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;
/*----------------------------------------------------------------------------*/
/* Rule to place Received and Intransit LPNs on hold */
select @vRuleCondition   =  null,
       @vRuleDescription = 'Place Auto selected InTransit/Received LPNs on QC Hold',
       @vRuleQuery       = 'Update L
                            set L.InventoryStatus = ''QC'',
                                L.DestZone        = ''QC'',
                                L.PutawayClass    = ''QC'',
                                L.Reference       =  ~Reference~,
                                L.ReasonCode      =  ~ReasonCode~,
                                L.ModifiedDate    =  current_timestamp,
                                L.ModifiedBy      = ''CimsAgent''
                            from LPNs L
                              join #LPNsForQC LQC on (L.LPNId = LQC.LPNId)
                            where (LQC.Selected = ''Y'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set to update LPNs for QC Release action */
/******************************************************************************/
select @vRuleSetName        = 'QC_ReleaseLPNsFromQCHold',
       @vRuleSetFilter      = '~Action~ = ''QCRelease''',
       @vRuleSetDescription = 'QC Release: Update LPN to release from QC',
       @vStatus             = 'NA' /* Not applicable */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to release Received and Intransit LPNs from hold */
select @vRuleCondition   = null,
       @vRuleDescription = 'Release Intransit/Received LPNs from QC',
       @vRuleQuery       = 'Update L
                            set InventoryStatus = ''N'',
                                DestZone        = null,
                                DestLocation    = null,
                                PutawayClass    = null, -- will be recomputed by preprocess
                                Reference       =  ~Reference~,
                                ReasonCode      =  ~ReasonCode~,
                                ModifiedDate    = current_timestamp,
                                ModifiedBy      = ''CimsAgent''
                            from LPNs L join #LPNsForQC LQC on (L.LPNId = LQC.LPNId)
                            where L.Status in (''R'',''T'') and (L.InventoryStatus = ''QC'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to release Putaway LPNs from hold */
select @vRuleCondition   = null,
       @vRuleDescription = 'Release Putaway LPNs from QC',
       @vRuleQuery       = 'Update L
                            set InventoryStatus = ''N'',
                                DestZone        = null,
                                DestLocation    = null,
                                PutawayClass    = null, -- will be recomputed by preprocess
                                Reference       =  ~Reference~,
                                ReasonCode      =  ~ReasonCode~,
                                ModifiedDate    = current_timestamp,
                                ModifiedBy      = ''CimsAgent''
                            from LPNs L join #LPNsForQC LQC on (L.LPNId = LQC.LPNId)
                            where (L.Status in (''P'')) and (L.InventoryStatus = ''QC'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
