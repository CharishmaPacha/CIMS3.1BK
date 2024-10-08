/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/01/09  TK      Changed to use set up procedure
  2015/09/30  TK/AY   Added ReceivingUoM
  2014/11/28  DK      Added Prepack.
  2013/09/07  PK      Updated Sort Seq.
  2013/09/06  PK      Initial revision.
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
  Generic UoMs
 -----------------------------------------------------------------------------*/
declare @UoMs TLookUpsTable, @LookUpCategory TCategory = 'UoM';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @UoMs
       (LookUpCode,   LookUpDescription,            Status)
values ('CS',         'Cases',                      'A'),
       ('PP',         'Prepack',                    'A'),
       ('EA',         'Eaches',                     'A')

exec pr_LookUps_Setup @LookUpCategory, @UoMs;

Go

/*------------------------------------------------------------------------------
  Receiving UoMs
 -----------------------------------------------------------------------------*/
declare @UoMs TLookUpsTable, @LookUpCategory TCategory = 'ReceivingUoM';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @UoMs
       (LookUpCode,   LookUpDescription,            Status)
values ('CS',         'Cases',                      'A'),
       ('PP',         'Prepack',                    'I'),
       ('EA',         'Eaches',                     'A')

exec pr_LookUps_Setup @LookUpCategory, @UoMs;

Go
