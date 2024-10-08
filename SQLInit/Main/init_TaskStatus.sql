/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/05/31  NB      Moved OnHold status up in the order to the first
  2014/04/07  AY      Added OnHold task
  2011/12/28  PKS     Status Description "Not Yet started" was changed to "Ready to start"
  2011/12/19  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Task Status */
/*------------------------------------------------------------------------------*/
declare @TaskStatuses TStatusesTable, @Entity TEntity = 'Task';

insert into @TaskStatuses
       (StatusCode,  StatusDescription,  Status)
values ('O',         'On hold',          'A'),
       ('N',         'Ready to start',   'A'),
       ('I',         'In Progress',      'A'),
       ('C',         'Completed',        'A')

insert into @TaskStatuses
       (StatusCode,  StatusDescription,  Status,  SortSeq)
values ('X',         'Canceled',         'A',     99)

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @TaskStatuses;

Go
