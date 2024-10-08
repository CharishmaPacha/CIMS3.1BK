/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/09  NB      Initial Revision(CIMSV3-103)
------------------------------------------------------------------------------*/
/*--------Need to add this LookUpCategory into Init_LookUps.sql file----------*/

Go

/*------------------------------------------------------------------------------*/
 /* Document Class */
/*------------------------------------------------------------------------------*/
declare @DocumentClassLookUps TLookUpsTable, @LookUpCategory TCategory = 'UserFilterGroups';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @DocumentClassLookUps
       (LookUpCode,  LookUpDescription,      Status)
values ('Warehouse', 'Allowed Warehouses',   'A'   )

exec pr_LookUps_Setup @LookUpCategory, @DocumentClassLookUps;

Go
