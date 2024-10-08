/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/07/30  PK      Added LI - Loading In-progress, SI - Shipping In-progress
                        status codes (S2G-1064)
  2012/06/18  TD      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Load Statuses */
/*------------------------------------------------------------------------------*/
declare @LoadStatuses TStatusesTable, @Entity TEntity = 'Load';

insert into @LoadStatuses
       (StatusCode,  StatusDescription,        Status)
values ('N',         'New',                    'A'),
       ('I',         'In progress',            'A'),
       ('R',         'Ready to load',          'A'),
       ('M',         'Loading',                'A'),
       ('LI',        'Loading In-progress',    'A'),
       ('L',         'Ready to ship',          'A'),
       ('SI',        'Shipping In-progress',   'A'),
       ('S',         'Shipped',                'A'),
       ('X',         'Cancelled',              'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @LoadStatuses;

Go
