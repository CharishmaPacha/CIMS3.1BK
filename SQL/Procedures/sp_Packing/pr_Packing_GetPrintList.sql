/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/20  RV      pr_Packing_ClosePackage, pr_Packing_GetPrintList: Made changes to return the SPL notifications
  2021/12/17  RV      pr_Packing_GetPrintList: calling EntitiesToPrint_Finalize before print list process (OB2-2240)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_GetPrintList') is not null
  drop Procedure pr_Packing_GetPrintList;
Go
/*------------------------------------------------------------------------------
  pr_Packing_GetPrintList: Given thee input for #EntitiesToPrint, it will process
    and generate the #PrintList and return the results i.e. the documents to print
    along with the data.

  Print list can only be determined completely after the create shipment has happened.
  So, if we use CLR and create shipment can happen in ClosePackage and then the print
  list is ready. On the other hand, if CLR is not used, then create shipment is done
  by UI after which it invokes this procedure to get the print list.

  Usage: This is used indirectly by ClosePackage (by BuildPrintList) or directly by UI
  after creating the shipment using the EntitiesToPrint given by ClosePackage.
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_GetPrintList
  (@InputXML     TXML,
   @PrintListXML TXML output,
   @ResultXML    TXML = null output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vxmlInputXML           xml,
          @vEntity                TEntity,
          @vRulesDataXML          TXML,
          @vAction                TAction,
          @vOperation             TOperation,
          @vDeviceId              TDeviceId,
          @vUserId                TUserId,
          @vBusinessUnit          TBusinessUnit,
          @vRuleSetType           TRuleSetType,
          @vPrintListXML          TXML,
          @vLabelPrinterName      TName,
          @vReportPrinterName     TName;

  declare @ttSelectedEntities     TEntityValuesTable,
          @ttEntitiesToPrint      TEntitiesToPrint,
          @ttPrintList            TPrintList;
begin /* pr_Packing_GetPrintList */

  /* Convert string to xml to parse */
  select @vxmlInputXML = convert(xml, @InputXML),
         @PrintListXML    = null;

  select @vEntity            = Record.Col.value('Entity[1]',                              'TEntity'),
         @vAction            = Record.Col.value('Action[1]',                              'TAction'),
         @vUserId            = Record.Col.value('(SessionInfo/UserId)[1]',                'TUserId'),
         @vDeviceId          = Record.Col.value('(SessionInfo/DeviceId)[1]',              'TDeviceId'),
         @vBusinessUnit      = Record.Col.value('(SessionInfo/BusinessUnit)[1]',          'TBusinessUnit'),
         @vLabelPrinterName  = Record.Col.value('(SessionInfo/DeviceLabelPrinter)[1]',    'TName'),
         @vReportPrinterName = Record.Col.value('(SessionInfo/DeviceDocumentPrinter)[1]', 'TName'),
         @vOperation         = Record.Col.value('(Data/Operation)[1]',                    'TOperation')
  from @vxmlInputXML.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlInputXML = null ) );

  select * into #ttSelectedEntities from @ttSelectedEntities;
  if (object_id('tempdb..#EntitiesToPrint') is null) select * into #EntitiesToPrint from @ttEntitiesToPrint;
  select * into #PrintList from @ttPrintList;

  /* If #EntitiesToPrint is not passed in, then build it form the input XML */
  if (not exists(select * from #EntitiesToPrint))
    begin
      insert into #EntitiesToPrint(EntityType, EntityId, EntityKey, RecordId)
      select Record.Col.value('EntityType[1]', 'TEntity'),
             Record.Col.value('EntityId[1]',   'TRecordId'),
             Record.Col.value('EntityKey[1]',  'TEntityKey'),
             row_number() over (order by (select 2))
      from @vxmlInputXML.nodes('/Root/SelectedRecords/RecordDetails') as Record(Col);

      update #EntitiesToPrint
      set OrderId = EntityId
      where EntityType = 'Order';

      update ETP
      set OrderId = L.OrderId
      from #EntitiesToPrint ETP join LPNs L on ETP.EntityType = 'LPN' and ETP.EntityId = L.LPNId;
    end /* if not exists #EntitiesToPrint */

  /* Update required info on EntitiesToPrint */
  update ETP
  set PickTicket            = OH.PickTicket,
      OrderType             = OH.OrderType,
      OrderStatus           = OH.Status,
      WaveId                = OH.PickBatchId,
      WaveNo                = OH.PickBatchNo,
      Warehouse             = OH.Warehouse,
      ShipVia               = OH.ShipVia,
      Carrier               = SV.Carrier,
      IsSmallPackageCarrier = SV.IsSmallPackageCarrier,
      SourceSystem          = OH.SourceSystem
   from #EntitiesToPrint ETP
     join OrderHeaders OH on (ETP.OrderId = OH.OrderId)
     join ShipVias     SV on (OH.ShipVia = SV.ShipVia) and (OH.BusinessUnit = SV.BusinessUnit);

  select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('Operation',         @vOperation) +
                            dbo.fn_XMLNode('Action',            @vAction) +
                            dbo.fn_XMLNode('BusinessUnit',      @vBusinessUnit) +
                            dbo.fn_XMLNode('UserId',            @vUserId) +
                            dbo.fn_XMLNode('LabelPrinterName',  @vLabelPrinterName) +
                            dbo.fn_XMLNode('ReportPrinterName', @vReportPrinterName));

  /* To update the necessary info on #EntitiesToPrint as separated the new Rule Set type */
  exec pr_RuleSets_ExecuteAllRules 'EntitiesToPrint_Finalize', @vRulesDataXML, @vBusinessUnit;

  select @vRuleSetType = coalesce(@vOperation, @vAction, 'ShippingDocs');
  exec pr_Printing_ProcessPrintList @vRuleSetType, @vRulesDataXML, @vBusinessUnit, @vUserId;

  /* Get the notifications while generating the SPL labels to show to the users */
  exec pr_Printing_GetSPLNotifications 'Yes' /* Build Messages */, @vBusinessUnit, @vUserId, @ResultXML output;

  /* Temp fix: If result xml is null, from UI throwing null reference exception. Until fix in UI return dummy xml */
  if (coalesce(@ResultXML, '') = '')
    select @ResultXML = dbo.fn_XMLNode('Result', '');

  select @vPrintListXML = cast((select * from #PrintList PL
                                order by SortOrder, RecordId
                                FOR XML RAW('PrintListRecord'), TYPE, ELEMENTS XSINIL, binary base64) as varchar(max));

  if (coalesce(@vPrintListXML, '') <> '') select @PrintListXML = dbo.fn_XMLNode('PrintList', coalesce(@vPrintListXML, ''));

end  /* pr_Packing_GetPrintList */

Go
