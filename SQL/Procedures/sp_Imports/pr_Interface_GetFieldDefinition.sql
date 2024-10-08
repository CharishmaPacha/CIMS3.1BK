/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Interface_GetFieldDefinition') is not null
  drop Procedure pr_Interface_GetFieldDefinition;
Go
/*------------------------------------------------------------------------------
  Proc pr_Interface_GetFieldDefinition: The list of fields given by clients in the file
    and the field names expected by CIMS may be different, so we need a mapping
    from external field names to CIMS field names. This procedure returns the
    field map based upon the filename.
------------------------------------------------------------------------------*/
Create Procedure pr_Interface_GetFieldDefinition
  (@ProcessName     TName,
   @DataSetName     TName,
   @ImportFileName  TName)
as
  declare @InterfaceFieldMappingxml    TXML;
  declare @ttInterfaceFieldMap table (FieldName         TEntity,
                                      ExternalFieldName TEntity,
                                      FieldType         TTypeCode,
                                      FieldWidth        TInteger,
                                      Justification     TName,
                                      PadChar           Char,
                                      SortOrder         TSortSeq,

                                      RecordId          TRecordId Identity(1,1));
begin
  /* Get the fields and their attributes */
  insert into @ttInterfaceFieldMap (FieldName, ExternalFieldName, FieldType, FieldWidth, Justification, PadChar, SortOrder)
    select FieldName, ExternalFieldName, FieldType, FieldWidth, Justification, PadChar, SortSeq
    from InterfaceFields
    where (ProcessName  = @ProcessName) and
          (@DatasetName = @DataSetName) and
          (Status       = 'A' /* Active */)
    order by SortSeq, FieldName;

  select * from @ttInterfaceFieldMap
  order by RecordId;
end /* pr_Interface_GetFieldDefinition */

Go
