/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/09/23  NB      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Print Label Request Status */
/*------------------------------------------------------------------------------*/
declare @Statuses TStatusesTable, @Entity TEntity = 'PrintServiceRequest';

insert into @Statuses
       (StatusCode,  StatusDescription,  Status)
values ('S',         'Scheduled',        'A'),
       ('P',         'Printing',         'A'),
       ('C',         'Completed',        'A'),
       ('E',         'Error',            'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @Statuses;

Go
