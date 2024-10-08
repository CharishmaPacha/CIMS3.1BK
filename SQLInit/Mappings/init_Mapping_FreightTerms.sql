/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  This file defines the mapping between cims freight term values to host values.
  There are instances where the FreightTerms in cims system have to be transformed to
  send values understood by the host system.

  Revision History:

  Date        Person  Comments

  2023/01/06  VS      Get the Proper FrightTerms (OBV3-1652)
  2019/07/09  MS      Revisions (CID-734)
  2018/12/05  DA      pr_Mapping_Setup rename as pr_Setup_Mapping (CIMS-2219)
  2018/03/09  RT      Mapping set up for Freight Terms (S2G-319)
  2016/02/15  NB      Initial Revision
------------------------------------------------------------------------------*/

/******************************************************************************/
declare @Mapping       TMapping,
        @SourceSystem  TName      = 'HOST',
        @TargetSystem  TName      = 'CIMS',
        @EntityType    TEntity    = 'FreightTerms',
        @Operation     TOperation = 'replace';

/* Host may use different terminology for Freight Terms and so map the ones from host to CIMS Standard */
insert into @Mapping
       (SourceValue,                   TargetValue)
values ('THIRDPARTY',                  '3RDPARTY'),
       ('PREPAID',                     'SENDER');

Go

/******************************************************************************/
declare @Mapping       TMapping,
        @SourceSystem  TName      = 'CIMS',
        @TargetSystem  TName      = 'FEDEX',
        @EntityType    TEntity    = 'FreightTerms',
        @Operation     TOperation = 'ShippingChargesPayment';

/* Host may use different terminology for Freight Terms and so map the ones from host to CIMS Standard */
insert into @Mapping
       (SourceValue,                   TargetValue)
values ('COLLECT',                     'COLLECT'),
       ('SENDER',                      'SENDER'),
       ('PREPAID',                     'SENDER'),
       ('RECEIVER',                    'RECIPIENT'),
       ('3RDPARTY',                    'THIRD_PARTY'),
       /* Applicable for International */
       ('DDP',                         'SENDER'),
       ('DDU',                         'SENDER');

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go

/******************************************************************************/
declare @Mapping       TMapping,
        @SourceSystem  TName      = 'CIMS',
        @TargetSystem  TName      = 'FEDEX',
        @EntityType    TEntity    = 'FreightTerms',
        @Operation     TOperation = 'DutiesPayment';

/* Host may use different terminology for Freight Terms and so map the ones from host to CIMS Standard */
insert into @Mapping
       (SourceValue,                   TargetValue)
values ('COLLECT',                     'COLLECT'),
       ('SENDER',                      'SENDER'),
       ('PREPAID',                     'SENDER'),
       ('RECEIVER',                    'RECIPIENT'),
       ('3RDPARTY',                    'THIRD_PARTY'),
       /* Applicable for International */
       ('DDP',                         'SENDER'),
       ('DDU',                         'RECIPIENT');

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go

/******************************************************************************/
declare @Mapping       TMapping,
        @SourceSystem  TName      = 'CIMS',
        @TargetSystem  TName      = 'UPS',
        @EntityType    TEntity    = 'FreightTerms',
        @Operation     TOperation = 'ShippingAPI';

/* Host may use different terminology for Freight Terms and so map the ones from host to CIMS Standard */
insert into @Mapping
       (SourceValue,                   TargetValue)
values ('COLLECT',                     'BillReceiver'),
       ('SENDER',                      'BillShipper'),
       ('PREPAID',                     'BillShipper'),
       ('RECEIVER',                    'BillReceiver'),
       ('3RDPARTY',                    'BillThirdParty'),
       ('CONSIGNEE',                   'ConsigneeBilledIndicator');

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go

