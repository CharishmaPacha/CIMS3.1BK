/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/12/07  GAG     File consolidation changes (CIMSV3-2479)
------------------------------------------------------------------------------*/

Go

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

Go

/*------------------------------------------------------------------------------
  PickMethods Types
 -----------------------------------------------------------------------------*/
declare @PickMethods TLookUpsTable, @LookUpCategory TCategory = 'PickMethod';

insert into @PickMethods
       (LookUpCode,   LookUpDescription,         Status)
values ('CIMSRF',     'CIMS RF',                 'A'   ),
       ('6River',     '6 River',                 'A'   );

exec pr_LookUps_Setup @LookUpCategory, @PickMethods, @LookUpCategoryDesc = 'Pick Methods';

Go

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

/*------------------------------------------------------------------------------
  PickUoM
 -----------------------------------------------------------------------------*/
declare @PickUoMs TLookUpsTable, @LookUpCategory TCategory = 'PickUoM';

insert into @PickUoMs
       (LookUpCode,  LookUpDescription,      SortSeq,  Status, Visible)
values ('U',         'Units',                1,        'A',    'False'),
       ('C',         'Cases',                2,        'A',    'False'),
       ('B',         'Bulk',                 3,        'A',    'False')

exec pr_LookUps_Setup @LookUpCategory, @PickUoMs, @LookUpCategoryDesc = 'Pick UoM';

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
/* Task Status */
/*------------------------------------------------------------------------------*/
declare @TaskStatuses TStatusesTable, @Entity TEntity = 'Task';

insert into @TaskStatuses
       (StatusCode,  StatusDescription,  Status)
values ('O',         'On hold',          'A'),
       ('N',         'Ready to start',   'A'),
       ('I',         'In Progress',      'A'),
       ('C',         'Completed',        'A')

insert into @TaskStatuses
       (StatusCode,  StatusDescription,  Status,  SortSeq)
values ('X',         'Canceled',         'A',     99)

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @TaskStatuses;

Go
