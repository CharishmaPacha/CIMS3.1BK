/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/12/08  GAG     File consolidation changes (CIMSV3-2471)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
 /* Countries Of Origin */
/*------------------------------------------------------------------------------*/
declare @CoO TLookUpsTable, @LookUpCategory TCategory = 'CoO';

insert into @CoO
       (LookUpCode,  LookUpDescription,  Status)
values ('US',        'United States',    'A'),
       ('AF',        'Afghanistan',      'A'),
       ('CN',        'China',            'A'),
       ('ID',        'Indonesia',        'A'),
       ('LK',        'Sri Lanka',        'A'),
       ('IN',        'India',            'A'),
       ('BG',        'Bangladesh',       'A'),
       ('CH',        'China',            'A'),
       ('EG',        'Egypt',            'A'),
       ('HT',        'Haiti',            'A'),
       ('MG',        'Madagascar',       'A'),
       ('USA',       'United States',    'A'),
       ('VN',        'Vietnam',          'A')

exec pr_LookUps_Setup @LookUpCategory, @CoO, @LookUpCategoryDesc = 'Country of Origin';

Go

/*------------------------------------------------------------------------------*/
/* Inventory Statuses */
/*------------------------------------------------------------------------------*/
declare @InventoryStatuses TStatusesTable, @Entity TEntity = 'Inventory';

insert into @InventoryStatuses
       (StatusCode,  StatusDescription,  Status)
values ('N',         'Normal Stock',     'A'),
       ('Q',         'QC Hold',          'A'),
       ('P',         'In Production',    'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @InventoryStatuses;

Go

/*------------------------------------------------------------------------------
 InventoryClass1
 -----------------------------------------------------------------------------*/
declare @InventoryClasses TLookUpsTable, @LookUpCategory TCategory = 'InventoryClass1';

insert into @InventoryClasses
       (LookUpCode,  LookUpDescription,  Status)
values ('',          'None',             'A')

exec pr_LookUps_Setup @LookUpCategory, @InventoryClasses, @LookUpCategoryDesc = 'Inventory Class1';

Go

/*------------------------------------------------------------------------------
 InventoryClass2
 -----------------------------------------------------------------------------*/
declare @InventoryClasses TLookUpsTable, @LookUpCategory TCategory = 'InventoryClass2';

insert into @InventoryClasses
       (LookUpCode,  LookUpDescription,  Status)
values ('',          '',                 'A')

exec pr_LookUps_Setup @LookUpCategory, @InventoryClasses, @LookUpCategoryDesc = 'Inventory Class2';

Go

/*------------------------------------------------------------------------------
 InventoryClass3
 -----------------------------------------------------------------------------*/
declare @InventoryClasses TLookUpsTable, @LookUpCategory TCategory = 'InventoryClass3';

insert into @InventoryClasses
       (LookUpCode,  LookUpDescription,   Status)
values ('',          '',                  'A')

exec pr_LookUps_Setup @LookUpCategory, @InventoryClasses, @LookUpCategoryDesc = 'Inventory Class3';

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

/*------------------------------------------------------------------------------
  Receiving UoMs
 -----------------------------------------------------------------------------*/
declare @UoMs TLookUpsTable, @LookUpCategory TCategory = 'ReceivingUoM';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @UoMs
       (LookUpCode,   LookUpDescription,            Status)
values ('CS',         'Cases',                      'A'),
       ('PP',         'Prepack',                    'I'),
       ('EA',         'Eaches',                     'A')

exec pr_LookUps_Setup @LookUpCategory, @UoMs;

Go

/*------------------------------------------------------------------------------
  Generic UoMs
 -----------------------------------------------------------------------------*/
declare @UoMs TLookUpsTable, @LookUpCategory TCategory = 'UoM';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @UoMs
       (LookUpCode,   LookUpDescription,            Status)
values ('CS',         'Cases',                      'A'),
       ('PP',         'Prepack',                    'A'),
       ('EA',         'Eaches',                     'A')

exec pr_LookUps_Setup @LookUpCategory, @UoMs;

Go
