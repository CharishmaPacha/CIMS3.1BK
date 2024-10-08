/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/06/23  SK      pr_LPNs_CreateLPNs_TransferInventory: Pass Lot value (HA-3875)
  2022/06/15  TK      pr_LPNs_Action_BulkMove & pr_LPNs_CreateLPNs_TransferInventory:
  2021/11/10  VM      pr_LPNs_CreateLPNs_TransferInventory: Prepare TransferInfo with Source Inv and Destination KITs when KITs are created (FBV3-346)
                      pr_LPNs_CreateLPNs_TransferInventory: Code Refractoring
                      pr_LPNs_CreateLPNs_TransferInventory: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_CreateLPNs_TransferInventory') is not null
  drop Procedure pr_LPNs_CreateLPNs_TransferInventory;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_CreateLPNs_TransferInventory: This procedure transfers inventory from
    source LPNs to destination LPNs and generates inventory change exports as required.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_CreateLPNs_TransferInventory
  (@InputXML             xml)
as
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vMessage                   TMessage,

          @SKUId                      TRecordId,
          @Quantity                   TQuantity,
          @Ownership                  TOwnership,
          @Warehouse                  TWarehouse,
          @ReasonCode                 TReasonCode,
          @InventoryClass1            TInventoryClass,
          @InventoryClass2            TInventoryClass,
          @InventoryClass3            TInventoryClass,
          @Action                     TAction,
          @BusinessUnit               TBusinessUnit,
          @UserId                     TUserId,

          @vDropLocationId            TRecordId,
          @vDropLocation              TLocation;

  declare @ttInventoryTransfer        TInventoryTransfer;

begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Create required hash tables */
  select * into #InventoryTransferInfo from @ttInventoryTransfer;

  /* If no LPNs were created or there is not inventory to consume then return */
  if not exists (select *  from #CreateLPNs) or
     not exists (select * from #InventoryToConsume)
    return;

    /* Get the XML User inputs into the local variables */
  select @SKUId            = Record.Col.value('SKUId[1]'              , 'TRecordId'),
         @Quantity         = Record.Col.value('UnitsPerLPN[1]'        , 'TQuantity'),
         @Ownership        = Record.Col.value('Owner[1]'              , 'TOwnership'),
         @Warehouse        = Record.Col.value('Warehouse[1]'          , 'TWarehouse '),
         @ReasonCode       = Record.Col.value('ReasonCode[1]'         , 'TReasonCode'),
         @InventoryClass1  = Record.Col.value('InventoryClass1[1]'    , 'TInventoryClass'),
         @InventoryClass2  = Record.Col.value('InventoryClass2[1]'    , 'TInventoryClass'),
         @InventoryClass3  = Record.Col.value('InventoryClass3[1]'    , 'TInventoryClass')
  from @InputXML.nodes('Root/Data') as Record(Col);

  select @Action       = Record.Col.value('Action[1]'                    , 'TAction'),
         @BusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @UserId       = Record.Col.value('(SessionInfo/UserId)[1]'      , 'TUserId')
  from @InputXML.nodes('Root') as Record(Col);

  /*---------------  Inventory Updates  -----------------*/

  /* Build data into hash table to transfer inventory from Picklanes to newly created LPNs
     Pass in only new LPN info as we only need to transfer inventory from Picklanes to newly created LPNs
     there wouldn't be any change in SKU or InventoryClass(es) */
  insert into #InventoryTransferInfo (LPNId, LPN, LPNDetailId, NewLPNId, NewLPN, SKUId, SKU, Quantity, InventoryClass1, InventoryClass2, InventoryClass3,
                                      PalletId, LocationId, Location, Ownership, Warehouse)
    select ITC.LPNId, ITC.LPN, ITC.LPNDetailId, CL.EntityId, CL.EntityKey, ITC.SKUId, ITC.SKU, @Quantity,
           @InventoryClass1, @InventoryClass2, @InventoryClass3, ITC.PalletId, ITC.LocationId, ITC.Location,
           @Ownership, @Warehouse
    from #InventoryToConsume ITC, #CreateLPNs CL;

  /* Invoke Proc to transfer inventory */
  exec pr_Inventory_BulkTransfer @ReasonCode, @Action, @BusinessUnit, @UserId;

  /*---------------  Locating LPNs and/or Pallets  -----------------*/

  /* Get the Staging location to drop the created LPNs */
  select top 1 @vDropLocationId = LocationId
  from Locations
  where (LocationType = 'S'/* Staging */) and
        (Warehouse    = @Warehouse)
  order by Status;  -- Empty Location comes first

  /* If there is a location to then drop them */
  if (@vDropLocationId is not null)
    begin
      select EntityId as LPNId into #LPNsToLocate from #CreateLPNs;

      /* Invoke proc to locate LPNs & associated pallets */
      exec pr_LPNs_Locate @vDropLocationId, @BusinessUnit, @UserId
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_CreateLPNs_TransferInventory */

Go
