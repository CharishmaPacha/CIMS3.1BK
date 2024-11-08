/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/03/09  PHK     pr_File_Upload: Included Filetype SKU (HA-109)
  2021/02/24  RV      pr_File_Import, pr_File_Upload: Made changes to get the full file path from controls (CIMSV3-1351)
  2021/02/19  SK      pr_File_Upload: add timestammp to error file (HA-2010)
  2021/02/03  RKC     pr_File_Upload: Used the fn_Controls_GetAsPath to get the paths (CIMSV3-1351)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_File_Upload') is not null
  drop Procedure pr_File_Upload;
Go
/*------------------------------------------------------------------------------
  Proc pr_File_Upload: This procedure take input as file name and inserts records
    from the file into a table and returns the records of the table. Returns
    ErrorFile if any

 FileType: SKUPriceList, SKUs, Locations (We will send Codes of them as SPL, SKU etc..)
 FileName: Name of the file to be imported with CurrentTimeStamp. At present only CSV files are processed
------------------------------------------------------------------------------*/
Create Procedure pr_File_Upload
 (@FileType      TTypeCode,
  @FileName      TVarchar,
  @BusinessUnit  TBusinessunit,
  @UserId        TUserId,
  @TmpTable      TVarchar output,
  @ErrorFile     TVarchar output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,
          @vRecordId          TRecordId,

          @vTimestamp         TString,
          @vFilePath          TVarchar,
          @vErrorLogPath      TVarchar,

          @vControlCategory   TCategory,
          @vErrorFileName     TVarchar,
          @vErrorFileExists   TInteger,
          @vErrorFilePath     varchar(1000), /* xp_fileexist is not supporting varchar(max), hence size was defined here
                                              Assumption is we won't get value of this variable morethan 1000 charaters */
          @vDatasetName       TVarchar,
          @vProcessName       TVarchar,
          @vMainTableName     TName,
          @vKeyFieldName      TName,
          @vFieldList         TSQL,
          @vSQL               TNVarchar,
          @vAddColString      TNVarchar;

begin
begin try /* pr_File_Upload */
  SET NOCOUNT ON;

  /* Log the input */
  exec pr_ActivityLog_AddMessage @FileType, null /* Entity Id */, null /* EntityKey */, @FileName,
                                 'Import File', @@ProcId, null, @BusinessUnit, @UserId;

  select @vReturnCode      = 0,
         @vMessageName     = null,
         @vRecordId        = 0,
         @vTimestamp       = replace(replace(convert(varchar, getdate(), 126), ':', '-'), '.', '-'),
         @vProcessName     = 'ImportFile',
         @vControlCategory = 'Import_File_' + @FileType;

  /* Get the FilePath from Controls using FileType */
  select @vFilePath     = dbo.fn_Controls_GetAsPath(@vControlCategory, 'FilePath_DB', null /* Default */, @BusinessUnit, null /* UserId */),
         @vErrorLogPath = dbo.fn_Controls_GetAsPath(@vControlCategory, 'ErrorLog_DB', null /* Default */, @BusinessUnit, null /* UserId */);

  /* FilePath is null then get the default path */
  if (@vFilePath is null)
    select @vFilePath     = dbo.fn_Controls_GetAsPath('Import_File', 'DefaultPath_DB', null /* Default */, @BusinessUnit, null /* UserId */),
           @vErrorLogPath = dbo.fn_Controls_GetAsPath('Import_File', 'ErrorLog_DB', null /* Default */, @BusinessUnit, null /* UserId */);

  /* Get the datasetname for the respective FileType, Assumption is we always send file type from UI */
  select @vDatasetName   = dbo.fn_Controls_GetAsString(@vControlCategory, 'DataSetName', @FileType /* Default */, @BusinessUnit, null /* UserId */),
         @vMainTableName = dbo.fn_Controls_GetAsString(@vControlCategory, 'TableName', @vDataSetName /* default */, @BusinessUnit, null /* UserId */),
         @vKeyFieldName  = dbo.fn_Controls_GetAsString(@vControlCategory, 'KeyFieldName', 'UniqueId' /* default */, @BusinessUnit, null /* UserId */);

  /* Remove File Extension to use proper format while creating tablename */
  select @FileName = dbo.fn_SubstringUptoNthSeparator(@FileName, '.', 1);

  /* Build naming for both table & log file, append time stamp for error file to avoid conflicts with existing files */
  select @TmpTable       = 'Imp' + '_' + @FileType + '_' + @FileName,
         @vErrorFileName = @TmpTable + @vTimestamp + '.log';

  /* Build log filename with path */
  select @vErrorFilePath = @vErrorLogPath + @vErrorFileName;

  /* Get the FieldList to create a temp table */
  exec pr_Table_GetFieldList @vProcessName, @vDatasetName, null /* Default */, @vFieldList output;

  /* Validations */
  if (@TmpTable is null)
    set @vMessageName = 'FileImport_Inv_TableProcessError';
  else
  if (@vFieldList is null)
    set @vMessageName = 'FileImport_Inv_TableFieldProcessError';
  else
  if (@vFilePath is null)
    set @vMessageName = 'FileImport_Inv_FilepathError';
  else
  if (@FileName is null)
    set @vMessageName = 'FileImport_Inv_FilenameError';
  else
  if (@vErrorFilePath is null)
    set @vMessageName = 'FileImport_Inv_ErrFilepathError';

  if (@vMessageName is not null)
   goto ErrorHandler;

  /* Add required fields as needed for different file types */
  if (@FileType in ('SPL' , 'LOC', 'SKU', 'LOCREP' /* SKUPriceList, Locations, SKUs, LocationReplenishLevels */))
    select @vAddColString = 'Alter Table  ' + @TmpTable + ' Add ' +
                              'Validated      varchar (10),
                               ValidationMsg  varchar (max),
                               CreatedBy      varchar (50),
                               KeyData        varchar (200),
                               RecordId       int  identity (1,1);';
  else
    select @vAddColString = 'Alter Table  ' + @TmpTable + ' Add ' +
                              'Validated      varchar (10),
                               ValidationMsg  varchar (max),
                               CreatedBy      varchar (50),
                               KeyData        varchar (200),
                               BusinessUnit   varchar (10),
                               RecordId       int  identity (1,1);';

  /* Create table and insert data into it */
  select @vSQL = 'if object_id(''' + @TmpTable +''') is not null drop table ' + @TmpTable +'; Create Table ' + @TmpTable + ' (' + @vFieldList + '); ' +

                 'BULK INSERT ' + @TmpTable + ' FROM ' + '''' + @vFilePath + @FileName + '.csv''' + '
                  WITH (
                        FIRSTROW        = 2,
                        DATAFILETYPE    = ''char'',
                        ERRORFILE       = '''+ @vErrorFilePath + ''',
                        FIELDTERMINATOR = '','',
                        ROWTERMINATOR   = ''\n''
                       );' +
                 /* Add required columns */
                 @vAddColString;

  /* Execute SQL Statements */
  exec (@vSQL);

  /* Check log file created or not */
  exec master.dbo.xp_fileexist @vErrorFilePath, @vErrorFileExists output;

  /* If log file created return the log filename else return null */
  select @ErrorFile = case when @vErrorFileExists = 1 then @vErrorFileName
                           else null
                      end;

  /* Validate data in Temp table */
  exec pr_File_Upload_Validate @FileType, @TmpTable, @vMainTableName, @vKeyFieldName, @BusinessUnit, @UserId;

  /* Return the dataset to show in Grid */
  select @vSQL = 'select * from ' + @TmpTable + ';'

  /* Execute SQL Statements */
  exec (@vSQL);

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;
end try
begin catch
  exec @vReturnCode = pr_ReRaiseError;
end catch;

  return(coalesce(@vReturnCode, 0));
end /* pr_File_Upload */

Go
