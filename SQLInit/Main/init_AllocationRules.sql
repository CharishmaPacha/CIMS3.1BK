/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/15  TK      Added Rules for BPP Waves (BK-181)
  2020/10/14  MS      Setup Allocation as per new Standards (HA-265)
  2017/08/09  TK      Introduced new searchset for OnDemand replenish allocations and modified Min-Max replenish allocation rules to consider ReplenishClass (HPI-1625)
  2016/07/25  TK      Corrected Rules for various batch types (HPI-359)
  2016/05/14  TD      Added rules for pick & Pack
  2016/04/06  AY      Replenish by FIFO
  2015/04/23  PK      Added Allocation rules for Bulk Pull Preference batch.
  2015/03/11  TK      Replenish Batch should not allocate Partial LPNs from Reserve Locations.
  2015/03/10  TK      Added Allocation Rules for Replenish Batch
  2015/02/25  TK      Added rules for Bulk Batch and migrated missing rules from Staging
  2015/02/25  TK      Added rules for Replenish Batch
  2015/02/09  PK      Addded allocation rules for boot barn batch.
  2015/01/22  TK      Added rules to allocate inventory from PartialLPNs from Reserve locations.
  2015/01/09  TK      Updated rules to Allocate LPN from StorageType Pallets & LPNs
                        if there are no LPNs in LPNs StorageType.
  2014/12/23  VM      Initial Revision
------------------------------------------------------------------------------*/

Go

declare @vSearchSet    TLookUpCode,
        @vWaveType     TTypeCode,
        @vWarehouses   TVarchar; -- CSV of Warehouses, null means rules would be set up for all active WHs

declare @ttAR TAllocationRulesTable;

/* Drop temp table if exists */
if object_id('tempdb..#AllocationRules') is not null drop table #AllocationRules
select * into #AllocationRules from @ttAR;

/***********************************************************************************************************************
  Bulk Pick & Pack Wave

  For Bulk Pick & Pack wave:
    1. Allocate full LPNs from Pallets & LPNs storage first and then from LPNs storage
    2. Allocate full cases from Pallets & LPNs storage first and then from LPNs storage
    2. Allocate units from Picklanes
***********************************************************************************************************************/
select @vWaveType  = 'BPP';
delete from #AllocationRules

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_AvailableLPNsFromBulk';

insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType, StorageType, PickingZone,     PickingClass, SearchType, QuantityCondition, OrderByField, OrderByType,  Status, SearchSet)
/* Allocate full LPNs from Bulk - Pallets & LPNs storage */
      select  1,           '01',      'B',          'LA',        null,            'FL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
union select  2,           '01',      'B',          'LA',        null,            'PL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
union select  3,           '01',      'B',          'LA',        null,            'OL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
/* Allocate full LPNs from Bulk - Pallets storage */
union select  1,           '01',      'B',          'A',         null,            'FL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
union select  2,           '01',      'B',          'A',         null,            'PL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
union select  3,           '01',      'B',          'A',         null,            'OL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
/* Allocate full LPNs from Bulk - LPNs storage */
union select  1,           '02',      'B',          'L',         null,            'FL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
union select  2,           '02',      'B',          'L',         null,            'PL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
union select  3,           '02',      'B',          'L',         null,            'OL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_AvailableCasesFromBulk';

insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType, StorageType, PickingZone,     PickingClass, SearchType, QuantityCondition, OrderByField, OrderByType,  Status, SearchSet)
/* Allocate from OL LPNs first */
      select  1,           '01',      'B',          'LA',        null,            'OL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  2,           '01',      'B',          'L',         null,            'OL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  3,           '01',      'B',          'A',         null,            'OL',         'P',        null,              null,         null,         'A',    @vSearchSet
