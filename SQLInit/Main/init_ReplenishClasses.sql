/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2017/08/09  TK      Initial revision (HPI-1624)
------------------------------------------------------------------------------*/

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
