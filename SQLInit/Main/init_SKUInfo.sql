/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/11/28  GAG     File consolidation changes (CIMSV3-2470)
  2022/10/18  GAG     Added SKUCartonGroups, ProductCategory and ProductSubCategory (CIMSV3-1622)
  2022/08/17  AY      Added RestockFee/Reject for return dispositions (OBV3-963)
  2021/08/25  RIA     Initial revision (FBV3-249)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 ABC Classes
 -----------------------------------------------------------------------------*/
declare @ABCClasses TLookUpsTable, @LookUpCategory TCategory = 'ABCClasses';

insert into @ABCClasses
       (LookUpCode,  LookUpDescription,         Status)
values ('A',        'Fast Mover',               'A'),
       ('B',        'Moderate Mover',           'A'),
       ('C',        'Slow Mover',               'A')

exec pr_LookUps_Setup @LookUpCategory, @ABCClasses, @LookUpCategoryDesc = 'ABC Classes';

Go

/*------------------------------------------------------------------------------
 Carton Groups
 -----------------------------------------------------------------------------*/
declare @CartonGroup TLookUpsTable, @LookUpCategory TCategory = 'CartonGroups';

insert into @CartonGroup
       (LookUpCode,  LookUpDescription,           Status)
values ('B',        'All Boxes',                 'A'),
       ('P',        'Padded Bag',                'A'),
       ('L',        'Large Boxes',               'A')

exec pr_LookUps_Setup @LookUpCategory, @CartonGroup, @LookUpCategoryDesc = 'Carton Groups';

Go

/*------------------------------------------------------------------------------*/
/* Product Category */
/*------------------------------------------------------------------------------*/
delete from LookUps where LookUpCategory = 'ProductCategory';

declare @ProductCatagories TLookUpsTable, @LookUpCategory TCategory = 'ProductCategory';

insert into @ProductCatagories
       (LookUpCode,  LookUpDescription,  Status)
values ('',          'None',             'A')

exec pr_LookUps_Setup @LookUpCategory, @ProductCatagories, @LookUpCategoryDesc = 'Product Category';

Go

/*------------------------------------------------------------------------------*/
/* Product Category */
/*------------------------------------------------------------------------------*/
delete from LookUps where LookUpCategory = 'ProductSubCategory';

declare @ProductCatagories TLookUpsTable, @LookUpCategory TCategory = 'ProductSubCategory';

insert into @ProductCatagories
       (LookUpCode,  LookUpDescription,  Status)
values ('',          'None',             'A')

exec pr_LookUps_Setup @LookUpCategory, @ProductCatagories, @LookUpCategoryDesc = 'Product Sub Category';

Go

-- /*------------------------------------------------------------------------------
--   Dropdown values for return Disposition
--  -----------------------------------------------------------------------------*/
-- declare @LookUpCodes TLookUpsTable, @LookUpCategory TCategory = 'Return_Disposition';
-- 
-- insert into @LookUpCodes
--        (LookUpCode,  LookUpDescription,            Status)
-- values ('320',       'Return To Stock',            'A'),
--        ('321',       'Scrap',                      'A')
-- 
-- exec pr_LookUps_Setup @LookUpCategory, @LookUpCodes, @LookUpCategoryDesc = 'Return Dispositions';
-- 
-- Go
