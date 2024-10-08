/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/01  AY      Added Non-Directed for CC_SubTask (CIMSV3-1026)
  2020/05/15  AY      Added PickTaskSubType (HA-566)
  2017/01/17  OK      Added L1, L2 sub tasktypes (GNC-1408)
  2017/01/10  MV      SubTask : Added the Directed supervisor (GNC-1406)
  2015/07/26  TK      Added Pallet Pick TaskSubType.
  2014/01/09  TK      Added Pick Empty and Pick Non Empty TaskSubTypes.
  2014/04/16  TK      Changes made to control data using procedure
  2011/12/19  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Task Type */
/*------------------------------------------------------------------------------*/
declare @TaskTypes TEntityTypesTable, @Entity TEntity = 'Task';

insert into @TaskTypes
       (TypeCode,  TypeDescription,   Status)
values ('CC',      'Cycle Counting',  'A'),
       ('PB',      'Picking',         'A')

exec pr_EntityTypes_Setup @Entity, @TaskTypes;

Go

/*------------------------------------------------------------------------------*/
/* SubTask Type */
/*------------------------------------------------------------------------------*/
declare @TaskSubTypes TEntityTypesTable, @Entity TEntity = 'SubTask';

insert into @TaskSubTypes
       (TypeCode,  TypeDescription,      Status)
values ('D',       'Directed',           'A'),
       ('DL1',     'Directed Supervisor','A'),
       ('N',       'Non Directed',       'A'),
       ('P',       'Pallet Pick',        'A'),
       /* Cycle count Task Sub Types */
       ('L1',      'User Count',         'A'),
       ('L2',      'Supervisor Count',   'A'),
       ('L',       'LPN Pick',           'A'),
       ('CS',      'Case Pick',          'A'),
       ('U',       'Unit Pick',          'A'),
       ('PE',      'Pick Empty',         'A'),
       ('PN',      'Picking Non Empty',  'A'),
       ('RP',      'Replenish Pick',     'A')

exec pr_EntityTypes_Setup @Entity, @TaskSubTypes;

/*------------------------------------------------------------------------------*/
/* Cycle count SubTask Type - to be used for drop downs */
/*------------------------------------------------------------------------------*/
declare @TaskSubTypeEntityTypes TEntityTypesTable, @TaskSubTypeEntity TEntity = 'CC_SubTask';

insert into @TaskSubTypeEntityTypes
       (TypeCode,  TypeDescription,     Status)
values /* Cycle count Task Sub Types */
       ('L1',      'User Count',        'A'),
       ('L2',      'Supervisor Count',  'A'),
       ('N',       'Non-Directed',      'A')

exec pr_EntityTypes_Setup @TaskSubTypeEntity, @TaskSubTypeEntityTypes;

/*------------------------------------------------------------------------------*/
/* PickTask SubType */
/*------------------------------------------------------------------------------*/
declare @PickTaskSubTypes TEntityTypesTable, @PickTaskSubTypeEntity TEntity = 'PickTaskSubType';

insert into @PickTaskSubTypes
       (TypeCode,  TypeDescription,      Status)
values ('P',       'Pallet Pick',        'A'),
       ('L',       'LPN Pick',           'A'),
       ('CS',      'Case Pick',          'A'),
       ('U',       'Unit Pick',          'A');

exec pr_EntityTypes_Setup @PickTaskSubTypeEntity, @PickTaskSubTypes;

Go
