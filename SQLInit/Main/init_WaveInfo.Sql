/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/11/28  GAG     File consolidation changes (CIMSV3-2470)
  2021/05/20  TK      Initial Revison (HA-2813)
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
 Cartonization Model
------------------------------------------------------------------------------*/
declare @ttCartonizationModels TLookUpsTable, @LookUpCategory TCategory = 'CartonizationModel';

insert into @ttCartonizationModels
       (LookUpCode,     LookUpDescription,         Status)
values ('Default',      'Default',                 'A'),
       ('ByVolume',     'By Volume',               'A'),
       ('ByPrepack',    'By Prepack',              'A')

exec pr_LookUps_Setup @LookUpCategory, @ttCartonizationModels;

Go

/*------------------------------------------------------------------------------*/
/* Wave Status for Generate Waves from Open Orders */
/*------------------------------------------------------------------------------*/
declare @WaveStatuses TStatusesTable, @Entity TEntity = 'GeneratePickBatch';

insert into @WaveStatuses
       (StatusCode,  StatusDescription,  Status)
values ('N',         'New',              'A'),
       ('E',         'Released',         'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @WaveStatuses;  -- for V2, to be deprecated
exec pr_Statuses_Setup 'GenerateWave', @WaveStatuses; -- for V3

Go

/*------------------------------------------------------------------------------
 Inv Allocation Model
 -----------------------------------------------------------------------------*/
declare @InvAllocationModel TLookUpsTable, @LookUpCategory TCategory = 'InvAllocationModel';

insert into @InvAllocationModel
       (LookUpCode,  LookUpDescription,         Status)
values ('SR',        'System Reservation',      'A'),
       ('MR',        'Manual Reservation',      'A')

exec pr_LookUps_Setup @LookUpCategory, @InvAllocationModel;

Go

/*------------------------------------------------------------------------------*/
/* Wave Types:

  PTS: Pick into a shipping carton on the cart
  PTC: Pick to cart/tote and pack order later
  SLB: Single Line order - Bulk Pull - Pack order on scan of SKU

  CP: Pick LPNs/Cases and ship
  PTLC: Pick using a shipping label for each cases directly from location. May involve replenish to location first.
  PTL: Pick multiple units per shipping cartons, Confirm Pick Tasks. May involve replenish to location first.

  BCP: Bulk Pull LPNs/Cases and then activate shipping labels
  BPP: Bulk Pull inventory for multi-SKU orders, activate shipping labels by Confirm Pick Tasks

  RW: Pull inventory, rework, put same LPNs back into stock
  MK: Pull Components, rework, Put kits back into stock
  BK: Pull kits, rework, Put components back into stock

  R*: Replenish
 */
/*------------------------------------------------------------------------------*/
declare @WaveTypes TEntityTypesTable, @Entity TEntity = 'PickBatch';

insert into @WaveTypes
       (TypeCode,  TypeDescription,     Status)
values ('PTS',     'Pick To Ship',      'A'),
       ('PTC',     'Pick To Cart',      'A'),
       ('SLB',     'Single Line Bulk',  'A'),

       ('CP',      'Case Pick',         'A'),
       ('PTLC',    'Pick To Label/Case','I'),
       ('PTL',     'Pick To Label',     'I'),

       ('BCP',     'Bulk Case Pick',    'A'),
       ('BPP',     'Pick & Pack',       'A'), -- also referred as DTS by S2GCA

       ('RW',      'Rework',            'A'),
       ('MK',      'Make Kits',         'I'),
       ('BK',      'Break Kits',        'I'),
       ('XFER',    'Transfer',          'A'),

       ('R',       'Replenish',         'I'),
       ('RU',      'Replenish Units',   'A'),
       ('RP',      'Replenish Cases',   'A');

exec pr_EntityTypes_Setup @Entity, @WaveTypes; -- for V2, to be deprecated
exec pr_EntityTypes_Setup 'Wave', @WaveTypes; -- for V3

/*------------------------------------------------------------------------------*/
/* Create Wave Type V2 */
/*------------------------------------------------------------------------------*/
declare @CreateWaveTypes TEntityTypesTable;
select @Entity = 'CreatePickBatch';

insert into @CreateWaveTypes (TypeCode, TypeDescription, Status)
  select TypeCode, TypeDescription, Status
  from @WaveTypes
  where (TypeCode not in ('RU'/* Replenish Units */, 'RP' /* Replenish Cases */, 'R' /* Replenish Orders */)) and
        (Status <> 'I'/* In-Active */);

exec pr_EntityTypes_Setup @Entity, @CreateWaveTypes; -- for V2, to be deprecated
exec pr_EntityTypes_Setup 'CreateWave', @CreateWaveTypes; -- for V3

Go

/*------------------------------------------------------------------------------*/
/* Wave Status */
/*------------------------------------------------------------------------------*/
declare @WaveStatuses TStatusesTable, @Entity TEntity = 'PickBatch';

insert into @WaveStatuses
       (StatusCode,  StatusDescription,  Status)
values ('N',         'New',              'A'),
       ('B',         'Planned',          'A'),
       ('L',         'Ready To Pull',    'I'),
       ('E',         'Released',         'A'),
       ('R',         'Ready To Pick',    'A'),
       ('P',         'Picking',          'A'),
       ('U',         'Paused',           'A'),
       ('K',         'Picked',           'A'),
       ('A',         'Packing',          'A'),
       ('C',         'Packed',           'A'),
       ('G',         'Staged',           'A'),
       ('O',         'Loaded',           'A')

insert into @WaveStatuses
       (StatusCode,  StatusDescription,    Status,  SortSeq)
values ('S',         'Shipped',            'A',     90),
       ('D',         'Completed',          'A',     91),
       ('X',         'Canceled',           'A',     92)

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @WaveStatuses; -- for V2, to be deprecated
exec pr_Statuses_Setup 'Wave', @WaveStatuses; -- for V3

Go

/*------------------------------------------------------------------------------
  PickSequence
 -----------------------------------------------------------------------------*/
declare @PickSequence TLookUpsTable, @LookUpCategory TCategory = 'WavePickSequence';

insert into @PickSequence
       (LookUpCode,  LookUpDescription,                  Status)
values ('Optimal',   'Optimal, in pickpath order',       'A'),
       ('Order',     'Pick by Order, pickpath',          'I'),
       ('Style',     'Pick by Order, Style',             'I')

exec pr_LookUps_Setup @LookUpCategory, @PickSequence, @LookUpCategoryDesc = 'Pick Sequence';

Go
