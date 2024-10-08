/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/03/22  TD      Added ReleaseForAllocation_WaveNotApprovedYet(BK-1033)
  2022/07/29  RV      Added the rule to give a warning message for invalid ship to address (BK-882)
  2022/02/25  RT      Added WaveRelease_InvalidShipToContact (CID-1904)
  2021/08/13  OK      Added rules to do not release the wave if any order warhouse/shipfrom doesn't has ShipFrom Contact (BK-487)
  2021/06/30  OK      Added rule to do not release the wave if any OrderDetails doesn't has PrepackRatio (UnitsPerInnerpack) (HA-2934)
  2021/04/14  TK      Transfer & Rework wave can only be waved as Transfer & Rework waves respectively (HA-2626)
  2021/03/16  MS      Changes to validate carrier only for PTS (HA-2293)
  2021/03/03  MS      Added RuleSetType 'WaveOnRelease' (BK-174)
  2021/02/22  AY      update PackingGroup on Wave release (HA-2037)
  2020/08/14  PK      Disabled generic FreightTerms rule and enabled SPL Freight Terms rule (HA-1315).
  2020/07/22  PK      ValidationsForOtherThanReplenishWaves: Added condition to not consider Transfer Ordertype for UCC128LabelFormat,
                        ShipToState & SalesPrice queries.
  2020/07/13  RKC     Should not allow to release the waves if any orders does not have correct packing list formats (HA-1087)
  2020/07/08  AY      Allow Waves to be released with Order.ShipVia = Generic
  2020/07/07  RKC     Should not allow to release the waves if any orders does not have correct UCC & Content label formats (HA-1076)
  2020/06/11  YJ      Waves having Small package Orders which are missing MissingShipFromPhoneNo (HA-645)
  2020/06/05  TK      Bug fix in drop location validation (HA-859)
  2020/06/03  RKC     Do not allow release of PTS Waves if Allocation Model isn't System Reservation (HA-787)
  2020/05/30  TK      Changes to exclude pack combination ratio for packing group with 'SOLID' (HA-646)
                      Check for pack combination ratio only when UnitsPerCarton is greater than zero (HA-703)
  2020/05/27  SV      Added rule to validate the Warehouses of the DropLocation and Wave (HA-655)
  2020/05/19  TK      Added rule to validate Packing Group & invalid pack combination as well (HA-386)
  2020/05/12  TK      Migrated rules from CID and added rule to validate UnitsPerCarton (HA-386)
  2019/05/28  AY      Do not allow release of PTS Waves without Pick bins setup for A/B SKUs
  2019/03/22  TD      Bugfix to do not consider inactive logical LPNs (HPI-2487)
  2018/12/03  MS      Added rules to validate Waves having Invalid Ship To Country (OB2-718)
  2018/11/10  RIA     Added rule to validate Single Line Wave having multi line orders or not (OB2-666)
  2016/04/24  TK      Added Wave Dependency Rules for L1 & LDP waves
  2016/04/11  AY      Added rule to validate Case Storage locations for PTL/PTLC
  2016/04/11  AY/TK   Added CF rule to limit small orders, changed Automation wave rule as per revised spec (S2G-593)
  2016/03/30  AY      Setup rules to prevent releasing of Waves with unit storage picklanes (S2G-439)
                      Added rule to catch invalid address S2G-515
  2016/03/28  AY      Setup WCSDependency for other wave types (S2G-512)
  2018/03/14  TK      Changed Wave Validation Rules (S2G-382)
  2018/03/10  AY      Revised rules for InitializeWCSDependency (S2G-242)
  2018/03/06  RT      Added Rule to update the UDF2 based on the Wave Type info (S2G-242)
  2016/07/03  TK      Wave can have replenish order(s) only if it is a Replenish Wave(s)
  2017/02/03  TK      Added rule not to release waves if Pick-Bins are not set up for any of the SKUs (HPI-1364)
  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2015/05/23  OK      Initial version
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
/* Rules for : Wave Release Validation */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'WaveRelease';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Validations for Replenish Waves */
/******************************************************************************/
select @vRuleSetName        = 'ValidationsForReplenishWaves',
       @vRuleSetFilter      = '~WaveType~ in (''R'', ''RU'', ''RP'')',
       @vRuleSetDescription = 'Validations for Replenish Waves',
       @vSortSeq            = 0,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Replenish Waves */