/* Allocate from PL LPNs after */
union select  1,           '02',      'B',          'LA',        null,            'PL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  2,           '02',      'B',          'L',         null,            'PL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  3,           '02',      'B',          'A',         null,            'PL',         'P',        null,              null,         null,         'A',    @vSearchSet
/* Allocate from FL LPNs last */
union select  1,           '03',      'B',          'LA',        null,            'FL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  2,           '03',      'B',          'A',         null,            'FL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  3,           '03',      'B',          'L',         null,            'FL',         'P',        null,              null,         null,         'A',    @vSearchSet

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_AvailableQtyFromBulk';

insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType, StorageType, PickingZone,     PickingClass, SearchType, QuantityCondition, OrderByField, OrderByType,  Status, SearchSet)
/* Allocate from OL LPNs first */
      select  1,           '01',      'B',          'LA',        null,            'OL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  2,           '01',      'B',          'L',         null,            'OL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  3,           '01',      'B',          'A',         null,            'OL',         'P',        null,              null,         null,         'A',    @vSearchSet
/* Allocate from PL LPNs after */
union select  1,           '02',      'B',          'LA',        null,            'PL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  2,           '02',      'B',          'L',         null,            'PL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  3,           '02',      'B',          'A',         null,            'PL',         'P',        null,              null,         null,         'A',    @vSearchSet
/* Allocate from FL LPNs last */
union select  1,           '03',      'B',          'LA',        null,            'FL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  2,           '03',      'B',          'A',         null,            'FL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  3,           '03',      'B',          'L',         null,            'FL',         'P',        null,              null,         null,         'A',    @vSearchSet

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_AvailableLPNsFromReserve';

insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType, StorageType, PickingZone,     PickingClass, SearchType, QuantityCondition, OrderByField, OrderByType,  Status, SearchSet)
/* Allocate full LPNs from Reserve - Pallets & LPNs storage */
      select  1,           '01',      'R',          'LA',        null,            'FL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
union select  2,           '01',      'R',          'LA',        null,            'PL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
union select  3,           '01',      'R',          'LA',        null,            'OL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
/* Allocate full LPNs from Reserve - Pallets storage */
union select  1,           '01',      'R',          'A',         null,            'FL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
union select  2,           '01',      'R',          'A',         null,            'PL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
union select  3,           '01',      'R',          'A',         null,            'OL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
/* Allocate full LPNs from Reserve - LPNs storage */
union select  1,           '02',      'R',          'L',         null,            'FL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
union select  2,           '02',      'R',          'L',         null,            'PL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet
union select  3,           '02',      'R',          'L',         null,            'OL',         'F',        'LTEQ',            null,         null,         'A',    @vSearchSet

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_AvailableCasesFromReserve';

insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType, StorageType, PickingZone,     PickingClass, SearchType, QuantityCondition, OrderByField, OrderByType,  Status, SearchSet)
/* Allocate from OL LPNs first */
      select  1,           '01',      'R',          'LA',        null,            'OL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  2,           '01',      'R',          'L',         null,            'OL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  3,           '01',      'R',          'A',         null,            'OL',         'P',        null,              null,         null,         'A',    @vSearchSet
/* Allocate from PL LPNs after */
union select  1,           '02',      'R',          'LA',        null,            'PL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  2,           '02',      'R',          'L',         null,            'PL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  3,           '02',      'R',          'A',         null,            'PL',         'P',        null,              null,         null,         'A',    @vSearchSet
/* Allocate from FL LPNs last */
union select  1,           '03',      'R',          'LA',        null,            'FL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  2,           '03',      'R',          'A',         null,            'FL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  3,           '03',      'R',          'L',         null,            'FL',         'P',        null,              null,         null,         'A',    @vSearchSet

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_AvailableQtyFromReserve';

insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType, StorageType, PickingZone,     PickingClass, SearchType, QuantityCondition, OrderByField, OrderByType,  Status, SearchSet)
/* Allocate from OL LPNs first */
      select  1,           '01',      'R',          'LA',        null,            'OL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  2,           '01',      'R',          'L',         null,            'OL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  3,           '01',      'R',          'A',         null,            'OL',         'P',        null,              null,         null,         'A',    @vSearchSet
