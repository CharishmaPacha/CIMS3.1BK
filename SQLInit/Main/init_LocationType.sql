/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2018/01/11  OK      Added the Location type for Generate Locations (S2G-64)
  2014/04/16  TK      Changes made to control data using procedure
  2012/06/27  AY      Added Conveyor Location Type
  2011/02/09  PK      Added BusinessUnit field in EntityType table.
  2010/10/06  PK      Initial Revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Location Type */
/*------------------------------------------------------------------------------*/
declare @LocationTypes TEntityTypesTable, @Entity TEntity = 'Location';

insert into @LocationTypes
       (TypeCode, TypeDescription,         Status)
values ('R',      'Reserve',               'A'),
       ('B',      'Bulk',                  'A'),
       ('K',      'Picklane',              'A'),
       ('KD',     'Dynamic Picklane',      'I'),
       ('KS',     'Static Picklane',       'I'),
       ('S',      'Staging',               'A'),
       ('D',      'Dock',                  'A'),
       ('C',      'Conveyor',              'I')

exec pr_EntityTypes_Setup @Entity, @LocationTypes;

Go

/*------------------------------------------------------------------------------*/
/* Location Types for Generate Locations */
/*------------------------------------------------------------------------------*/
declare @LocationTypes TEntityTypesTable, @Entity TEntity = 'LOCTypeforGenerate';

insert into @LocationTypes
       (TypeCode, TypeDescription,         Status)
values ('R',      'Reserve',               'A'),
       ('B',      'Bulk',                  'A'),
       ('K',      'Picklane',              'I'),
       ('KD',     'Dynamic Picklane',      'A'),
       ('KS',     'Static Picklane',       'A'),
       ('S',      'Staging',               'A'),
       ('D',      'Dock',                  'A'),
       ('C',      'Conveyor',              'I')

exec pr_EntityTypes_Setup @Entity, @LocationTypes;

Go
