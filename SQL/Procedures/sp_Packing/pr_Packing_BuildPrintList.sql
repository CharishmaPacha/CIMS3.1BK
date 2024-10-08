/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/13  TK      pr_Packing_CreateShipment: Initial Revision (BK-349)
                      pr_Packing_BuildPrintList: Initial Revision (BK-348)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_BuildPrintList') is not null
  drop Procedure pr_Packing_BuildPrintList;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_BuildPrintList: The entities to print are loaded into #EntitiesToPrint
    and this procedure builds the print list for those entities including the data
    or it would provide the EntitiesToPrint list (GeneratePrintListInput) for UI
    to generate the Printlist later.

  If @CreateShipment is 'ToBeCreated' then we will just generate the print list input and return so that
    UI will create shipment first and then build print list to print them
  If @CreateShipment is 'NotRequired' or 'Created' then we will build print list and return print list XML
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_BuildPrintList
  (@InputXML                TXML,
   @CreateShipment          TControlValue,
   @PrintListOutputXML      TXML     output,
   @GeneratePrintList       TFlags   output,
   @GeneratePrintListInput  TXML     output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vxmlInput               xml,
          @vSessionInfoXML         TXML,
          @vProcessPrintListInput  TXML;
begin /* pr_Packing_BuildPrintList */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode       = 0,
         @vMessageName      = null,
         @vxmlInput         = convert(xml, @InputXML),
         @GeneratePrintList = 'N';  -- By default

  /* Unless CreateShipment is ToBeCreated, then we can get the print list right away */
  if (@CreateShipment <> 'ToBeCreated')
    exec pr_Packing_GetPrintList @InputXML, @PrintListOutputXML out;

  /* If Print List XML is available then return */
  if (@PrintListOutputXML is not null) goto ExitHandler;

GeneratePrintList:
  /* Build the Input to be used by UI to re-generate the print list, when needed */

  /* Extract Session info from input xml */
  select @vSessionInfoXML = convert(varchar(max), @vxmlInput.query('Root/SessionInfo'));

  /* Build GeneratePrintList input */
  select @vProcessPrintListInput =  dbo.fn_XMLNode('Action', 'GeneratePrintList') +
                                      dbo.fn_XMLNode('Data',
                                        dbo.fn_XMLNode('Operation', 'Packing')) +
                                        dbo.fn_XMLNode('SelectedRecords',
                                          cast((select EntityType, EntityId, EntityKey from #EntitiesToPrint
                                                for xml raw('RecordDetails'), type, elements XSINIL, binary base64) as varchar(max)));

  select @GeneratePrintListInput =  dbo.fn_XMLNode('Root', coalesce(@vProcessPrintListInput, '') + coalesce(@vSessionInfoXML, ''));

  /* If we are here then we would have obtained Generate Print List Input so set generate PrintListFlag to 'Yes' */
  select @GeneratePrintList = 'Y';

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_BuildPrintList */

Go
