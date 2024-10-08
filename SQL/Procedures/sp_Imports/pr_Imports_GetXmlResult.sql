/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/17  VS      pr_Imports_CIMSDE_ImportData, pr_Imports_ImportsSQLData, pr_Imports_SKUs,
                      pr_Imports_ValidateSKU, pr_Imports_GetXmlResult, pr_Import_SQLDATAInterfaceLog,
                      pr_InterfaceLog_AddDetails: Import process changed to New process by using ##Tables (HA-3084)
  2021/08/08  AY      pr_Imports_GetXmlResult: Changed control var name and default logging to be on error only (FBV3-235)
  2018/01/22  TD      pr_Imports_GetXmlResult,pr_InterfaceLog_AddDetails:Changes to CIMSRecId on DE tables (S2G-135)
  2017/11/09  TD      pr_Imports_GetXmlResult, pr_Imports_SKUs, pr_Imports_SKUs: changes to use hostrecid (CIMSDE-14)
  2016/06/21  AY      pr_Imports_GetXmlResult: Change to return "Accepted" in the ResultXML
                      pr_Imports_GetXmlResult: Initial Revision (HPI-25)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_GetXmlResult') is not null
  drop Procedure pr_Imports_GetXmlResult;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_GetXmlResult: This procedure builds xml result for the input
    ParentLogId. The level of XML Logging may vary based upon the source system
    and hence the control var is used to determine if all details should be
    logged or only on Error.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_GetXmlResult
  (@ParentLogId   TRecordId,
   @SourceSystem  TName,
   @BusinessUnit  TBusinessUnit,
   @xmlResult     xml = null output)
as
  declare @vLogXMLResult     TControlValue,
          @vXMLResult        TXML,
          @vImportsCategory  TCategory;
begin
  /* Initilize */
  select @vImportsCategory = 'Imports_' + coalesce(@SourceSystem, 'HOST');

  /* Control Variable */
  /* N - Never, A - All Records, E - Errors only */
  select @vLogXMLResult = dbo.fn_Controls_GetAsString(@vImportsCategory, 'LogXMLResult', 'E'/* Errors */,
                                                          @BusinessUnit, null/* UserId */);

  if (@vLogXMLResult = 'N'/* Never */)
    return;

  /* Build xml Result */
  set @xmlResult = (select case when Status = 'S' /* Success */ then 'True' else 'False' end "@Accepted",
                           RecordType,
                           KeyData,
                           convert(varchar(max), ResultXml) as Error,
                           HostRecId as RecordId
                    from InterfaceLogDetails
                    where (ParentLogId = @ParentLogId) and
                          ((@vLogXMLResult in ('A', 'E') /* All Records & Error */) or
                           (Status = 'E' /* Error */))
                    FOR XML Path('Results'), TYPE, ELEMENTS XSINIL, ROOT('msg'));

  /* while converting ResultXml to xml it replaces '<' with '&lt' and '>' with '&gt',
     since replace function doesn't work on xml, convert it into varchar and revert it */
  set @vXMLResult = convert(varchar(max), @xmlResult);
  set @vXMLResult = replace(replace(@vXMLResult, '&lt;', '<'), '&gt;', '>');
  set @xmlResult  = convert(xml, @vXMLResult);

end /* pr_Imports_GetXmlResult */

Go
