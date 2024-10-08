/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_Printing_ReprocessPrintListData: Made changes to call the new procedure to process the SPL notifications (OBV3-529)
  2021/12/16  NB      pr_Printing_ReprocessPrintListData fixes and changes to return PrintDataReadable in debug mode(CIMSV3-1767)
  2021/12/10  NB      pr_Printing_ReprocessPrintListData changes to ensure Base64PrintData for processed records
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_ReprocessPrintListData') is not null
  drop Procedure pr_Printing_ReprocessPrintListData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printing_ReprocessPrintListData: Executes pr_Printing_ProcessPrintListData
    against the given PrintList records in the Input - returns the updated PrintList to the caller

  Usage: Shipping Docs - After the Carrier labels are generated for the LPNs,
    this process is invoked with the user selected PrintList to get the latest
    PrintData for the records which don't have print data.
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_ReprocessPrintListData
  (@InputXML         TXML,
   @ResultXML        TXML output)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vDebug                   TFlags,
          @vInputXML                XML,
          @vModule                  TName,
          @vOperation               TOperation,
          @vBusinessUnit            TBusinessUnit,
          @vUserId                  TUserId,
          @vRulesDataXML            TXML;

  declare @ttPrintList                      TPrintList,
          @ttPrintListRecordsWithBase64Data TEntityKeysTable;

