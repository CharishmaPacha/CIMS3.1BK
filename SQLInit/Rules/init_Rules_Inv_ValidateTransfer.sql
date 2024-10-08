/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/18  RKC     Enabled the rules: LPN cannot be transferred to picklanes if the Receiver is not closed (HA-1369)
  2020/04/19  TK      Corrected validation rules (HA-222)
  2019/04/16  TK      Migrated TransferInvValidation RuleSet from Init_Rules_TransferInvValidation file (HA-82)
  2019/02/28  VS      Initial version (CID-138)
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
/* Rules for : Transfer Inventory Validation */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Inv_ValidateTransferInv';

delete from @RuleSets;
delete from @Rules;

/*******************************************************************************/
/* Rule Set - Rules to validate transfers from LPNs to Picklane */
/*******************************************************************************/
select @vRuleSetName        = 'Inv_ValidateTransferInv',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Rules to validate on transfer from LPN to Location',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0; -- as we update RecordId, we do not need to specify this

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: LPNs cannot be transfer to picklanes if Receiver is not closed */
select @vRuleCondition   = '(~Source~ = ''LPN'') and  (~FromLPNStatus~ = ''R'') and
                            (~ToLocationType~ = ''K'')',
       @vRuleDescription = 'On transfer of LPN to picklane, check Receiver is closed',
       @vRuleQuery       = 'select ''TransferInv_ReceiverNotClosed''
                            from LPNs L
                              join Receivers RCV on L.ReceiverNumber = RCV.ReceiverNumber and L.BusinessUnit = RCV.BusinessUnit
                            where (L.LPNId = ~FromLPNId~) and
                                  (RCV.Status <> ''C'' /* Closed */) and
                                  (~ToLocationType~ = ''K'')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* disabling this rule as I don't know the purpose or context of this - AY */
/*----------------------------------------------------------------------------*/
/* Rule: Do not allow transfer from Received LPN to Putaway LPN/Picklane Location */
select @vRuleCondition   = '(~FromLPNStatus~ = ''R'') and (~ToLPNStatus~ = ''P'')',
       @vRuleDescription = 'Do not allow transfer from Received LPN to Putaway LPN/Picklane Location',
       @vRuleQuery       = 'select ''TransferInv_NotValidFromReceivedToPutaway''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go