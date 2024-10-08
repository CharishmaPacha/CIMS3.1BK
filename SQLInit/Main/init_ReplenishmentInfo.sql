/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/10/18  GAG     Initial revision (CIMSV3-1622)
------------------------------------------------------------------------------*/

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

/*------------------------------------------------------------------------------
 Putaway Classes
 -----------------------------------------------------------------------------*/
declare @ReplenishClasses TLookUpsTable, @LookUpCategory TCategory = 'ReplenishClasses';

insert into @ReplenishClasses
       (LookUpCode,  LookUpDescription,           Status)
values ('PC',        'Replenish partial cases',   'A'),
       ('FC',        'Replenish full cases',      'A')

exec pr_LookUps_Setup @LookUpCategory, @ReplenishClasses, @LookUpCategoryDesc = 'Replenish Classes';

Go

/*------------------------------------------------------------------------------
  Replenish UoMs
 -----------------------------------------------------------------------------*/
declare @UoMs TLookUpsTable, @LookUpCategory TCategory = 'ReplenishUoM';

insert into @UoMs
       (LookUpCode,   LookUpDescription,            Status)
values ('LPN',        'Pallets',                    'A'),
       ('CS',         'Cases',                      'A'),
       ('EA',         'Eaches',                     'A')

exec pr_LookUps_Setup @LookUpCategory, @UoMs, @LookUpCategoryDesc = 'Replenish UoM';

Go
