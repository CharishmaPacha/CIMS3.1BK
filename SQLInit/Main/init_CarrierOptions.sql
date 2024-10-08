/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2019/01/03  MS      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  CarrierOptions
 -----------------------------------------------------------------------------*/
declare @CarrierOptions TLookUpsTable, @LookUpCategory TCategory = 'CarrierOptions';

insert into @CarrierOptions
       (LookUpCode,  LookUpDescription,           Status)
values ('N',         'No Insurance required',     'A'),
       ('IA',        'Insure All Packages',       'A'),
       ('IR',        'Insure considering Rules',  'A')

exec pr_LookUps_Setup @LookUpCategory, @CarrierOptions, @LookUpCategoryDesc = 'Carrier Options';

Go
