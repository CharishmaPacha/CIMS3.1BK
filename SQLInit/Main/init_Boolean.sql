/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/30  TK      Initial revision (HA-69)
------------------------------------------------------------------------------*/
/*--------Need to add this LookUpCategory into Init_LookUps.sql file----------*/

Go

/*------------------------------------------------------------------------------
  YesNo
 -----------------------------------------------------------------------------*/
declare @TrueFalse TLookUpsTable, @LookUpCategory TCategory = 'Boolean';

insert into @TrueFalse
       (LookUpCode,  LookUpDescription,  Status)
values ('1',         'True',             'A'),
       ('0',         'False',            'A')

exec pr_LookUps_Setup @LookUpCategory, @TrueFalse;

Go
