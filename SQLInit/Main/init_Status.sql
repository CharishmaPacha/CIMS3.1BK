/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/14  AY      Added Serial No status
  2020/03/15  AY      Distinguish between Status & EntityStatus fields
  2013/08/01  TK      Added View Status.
  2011/01/13  VK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Status */
/*------------------------------------------------------------------------------*/
declare @Statuses TStatusesTable, @Entity TEntity = 'Status';

insert into @Statuses
       (StatusCode,  StatusDescription,  Status)
values ('A',         'Active',           'A'),
       ('I',         'Inactive',         'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @Statuses;

/*------------------------------------------------------------------------------*/
/* Entity Status */
/*------------------------------------------------------------------------------*/
select @Entity = 'EntityStatus';
delete from @Statuses;

insert into @Statuses
       (StatusCode,  StatusDescription,  Status)
values ('A',         'Active',           'A'),
       ('I',         'Inactive',         'A'),
       ('V',         'View',             'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @Statuses;

/*------------------------------------------------------------------------------*/
/* Serial No Statuses */
/*------------------------------------------------------------------------------*/
select @Entity = 'SerialNo';
delete from @Statuses;

insert into @Statuses
       (StatusCode,  StatusDescription,  Status)
values ('A',         'Assigned',         'A'),
       ('R',         'Ready to Use',     'A'),
       ('S',         'Shipped',          'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @Statuses;

Go