select @vRuleCondition   = null,
       @vRuleDescription = 'Replenish waves should have only Replenish Orders',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_OnlyReplenishOrders'', OH.PickBatchNo, OH.PickTicket
                              from OrderHeaders OH
                              where (OH.PickBatchId = ~WaveId~) and
                                    (OH.OrderType not in (''R'', ''RU'', ''RP''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Update Parent info on all validations */
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave Release: Update Parent info on all Validations',
       @vRuleQuery       = 'Update #Validations
                            set MasterEntityType = ''Wave'',
                                MasterEntityId   = ~WaveId~,
                                MasterEntityKey  = ~WaveNo~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Validations for Waves other Replenish Waves */
/******************************************************************************/
select @vRuleSetName        = 'ValidationsForOtherThanReplenishWaves',
       @vRuleSetFilter      = '~WaveType~ not in (''R'', ''RU'', ''RP'')',
       @vRuleSetDescription = 'Validations for other than Replenish Waves',
       @vSortSeq            = 10,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Customer order Waves having Replenish Order in it */
select @vRuleCondition   = null,
       @vRuleDescription = 'Other than Replenish wave should not have Replenish Order',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_CannotHaveReplenishOrders'', OH.PickBatchNo, OH.PickTicket
                              from OrderHeaders OH
                              where (OH.PickBatchId = ~WaveId~) and
                                    (OH.OrderType in (''R'', ''RU'', ''RP''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Transfer Orders only on Tranfer Waves */
select @vRuleCondition   = '~WaveType~ not in (''XFER'')',
       @vRuleDescription = 'Transfer Orders: Can only be on Transfer Waves',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_CannotHaveTransferOrders'', OH.PickBatchNo, OH.PickTicket
                              from OrderHeaders OH
                              where (OH.PickBatchId = ~WaveId~) and
                                    (OH.OrderType in (''T''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rework Orders only on Rework Waves */
select @vRuleCondition   = '~WaveType~ not in (''RW'')',
       @vRuleDescription = 'Rework Orders: Can only be on Rework Waves',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_CannotHaveReworkOrders'', OH.PickBatchNo, OH.PickTicket
                              from OrderHeaders OH
                              where (OH.PickBatchId = ~WaveId~) and
                                    (OH.OrderType in (''RW''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Ensure selected DropLocation WH & Wave's WH are same */
select  @vRuleCondition   = '~DropLocationWH~ <> ''''',
        @vRuleDescription = 'On releasing a wave for allocation, selected DropLoc WH should be same as selected Wave WH',
        @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                               select ''Wave'', W.WaveId, W.WaveNo, ''WaveRelease_WarehouseMismatch'', W.Warehouse, ~DropLocationWH~
                               from Waves W
                               where (W.WaveId = ~WaveId~) and
                                     (W.Warehouse <> ~DropLocationWH~)' ,
        @vRuleQueryType   = 'Update',
        @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
        @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Validate that all orders have a valid UCC128LabelFormat */
select @vRuleCondition   = null,
       @vRuleDescription = 'Should not allow to release the waves if any orders have an invalid UCC label formats',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_InvalidShipLabelFormat'', OH.PickBatchNo, OH.PickTicket, OH.UCC128LabelFormat
                              from OrderHeaders OH
                                left outer join LabelFormats LF on (OH.UCC128LabelFormat = LF.LabelFormatName) and (OH.BusinessUnit = LF.BusinessUnit)
                              where (OH.PickBatchId = ~WaveId~) and
                                    (coalesce(OH.UCC128LabelFormat, '''') <> '''') and
                                    (LF.LabelFormatName is null) and
                                    (OH.OrderType not in (''T''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Validate that all orders have a valid ContentsLabelFormat */
select @vRuleCondition   = null,
       @vRuleDescription = 'Should not allow to release the waves if any orders does not have Content label formats',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_InvalidContentLabelFormat'', OH.PickBatchNo, OH.PickTicket, OH.ContentsLabelFormat
                              from OrderHeaders OH
                                left outer join LabelFormats LF on (OH.ContentsLabelFormat = LF.LabelFormatName) and (OH.BusinessUnit = LF.BusinessUnit)
                              where (OH.PickBatchId = ~WaveId~) and
                                    (coalesce(OH.ContentsLabelFormat, '''') <> '''') and
                                    (LF.LabelFormatName is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Validate that all orders have a valid packing list Format */
select @vRuleCondition   = null,
       @vRuleDescription = 'Should not allow to release the waves if any orders does not have correct packing list formats',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_InvalidPackingListFormat'', OH.PickBatchNo, OH.PickTicket, OH.ContentsLabelFormat
                              from OrderHeaders OH
                              left outer join Reports R on (OH.PackingListFormat = R.ReportName) and (OH.BusinessUnit = R.BusinessUnit)
                            where (OH.PickBatchId = ~WaveId~) and
                                  (coalesce(OH.PackingListFormat, '''') <> '''') and
                                  (R.ReportName is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having invalid Prepack ratio */
select @vRuleCondition   = null,
       @vRuleDescription = 'Should not allow to release the waves if any OrderDetails UnitsPerInnerpack and selected Cartonization Model as Prepack',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3, Value4, Value5)
                              select distinct ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_OrderDetailsWithInvalidPrepackRatio'', OH.PickBatchNo, OH.PickTicket, OD.HostOrderLine, S.SKU, OD.UnitsPerInnerPack
                              from OrderHeaders OH
                                join OrderDetails OD on (OH.OrderId = OD.OrderId)
                                join SKUs S on (S.SKUId = OD.SKUId)
                              where (OH.PickBatchId = ~WaveId~) and
                                    (OH.OrderType <> ''B''/* Bulk */) and
                                    (OD.UnitsAuthorizedToShip > 0) and
                                    (coalesce(OD.UnitsPerInnerPack, 0) = 0) and
                                    (~CartonizationModel~ = ''ByPrepack'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A',  /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Ensure DropLocation & Shipdate exists for *** Waves */
select  @vRuleCondition   = '~WaveType~ in (''XYZ'')',
        @vRuleDescription = 'DropLocation & ShipDate are required to Release *** Wave',
        @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                               select ''Wave'', W.WaveId, W.WaveNo, ''WaveRelease_NoDropLocationOrShipDate'', W.WaveNo, null
                               from Waves W
                               where (W.WaveId = ~WaveId~ ) and
                                     ((W.ShipDate is null)             or
                                      (nullif(PB.DropLocation, '''') is null))' ,
        @vRuleQueryType   = 'Update',
        @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
        @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to limit the number of Orders/Units per wave */
select @vRuleCondition   = '~WaveType~ in (''XYZ'')',
       @vRuleDescription = '*** Waves should have 500 orders or less and 5000 units or less',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Wave'', ~WaveId~, ~WaveNo~, ''WaveRelease_OrdersOrUnitsExceededThresholdValue'', ~WaveNo~, null
                              where ((~WaveNumOrders~ > 500) or
                                     (~WaveNumUnits~ > 5000))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves for which allocation model should be system reservation */
select @vRuleCondition   = '~WaveType~ in (''PTS'') and ~InvAllocationModel~ <> ''SR''',
       @vRuleDescription = 'Should not allow to release the PTS waves with invallocationModel as manual Reservation',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1)
                              select ''Wave'', ~WaveId~, ~WaveNo~, ''WaveRelease_WaveNeedsSystemReservation'', ~WaveNo~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having SKUs with invalid Pack Config */
select @vRuleCondition   = '~WaveType~ in (''PTS'', ''BPP'')',
       @vRuleDescription = 'Waves having SKUs with invalid Pack Configuration',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3, Value4)
                              select distinct ''SKU'', S.SKUId, S.SKU, ''WaveRelease_SKUwithInvalidPackConfig'', OH.PickBatchNo, S.SKU, S.UnitWeight, S.UnitVolume
                              from OrderHeaders OH
                                join OrderDetails OD on (OH.OrderId = OD.OrderId)
                                join SKUs S on (OD.SKUId = S.SKUId)
                              where (OH.PickBatchId = ~WaveId~) and
                                    ((coalesce(S.UnitWeight, 0) = 0) or (coalesce(S.UnitVolume, 0) = 0)) and
                                    (OD.UnitsAuthorizedToShip > 0)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A',  /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having SKUs with invalid Nesting factor for given Orders */
select @vRuleCondition   = '~WaveType~ in (''PTS'', ''BPP'')',
       @vRuleDescription = 'Waves having SKUs with invalid Nesting Factor',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
                              select distinct ''SKU'', S.SKUId, S.SKU, ''WaveRelease_SKUWithInvalidNestingFactor'', OH.PickBatchNo, S.SKU, S.NestingFactor
                              from OrderHeaders OH
                                join OrderDetails OD on (OH.OrderId = OD.OrderId)
                                join SKUs S on (OD.SKUId = S.SKUId)
                              where (OH.PickBatchId = ~WaveId~) and
                                    (coalesce(S.NestingFactor, 0) = 0) and
                                    (OD.UnitsAuthorizedToShip > 0)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Warning to the user, if user is not yet approved the EstimatedCartonInfo */
select @vRuleCondition   = '~WaveType~ in (''PTS'', ''BPP'')',
       @vRuleDescription = 'Wave Release Warning: Wave not approved for Release',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageType, MessageName, Value1)
                              select ''Wave'', WaveId, WaveNo, ''E'', ''ReleaseForAllocation_WaveNotApprovedYet'', WaveNo
                              from Waves
                              where (WaveId = ~WaveId~) and
                                    (WaveStatus = ''N'' /* New */)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* For CID, PTS Waves require Pick bins setup, but only for A/B SKUs. C SKUs could
   still be picked from Reserve. This rule applies to new SKUs also, but we don't have
   data to figure out what new SKUs are, so we will change this later */
/*---------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTS'')',
       @vRuleDescription = 'Do not release waves if Picklanes are not set up  for A/B SKUs',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
                              select distinct ''OD SKU'', S.SKUId, S.SKU, ''WaveRelease_PickBinsNotSetUpForSomeSKUs'', OH.PickBatchNo, S.SKU, OD.UnitsPerCarton
                              from vwOrderDetails OD
                                left outer join vwLPNs L on (OD.SKUId        = L.SKUId) and
                                                            (L.LPNType       = ''L''/* Logical */) and
                                                            (L.DestWarehouse = OD.Warehouse) and
                                                            (L.StorageType   = ''U'' /* Units */)
                                left outer join SKUs S on (OD.SKUId = S.SKUId)
                              where (OD.UnitsAuthorizedToShip > 0) and
                                    (L.LPN is null) and
                                    (coalesce(S.ABCClass, '''') in (''A'', ''B'')) and
                                    (OD.PickBatchId = ~WaveId~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves without pick-bins set up */
select @vRuleCondition   = '~WaveType~ in (''XYZ'')',
       @vRuleDescription = 'Do not release waves if Picklanes are not set up for any of the SKUs',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
                              select distinct ''OD SKU'', S.SKUId, S.SKU, ''WaveRelease_PickBinsNotSetUpForSomeSKUs'', OH.PickBatchNo, S.SKU, OD.UnitsPerCarton
                              from vwOrderDetails OD
                              left outer join LPNs L on (OD.SKUId = L.SKUId) and
                                                        (L.LPNType = ''L''/* Logical */) and
                                                        (L.DestWarehouse = OD.Warehouse) and
                                                        (L.Status <> ''I'' /* Inactive */)
                              where (OD.UnitsAuthorizedToShip > 0) and
                                    (L.LPN is null) and
                                    (OD.PickBatchId = ~WaveId~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having invalid OD.UnitsPerCarton */
select @vRuleCondition   = '~WaveType~ in (''BCP'')',
       @vRuleDescription = 'Waves having invalid OD.UnitsPerCarton',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
                              select distinct ''OD SKU'', S.SKUId, S.SKU, ''WaveRelease_ODsWithInvalidUnitsPerCarton'', OH.PickBatchNo, S.SKU, OD.UnitsPerCarton
                              from OrderHeaders OH
                                join OrderDetails OD on (OH.OrderId = OD.OrderId)
                                join SKUs S on (OD.SKUId = S.SKUId)
                              where (OH.PickBatchId = ~WaveId~) and
                                    (OH.OrderType <> ''B''/* Bulk */) and
                                    (coalesce(OD.UnitsPerCarton, 0) = 0) and
                                    (OD.UnitsAuthorizedToShip > 0)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A',  /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having with Packing Group undefined */
select @vRuleCondition   = '~WaveType~ in (''BCP'')',
       @vRuleDescription = 'Waves with Packing Group undefined ',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
                              select distinct ''OD SKU'', S.SKUId, S.SKU, ''WaveRelease_ODsWithoutPackingGroup'', OH.PickBatchNo, S.SKU, OD.HostOrderLine
                              from OrderHeaders OH
                                join OrderDetails OD on (OH.OrderId = OD.OrderId)
                                join SKUs S on (OD.SKUId = S.SKUId)
                              where (OH.PickBatchId = ~WaveId~) and
                                    (OH.OrderType <> ''B''/* Bulk */) and
                                    (coalesce(OD.PackingGroup, '''') = '''') and
                                    (OD.UnitsAuthorizedToShip > 0)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A',  /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having invalid Pack Combination ratio */
select @vRuleCondition   = '~WaveType~ in (''BCP'')',
       @vRuleDescription = 'Waves having invalid Pack Combination ratio',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select distinct ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_OrdersWithInvalidPackCombination'', min(OH.PickBatchNo), OD.PackingGroup
                              from OrderHeaders OH
                                join OrderDetails OD on (OH.OrderId = OD.OrderId)
                              where (OH.PickBatchId = ~WaveId~) and
                                    (OH.OrderType <> ''B''/* Bulk */) and
                                    (OD.UnitsAuthorizedToShip > 0) and
                                    (OD.UnitsPerCarton > 0) and
                                    (OD.PackingGroup <> ''SOLID'')
                              group by OH.OrderId, OH.PickTicket, OD.PackingGroup
                              having min(OD.UnitsAuthorizedToShip / OD.UnitsPerCarton) <>
                                     max(OD.UnitsAuthorizedToShip / OD.UnitsPerCarton)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A',  /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Pick To Ship Wave should have only Pick To Ship Orders  */
select @vRuleCondition   = '~WaveType~ in (''PTS'')',
       @vRuleDescription = 'Pick To Ship Wave should have only Pick To Ship Orders',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_OnlyPickToShipOrders'', OH.PickBatchNo, OH.PickTicket
                              from OrderHeaders OH
                              where (OH.PickBatchId = ~WaveId~) and
                                    (OH.OrderCategory1 not in (''Pick To Ship''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Ensure Single Line Wave does not have Multi Line Orders */
select @vRuleCondition   = '~WaveType~ in (''SLB'')',
       @vRuleDescription = 'Single Line Waves should not have multi line orders',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_SLWaveWithMultiLineOrders'', OH.PickBatchNo, OH.PickTicket
                              from OrderDetails OD join OrderHeaders OH on OD.OrderId = OH.OrderId
                              where (OH.PickBatchId = ~WaveId~) and
                                    (OD.UnitsAuthorizedToShip > 0)
                              group by OH.OrderId, OH.PickTicket
                              having count(*) > 1',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* PCPK Waves: check whether pick bins are set up for all SKUs, and there is enough inventory to allocate Units */
select @vRuleCondition   = '~WaveType~ in (''PCPK'')',
       @vRuleDescription = 'PCPK Waves: check whether pick bins are set up for all SKUs, and there is enough inventory to allocate Units',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, dbo.fn_Wave_ValidatePCPKWaveRelease(~WaveId~), OH.PickBatchNo, OH.PickTicket',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA',  /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Orders with invalid Ship Via */
select @vRuleCondition   = null,
       @vRuleDescription = 'Waves having Orders with invalid Ship Via',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_ShipViaInvalid'', OH.PickBatchNo, OH.PickTicket
                              from OrderHeaders OH
                                left outer join ShipVias SV on (OH.ShipVia = SV.ShipVia)
                              where (OH.PickBatchId = ~WaveId~) and
                                    (SV.ShipVia is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Orders with invalid Carrier */
select @vRuleCondition   = '~WaveType~ = ''PTS''',
       @vRuleDescription = 'Waves having Orders with invalid Carrier types',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_CarrierInvalid'', OH.PickBatchNo, OH.PickTicket
                              from vwOrderHeaders OH
                              where (OH.PickBatchId = ~WaveId~) and
                                    (OH.Carrier in (''Invalid''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Orders with generic Carrier - this is most often not used as
   the Carrier may not be known at the time of Waving yet */
select @vRuleCondition   = null,
       @vRuleDescription = 'Waves having Orders with Generic types',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_CarrierGenericNotValidforWaving'', OH.PickBatchNo, OH.PickTicket
                              from vwOrderHeaders OH
                              where (OH.PickBatchId = ~WaveId~) and
                                    (OH.Carrier in (''Generic''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Orders with invalid address Order missing Ship To City */
select @vRuleCondition   = null,
       @vRuleDescription = 'Waves having Orders with missing ShipToCity',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_OrderMissingShipToCity'', OH.PickBatchNo, OH.PickTicket
                              from vwOrderHeaders OH
                              where (OH.PickBatchId = ~WaveId~) and
                                    ((coalesce(OH.ShipToCity, '''') = ''''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Orders with invalid address Order missing Ship To Zip */
select @vRuleCondition   = null,
       @vRuleDescription = 'Waves having Orders with missing or invalid ShipToZip',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_OrderHasInvalidShipToZip'', OH.PickBatchNo, OH.PickTicket, OH.ShipToZip
                              from vwOrderHeaders OH
                              where (OH.PickBatchId = ~WaveId~) and
                                    (coalesce(OH.ShipToCountry, ''US'') = ''US'') and (len(OH.ShipToZip) not in (5, 9, 10))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Orders with invalid address Order missing Ship To State */
select @vRuleCondition   = null,
       @vRuleDescription = 'Waves having Orders with missing ShipToState',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_OrderMissingShipToState'', OH.PickBatchNo, OH.PickTicket
                              from vwOrderHeaders OH
                              where (OH.PickBatchId = ~WaveId~) and
                                    (coalesce(OH.ShipToState, '''') = '''') and (OH.OrderType not in (''T''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Orders which are missing AES Number */
select @vRuleCondition   = null,
       @vRuleDescription = 'Waves having Orders requires AES number',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_MissingAESNumber'', OH.PickBatchNo, OH.PickTicket, OH.ShipToCountry
                              from vwOrderHeaders OH
                              where (OH.PickBatchId = ~WaveId~) and (coalesce(OH.OH_UDF14, '''') = '''') and
                                    (OH.TotalSalesAmount >= 2500) and (OH.Carrier in (''FEDEX'', ''UPS'')) and
                                    (OH.ShipToCountry not in (''US'', ''USA'', ''CA''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Small package Orders which are missing FreightTermsMissing */
select @vRuleCondition   = null,
       @vRuleDescription = 'Missing FreightTerms for some Small Package Orders',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_MissingFreightTerms'', OH.PickBatchNo, OH.PickTicket
                              from OrderHeaders OH
                                join ShipVias S on S.ShipVia = OH.ShipVia
                              where (OH.PickBatchId = ~WaveId~) and
                                    (S.IsSmallPackageCarrier = ''Y'') and
                                    (coalesce(OH.FreightTerms,'''') = '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Orders %2 which are missing FreightTermsMissing */
select @vRuleCondition   = null,
       @vRuleDescription = 'Missing FreightTerms for some Orders',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_MissingFreightTerms'', OH.PickBatchNo, OH.PickTicket
                              from OrderHeaders OH
                              where (OH.PickBatchId = ~WaveId~) and
                                    (coalesce(OH.FreightTerms,'''') = '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Orders which are missing SalesPrice */
select @vRuleCondition   = null,
       @vRuleDescription = 'Missing SalePrice for some Orders',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2)
                              select distinct ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_MissingSalePrice'', OH.PickBatchNo, OH.PickTicket
                              from OrderHeaders OH
                                join OrderDetails OD on OD.OrderId = OH.OrderId and OD.BusinessUnit = OH.BusinessUnit
                                join Contacts C on C.ContactRefId = OH.ShipToId and C.BusinessUnit = OH.BusinessUnit
                              where (OH.PickBatchId = ~WaveId~) and (OH.OrderType not in (''T'')) and (C.AddressRegion = ''I'') and
                                    (C.ContactType = ''S'') and (OD.UnitSaleprice is null or OD.UnitSaleprice = '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Orders which are missing ShipFrom Contact */
select @vRuleCondition   = null,
       @vRuleDescription = 'Missing ShipFrom contact',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_MissingShipFromContact'', OH.PickBatchNo, OH.PickTicket, OH.ShipFrom
                              from OrderHeaders OH
                                left outer join Contacts C on (C.ContactRefId = OH.ShipFrom) and (C.ContactType = ''F'' /* Ship From */)
                              where (OH.PickBatchId = ~WaveId~)and
                                    (C.ContactId is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Small package Orders which has Invalid Ship to address.
   For PTS/BPP we have to generate labels and print on allocation, so we have
   to give error and stop wave release */
select @vRuleCondition   = '~WaveType~ in (''PTS'', ''BPP'')',
       @vRuleDescription = 'Wave Release: Ensure Order has valid Ship To Address',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageType, MessageName, Value1, Value2, Value3)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''E'', ''WaveRelease_InvalidShipToContact'', OH.PickBatchNo, OH.PickTicket, OH.ShipToId
                              from OrderHeaders OH
                                left outer join Contacts C on (C.ContactRefId = OH.ShipToId) and (C.ContactType = ''S'' /* Ship To */)
                              where (OH.PickBatchId = ~WaveId~)and
                                    (C.AVStatus not in (''NotRequired'', ''Valid''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Warning to the user Waves having Orders which has Invalid Contact. For other than
   PTS/BPP Waves, we only give warning so that they can fix the issue before packing */
select @vRuleCondition   = '~WaveType~ not in (''PTS'', ''BPP'')',
       @vRuleDescription = 'Wave Release Warning: Order has invalid Ship To Address',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageType, MessageName, Value1, Value2, Value3)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''W'', ''WaveRelease_InvalidShipToContact'', OH.PickBatchNo, OH.PickTicket, OH.ShipToId
                              from OrderHeaders OH
                                left outer join Contacts C on (C.ContactRefId = OH.ShipToId) and (C.ContactType = ''S'' /* Ship To */)
                              where (OH.PickBatchId = ~WaveId~)and
                                    (C.AVStatus not in (''NotRequired'', ''Valid''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Orders which are missing Warehouse Contact */
select @vRuleCondition   = null,
       @vRuleDescription = 'Missing Warehouse contact',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_MissingWarehouseContact'', OH.PickBatchNo, OH.PickTicket, OH.Warehouse
                              from OrderHeaders OH
                                left outer join Contacts C on (C.ContactRefId = OH.Warehouse) and (C.ContactType = ''F'' /* Ship From */)
                              where (OH.PickBatchId = ~WaveId~)and
                                    (C.ContactId is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Small package Orders which are missing MissingShipFromPhoneNo */
select @vRuleCondition   = null,
       @vRuleDescription = 'Missing ShipFromPhoneNo for some Small Package Orders',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_MissingShipFromPhoneNo'', OH.PickBatchNo, OH.PickTicket, OH.ShipVia
                              from OrderHeaders OH
                                join ShipVias S on (S.ShipVia = OH.ShipVia)
                                join Contacts C on (C.ContactRefId = OH.ShipFrom)
                              where (OH.PickBatchId = ~WaveId~) and
                                    (S.IsSmallPackageCarrier = ''Y'') and
                                    (C.ContactType = ''F'' /* Ship From */) and
                                    (coalesce(C.PhoneNo, '''') = '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Orders which are missing ContactNumber */
select @vRuleCondition   = null,
       @vRuleDescription = 'Missing PhoneNumber for some Orders',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_MissingPhoneNumber'', OH.PickBatchNo, OH.PickTicket, OH.ShipVia
                              from OrderHeaders OH
                                join Contacts C on  C.ContactRefId = OH.MarkForAddress and C.BusinessUnit = OH.BusinessUnit
                              where (OH.PickBatchId = ~WaveId~) and (C.ContactType = ''S'') and
                                    (OH.ShipVia in (''FEDX1P'' /* Next Day Air */, ''FEDX1F'' /* 2nd Day Air */)) and (C.PhoneNo is null or C.PhoneNo = '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves having Orders which are PR States */
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave release: Cannot ship ground to some states',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3, Value4)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''WaveRelease_CannotShipGroundtoPR'', OH.PickBatchNo, OH.PickTicket, OH.ShipVia, C.State
                              from OrderHeaders OH
                                join Contacts C on  C.ContactRefId = OH.ShipToId and C.BusinessUnit = OH.BusinessUnit
                              where (OH.PickBatchId = ~WaveId~) and (C.ContactType = ''S'') and
                                    (OH.ShipVia = ''UPSG'') and (C.State = ''PR'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Update Parent info on all validation */
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave Release: Update Parent info on all Validations',
       @vRuleQuery       = 'Update #Validations
                            set MasterEntityType = ''Wave'',
                                MasterEntityId   = ~WaveId~,
                                MasterEntityKey  = ~WaveNo~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for Updating Wave Release Dependency Flags Information */
/******************************************************************************/
/******************************************************************************/
select  @vRuleSetType = 'SetWCSDependency';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* WCS Dependency */
/******************************************************************************/
select @vRuleSetName        = 'InitializeWCSDependency',
       @vRuleSetDescription = 'Updating Wave Release Dependency Flags with RLD',
       @vRuleSetFilter      = null,
       @vSortSeq            = 20,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Initialising Wave Release Dependency Flags on release for allocation */
select @vRuleCondition   = '~WaveType~ in (''XYZ'') and ~Operation~ = ''ReleaseForAllocation''',
       @vRuleDescription = 'Initialize WCS Dependency flags as RLD on Release for Allocation',
       @vRuleQuery       = 'select ''RLD''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Initialising Wave Release Dependency Flags on wave generation */
select @vRuleCondition   = '~WaveType~ in (''XYZ'') and ~Operation~ = ''WaveGeneration''',
       @vRuleDescription = 'Initialize WCS Dependency flags as RLD on Wave Generation',
       @vRuleQuery       = 'select ''RLD''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Waves with No Dependency */
select @vRuleCondition   = '~WaveType~ in (''XYZ'') and ~Operation~ = ''ReleaseForAllocation''',
       @vRuleDescription = 'Waves with No Dependency',
       @vRuleQuery       = 'select ''''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* By default - initialize WCS Dependency flags to R on Release for Allocation */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~Operation~ = ''ReleaseForAllocation''',
       @vRuleDescription = 'By default - initialize WCS Dependency flags to R on Release for Allocation',
       @vRuleQuery       = 'select ''R''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for Updating required info during wave release */
/******************************************************************************/
/******************************************************************************/
select  @vRuleSetType = 'WaveOnRelease';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Wave after release functions */
/******************************************************************************/
select @vRuleSetName        = 'WaveOnRelease',
       @vRuleSetDescription = 'Updates to be done after the wave release',
       @vRuleSetFilter      = null,
       @vSortSeq            = 100,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Update OD.DestZone on release of a Wave */
select @vRuleCondition   = '~WaveStatus~ = ''N'' /* New */',
       @vRuleDescription = 'Update OD Dest Zone on release of Wave',
       @vRuleQuery       = 'declare @ttBatchedOrderDetails  TBatchedOrderDetails;
                            insert into @ttBatchedOrderDetails
                              exec pr_PickBatch_ProcessOrderDetails ~WaveId~, null /* xml - Attributes */, ~BusinessUnit~, ~UserId~;

                            /* Update DestZone */
                            update OD
                            set OD.DestZone     = TBOD.DestZone,
                                OD.ModifiedDate = current_timestamp
                            from OrderDetails OD
                              join @ttBatchedOrderDetails TBOD on (TBOD.OrderDetailId = OD.OrderDetailId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Allocate Inventory for Orders on the Pickbatch */
select @vRuleCondition   = 'dbo.fn_Controls_GetAsString(~ControlCategory~, ''AllocateOnRelease'', ''J'', ~BusinessUnit~, ~UserId~) = ''O''',
       @vRuleDescription = 'Allocate Inventory when Wave is released',
       @vRuleQuery       = 'exec pr_Allocation_AllocateWave ~WaveId~, null /* Action */, ~BusinessUnit~, ~UserId~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Insert data into CIMS sorter tables */
select @vRuleCondition   = 'dbo.fn_Controls_GetAsString(~ControlCategory~, ''ExportSrtData'', ''N'', ~BusinessUnit~, ~UserId~) = ''O''',
       @vRuleDescription = 'Insert data into CIMS sorter tables',
       @vRuleQuery       = 'exec pr_Sorter_InsertWaveDetails ~WaveId~, null /* Sorter Name */, ~BusinessUnit~, ~UserId~;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Export data into DCMS sorter tables */
select @vRuleCondition   = 'dbo.fn_Controls_GetAsString(~ControlCategory~, ''ExportSrtData'', ''N'', ~BusinessUnit~, ~UserId~) = ''O''',
       @vRuleDescription = 'Export data into DCMS sorter tables',
       @vRuleQuery       = 'exec pr_Sorter_DCMS_ExportWaveDetails ~WaveId~, null /* Sorter Name */, ~BusinessUnit~, ~UserId~

                            update Waves
                            set Status = ''E'' /* Exported */
                            where WaveId = ~WaveId~;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Export status of the Orders to Host */
select @vRuleCondition   = 'dbo.fn_Controls_GetAsString(''WaveAfterRelease'', ''ExportStatusToHost'', ''N'', ~BusinessUnit~, ~UserId~) = ''Y''',
       @vRuleDescription = 'Wave On Release: Export status of the Orders to Host',
       @vRuleQuery       = 'exec pr_OrderHeaders_ExportStatus  ~WaveId~, null /* OrderId */, 140 /* ReasonCode */, null /* Temp table */, ~BusinessUnit~, ~UserId~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Email Wave Shorts report */
select @vRuleCondition   = 'dbo.fn_Controls_GetAsString(''WaveAfterRelease'', ''EmailWaveShortSummary'', ''N'', ~BusinessUnit~, ~UserId~) = ''Y''',
       @vRuleDescription = 'Email Wave Shorts report',
       @vRuleQuery       = 'exec pr_Alerts_WaveShortsSummary ~WaveNo~, ~BusinessUnit~, ~UserId~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Generate Loads for the Waves which are released */
select @vRuleCondition   = 'dbo.fn_Controls_GetAsString(''Wave'', ''GenerateLoadForWave'', ''N'', ~BusinessUnit~, ~UserId~) = ''O''',
       @vRuleDescription = 'Generate Loads for the Waves which are released',
       @vRuleQuery       = 'exec pr_Load_GenerateLoadForWavedOrders ~WaveId~, ~BusinessUnit~, ~UserId~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Update SeqIndex on all Orders in selected wave */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update SeqIndex on all Orders in selected wave',
       @vRuleQuery       = ';with SeqIndexUpdate (OrderId, WaveNo, SeqIndex)
                            as
                            (
                              select OH.OrderId, OH.PickBatchNo as WaveNo, row_number() over(order by OH.Account, OH.CustPO, OH.PickTicket, OH.OrderId) As SeqIndex
                              from OrderHeaders OH
                              where (OH.OrderType <> ''B''/* Bulk */) and
                                    (OH.PickBatchId = ~WaveId~)
                            )
                            update OH
                            set OH.WaveSeqNo = SIU.SeqIndex
                            from OrderHeaders OH
                              join SeqIndexUpdate SIU on (OH.OrderId = SIU.OrderId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
