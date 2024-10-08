/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2018/01/11  AY      Setup all Owner-WH combinations
  2016/01/05  NB      Initial revision(NBD-59)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  DefaultWarehouse

  Default Warehouse mapping is to map the Ownercode with respective Physical or Logical Warehouse
  This is used for setting the default Warehouse where the order must be shipped from, during Order Imports

  in this mapping, the OwnerCode is the LookUp code where as the mapped Warehouse is the LookUpDescription.
 -----------------------------------------------------------------------------*/
declare @DefaultWarehouses TLookUpsTable, @LookUpCategory TCategory = 'OwnerDefaultWarehouse';

/* By default let us setup all combinations of Owners and Warehouses. This can be customized as per client needs */

insert into @DefaultWarehouses
       (LookUpCode,  LookUpDescription,  Status)
values ('SCT',       'W1',               'A'),
       ('DEMO',      'W2',               'A'),
       ('V1',        'W1',               'A'),
       ('V2',        'W2',               'A')

exec pr_LookUps_Setup @LookUpCategory, @DefaultWarehouses, @LookUpCategoryDesc = 'Owner Warehouse Mapping';

Go
