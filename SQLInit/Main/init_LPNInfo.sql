/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/11/28  VM      File consolidation changes (CIMSV3-2478)
  2021/09/14  VM      Initial revision (FBV3-264)
  2021/03/24  MS      Initial revision (HA-2410)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* LPN Type  */
/*------------------------------------------------------------------------------*/
declare @LPNTypes TEntityTypesTable, @Entity TEntity = 'LPN';

insert into @LPNTypes
       (TypeCode,   TypeDescription,       Status)
values ('C',        'Carton',              'A'),
       ('F',        'Flat',                'I'),
       ('H',        'Hanging',             'I'),
       ('L',        'Picklane',            'A'),
       ('A',        'Cart',                'A'),
       ('S',        'Ship Carton',         'A'),
       ('TO',       'Tote',                'A'),
       ('T',        'Temp Carton',         'I')

exec pr_EntityTypes_Setup @Entity, @LPNTypes;

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

/*------------------------------------------------------------------------------
  LPN Format
 -----------------------------------------------------------------------------*/
declare @LPNFormats TLookUpsTable, @LookUpCategory TCategory = 'LPNFormat';

insert into @LPNFormats
       (LookUpCode,  LookUpDescription,                  Status)
values ('LPNF1',     '<LPNType><BusinessUnit><SeqNo>',   'I'),
       ('LPNF2',     '<LPNType><SeqNo>',                 'A'),
       ('LPNF3',     '<Owner><SeqNo>',                   'I'),
       ('LPNF4',     'T<SeqNo>',                         'A')

exec pr_LookUps_Setup @LookUpCategory, @LPNFormats, @LookUpCategoryDesc = 'LPN Format';

Go

/*------------------------------------------------------------------------------
 LPNTypes for Generate Pallet
 -----------------------------------------------------------------------------*/
declare @LPNLookUps TLookUpsTable, @LookUpCategory TCategory = 'LPNTypeForCart';

insert into @LPNLookUps
       (LookUpCode, LookUpDescription,     Status)
values ('A',        'Cart',                'A')

exec pr_LookUps_Setup @LookUpCategory, @LPNLookUps, @LookUpCategoryDesc = 'LPN Type for Cart';

Go

/*------------------------------------------------------------------------------*/
/* LPN Type for Create Inventory */
/*------------------------------------------------------------------------------*/
declare @LPNTypes TEntityTypesTable, @Entity TEntity = 'LPNTypeForCreateInventory';

insert into @LPNTypes
       (TypeCode,   TypeDescription,       Status)
values ('C',        'Carton',              'A'),
       ('T',        'Temp Carton',         'I')

exec pr_EntityTypes_Setup @Entity, @LPNTypes;

Go

/*------------------------------------------------------------------------------
 LPNTypes for Generate LPNs
 -----------------------------------------------------------------------------*/
declare @LPNLookUps TLookUpsTable, @LookUpCategory TCategory = 'LPNTypeForGenerate';

insert into @LPNLookUps
       (LookUpCode, LookUpDescription,     Status)
values ('C',        'Carton',              'A'),
       ('TO',       'Tote',                'A'),
       ('S',        'Ship Carton',         'A')

exec pr_LookUps_Setup @LookUpCategory, @LPNLookUps, @LookUpCategoryDesc = 'LPN Type for Generate';

Go

/*------------------------------------------------------------------------------
 LPNTypes for Modify
 -----------------------------------------------------------------------------*/
declare @LPNLookUps TLookUpsTable, @LookUpCategory TCategory = 'LPNTypeForModify';

insert into @LPNLookUps
       (LookUpCode, LookUpDescription,     Status)
values ('C',        'Carton',              'A'),
       ('TO',       'Tote',                'A'),
       ('A',        'Cart',                'A')

exec pr_LookUps_Setup @LookUpCategory, @LPNLookUps, @LookUpCategoryDesc = 'LPN Type for Modify';

Go

/*------------------------------------------------------------------------------
  Pallet LPN Format
 -----------------------------------------------------------------------------*/
declare @LPNFormats TLookUpsTable, @LookUpCategory TCategory = 'PalletLPNFormat';

insert into @LPNFormats
       (LookUpCode,  LookUpDescription,                  Status)
values ('PLPNF1',    '<PalletNo>-<CharSeq>',             'A'),
       ('PLPNF2',    '<PalletNo>-<SeqNo>',               'A')

exec pr_LookUps_Setup @LookUpCategory, @LPNFormats, @LookUpCategoryDesc = 'Pallet LPN Format';

Go

/*------------------------------------------------------------------------------
  RegenerateTrackingNo
 -----------------------------------------------------------------------------*/
declare @RegenerateTrackingNoOptions TLookUpsTable, @LookUpCategory TCategory = 'RegenerateTrackingNoOptions';

insert into @RegenerateTrackingNoOptions
       (LookUpCode,  LookUpDescription,                   Status)
values ('M',         'Generate For Missing Tracking Nos', 'A'),
       ('A',         'Generate For All Selected Cartons', 'I')

exec pr_LookUps_Setup @LookUpCategory, @RegenerateTrackingNoOptions, @LookUpCategoryDesc = 'Regenerate TrackingNo';

Go
