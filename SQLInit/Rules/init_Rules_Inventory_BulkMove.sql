/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/30  RV      Made changes to Picked and Packed LPN status as Staged when drop location PA zone is drop-PTS (HA-2485)
  2020/12/07  RKC     Added new rule to mark the LPN status as Staged if LPNs moved to Staging location (HA-1725)
  2020/10/30  SV      Rule to mark the LPN status as Staged on dropping to Staging location (HA-1584)
  2020/07/13  TK      Initial Revision (HA-1115)
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
/* Rules to update Dest Location */
/******************************************************************************/
/******************************************************************************/
select  @vRuleSetType = 'LPNsBulkMove_UpdateDestLocation';

/******************************************************************************/
/* Rule Set to determine the destination location to Move LPNs to */
/******************************************************************************/
select @vRuleSetName        = 'LPNsBulkMoveUpdateDestLocation',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update Dest Location on LPNs',
       @vStatus             = 'NA', /* Not applicable */
       @vSortSeq            = 10;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule */
select @vRuleCondition   = null,
       @vRuleDescription = 'Rule Description',
       @vRuleQuery       = '',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for validating move LPNs */
/******************************************************************************/
/******************************************************************************/
select  @vRuleSetType = 'LPNsBulkMove_Validations';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* LPNsBulkMove ValidateDestLocation */
/******************************************************************************/
select @vRuleSetName        = 'LPNsBulkMove_ValidateDestLocation',
       @vRuleSetDescription = 'LPNs Bulk Move: Validate Dest Location',
       @vRuleSetFilter      = null,
       @vSortSeq            = 20,
       @vStatus             = 'NA' /* Not applicable */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules */
select @vRuleCondition   = null,
       @vRuleDescription = 'Rule Description',
       @vRuleQuery       = '',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for changing status of LPN on move */
/******************************************************************************/
/******************************************************************************/
select  @vRuleSetType = 'LPNMove_ChangeStatus';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* LPNMove Statuses */
/******************************************************************************/
select @vRuleSetName        = 'LPNMove_ChangeStatus',
       @vRuleSetDescription = 'Change status of LPN on Move',
       @vRuleSetFilter      = null,
       @vSortSeq            = 30,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* For PTS wave, dropping Picked and Packed LPN at Staging Location, need to mark the LPN status as Staged */
select @vRuleCondition   = '(~WaveType~ is not null) and
                            (~WaveType~ = ''PTS'') and
                            (~LocPutawayZone~ = ''Drop-PTS'') and
                            (~Status~ in (''K'', ''D''))',
       @vRuleDescription = 'On dropping PTS wave Picked and Packed LPN to Staging location, need to mark the status as Staged ',
       @vRuleQuery       = 'select ''E''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Moved LPN to Staging Location, need to mark the LPN status as Staged */
select @vRuleCondition   = '(~LocPutawayZone~ = ''ShipStaging'') and
                            (~Status~ = ''D'')',
       @vRuleDescription = 'LPN moved to Staging location, need to mark the status as Staged ',
       @vRuleQuery       = 'select ''E''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
