/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/03/11  MS      pr_Cubing_AddCartonDetails: Bug fix to send BusinessUnit (BK-788)
  2021/03/28  TK      pr_Cubing_AddCartons, pr_Cubing_AddCartonDetails & pr_Cubing_Execute:
                        Code optimization for UCC barcode generation (HA-2471)
  2020/07/31  TD      pr_Cubing_AddCartonDetails: Performance changes (S2GCA-1215)
  2020/04/25  TK      pr_Cubing_AddCartonDetails, pr_Cubing_Execute, pr_Cubing_FindOptimalCarton:
                        Changes to cube either order details or task details & performance improvements
                      pr_Cubing_GetDetailsToCube: Initial Revision (HA-171)
  2019/10/07  TK      pr_Cubing_Execute, pr_Cubing_AddCartonDetails & pr_Cubing_FindAvailableCarton:
                        Performance improvements
                      pr_Cubing_PrepareToCubePicks & pr_Cubing_AddCartons: Initial Revision (CID-883)
  2018/09/18  TK      pr_Cubing_AddCartonDetails: Split line only for allocated task (S2GCA-285)
  2018/04/09  TK      pr_Cubing_AddCartonDetails & pr_Cubing_Execute: Changes to ignore canceled task details (S2G-568)
  2018/03/27  TK      pr_Cubing_AddCartonDetails: Changes to split LPN Detail as per TempLabel quantity (S2G-505)
  2018/03/15  TK      pr_Cubing_AddCartonDetails: Initial Revision (S2G-423)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Cubing_AddCartonDetails') is not null
  drop Procedure pr_Cubing_AddCartonDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Cubing_AddCartonDetails: This proc adds details to cubed cartons and if there are
    any task details which are cubed into multiple cartons then, splits task details accordingly
