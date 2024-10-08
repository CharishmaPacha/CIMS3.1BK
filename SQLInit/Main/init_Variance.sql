/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2014/04/16  TK      Changes made to control data using procedure
  2012/01/20  YA      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Variance
 -----------------------------------------------------------------------------*/
declare @Variance TLookUpsTable, @LookUpCategory TCategory = 'Variance';

insert into @Variance
       (LookUpCode,  LookUpDescription,        Status)
values ('M',         'SKU Misplaced',          'A'),
       ('N',         'New SKU in Location',    'A'),
       ('Q',         'Change in Quantity',     'A')

exec pr_LookUps_Setup @LookUpCategory, @Variance, @LookUpCategoryDesc = 'Variance';

Go
