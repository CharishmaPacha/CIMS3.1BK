/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/16  YJ      Added to send empty LookUpCode to avoid exception if there is no value (CIMSV3-1222)
  2011/08/26  VM      Initial revision: Blank file for future customer specific entries
------------------------------------------------------------------------------*/
/*--------Need to add this LookUpCategory into Init_LookUps.sql file----------*/


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