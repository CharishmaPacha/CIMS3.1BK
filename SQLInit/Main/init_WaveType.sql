/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/08/27  AY      Setup standard WaveTypes for CIMS
  2016/07/17  AY      Added SLB and cleaned up others that are HPI specific
  2016/06/13  KN      Added: DHL related code (NBD-554).
  2016/04/30  KL      Added wave type's (SP - Special, SW - Sew-To, PC - Pick To Cart (HPI-60)
  2016/03/24  RV      Added New entity type CreatePickBatch to filter the unwanted wave types while create batch (CIMS-548)
  2016/06/11  AY      Added new batch type SL - Single Line
  2016/02/10  KN      Added a new batch type USPS (NBD-162)
  2015/10/29  AY      Added WaveType R for Replenish to Reserve
  2015/04/23  PK      Added a new batch type for BulkPull Preference.
  2015/02/26  TK      Added new batch type for Bulk Pull.
  2014/04/16  TK      Changes made to control data using procedure
  2103/06/17  TD      Added new batch type Replenish.
  2012/03/25  TD      Added new BatchTypes S-Small Orders, L-Large Orders.
  2012/05/25  NY      Initial revision.
------------------------------------------------------------------------------*/

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
