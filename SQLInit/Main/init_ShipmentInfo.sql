/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/10/18  GAG     Initial revision (CIMSV3-1622)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Shipment Types */
/*------------------------------------------------------------------------------*/
declare @ShipmentTypes TEntityTypesTable, @Entity TEntity = 'Shipment';

insert into @ShipmentTypes
       (TypeCode,  TypeDescription,  Status)
values ('C',       'Customer',       'A'),
       ('T',       'Transfer',       'A')

exec pr_EntityTypes_Setup @Entity, @ShipmentTypes;

Go

/*------------------------------------------------------------------------------*/
/* Shipment Statuses */
/*------------------------------------------------------------------------------*/
declare @ShipmentStatuses TStatusesTable, @Entity TEntity = 'Shipment';

insert into @ShipmentStatuses
       (StatusCode,  StatusDescription,  Status)
values ('N',         'New',              'A'),
       ('I',         'Initial',          'A'),
       ('C',         'Picking',          'A'),
       ('P',         'Picked',           'A'),
       ('A',         'Staging',          'A'),
       ('G',         'Staged',           'A'),
       ('M',         'Loading',          'A'),
       ('L',         'Loaded',           'A'),
       ('S',         'Shipped',          'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @ShipmentStatuses;

Go
