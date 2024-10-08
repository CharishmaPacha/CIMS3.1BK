/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/22  AY      Added status of M for Loading (HA-1710)
  2012/08/17  AY      Added new status 'A' for 'Staging'
  2012/06/18  TD      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* PALLET Statuses */
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
