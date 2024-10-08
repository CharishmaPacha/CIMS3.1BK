/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/19  SV      Added Returns Receiving (OB2-1358)
  2021/02/01  SK      New Transaction Type EDI753 (HA-1896)
  2020/12/06  MS      Corrections as per New Standards (CIMSV3-1273)
  2015/09/30  OK      Added return (FB-388)
  2015/09/14  YJ      Added RecvRet Type (FB-381)
  2014/07/i8  NY      Added WHxfer Type.
  2014/05/28  PK      Activated Pick transaction type
  2014/04/16  TK      Changes made to control data using procedure
  2130/10/09  TD      Added PTCancel.
  2013/09/02  PK      Added ROOpen, ROClose.
  2013/08/01  AY      Added SKU, UPC change types
  2011/10/20  AY      Loehmanns doesn't need Xfer records
  2011/10/06  AY      Added Xfer
  2011/10/05  VM      Added 'PhotoIn' and 'PhotoOut'
  2011/04/05  VM      Added "Picked"
  2011/02/09  PK      Added BusinessUnit field in EntityType table
  2011/01/21  VM      'Inv' => 'InvCh'
  2010/12/08  VK      Initial Revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Transaction Type */
/*------------------------------------------------------------------------------*/
declare @TransactionTypes TEntityTypesTable, @Entity TEntity = 'Transaction';

insert into @TransactionTypes
       (TypeCode,   TypeDescription,         Status)
values ('Recv',     'Receipts',              'A'),
       ('Return',   'Returns',               'A'),
       ('RMA',      'Returns Receiving',     'A'),
       ('InvCh',    'Inventory Changes',     'A'),
       ('Res',      'Reservation',           'I'),
       ('UnRes',    'UnReservation',         'I'),
       ('Pick',     'Picked',                'I'),
       ('Ship',     'Shipped',               'A'),
       ('PhotoIn',  'Photo In',              'I'),
       ('PhotoOut', 'Photo Out',             'I'),
       ('Xfer',     'Transfers',             'I'),
       ('SKUCh',    'SKU Change',            'I'),
       ('UPC+',     'UPC Added',             'I'),
       ('UPC-',     'UPC Removed',           'I'),
       ('ROOpen',   'RO Reopen',             'A'),
       ('ROClose',  'RO Close',              'A'),
       ('PTCancel', 'PT Cancel',             'A'),
       ('PTStatus', 'PT Status',             'A'),
       ('WHXfer',   'WH Change',             'A'),
       ('EDI753',   'EDI 753',               'A')

exec pr_EntityTypes_Setup @Entity, @TransactionTypes;

Go