/* The below is just an example on how ShipVia can be mapped to include Freight Terms as well */
/*
insert into @Mapping
       (SourceValue,                   TargetValue)
values ('AAA COOPER',                  'SENDER'),
       ('ABF',                         'SENDER'),
       ('AIT',                         ''),
       ('ALLTRANS',                    ''),
       ('AMERICAN HWY',                ''),
       ('AVERITT EXPRESS',             'SENDER'),
       ('BESTPARCEL',                  ''),
       ('BESTLTL',                     ''),
       ('BNSF',                        'SENDER'),
       ('CENTRAL',                     'SENDER'),
       ('CENTRAL FRT',                 'SENDER'),
       ('CEVA',                        ''),
       ('CH ROB',                      ''),
       ('CONWAY',                      'SENDER'),
       ('COURIER',                     ''),
       ('CUST P/UP',                   'SENDER'),
       ('DAYLIGHT',                    ''),
       ('DHL EXPRESS',                 ''),
       ('DHL GLOBAL',                  ''),
       ('DUGAN',                       'SENDER'),
       ('EMBROIDERY-PACK',             'SENDER'),
       ('ESTES',                       'SENDER'),
       ('EXXACT EXPRESS',              ''),
       ('FNL',                         ''),
       ('HERCULES',                    ''),
       ('HUB GROUP',                   ''),
       ('ITNL',                        ''),
       ('INTERNATIONAL',               ''),
       ('J.B. HUNT ',                  'SENDER'),
       ('K+N ',                        ''),
       ('KNIGHT ',                     ''),
       ('LDWY ',                       ''),
       ('LYNDEN ',                     ''),
       ('MSLQ ',                       ''),
       ('MULLEN ',                     ''),
       ('OLD DOMINION ',               ''),
       ('ON TIME ',                    ''),
       ('ON TIME - AIR ',              ''),
       ('ON TIME - VSL ',              ''),
       ('OVERNITE ',                   ''),
       ('PACK-EMBROIDERY',             ''),
       ('PAYSTAR',                     ''),
       ('RAI',                         ''),
       ('RNL',                         ''),
       ('ROADRUNNER',                  ''),
       ('ROADWAY',                     'SENDER'),
       ('SADDLE CREEK',                ''),
       ('SAIA LTL',                    ''),
       ('SCHNEIDER INT',               'SENDER'),
       ('SHIP/HOLD- EMB',              ''),
       ('SHOP',                        ''),
       ('SMT',                         ''),
       ('SOUTHEASTERN',                ''),
       ('SPXH',                        ''),
       ('STAMPS',                      ''),
       ('SUNSET PACIFIC',              ''),
       ('SWIFT',                       'SENDER'),
       ('TAZMANIAN',                   ''),
       ('TEX-AIR',                     ''),
       ('TOTAL QUALITY',               ''),
       ('TRANS AMERICA',               ''),
       ('TRANSPLACE',                  'SENDER'),
       ('UPSSCS',                      'SENDER'),
       ('US XPRESS',                   'SENDER'),
       ('VITRAN',                      'SENDER'),
       ('WERNER',                      'SENDER'),
       ('XPO',                         ''),
       ('YELLOW',                      'SENDER'),
       ('YRC',                         'SENDER'),
       ('DHL EXPRESS',                 'SENDER'),
       ('FEDEX 2DAY',                  'SENDER'),
       ('FEDEX 2DAY AM',               'SENDER'),
       ('FEDEX 3RD 1ST',               '3RDPARTY'),
       ('FEDEX 3RD EXP',               '3RDPARTY'),
       ('FEDEX 3RD PARTY',             '3RDPARTY'),
       ('FEDEX 3RD PRO',               '3RDPARTY'),
       ('FEDEX 3RD STD',               '3RDPARTY'),
       ('FEDEX 3RD2DAY',               '3RDPARTY'),
       ('FEDEX COL 2DAY',              'COLLECT'),
       ('FEDEX COL EXSA',              'COLLECT'),
       ('FEDEX COL PRON',              'COLLECT'),
       ('FEDEX COL STD',               'COLLECT'),
       ('FEDEX COLLECT',               'COLLECT'),
       ('FEDEX EXSA',                  'SENDER'),
       ('FEDEX FRT',                   'SENDER'),
       ('FEDEX GRND',                  'SENDER'),
       ('FEDEX INT ECO',               'SENDER'),
       ('FEDEX INT PRI',               'SENDER'),
       ('FEDEX PRON',                  'SENDER'),
       ('FEDEX SMT POST',              'SENDER'),
       ('FEDEX STON',                  'SENDER'),
       ('INTERNATIONAL',               'SENDER'),
       ('PUROLATOR',                   'SENDER'),
       ('R/GUIDE',                     'SENDER'),
       ('UPS 3RD BLUE',                '3RDPARTY'),
       ('UPS 3RD NDASA',               '3RDPARTY'),
       ('UPS 3RD ORG',                 '3RDPARTY'),
       ('UPS 3RD PARTY',               '3RDPARTY'),
       ('UPS 3RD RED',                 '3RDPARTY'),
       ('UPS BLUE',                    'SENDER'),
       ('UPS BLUE AM',                 'SENDER'),
       ('UPS COL NDASA',               'COLLECT'),
       ('UPS COLL 3DAY',               'COLLECT'),
       ('UPS COLL BLUE',               'COLLECT'),
       ('UPS COLL NDA',                'COLLECT'),
       ('UPS COLL NDAM',               'COLLECT'),
       ('UPS COLLECT',                 'COLLECT'),
       ('UPS EXPEDITED',               'SENDER'),
       ('UPS EXPRESS',                 'SENDER'),
       ('UPS FREIGHT',                 'SENDER'),
       ('UPS GROUND',                  'SENDER'),
       ('UPS ORANGE',                  'SENDER'),
       ('UPS RED',                     'SENDER'),
       ('UPS RED AM',                  'SENDER'),
       ('UPS RED SAVER',               'SENDER'),
       ('UPS STANDARD',                'SENDER'),
       ('UPS SURE PST',                'SENDER'),
       ('UPS W EXPEDITED',             'SENDER'),
       ('USPS EXP',                    'SENDER'),
       ('USPS FIRST',                  'SENDER'),
       ('USPS MAIL',                   'SENDER'),
       ('USPS MEDIA',                  'SENDER'),
       ('USPS PRIOR',                  'SENDER')


exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;
*/
Go

/******************************************************************************/
declare @Mapping       TMapping,
        @SourceSystem  TName      = 'CIMS',
        @TargetSystem  TName      = 'HOST',
        @EntityType    TEntity    = 'FreightTerms',
        @Operation     TOperation = 'replace';

/* This is just an example on mappings from CIMS to HOST as Host may use different terminology
  for Freight Terms and so map the ones from host to CIMS Standard */
/*
insert into @Mapping
       (SourceValue,                   TargetValue)
values ('SENDER',                      'PP'),
       ('PREPAID',                     'PP'),
       ('COLLECT',                     'CC'),
       ('3RDPARTY',                    'TP');
*/

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go
