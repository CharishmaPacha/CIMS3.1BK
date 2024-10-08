/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/09  SK      Initial Revision (HA-2972)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Productivity */
/*------------------------------------------------------------------------------*/

declare @FreightTerms TLookUpsTable, @LookUpCategory TCategory = 'UserProductivitySumBy';

insert into @FreightTerms
       (LookUpCode,  LookUpDescription,       Status)
values ('User',     'By User',                'A'),
       ('Date',     'By Date',                'A'),
       ('UserDate', 'By User & Date',         'A');

exec pr_LookUps_Setup @LookUpCategory, @FreightTerms, @LookUpCategoryDesc = 'User Productivity Sum by';

Go