begin
  select @vInputXML = convert(xml, @InputXML);

  /* Read inputs for generic procedure */
  select @vModule       = Record.Col.value('(Data/Module)[1]',             'TDescription'),
         @vOperation    = Record.Col.value('(Data/Operation)[1]',          'TDescription'),
         @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]','TBusinessUnit'),
         @vUserId       = Record.Col.value('(SessionInfo/UserId)[1]',      'TUserId')
  from @vInputXML.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vInputXML = null ) );

  /* Create temp tables */
  select * into #PrintList from @ttPrintList;

  /* Transfer details of PrintList from InputXML to #PrintList */
  insert into #PrintList(EntityType, EntityKey, EntityId, PrintRequestId, PrintJobId, DocumentClass,
                         DocumentSubClass, DocumentType, DocumentSubType, PrintDataFlag, DocumentFormat, DocumentSchema,
                         PrintData, AdditionalContent, PrinterName, PrinterConfigName, PrinterConfigIP, PrinterPort,
                         PrintProtocol, PrintBatch, NumCopies, SortOrder, InputRecordId, Status,
                         Description, Action, CreateShipment, FilePath, FileName, SortSeqNo,
                         ParentEntityKey, UDF1, UDF2, UDF3, UDF4, UDF5, ParentRecordId, PrintDataBase64)
    select Record.Col.value('EntityType[1]',  'TEntity'), Record.Col.value('EntityKey[1]', 'TEntityKey'),
           Record.Col.value('EntityId[1]', 'TRecordId'), Record.Col.value('PrintRequestId[1]', 'TRecordId'),
           Record.Col.value('PrintJobId[1]', 'TRecordId'), Record.Col.value('DocumentClass[1]', 'TTypeCode'),
           Record.Col.value('DocumentSubClass[1]', 'TTypeCode'), Record.Col.value('DocumentType[1]', 'TTypeCode'),
           Record.Col.value('DocumentSubType[1]', 'TTypeCode'), Record.Col.value('PrintDataFlag[1]', 'TFlags'),
           Record.Col.value('DocumentFormat[1]', 'TName'), Record.Col.value('DocumentSchema[1]', 'TName'),
           Record.Col.value('PrintData[1]', 'TBinary'), Record.Col.value('AdditionalContent[1]', 'TName'),
           Record.Col.value('PrinterName[1]', 'TName'), Record.Col.value('PrinterConfigName[1]', 'TName'),
           Record.Col.value('PrinterConfigIP[1]', 'TName'), Record.Col.value('PrinterPort[1]', 'TName'),
           Record.Col.value('PrintProtocol[1]', 'TName'), Record.Col.value('PrintBatch[1]', 'TInteger'),
           Record.Col.value('NumCopies[1]', 'TInteger'), Record.Col.value('SortOrder[1]', 'TSortOrder'),
           Record.Col.value('InputRecordId[1]', 'TRecordId'), Record.Col.value('Status[1]', 'TStatus'),
           Record.Col.value('Description[1]', 'TDescription'), Record.Col.value('Action[1]', 'TFlags'),
           Record.Col.value('CreateShipment[1]', 'TFlags'), Record.Col.value('FilePath[1]', 'TName'),
           Record.Col.value('FileName[1]', 'TName'), Record.Col.value('SortSeqNo[1]', 'TSortSeq'),
           Record.Col.value('ParentEntityKey[1]', 'TEntityKey'), Record.Col.value('UDF1[1]', 'TUDF'),
           Record.Col.value('UDF2[1]', 'TUDF'), Record.Col.value('UDF3[1]', 'TUDF'),
           Record.Col.value('UDF2[1]', 'TUDF'), Record.Col.value('UDF5[1]', 'TUDF'),
           Record.Col.value('ParentRecordId[1]', 'TRecordId'),
           Record.Col.value('PrintDataBase64[1]', 'varchar(max)')
      from @vInputXML.nodes('/Root/Data/PrintList/PrintListRecord') as Record(Col)
      OPTION (OPTIMIZE FOR (@vInputXML = null));

  /* Only reprocess the records which do not have the PrintData
     CreateShipment = Y .. this condition is added as some time PrintData is returned as non-empty base64 value
     for records with no print data. This has to be handled in the primary code which is transforming PrintData
     to Base64. For now, this is handled via this condition
     It is possible that some of the records in the input may already be processed and have data  */
  update #PrintList
  set PrintDataFlag = 'Required'
  where (Action like '%P%' or Action like '%S%') and ((coalesce(PrintData, '') = '') or (CreateShipment = 'Y'));

  /* Capture RecordIds of PrintList which are already having base64 data */
  insert into @ttPrintListRecordsWithBase64Data(EntityId)
    select RecordId from #PrintList
    where (PrintDataFlag <> 'Required');

  /* Use Operation instead of Module if the Input does not contain the value */
  select @vModule = coalesce(nullif(@vModule, ''), @vOperation, '');
  select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('Operation',         @vOperation) +
                            dbo.fn_XMLNode('BusinessUnit',      @vBusinessUnit) +
                            dbo.fn_XMLNode('UserId',            @vUserId));

  /* process the print list, fills in the print data for all records flagged as PrintDataFlag = Required */
  exec pr_Printing_ProcessPrintList @vModule, @vRulesDataXML, @vBusinessUnit, @vUserId;

  /* Return the updated print list to UI */
  /* Convert binary data to base64 and update on newly added column */
  update ttPrintList
  set PrintDataBase64 = binary.PrintDataString
  from #PrintList ttPrintList
    cross apply (select PrintData '*' for xml path('')) binary (PrintDataString)
  where (ttPrintList.RecordId not in (select EntityId from @ttPrintListRecordsWithBase64Data));

  /* PrintData is the readable text, but it causes issue with xml as it may have special chars
     etc. So, set it to readable text only if in debug mode. In regular mode, both PrintData
     and PrintDataBase64 would have same info - because PrintManager is still expecting it to
     have the Base64 data in PrintData , but once that is resolved we should clear it to reduce
     size of data */
  update #PrintList
  set PrintDataReadable = case when @vDebug <> '' then
                              cast(cast(PrintDataBase64 as XML).value('.', 'varbinary(max)') AS varchar(max))
                            else null
                          end;

  /* Return data set with base64 data only as caller expects Base64 data in PrintData column */
  alter table #PrintList drop column PrintData;
  select *,PrintDataBase64 as PrintData from #PrintList order by SortOrder;

  /* Get the notifications while generating the SPL labels to show to the users */
  exec pr_Printing_GetSPLNotifications default, @vBusinessUnit, @vUserId, @ResultXML output;
end /* pr_Printing_ReprocessPrintListData */

Go
