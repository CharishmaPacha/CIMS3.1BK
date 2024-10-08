/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/04/05  AY      Added new code X for canceled.
  2010/12/06  VK      Added a new StatusCode 'E' with StatusDescription 'Received'.
  2010/10/12  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Receipt Statuses */
/*------------------------------------------------------------------------------*/
declare @ReceiptStatuses TStatusesTable, @Entity TEntity = 'Receipt';

insert into @ReceiptStatuses
       (StatusCode,  StatusDescription,  Status)
values ('I',         'Initial',          'A'),
       ('T',         'In Transit',       'A'),
       ('R',         'In Progress',      'A'),
       ('E',         'Received',         'A'),
       ('C',         'Closed',           'A'),
       ('X',         'Canceled',         'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @ReceiptStatuses;

Go
