/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/03  PK      Added Temp Carton type in LPN, LPNTypeForCreateInventory (HA-1970)
  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2020/04/05  OK      Added type LPNTypeForCreateInventory to define LPNTypes for create inventory (CIMSV3-874)
  2020/03/19  RT      Changed the LPNTypeForModify, LPNTypeForGenerate and LPNTypeForCart as per standard by capitalising the Prefix (CIMSV3-697)
  2019/03/26  VS      set Status to Active for Tote Types.(CID-223)
  2016/02/11  TK      Ship Cartons needs to be generated from UI (NBD-155)
  2015/08/21  YJ      Added LPNTypes for Generate Palle(ACME-139)
  2015/07/08  YJ      Added LPNTypes for Generate LPNs(cIMS-522)
  2014/12/23  AK      set Status to Inactive for Tote Types.
  2014/04/16  TK      Changes made to control data using procedure
  2103/05/22  TD      Added new LPN type -TO (Tote)
  2012/04/09  AY      Customized for TD - Initial revision.
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
