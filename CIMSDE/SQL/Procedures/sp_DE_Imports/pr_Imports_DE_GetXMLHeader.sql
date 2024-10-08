/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_GetXMLHeader') is not null
  drop Procedure pr_Imports_DE_GetXMLHeader;
Go
/*------------------------------------------------------------------------------
  pr_Imports_DE_GetXMLHeader: The import procedures of CIMS expect a message header.
    So, when we are importing from CIMSDE, we would need to build a header and this
    proceduces does that with the given params or defaults to standard values.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_GetXMLHeader
  (@SourceSystem     TDescription = null,
   @TargetSystem     TDescription = null,
   @SourceReference  TDescription = null,
   @TransferMethod   TDescription = null,

   @xmlHeader         TXML = null output)
as
  declare @vReturnCode      TInteger;
begin /* pr_Imports_DE_GetXMLHeader */
  SET NOCOUNT ON;

  /* initilize values here */
  select @SourceSystem    = coalesce(@SourceSystem, 'CIMSDE'),
         @TargetSystem    = coalesce(@TargetSystem, 'CIMS'),
         @SourceReference = coalesce(@SourceReference, cast(current_timestamp as varchar(20))),
         @TransferMethod  = coalesce(@TransferMethod, 'DB');

  /*build xml msg header xml here based on the given / assigned  values  */
  select @xmlHeader = '<msgHeader>' +
                         '<SourceSystem>'    + @SourceSystem    + '</SourceSystem>' +
                         '<TargetSystem>'    + @TargetSystem    + '</TargetSystem>' +
                         '<SourceReference>' + @SourceReference + '</SourceReference>' +
                         '<TransferMethod>'  + @TransferMethod  + '</TransferMethod>' +
                      '</msgHeader>'
ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_GetXMLHeader */

Go
