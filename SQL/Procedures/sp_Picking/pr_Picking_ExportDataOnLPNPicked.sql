/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/05/28  TD      pr_Picking_OnPicked: Ignoring import and export to the srtLPNs if the destination of the
                         LPN is ShipDock, instead of that we are doing exports with pick transaction type.
                      pr_Picking_ConfirmUnitPick:Changes to update PickBatchNo, DestZone on the ToLPN.
                      pr_Picking_BatchPickResponse:Changes to to set PickType based on the task subtype.
                      Added pr_Picking_ExportDataOnLPNPicked.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ExportDataOnLPNPicked') is not null
  drop Procedure pr_Picking_ExportDataOnLPNPicked;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_ExportDataOnLPNPicked:

  Assumption: This procedure will only used for unit picking, becuase we will mark
              the LPNs as picked while dropping the picking pallet. So we need to call
              this procedure with updated LPNs.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_ExportDataOnLPNPicked
  (@PickBatchId      TRecordId,
   @LPNId            TRecordId,
   @PickedLPNs       TEntityKeysTable readonly,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode                 TInteger,

          @vBatchType                  TTypeCode,
          @vLPN                        TLPN,
          @vDestZone                   TZoneId,

          /* Controls */
          @vBatchTypeToExportToSorter  TControlvalue,
          @vBatchTypeToExportToRouter  TControlvalue;

begin /* pr_Picking_ExportDataOnLPNPicked */

  /* Get Batch info */
  select @vBatchType = BatchType
  from PickBatches
  where (RecordId = @PickBatchId)

  /* Get the control variables */
  select @vBatchTypeToExportToSorter = dbo.fn_Controls_GetAsString('Sorter', 'ExportLPN_' + @vBatchType,  'N' /* No */  , @BusinessUnit, @UserId),
         @vBatchTypeToExportToRouter = dbo.fn_Controls_GetAsString('Router', 'ExportLPN_' + @vBatchType,  'N' /* No */  , @BusinessUnit, @UserId);

  if (@vBatchTypeToExportToSorter <> 'N' /* No */)
    begin
      exec pr_Sorter_InsertLPNDetails @LPNId, @PickedLPNs, null /* Sorter Name */,
                                      @BusinessUnit, @UserId;

      /* Export the Picked LPNDetails to the Sorter if ExportToSorter is to be done on Picked */
      if (@vBatchTypeToExportToSorter in ('P' /* On Picked */))
        exec pr_Sorter_ExportLPNDetails @LPNId, null /* Sorter Name */, @BusinessUnit, @UserId;
    end

  /* Insert the Router Instruction into RouterInstruction table */
  --if (@vBatchTypeToExportToRouter in ('Y' /* Yes */, 'P' /* On Picked */))
  --  exec pr_Router_SendRouteInstruction @LPNId, null /* LPN */, @PickedLPNs,
  --                                      null /* Destination */, default /* WorkId */, 'N' /* @ForceExport */,
  --                                      @BusinessUnit, @UserId;
end /* pr_Picking_ExportDataOnLPNPicked */

Go
