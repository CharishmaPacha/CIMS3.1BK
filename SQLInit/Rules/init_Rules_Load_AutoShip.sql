/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/28  MS      Added Rule to Generate MasterBoL for Loads (HA-1206)
  2020/07/09  OK      Initial version (HA-1128)
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
/* Rules for : Selecting Loads for Auto adding of Orders */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'Load_AutoShipLoads';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Description of this RuleSet */
/******************************************************************************/
select @vRuleSetName        = 'Load_AutoShipLoads',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Auto Load Ship: Automatically Ship the Loads which are Ready To Ship',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0; -- as we update RecordId, we do not need to specify this

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule select the Loads that can be auto shipped */
select @vRuleCondition   = null,
       @vRuleDescription = 'Auto Ship Loads: Get the list of Loads which are to be evaluated',
       @vRuleQuery       = 'insert into #LoadsToAutoShip (LoadId, LoadNumber, LoadType, ShipVia, ProcessFlag,
                                                          CreatedDate, CreatedHour, CurrentHour)
                              select LoadId, LoadNumber, LoadType, ShipVia, '''',
                                     CreatedDate, datepart(Hour, CreatedDate), datepart(Hour, current_timestamp)
                              from Loads
                              where (Status in (''N'', ''I'', ''R'', ''L''/* New, In-Progress, Ready To Ship */)) and
                                    (NumOrders > 0) and
                                    (CreatedBy = ''cIMSAgent'')',
       @vRuleQueryType   = 'DataSet',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Ship the loads created today when the time arrives to ship them */
select @vRuleCondition   = null,
       @vRuleDescription = 'Auto Ship Loads: Ship the loads created today as per schedule',
       @vRuleQuery       = 'Update #LoadsToAutoShip
                            set ProcessFlag = ''Y''
                            where CreatedHour = case when (Currenthour = 17) then 6 /* at 5 pm close loads created at 6 am */
                                                     else 99
                                                end',
       @vRuleQueryType   = 'DataSet',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Ship the loads created yesterday when the time arrives to ship them */
select @vRuleCondition   = null,
       @vRuleDescription = 'Auto Ship Loads: At 7am, ship the loads created at 5 pm yesterday',
       @vRuleQuery       = 'Update #LoadsToAutoShip
                            set ProcessFlag = ''Y''
                            where (CreatedHour = 17) and
                                  (CurrentHour = 5) and
                                  (cast(CreatedDate as date) = cast(day, -1, current_timestamp))',
       @vRuleQueryType   = 'DataSet',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule update MasterBolNumber on Loads that are selected */
select @vRuleCondition   = null,
       @vRuleDescription = 'Auto Ship Loads: Generate MasterBolNum and update on selected Loads',
       @vRuleQuery       = 'exec pr_Loads_AutoGenerateBoLNum ~BusinessUnit~, null',
       @vRuleQueryType   = 'DataSet',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
