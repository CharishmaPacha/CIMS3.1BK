/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/20  NB      Initial Revision(CIMSV3-151)
------------------------------------------------------------------------------*/
/*--------NO Need to add this LookUpCategory into Init_LookUps.sql file----------*/

Go

/*------------------------------------------------------------------------------*/
 /* Packing Mode */
/*------------------------------------------------------------------------------*/
declare @PackingModes TLookUpsTable, @LookUpCategory TCategory = 'PackingMode';

insert into @PackingModes
       (LookUpCode,       LookUpDescription,      Status)
values ('SCANEACH',       'Scan and Pack',        'A'),
       ('SCANANDCOUNT',   'Scan, Count and Pack', 'A'),
       ('COUNTANDSCAN',   'Count, Scan and Pack', 'I')

exec pr_LookUps_Setup @LookUpCategory, @PackingModes, @LookUpCategoryDesc = 'Packing Mode';

Go
