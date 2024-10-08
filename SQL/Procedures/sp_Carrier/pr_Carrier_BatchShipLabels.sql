/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  if object_id('dbo.pr_Carrier_BatchShipLabels') is null
  exec('Create Procedure pr_Carrier_BatchShipLabels as begin return; end')
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Carrier_BatchShipLabels') is not null
  drop Procedure pr_Carrier_BatchShipLabels;
Go
/*------------------------------------------------------------------------------
  Proc pr_Carrier_BatchShipLabels: The set of shiplabels to be inserted would be
    in #ShipLabelsToInsert and this procedure splits them into batches for
    further processing by DocumentProcessor (if required).
------------------------------------------------------------------------------*/
Create Procedure pr_Carrier_BatchShipLabels
  (@Module       TName,
   @Operation    TOperation,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vRecordId             TRecordId,

          @vRecordCount          TCount,
          @vNumBatches           TCount,
          @vMaxLabelsPerBatch    TInteger,
          @vNextProcessBatch     TBatch;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Exit if no labels to batch */
  if (object_id('tempdb..#ShipLabelsToInsert') is null) return;

  select @vRecordCount = count(*) from #ShipLabelsToInsert where (InsertRequired = 'Yes') and (CarrierInterface = 'CIMSSI');

  /* Exit if there aren't any labels being processed by CIMSSI */
  if (@vRecordCount = 0) return;

  /* Max labels to batch to generate labels */
  select @vMaxLabelsPerBatch = dbo.fn_Controls_GetAsInteger('GenerateShipLabels', 'MaxLabelsToGenerate', '200', @BusinessUnit, @UserId)

  /* Compute num batches to be created */
  select @vNumBatches = ceiling(@vRecordCount * 1.0 / @vMaxLabelsPerBatch)

  /* Get the next process batch */
  exec pr_Controls_GetNextSeqNo 'Seq_ShipLabels_ProcessBatch', @vNumBatches, @UserId, @BusinessUnit,
                                @vNextProcessBatch output;

  ;with LPNsToInsert as
  (
   select row_number() over (order by OrderId, RecordId) as RecordId, RecordId as SLRecordId
   from  #ShipLabelsToInsert
   where (InsertRequired = 'Yes') and (CarrierInterface = 'CIMSSI')
  )
  update SL
  set SL.ProcessBatch = @vNextProcessBatch + floor(LTI.RecordId * 1.0/ @vMaxLabelsPerBatch)
  from #ShipLabelsToInsert SL
    join LPNsToInsert LTI on (LTI.SLRecordId = SL.RecordId) and (InsertRequired = 'Yes') and (CarrierInterface = 'CIMSSI');

end /* pr_Carrier_BatchShipLabels */

Go
