/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/20  NB      Initial Revision(CIMSV3-221)
------------------------------------------------------------------------------*/
/*--------Need to add this LookUpCategory into Init_LookUps.sql file----------*/

Go

/*------------------------------------------------------------------------------*/
 /* Document Class */
/*------------------------------------------------------------------------------*/
declare @DocumentClassLookUps TLookUpsTable, @LookUpCategory TCategory = 'DocumentClass';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @DocumentClassLookUps
       (LookUpCode,  LookUpDescription,      Status)
values ('LABEL',     'Label',                'A'),
       ('REPORT',    'Report',               'A')

exec pr_LookUps_Setup @LookUpCategory, @DocumentClassLookUps;

Go
