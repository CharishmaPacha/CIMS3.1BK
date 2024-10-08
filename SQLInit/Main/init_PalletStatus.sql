/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/02/23  MS      Added InTransit & Receiving Statuses (JL-124)
  2018/05/16  AY      Activated Staged status (S2G-812)
  2012/09/27  VM      Built status activated.
  2012/05/03  AY      Added Received status.
  2012/02/22  PKS     Status 'Built' was added.
  2011/07/28  AK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* PALLET Statuses */
/*------------------------------------------------------------------------------*/
declare @PalletStatuses TStatusesTable, @Entity TEntity = 'Pallet';

insert into @PalletStatuses
       (StatusCode,  StatusDescription,  Status)
values ('E',         'Empty',            'A'),
       ('B',         'Built',            'A'),
       ('T',         'InTransit',        'A'),
       ('J',         'Receiving',        'A'),
       ('R',         'Received',         'A'),
       ('P',         'Putaway',          'A'),
       ('A',         'Allocated',        'A'),
       ('C',         'Picking',          'A'),
       ('K',         'Picked',           'A'),
       ('G',         'Packing',          'A'),
       ('D',         'Packed',           'A'),
       ('SG',        'Staged',           'A'),
       ('I',         'Invoiced',         'I'),
       ('L',         'Loaded',           'A'),
       ('S',         'Shipped',          'A'),
       ('V',         'Voided',           'A'),
       ('O',         'Lost',             'A'),
       ('H',         'Short Picked',     'I')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @PalletStatuses;

Go
