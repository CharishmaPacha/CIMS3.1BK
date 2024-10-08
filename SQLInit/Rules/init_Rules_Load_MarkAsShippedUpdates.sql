/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/01  RV      Added rules for Manifest close (HA-950)
  2019/09/18  RKC     Initial version (CID-1012)
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
/* Rules to update required values while sending to Exports */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'LoadShip_PreValidateUpdates';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Description of this RuleSet */
/******************************************************************************/
select @vRuleSetName        = 'Updates_Trackingno',
       @vRuleSetDescription = 'Updating Trackingno on LPNs',
       @vRuleSetFilter      = null,
       @vSortSeq            = 0, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to update LPNs with Load.MasterTrackingNo */
select @vRuleCondition   = null,
       @vRuleDescription = 'Load Ship: Upload Load Master Trackingno on LPNs if LPNs do not have Trackingno',
       @vRuleQuery       = 'Update LPNs
                            set TrackingNo = LD.MasterTrackingNo
                            from LPNs L join Loads LD on L.LoadId = LD.LoadId
                            where (L.LoadId = ~LoadId~) and
                                  (coalesce(L.TrackingNo, '''') = '''') and
                                  (coalesce(LD.MasterTrackingNo, '''') <> '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules to check whether manifest close reuired or not */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'LoadShip_ManifestCloseRequired';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Default rule */
/******************************************************************************/
select @vRuleSetName        = 'ManifestCloseRequired',
       @vRuleSetDescription = 'Check Manifest close required or not',
       @vRuleSetFilter      = null,
       @vSortSeq           += 1, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Default rule to do not require Manifest close */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default Rule: Do not require Manifest close',
       @vRuleQuery       = 'select ''N''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
