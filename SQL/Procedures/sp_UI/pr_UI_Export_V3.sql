/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/22  SV/NB   pr_UI_Export_V3 changes to prevent duplicates in formulating the SQL statement (FBV3-855)
  2021/11/08  NB      Added pr_UI_Export_V3(CIMSV3-810)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_UI_Export_V3') is not null
  drop Procedure pr_UI_Export_V3;
Go
/*------------------------------------------------------------------------------
pr_UI_Export_V3

Proc processing the input details, identifies the data to be exported and processes export
to file via bcp utility

------------------------------------------------------------------------------*/
Create Procedure pr_UI_Export_V3
  (@InputXML     TXML,
   @OutputXML    TXML output)
as
  declare @vInputXML                    xml,
          @vErrorXML                    TXML,
          @vStoredProcOutputXML         TXML,
          @vReturnCode                  TInteger,
          @vxpcmdshellconfig            TInteger,
          @vErrorMessage                TMessage,
          @vMessageName                 TMessageName,
          @vEntity                      TEntity,
          @vAction                      TAction,
          @vDatasetName                 TName,
          @vEntityIdFieldName           TName,
          @vEntityKeyFieldName          TName,
          @vContextName                 TName,
          @vLayoutDesc                  TDescription,
          @vBusinessUnit                TBusinessUnit,
          @vUserId                      TUserId,
          @vUIDataCaption               TName,
          @vDbSourceType                TLookUpCode,
          @vDbSource                    TName,
          @vSQLStatement                TVarchar,
          @vSelectionFilterWhereClause  TVarchar,
          @vSummaryFilterWhereClause    TVarchar,
          @vDataSQLStatement            TVarchar,
          @vDataSQLWhereClause          TVarchar,
          @vDataCTESQLStatement         TVarchar,
          @vDataHeadersSQLStatement     TVarchar,
          @vBCPOutputDataFieldNames     TVarchar,
          @vOrderByClause               TVarchar,
          @vGroupByClause               TVarchar,
          @vColumnNames                 TVarchar,
          @vDBName                      TName,
          @vServerName                  TName,
          @vDBUsername                  TName,
          @vDBPassword                  TName,
          @vFolderPath_DB               TVarchar,
          @vFolderPath_UI               TVarchar,
          @vFileName                    TFileName,
          @vBCPCommand                  varchar(8000),/* varchar max cant be used for this parameter hence forced to consider this length */
          @vBatchNo                     TRecordId,
          @NumBatchNoToCreate           TRecordId,
          @vTempTable1                  TName,
          @vTempSQL                     TVarchar
          ;

  declare @ttResultMessages  TResultMessagesTable,
          @ttResultData      TNameValuePairs;
