/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/23  OK      Added carton types for UPS Mail innovations (BK-506)
  2021/02/05  AY      Setup Carton Groups (BK-155)
  2016/06/13  KN      Added: DHL related code (NBD-554).
  2016/02/10  KN      Added USPS Paracels , need to update client specific details (NBD-162).
  2015/05/14  DK      Deactivated UPS Parcel Post, Package, Priority Mail Innovations and Economy Mail Innovations.
  2014/04/14  DK      Added UPS Parcel Post.
  2014/12/30  SV      Upgraded CartonTypes for Fedex version V15
  2014/12/19  SV      Added FedEx Carton Types
                      FedEx program corrected to use CarrierPackagingType from Carton types, hence updated
  2013/04/10  YA      Included UPS related cartons.
  2013/04/10  AY      Initial OB version
------------------------------------------------------------------------------*/

delete from CartonTypes;
delete from CartonGroups;

declare @CartonGroup TDescription;

/*------------------------------------------------------------------------------*/
/* Sample Carton Types  */
/*------------------------------------------------------------------------------*/

insert into CartonTypes
            (CartonType,  Description,            InnerLength, InnerWidth, InnerHeight, OuterLength, OuterWidth, OuterHeight, Status, SortSeq, CarrierPackagingType,  BusinessUnit)
      select 'A',         'A Carton',             27,          19,         19,          27,          19,         19,          'A',    1,       'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits
union select 'B',         'B Carton',             27,          19,         16,          27,          19,         16,          'A',    2,       'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits
union select 'C',         'C Carton',             27,          19,         13,          27,          19,         13,          'A',    3,       'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits

union select 'F',         'F Carton',             23,          19,         18,          23,          19,         18,          'A',    4,       'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits
union select 'G',         'G Carton',             23,          19,         15,          23,          19,         15,          'A',    5,       'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits
union select 'H',         'H Carton',             23,          19,         12,          23,          19,         12,          'A',    6,       'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits

union select 'I',         'I Carton',             24,          19,         13,          24,          19,         13,          'A',    7,       'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits
union select 'J',         'J Carton',             24,          19,         11,          24,          19,         11,          'A',    8,       'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits
union select 'K',         'K Carton',             24,          19,          7,          24,          19,          7,          'A',    9,       'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits

union select 'L',         'L Carton',             21,          12,         13,          21,          12,         13,          'A',    10,      'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits
union select 'M',         'M Carton',             21,          12,         10,          21,          12,         10,          'A',    11,      'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits

union select 'N',         'N Carton',             21,          12,          7,          21,          12,          7,          'A',    12,      'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits
union select 'O',         'O Carton',             21,          12,          5,          21,          12,          5,          'A',    13,      'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits

union select 'P',         'P Carton',             12,          12,          8,          12,          12,          8,          'A',    14,      'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits
union select 'Q',         'Q Carton',             12,          12,          5,          12,          12,          5,          'A',    15,      'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits

union select 'R',         'R Carton',             12,           6,          6,          12,           6,          6,          'A',    16,      'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits
union select 'S',         'S Carton',             12,           6,          4,          12,           6,          4,          'A',    17,      'YOUR_PACKAGING',      BusinessUnit from vwBusinessUnits


/* Envelope should have a PackagingType to represent it is a Fedex envelope
update CartonTypes
set CarrierPackagingType='<CarrierPackagingTypes><CarrierPackagingType><ShipVia>FEDEX</ShipVia><PackagingType>YOUR_PACKAGING</PackagingType></CarrierPackagingType></CarrierPackagingTypes>'
where CartonType in ('10');
*/


/*----------------------------------------------------------------------------*/
  /* UPS Carton types */
/* Length, Width and Height is set referring to the UPS site, but Inner width and Outer width is all same now as they have mentioned only one dimension for all individual package (Pallet size is not mantioned)*/
insert into CartonTypes
            (CartonType,  Description,                  InnerLength, InnerWidth, InnerHeight, OuterLength, OuterWidth, OuterHeight, Status, SortSeq, CarrierPackagingType,     BusinessUnit)
      select 'AA',        'UPS Express Envelope',       10,          13,         0,           10,          13,         0,           'A',    1,       'UPS Express Envelope',   BusinessUnit from vwBusinessUnits
