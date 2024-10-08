/*------------------------------------------------------------------------------
  (c) Foxfire Technologies (India) Ltd. Hyderabad, India

  Revision History:

  Date        Person  Comments

  2022/12/02  GAG     File consolidation changes (CIMSV3-2477)
  2022/07/20  AY      Putaway/Pick Paths: Additional options for descending order (OBV3-932)
  2022/07/12  AY      PickPathFormat: Revised put/pick path formats
  2022/06/23  PKK     PickPathFormat: Added PPF5 & PPF6, PutawayPathFormat: Added PAPF5 & PAPF6 (OBV3-828)
  2022/05/29  GAG     Initial Revision (OBV3-623)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Location Allowed OPerations
 -----------------------------------------------------------------------------*/
declare @OnHoldLocOperations TLookUpsTable, @LookUpCategory TCategory = 'LocAllowedOperations';

insert into @OnHoldLocOperations
       (LookUpCode,  LookUpDescription,   Status)
values ('P',         'Putaway',           'A'),
       ('K',         'Picking',           'A'),
       ('R',         'Replenishments',    'A'),
       ('C',         'Cycle Count',       'I'),
       ('N',         'None',              'A')

exec pr_LookUps_Setup @LookUpCategory, @OnHoldLocOperations, @LookUpCategoryDesc = 'Location Operations';

Go

/*------------------------------------------------------------------------------*/
/* Location Type */
/*------------------------------------------------------------------------------*/
declare @LocationTypes TEntityTypesTable, @Entity TEntity = 'Location';

insert into @LocationTypes
       (TypeCode, TypeDescription,         Status)
values ('R',      'Reserve',               'A'),
       ('B',      'Bulk',                  'A'),
       ('K',      'Picklane',              'A'),
       ('KD',     'Dynamic Picklane',      'I'),
       ('KS',     'Static Picklane',       'I'),
       ('S',      'Staging',               'A'),
       ('D',      'Dock',                  'A'),
       ('C',      'Conveyor',              'I')

exec pr_EntityTypes_Setup @Entity, @LocationTypes;

Go

/*------------------------------------------------------------------------------*/
/* Location Status */
/*------------------------------------------------------------------------------*/
declare @LocationStatuses TStatusesTable, @Entity TEntity = 'Location';

insert into @LocationStatuses
       (StatusCode,  StatusDescription,  Status)
