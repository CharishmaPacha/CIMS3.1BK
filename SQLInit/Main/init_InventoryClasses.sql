/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2020/03/30  MS      Initial Revison (HA-77)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 InventoryClass1
 -----------------------------------------------------------------------------*/
declare @InventoryClasses TLookUpsTable, @LookUpCategory TCategory = 'InventoryClass1';

insert into @InventoryClasses
       (LookUpCode,  LookUpDescription,  Status)
values ('',          'None',             'A')

exec pr_LookUps_Setup @LookUpCategory, @InventoryClasses, @LookUpCategoryDesc = 'Inventory Class1';

Go

/*------------------------------------------------------------------------------
 InventoryClass2
 -----------------------------------------------------------------------------*/
declare @InventoryClasses TLookUpsTable, @LookUpCategory TCategory = 'InventoryClass2';

insert into @InventoryClasses
       (LookUpCode,  LookUpDescription,  Status)
values ('',          '',                 'A')

exec pr_LookUps_Setup @LookUpCategory, @InventoryClasses, @LookUpCategoryDesc = 'Inventory Class2';

Go

/*------------------------------------------------------------------------------
 InventoryClass3
 -----------------------------------------------------------------------------*/
declare @InventoryClasses TLookUpsTable, @LookUpCategory TCategory = 'InventoryClass3';

insert into @InventoryClasses
       (LookUpCode,  LookUpDescription,   Status)
values ('',          '',                  'A')

exec pr_LookUps_Setup @LookUpCategory, @InventoryClasses, @LookUpCategoryDesc = 'Inventory Class3';

Go
