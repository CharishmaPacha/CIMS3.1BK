/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/11  RKC     pr_File_Import, pr_File_Import_ProcessIUDSQLStmts: Made changes to process the
                      IUD import process files (HA-2010)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_File_Import_ProcessIUDSQLStmts') is not null
  drop Procedure pr_File_Import_ProcessIUDSQLStmts;
Go
/*------------------------------------------------------------------------------
  Proc pr_File_Import_ProcessIUDSQLStmts: Process the records in the import temp table
   via Insert, Update and Delete SQL statements
------------------------------------------------------------------------------*/
Create Procedure pr_File_Import_ProcessIUDSQLStmts
  (@xmlRulesData     XML,
   @FieldList        TSQL,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @vMainTableName     TName,
          @vTempTableName     TName,
          @vProcessName       TName,
          @vDatasetName       TName,
          @vKeyFieldName      TName,
          @vSQL               TSQL,
          @vFieldList         TSQL,
          @vSetClause         TSQL;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0,
         @vSetClause   = '';

  /* Get the Action from the xml */
  select @vProcessName   = Record.Col.value('ProcessName[1]',        'TVarchar'),
         @vDatasetName   = Record.Col.value('DatasetName[1]',        'TVarchar'),
         @vMainTableName = Record.Col.value('MainTableName[1]',      'TName'),
         @vTempTableName = Record.Col.value('TempTableName[1]',      'TVarchar'),
         @vKeyFieldName  = Record.Col.value('KeyFieldName[1]',       'TName')
  from @xmlRulesData.nodes('/RootNode') as Record(Col);

   /* If there is no RecordAction field in the field list, then we cannot process using IUD, so remove that method */
  select @vFieldList = case when (charindex ('RecordAction', @FieldList) > 0) then replace(@FieldList, 'RecordAction,', '') else @FieldList end;

  select @vSQL = 'insert into ' + @vMainTableName + ' (' + @vFieldList + ')
                    select ' + @vFieldList + '
                    from ' + @vTempTableName + '
                    where (Validated = ''Y'') and (RecordAction = ''I'' /* Insert */);';

  /* Execute the insert statement */
  exec(@vSQL);

  /*-----------------------*/
  /* Update records from MainTable, if record action is U */

  select @vSetClause += ', '+'MT.' + FieldName + ' = coalesce(TT.' + FieldName + ', MT.' + FieldName + ')'
  from InterfaceFields
  where (ProcessName  = @vProcessName) and
        (DatasetName  = @vDatasetName) and
        (Status       = 'A' /* Active */) and
        (FieldName    <> 'RecordAction')  /* RecordAction field does not exists on the main table so need to exclude then here */
  order by SortSeq, FieldName;

  /* Remove the Extra ',' & Removed the Unwanted fields ex : RecordAction from main table */
  set @vSetClause  = right(@vSetClause,len(@vSetClause) -1)

  select @vSQL = 'Update MT set ' + @vSetClause + '
                  from ' + @vMainTableName + ' MT
                  left outer join ' + @vTempTableName + ' TT on (MT.' + @vKeyFieldName + ' = TT.KeyData) and
                                                               (MT.BusinessUnit = TT.BusinessUnit)
                  where (TT.RecordAction = ''U'') and (Validated = ''Y'');';

  /* Execute the update SQL Statement */
  exec(@vSQL);

  /*-----------------------*/
  /* Delete records from MainTable, if record action is D */
  select @vSQL = 'delete from MT
                  from ' + @vMainTableName + ' MT
                    join ' + @vTempTableName + ' TT on (MT.' + @vKeyFieldName + ' = TT.KeyData)
                  where (MT.Status       = ''A'' /* Active */) and
                        (TT.Validated    = ''Y'') and
                        (TT.RecordAction = ''D'' /* Delete */);';

  /* Execute the Delete SQL Statement */
  exec(@vSQL);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_File_Import_ProcessIUDSQLStmts */

Go
