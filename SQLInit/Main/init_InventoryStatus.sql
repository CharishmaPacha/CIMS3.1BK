/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2010/10/28  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Inventory Statuses */
/*------------------------------------------------------------------------------*/
declare @InventoryStatuses TStatusesTable, @Entity TEntity = 'Inventory';

insert into @InventoryStatuses
       (StatusCode,  StatusDescription,  Status)
values ('N',         'Normal Stock',     'A'),
       ('Q',         'QC Hold',          'A'),
       ('P',         'In Production',    'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @InventoryStatuses;

Go
