/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/03/01  PKS     Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Receiver Status */
/*------------------------------------------------------------------------------*/
declare @ReceiverStatuses TStatusesTable, @Entity TEntity = 'Receiver';

insert into @ReceiverStatuses
       (StatusCode,  StatusDescription,  Status)
values ('O',         'Open',             'A'),
       ('C',         'Closed',           'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @ReceiverStatuses;

Go
