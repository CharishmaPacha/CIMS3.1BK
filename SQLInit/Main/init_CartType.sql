/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2018/12/04  TK      Initial revision (HPI-2049)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Cart Types
------------------------------------------------------------------------------*/
declare @WaveTypes TEntityTypesTable, @Entity TEntity = 'CartType';

insert into @WaveTypes
       (TypeCode,  TypeDescription,            Status)
values ('C1',      '8 Shelf Cart - 72" wide',  'A'),
       ('C2',      '6 Shelf Cart - 54" wide',  'A')

exec pr_EntityTypes_Setup @Entity, @WaveTypes;

Go
