/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/13  SV      Activated the Returns type (OB2-1794)
  2021/03/11  SV      Added Returns receipt type (OB2-1358)
  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2014/04/16  TK      Changes made to control data using procedure
  2013/08/01  AY      Added Transfer Order T
  2011/02/08  PK      Added Purchase Order P, and added M(Manufacturing).
  2010/10/06  PK      Initial Revision.
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
