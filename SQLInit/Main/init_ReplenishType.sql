/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2014/04/16  TK      Changes made to control data using procedure
  2012/02/07  VM      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Pick Batch Status */
/*------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Replenish Type */
/*------------------------------------------------------------------------------*/
declare @ReplenishTypes TEntityTypesTable, @Entity TEntity = 'Replenish';

insert into @ReplenishTypes
       (TypeCode,  TypeDescription,                               Status)
values ('H',       'Hot',       /* (Qty < Required Order Qty) */  'A'),
       ('R',       'Required',  /* (Qty < Min repl. level)    */  'A'),
       ('F',       'Fill Up',   /* (Qty < Max repl. level)    */  'A')

exec pr_EntityTypes_Setup @Entity, @ReplenishTypes;

Go
