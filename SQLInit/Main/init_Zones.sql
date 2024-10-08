/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/11  AY      Added Receiving Reserve Zone for Floor Reserve Locations at Receiving
  2020/04/20  TK      Added Zones for CasePick & Rework Waves (HA-226)
  2020/04/15  AY      set up RecvStaging/ShipStaging zones
  2019/06/03  VS      Added Pause and Hold Zones (CID-486)
  2019/04/09  VS      Added VAS Zone (CID-206)
  2019/03/26  VS      Setup Drop Zones (CID-220)
  2015/05/12  AY      Generalized the zones for default CIMS Setup
  2015/03/03  TK      Added DropZones
  2014/04/16  TK      Changes made to control data using procedure
  2013/05/23  VM      Setup PA Zones for TLP
------------------------------------------------------------------------------*/
/*--------Need to add this LookUpCategory into Init_LookUps.sql file----------*/

Go

/*------------------------------------------------------------------------------
 Pick Zones
 -----------------------------------------------------------------------------*/
declare @PickZones TLookUpsTable, @LookUpCategory TCategory = 'PickZones';

insert into @PickZones
       (LookUpCode,        LookUpDescription,         Status)
values ('R01',             'Reserve',                 'A'),
       ('P01',             'Picklanes',               'A'),
       ('RRecv',           'Receiving Reserve',       'A'),
       ('Drop-BPP',        'BPP Drop Area',           'I'),
       ('Drop-BCP',        'Case Pick Drop Area',     'I'),
       ('Drop-PTS',        'PTS Drop Area',           'I'),
       ('Drop-PTC',        'PTC Drop Area',           'I'),
       ('Drop-SLB',        'SLB Drop Area',           'I'),
       ('Drop-LTL',        'LTL Drop Area',           'I'),
       ('Drop-XFER',       'Xfer Drop Area',          'I'),
       ('Drop-RW',         'Rework Drop Area',        'I'),
       ('Drop-Pause',      'Pause Drop Area',         'I'),
       ('Drop-Hold',       'Hold Drop Area',          'I');

exec pr_LookUps_Setup @LookUpCategory, @PickZones;

Go

/*------------------------------------------------------------------------------
 Putaway Zones
 -----------------------------------------------------------------------------*/
declare @PutawayZones TLookUpsTable, @LookUpCategory TCategory = 'PutawayZones';

insert into @PutawayZones
       (LookUpCode,        LookUpDescription,         Status)
values ('R01',             'Reserve',                 'A'),
       ('P01',             'Picklanes'    ,           'A'),
       ('Drop-BPP',        'BPP Drop Area',           'A'),
       ('Drop-BCP',        'Case Pick Drop Area',     'A'),
       ('Drop-PTS',        'PTS Drop Area',           'A'),
       ('Drop-PTC',        'PTC Drop Area',           'A'),
       ('Drop-SLB',        'SLB Drop Area',           'A'),
       ('Drop-LTL',        'LTL Drop Area',           'A'),
       ('Drop-XFER',       'Xfer Drop Area',          'A'),
       ('Drop-RW',         'Rework Drop Area',        'A'),
       ('Drop-Pause',      'Pause Drop Area',         'A'),
       ('Drop-Hold',       'Hold Drop Area',          'A'),
       ('RecvStaging',     'Receiving Staging',       'A'),
       ('ShipStaging',     'Shipping Staging',        'A');

exec pr_LookUps_Setup @LookUpCategory, @PutawayZones;

Go

/*------------------------------------------------------------------------------
 Drop Zones
 -----------------------------------------------------------------------------*/
declare @DropZones TLookUpsTable, @LookUpCategory TCategory = 'DropZones';

insert into @DropZones
       (LookUpCode,        LookUpDescription,         Status)
values ('Drop-BPP',        'BPP Drop Area',           'A'),
       ('Drop-BCP',        'Case Pick Drop Area',     'A'),
       ('Drop-PTS',        'PTS Drop Area',           'A'),
       ('Drop-PTC',        'PTC Drop Area',           'A'),
       ('Drop-SLB',        'SLB Drop Area',           'A'),
       ('Drop-LTL',        'LTL Drop Area',           'A'),
       ('Drop-XFER',       'XFer Drop Area',          'A'),
       ('Drop-RW',         'Rework Drop Area',        'A'),
       ('Drop-Pause',      'Pause Drop Area',         'A'),
       ('Drop-Hold',       'Hold Drop Area',          'A'),
       ('QualityCheck',    'Quality Check Area',      'A'),
       ('ShipStaging',     'Outbound Staging Area',   'A'),
       ('DZ1',             'Drop Zone 1',             'A'),
       ('DZ2',             'Drop Zone 2',             'A'),
       ('DZ3',             'Drop Zone 3',             'A'),
       ('DZ4',             'Drop Zone 4',             'A'),
       ('DZ5',             'Drop Zone 5',             'A');

exec pr_LookUps_Setup @LookUpCategory, @DropZones;

Go
