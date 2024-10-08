/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2015/09/16  SV      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Print Label Type */
/*------------------------------------------------------------------------------*/
declare @LabelTypesLookUps TLookUpsTable, @LookUpCategory TCategory = 'RePrintLabelType';

insert into @LabelTypesLookUps
       (LookUpCode,  LookUpDescription,      Status)
values ('SL',        'Reprint Ship Label',   'A')

exec pr_LookUps_Setup @LookUpCategory, @LabelTypesLookUps, @LookUpCategoryDesc = 'Reprint Label Type';

Go