/* Allocate from PL LPNs after */
union select  1,           '02',      'R',          'LA',        null,            'PL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  2,           '02',      'R',          'L',         null,            'PL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  3,           '02',      'R',          'A',         null,            'PL',         'P',        null,              null,         null,         'A',    @vSearchSet
/* Allocate from FL LPNs last */
union select  1,           '03',      'R',          'LA',        null,            'FL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  2,           '03',      'R',          'A',         null,            'FL',         'P',        null,              null,         null,         'A',    @vSearchSet
union select  3,           '03',      'R',          'L',         null,            'FL',         'P',        null,              null,         null,         'A',    @vSearchSet

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_AvailableQty';

insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType, StorageType, PickingZone,     PickingClass, SearchType, QuantityCondition, OrderByField, OrderByType,  Status, SearchSet)
/* Allocate units from Picklanes */
      select  1,           '01',      'K',          'U',         null,            'U',          'P',        null,              null,         null,         'A',    @vSearchSet

/*----------------------------------------------------------------------------*/
exec pr_Setup_AllocationRules @vWaveType, null, @vWarehouses, 'DI' /* Delete & Add */

/***********************************************************************************************************************
  PTS Wave

  For PTS wave, allocate Units from Picklanes first, if not, do on demand replen, finally allocate from Reserve
***********************************************************************************************************************/

select @vWaveType  = 'PTS';
select @vSearchSet = 'AllocateInv_AvailableQtyFromPicklanes';

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate units from picklanes */
       select 1,           '1',       'K',           'U',          null,         'U',           'P',         null,               null,          null,          'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_DirectedQtyFromPicklanes';

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate Directed units from picklanes */
       select 1,           '1',       'K',           'U',          null,         'U',           'UD',        null,               null,          null,          'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_FromReserve';

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate Full LPNs */
       select  1,          '1',        'R',          'L',          null,         'FL',          'F',         'LTEQ',             'FIFO',        null,          'A'
union  select  2,          '1',        'R',          'L',          null,         'OL',          'F',         'LTEQ',             'FIFO',        null,          'A'
union  select  3,          '1',        'R',          'L',          null,         'PL',          'F',         'LTEQ',             'FIFO',        null,          'A'
/* Allocate Units from LPNs */
union  select  1,          '2',        'R',          'L',          null,         'OL',          'P',         null,               'FIFO',        null,          'A'
union  select  2,          '2',        'R',          'L',          null,         'PL',          'P',         null,               'FIFO',        null,          'A'
union  select  3,          '2',        'R',          'L',          null,         'FL',          'P',         null,               'FIFO',        null,          'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/***********************************************************************************************************************
  PTC Wave

  For PTC wave, allocate Units from Picklanes first, if not, do on demand replen, finally allocate from Reserve
***********************************************************************************************************************/
select @vWaveType  = 'PTC';
select @vSearchSet = 'AllocateInv_AvailableQtyFromPicklanes';

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate units from picklanes */
       select  1,          '1',       'K',           'U',          null,         'U',           'P',         null,               null,          null,          'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/*----------------------------------------------------------------------------*/
set @vSearchSet = 'AllocateInv_DirectedQtyFromPicklanes';

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate Directed units from picklanes */
       select  1,          '1',        'K',          'U' ,         null,         'U',           'UD',        null,               null,          null,          'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/*----------------------------------------------------------------------------*/
set @vSearchSet = 'AllocateInv_FromReserve';

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate Full LPNs */
       select  1,          '1',       'R',           'L',          null,         'FL',          'F',         'LTEQ',             'FIFO',         null,         'A'
