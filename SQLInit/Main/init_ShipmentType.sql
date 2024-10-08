/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2014/04/16  TK      Changes made to control data using procedure
  2012/07/05  NB      Initial Revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* ShipLabel Types */
/*------------------------------------------------------------------------------*/
declare @ShipmentTypes TEntityTypesTable, @Entity TEntity = 'Shipment';

insert into @ShipmentTypes
       (TypeCode,  TypeDescription,  Status)
values ('C',       'Customer',       'A'),
       ('T',       'Transfer',       'A')

exec pr_EntityTypes_Setup @Entity, @ShipmentTypes;

Go
