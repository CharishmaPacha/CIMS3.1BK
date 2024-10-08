/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/30  AY      pr_Printing_BuildPrintDataSet: Use DBObjectName of LabelFormats (BK-446)
  2020/04/16  AY      pr_Printing_ProcessPrintList, pr_Printing_BuildPrintDataSet, pr_Printing_EntityPrintRequest:
  2020/04/07  KBB     Change the data type  pr_Printing_BuildPrintDataSet/pr_Printing_GetPrintDataStream(HA-50)
  2020/02/11  MS      pr_Printing_BuildPrintDataSet: Changes to consider LabelSQLStatement as input (JL-39)
  2020/01/22  AY      pr_Printing_BuildPrintDataSet, pr_Printing_GetPrintDataStream: Enh. for V3 ZPL Printing
  2019/12/18  AY      pr_Printing_BuildPrintDataSet: Changed to use PrepareResultsTempTable (CID-1191)
  2019/12/09  AY      pr_Printing_BuildPrintDataSet: Run the SQL to get the dataset for a label
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_BuildPrintDataSet') is not null
  drop Procedure pr_Printing_BuildPrintDataSet;
Go
/*-----------------------------------------------------------------------------
  Proc pr_Printing_BuildPrintDataSet: Executes the SQL statement and inserts
   the result data set into #PrintDataSet. For the given entity, this could return
   one row to print (like in the case of a Shipping label or several rows to print
   (like in the case of price stickers).
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_BuildPrintDataSet
  (@EntityType       TEntity,
   @EntityId         TRecordId,
   @EntityKey        TEntityKey,
   @LabelFormatName  TName,
   @LabelSQLStmt     TSQL,
   @Operation        TOperation,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;

  declare @vProcName          TName,
          @vLabelSQLStmt      TSQL,
          @vZPLLabelSQLStmt   TSQL,
          @vSQL               TSQL,
          @vLabelEntity       TEntity,
          @vDBObjectName      TName;
begin /* pr_Printing_BuildPrintDataSet */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* If we already sending LabelSqlStmt as input then use it else get from LabelFormats */
  select @vLabelSQLStmt    = coalesce(@LabelSQLStmt, LabelSQLStatement),
         @vZPLLabelSQLStmt = ZPLLabelSQLStatement,
         @vDBObjectName    = DBObjectName
  from LabelFormats
  where (LabelFormatName = @LabelFormatName) and (BusinessUnit = @BusinessUnit);

  /* Extract proc name from sql */
  if (charindex('exec ', @vLabelSQLStmt) > 0)
    begin
      select @vProcName    = replace(@vLabelSQLStmt, 'exec ', '');
      select @vLabelEntity = stuff(@vProcName, charindex(' ', @vProcName), len(@vProcName), '');
    end
  else
  /* For listing labels, the label sql statement is a select */
  if (charindex('Select', @vLabelSQLStmt) > 0) and (@Operation = 'ListingLabels')
    begin
      /* The LabelSQLStatement for listing labels is already prepared by caller with join
         with #SelectedEntities, so nothing else needs to be done here */

      select @vLabelEntity = @EntityType + 'Label';

      /* Build temp table with the Result set for the given entity. i.e. if it is pallets
         then we would have DBObjects defined the result set as select * from vwPallets */
     -- exec pr_PrepareHashTable @vLabelEntity, '#PrintDataSet';
    end
  else
  /* For Entity labels, the label sql statement is a select */
  if (exists (select * from DBObjects where ObjectName = @EntityType + 'Label'))
    begin
      select @vLabelEntity = @EntityType + 'Label';

      /* For Entity labels which are not printed from UI, the ZPL Label SQL statement has
         to be used with the given entity id */
      select @vLabelSQLStmt = @vZPLLabelSQLStmt;

      /* Build temp table with the Result set for the given entity. i.e. if it is pallets
         then we would have DBObjects defined the result set as select * from vwPallets */
  --    exec pr_PrepareHashTable @vLabelEntity, '#PrintDataSet';
    end
  else
    /* For any other labels assume that the result set is defined for the specific LabelFormat */
    begin
      select @vLabelEntity = @LabelFormatName;

      /* For Entity labels which are not printed from UI, the ZPL Label SQL statement has
         to be used with the given entity id */
      select @vLabelSQLStmt = @vZPLLabelSQLStmt;
    end

  /* If a specific DB object name is specified for the label, then use that, else go with default */
  select @vDBObjectName = coalesce(@vDBObjectName, @vLabelEntity);

  /* Build temp table with the Result set of the procedure */
  exec pr_PrepareHashTable @vDBObjectName, '#PrintDataSet';

  /* Capture results into temp table */
  select @vSQL = 'insert into #PrintDataSet ' + @vLabelSQLStmt;
  select @vSQL = replace (@vSQL, '~EntityType~', '''' + @EntityType + '''');
  select @vSQL = replace (@vSQL, '~EntityId~', coalesce(cast(@EntityId as varchar), 'null'));
  select @vSQL = replace (@vSQL, '~EntityKey~', coalesce(cast(@EntityKey as varchar), 'null'));
  select @vSQL = replace (@vSQL, '~Operation~', coalesce('''' + @Operation + '''', 'null'));
  select @vSQL = replace (@vSQL, '~LabelFormatName~', '''' + @LabelFormatName + '''');
  select @vSQL = replace (@vSQL, '~BusinessUnit~', '''' + @BusinessUnit + '''');

  exec (@vSQL);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Printing_BuildPrintDataSet */

Go
