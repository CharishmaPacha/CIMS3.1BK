/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2020/09/17  RBV     Initial revision. (CID - 1488)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  PickMethods Types
 -----------------------------------------------------------------------------*/
declare @PickMethods TLookUpsTable, @LookUpCategory TCategory = 'PickMethod';

insert into @PickMethods
       (LookUpCode,   LookUpDescription,         Status)
values ('CIMSRF',     'CIMS RF',                 'A'   ),
       ('6River',     '6 River',                 'A'   );

exec pr_LookUps_Setup @LookUpCategory, @PickMethods, @LookUpCategoryDesc = 'Pick Methods';

Go