union  select  2,          '1',       'R',           'L',          null,         'OL',          'F',         'LTEQ',             'FIFO',         null,         'A'
union  select  3,          '1',       'R',           'L',          null,         'PL',          'F',         'LTEQ',             'FIFO',         null,         'A'
/* Allocate Units from LPNs */
union  select  1,          '2',       'R',           'L',          null,         'OL',          'P',         null,               'FIFO',         null,         'A'
union  select  2,          '2',       'R',           'L',          null,         'PL',          'P',         null,               'FIFO',         null,         'A'
union  select  3,          '2',       'R',           'L',          null,         'FL',          'P',         null,               'FIFO',         null,         'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/***********************************************************************************************************************
  SLB Wave

  For SLB wave, allocate Cases from Reserve first, if not, allocate Units from Picklane, finally allocate Units from Reserve
***********************************************************************************************************************/
select @vWaveType  = 'SLB';

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_LPNsFromReserve';

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate Full LPNs From Reserve */
       select  1,          '1',       'R',           'L',          null,         'FL',          'F',         'LTEQ',             'FIFO',        null,          'A'
union  select  2,          '1',       'R',           'L',          null,         'OL',          'F',         'LTEQ',             'FIFO',        null,          'I'
union  select  3,          '1',       'R',           'L',          null,         'PL',          'F',         'LTEQ',             'FIFO',        null,          'I'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_AvailableQtyFromPicklanes';

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate units from picklanes */
       select  1,          '1',       'K',           'U',          null,         'U',           'P',         null,               null,          null,          'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_DirectedQtyFromPicklanes';

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate Directed units from picklanes */
       select  1,          '1',        'K',          'U',          null,         'U',           'UD',        null,               null,          null,          'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_AvailableQtyFromReserve';

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate Units from LPNs */
       select 1,           '1',       'R',           'L',          null,         'OL',          'P',         null,               'FIFO',         null,         'A'
union  select 2,           '1',       'R',           'L',          null,         'PL',          'P',         null,               'FIFO',         null,         'A'
union  select 3,           '1',       'R',           'L',          null,         'FL',          'P',         null,               'FIFO',         null,         'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/***********************************************************************************************************************
  LTL Wave

  For LTL wave, allocate full cases from Reserve/Bulk Locations and then allocate units
***********************************************************************************************************************/
select @vWaveType  = 'LTL';
select @vSearchSet = 'AllocateInv_LPNsFromReserve';

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate Full LPNs */
       select 1,           '1',       'R',           'L',          null,         'FL',          'F',         'LTEQ',             'FIFO',        null,          'A'
union  select 2,           '1',       'R',           'L',          null,         'PL',          'F',         'LTEQ',             'FIFO',        null,          'A'
union  select 3,           '1',       'R',           'L',          null,         'OL',          'F',         'LTEQ',             'FIFO',        null,          'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_UnitsFromReserve';

delete from AllocationRules where WaveType = @vWaveType and SearchSet = @vSearchSet;

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate Units from LPNs */
       select  1,          '2',       'R',           'L',          null,         'OL',          'P',         null,               'FIFO',         null,         'I'
union  select  2,          '2',       'R',           'L',          null,         'PL',          'P',         null,               'FIFO',         null,         'I'
union  select  3,          '2',       'R',           'L',          null,         'FL',          'P',         null,               'FIFO',         null,         'I'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_AvailableQtyFromPicklanes';

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate units from picklanes */
       select 1,           '1',       'K',           'U',          null,         'U',           'P',         null,               null,          null,          'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateInv_DirectedQtyFromPicklanes';

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate Directed units from picklanes */
      select  1,           '1',       'K',           'U',          null,         'U',           'UD',        null,               null,          null,          'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/***********************************************************************************************************************
  Replenishments to Dynamic Locations

  Allocate only what is required, do not over allocate
  First Allocate LPNs, Cases from reserve Locations
  Allocate Units from picklanes
  Allocate Units from reserve Locations
***********************************************************************************************************************/
select @vWaveType  = 'RU';

