/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/09  AY      pr_LPNs_Unallocate: Revert LPNType to C when unallocated (HA-2581)
  2021/02/04  VS      pr_LPNs_Unallocate: Added parameter as default for temptable (BK-126)
  2018/05/23  MJ      pr_LPNs_Unallocate: Changed the callers based on the recent parameters (S2G-443)
  2017/03/08  SV      pr_LPNs_Unallocate: Need to void the ShipLabels for the LPNs in which we unallocate (HPI-846)
  2016/12/20  SV      pr_LPNs_Unallocate: Cleaning up the TaskId over the LPN once it is UnAllocated (HPI-1200)
  2016/06/16  NY      pr_LPNs_Unallocate: Recalculate Pallet counts to reset PickbatchId on Pallet (FB-703)
  2015/11/19  OK      pr_LPNs_Unallocate: Made changes to update wave number after un allocation all the LPNs on the pallet (FB-513)
  2015/10/15  RV      pr_LPNs_Unallocate: Cancel the task if pallet pick.
                      pr_LPNs_Lost: Modified procedure to handle as flag changes in pr_LPNs_Unallocate.
                      pr_LPNs_Modify: Modified procedure to handle as flag changes in pr_LPNs_Unallocate.
                      pr_LPNs_Void: Modified procedure to handle as flag changes in pr_LPNs_Unallocate (FB-441).
                      pr_LPNs_Unallocate: Cancel the task if pallet pick (FB-427)
  2015/07/30  AY      pr_LPNs_Unallocate: Change to skip export to Panda based upon LPN Warehouse
  2014/03/25  NY      pr_LPNs_Unallocate : Recalculate LPN Counts.(xsc-524)
  2013/10/02  TD      Added pr_LPNs_UnallocateLine
  2013/02/27  YA      pr_LPNs_Lost: Modified procedure to handle as signature changes in pr_LPNs_Unallocate.
  2013/02/26  YA      pr_LPNs_Unallocate: Unallocate pallet on unallocating LPN(s).
  2012/10/20  NY      pr_LPNs_Unallocate: Implemented AuditTrail for UnallocateLPN
  2012/10/16  AA      pr_LPNs_Unallocate: added call to pr_PandA_UpdateLPNs to update Label Data, Export Status
  2012/10/09  VM      pr_LPNs_Unallocate: Set PackageSeqNo to null instead of zero
              AY      pr_LPNs_Unallocate: Clear Shipping info when Unallocated
  2012/10/01  AA      pr_LPNs_Unallocate: fixed passing incorrect variable to pr_LPNs_SetStatus procedure
              AY      pr_LPNs_Unallocate: Reset LPN's Onhand status back to Available.
  2012/08/22  PK      Added pr_LPNs_Unallocate
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Unallocate') is not null
  drop Procedure pr_LPNs_Unallocate;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Unallocate: Unallocate an LPN associated with an Order
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Unallocate
  (@LPNId          TRecordId,
   @LPNsToUpdate   TEntityKeysTable readonly,
   @UnallocPallet  TFlag = 'N' /* No */,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId = null)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TMessageName,

          @vRecordId         TRecordId,
          @vPalletId         TRecordId,
          @vLPNId            TRecordId,
          @vLPN              TLPN,
          @vLPNDetailId      TRecordId,
          @vQuantity         TQuantity,
          @vOrderId          TRecordId,
          @vOrderDetailId    TRecordId,
          @vTaskDetailId     TRecordId,
          @vLPNWarehouse     TWarehouse,

          @vOrderTypesToExportToPanda  TControlvalue,
          @vWarehousesToExportToPanda  TControlvalue,

          @ttPalletsToRecount    TRecountKeysTable,
          @ttOrdersToRecount     TEntityKeysTable,
          @ttLPNOnPallets        TEntityKeysTable,
          @ttPalletsToUnallocate TEntityKeysTable;

  declare @ttLPNs Table
          (RecordId             TRecordId  identity (1,1),
           PalletId             TRecordId,
           LPNId                TRecordId,
           LPN                  TLPN,
           LPNDetailId          TRecordId,
           Quantity             TQuantity,
           OrderId              TRecordId,
           OrderDetailId        TRecordId,
           LPNWarehouse         TWarehouse,
           Processed            TFlag      default 'N');

