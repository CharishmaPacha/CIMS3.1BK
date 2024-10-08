/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/09/03  RV      Made changes to decide is carrier small package or not based on the IsSmallPackageCarrier flag
                        instead of mention each carrier (S2GCA-236)
  2018/02/23  RV      Initial version (S2G-255)
------------------------------------------------------------------------------*/

declare @vRuleSetType  TRuleSetType = 'ShipLabelsInsert';

Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
delete from RuleSets where RuleSetType = @vRuleSetType;

  declare @vRecordId           TRecordId,
          @vRuleSetId          TRecordId,
          @vRuleSetName        TName,
          @vRuleSetDescription TDescription,
          @vRuleSetFilter      TQuery,

          @vBusinessUnit       TBusinessUnit,

          @vRuleCondition      TQuery,
          @vRuleQuery          TQuery,
          @vRuleDescription    TDescription,

          @vSortSeq            TSortSeq,
          @vStatus             TStatus;

  declare @RuleSets            TRuleSetsTable,
          @Rules               TRulesTable;

/******************************************************************************/
/* Rule Set #1 - Returns Y or N to decide whether the cartons are insert into ShipLabels table or not based on WaveType*/
/******************************************************************************/
select @vRuleSetName        = 'InsertShipLabels_WaveType',
       @vRuleSetDescription = 'Decide to insert the cartons into ShipLabels table based upon wave type',
       @vRuleSetFilter      = '~Validation~ = ''WaveType''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Insert cartons into ShipLabels table if carrier is small package carrier and wave type */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''SLB'', ''PTS'')',
       @vRuleDescription = 'For Waves that we cube, Insert cartons into ShipLabels table',
       @vRuleQuery       = 'select ''Y''' /* Yes */,
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Default rule to not insert cartons into ShipLabels table  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'By default we do not insert cartons into ShipLabels table',
       @vRuleQuery       = 'select ''N''' /* No */,
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #2 - Returns Y or N to decide whether the cartons are insert into ShipLabels table or not based on Carrier*/
/******************************************************************************/
select @vRuleSetName        = 'InsertShipLabels_Carrier',
       @vRuleSetDescription = 'Decide to insert the cartons into ShipLabels table based upon the carrier',
       @vRuleSetFilter      = '~Validation~ = ''Carrier''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Insert cartons into ShipLabels table if carrier is small package carrier */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~IsSmallPackageCarrier~ = ''Y''', /* Yes */
       @vRuleDescription = 'Insert cartons into ShipLabels table for small package carriers',
       @vRuleQuery       = 'select ''Y''' /* Yes */,
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Default rule to not insert cartons into ShipLabels table  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'By default we do not insert cartons into ShipLabels table for non Small package carriers',
       @vRuleQuery       = 'select ''N''' /* No */,
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

Go