/*----------------------------------------------------------------------------*/
select @vSearchSet = 'AllocateCasesForDynamicReplenishments' /* Replenish dynamic locations */;

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate Full Cases */
       select 1,           '1',       'B',           'L',          null,         'FL',          'F',         'LTEQ',             'FIFO',        null,          'I'
union  select 2,           '1',       'R',           'L',          null,         'FL',          'F',         'LTEQ',             'FIFO',        null,          'A'
/* Allocate Opened Cases */
union  select 1,           '2',       'B',           'L',          null,         'OL',          'F',         'LTEQ',             'FIFO',        null,          'I'
union  select 2,           '2',       'R',           'L',          null,         'OL',          'F',         'LTEQ',             'FIFO',        null,          'A'
/* Allocate Partial Cases */
union  select 1,           '3',       'B',           'L',          null,         'PL',          'F',         'LTEQ',             'FIFO',        null,          'I'
union  select 2,           '3',       'R',           'L',          null,         'PL',          'F',         'LTEQ',             'FIFO',        null,          'A'
/* Allocate Cases from Opened cases */
union  select 1,           '4',       'B',           'L',          null,         'OL',          'P',         null,               'FIFO',        null,          'I'
union  select 2,           '4',       'R',           'L',          null,         'OL',          'P',         null,               'FIFO',        null,          'A'
/* Allocate Cases from Partial cases */
union  select 1,           '5',       'B',           'L',          null,         'PL',          'P',         null,               'FIFO',        null,          'I'
union  select 2,           '5',       'R',           'L',          null,         'PL',          'P',         null,               'FIFO',        null,          'A'
/* Allocate Cases from Full cases */
union  select 1,           '6',       'B',           'L',          null,         'FL',          'P',         null,               'FIFO',        null,          'I'
union  select 2,           '6',       'R',           'L',          null,         'FL',          'P',         null,               'FIFO',        null,          'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/*----------------------------------------------------------------------------*/
/* Allocate Units from picklanes
   Allocate Units from reserve Locations
*/
select @vSearchSet = 'AllocateUnitsForDynamicReplenishments';

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
       select 1,           '1',       'K',           'U',          null,         'U',           'U',         null,               null,          null,          'A'
/* Allocate Units from Opened cases */
union  select 1,           '2',       'B',           'L',          null,         'OL',          'P',         null,               'FIFO',        null,          'I'
union  select 2,           '2',       'R',           'L',          null,         'OL',          'P',         null,               'FIFO',        null,          'A'
/* Allocate Units from Partial cases */
union  select 1,           '3',       'B',           'L',          null,         'PL',          'P',         null,               'FIFO',        null,          'I'
union  select 2,           '3',       'R',           'L',          null,         'PL',          'P',         null,               'FIFO',        null,          'A'
/* Allocate Units from Full cases */
union  select 1,           '4',       'B',           'L',          null,         'FL',          'P',         null,               'FIFO',        null,          'I'
union  select 2,           '4',       'R',           'L',          null,         'FL',          'P',         null,               'FIFO',        null,          'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/*----------------------------------------------------------------------------*/
/* OnDemand Replenish - PickLane Unit Storage

  Allocate Partial cases from Reserve and then Full cases from Reserve. In each scenario, try to get from LPN Storage
    before we get from Pallets or Pallets & LPN storage
*/
select @vSearchSet = 'RU_OnDemand' /* OnDemand Replenish - PickLane Unit Storage */;

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate Partial cases whose Quantity is greater than or equal to Units to Allocate from rest of the PickZones */
       select 61,          '40',      'R',           'L',          null,         'PL',          'F',         'GTEQ',             'CUSTOM',      null,          'A'
union  select 62,          '40',      'R',           'LA',         null,         'PL',          'F',         'GTEQ',             'CUSTOM',      null,          'A'
union  select 63,          '40',      'R',           'A',          null,         'PL',          'F',         'GTEQ',             'CUSTOM',      null,          'A'

