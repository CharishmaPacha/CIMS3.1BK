/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/06/14  VM      vwROReceivers => vwReceivedCounts (S2G-947)
  2018/03/06  SV      Initial version
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
/* Rules for : Find the Receiver */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Receiver_Find';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Find Open Receiver for RO */
/******************************************************************************/
select @vRuleSetName        = 'Receiver_FindOpenReceiverForRO',
       @vRuleSetFilter      = '~ReceiptId~ != ''''',
       @vRuleSetDescription = 'Fetch the appropriate Receiver to receive against the given Receipt#',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = null;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule for Auto Generation of Receivers:
    System needs to send the top most open receiver associated to the given PO
    created on that date. If nothing(ReceiverId) gets returned from the rule,
    system will create a new receiver */
select @vRuleCondition   = null,
       @vRuleDescription = 'Find an Open Receiver created today for the given Receipt#',
       @vRuleQuery       = 'select top 1 ROR.ReceiverId
                            from vwReceivedCounts ROR
                            where (ROR.ReceiptId = ~ReceiptId~) and
                                  (ROR.ReceiverStatus = ''O'') and
                                  (convert(Date, ROR.CreatedDate) = CAST(getdate() as Date))',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* A-Active, I-In-Active, NA-Not applicable */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
