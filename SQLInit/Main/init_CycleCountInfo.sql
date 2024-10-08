/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/17  SK     Added new category CC_Process (HA-1567)
  2020/07/16  MS     Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  CC_LocationDetail - Locations for CC can be selected by themselves or by Location & SKU
 -----------------------------------------------------------------------------*/
declare @CCDetailLevels TLookUpsTable, @LookUpCategory TCategory = 'CC_LocationDetail';

insert into @CCDetailLevels
       (LookUpCode,  LookUpDescription,      Status)
values ('LOC',       'Location',             'A'),
       ('LOCSKU',    'Location & SKU',       'A');

exec pr_LookUps_Setup @LookUpCategory, @CCDetailLevels, @LookUpCategoryDesc = 'CycleCount Location Detail';

Go

/*------------------------------------------------------------------------------*/
/* CC_Level: Cycle count levels - to be used for drop downs */
/*------------------------------------------------------------------------------*/
declare @CCLevels TLookUpsTable, @LookUpCategory TCategory = 'CC_Level';

insert into @CCLevels
       (LookUpCode,  LookUpDescription,      Status)
values /* Cycle count Levels */
       ('L1',       'User Count',            'A'),
       ('L2',       'Supervisor Count',      'A')

exec pr_LookUps_Setup @LookUpCategory, @CCLevels, @LookUpCategoryDesc = 'CycleCount Level';

Go

/*------------------------------------------------------------------------------*/
/* CC_Process: Cycle count Process */
/*------------------------------------------------------------------------------*/
declare @CCLevels TLookUpsTable, @LookUpCategory TCategory = 'CC_Process';

insert into @CCLevels
       (LookUpCode,  LookUpDescription,      Status)
values /* Cycle count Levels */
       ('CC',       'Cycle Count',           'A'),
       ('PI',       'Physical Inventory',    'A')

exec pr_LookUps_Setup @LookUpCategory, @CCLevels, @LookUpCategoryDesc = 'CycleCount Process';

Go