/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2014/04/16  TK      Changes made to control data using procedure
  2013/02/10  AY      Added SortSeq
  2011/02/09  PK      Added BusinessUnit
  2011/01/13  VK      Initial Revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* DataTypes */
/*------------------------------------------------------------------------------*/
declare @DataTypes TEntityTypesTable, @Entity TEntity = 'Data';

insert into @DataTypes
       (TypeCode,  TypeDescription,  Status)
values ('I',       'Integer',        'A'),
       ('S',       'String',         'A'),
       ('B',       'Binary',         'A'),
       ('F',       'Float',          'A')

exec pr_EntityTypes_Setup @Entity, @DataTypes;

Go
