/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/22  VS/AY   Initial version (CID-110)
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
/* Rules for : Validate the LPNs aginist Receiver */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Putaway_Validations';

delete from @RuleSets;
delete from @Rules;

/*******************************************************************************/
/* Rule Set - Rules to validate LPNs to Putaway */
/*******************************************************************************/
select @vRuleSetName        = 'PA_Validations',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Rules to validate LPNs to Putaway',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = null; -- as we update RecordId, we do not need to specify this

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* For CID: LPNs cannot be putaway to picklanes if Receiver is not closed */
select @vRuleCondition   = '~Operation~ = ''ConfirmPutawayLPN''',
       @vRuleDescription = 'On putaway of LPN to picklane, check Receiver is closed',
       @vRuleQuery       = 'select ''PALPN_ReceiverNotClosed''
                            from LPNs L
                              join Receivers RCV on L.ReceiverNumber = RCV.ReceiverNumber and L.BusinessUnit = RCV.BusinessUnit
                            where (L.LPNId = ~LPNId~) and
                                  (RCV.Status <> ''C'' /* Closed */) and
                                  (~PALocationType~ = ''K'')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* For CID: If DestZone is PA, PB1 or PC then show the errro on validation itself  */
select @vRuleCondition   =  '~Operation~ like ''ValidatePutawayLPN%''',
       @vRuleDescription = 'On attempting to Putaway LPN to Picklanes if Receiver is not closed',
       @vRuleQuery       = 'select ''PALPN_ReceiverNotClosed''
                            from LPNs L
                              join Receivers RCV on L.ReceiverNumber = RCV.ReceiverNumber and L.BusinessUnit = RCV.BusinessUnit
                            where (L.LPNId = ~LPNId~) and
                                  (RCV.Status <> ''C'' /* Closed */) and
                                  (L.DestZone in (''PA'', ''PB1'', ''PC''))',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/* --------------------------------------------------------- */
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
