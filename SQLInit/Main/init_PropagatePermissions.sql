/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2020/04/20  TK      Initial revision (HA-69)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  YesNo
 -----------------------------------------------------------------------------*/
declare @TrueFalse TLookUpsTable, @LookUpCategory TCategory = 'PropagatePermissions';

insert into @TrueFalse
       (LookUpCode,  LookUpDescription,                     Status)
values ('P',         'Selected Operation only',             'A'),
       ('PC',        'Selected Operation & its child',      'A')

exec pr_LookUps_Setup @LookUpCategory, @TrueFalse, @LookUpCategoryDesc = 'Propagate Permisisons options';

Go
