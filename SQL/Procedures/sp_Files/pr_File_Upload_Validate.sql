/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_File_Upload_Validate') is not null
  drop Procedure pr_File_Upload_Validate;
Go
/*------------------------------------------------------------------------------
  Proc pr_File_Upload_Validate: This procedure validates the data inserted into
   temp table while uploading the file.
------------------------------------------------------------------------------*/
Create Procedure pr_File_Upload_Validate
 (@FileType      TTypeCode,
  @TmpTable      TVarchar,
  @MainTable     TName,
  @KeyFieldName  TName,
  @BusinessUnit  TBusinessunit,
  @UserId        TUserId)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName,
          @vMessage      TDescription,
          @vRecordId     TRecordId,

          @vxmlRulesData TXml;
begin
begin try /* pr_File_Upload_Validate */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Prepare Xml to use in Rules */
  select @vxmlRulesData = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('FileType',      @FileType) +
                            dbo.fn_XMLNode('TempTableName', @TmpTable) +
                            dbo.fn_XMLNode('MainTableName', @MainTable) +
                            dbo.fn_XMLNode('KeyFieldName',  @KeyFieldName) +
                            dbo.fn_XMLNode('BusinessUnit',  @BusinessUnit) +
                            dbo.fn_XMLNode('UserId',        @UserId));

  /* Rules to validate & process records from given file */
  /* pr_RuleSets_ExecuteAllRules is used instead of pr_RuleSets_ExecuteRules as there may be many Rules which
     needs to be executed independent of other Rules execution */
  exec pr_RuleSets_ExecuteAllRules 'ImportFile_ProcessData' /* RuleSetType */, @vxmlRulesData, @BusinessUnit;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;
end try
begin catch
  exec @vReturnCode = pr_ReRaiseError;
end catch;

  return(coalesce(@vReturnCode, 0));
end /* pr_File_Upload_Validate */

Go