values ('I',         'Inactive',         'A'),
       ('E',         'Empty',            'A'),
       ('U',         'Available',        'A'),
       ('R',         'Reserved',         'A'),
       ('D',         'Deleted',          'A'),
       ('F',         'Full',             'I'),
       ('N',         'N/A',              'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @LocationStatuses;

Go

/*------------------------------------------------------------------------------
 Location Classes
 -----------------------------------------------------------------------------*/
declare @LocClasses TLookUpsTable, @LookUpCategory TCategory = 'LocationClasses';

insert into @LocClasses
       (LookUpCode,  LookUpDescription,         Status)
values ('RP',        'Reserve Pallet Racks',    'A'),
       ('RF',        'Reserve Floor Locations', 'A'),
       ('P1',        'Picklanes',               'A'),
       ('B',         'Bulk Locations',          'A')

exec pr_LookUps_Setup @LookUpCategory, @LocClasses, @LookUpCategoryDesc = 'Location Classes';

Go

/*------------------------------------------------------------------------------
 Location Format
 -----------------------------------------------------------------------------*/
declare @LocationFormats TLookUpsTable, @LookUpCategory TCategory = 'LocationFormat';

insert into @LocationFormats
       (LookUpCode,  LookUpDescription,                         Status)
values ('LF1',       '<LocationType>-<Row>-<Section>-<Level>',  'A'),
       ('LF2',       '<LocationType>-<Row>-<Level>-<Section>',  'A'),
       ('LF3',       '<Row>-<Section>-<Level>',                 'A'),
       ('LF4',       'P-<Row>-<Level>',                         'A'),
       ('LF5',       'E-<Row>-<Level>-<Section>',               'I'),
       ('LF6',       'R-<Row>-<Level>-<Section>',               'I')

exec pr_LookUps_Setup @LookUpCategory, @LocationFormats, @LookUpCategoryDesc =  'Location Format';

Go

/*------------------------------------------------------------------------------*/
/* Location Storage Type */
/*------------------------------------------------------------------------------*/
declare @LocationStorageTypes TEntityTypesTable, @Entity TEntity = 'LocationStorage';

insert into @LocationStorageTypes
       (TypeCode,  TypeDescription,   Status)
values ('L',       'LPNs',            'A'),
       ('P',       'Cases',           'A'),
       ('U',       'Units',           'A'),
       ('A',       'Pallets',         'A'),
       ('LA',      'Pallets & LPNs',  'A'),
       ('LF',      'LPNs Flat',       'I'),
       ('LH',      'LPNs Hanging',    'I'),
       ('UF',      'Units Flat',      'I'),
       ('UH',      'Units Hanging',   'I')

exec pr_EntityTypes_Setup @Entity, @LocationStorageTypes;

Go

/*------------------------------------------------------------------------------*/
/* Location Sub Type */
/*------------------------------------------------------------------------------*/
declare @LocationSubTypes TEntityTypesTable, @Entity TEntity = 'LocationSubType';

insert into @LocationSubTypes
       (TypeCode, TypeDescription,   Status)
values ('D',      'Dynamic',         'A'),
       ('S',      'Static',          'A')

exec pr_EntityTypes_Setup @Entity, @LocationSubTypes;

Go

/*------------------------------------------------------------------------------*/
/* Location Types for Generate Locations */
/*------------------------------------------------------------------------------*/
declare @LocationTypes TEntityTypesTable, @Entity TEntity = 'LOCTypeforGenerate';

insert into @LocationTypes
       (TypeCode, TypeDescription,         Status)
values ('R',      'Reserve',               'A'),
       ('B',      'Bulk',                  'A'),
       ('K',      'Picklane',              'I'),
       ('KD',     'Dynamic Picklane',      'A'),
       ('KS',     'Static Picklane',       'A'),
       ('S',      'Staging',               'A'),
       ('D',      'Dock',                  'A'),
       ('C',      'Conveyor',              'I')

exec pr_EntityTypes_Setup @Entity, @LocationTypes;

Go

/*------------------------------------------------------------------------------
 PickPath Formats
 -----------------------------------------------------------------------------*/
declare @PickPath TLookUpsTable, @LookUpCategory TCategory = 'PickPathFormat';

insert into @PickPath
       (LookUpCode,  LookUpDescription,                                 Status)
values ('PPF01',     '~Row~-~Bay~-~Section~-~Level~',                   'A'),
       ('PPF02',     '~Row~-~Bay~-~Level~-~Section~',                   'A'),
       ('PPF03',     '~Aisle~-~Bay~-~Section~-~Level~',                 'A'),
       ('PPF04',     '~Aisle~-~Bay~-~Level~-~Section~',                 'A'),
       ('PPF05',     '~Aisle~-~Bay~-~Row~-~Level~-~Section~',           'A'),
       ('PPF06',     '~Aisle~-~Bay~-~Row~-~Section~-~Level~',           'A'),
       ('PPF07',     '~Row~-~Level~-~Section~',                         'A'),
       ('PPF08',     '~Row~-~Section~-~Level~',                         'A'),

       ('PPF21',     '~Aisle~-~BayDesc~-~Row~-~Level~-~Section~',       'A'),
       ('PPF22',     '~Aisle~-~BayDesc~-~Row~-~Section~-~Level~',       'A'),
       ('PPF23',     '~Aisle~-~BayDesc~-~Row~-~Level~-~SectionDesc~',   'A'),
       ('PPF24',     '~Aisle~-~BayDesc~-~Row~-~SectionDesc~-~Level~',   'A'),

       ('PPF31',     '~Row~-~LevelDesc~-~Section~',                     'A'),
       ('PPF32',     '~Row~-~Section~-~LevelDesc~',                     'A'),
       ('PPF33',     '~Row~-~Level~-~SectionDesc~',                     'A'),
       ('PPF34',     '~Row~-~SectionDesc~-~Level~',                     'A'),
       ('PPF35',     '~Row~-~LevelDesc~-~SectionDesc~',                 'A'),
       ('PPF36',     '~Row~-~SectionDesc~-~LevelDesc~',                 'A'),

       ('$CLEAR$',   'Clear the path',                                  'A'); -- will always be the last one in the list

exec pr_LookUps_Setup @LookUpCategory, @PickPath, @LookUpCategoryDesc = 'Pickpath Format';

Go

/*------------------------------------------------------------------------------
 Putaway Formats
 -----------------------------------------------------------------------------*/
declare @PutawayPath TLookUpsTable, @LookUpCategory TCategory = 'PutawayPathFormat';

insert into @PutawayPath
       (LookUpCode,  LookUpDescription,                                 Status)
values ('PAPF01',    '~Row~-~Bay~-~Section~-~Level~',                   'A'),
       ('PAPF02',    '~Row~-~Bay~-~Level~-~Section~',                   'A'),
       ('PAPF03',    '~Aisle~-~Bay~-~Section~-~Level~',                 'A'),
       ('PAPF04',    '~Aisle~-~Bay~-~Level~-~Section~',                 'A'),
       ('PAPF05',    '~Aisle~-~Bay~-~Row~-~Level~-~Section~',           'A'),
       ('PAPF06',    '~Aisle~-~Bay~-~Row~-~Section~-~Level~',           'A'),
       ('PAPF07',    '~Row~-~Level~-~Section~',                         'A'),
       ('PAPF08',    '~Row~-~Section~-~Level~',                         'A'),

       ('PAPF21',    '~Aisle~-~BayDesc~-~Row~-~Level~-~Section~',       'A'),
       ('PAPF22',    '~Aisle~-~BayDesc~-~Row~-~Section~-~Level~',       'A'),
       ('PAPF23',    '~Aisle~-~BayDesc~-~Row~-~Level~-~SectionDesc~',   'A'),
       ('PAPF24',    '~Aisle~-~BayDesc~-~Row~-~SectionDesc~-~Level~',   'A'),

       ('PAPF31',    '~Row~-~LevelDesc~-~Section~',                     'A'),
       ('PAPF32',    '~Row~-~Section~-~LevelDesc~',                     'A'),
       ('PAPF33',    '~Row~-~Level~-~SectionDesc~',                     'A'),
       ('PAPF34',    '~Row~-~SectionDesc~-~Level~',                     'A'),
       ('PAPF35',    '~Row~-~LevelDesc~-~SectionDesc~',                 'A'),
       ('PAPF36',    '~Row~-~SectionDesc~-~LevelDesc~',                 'A'),

       ('$CLEAR$',   'Clear the path',                                  'A');  -- will always be the last one in the list

exec pr_LookUps_Setup @LookUpCategory, @PutawayPath, @LookUpCategoryDesc = 'PutawayPath Format';

Go

/*------------------------------------------------------------------------------*/
/* Replenish Storage Types */
/*------------------------------------------------------------------------------*/
declare @LocationStorageTypes TEntityTypesTable, @Entity TEntity = 'ReplenishStorageTypes';

insert into @LocationStorageTypes
       (TypeCode,  TypeDescription,   Status)
values ('P',       'Cases',           'A'),
       ('U',       'Units',           'A')

exec pr_EntityTypes_Setup @Entity, @LocationStorageTypes;

Go

/*------------------------------------------------------------------------------
  Variance
 -----------------------------------------------------------------------------*/
declare @Variance TLookUpsTable, @LookUpCategory TCategory = 'Variance';

insert into @Variance
       (LookUpCode,  LookUpDescription,        Status)
values ('M',         'SKU Misplaced',          'A'),
       ('N',         'New SKU in Location',    'A'),
       ('Q',         'Change in Quantity',     'A')

exec pr_LookUps_Setup @LookUpCategory, @Variance, @LookUpCategoryDesc = 'Variance';

Go
