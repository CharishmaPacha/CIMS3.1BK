/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2014/04/16  TK      Changes made to control data using procedure
  2010/09/20  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Upload Processed Flags
 -----------------------------------------------------------------------------*/
declare @Export TLookUpsTable, @LookUpCategory TCategory = 'ProcessedFlag';

insert into @Export
       (LookUpCode,  LookUpDescription,    Status)
values ('Y',         'Processed',          'A'),
       ('N',         'Not yet Processed',  'A'),
       ('I',         'Ignored',            'A'),
       ('H',         'On Hold',            'A'),
       ('X',         'Cancelled',          'A')

exec pr_LookUps_Setup @LookUpCategory, @Export, @LookUpCategoryDesc = 'Export Processed Flag';

Go
