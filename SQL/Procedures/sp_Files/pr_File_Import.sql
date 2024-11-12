/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/11/12  PHK     Changes to get required fields as needed for SKUs (BK-1160)
  2022/03/04  GAG     pr_File_Import: Changed @vDatasetName and @vMainTableName to use function control as fn_Controls_GetAsString
                      pr_File_Upload: Add required fields if fieldtype is of "LOCREP" (BK-766)
  2021/03/24  TK      pr_File_Import_Inventory_Process: Trim trailing spaces for inventory class (HA-GoLive)
  2021/03/19  TK      pr_File_Import_Inventory_Process: Bug fix to update pallet info on the LPNs that are created in the run (HA-2341)
  2021/03/15  RKC/TK  pr_File_Import_Inventory_Process: Made changes to update the pallet & locations on the newly created LPNs (HA-2285)
  2021/03/13  RKC     pr_File_Import_Inventory_Process: Made changes to get the correct values (HA-2276)
  2021/03/11  RKC     pr_File_Import, pr_File_Import_ProcessIUDSQLStmts: Made changes to process the
                      IUD import process files (HA-2010)
  2021/02/24  RV      pr_File_Import, pr_File_Upload: Made changes to get the full file path from controls (CIMSV3-1351)
  2021/02/05  RKC     pr_File_Import_INV_Process: Initial Revision (CIMSV3-1323)
  2020/01/21  AY      pr_File_Import_RemoveTempTables: Revised to make sure it does not accidentally delete tables.
  2020/01/20  AY      pr_File_Import: Allow processing using stored procedures (HA-1926)
  2020/12/29  VS      pr_File_RemoveTempTables Renamed as pr_File_Import_RemoveTempTables (CID-1399)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_File_Import') is not null
  drop Procedure pr_File_Import;
Go
/*------------------------------------------------------------------------------
  Proc pr_File_Import: This procedure take input as FileType & Temp Table name
   and inserts records from temp table into Main Table.
------------------------------------------------------------------------------*/
Create Procedure pr_File_Import
 (@FileType      TTypecode,
  @TempTableName TVarchar,
  @BusinessUnit  TBusinessunit,
  @UserId        TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,
          @vRecordId          TRecordId,

          @vControlCategory   TCategory,
          @vDatasetName       TVarchar,
          @vProcessName       TVarchar,
          @vFileName          TVarchar,
          @vFieldList         TSQL,
          @vTempTableFields   TSQL,
          @vMainTableName     TName,
          @vKeyFieldName      TName,
          @vImportProcess     TOperation,
          @vImportProcName    TName,
          @vxmlRulesData      TXml,

          @vSQL               TNVarchar;

begin
begin try /* pr_File_Import */
  SET NOCOUNT ON;

  begin tran

  select @vReturnCode      = 0,
         @vMessageName     = null,
         @vRecordId        = 0,
         @vProcessName     = 'ImportFile',
         @vControlCategory = 'Import_File_' + @FileType;

  /* Get the DatasetName & FileName of respective FileType , Assumption is we always send FileType from UI */
  /* GAG--> If @vDatasetName and @vMainTableName is given as fn_Controls_GetAspath it doesn't work and also we dont need full path name for those fields, so changing to "fn_Controls_GetAsString" */
  select @vDatasetName   = dbo.fn_Controls_GetAsString(@vControlCategory, 'DataSetName', @FileType /* default */, @BusinessUnit, null /* UserId */),
         @vMainTableName = dbo.fn_Controls_GetAsString(@vControlCategory, 'TableName', @vDataSetName /* default */, @BusinessUnit, null /* UserId */),
         @vKeyFieldName  = dbo.fn_Controls_GetAsString(@vControlCategory, 'KeyFieldName', 'UniqueId' /* default */, @BusinessUnit, null /* UserId */),
         @vImportProcess = dbo.fn_Controls_GetAsString(@vControlCategory, 'ImportProcess', 'IUDSQL,Rules,Procedure' /* default */, @BusinessUnit, null /* UserId */),
         @vFileName      = replace(@TempTableName , 'Imp' + '_' + @FileType + '_', ''); --FileName to use in InterfaceLog

  /* Get the FieldList of Table */
  exec pr_Table_GetFieldList @vProcessName, @vDatasetName, 'FWOD' /* FieldList without Datatype */, @vFieldList output;

  select @vFieldList      += ', CreatedBy',
         @vImportProcName  = 'pr_File_Import_' + @vDatasetName + '_Process';

  /* PHK_1211: Implemented a temporary change to insert the Business Unit (BU) into the fieldList for the SKUs fieldType.   
     This will be reverted once the proper changes are rolled out to the onsite system. */  
  if @FileType = 'SKU'
    select @vFieldList    += ', BusinessUnit'; 

  /* If there is no RecordAction field in the field list, then we cannot process using IUD, so remove that method */
  select @vImportProcess = case when (charindex ('RecordAction', @vFieldList) = 0) then replace(@vImportProcess, 'IUDSQL', '') else @vImportProcess end;

  /* Prepare Xml to use in Rules */
  select @vxmlRulesData = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('FileType',      @FileType) +
                            dbo.fn_XMLNode('ProcessName',   @vProcessName) +
                            dbo.fn_XMLNode('DatasetName',   @vDatasetName) +
                            dbo.fn_XMLNode('MainTableName', @vMainTableName) +
                            dbo.fn_XMLNode('TempTableName', @TempTableName) +
                            dbo.fn_XMLNode('KeyFieldName',  @vKeyFieldName) +
                            dbo.fn_XMLNode('BusinessUnit',  @BusinessUnit) +
                            dbo.fn_XMLNode('UserId',        @UserId));

  /* Import records using Insert/Update/Delete SQL Statements */
  if (charindex('IUDSQL', @vImportProcess) > 0)
    exec pr_File_Import_ProcessIUDSQLStmts @vxmlRulesData, @vFieldList, @BusinessUnit, @UserId;

  /* Import records using rules */
  if (charindex('Rules', @vImportProcess) > 0)
    exec pr_RuleSets_ExecuteAllRules 'ImportFile_UpdateRecords' /* RuleSetType */, @vxmlRulesData, @BusinessUnit;

  /* Import records using procedure if such a procedure exists */
  if (charindex('Procedure', @vImportProcess) > 0) and
     (object_id(@vImportProcName) is not null)
    begin
      select @vSQL = 'exec ' + @vImportProcName + ' ' + quotename(@TempTableName, '''') + ', ' + quotename(@BusinessUnit, '''') + ', ' + quotename(@UserId, '''');
      exec (@vSQL);
    end

  /* Log the records */
  exec pr_File_Import_LogResults @vFileName, @FileType, @TempTableName, @vFieldList, @BusinessUnit, @UserId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If we are here, there are no errors */
  commit;

end try
begin catch
  if (@@trancount > 0) rollback;

  exec @vReturnCode = pr_ReRaiseError;
end catch;

  return(coalesce(@vReturnCode, 0));
end /* pr_File_Import */

Go
