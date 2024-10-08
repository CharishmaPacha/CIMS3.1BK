/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/02/22  AY      Load Consolidator changes (HA-2042)
  2020/12/06  MS      Corrections as per New Standards (CIMSV3-1273)
  2020/12/04  PHK     Added contact type for Consolidator Address (HA-1020)
  2015/04/22  YJ      Added Contact Type MarkForAddress.
  2014/04/16  TK      Changes made to control data using procedure
  2011/02/09  PK      Addedd BusinessUnit field in EntityTypes table.
  2010/10/14  VM      Added 'Bill To'
  2010/09/20  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Contact Type  */
/*------------------------------------------------------------------------------*/
declare @ContactTypes TEntityTypesTable, @Entity TEntity = 'Contact';

insert into @ContactTypes
       (TypeCode,  TypeDescription,  Status)
values ('C',       'Customer',       'A'),
       ('F',       'Ship From',      'A'),
       ('O',       'Owner',          'A'),
       ('S',       'Ship To',        'A'),
       ('V',       'Vendor',         'A'),
       ('B',       'Bill To',        'A'),
       ('R',       'Return',         'A'),
       ('M',       'Mark For',       'A'),
       ('FC',      'Consolidator',   'A')

exec pr_EntityTypes_Setup @Entity, @ContactTypes;

Go
