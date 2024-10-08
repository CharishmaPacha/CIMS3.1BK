/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/24  RKC     pr_UI_DS_WaveSummary: Get the WaveNo using MasterSelectionFilters values if it is for EntityInfo (HA-2381)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_UI_DS_WaveSummary') is not null
  drop Procedure pr_UI_DS_WaveSummary;
Go
/*------------------------------------------------------------------------------
  Procedure pr_UI_DS_WaveSummary
    Datasource procedure for Wave Summary Listing
------------------------------------------------------------------------------*/
Create Procedure pr_UI_DS_WaveSummary
  (@xmlInput     XML,
   @OutputXML    TXML = null output)
as
  declare @vEntityDetailXML               xml,
          @vMenuCaption                   TName,
          /* pr_Wave_GetSummary inputs */
          @vWaveNo                        TWaveNo,
          @ttInputSelectionFilters        TSelectionFilters;

begin /* pr_UI_DS_WaveSummary */

  /* fetch the inputs for pr_Wave_GetSummary procedure */
  select @vWaveNo      = Record.Col.value('(Data/WaveNo)[1]',          'TWaveNo'),
         @vMenuCaption = Record.Col.value('(EntityDetail/Caption)[1]', 'TName')
  from @xmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlInput = null ));

  /* If Wave no is null from Data/WaveNo (ListLink), it could be for EntityInfo. If so, get the WaveNo based on the MasterSelectionFilter nodes */
  if (@vWaveNo is null)
    begin
      insert into @ttInputSelectionFilters(FieldName,  FilterValue)
        select Record.Col.value('(MasterSelectionFilters/Filter/FieldName)[1]',       'TName'),
               Record.Col.value('(MasterSelectionFilters/Filter/FilterValue)[1]',     'TName')
      from @xmlInput.nodes('/Root') as Record(Col)
      OPTION ( OPTIMIZE FOR ( @xmlInput = null));

      select @vWaveNo = WaveNo
      from Waves W
        join @ttInputSelectionFilters ttS on (W.WaveId = tts.FilterValue) and
                                             ((tts.FieldName = 'WaveId') or (tts.FieldName = 'BatchId'));
    end

  exec pr_Wave_GetSummary null, @vWaveNo, 'Y' /* Save To TempTable */;

  /* Build Entity Detail Menu Caption, for the UI to show relevant caption */
  if (charindex(@vWaveNo, @vMenuCaption) <= 0)
    select @vMenuCaption = @vMenuCaption + ' for Wave ' + @vWaveNo;

  select @vEntityDetailXML = (select @vMenuCaption Caption for xml raw('EntityDetail'), elements);

  /* Build Result XML */
  select @OutputXML = coalesce(convert(varchar(max), @vEntityDetailXML), '');
end  /* pr_UI_DS_WaveSummary */

Go
