/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/03/09  AY      Added N/A status
  2015/11/03  SV      Added Deleted status
  2010/12/10  VM      Modified 'In Use' StatusCode.
  2010/12/06  VK      Added a new StatusDescription 'In Use' by deleting the
                       previous StatusDescription 'Available' and changed some
                       Status to 'I'.
  2010/11/30  VM      Added Active, InActive statuses and some corrections to file.
  2010/09/20  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Location Status */
/*------------------------------------------------------------------------------*/
declare @LocationStatuses TStatusesTable, @Entity TEntity = 'Location';

insert into @LocationStatuses
       (StatusCode,  StatusDescription,  Status)
values ('I',         'Inactive',         'A'),
       ('E',         'Empty',            'A'),
       ('U',         'Available',        'A'),
       ('R',         'Reserved',         'A'),
       ('D',         'Deleted',          'A'),
       ('F',         'Full',             'I'),
       ('N',         'N/A',              'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @LocationStatuses;

Go
