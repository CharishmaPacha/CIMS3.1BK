/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/12/07  GAG     File consolidation changes (CIMSV3-2479)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Receipt Type */
/*------------------------------------------------------------------------------*/
declare @ReceiptTypes TEntityTypesTable, @Entity TEntity = 'Receipt';

insert into @ReceiptTypes
       (TypeCode,  TypeDescription,   Status)
values ('PO',      'Purchase Order',  'A'),
       ('P',       'Purchase Order',  'I'),
       ('R',       'Return',          'A'),
       ('A',       'ASN',             'A'),
       ('M',       'Manf. Work Order','A'),
       ('T',       'Transfer',        'I'),
       ('RMA',     'RMA',             'I')

exec pr_EntityTypes_Setup @Entity, @ReceiptTypes;

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
