/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/02/23  MS      pr_Inventory_OnhandInventory, pr_Inventory_InvSnapshot_Create: Changes to insert SourceSystem (BK-1026)
  2023/02/09  MS      pr_Inventory_InvSnapshot_Create: Changes to insert ToShipQty (BK-1015)
  2023/01/25  VS      pr_Inventory_InvSnapshot_ContinualUpdate, pr_Inventory_InvSnapshot_Create: Update the ReserveQty and added InitialOnhandQty (JLFL-98)
  pr_Inventory_InvSnapshot_Create: Changes to archive old records
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Inventory_InvSnapshot_Create') is not null
  drop Procedure pr_Inventory_InvSnapshot_Create;
Go
/*------------------------------------------------------------------------------
  Proc pr_Inventory_InvSnapshot_Create:
    This procedure creates a snapshot of the inventory available at the time this
    is run. In case we missed creating a snapshot we could create one with specified
    time once we receive the alert - before production begins the next day.

  @Mode: WH or LPN - by default the onhand inventory is summarized by WH, but if
         we need to create a more detailed snapshot, then we can do so by pass in
         LPN for Mode.

  exec pr_Inventory_InvSnapshot_Create 'HA', 'cimsadmin', 'WH11', @Warehouse = '11'

------------------------------------------------------------------------------*/
Create Procedure pr_Inventory_InvSnapshot_Create
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @SnapshotType     TTypeCode     = 'Adhoc',
   @SnapshotDateTime TDateTime     = null,
   @SKU              TSKU          = null,
   @SKU1             TSKU          = null,
   @SKU2             TSKU          = null,
   @SKU3             TSKU          = null,
   @SKU4             TSKU          = null,
   @SKU5             TSKU          = null,
   @Warehouse        TWarehouse    = null,
   @Ownership        TOwnership    = null,
   @Location         TLocation     = null,
   @Mode             TName         = null)
as
  declare @vReturnCode       TInteger,
          @vSnapshotId       TRecordId,
          @vUserId           TUserId,
          @vSnapshotDateTime TDateTime,
          @vSnapshotDate     TDate;

  declare @ttOnhandInventory TOnhandInventory;
begin /* pr_Inventory_Create InvSnapshot */

  select @vUserId           = System_User,
         @vSnapshotDateTime = coalesce(@SnapshotDateTime, getdate()),
         @vSnapshotDate     = cast(@vSnapshotDateTime as Date);

  if (object_id('tempdb..#OHIResults') is null) select * into #OHIResults from @ttOnhandInventory

  /* Archive old Snapshots when new one is being created */
  if (@SnapshotType = 'EndOfDay')
   update InvSnapshot
   set Archived = 'Y'
   where (Archived = 'N') and
         (SnapshotDate < @vSnapshotDate);

  /* Get next InvSnapshotId */
  exec pr_Controls_GetNextSeqNo 'InventorySnapshot', 1, @vUserId , @BusinessUnit,
                                @vSnapshotId output;

  /* Build the onhand inventory - the procedure populates the data into #OHIResults */
  exec pr_Inventory_OnhandInventory null /* SKUId */, @SKU, @SKU1, @SKU2, @SKU3, @SKU4, @SKU5,
                                    @Warehouse, @Ownership, null /* LPN */, @Location,
                                    @Mode = @Mode, @BusinessUnit = @BusinessUnit, @ReturnResultSet = 'N';

  /* Insert required data in Snapshot table */
  insert into InvSnapshot (SnapshotId, SnapshotDateTime, SnapshotDate, SnapShotType,
                           SKUId, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UPC, SourceSystem,
                           Location, Warehouse, LPN, Ownership, BusinessUnit, InventoryKey,
                           InventoryClass1, InventoryClass2, InventoryClass3,
                           UnitsPerInnerPack, AvailableIPs, ReservedIPs, ReceivedIPs, ToShipIPs, ToShipQty,
                           AvailableQty, ReservedQty, ReceivedQty, OnhandValue, InitialOnhandQty, CreatedBy)
    select @vSnapshotId, @vSnapshotDateTime, @vSnapshotDate, @SnapshotType,
           SKUId, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UPC, SourceSystem,
           Location, Warehouse, LPN, Ownership, BusinessUnit, InventoryKey,
           rtrim(coalesce(InventoryClass1, '')), rtrim(coalesce(InventoryClass2, '')), rtrim(coalesce(InventoryClass3, '')),
           UnitsPerInnerPack, AvailableIPs, ReservedIPs, ReceivedIPs, ToShipIPs, ToShipQty,
           AvailableQty, ReservedQty, ReceivedQty, OnhandValue, coalesce(AvailableQty, 0) + coalesce(ReservedQty, 0), @UserId
    from #OHIResults;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end/* pr_Inventory_InvSnapshot_Create */

Go
