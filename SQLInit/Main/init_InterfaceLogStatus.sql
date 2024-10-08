/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/07/03  NY      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* InterfaceLog Statuses */
/*------------------------------------------------------------------------------*/
declare @InterfaceLogStatuses TStatusesTable, @Entity TEntity = 'InterfaceLog';

insert into @InterfaceLogStatuses
       (StatusCode,  StatusDescription,  Status)
values ('S',         'Succeeded',        'A'),
       ('F',         'Failed',           'A'),
       ('P',         'Processing',       'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @InterfaceLogStatuses;

Go