begin /* pr_LPNs_Unallocate */
  select @vReturnCode     = 0,
         @vMessageName    = null;

  select @vOrderTypesToExportToPanda = dbo.fn_Controls_GetAsString('Panda',  'OrderTypesToExport', ''  /* None */, @BusinessUnit, @UserId),
         @vWarehousesToExportToPanda = dbo.fn_Controls_GetAsString('Panda',  'WarehousesToExport', ''  /* None */, @BusinessUnit, @UserId);

  if (@LPNId is not null)
    /* Insert the Pallet Details into temp table to clear the Order Info on the LPNs */
    insert into @ttLPNs (PalletId, LPNId, LPN, LPNDetailId, Quantity, OrderId, OrderDetailId, LPNWarehouse)
      select PalletId, LPNId, LPN, LPNDetailId, Quantity, OrderId, OrderDetailId, DestWarehouse
      from vwLPNDetails
      where (LPNId = @LPNId) and (OrderId is not null);
  else
    /* Insert the Pallet Details into temp table to clear the Order Info on the LPNs */
    insert into @ttLPNs (PalletId, LPNId, LPN, LPNDetailId, Quantity, OrderId, OrderDetailId, LPNWarehouse)
      select PalletId, LPNId, LPN, LPNDetailId, Quantity, OrderId, OrderDetailId, DestWarehouse
      from vwLPNDetails LD join @LPNsToUpdate LU on LD.LPNId = LU.EntityId
      where (OrderId is not null);

  /* If a Pallet has been allocated and if an attempt is being made to unallocate
     some LPNs on the pallet, then we may want to unallocate the entire pallet
     as the Pallet would have some allocted LPNs and some PA LPNs making it
     ineligible for Pallet Picking */
  if (@UnallocPallet in ('A' /* Always */,'P' /* PalletPick only */))
    begin
      /* Fetch the pallets which are allocated on the above LPNs */
      insert into @ttPalletsToUnallocate (EntityId)
        select distinct(L.PalletId)
        from @ttLPNs L join Pallets P on (L.PalletId = P.PalletId)
                       join Locations LOC on (P.LocationId = LOC.LocationId)
        where (P.Status         = 'A'/* Allocated */) and
              (LOC.LocationType = 'R'/* Reserve */);

      /* Fetch all LPNs on these Pallets, which are not already in the list */
      insert into @ttLPNOnPallets(EntityId)
        select distinct L.LPNId
        from LPNs L join @ttPalletsToUnallocate PUA on L.PalletId = PUA.EntityId
        except
        select LPNId
        from @ttLPNs;

      /* Insert all these LPNs to unallocate */
      insert into @ttLPNs (PalletId, LPNId, LPN, LPNDetailId, Quantity, OrderId, OrderDetailId, LPNWarehouse)
        select PalletId, LPNId, LPN, LPNDetailId, Quantity, OrderId, OrderDetailId, DestWarehouse
        from vwLPNDetails LD join @ttLPNOnPallets LU on LD.LPNId = LU.EntityId
        where (OrderId is not null);
    end

  /* begin Loop */
  while (exists (select *
                 from @ttLPNs
                 where Processed = 'N'/* No */))
    begin
      /* Get the top 1 LPN info on the Pallet */
      select top 1 @vRecordId      = RecordId,
                   @vPalletId      = PalletId,
                   @vLPNId         = LPNId,
                   @vLPN           = LPN,
                   @vLPNDetailId   = LPNDetailId,
                   @vQuantity      = Quantity,
                   @vOrderId       = OrderId,
                   @vOrderDetailId = OrderDetailId,
                   @vLPNWarehouse  = LPNWarehouse
      from @ttLPNs
      where Processed = 'N';

      exec pr_LPNDetails_Unallocate @vLPNId, @vLPNDetailId, @UserId;

      /* We need to Void the ShipLabels for the LPNs whose labels already got generated.
         There is a question that once after voiding the Labels, how does these void change gets
           updated at the small package service end. Will be having a discussion with AY on this */
      if (exists(select EntityKey from ShipLabels where EntityKey = @vLPN and Status = 'A'))
        exec pr_Shipping_VoidShipLabels null /* OrderId */, @vLPNId, default, @BusinessUnit, default /* RegenerateLabel - No */, @vMessage;

      /* Once LPN is unallocated, user may think that TaskId exists over the LPN and hence will not
         be available for other Orders. So,cleaning up the TaskId over the LPN once it is UnAllocated */
      update LPNs
      set TaskId  = null,
          LPNType = case when ReservedQty = 0 and LPNType = 'S' then 'C' else LPNType end
      where (LPNId = @vLPNId);

      /* Why - to  recalc reserved qty on LPN */
      exec pr_LPNs_Recount @vLPNId;

      /* Update LabelData, ExportStatus in PandaLabels */
      if (charindex(@vLPNWarehouse, @vWarehousesToExportToPanda) > 0)
        exec pr_PandA_UpdateLPNs @vLPN,
                                 default /* TEntityKeysTable */,
                                 null    /* Label Data       */,
                                 'U'     /* ExportStatus - (U)nallocated */,
                                 @BusinessUnit, @UserId;

      if (@vPalletId is not null) and (not exists(select * from @ttPalletsToRecount where EntityId = @vPalletId))
        insert into @ttPalletsToRecount (EntityId) select @vPalletId;

      if (not exists(select * from @ttOrdersToRecount where EntityId = @vOrderId))
        insert into @ttOrdersToRecount (EntityId) select @vOrderId;

      /* Update the LPN as processed */
      delete from @ttLPNs
      where (RecordId = @vRecordId);
    end

  /* Reset the value */
  select @vRecordId = 0;

  /* As the pallet pick task details would hold PalletId (not LPNId), need to explicitly cancel Pallet tasks.
  So, find it out and cancel only when UnallocPallet = 'Y' or 'A' */
  while (exists(select * from @ttPalletsToUnallocate where RecordId > @vRecordId))
    begin
      select @vTaskDetailId = null;

      /* select top 1 here */
      select top 1 @vPalletId = EntityId,
                   @vRecordId = RecordId
      from @ttPalletsToUnallocate
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Get the TaskId and TaskDetailId on the Pallet */
      select @vTaskDetailId = TaskDetailId
      from TaskDetails TD
           left outer join Tasks T on (TD.TaskId = T.TaskId)
      where (TD.PalletId    = @vPalletId) and
            ((T.TaskSubType = 'P' /* PalletPick */ and @UnallocPallet  = 'P' /*PalletPick only*/ ) or
            @UnallocPallet  = 'A' /* Always */)

      if (@vTaskDetailId is not null)
        exec pr_TaskDetails_Close @vTaskDetailId, null , @UserId, null /* Operation */;
    end

  /* Update the WaveNo to null on the pallet after unallocating all the LPNs on it */
  update Pallets
  set PickBatchId = 0,
      PickBatchNo = null
  from Pallets P
  join @ttPalletsToUnallocate PU on (P.PalletId = PU.EntityId);

  exec pr_Pallets_Recalculate @ttPalletsToRecount, 'CS' /* Recalculate Counts & Status */, @BusinessUnit, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Unallocate */

Go
