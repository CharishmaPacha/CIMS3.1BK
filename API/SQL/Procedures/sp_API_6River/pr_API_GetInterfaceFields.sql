/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/12  TK      pr_API_6River_Outbound_PickWave_GetMsgData: Changes to format message data properly
                      pr_API_GetInterfaceFields: Float conversion included (CID-1715)
------------------------------------------------------------------------------*/

Go

if object_id('pr_API_GetInterfaceFields') is not null
  drop Procedure pr_API_GetInterfaceFields;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_GetInterfaceFields:
   This procedure Returns the field names & its External Field name as alias name
   that are required for any integration
------------------------------------------------------------------------------*/
Create Procedure pr_API_GetInterfaceFields
  (@ProcessName         TName,
   @DataSetName         TName,
   @BusinessUnit        TBusinessUnit,
   @FieldList           TVarchar output)
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessageName;

  declare @ttInterfaceFields table (FieldName           TName,
                                    ExternalFieldName   TName,
                                    FieldType           TTypeCode,
                                    FieldDefaultValue   TString,
                                    SortSeq             TSortSeq,
                                    RecordId            TRecordId Identity(1,1));

begin /* pr_API_GetInterfaceFields */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessagename = null;--Initialize

  /* Insert records of specific dataset into temptable */
  insert into @ttInterfaceFields (FieldName, ExternalFieldName, FieldType, FieldDefaultValue, SortSeq)
    select FieldName, ExternalFieldName, FieldType, FieldDefaultValue, SortSeq
    from InterfaceFields
    where (ProcessName  = @ProcessName    ) and
          (DatasetName  = @DatasetName    ) and
          (BusinessUnit = @BusinessUnit   ) and
          (Status       = 'A' /* Active */)
    order by SortSeq, FieldName;

  if not exists (select * from @ttInterfaceFields)
    goto ExitHandler;

  /* Append Field Name and column list */
  select @FieldList = coalesce(@FieldList + ', ', '') +
                      coalesce(case when FieldType = 'string'   then 'dbo.fn_Str(' + FieldName + ')'
                                    when FieldType = 'datetime' then 'convert(nvarchar(30), cast(' + FieldName + ' as datetimeoffset), 127)'
                                    when FieldType = 'float' then 'cast(' + FieldName + ' as float)'
                                    else FieldName
                               end,
                               case when FieldType = 'float' then 'cast(' + FieldDefaultValue + ' as float)'
                                    else '''' + FieldDefaultValue + ''''
                               end) +
                      ' as ''' + ExternalFieldName + ''''
  from @ttInterfaceFields
  order by SortSeq;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_GetInterfaceFields */

Go
