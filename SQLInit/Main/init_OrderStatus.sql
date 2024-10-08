/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/08  AY      Revised to update status H to Pack & Hold
  2017/07/17  VS      Added 'TC' Tobeconsolidate Order status (CID-Golive issue)
  2013/09/16  PK      Added Inprogress 'I' status and changed the StatusCode for New to 'N'
  2012/08/23  VM      Activated Allocated Status
  2012/07/04  AY      Activated Staged Status
  2012/05/24  PK      Added Hold Status
  2011/12/28  AA      Added SortSeq column and values for charts to display legend in custom order
  2011/11/02  AY      Initial -> New, inactivated cancel in progress.
  2011/08/11  AY      Customized for Loehmanns
  2010/10/12  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Order Status */
/*------------------------------------------------------------------------------*/
declare @OrderStatuses TStatusesTable, @Entity TEntity = 'Order';

insert into @OrderStatuses
       (StatusCode,  StatusDescription,   Status)
values ('N',         'New',               'A'),
       ('I',         'In Progress',       'I'),
       ('W',         'Waved',             'A'),
       ('A',         'Allocated',         'A'),
       ('C',         'Picking',           'A'),
       ('P',         'Picked',            'A'),
       ('K',         'Packed',            'A'),
       ('R',         'Ready To Ship',     'A'),
       ('G',         'Staged',            'A'),
       ('L',         'Loaded',            'A'),
       ('TC',        'To Consolidate',    'I'),
       ('V',         'Invoiced',          'I'),
       ('O',         'Downloaded',        'A')

insert into @OrderStatuses
       (StatusCode,  StatusDescription,  Status,  SortSeq)
values ('S',         'Shipped',          'A',     90),
       ('D',         'Completed',        'A',     91),
       ('E',         'Cancel in Progress',
                                         'I',     92),
       ('X',         'Canceled',         'A',     93),
       ('H',         'Pack & Hold',      'A',     94)

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @OrderStatuses;

Go