------------------------------------------------------------------------------*/
Create Procedure pr_Cubing_AddCartonDetails
  (@WaveId            TRecordId,
   @Operation         TOperation,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,

          @vRecordId                TRecordId,
          @vTempLabelId             TRecordId,
          @vTempLabel               TLPN,
          @vTempLabelDetailId       TRecordId,
          @vTempLabelQty            TQuantity,
          @vSKUId                   TRecordId,
          @vUnitsPerCase            TQuantity,

          @vTaskId                  TRecordId,
          @vTaskDetailId            TRecordId,
          @vTDStatus                TStatus,
          @vPickType                TTypeCode,
          @vTDInnerpacks            TInnerpacks,
          @vTDQuantity              TQuantity,
          @vWaveId                  TRecordId,
          @vWaveNo                  TWaveNo,
          @vOrderId                 TRecordId,
          @vOrderDetailId           TRecordId,
          @vDestZone                TZoneId,
          @vDestLocation            TLocation,
          @vFromLocationId          TRecordId,
          @vFromLPNId               TRecordId,
          @vFromLPNDetailId         TRecordId,
          @vSplitLPNDetailId        TRecordId,
          @vInputXML                TXML;

  declare @ttCubedDetails           TTaskInfoTable,
          @ttCreatedLPNDetails      TLPNDetails,
          @ttTempLabelsToRecount    TRecountKeysTable;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Create required hash tables */
  select * into #CreateLPNDetails from @ttCreatedLPNDetails;

  /* Get all the order details/task details that are cubed */
  insert into @ttCubedDetails(PickBatchId, PickBatchNo, TaskId, TaskDetailId, TDStatus, TDInnerPacks, TDQuantity, OrderId, OrderDetailId, LPNId, LPNDetailId,
                              LocationId, UnitsToAllocate, SKUId, CartonType, TempLabelId, TempLabel,
                              DestZone, DestLocation, PickType, LocationType, Processed)
    select DTC.WaveId, DTC.WaveNo, TD.TaskId, TD.TaskDetailId, TD.Status, TD.InnerPacks, TD.Quantity, DTC.OrderId, DTC.OrderDetailId, TD.LPNId, TD.LPNDetailId,
           TD.LocationId, CD.UnitsCubed, DTC.SKUId, CH.CartonType, CH.LPNId, CH.LPN,
           TD.DestZone, TD.DestLocation, TD.PickType, TD.LocationType, 'N' /* No */
    from #DetailsToCube DTC
                 join #CubeCartonDtls CD on (DTC.UniqueId = CD.UniqueId)
                 join #CubeCartonHdrs CH on (CD.CartonId = CH.CartonId)
      left outer join TaskDetails     TD on (DTC.TaskDetailId = TD.TaskDetailId)
    order by DTC.RecordId;

  /* If we cubing order details or whole task detail is being cubed into single ship carton then
     just insert those details into #CreateLPNDetails table, mark those details as processed and
     invoke LPNs_CreateLPNs procedure which inserts LPN Details for all the ship cartons created earlier */
  update ttCD
  set Processed = 'Y' /* Yes */
  output Inserted.TempLabelId, Inserted.TempLabel, 'U'/* OnhandStatus */, Inserted.SKUId, Inserted.UnitsToAllocate /* UnitsCubed */,
         Inserted.OrderId, Inserted.OrderDetailId, Inserted.RecordId, @BusinessUnit, @UserId
  into #CreateLPNDetails (LPNId, LPN, OnhandStatus, SKUId, Quantity, OrderId, OrderDetailId, Reference, BusinessUnit, CreatedBy)
  from @ttCubedDetails ttCD
  where (TaskDetailId is null) or (UnitsToAllocate >= TDQuantity);

  /* If there exists records in CreateLPNDetails then just invoke CreateLPNs procedure
     which will create/insert LPN Details for generated ship cartons */
  if exists (select * from #CreateLPNDetails)
    begin
      select @vInputXML = dbo.fn_XMLNode('Root',
                            dbo.fn_XMLNode('Data',
                              dbo.fn_XMLNode('Operation',   @Operation)) +
                            dbo.fn_XMLNode('SessionInfo',
                              dbo.fn_XMLNode('BusinessUnit',   @BusinessUnit)));

      exec pr_LPNs_CreateLPNs @vInputXML;
    end

   /* Update Task Details with the TempLabel info for the records that are processed above */
   update TD
   set TempLabel         = CLD.LPN,
       TempLabelId       = CLD.LPNId,
       TempLabelDetailId = CLD.LPNDetailId
   from TaskDetails TD
     join @ttCubedDetails   ttCD on (TD.TaskDetailId = ttCD.TaskDetailId)
     join #CreateLPNDetails CLD  on (ttCD.RecordId   = CLD.Reference)
   where (ttCD.Processed = 'Y'/* Yes */);

  /* Generate LPN details for temp labels created and assign them to tasks */
  while exists(select * from @ttCubedDetails where RecordId > @vRecordId and Processed = 'N' /* No */)
     begin
       select top 1 @vRecordId        = RecordId,
                    @vTempLabelId     = TempLabelId,
                    @vTempLabel       = TempLabel,
                    @vTempLabelQty    = UnitsToAllocate,
                    @vSKUId           = SKUId,
                    @vTaskId          = TaskId,
                    @vTaskDetailId    = TaskDetailId,
                    @vTDStatus        = TDStatus,
                    @vPickType        = PickType,
                    @vWaveId          = PickBatchId,
                    @vWaveNo          = PickBatchNo,
                    @vOrderId         = OrderId,
                    @vOrderDetailId   = OrderDetailId,
                    @vDestZone        = DestZone,
                    @vDestLocation    = DestLocation,
                    @vFromLocationId  = LocationId,
                    @vFromLPNId       = LPNId,
                    @vFromLPNDetailId = LPNDetailId
       from @ttCubedDetails
       where (RecordId > @vRecordId) and
             (Processed = 'N' /* No */)
       order by RecordId;

       /* Add SKUs to each temp Label */
       exec pr_LPNDetails_AddOrUpdate @vTempLabelId, null /* LPNLine */, null /* CoO */,
                                      @vSKUId, null /* SKU */, null /* innerpacks */, @vTempLabelQty,
                                      0 /* ReceivedUnits */, null /* ReceiptId */, null /* ReceiptDetailId */,
                                      @vOrderId, @vOrderDetailId, 'U' /* OnhandStatus */, 'Cubing' /* Operation */,
                                      null /* Weight */, null /* Volume */, null /* Lot */,
                                      @BusinessUnit /* BusinessUnit */, @vTempLabelDetailId  output;

       /* Get the quantity on parent task detail */
       select @vTDQuantity   = Quantity,
              @vUnitsPerCase = case when (Innerpacks > 0) then floor(Quantity/Innerpacks) else 0 end
       from TaskDetails
       where (TaskDetailId = @vTaskDetailId);

       /* There may be a chance that single task detail can be cubed into multiple cartons
          if so, split task details */
       if (@vTempLabelQty < @vTDQuantity)
         begin
           /* Evaluate innerpacks for new line */
           select @vTDInnerPacks = case
                                     when (@vPickType = 'CS') and (@vUnitsPerCase > 0)
                                       then @vTempLabelQty/@vUnitsPerCase
                                     else 0
                                   end;

           /* Invoke TaskDetails_SplitDetail which splits TaskDetail, FromLPN & LPNTask wherever needed */
           exec pr_TaskDetails_SplitDetail @vTaskDetailId, @vTDInnerPacks, @vTempLabelQty,
                                           default /* Operation */, @BusinessUnit, @UserId,
                                           @vTaskDetailId output
         end

        /* Update Task Details with the TempLabel DetailId */
        update TaskDetails
        set TempLabel         = @vTempLabel,
            TempLabelId       = @vTempLabelId,
            TempLabelDetailId = @vTempLabelDetailId
         where (TaskDetailId = @vTaskDetailId);

       /* Update the record as processed */
       update @ttCubedDetails
       set Processed = 'Y'/* Yes */
       where (RecordId = @vRecordId);

       /* Reset LPN DetailId so that it will add new line everytime */
       select @vTempLabelDetailId = null,
              @vSplitLPNDetailId  = null;
     end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Cubing_AddCartonDetails */

Go