begin /* pr_UI_Export_V3 */
begin try
  select @vInputXML = convert(xml, @InputXML);

  /* Verify if xp_cmdshell needed to run bcp export is enabled on the server */
  select @vxpcmdshellconfig = convert(INT, isnull(value, value_in_use))
  from sys.configurations
  where name = 'xp_cmdshell';

  if (@vxpcmdshellconfig != 1)
    select @vMessageName = 'BCP_xp_cmdshelldisabled';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  select * into #ResultMessages from @ttResultMessages;      -- to hold the results of the action
  select * into #ResultData     from @ttResultData;          -- to hold the data to be returned to UI

  select @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @vUserId        = Record.Col.value('(SessionInfo/UserId)[1]',       'TUserName'),
         @vContextName   = Record.Col.value('(UIInfo/ContextName)[1]',       'TName'),
         @vLayoutDesc    = Record.Col.value('(UIInfo/LayoutDescription)[1]', 'TDescription'),
         @vSQLStatement  = Record.Col.value('(Data/SQLStatement)[1]',        'TVarchar'),
         @vDBUserName    = Record.Col.value('(Data/DBUserName)[1]',          'TName'),
         @vDBPassword    = Record.Col.value('(Data/DBPassword)[1]',          'TName'),
         @vUIDataCaption = Record.Col.value('(EntityDetail/Caption)[1]',     'TName'),
         @vDbSourceType  = Record.Col.value('(EntityDetail/DbSourceType)[1]','TLookUpCode'),
         @vDbSource      = Record.Col.value('(EntityDetail/DbSource)[1]',    'TName')
  from @vInputXML.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vInputXML = null ));

  /* Verify whether the intent to export data is from a stored procedure data source listing
     If so, fetch the data into a hashtable and build the SQLStatement for the output dataset from the stored procedure */
  if (@vDBSourceType = 'P' /* Stored Procedure */)
    begin
      /* create temp table for capturing result set with a single identity column */
      create table #ResultDataSet (RDSRecordId int identity(1, 1) not null);
      exec pr_PrepareHashTable @vDBSource, '#ResultDataSet';

      exec @vDBSource @vInputXML, @vStoredProcOutputXML output;

      exec pr_Controls_GetNextSeqno 'ExportToExcel', 1 /* SeqNos to be generated */, @vUserId, @vBusinessUnit, @vBatchNo output;

      set @vTempTable1= '##ttUIExportData' + convert(varchar(10), @vBatchNo);
      /* Dropping the temp table if any exists with the said names */
      if object_id('tempdb..'+@vTempTable1, 'U') is not null
        begin
          set @vTempSQL = 'drop table '+@vTempTable1;
          exec(@vTempSQL);
        end

      select @vTempSQL = 'select * into '+ @vTempTable1 + ' from #ResultDataSet';
      exec(@vTempSQL);
      select @vDataSQLStatement ='select * from ' + @vTempTable1;
    end
  else
  /* When the Input is passed in with a SQL Statement, use the statement to export requested data
     when this procedure is called from UI, the SQL Statement for the Listing Data which the user has requested
     to export is passed in the input. The procedure need not build the SQL Statement in this case.*/
  if (@vSQLStatement is not null)
    begin
      select @vDataSQLStatement = @vSQLStatement;
    end
  else
    /* If datasource is a table or view */
    begin
      exec pr_Entities_GetDataSetInfo @vContextName, @vBusinessUnit, @vUserId,
                                      @vDataSetName out, @vEntityIdFieldName out, @vEntityKeyFieldName out;

      /* Build SQL Statement for the data */
      exec pr_Entities_BuildSQLWhere @vInputXML,
                                     @vSelectionFilterWhereClause output,
                                     @vSummaryFilterWhereClause   output;

      if (@vSummaryFilterWhereClause is not null)
        select @vDataSQLWhereClause =  coalesce(@vSelectionFilterWhereClause + ' AND ', '') + @vSummaryFilterWhereClause;
      else
        select @vDataSQLWhereClause = @vSelectionFilterWhereClause;

      /*  The datasource is a Table or a View. Retrieve the data using a select statement */
      if (@vDataSQLWhereClause is not null)
        begin
          /* Build SQL statement to fetch Data from the Context's Db Source */
          select @vOrderByClause = Record.Col.value('(ListDetails/SortByClause)[1]', 'TVarchar')
          from @vInputXML.nodes('/Root') as Record(Col)
          OPTION (OPTIMIZE FOR (@vInputXML = null));

          select @vDataSQLWhereClause = nullif(@vDataSQLWhereClause,   ''),
                 @vOrderByClause      = coalesce(nullif(@vOrderByClause, ''), '1'),
                 @vGroupByClause      = nullif(@vGroupByClause, '');

          select @vColumnNames = coalesce( @vColumnNames + ',', '')+ LF.FieldName
          from LayoutFields LF
          left outer join Fields F on LF.FieldName = F.FieldName and (F.BusinessUnit = LF.BusinessUnit)
          where (LF.ContextName = @vContextName) and (LF.LayoutDescription = @vLayoutDesc) and (coalesce(LF.FieldVisible, F.Visible, -1) = 1)
          order by FieldVisibleIndex;

          select @vDataSQLStatement = 'select ' + @vColumnNames +
                                      ' from ' +  @vDatasetName +
                                      coalesce(' where ' + @vDataSQLWhereClause, '') +
                                      coalesce(' group by ' + @vGroupByClause, '') +
                                      coalesce(' order by ' + @vOrderByClause, '');
          --exec(@vGetDataSQLStatement);
        end
    end

  /* Build the SQL for BCP Call with SQL including Row for Field Names at the top
  
   (SYSTYP.name <> 'sysname') Query in CTEQueryFieldNames excludes sysname type.
   This is added to avoid duplicates in the CTE
   nvarchar and sysname have the same system_type_id in sys.types. Because of this, the output in the CTE has duplicates
   Until a proper solution can be found, this condition is added to ensure the functionality works. 
  */
  ;
  with CTEQueryFieldNames as
  (  select dsdef.column_ordinal [C1], dsdef.name [ColumnName], SYSTYP.name [ColumnTypeName]
     from sys.dm_exec_describe_first_result_set(@vDataSQLStatement, null, 0) dsdef
     join sys.types SYSTYP on (SYSTYP.system_type_id = dsdef.system_type_id) and (SYSTYP.is_user_defined = 0) and (SYSTYP.name <> 'sysname') 
  )
  select @vDataHeadersSQLStatement = coalesce(@vDataHeadersSQLStatement + ',', '') + '''' + coalesce(F.Caption, LF.FieldCaption, QFN.ColumnName) + ''' as ' +  QFN.ColumnName,
         @vDataCTESQLStatement     = coalesce(@vDataCTESQLStatement + ',', '') + case when ColumnTypeName <> 'varchar' then 'Cast(' + ColumnName +' as varchar) as ' + ColumnName else ColumnName end,
         @vBCPOutputDataFieldNames = coalesce(@vBCPOutputDataFieldNames + ',', '') + QFN.ColumnName
  from CTEQueryFieldNames QFN
  left outer join LayoutFields LF on (LF.FieldName = QFN.ColumnName) and (LF.ContextName = @vContextName) and (LF.LayoutDescription = @vLayoutDesc)
  left outer join Fields F on (F.FieldName = QFN.ColumnName)
  order by QFN.C1;

  /* Add OutputOrder to ensure the Field Names come up at the top */
  select @vDataHeadersSQLStatement = 'select ' + @vDataHeadersSQLStatement + ', 1 as OutputOrder',
         @vDataCTESQLStatement     = @vDataCTESQLStatement  + ', OutputOrder';

  select @vDataCTESQLStatement = '; With GetDataCTE as ( ' + @vDataSQLStatement + '), DataCTE as ( select *, 2 as OutputOrder from GetDataCTE), CombinedDataCTE as(' + @vDataHeadersSQLStatement + ' UNION select ' + @vDataCTESQLStatement + ' from DataCTE) select ' + @vBCPOutputDataFieldNames + ' from CombinedDataCTE';

  /* Assigning servername, dbname and xml values */
  select @vServerName    = @@SERVERNAME,
         @vDBName        = DB_NAME(),
         @vFolderPath_DB = dbo.fn_Controls_GetAsPath('ExportToExcel', 'FolderPath_DB', '' /* Default */, @vBusinessUnit, @vUserId /* UserId */),
         /* Layout Description + UserId + YYYY-mm-DD_HHMMSS */
         @vFileName      = replace(@vUIDataCaption, ' ', '_') + '_' + replace(@vLayoutDesc, ' ', '_') + '_' + @vUserId + '_' +  replace(replace(convert(varchar, current_timestamp, 120), ' ', '_'), ':', '') + '.xlsx';

  /* build full BCP query
      -T       implies the bcp used trusted sql connection
      -c       implies the data is converted into char objects to export the data to the external file.
                 uses \t as delimiter. and \r\n as new row character
      -U       implies the user name to login into the database
      -P       implies the password to login into the database
      -S       implies the Server to which the bcp needs to connect
      queryout implies the data will be copied from the query to the said file in the specified folder. */

  --select @vGetDataSQLStatement = replace(@vGetDataSQLStatement, '''', '''''');
  --select @vGetDataSQLStatement;
  set @vBCPCommand = 'bcp "'+ @vDataCTESQLStatement +'" queryout';
  set @vBCPCommand = @vBCPCommand + ' ' + @vFolderPath_DB + @vFileName +' -t, -c '+ ' -S '+ @vServerName + ' -U '+@vDBUserName+' -P '+@vDBPassword+ + ' -T -d ' + @vDBName;

  create table #bcpcommandoutput (output varchar(255) null);
  insert into #bcpcommandoutput
  exec @vReturnCode = xp_cmdshell @vBCPCommand;

  if (@vReturnCode > 0)
    begin
      select @vErrorMessage =  coalesce( @vErrorMessage + ' ', '') + coalesce(output, '')
      from #bcpcommandoutput;

      select @vErrorXML =  '<Errors>' +
                               dbo.fn_XMLNode('Message', dbo.fn_XMLNode('DisplayText', @vErrorMessage)) +
                           '</Errors>';
      select @OutputXML = '<Result>' + @vErrorXML + '</Result>';
    end
  else
    begin
      select @vFolderPath_UI = dbo.fn_Controls_GetAsPath('ExportToExcel', 'FolderPath_UI', '' /* Default */, @vBusinessUnit, @vUserId /* UserId */);

      insert into #ResultData (FieldName, FieldValue)
        select 'ExportFile', @vFolderPath_UI + @vFileName;

        exec pr_Entities_BuildMessageResults @vEntity, @vAction, @OutputXML output;
    end

  /* Drop the global temp table that was created earlier */
  if (@vDBSourceType = 'P' /* Stored Procedure */)
    begin
      /* Dropping the temp table if any exists with the said names */
      if object_id('tempdb..'+@vTempTable1, 'U') is not null
        begin
          set @vTempSQL = 'drop table '+@vTempTable1;
          exec(@vTempSQL);
        end
    end

end try
begin catch
  /* Capture Exception details and send in output Format */
  select @vErrorMessage = ERROR_MESSAGE();
  select @vErrorXML =  '<Errors>' +
                           dbo.fn_XMLNode('Message', dbo.fn_XMLNode('DisplayText', @vErrorMessage)) +
                       '</Errors>';
  select @OutputXML = '<Result>' + @vErrorXML + '</Result>';
end catch
end /* pr_UI_Export_V3 */

Go
