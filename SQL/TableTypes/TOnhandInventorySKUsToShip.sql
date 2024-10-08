/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/02/14  MS      TOnhandInventorySKUsToShip: Changes to use InventoryKey as Primary Key (BK-1020)
  2023/01/18  MS      TOnhandInventorySKUsToShip: Added Lot & corrected inventorykey computation (BK-992)
  2020/06/24  VS      Added TOnhandInventorySKUsToShip,TOnhandInventoryResult,TOnhandInventory2 (FB-2029)
  Create Type TOnhandInventorySKUsToShip as Table
  Grant References on Type:: TOnhandInventorySKUsToShip to public;
------------------------------------------------------------------------------*/

Go

Create Type TOnhandInventorySKUsToShip as Table
  (SKUId             TRecordId,
   SKU               TSKU,
   UPC               TUPC,
   UoM               TUoM,
   Warehouse         TWarehouse,
   Ownership         TOwnership,
   Lot               TLot,
   InventoryClass1   TInventoryClass      default '',
   InventoryClass2   TInventoryClass      default '',
   InventoryClass3   TInventoryClass      default '',
   UnitsToShip       TQuantity,
   BusinessUnit      TBusinessUnit,
   InventoryKey      as concat_ws('-', SKUId, Ownership, Warehouse, Lot, InventoryClass1, InventoryClass2, InventoryClass3),

   Primary Key       (InventoryKey),
   Unique            (InventoryKey)
);

Grant References on Type:: TOnhandInventorySKUsToShip to public;

Go
