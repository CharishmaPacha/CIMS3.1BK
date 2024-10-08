/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/31  AY      pr_Waves_Rpt_GetSKUSummaryData: Changed to use TWaveSummary (HA-1353)
  2020/08/10  NB      pr_Waves_Rpt_GetSKUSummaryData: changes to procedure for V3 Reports_GetData generic implementation(CIMSV3-1022)
  2020/08/04  MS      pr_Waves_Rpt_GetSKUSummaryData: Added new proc to print WaveSummary Report (HA-1262)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_Rpt_GetSKUSummaryData') is not null
  drop Procedure pr_Waves_Rpt_GetSKUSummaryData;
Go
/*------------------------------------------------------------------------------
Proc pr_Waves_Rpt_GetSKUSummaryData: Returns the data set for the WaveSKUSummary
  report with the Wave header info and Details being the SKU Summary

xmlWaveSummary:
  <REPORTS>
    <WaveSKUSummaryReport>
      <WaveHeader>
        <RecordId>29</RecordId>
        <WaveId>29</WaveId>
        <WaveNo>200508001</WaveNo>
      </WaveHeader>
      <WaveSKUSummaryDetails>
        <SKUId>23162</SKUId>
        <SKU>884411543987</SKU>
        <SKU1>GW2418BB</SKU1>
        <SKU2>BLUPK</SKU2>
        <SKU3>6/6X</SKU3>
        .......
      </WaveSKUSummaryDetails>
      <WaveSKUSummaryDetails>
        <SKUId>23162</SKUId>
        <SKU>884411543987</SKU>
        <SKU1>GW2418BB</SKU1>
        <SKU2>BLUPK</SKU2>
        <SKU3>6/6X</SKU3>
         ....
      </WaveSKUSummaryDetails>
    </WaveSKUSummaryReport>
  </REPORTS>
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_Rpt_GetSKUSummaryData
  (@xmlInput          xml,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @xmlResult         xml output)
as
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @WaveId                     TRecordId,
          @vWaveId                    TRecordId,
          @vWaveNo                    TWaveNo,
          @vWaveHeaderXML             TXML,
          @vWaveSKUSummaryDetailsXML  TXML,
          @xmlWaveSummary             TXML;

  declare @ttWaveSummaryData TWaveSummary; -- Table Variable for output
begin /* pr_Waves_Rpt_GetSKUSummaryData */

  select @vReturnCode  = 0,
         @vMessageName = null;

  select @WaveId = Record.Col.value('EntityId[1]', 'TRecordId')
  from @xmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlInput = null ));

  select @vWaveId = WaveId,
         @vWaveNo = WaveNo
  from Waves
  where (WaveId = @WaveId);

  if (@vWaveId is null)
    set @vMessageName = 'WaveIsInvalid';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Create Temp Table to hold result set */
  select * into #ResultDataSet from @ttWaveSummaryData;

  select @vWaveHeaderXML  = (select *
                             from vwWaves
                             where (WaveId = @WaveId)
                             for xml raw('WaveHeader'), elements);

  /* Get the summary by SKU */
  exec pr_Wave_GetSummary @vWaveId, @vWaveNo, 'Y' /* Save To TempTable */;

  select @vWaveSKUSummaryDetailsXML = (select * from #ResultDataSet
                                       for xml raw('WaveSKUSummaryDetails'), elements);

  select @xmlWaveSummary  = dbo.fn_XMLNode('REPORTS',
                              dbo.fn_XMLNode('WaveSKUSummaryReport',
                                coalesce (@vWaveHeaderXML,  '') +
                                coalesce (@vWaveSKUSummaryDetailsXML, '')));

  select @xmlResult = cast(@xmlWaveSummary as xml);
  return(coalesce(@vReturnCode, 0));
end /* pr_Waves_Rpt_GetSKUSummaryData */

Go
