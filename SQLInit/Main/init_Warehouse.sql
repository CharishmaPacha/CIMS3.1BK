/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2014/04/16  TK      Changes made to control data using procedure
  2012/02/05  AY      Initial revision
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Warehouses
 -----------------------------------------------------------------------------*/
declare @Warehouses TLookUpsTable, @LookUpCategory TCategory = 'Warehouse';

insert into @Warehouses
/* SCT */
       (LookUpCode,  LookUpDescription,  Status)
values ('W1',        'Atlanta DC',       'A'),
       ('W2',        'Greenville DC',    'A'),

/* The Latin Products */
       ('ATLGA',     'Atlanta, GA',      'I')

exec pr_LookUps_Setup @LookUpCategory, @Warehouses, @LookUpCategoryDesc = 'Warehouses';

Go
