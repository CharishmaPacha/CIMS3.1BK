/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/18  RKC     If any of the LPNs do not have TrackingNo then those SPL orders should not be added to the load (BK-647)
  2021/08/17  OK      Changes to get the order to load from Load Warehouse only and
                      Changed hash table name as per the latest changes (BK-498)
  2021/05/16  TK      Consider Load ShipForm while adding orders to load (HA-2788)
  2020/10/27  SV      Changes not to add Order to Load until the Order is packed (HA-1584)
  2020/07/02  OK      Initial version (HA-1060, HA-1061)
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
/* Rules for : Selecting Loads for Auto building of Loads */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Loads_AutoBuild_GetLoadsToBuild';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Determine the list of Loads to automatically build */
/******************************************************************************/
select @vRuleSetName        = 'Loads_GetLoadsToBuild',
       @vRuleSetFilter      = '~Operation~ = ''Loads_AutoBuild''',
       @vRuleSetDescription = 'Auto Build Loads: Get the Loads to process',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule select the Loads to be automatically built */
select @vRuleCondition   = null,
       @vRuleDescription = 'Auto Build Loads: Get the list of Loads to process',
       @vRuleQuery       = 'insert into #AutoBuildLoads (LoadId, LoadNumber, LoadType, ShipFrom, ShipVia, Warehouse)
                              select LoadId, LoadNumber, LoadType, ShipFrom, ShipVia, FromWarehouse
                              from Loads
                              where (Archived = ''N'') and /* for performance */
                                    (CreatedOn = cast(current_timestamp as Date)) and
                                    (Status not in (''SI'', ''S'', ''X'' /* Shipped, Cancelled */)) and
                                    (CreatedBy = ''CIMSAgent'')',
       @vRuleQueryType   = 'DataSet',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rule Set - Get the Orders to Add to the Loads */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Loads_AutoBuild_GetOrdersToAdd';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
select @vRuleSetName        = 'Loads_GetOrdersToAddToLoads',
       @vRuleSetFilter      = '~Operation~ = ''Loads_AutoBuild''',
       @vRuleSetDescription = 'Add the Orders to the Load',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = null; -- as we update RecordId, we do not need to specify this

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Add UPS Orders to UPSE or UPSN Load Types, similarly FedEx or any other LTL Carriers */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~LoadType~ in (''UPSN'', ''UPSE'', ''FDEN'', ''FDEG'', ''USPS'')',
       @vRuleDescription = 'Loads Auto Build: Small Package Loads: Add PTS Orders to the corresponding Load Type matching SCAC & LoadType',
       @vRuleQuery       = 'insert into #AutoBuildLoadAddOrders (OrderId, PickTicket, OrderType, SortOrder)
                              select OH.OrderId, OH.PickTicket, OH.PickBatchNo, OH.OrderId
                              from OrderHeaders OH
                                join Waves           W   on (OH.PickBatchId = W.WaveId)
                                join vwShipVias      SV  on (OH.ShipVia = SV.ShipVia)
                                join #AutoBuildLoads ABL on (OH.ShipFrom = ABL.ShipFrom)
                              where (W.WaveType in (''PTS'')) and
                                    (OH.Status in (''K'', ''G'' /* Packed, Staged */)) and
                                    (OH.Archived = ''N'') and /* for performance */
                                    (ABL.LoadId = ~LoadId~) and
                                    (SV.SCAC = ~LoadType~) and
                                    (OH.Warehouse = coalesce(~Warehouse~, OH.Warehouse)) and
                                    (OH.BusinessUnit = ~BusinessUnit~)',
       @vRuleQueryType   = 'DataSet',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Add UPS Orders to UPSE or UPSN Load Types, similarly FedEx or any other LTL Carriers */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~LoadType~ in (''UPSN'', ''UPSE'', ''FDEN'', ''FDEG'', ''USPS'')',
       @vRuleDescription = 'Loads Auto Build: Small Package Loads: Add PTC, SLB Orders to the corresponding Load Type matching SCAC & LoadType',
       @vRuleQuery       = 'insert into #AutoBuildLoadAddOrders (OrderId, PickTicket, OrderType, SortOrder)
                              select OH.OrderId, OH.PickTicket, OH.PickBatchNo, OH.OrderId
                              from OrderHeaders OH
                                join Waves           W   on (OH.PickBatchId = W.WaveId)
                                join vwShipVias      SV  on (OH.ShipVia = SV.ShipVia )
                                join #AutoBuildLoads ABL on (OH.ShipFrom = ABL.ShipFrom)
                              where (W.WaveType in (''PTC'', ''SLB'')) and
                                    (OH.Status in (''K'', ''G'' /* Packed, Staged */)) and
                                    (OH.Archived = ''N'') and /* for performance */
                                    (ABL.LoadId = ~LoadId~) and
                                    (SV.SCAC = ~LoadType~) and
                                    (OH.Warehouse = coalesce(~Warehouse~, OH.Warehouse)) and
                                    (OH.BusinessUnit = ~BusinessUnit~)',
       @vRuleQueryType   = 'DataSet',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Add Packed small package orders to Load, but only if all LPNs have a tracking no */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~LoadType~ in (''UPSN'', ''UPSE'', ''FDEN'', ''FDEG'', ''USPS'')',
       @vRuleDescription = 'Loads Auto Build: Add Packed orders to the Load',
       @vRuleQuery       = ' ;with ValidOrdersToLoad as
                              (
                                 select OH.OrderId, OH.PickTicket, min(OH.OrderType) OrderType
                                 from OrderHeaders OH
                                   join LPNs          L on (L.OrderId      = OH.OrderId)
                                   join vwShipVias   SV on (OH.ShipVia     = SV.ShipVia)
                                 where (OH.Status       in (''K'', ''G'' /* Packed, Staged */) ) and
                                       (OH.Archived     = ''N'') /* for performance */ and
                                       (OH.Warehouse    = coalesce(~Warehouse~, OH.Warehouse)) and
                                       (SV.SCAC         = ~LoadType~) and
                                       (SV.IsSmallPackageCarrier = ''Y'') and /* Small package carriers orders only */
                                       (OH.BusinessUnit = ~BusinessUnit~)
                                 group by OH.OrderId, OH.PickTicket
                                 /* Make sure all packages on each order have tracking numbers generated */
                                 having sum(case when coalesce(L.TrackingNo, '''') <> '''' then 1 else 0 end) = count(L.LPNId)
                              )
                            insert into #AutoBuildLoadAddOrders (OrderId, PickTicket, OrderType, SortOrder)
                              select VO.OrderId, VO.PickTicket, VO.OrderType, VO.OrderId
                              from ValidOrdersToLoad VO',
       @vRuleQueryType   = 'DataSet',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Delete Orders that are already on a load */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Delete Orders which are already on a Load',
       @vRuleQuery       = 'delete #AutoBuildLoadAddOrders
                            from #AutoBuildLoadAddOrders ABLO join vwOrderShipments OS on ABLO.OrderId = OS.OrderId
                            where OS.LoadId > 0',
       @vRuleQueryType   = 'DataSet',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
