/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/10  SK      Default depth of CC for Reserve Location and Storage type A and LA is PD3 (HA-1077)
  2018/06/05  OK      Initial version (S2G-217)
------------------------------------------------------------------------------*/

declare @vRuleSetType  TRuleSetType = 'CycleCount_LocationCountDetail';

Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
delete from RuleSets where RuleSetType = @vRuleSetType;

  declare @vRecordId           TRecordId,
          @vRuleSetId          TRecordId,
          @vRuleSetName        TName,
          @vRuleSetDescription TDescription,
          @vRuleSetFilter      TQuery,

          @vBusinessUnit       TBusinessUnit,

          @vRuleCondition      TQuery,
          @vRuleDescription    TDescription,
          @vRuleQuery          TQuery,
          @vRuleQueryType      TTypeCode,

          @vSortSeq            TSortSeq,
          @vStatus             TStatus;

  declare @RuleSets            TRuleSetsTable,
          @Rules               TRulesTable;

/******************************************************************************/
/* Rule Set #1: Determine teh CC detail based on the location info
   various types of CC levels are
     For LPN Storage:
       LD1 - Count the num of LPNs only
       LD2 - Scan each LPN
       LD3 - Verify SKU and Qty in each LPN

     For Pallet Storage
       PD1 - Count the number of Pallets only
       PD2 - Scan each Pallet and verify the count of LPNs on the Pallet
       PD3 - Scan each LPN on the Pallet
       PD4 - Verify the SKU and Qty of each LPN  */
/******************************************************************************/
select @vRuleSetName        = 'CycleCount_LocationCountDetail',
       @vRuleSetDescription = 'Determine cycle count detail based on Location info & user option',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Count level for Bulk locations, LPNs storage */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Cycle count detail for Bulk Location, LPN Storage',
       @vRuleQuery       = 'Update Taskdetails
                            set RequestedCCLevel = ''LD1''
                            from TaskDetails TD join Locations L on (TD.LocationId = L.LocationId)
                            where (TD.TaskId = ~TaskId~) and (RequestedCCLevel is null) and
                                  (L.LocationType = ''B'') and (L.StorageType = ''L'')', /* Confirm Location with correct LPN count */
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleQueryType, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleQueryType, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Count level for Bulk locations, Pallets storage */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Cycle count detail for Bulk Location, Pallet Storage',
       @vRuleQuery       = 'Update Taskdetails
                            set RequestedCCLevel = ''PD1''
                            from TaskDetails TD join Locations L on (TD.LocationId = L.LocationId)
                            where (TD.TaskId = ~TaskId~) and (RequestedCCLevel is null) and
                                  (L.LocationType = ''B'') and (L.StorageType = ''A'')', /* Confirm Location with correct Pallet count */
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleQueryType, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleQueryType, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Count level for Reserve locations, LPNs storage */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Cycle count detail for Reserve Location, LPN Storage',
       @vRuleQuery       = 'Update Taskdetails
                            set RequestedCCLevel = ''LD2''
                            from TaskDetails TD join Locations L on (TD.LocationId = L.LocationId)
                            where (TD.TaskId = ~TaskId~) and (RequestedCCLevel is null) and
                                  (L.LocationType = ''R'') and (L.StorageType in (''L''))', /* Confirm Location with correct Pallet count */
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleQueryType, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleQueryType, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Count level for Reserve locations, Pallets storage */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~CCProcess~ = ''PI'' /* Physical Inventory */',
       @vRuleDescription = 'Cycle count detail for Reserve Location, Pallet Storage with LPN Confirm',
       @vRuleQuery       = 'Update Taskdetails
                            set RequestedCCLevel = ''PD4''
                            from TaskDetails TD join Locations L on (TD.LocationId = L.LocationId)
                            where (TD.TaskId = ~TaskId~) and (RequestedCCLevel is null) and
                                  (L.LocationType = ''R'') and (L.StorageType in (''A'', ''LA''))', /* Confirm Location with correct Pallet count */
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleQueryType, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleQueryType, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Count level for Reserve locations, Pallets storage */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Cycle count detail for Reserve Location, Pallet Storage',
       @vRuleQuery       = 'Update Taskdetails
                            set RequestedCCLevel = ''PD3''
                            from TaskDetails TD join Locations L on (TD.LocationId = L.LocationId)
                            where (TD.TaskId = ~TaskId~) and (RequestedCCLevel is null) and
                                  (L.LocationType = ''R'') and (L.StorageType in (''A'', ''LA''))', /* Confirm Location with correct Pallet count */
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleQueryType, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleQueryType, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Count level for Staging locations, LPNs storage */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Cycle count detail for Staging Location, LPN Storage',
       @vRuleQuery       = 'Update Taskdetails
                            set RequestedCCLevel = ''LD1''
                            from TaskDetails TD join Locations L on (TD.LocationId = L.LocationId)
                            where (TD.TaskId = ~TaskId~) and (RequestedCCLevel is null) and
                                  (L.LocationType = ''S'') and (L.StorageType = ''L'')', /* Confirm Location with correct Pallet count */
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleQueryType, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleQueryType, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Count level for Staging locations, Pallets storage */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Cycle count detail for Staging Location, Pallet Storage',
       @vRuleQuery       = 'Update Taskdetails
                            set RequestedCCLevel = ''PD1''
                            from TaskDetails TD join Locations L on (TD.LocationId = L.LocationId)
                            where (TD.TaskId = ~TaskId~) and (RequestedCCLevel is null) and
                                  (L.LocationType = ''S'') and (L.StorageType = ''A'')', /* Confirm Location with correct Pallet count */
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleQueryType, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleQueryType, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

Go