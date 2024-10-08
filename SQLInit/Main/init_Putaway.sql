/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2014/04/16  TK      Changes made to control data using procedure
  2013/09/10  NY      Initial Revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Putaway Type  */
/*------------------------------------------------------------------------------*/
declare @PutawayTypes TEntityTypesTable, @Entity TEntity = 'Putaway';

insert into @PutawayTypes
       (TypeCode,  TypeDescription,  Status)
values ('L',       'LPNs',           'A'),
       ('P',       'Pallets',        'A'),
       ('LP',      'LPNs on Pallets','A'),
       ('LD',      'LPN Details',    'A')

exec pr_EntityTypes_Setup @Entity, @PutawayTypes;

Go