union  select 64,          '41',      'R',           'L',          null,         'FL',          'F',         'LTEQ',             'CUSTOM',      null,          'A'
union  select 65,          '41',      'R',           'LA',         null,         'FL',          'F',         'LTEQ',             'CUSTOM',      null,          'A'
union  select 66,          '41',      'R',           'A',          null,         'FL',          'F',         'LTEQ',             'CUSTOM',      null,          'A'

union  select 67,          '42',      'R',           'L',          null,         'PL',          'F',         'LTEQ',             'CUSTOM',      null,          'A'
union  select 68,          '42',      'R',           'LA',         null,         'PL',          'F',         'LTEQ',             'CUSTOM',      null,          'A'
union  select 69,          '42',      'R',           'A',          null,         'PL',          'F',         'LTEQ',             'CUSTOM',      null,          'A'

union  select 70,          '43',      'R',           'L',          null,         'FL',          'F',         'GTEQ',             'CUSTOM',      null,          'A'
union  select 71,          '43',      'R',           'LA',         null,         'FL',          'F',         'GTEQ',             'CUSTOM',      null,          'A'
union  select 72,          '43',      'R',           'A',          null,         'FL',          'F',         'GTEQ',             'CUSTOM',      null,          'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

/*----------------------------------------------------------------------------*/
/* Replenish - PickLane Unit Storage

  Allocate Partial cases from Reserve and then Full cases from Reserve. In each scenario, try to get from LPN Storage
    before we get from Pallets or Pallets & LPN storage
*/
select @vSearchSet = 'RU' /* Replenish - PickLane Unit Storage */;

delete from #AllocationRules
insert into #AllocationRules
             (SearchOrder, RuleGroup, LocationType,  StorageType,  PickingZone,  PickingClass,  SearchType,  QuantityCondition,  OrderByField,  OrderByType,   Status)
/* Allocate Partial cases whose Quantity is less than or equal to Units to Allocate */
       select 1,           '1',       'R',           'L',          null,         'PL',          'F',         'LTEQ',             'FIFO',        null,          'A'
union  select 2,           '1',       'R',           'LA',         null,         'PL',          'F',         'LTEQ',             'FIFO',        null,          'A'
union  select 3,           '1',       'R',           'A',          null,         'PL',          'F',         'LTEQ',             'FIFO',        null,          'A'

/* Allocate Full cases whose Quantity is less than or equal to Units to Allocate */
union  select 1,           '2',       'R',           'L',          null,         'FL',          'F',         'LTEQ',             'FIFO',        null,          'A'
union  select 2,           '2',       'R',           'LA',         null,         'FL',          'F',         'LTEQ',             'FIFO',        null,          'A'
union  select 3,           '2',       'R',           'A',          null,         'FL',          'F',         'LTEQ',             'FIFO',        null,          'A'

/* Allocate Partial cases whose Quantity is greater than or equal to Units to Allocate */
union  select 1,           '3',       'R',           'L',          null,         'PL',          'F',         'GTEQ',             'FIFO',        null,          'A'
union  select 2,           '3',       'R',           'LA',         null,         'PL',          'F',         'GTEQ',             'FIFO',        null,          'A'
union  select 3,           '3',       'R',           'A',          null,         'PL',          'F',         'GTEQ',             'FIFO',        null,          'A'

/* Allocate Full cases whose Quantity is greater than or equal to Units to Allocate */
union  select 1,           '4',       'R',           'L',          null,         'FL',          'F',         'GTEQ',             'FIFO',        null,          'A'
union  select 2,           '4',       'R',           'LA',         null,         'FL',          'F',         'GTEQ',             'FIFO',        null,          'A'
union  select 3,           '4',       'R',           'A',          null,         'FL',          'F',         'GTEQ',             'FIFO',        null,          'A'

/******************************************************************************/
exec pr_Setup_AllocationRules @vWaveType, @vSearchSet, @vWarehouses, 'DI' /* Delete & Add */

Go
