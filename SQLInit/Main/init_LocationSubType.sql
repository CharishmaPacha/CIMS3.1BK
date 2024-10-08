/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2014/04/16  TK      Changes made to control data using procedure
  2012/02/07  YA      Initial Revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Location Sub Type */
/*------------------------------------------------------------------------------*/
declare @LocationSubTypes TEntityTypesTable, @Entity TEntity = 'LocationSubType';

insert into @LocationSubTypes
       (TypeCode, TypeDescription,   Status)
values ('D',      'Dynamic',         'A'),
       ('S',      'Static',          'A')

exec pr_EntityTypes_Setup @Entity, @LocationSubTypes;

Go
