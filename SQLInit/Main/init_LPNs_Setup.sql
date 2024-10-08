/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/24  MS      Initial revision (HA-2410)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  RegenerateTrackingNo
 -----------------------------------------------------------------------------*/
declare @RegenerateTrackingNoOptions TLookUpsTable, @LookUpCategory TCategory = 'RegenerateTrackingNoOptions';

insert into @RegenerateTrackingNoOptions
       (LookUpCode,  LookUpDescription,                   Status)
values ('M',         'Generate For Missing Tracking Nos', 'A'),
       ('A',         'Generate For All Selected Cartons', 'I')

exec pr_LookUps_Setup @LookUpCategory, @RegenerateTrackingNoOptions, @LookUpCategoryDesc = 'Regenerate TrackingNo';

Go
