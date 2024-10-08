/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/25  RKC     pr_Setup_CreateInterfaceDataSet: Initial revision (HA-1951)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Setup_CreateInterfaceDataSet') is not null
  drop Procedure pr_Setup_CreateInterfaceDataSet;
Go
/*------------------------------------------------------------------------------
  pr_Setup_CreateInterfaceDataSet: We need to have a dataset defined for each
   interface to be able to view the dataset being imported. This procedure
   creates a view for the given dataset using the fields listed in InterfaceFields
   for the particular dataset.
------------------------------------------------------------------------------*/
Create Procedure pr_Setup_CreateInterfaceDataSet
  (@ProcessName      TName = 'ImportFile',
   @DataSetName      TName,
   @BusinessUnit     TBusinessUnit = null,
   @UserId           TUserId       = null)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,
          @vSQLViewName    TName,
          @vSQLQuery       TVarchar,
          @vSQL            TVarchar;

begin /* pr_Setup_CreateLayoutDataSetName */
  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vSQLViewName = 'vw'+ @ProcessName + @DataSetName,
         @BusinessUnit = coalesce(@BusinessUnit, BusinessUnit) from vwBusinessUnits;

  if object_id('tempdb..#InterfaceFieldsList') is not null drop table #InterfaceFieldsList;

  /* If Datasetname is given then need to drop the View and create below */
  if (object_id(@vSQLViewName) is not null)
    begin
      set @vSQL = 'drop view '+ @vSQLViewName;
      exec(@vSQL)
    end

  /* Get the All the fields from InterfaceFields table based on the given data set */
  select IFF.FieldName, T1.max_length, T2.name,
         case when t2.name = 'varchar' then '''''' when t2.name = 'date' then 'null' else '0' end as defaultvalue,
         case when t2.name = 'varchar' then 'varchar('+ case when t1.max_length = -1 then +'max' else cast(t1.max_length as varchar) end + ')' else t2.name end as datatype,
         row_number() over (order by sortseq) RecordId
  into #InterfaceFieldsList
  from InterfaceFields IFF
    join sys.types T1 on (IFF.FieldType     = T1.name)
    join sys.types T2 on (T1.system_type_Id = T2.user_type_id)
  where (IFF.DataSetName = @DataSetName) and (BusinessUnit = @BusinessUnit)
  order by SortSeq;

  /* Build the SQL statement to create View with the fields defined in the interface fields table based on the data set definced */
  select @vSQLQuery = coalesce(@vSQLQuery + ', ', '') + 'cast(' + defaultvalue + ' as ' + dataType + ') as ' +FieldName
  from #InterfaceFieldsList
  order by RecordId

  select @vSQLQuery =+ 'Create view ' + @vSQLViewName + ' as select ' + @vSQLQuery
  exec (@vSQLQuery);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end  /* pr_Setup_CreateInterfaceDataSet */

Go
