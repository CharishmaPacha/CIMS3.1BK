/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/11  SAK     pr_Waves_Action_GenerateWaves: Priority as changed to WavePriority in xmlGenerateWaveRules (HA-2018)
  pr_Waves_Action_GenerateWaves: Added new proc (HA-1403)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_Action_GenerateWaves') is not null
  drop Procedure pr_Waves_Action_GenerateWaves;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_Action_GenerateWaves:
   This proc is used to generate the waves for the selected orders
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_Action_GenerateWaves
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vMessage                   TVarchar,
          @vRecordId                  TRecordId,

          @vEntity                    TEntity,
          @vAction                    TAction,
          @vNumOrdersSelected         TCount,
          @vNumOrdersSkipped          TCount,
          @vxmlGenerateWaveRules      xml,
          @vGenerateWaveRules         TXML,
          @vAddOrdersToExistingWaves  TFlag,
          @vSelectedWavingRules       TVarchar;

  declare @ttWavesCreated Table
          (RecordId       TRecordId identity (1,1),
           WaveId         TRecordId,
           WaveNo         TWaveNo,
           WavePriority   TPriority,
           WaveStatus     TStatus);

  declare @ttSelectedWavingRules Table
    (RecordId      TRecordId identity (1,1) not null,
     RuleId        TRecordId);
begin /* pr_Waves_Action_GenerateWaves */
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vRecordId     = 0;

  /* Create hash table */
  if object_id('tempdb..#WavesCreated') is null select * into #WavesCreated from @ttWavesCreated;

  select @vEntity  = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction  = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)

  if (@vAction = 'GenerateWavesviaCustom')
    begin
      select @vAddOrdersToExistingWaves = Record.Col.value('AddToExistingWave[1]', 'TFlag')
      from @xmlData.nodes('/Root/Data') as Record(Col);

      select @vxmlGenerateWaveRules = (select 0 as RuleId,
                                              Record.Col.value('WaveType[1]',      'TLookupCode') BatchType,
                                              Record.Col.value('WavePriority[1]',  'TInteger')    BatchPriority,
                                              Record.Col.value('NewWaveStatus[1]', 'TLookupCode') BatchStatus,
                                              Record.Col.value('OrdersPerWave[1]', 'TInteger') MaxOrders,
                                              Record.Col.value('SKUsPerWave[1]',   'TInteger') MaxSKUs,
                                              Record.Col.value('LinesPerWave[1]',  'TInteger') MaxLines,
                                              Record.Col.value('UnitsPerWave[1]',  'TInteger') MaxUnits,
                                              0 as SortSeq
                                       from @xmlData.nodes('/Root/Data') as Record(Col)
                                       FOR XML RAW('BatchRule'), TYPE, ELEMENTS, ROOT('BatchRules')
                                       );
    end
  else
  if (@vAction in ('GenerateWavesviaRules', 'GenerateWavesviaSelectedRules'))
    begin
      select @vAddOrdersToExistingWaves = Record.Col.value('AddToExistingWave[1]', 'TFlag'),
             @vSelectedWavingRules      = Record.Col.value('SelectedRules[1]',     'TVarchar')
      from @xmlData.nodes('/Root/Data') as Record(Col);

      select @vGenerateWaveRules = null;
      if (@vSelectedWavingRules is not null)
        begin
          /* convert the CSV into a dataset */
          insert into @ttSelectedWavingRules (RuleId)
             select Value from dbo.fn_ConvertStringToDataSet(@vSelectedWavingRules, ',');

          select @vxmlGenerateWaveRules = (select *
                                           from vwBatchingRules BR
                                           join @ttSelectedWavingRules SWR on (SWR.RuleId = BR.RuleId)
                                           FOR XML RAW('BatchRule'), TYPE, ELEMENTS, ROOT('BatchRules')
                                           );
        end
    end

  if (@vxmlGenerateWaveRules is not null)
    select @vGenerateWaveRules = convert(varchar(max), @vxmlGenerateWaveRules);

  /* Generate waves for selected criteria */
  exec pr_PickBatch_GenerateBatches @BusinessUnit, @UserId, @vGenerateWaveRules /* Rules */,
                                    null /* Orders - in #ttSelectedEntities */, @vAddOrdersToExistingWaves,
                                    @vMessage output;

  /* Show the summary message in V3 UI */
  insert into #ResultMessages (MessageType, MessageText) select 'I' /* Info */, @vMessage;

  /* Get Info of num orders selected and num orders skipped */
  select @vNumOrdersSelected = (select count(distinct EntityId) from #ttSelectedEntities),
         @vNumOrdersSkipped  = (select count(distinct(TSE.EntityId))
                                from #ttSelectedEntities TSE
                                  join OrderHeaders      OH on (TSE.EntityId = OH.OrderId)
                                where (coalesce(OH.PickBatchNo, '') = ''));

  /* Show all the waves generated */
  insert into #ResultMessages (MessageType, MessageName, Value1, Value2)
    select 'I' /* Info */, 'Waves_Generate_Successful', min(W.WaveNo), min(W.NumOrders)
    from Waves W join #WavesCreated WC on (W.WaveId = WC.WaveId)
    group by WC.WaveNo

  /* If some waves were generated, then show the number of Orders not waved */
  if (@@rowcount > 0) and (@vNumOrdersSkipped > 0)
    insert into #ResultMessages (MessageType, MessageName, Value1, Value2)
      select 'I' /* Info */, 'Waves_Generate_SomeOrdersNotWaved', @vNumOrdersSkipped, @vNumOrdersSelected

  return(coalesce(@vReturnCode, 0));
end /* pr_Waves_Action_GenerateWaves */

Go
