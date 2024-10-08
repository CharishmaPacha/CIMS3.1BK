/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/04/26  OK      pr_Exports_ExportGenericDataSet: Enhanced to send the ItemMasterData (S2G-614)
  2018/02/14  DK      pr_Exports_ExportGenericDataSet: Enhanced to support RouterInstructions_FW (S2G-232)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_ExportGenericDataSet') is not null
  drop Procedure pr_Exports_ExportGenericDataSet;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_ExportGenericDataSet: procedure to export a generic dataset which DI
    may use to write to a file.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_ExportGenericDataSet
  (@xmlInput      TXML,
   @xmlResult     XML           = null output)
as
  declare @vReturnCode  TInteger = 0,
          @MessageName  TMessageName,

          @vDataSet     TName,
          @xmlData      xml;
begin
  /* Extracting data elements from XML. */
  set @xmlData = convert(xml, @xmlInput);

  select @vDataSet = Record.Col.value('DataSet[1]', 'TName')
  from @xmlData.nodes('/Root') as Record(Col);

  /* Routing the execution to the corresponding procedure based on Entity and Action */
  if (@vDataSet = 'WaveDetails_FW')
    exec @vReturnCode = pr_Sorter_ExportWaveDetails_FW @xmlData, @xmlResult output;
  else
  if (@vDataSet = 'RouterInstructions_FW')
    exec @vReturnCode = pr_Router_ExportInstructions_FW @xmlData, @xmlResult output;
  else
  if (@vDataSet = 'ItemMasterData_FW')
    exec @vReturnCode = pr_SKUs_ExportSKUs_FW @xmlData, @xmlResult output;

ErrorHandler:
  if (@MessageName is not null)
    begin
      select @MessageName = dbo.fn_Messages_GetDescription(@MessageName),
             @vReturnCode = 1;
      raiserror(@MessageName, 16, 1);
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_ExportGenericDataSet */

Go
