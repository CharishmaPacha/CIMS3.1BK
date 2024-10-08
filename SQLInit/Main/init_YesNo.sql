/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2014/04/16  TK      Changes made to control data using procedure
  2012/06/30  PKS     Visible set to false, because no need to show this category in UI Maintenance->Lists page.
  2011/07/21  TD      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  YesNo
 -----------------------------------------------------------------------------*/
declare @YesNo TLookUpsTable, @LookUpCategory TCategory = 'YesNo';

insert into @YesNo
       (LookUpCode,  LookUpDescription,  Status)
values ('Y',         'Yes',              'A'),
       ('N',         'No',               'A')

exec pr_LookUps_Setup @LookUpCategory, @YesNo,  @LookUpCategoryDesc = 'Yes / No';

Go
