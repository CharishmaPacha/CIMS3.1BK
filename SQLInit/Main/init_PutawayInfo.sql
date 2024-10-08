/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/10/18  GAG     Added LPNPutawayClasses and SKUPutawayClasses (CIMSV3-1622)
  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2014/04/16  TK      Changes made to control data using procedure
  2013/09/10  NY      Initial Revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 LPNPutaway Classes
 -----------------------------------------------------------------------------*/
declare @PutawayClasses TLookUpsTable, @LookUpCategory TCategory = 'LPNPutawayClasses';

insert into @PutawayClasses
       (LookUpCode,  LookUpDescription,  Status)
values ('FL',        'Full LPN',         'A'),
       ('PL',        'Partial LPN',      'A'),
       ('QC',        'QC LPN',           'A'),
       ('RC',        'Replenish LPN',    'A'),
       ('1',         '1',                'I'),
       ('2',         '2',                'I'),
       ('3',         '3',                'I')

exec pr_LookUps_Setup @LookUpCategory, @PutawayClasses, @LookUpCategoryDesc = 'LPN Putaway Classes';

Go

/*------------------------------------------------------------------------------*/
/* Putaway Type  */
/*------------------------------------------------------------------------------*/
declare @PutawayTypes TEntityTypesTable, @Entity TEntity = 'Putaway';

insert into @PutawayTypes
       (TypeCode,  TypeDescription,  Status)
values ('L',       'LPNs',           'A'),
       ('P',       'Pallets',        'A'),
       ('LP',      'LPNs on Pallets','A'),
       ('LD',      'LPN Details',    'A')

exec pr_EntityTypes_Setup @Entity, @PutawayTypes;

Go

/*------------------------------------------------------------------------------
Putaway Classes
 -----------------------------------------------------------------------------*/
declare @PutawayClasses TLookUpsTable, @LookUpCategory TCategory = 'PutawayClasses';

insert into @PutawayClasses
       (LookUpCode,  LookUpDescription,  Status)
values ('01',        'Generic',          'A')

exec pr_LookUps_Setup @LookUpCategory, @PutawayClasses, @LookUpCategoryDesc = 'Putaway Classes';

Go
