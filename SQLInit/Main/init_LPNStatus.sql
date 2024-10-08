/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/07/04  AY      Activated Staged status
  2012/06/18  PK      Added Picking Status
  2012/06/04  PK      Modified the Status as New from Empty/New, And Activated New Temp Status.
  2012/05/07  YA      Voided status activated
  2011/09/23  TD      Modified Invoice => InActive and activated as well (used in pr_LPN_Delete)
  2011/07/29  AK      Made Packing status active and Packed status added regarding
                       Packing & Shipping Module
  2010/12/21  VM      Included SortSeq and rearranged the list.
  2010/12/06  VK      Added a StatusCode 'N' by deleting the StatusCode 'C' and
                       changed the StatusCode of StatusDescription 'Consumed' to
                       'C'.And Changed the some Status to 'I'.
  2010/10/12  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* LPN Statuses */
/*------------------------------------------------------------------------------*/
declare @LPNStatuses TStatusesTable, @Entity TEntity = 'LPN';

insert into @LPNStatuses
       (StatusCode,  StatusDescription,  Status)
values ('N',         'New',              'A'),
       ('T',         'In Transit',       'A'),
       ('J',         'Receiving',        'I'),
       ('R',         'Received',         'A'),
       ('Z',         'Palletized',       'I'),
       ('P',         'Putaway',          'A'),
       ('C',         'Consumed',         'A'),
       ('V',         'Voided',           'A'),
       ('O',         'Lost',             'A'),
       ('A',         'Allocated',        'A'),
       ('F',         'New Temp',         'A'),
       ('U',         'Picking',          'A'),
       ('K',         'Picked',           'A'),
       ('G',         'Packing',          'A'),
       ('D',         'Packed',           'A'),
       ('H',         'Short Picked',     'I'),
       ('E',         'Staged',           'A'),
       ('L',         'Loaded',           'A')

insert into @LPNStatuses
       (StatusCode,  StatusDescription,  Status,  SortSeq)
values ('I',         'Inactive',         'A',     90),
       ('S',         'Shipped',          'A',     99)

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @LPNStatuses;

Go
