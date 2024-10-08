/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2015/09/29  YJ      Added Storage types for ReplenishStorageTypes (FB-396)
  2014/04/16  TK      Changes made to control data using procedure
  2012/05/31  AY      Added Pallet & LPNs Storage type.
  2012/03/16  PK      Added Pallet Storage type.
  2011/07/08  AY      Added Storage Types for Loehmanns
  2011/02/09  PK      Added BusinessUnit field in EntityType table.
  2010/10/06  PK      Initial Revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Location Storage Type */
/*------------------------------------------------------------------------------*/
declare @LocationStorageTypes TEntityTypesTable, @Entity TEntity = 'LocationStorage';

insert into @LocationStorageTypes
       (TypeCode,  TypeDescription,   Status)
values ('L',       'LPNs',            'A'),
       ('P',       'Cases',           'A'),
       ('U',       'Units',           'A'),
       ('A',       'Pallets',         'A'),
       ('LA',      'Pallets & LPNs',  'A'),
       ('LF',      'LPNs Flat',       'I'),
       ('LH',      'LPNs Hanging',    'I'),
       ('UF',      'Units Flat',      'I'),
       ('UH',      'Units Hanging',   'I')

exec pr_EntityTypes_Setup @Entity, @LocationStorageTypes;

Go

/*------------------------------------------------------------------------------*/
/* Replenish Storage Types */
/*------------------------------------------------------------------------------*/
declare @LocationStorageTypes TEntityTypesTable, @Entity TEntity = 'ReplenishStorageTypes';

insert into @LocationStorageTypes
       (TypeCode,  TypeDescription,   Status)
values ('P',       'Cases',           'A'),
       ('U',       'Units',           'A')

exec pr_EntityTypes_Setup @Entity, @LocationStorageTypes;

Go
