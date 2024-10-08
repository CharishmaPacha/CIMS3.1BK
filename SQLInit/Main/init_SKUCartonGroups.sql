/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2018/09/25  KSK      Initial revision (HPI-2044)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Carton Groups
 -----------------------------------------------------------------------------*/
declare @CartonGroup TLookUpsTable, @LookUpCategory TCategory = 'CartonGroups';

insert into @CartonGroup
       (LookUpCode,  LookUpDescription,           Status)
values ('B',        'All Boxes',                 'A'),
       ('P',        'Padded Bag',                'A'),
       ('L',        'Large Boxes',               'A')

exec pr_LookUps_Setup @LookUpCategory, @CartonGroup, @LookUpCategoryDesc = 'Carton Groups';

Go
