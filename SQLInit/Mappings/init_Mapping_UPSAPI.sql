/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/03/29  AY      Cleaned up (JLCA-360)
  2022/11/25  AY      Added SurePost services (OBSupport)
  2022/04/18  AY      Setup UPS services that are valid (OBV3-610)
  2021/11/26  OK      Changed UPS STD GROUND as UPSST to support both CIMSSI and API (BK-706)
  2021/08/25  OK      Corrected mappings for UPS mail innovations (BK-506)
  2021/05/13  RV      Initial Revision (CIMSV3-1453).
------------------------------------------------------------------------------*/

Go

declare @Mapping       TMapping,
        @SourceSystem  TName      = 'CIMS',
        @TargetSystem  TName      = 'UPSAPI', /* API Integration */
        @EntityType    TEntity    = 'ShipVia',
        @Operation     TOperation = null;

/*------------------------------------------------------------------------------
  CIMS.ShipVia -> UPS.ServiceCode
------------------------------------------------------------------------------*/
select @SourceSystem = 'CIMS',
       @TargetSystem = 'UPSAPI', /* UPS API Integration */
       @EntityType   = 'ShipVia';

/* Mappings added as per the document Page No: 39 (https://vsvn.foxfireindia.com:8443/svn/sct/cIMS3.0/branches/Dev3.0/Documents/Manuals/Developer%20Manuals/UPS Shipping Package RESTful Developer Guide.pdf */

delete from @Mapping;
insert into @Mapping
       (SourceValue, TargetValue)
values ('UPS1',                                 '01'), /* UPS Next Day Air */
       ('UPSNEA',                               '14'), /* UPS Next Day Air Early */
       ('UPSNAS',                               '13'), /* UPS Next Day Air Saver */

       ('UPS2',                                 '02'), /* UPS 2nd Day Air */
       ('UPS2DAA',                              '59'), /* UPS 2nd Day Air A.M. */
       ('UPS3',                                 '12'), /* UPS 3 Day select */
       ('UPSG',                                 '03'), /* UPS Ground */

       /* UPS International Services */
       ('UPSST',                                '11'), /* UPS Standard */
       ('UPSWX',                                '08'), /* UPS Worldwide Expedited */
       ('UPSWE',                                '07'), /* UPS Worldwide Express */
       ('UPSWEP',                               '54'), /* UPS Worldwide Express Plus */
       ('UPSWSR',                               '65'), /* UPS Worldwide Saver */
       ('UPSWECDDP',                            '72'), /* UPS Worldwide Economy DDP */
       ('UPSWECDDU',                            '17'), /* UPS Worldwide Economy DDU */

       ('UPSMIFC',                              'M2'), /* UPS First-Class Mail */
       ('UPSMIPM',                              'M3'), /* UPS Priority Mail */
       ('UPSMIEX',                              'M4'), /* UPS Expedited MI */
       ('UPSMIP',                               'M5'), /* UPS Priority MI */
       ('UPSMIEC',                              'M6'), /* UPS Economy MI */
       ('UPSMIR',                               'M7'), /* UPS Mail Innovations Returns */

       /* NOT USED in CIMS */
       ('UPS Access Point Economy',             '70'),
       ('UPS Worldwide Express Freight Midday', '71'),
       ('UPS Express 12:00',                    '74'),
       ('UPSWEPF',                              '96'),

       /* Not used in CIMS - mostly likely for same day in city shipments */
       ('UPS Today Standard',                   '82'),
       ('UPS Today Dedicated Courier',          '83'),
       ('UPS Today Intercity',                  '84'),
       ('UPS Today Express',                    '85'),
       ('UPS EXPRESS SAV',                      '86'), /* UPS Today Express Saver */

       /* UPS Sure Post Services */
       ('UPSS1L',                               '92'),
       ('UPSS1G',                               '93'),
       ('UPSSPBPM',                             '94'),
       ('UPSSPM',                               '95'),
       ('UPSWEPF',                              '96')


exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

/*------------------------------------------------------------------------------
UPS Packaging types
-------------------------------------------------------------------------------*/
select @SourceSystem = 'CIMS',
       @TargetSystem = 'UPSAPI', /* UPS API Integration */
       @EntityType   = 'PackagingType';

/* Mappings added as per the document Page No: 79 (https://vsvn.foxfireindia.com:8443/svn/sct/cIMS3.0/branches/Dev3.0/Documents/Manuals/Developer%20Manuals/UPS Shipping Package RESTful Developer Guide.pdf */

delete from @Mapping;
insert into @Mapping
       (SourceValue,          TargetValue)
values ('UPS_Letter',         '01'),
       ('YOUR_PACKAGING',     '02'),
       ('Tube',               '03'),
       ('PAK',                '04'),
       ('UPS_Express_Box',    '21'),
       ('UPS_25KG_Box',       '24'),
       ('UPS_10KG_Box',       '25'),
       ('Pallet',             '30'),
       ('Small_Express_Box',  '2a'),
       ('Medium_Express_Box', '2b'),
       ('Large_Express_Box',  '2c'),
       ('Flats',              '56'),
       ('Parcels',            '57'),
       ('BPM',                '58'),
       ('UPS First Class',    '59'),
       ('UPS Priority',       '60'),
       ('Machineables',       '61'),
       ('Irregulars',         '62'),
       ('UPS Parcel Post',    '63'),
       ('BPM_Parcel',         '64'),
       ('Media_Mail',         '65'),
       ('BPM_Flat',           '66'),
       ('Standard_Flat',      '67')

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go