union select 'AB',        'UPS Tube',                   38,          6,          6,           38,          6,          6,           'A',    2,       'UPS Tube',               BusinessUnit from vwBusinessUnits
union select 'AC',        'UPS Pak',                    16,          13,         0,           16,          13,         0,           'A',    3,       'UPS Pak',                BusinessUnit from vwBusinessUnits
union select 'AD',        'UPS Express Box',            13,          4,          18,          13,          4,          18,          'A',    4,       'UPS Express Box',        BusinessUnit from vwBusinessUnits
union select 'AE',        'UPS 25kg Box',               19,          17,         14,          19,          17,         14,          'A',    5,       'UPS 25kg Box',           BusinessUnit from vwBusinessUnits
union select 'AF',        'UPS 10kg Box',               17,          13,         11,          17,          13,         11,          'A',    6,       'UPS 10kg Box',           BusinessUnit from vwBusinessUnits
union select 'AG',        'Pallet',                     12,          12,         6,           12,          12,         6,           'A',    7,       'Pallet',                 BusinessUnit from vwBusinessUnits
union select 'AH',        'UPS Small Express Box',      13,          11,         2,           13,          11,         2,           'A',    8,       'UPS Small Express Box',  BusinessUnit from vwBusinessUnits
union select 'AI',        'UPS Medium Express Box',     15,          11,         3,           15,          11,         3,           'A',    9,       'UPS Medium Express Box', BusinessUnit from vwBusinessUnits
union select 'AJ',        'UPS Large Express Box',      18,          13,         3,           18,          13,         3,           'A',   10,       'UPS Large Express Box',  BusinessUnit from vwBusinessUnits
union select 'PPT',       'UPS Parcel Post',            23,          19,         18,          23,          19,         18,          'I',   11,       'UPS Parcel Post',        BusinessUnit from vwBusinessUnits
union select 'MIP',       'Priority Mail Innovations',  0,           0,          0,           0,           0,          0,           'I',   13,       'MIP',                    BusinessUnit from vwBusinessUnits
union select 'MIE',       'Economy Mail Innovations',   0,           0,          0,           0,           0,          0,           'I',   14,       'MIE',                    BusinessUnit from vwBusinessUnits
union select 'CP',        'Package',                    0,           0,          0,           0,           0,          0,           'I',   12,       'CP',                     BusinessUnit from vwBusinessUnits
union select 'FC',        'First Class',                0,           0,          0,           0,           0,          0,           'A',   15,       'UPS First Class',        BusinessUnit from vwBusinessUnits
union select 'PR',        'Priority',                   0,           0,          0,           0,           0,          0,           'A',   16,       'UPS Priority',           BusinessUnit from vwBusinessUnits
union select 'PP',        'Parcel Post',                0,           0,          0,           0,           0,          0,           'A',   17,       'UPS Parcel Post',        BusinessUnit from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* FedEx carton types */
insert into CartonTypes
            (CartonType,    Description,            InnerLength, InnerWidth, InnerHeight, OuterLength, OuterWidth, OuterHeight, Status, SortSeq, CarrierPackagingType,    BusinessUnit)
      select 'ENVELOPE',    'FedEx Envelope',       23.5,        33.5,       01,          23.5,        33.5,       01,          'A',    1,       'FEDEX_ENVELOPE',        BusinessUnit from vwBusinessUnits
union select 'PAK',         'FedEx Large Pak',      30.48,       39.37,      01,          30.48,       39.37,      01,          'A',    2,       'FEDEX_PAK',             BusinessUnit from vwBusinessUnits
union select 'TUBE',        'FedEx Tube',           96.52,       15.24,      15.24,       96.52,       15.24,      15.24,       'A',    3,       'FEDEX_TUBE',            BusinessUnit from vwBusinessUnits
union select 'BOX_S',       'FedEx Small Box',      31.12,       27.69,      3.81,        31.12,       27.69,      3.81,        'A',    4,       'FEDEX_SMALL_BOX',       BusinessUnit from vwBusinessUnits
union select 'BOX_M',       'FedEx Medium Box',     33.26,       29.21,      6.03,        33.26,       29.21,      6.03,        'A',    5,       'FEDEX_MEDIUM_BOX',      BusinessUnit from vwBusinessUnits
union select 'BOX_L',       'FedEx Large Box',      45.40,       31.43,      7.62,        45.40,       31.43,      7.62,        'A',    6,       'FEDEX_LARGE_BOX',       BusinessUnit from vwBusinessUnits
union select '10KG',        'FedEx 10kg Box',       40.16,       32.86,      25.88,       40.16,       32.86,      25.88,       'A',    7,       'FEDEX_10KG_BOX',        BusinessUnit from vwBusinessUnits
union select '25KG',        'FedEx 25kg Box',       54.8,        42.1,       33.5,        54.8,        42.1,       33.5,        'A',    8,       'FEDEX_25KG_BOX',        BusinessUnit from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* USPS carton types */
insert into CartonTypes
            (CartonType,    Description,                                InnerLength, InnerWidth, InnerHeight, OuterLength, OuterWidth, OuterHeight, Status, SortSeq, CarrierPackagingType,    BusinessUnit)
      select 'USPS_BOX_S',  'Priority Mail Small Flat Rate Box',        5.37,        8.62,       1.62,        5.37,        8.62,       1.62,        'A',    1,       'USPS_SMALL_BOX',        BusinessUnit from vwBusinessUnits
union select 'USPS_BOX_M',  'Priority Mail Medium Flat Rate Box - 1',   11,          8.5,        5.5,         11,          8.5,        5.5,         'A',    2,       'USPS_MEDIUM_BOX',       BusinessUnit from vwBusinessUnits
union select 'USPS_BOX_L',  'Priority Mail Large Mailing Box',          14.75,       11.75,      11.5,        14.75,       11.75,      14.75,       'A',    3,       'USPS_LARGE_BOX',        BusinessUnit from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* DHL carton types */
insert into CartonTypes
            (CartonType,              Description,            InnerLength, InnerWidth, InnerHeight, OuterLength, OuterWidth, OuterHeight, Status, SortSeq, CarrierPackagingType,    BusinessUnit)
      select 'DHL_EXPRESS_ENVELOPE',  'DHL Express Envelope', 120,         80,         80,          120,         80,         80,          'I',    1,       'EE',                    BusinessUnit from vwBusinessUnits
union select 'DHL_YOUR_PACKAGING',    'Your packaging',       120,         80,         80,          120,         80,         80,          'I',    1,       'YP',                    BusinessUnit from vwBusinessUnits

/********************************************************************************/
/* Carton Groups */
/********************************************************************************/

/*----------------------------------------------------------------------------*/
/* ANYCARTON - All Active carton types */
select @CartonGroup = 'ANYCARTON';

insert into CartonGroups
            (CartonGroup,    CartonType,            Description,              Status, BusinessUnit)
     select @CartonGroup,    CartonType,            '',                       'A',    BusinessUnit from CartonTypes CT;

Go
