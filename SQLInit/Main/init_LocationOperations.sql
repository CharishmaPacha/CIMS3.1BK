 /*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2018/03/28  YJ      set Cycle Count inactive(S2G-327)
  2017/02/10  OK      Initial revision (GNC-1426)
------------------------------------------------------------------------------*/

Go

declare @OnHoldLocOperations TLookUpsTable, @LookUpCategory TCategory = 'LocAllowedOperations';

insert into @OnHoldLocOperations
       (LookUpCode,  LookUpDescription,   Status)
values ('P',         'Putaway',           'A'),
       ('K',         'Picking',           'A'),
       ('R',         'Replenishments',    'A'),
       ('C',         'Cycle Count',       'I'),
       ('N',         'None',              'A')

exec pr_LookUps_Setup @LookUpCategory, @OnHoldLocOperations, @LookUpCategoryDesc = 'Location Operations';

Go
