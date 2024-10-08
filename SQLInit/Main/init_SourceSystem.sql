/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2018/03/14  DK      Initial revision (FB-1111)
------------------------------------------------------------------------------*/

Go

declare @SourceSystems TLookUpsTable, @LookUpCategory TCategory = 'SourceSystem';

insert into @SourceSystems
       (LookUpCode,   LookUpDescription,      Status)
values ('HOST',       'Host',                 'A');

exec pr_LookUps_Setup @LookUpCategory, @SourceSystems, @LookUpCategoryDesc = 'SourceSystems';

Go
