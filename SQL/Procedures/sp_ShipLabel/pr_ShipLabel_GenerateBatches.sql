/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/04/07  TD      pr_ShipLabel_GenerateBatches:Changes to not process the same record every time (BK-1041)
  2021/05/25  OK      pr_ShipLabel_GenerateBatches: Changes to reset the ShipLabel process statis if process status is stuck in GI
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GenerateBatches') is not null
  drop Procedure pr_ShipLabel_GenerateBatches;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GenerateBatches:
    If Process Batch is Zero and Records exists then we need to generate New process batch for those records
    So many places we are inserting the Records into Shiplabels table with process batch as Zero
    From Allocation process we are computing the process batch but some other process we are not compluting the Process Batch
    for this case we need to Generate new process batch and need to update the records which have Process Batch as Zero
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GenerateBatches
 (@BusinessUnit       TBusinessUnit,
  @UserId             TUserId)
as
  declare @vReturnCode                      TInteger,
          @vMessageName                     TMessageName,

          @vNextBatchToProcess              TBatch,
          @vRecordCount                     TInteger,
          @vMaxLabelsPerBatch               TInteger,
          @vBatchesToGenerate               TInteger,
          @vThresholdTimeToRegenerateLabel  TInteger;
begin
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null;

  select @vMaxLabelsPerBatch              = dbo.fn_Controls_GetAsInteger('GenerateShipLabels', 'MaxLabelsToGenerate', '200', @BusinessUnit, @UserId),
         @vThresholdTimeToRegenerateLabel = dbo.fn_Controls_GetAsInteger('GenerateShipLabels', 'ThresholdTimeToRegenerate', '15' /* mins */, @BusinessUnit, @UserId);

  /* First update the Shiplabels status to N for which status is stuck in GI from more than threshold time. So that those will be processed again */
  /* TD-0407- It is creating issus with USPS, since we are trying to hit the USPS everyt time */
  /* update ShipLabels
     set ProcessStatus = 'N',
         ModifiedDate  = current_timestamp
     where (ProcessStatus = 'GI') and
           (datediff(mi, ModifiedDate, getdate()) > @vThresholdTimeToRegenerateLabel); */

  /* Verify if there are records to be procesed but without a batch */
  select @vRecordCount = count(*)
  from ShipLabels
  where (ProcessStatus = 'N' /* Not Yet Processed */) and
        (Status        = 'A' /* Active */) and
        (BusinessUnit  = @Businessunit) and
        (ProcessBatch = 0);

  /* If there are no records, then exit */
  if (@vRecordCount = 0) return;

  select @vBatchesToGenerate = ceiling(@vRecordCount * 1.0 / @vMaxLabelsPerBatch);

  /* Get the next process batch(es)  */
  exec pr_Sequence_GetNext 'Seq_ShipLabels_ProcessBatch', @vBatchesToGenerate, @UserId, @BusinessUnit, @vNextBatchToProcess output;

  /* Update the New process batch on the Process batch as Zero or null and not yet processed Records */
  ;with SLBatches as
  (
    select RecordId, (row_number() over(order by RecordId) / @vMaxLabelsPerBatch) BatchIndex
    from ShipLabels
    where (ProcessStatus = 'N' /* Not Yet Processed */) and
          (Status        = 'A' /* Active */) and
          (BusinessUnit  = @Businessunit) and
          (ProcessBatch  = 0)
  )
  update SL
  set ProcessBatch = @vNextBatchToProcess + SLB.BatchIndex
  from ShipLabels SL join SLBatches SLB on (SL.RecordId = SLB.RecordId);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ShipLabel_GenerateBatches */

Go
