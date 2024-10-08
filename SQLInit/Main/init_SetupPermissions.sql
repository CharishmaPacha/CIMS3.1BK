/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/21  AY      Revised descriptons (CIMSV3-1221)
  2020/04/03  TK      Initial revision (HA-69)
------------------------------------------------------------------------------*/
/*--------Need to add this LookUpCategory into Init_LookUps.sql file----------*/

Go

/*------------------------------------------------------------------------------
  Grant/Remove permissions options
 -----------------------------------------------------------------------------*/
declare @LookUps TLookUpsTable, @LookUpCategory TCategory = 'SetupPermissions';

insert into @LookUps
       (LookUpCode,  LookUpDescription,             Status)
values ('P',         'Operation only',             'A'),
       ('PC',        'Operation & children',       'A')

exec pr_LookUps_Setup @LookUpCategory, @LookUps;

Go
