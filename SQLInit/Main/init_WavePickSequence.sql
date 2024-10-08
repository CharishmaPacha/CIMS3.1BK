/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2019/01/24  RIA     Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  PickSequence
 -----------------------------------------------------------------------------*/
declare @PickSequence TLookUpsTable, @LookUpCategory TCategory = 'WavePickSequence';

insert into @PickSequence
       (LookUpCode,  LookUpDescription,                  Status)
values ('Optimal',   'Optimal, in pickpath order',       'A'),
       ('Order',     'Pick by Order, pickpath',          'I'),
       ('Style',     'Pick by Order, Style',             'I')

exec pr_LookUps_Setup @LookUpCategory, @PickSequence, @LookUpCategoryDesc = 'Pick Sequence';

Go
