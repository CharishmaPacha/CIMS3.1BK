/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('tr_SKUs_AU_UpdateUnitsPerLPN') is not null
  drop Trigger tr_SKUs_AU_UpdateUnitsPerLPN;
Go
/*------------------------------------------------------------------------------
  After Update tr_SKUs_AU_UpdateUnitsPerLPN

  Purpose - ???

------------------------------------------------------------------------------*/
Create Trigger tr_SKUs_AU_UpdateUnitsPerLPN on SKUs After Update
as
  declare @vOrderId   TRecordId,
          @vRecordId  TRecordId;

  declare @ttOrders   TEntityKeysTable;
begin
  /* Fetch all the orders(New and Bathced) for this SKU,to preprocess them (to recalculate UnitsPerCarton for now) */
  insert into @ttOrders(EntityId)
    select distinct OH.OrderId
    from Orderheaders OH join OrderDetails OD on (OD.OrderId = OH.OrderId)
    where (OH.Status in ('I' /* New */, 'W' /* Waved */)) and
          (OD.SKUId in (select SKUId from Inserted));

  select top 1 @vOrderId  = EntityId,
               @vRecordId = RecordId
  from @ttOrders
  order by RecordId

  /* Loop through and preprocess on the orders for which the SKUs has been updated */
  while (@@rowcount > 0)
    begin
      exec pr_OrderHeaders_Preprocess @vOrderId;

      /* select the next Order to be preprocessed */
      select top 1 @vOrderId  = EntityId,
                   @vRecordId = RecordId
      from @ttOrders
      where (RecordId > @vRecordId)
      order by RecordId
    end
end

Go

alter table SKUs disable trigger tr_SKUs_AU_UpdateUnitsPerLPN;

Go

