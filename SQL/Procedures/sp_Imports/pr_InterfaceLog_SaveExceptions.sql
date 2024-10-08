/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/01/01  TD      Added pr_InterfaceLog_SaveExceptions,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_InterfaceLog_SaveExceptions') is not null
  drop Procedure pr_InterfaceLog_SaveExceptions;
Go
/*------------------------------------------------------------------------------
  Procedure pr_InterfaceLog_SaveExceptions: This procedure will take the
    necessary data as input, and will log the details in interface log detail tables
    by calling a wrapper procedure.

    We will call this procedure when there is any exception while importing/exporting
    data into/from CIMS in direct database integration-
------------------------------------------------------------------------------*/
Create Procedure pr_InterfaceLog_SaveExceptions
  (@SourceSystem          TName         = null,
   @TargetSystem          TName         = null,
   @SourceReference       TName         = null,
   @TransferType          TTransferType = null,
   @ProcessType           TRecordType   = null,
   @RecordType            TRecordType   = null,
   @BusinessUnit          TBusinessUnit = null,
   @Message               TNvarchar     = null,
   @xmlData               Xml           = null,
   @xmlDocHandle          TInteger      = null,
   @RecordsProcessed      TCount        = null)
as
  declare @vxmlHeader    TXML,
          @vxmlErrorDtl  TXML,
          @xmlLogDetails TXML,
          @xmlResult     TXML;
begin
  /* initilize values here */
  select @SourceSystem    = coalesce(@SourceSystem, 'CIMSDE'),
         @TargetSystem    = coalesce(@TargetSystem, 'CIMS'),
         @SourceReference = coalesce(@SourceReference, cast(current_timestamp as varchar(20))),
         @TransferType    = coalesce(@TransferType, 'Import'),
         @RecordType      = coalesce(@RecordType, 'DB'),
         @ProcessType     = coalesce(@ProcessType, 'End');

  /* Framing appropraiate xmls here */
  select @vxmlHeader = '<Header>' +
                          '<SourceSystem>'    + @SourceSystem    + '</SourceSystem>' +
                          '<TargetSystem>'    + @TargetSystem    + '</TargetSystem>' +
                          '<SourceReference>' + @SourceReference + '</SourceReference>' +
                          '<TransferType>'    + @TransferType    + '</TransferType>' +
                          '<ProcessType>'     + @ProcessType     + '</ProcessType>' +
                          '<RecordTypes>'     + @RecordType      + '</RecordTypes>' +
                       '</Header>';

  /* Build Error xml here from the input */
  select @vxmlErrorDtl = '<Details>' +
                           '<Error>' + coalesce(@Message, '') + '</Error>' +
                         '</Details>';

  /* Frame complete xml here  */
  select @xmlLogDetails = '<LogDetails>'  +
                             coalesce(@vxmlHeader, '')  +
                             coalesce(@vxmlErrorDtl, '')  +
                          '</LogDetails>';

  /* call procedure here to log error details in interface tables */
  exec pr_InterfaceLog_Prepare @xmlLogDetails, @xmlResult output;

end /* pr_InterfaceLog_SaveExceptions */

Go
