/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2014/04/16  TK      Changes made to control data using procedure
  2011/08/31  NB      Initial Revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* ShipLabel Types */
/*------------------------------------------------------------------------------*/
declare @ShipLabelTypes TEntityTypesTable, @Entity TEntity = 'ShipLabel';

insert into @ShipLabelTypes
       (TypeCode,  TypeDescription,   Status)
values ('S',       'Shipping Label',  'A'),
       ('C',       'Contents Label',  'A'),
       ('U',       'UCC Label',       'A')

exec pr_EntityTypes_Setup @Entity, @ShipLabelTypes;

Go
