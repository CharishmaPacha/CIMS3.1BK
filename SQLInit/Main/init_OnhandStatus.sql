/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/16  MS      Changes taken from Base (HA-974)
  2018/01/24  TK      Added Pending Reservation (S2G-152)
  2014/06/12  TD      Added D, DR.
  2010/12/06  VK      Corrected with actual statuses.
  2010/10/12  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* LPN Onhand Statuses                                                        */
/*  The OnHand Status of an LPN determines if the LPN or LPN Detail would be
    considered as OnHand Inventory or not. The various statuses in use and their
    usage are as below

    A - Available   - This means that the inventory (LPN/LPNDetail) is available
                      to sell or allocate against Orders
    R - Reserved    - This means that the inventory is reserved for an outbound
                      order and hence is not allocable, but for all intents and
                      purpose of accounting is still considered as 'OnHand'
                      inventory.
    U - Unavailable - This means that the inventory is not considered as
                      'OnHand' by accounting standards. This is typically used
                      when the LPN is Lost, Voided, Consumed or Shipped (these
                      are not all inclusive statuses, just a few examples!)
                                                                              */
/*----------------------------------------------------------------------------*/
declare @OnhandStatuses TStatusesTable, @Entity TEntity = 'Onhand';

insert into @OnhandStatuses
       (StatusCode,  StatusDescription,      Status)
values ('A',         'Available',            'A'),
       ('R',         'Reserved',             'A'),
       ('U',         'Unavailable',          'A'),
       ('D',         'Directed',             'A'),
       ('DR',        'Directed Reserved',    'I'),
       ('PR',        'Pending Reservation',  'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @OnhandStatuses;

Go
