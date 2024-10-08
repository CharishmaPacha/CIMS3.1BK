/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/03/22  VMG     Defer SortOrder updates to later stage (SRIV3-451)
  2023/01/31  VS      pr_Replenish_CreateReplenishWaves, pr_Replenish_GenerateOrdersForDynamicLocations,
  2022/11/21  TK      pr_Replenish_CreateReplenishWaves, pr_Replenish_GenerateOndemandOrders & pr_Replenish_GenerateOndemandOrders:
  2022/11/20  AY      pr_Replenish_CreateReplenishWaves: Temp fix to handle mulitple replenish waves (OBV3-1475)
  2022/07/20  VS      pr_Replenish_CreateReplenishWaves: pr_PickBatch_GenerateBatches proc is replaced with pr_Waves_Generate proc (CIMSV3-1812)
  2022/03/10  VS      pr_Replenish_CreateReplenishWaves: Create a new Replenish wave if exsiting replenish wave is already allocated (FBV3-970)
                      pr_Replenish_CreateReplenishWaves; Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Replenish_CreateReplenishWaves') is not null
  drop Procedure pr_Replenish_CreateReplenishWaves;
Go
/*------------------------------------------------------------------------------
  Proc pr_Replenish_CreateReplenishWaves: Creates Wave for the given Replenish Orders.

  Operation: Could be AutoReplenish, MinMax, OnDemand. Used to have different control
             options for each of these ways when replenishments would be generated.
------------------------------------------------------------------------------*/
Create Procedure pr_Replenish_CreateReplenishWaves
  (@OrdersToWave           TEntityKeysTable  ReadOnly,
   @Operation              TOperation,
   @BusinessUnit           TBusinessUnit,
   @UserId                 TUserId,
   @WaveNo                 TWaveNo   = null,
   @ReplenishWaveId        TRecordId = null output,
   @ReplenishWaveNo        TWaveNo   = null output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage               TMessage,
          @vDebug                 TFlags,

          @vWaveId                TRecordId,
          @vAccountName           TName,
          @vOrdersXML             TXML,

          @vCreateReplWave        TFlag,
          @vAddOrdersToPriorWaves TFlag,
          @vCreateIndependentReplWave
                                  TFlag;

begin /* pr_Replenish_CreateReplenishWave */
  /* Generate replenish batch based on Control Var */
  select @vCreateReplWave            = dbo.fn_Controls_GetAsBoolean(@Operation, 'Replenish_CreateWave',
                                                                    'Y' /* Yes */, @BusinessUnit, @UserId),
         @vAddOrdersToPriorWaves     = dbo.fn_Controls_GetAsBoolean(@Operation, 'Replenish_AddOrdersToPriorWaves',
                                                                    'N' /* No */, @BusinessUnit, @UserId),
         @vCreateIndependentReplWave = dbo.fn_Controls_GetAsBoolean(@Operation, 'Replenish_CreateIndependentReplWave',
                                                                    'N' /* No */, @BusinessUnit, @UserId);

  if (@vCreateReplWave <> 'Y'/* Yes */)
    return;

  exec pr_Debug_GetOptions @@ProcId, @Operation, @BusinessUnit, @vDebug output;

  /* If Replenish Wave is independent of Originale Wave then Generate a new one or create a wave similar to Original Wave with suffix 'R' */
  select @ReplenishWaveNo = case when (@vCreateIndependentReplWave = 'N'/* No */) then @WaveNo + 'R' /* Replenish Order */ else null end;

  if (charindex('D', @vDebug) > 0) select @ReplenishWaveNo ReplenishWave, * from @OrdersToWave;

  /* Build XML of list of orders to add to the Replenish wave */
  select @vOrdersXML = convert(varchar(max),
                               (select distinct EntityId as OrderId
                                from @OrdersToWave
                                FOR XML RAW('OrderHeader'), TYPE, ELEMENTS XSINIL, ROOT('Orders')));

  /* When no specific wave number has to be created, then use Generate Batches and let system create as many
     waves as needed based upon Ownership and Warehouse */
  if (@ReplenishWaveNo is null)
    begin
      exec pr_PickBatch_GenerateBatches @BusinessUnit, @UserId, null /* Rules */, @vOrdersXML, @vAddOrdersToPriorWaves;

      /* typically there is only one replenish order created, so get the associated Replenish wave created */
      select @ReplenishWaveId = Min(OH.PickBatchId),
             @ReplenishWaveNo = Min(OH.PickBatchNo)
      from @OrdersToWave OTW join OrderHeaders OH on OTW.EntityId = OH.OrderId
      group by OTW.RecordId;
    end
  else
    begin
      /* Create Batch with orginal wave number prefix with 'R' */
      if not exists(select * from PickBatches where BatchNo = @ReplenishWaveNo and BusinessUnit = @BusinessUnit)
        exec pr_PickBatch_CreateBatch 'RU'/* Replenish */, null /* Rules */, @BusinessUnit, @UserId,
                                      @ReplenishWaveNo output, @ReplenishWaveId output;

      /* Add orders to the created replenish wave */
      exec pr_PickBatch_AddOrders @ReplenishWaveNo, @vOrdersXML, 'OH' /* Order Headers (Waving Level) */,
                                  @BusinessUnit, @UserId, @vMessage output;

      /* Instead of having new param to pr_PickBatch_CreateBatch, we can achieve the same here by getting
         Original wave attributes and update to Replenish wave, hence, there will not be any datalayer changes required */
      update RW
      set AccountName = @vAccountName
      from PickBatches RW /* Replenish Wave */ join PickBatches OW /* Original Wave */ on (RW.BatchNo = OW.BatchNo)
      where (OW.BatchNo = @ReplenishWaveNo);
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Replenish_CreateReplenishWaves */

Go
