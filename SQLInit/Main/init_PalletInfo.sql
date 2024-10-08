/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/11/28  GAG     File consolidation changes (CIMSV3-2470)
  2022/10/18  GAG     Initial revision (CIMSV3-1622)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Cart Types
------------------------------------------------------------------------------*/
declare @WaveTypes TEntityTypesTable, @Entity TEntity = 'CartType';

insert into @WaveTypes
       (TypeCode,  TypeDescription,            Status)
values ('C1',      '8 Shelf Cart - 72" wide',  'A'),
       ('C2',      '6 Shelf Cart - 54" wide',  'A')

exec pr_EntityTypes_Setup @Entity, @WaveTypes;

Go

/*------------------------------------------------------------------------------*/
/* Cart Types to Generate */
/*------------------------------------------------------------------------------*/
declare @PalletTypes TEntityTypesTable, @Entity TEntity = 'CartTypeGen';

insert into @PalletTypes
       (TypeCode,  TypeDescription,         Status)
values ('C',       'Picking Cart',          'A')

exec pr_EntityTypes_Setup @Entity, @PalletTypes;

Go

/*------------------------------------------------------------------------------
  Generate Pallet Options
 -----------------------------------------------------------------------------*/
declare @GeneratePalletOptions TLookUpsTable, @LookUpCategory TCategory = 'GeneratePalletOptions';

insert into @GeneratePalletOptions
       (LookUpCode,  LookUpDescription,       Status)
values ('I',         'Ignore',                'A'),
       ('N',         'Scan or Enter Pallet',  'A'),
       ('Y',         'Generate New Pallet',   'A')

exec pr_LookUps_Setup @LookUpCategory, @GeneratePalletOptions, @LookUpCategoryDesc = 'Generate Pallet Options';

Go

/*------------------------------------------------------------------------------*/
/* PALLET Type */
/*------------------------------------------------------------------------------*/
declare @PalletTypes TEntityTypesTable, @Entity TEntity = 'Pallet';

insert into @PalletTypes
       (TypeCode,  TypeDescription,         Status)
values ('I',       'Inventory',             'A'),
       ('C',       'Picking Cart',          'A'),
       ('T',       'Trolley',               'I'),
       ('H',       'Hanging Returns Cart',  'I'),
       ('F',       'Flat Returns Cart',     'I'),
       ('R',       'Receiving Pallet',      'A'),
       ('P',       'Picking Pallet',        'A'),
       ('S',       'Shipping Pallet',       'A'),
       ('SO',      'SingleOrder',           'I'),
       ('MO',      'MultipleOrders',        'I'),
       ('U',       'Putaway Pallet',        'A')

exec pr_EntityTypes_Setup @Entity, @PalletTypes;

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

/*------------------------------------------------------------------------------
  Cart Formats
 -----------------------------------------------------------------------------*/
declare @PalletFormats TLookUpsTable, @LookUpCategory TCategory = 'PalletFormat_C';

insert into @PalletFormats
       (LookUpCode,  LookUpDescription,  Status)
values ('PFC1',      'C<SeqNo>',         'A'),
       ('PFC2',      'T<SeqNo>',         'A')

exec pr_LookUps_Setup @LookUpCategory, @PalletFormats, @LookUpCategoryDesc = 'Pallet Format for Cart';

Go

/*------------------------------------------------------------------------------
  Pallet Formats
------------------------------------------------------------------------------*/
declare @PalletFormats TLookUpsTable, @LookUpCategory TCategory = 'PalletFormat_I';

insert into @PalletFormats
       (LookUpCode,  LookUpDescription,  Status)
values ('PFI1',       'P<SeqNo>',         'A'),
       ('PFI2',       'PA<SeqNo>',        'A'),
       ('PFI3',       '<SeqNo>',          'A')

exec pr_LookUps_Setup @LookUpCategory, @PalletFormats, @LookUpCategoryDesc =  'Pallet Format for Inventory';

Go

/*------------------------------------------------------------------------------*/
 /* Pallet Size */
/*------------------------------------------------------------------------------*/
declare @PalletSizeLookUps TLookUpsTable, @LookUpCategory TCategory = 'PalletSize';

insert into @PalletSizeLookUps
       (LookUpCode,  LookUpDescription,         Status)
values ('RS',        'Regular Size',            'A'),
       ('OS',        'Oversize' ,               'A')

exec pr_LookUps_Setup @LookUpCategory, @PalletSizeLookUps, @LookUpCategoryDesc = 'Pallet Size';

Go

/*------------------------------------------------------------------------------*/
/* Pallet Types to Generate */
/*------------------------------------------------------------------------------*/
declare @PalletTypes TEntityTypesTable, @Entity TEntity = 'PalletTypeGen';

insert into @PalletTypes
       (TypeCode,  TypeDescription,         Status)
values ('I',       'Inventory',             'A')

exec pr_EntityTypes_Setup @Entity, @PalletTypes;

Go
