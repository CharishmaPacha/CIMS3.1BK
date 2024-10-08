/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/11/30  GAG     File consolidation changes (CIMSV3-2473)
  2021/04/21  AY      Moved BOD_GroupCriteria (HA-2676)
  2021/03/31  KBB     Added BOLStatus (HA-2467)
  2020/07/17  OK      Addedn DeliveryRequestTypes (HA-1147)
  2020/07/10  RKC     Added LoadingMethods
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Bill of Lading Order Details are typically grouped by CustPO, but that is too
  much for some accounts as there are thousands of Orders with thousands of
  CustPOs, so we give an option to user to group based upon their criteria
 -----------------------------------------------------------------------------*/
declare @YesNo TLookUpsTable, @LookUpCategory TCategory = 'BOD_GroupCriteria';

insert into @YesNo
       (LookUpCode,     LookUpDescription,  Status)
values ('CustPO',       'Customer PO',      'A'),
       ('Consolidate',  'Consolidated',     'A')

exec pr_LookUps_Setup @LookUpCategory, @YesNo,  @LookUpCategoryDesc = 'BoL Order Details group criteria';

Go

/*------------------------------------------------------------------------------*/
/* BoL FreightTerms */
/*------------------------------------------------------------------------------*/

declare @FreightTerms TLookUpsTable, @LookUpCategory TCategory = 'BoLFreightTerms';

insert into @FreightTerms
       (LookUpCode,  LookUpDescription,       Status)
values ('PREPAID',   'Pre-Paid',              'A'),
       ('SENDER',    'Sender',                'A'),
       ('COLLECT',   'Collect',               'A');

exec pr_LookUps_Setup @LookUpCategory, @FreightTerms, @LookUpCategoryDesc = 'BoL Freight Terms';

Go

/*------------------------------------------------------------------------------*/
/* Load BOL Status */
/*------------------------------------------------------------------------------*/
declare @BoLStatuses TStatusesTable, @Entity TEntity = 'BoLStatus';

insert into @BoLStatuses
       (StatusCode,          StatusDescription,      Status)
values ('To Generate',       'To Generate',          'A'),
       ('Generated',         'Generated',            'A'),
       ('Final',             'Final',                'A')

exec pr_Statuses_Setup @Entity, @BoLStatuses;

Go

/*------------------------------------------------------------------------------*/
/* FoB */
/*------------------------------------------------------------------------------*/
declare @LookUPs TLookUpsTable, @LookUpCategory TCategory = 'DeliveryRequestType';

insert into @LookUPs
       (LookUpCode,          LookUpDescription,      Status)
values ('Deliver_On',        'Deliver On',           'A'),
       ('Deliver_Before',    'Deliver Before',       'A'),
       ('Deliver_Between',   'Deliver Between',      'A');

exec pr_LookUps_Setup @LookUpCategory, @LookUps, @LookUpCategoryDesc = 'Delivery Requirement';

Go

/*------------------------------------------------------------------------------*/
/* FoB */
/*------------------------------------------------------------------------------*/
declare @LookUPs TLookUpsTable, @LookUpCategory TCategory = 'FoB';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @LookUPs
       (LookUpCode,   LookUpDescription,   Status)
values ('ShipFrom',   'Ship From',         'A'),
       ('ShipTo',     'Ship To',           'A')

exec pr_LookUps_Setup @LookUpCategory, @LookUPs;

Go

/*------------------------------------------------------------------------------*/
 /* LoadType */
/*------------------------------------------------------------------------------*/
declare @LoadTypes TEntityTypesTable, @Entity TEntity = 'Load';

insert into @LoadTypes
       (TypeCode,      TypeDescription,        Status)
values ('Transfer',    'Transfer',             'I'),
       ('SINGLEDROP',  'Single Drop',          'A'),
       ('MULTIDROP',   'Multiple Drop',        'A'),
       /* Canadian Small Package carriers */
       ('TFORCE',      'T-Force',              'I'),
       ('PURO',        'Purolator',            'I'),
       ('CANADAPOST',  'Canada Post',          'I'),
       ('CANPAR',      'Canpar',               'I'),
       ('LOOMIS',      'LOOMIS',               'I'),
       /* USA Small Package carriers */
       ('UPS',         'UPS',                  'I'),
       ('FEDEX',       'FEDEX',                'I'),
       ('DHL',         'DHL',                  'I'),
       ('LTL',         'Less than Truck Load', 'A'),
       ('TL',          'Truck load',           'A'),
       /* Generic usage */
       ('SMPKG',       'Small Package',        'A'),
       /* Small Package carriers by Service Class */
       ('FDEG',        'FEDEX Ground',         'A'),
       ('FDEN',        'FEDEX Express',        'A'),
       ('UPSE',        'UPS Express',          'A'),
       ('UPSN',        'UPS',                  'A'),
       ('USPS',        'USPS',                 'A');

exec pr_EntityTypes_Setup @Entity, @LoadTypes;

Go

/*------------------------------------------------------------------------------*/
/* Load Statuses */
/*------------------------------------------------------------------------------*/
declare @LoadStatuses TStatusesTable, @Entity TEntity = 'Load';

insert into @LoadStatuses
       (StatusCode,  StatusDescription,        Status)
values ('N',         'New',                    'A'),
       ('I',         'In progress',            'A'),
       ('R',         'Ready to load',          'A'),
       ('M',         'Loading',                'A'),
       ('LI',        'Loading In-progress',    'A'),
       ('L',         'Ready to ship',          'A'),
       ('SI',        'Shipping In-progress',   'A'),
       ('S',         'Shipped',                'A'),
       ('X',         'Cancelled',              'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @LoadStatuses;

Go

/*------------------------------------------------------------------------------
 /* Loading Methods */
 -----------------------------------------------------------------------------*/
declare @LoadingMethods TLookUpsTable, @LookUpCategory TCategory = 'LoadingMethod';

insert into @LoadingMethods
       (LookUpCode,  LookUpDescription,        Status)
values ('RF',        'RF Scan Loading',        'A'),
       ('WCS',       'Fluid Loading',          'I'),
       ('Auto',      'Load on adding Order',   'A'),
       ('None',      'Loading not required',   'A');

exec pr_LookUps_Setup @LookUpCategory, @LoadingMethods, @LookUpCategoryDesc = 'Loading Method';

Go

/*------------------------------------------------------------------------------*/
/* Load Routing Status */
/*------------------------------------------------------------------------------*/
declare @LoadRoutingStatuses TStatusesTable, @Entity TEntity = 'LoadRouting';

insert into @LoadRoutingStatuses
       (StatusCode,  StatusDescription,        Status)
values ('N',         'Not Required',           'A'),
       ('P',         'Pending',                'A'),
       ('A',         'Awaiting Confirmation',  'A'),
       ('C',         'Confirmed',              'A')

exec pr_Statuses_Setup @Entity, @LoadRoutingStatuses;

Go
