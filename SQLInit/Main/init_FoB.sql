/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/23  KBB      Initial revision.(HA-986)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* FoB */
/*------------------------------------------------------------------------------*/
declare @LookUPs TLookUpsTable, @LookUpCategory TCategory = 'FoB';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @LookUPs
       (LookUpCode,   LookUpDescription,   Status)
values ('ShipFrom',   'Ship From',         'A'),
       ('ShipTo',     'Ship To',           'A')

exec pr_LookUps_Setup @LookUpCategory, @LookUPs;

Go
