/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/07/24  TD      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Order Status */
/*------------------------------------------------------------------------------*/
declare @ProductivityStatuses TStatusesTable, @Entity TEntity = 'Productivity';

insert into @ProductivityStatuses
       (StatusCode,  StatusDescription,  Status)
values ('A',         'Active',           'A'),
       ('I',         'In Progress',      'A'),
       ('C',         'Completed',        'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @ProductivityStatuses;

Go
