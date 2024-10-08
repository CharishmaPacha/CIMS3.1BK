/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Activation_PopulateLPNsInfo') is not null
  drop Procedure pr_LPNs_Activation_PopulateLPNsInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Activation_PopulateLPNsInfo: Bases upon the LPNs to be activated both From & To LPNs

  All temporary tables are create early on before this call is made
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Activation_PopulateLPNsInfo
  (@Operation     TOperation = null,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,

          @XMLRulesData             TXML;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Prepare hash tables */
  alter table #ToLPNDetails add KeyValue as cast(SKUId as varchar) + '-' + Warehouse + '-' + Ownership + '-' +
                                            InventoryClass1 + '-' + InventoryClass2 + '-' + InventoryClass3;

  alter table #FromLPNDetails drop column AllocableQty;
  alter table #FromLPNDetails add AllocableQty as Quantity - coalesce(ReservedQty, 0);
  alter table #FromLPNDetails add KeyValue as cast(SKUId as varchar) + '-' + Warehouse + '-' + Ownership + '-' +
                                              InventoryClass1 + '-' + InventoryClass2 + '-' + InventoryClass3;

  /* Build the list of SKUs to activate */
  select LD.SKUId, sum(LD.InnerPacks) IPsToActivate, sum(LD.Quantity) QtyToActivate,
         LD.OrderId, L.PickBatchId as WaveId, L.Ownership, L.DestWarehouse,
         L.InventoryClass1, L.InventoryClass2, L.InventoryClass3,
         concat_ws('-', LD.SKUId, L.DestWarehouse, L.Ownership, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3) as KeyValue
  into #SKUsToActivate
  from LPNDetails LD
    join LPNs L on (LD.LPNId = L.LPNId)
    join #ttSelectedEntities SE on (SE.EntityId = L.LPNId) and (L.Onhandstatus = 'U' /* Unavailable */)
    group by LD.SKUId, LD.OrderId, L.PickBatchId, L.Ownership, L.DestWarehouse, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3;

  /* Check if there are bulk orders in wave of the selected ship cartons */
  insert into #BulkOrders (OrderId, WaveId)
    select distinct OH.OrderId, OH.PickBatchId
    from OrderHeaders OH
      join #SKUsToActivate STA on (OH.PickBatchId = STA.WaveId) and
                                  (OH.OrderType   = 'B' /* Bulk */);

  /* Invoke proc to identify the inventory to be deducted to activate ship carton
     executing following proc will populate inventory to deduct into #FromLPNDetails */
  exec pr_LPNs_Activation_GetInventoryToDeduct 'LoadAllInventory', @BusinessUnit, @UserId;

  /* Get the LPNs Details that needs to activated from the selected LPNs list */
  insert into #ToLPNDetails (LPNId, LPNType, LPNDetailId, LPNLines, SKUId, InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                             OrderId, OrderDetailId, WaveId, Ownership, Warehouse, Lot,
                             InventoryClass1, InventoryClass2, InventoryClass3, ProcessedFlag)
    select LD.LPNId, L.LPNType, LD.LPNDetailId, L.NumLines, LD.SKUId, LD.InnerPacks, LD.UnitsPerPackage, LD.Quantity, 0 /* ReservedQty */,
           LD.OrderId, LD.OrderDetailId, L.PickBatchId, L.Ownership, L.DestWarehouse, LD.Lot,
           L.InventoryClass1, L.InventoryClass2, L.InventoryClass3, 'N' /* No */
    from LPNDetails LD
      join LPNs L on (LD.LPNId = L.LPNId)
      join #ttSelectedEntities SE on (L.LPNId = SE.EntityId)
    where (LD.OnhandStatus = 'U' /* Unavailable */)
    order by LD.LPNId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Activation_PopulateLPNsInfo */

Go
