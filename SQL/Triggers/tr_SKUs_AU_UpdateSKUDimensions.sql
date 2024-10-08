/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/03/20  TK      tr_SKUs_AU_UpdateSKUDimensions: Initial Revision (HA-2343)
------------------------------------------------------------------------------*/

Go

if object_id('tr_SKUs_AU_UpdateSKUDimensions') is not null
  drop Trigger tr_SKUs_AU_UpdateSKUDimensions;
Go
/*------------------------------------------------------------------------------
  tr_SKUs_AU_UpdateSKUDimensions: When SKU dimensions, UnitVolume or UnitWeight is modified this trigger
    set the preprocess flag on orders to 'N' which will be preprocessed again by job
------------------------------------------------------------------------------*/
Create Trigger tr_SKUs_AU_UpdateSKUDimensions on SKUs After Update
as
begin
  /* If SKUs table was modified, but UnitVolume or UnitWeight was not part of the update statement, then exit */
  if not (update(UnitVolume) or Update(UnitWeight)) return;

  /* Reset Preprocess flag to 'N' so those will be preprocessed again */
  update OH
  set PreprocessFlag = 'N' /* Not yet processed */
  from OrderHeaders OH
    join OrderDetails  OD on (OH.OrderId = OD.OrderId)
    join Inserted SM on (OD.SKUId = SM.SKUId)
  where (OH.Status in ('N', 'W' /* New, Waved */)) and
        (OH.Archived = 'N') and
        (OH.OrderType in ('C', 'CO'));
        --(OH.OrderType not in ('B', 'R', 'RU', 'RP', 'T', 'MK', 'BK', 'RW' /* Bulk, Replenish etc. */));

end /* tr_SKUs_AU_UpdateSKUDimensions */

Go

alter table SKUs disable trigger tr_SKUs_AU_UpdateSKUDimensions;

Go

