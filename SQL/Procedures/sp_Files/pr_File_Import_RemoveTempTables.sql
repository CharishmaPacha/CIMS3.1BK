/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/21  AY      pr_File_Import_RemoveTempTables: Revised to make sure it does not accidentally delete tables.
  2020/12/29  VS      pr_File_RemoveTempTables Renamed as pr_File_Import_RemoveTempTables (CID-1399)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_File_Import_RemoveTempTables') is not null
  drop Procedure pr_File_Import_RemoveTempTables;
Go
/*------------------------------------------------------------------------------
  Proc pr_File_Import_RemoveTempTables: Used to remove the temporary tables which
    are created during the file import process.

  Usage: exec pr_File_RemoveTempTables 'IMP_', 'SCT' will delete all
------------------------------------------------------------------------------*/
Create Procedure pr_File_Import_RemoveTempTables
  (@TableName    TName,
   @BusinessUnit TBusinessUnit)
as
declare @vReturnCode        TInteger,
        @vMessageName       TMessageName,
        @vRecordId          TRecordId,

        @vSQL               TSQL;
begin
  SET NOCOUNT ON;

  select @vSQL = '';

  /* Table name and a valid BU are required */
  if (coalesce(@TableName, '') = '') select @vMessageName = 'FileImport_TableNamePrefixRequired';
  if (not exists (select * from vwBusinessUnits where BusinessUnit = @BusinessUnit))
    select @vMessageName = 'FileImport_InvalidBusinessUnit';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Build the DynamicQuery to drop the tables */
  select @vSQL += 'drop table ' + ob.name + '; '
                   from sys.objects ob
                     join sys.schemas s on ob.schema_id = s.schema_id
                   where (ob.name like @Tablename + '%') and
                         (ob.type_desc = 'USER_TABLE') and
                         (ob.create_date < dateadd(DD, -1, getdate())) and
                         (not exists(select * from sys.dm_sql_referencing_entities(s.name + '.' + ob.name, 'OBJECT') dt))
                   order by ob.create_date;

  /* Drop the tables */
  exec sp_executesql @vSQL;

end /* pr_File_Import_RemoveTempTables */

Go
