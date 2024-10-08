/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/03/09  RV      Renamed to pr_API_FedEx2_Response_SaveDocuments (CIMSV3-3478) 
  2022/11/28  AY      pr_API_FedEx_Response_SaveDocuments: Initial Version
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_Response_SaveDocuments') is not null
  drop Procedure pr_API_FedEx2_Response_SaveDocuments;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_Response_SaveDocuments: Save the documents in #Documents
    onto the server and in the Document Library
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_Response_SaveDocuments
  (@EntityType               TTypeCode,
   @EntityId                 TRecordId,
   @EntityKey                TEntityKey,
   @BusinessUnit             TBusinessUnit,
   @UserId                   TUserId = null)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,

          @vLoadNumber                  TLoadNumber,
          @vWarehouse                   TWarehouse,
          @vPickTicket                  TPickTicket,

          @vDocsDBRootPath              TName,
          @vDocsRelativePath            TName,
          @vDocsFullPath                TName;

begin /* pr_API_FedEx2_Response_SaveDocuments */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  /* if there is nothing to save, then exit */
  if (object_id('tempdb..#Documents') is null) or
     (not exists (select * from #Documents))
    return;

  if (@EntityType = 'Load')
    select @vLoadNumber = LoadNumber,
           @vWarehouse  = ShipFrom
    from Loads
    where (LoadId = @EntityId)
  else
  if (@EntityType = 'Order')
    select @vPickTicket = PickTicket,
           @vWarehouse  = Warehouse
    from OrderHeaders
    where (OrderId = @EntityId);

  /* DB and UI Docs path may be same when both DB and UI are on the same server. DB may have shared path of the UI documents folder.
     Typically they are on different servers and the DB path reflects the the drives/folders as the DB servers sees on where the
     files have to be saved and UI Path reflects the same on the UI Server.
     For example: Files may actually be saved on the UI server in D:\CIMS\Documents (UI Path) but on the DB server
                  this is shared as P:\ (DBPath). When files are saved from SQL procedures like this, DB path is used
                  to save, but UI would access the same using UI Path which is why Document Library uses UI Path */

  /* If Entity is Load, then the context is IPD, so get the relative path for that */
  if (@EntityType = 'Load')
    exec pr_Controls_GetDocsPaths 'Loads_FedExIPD', 'Loads\~Load~\FEDEXIPD' /* Default */, @BusinessUnit, @UserId,
                                  @vDocsDBRootPath out, @vDocsRelativePath out;
  else
  if (@EntityType = 'Order')
    exec pr_Controls_GetDocsPaths 'Orders_CarrierDocs', 'Orders' /* Default */, @BusinessUnit, @UserId,
                                  @vDocsDBRootPath out, @vDocsRelativePath out;

  select @vDocsRelativePath = replace(@vDocsRelativePath, '~WH~',   coalesce(@vWarehouse, ''));
  select @vDocsRelativePath = replace(@vDocsRelativePath, '~Load~', coalesce(@vLoadNumber, ''));
  select @vDocsRelativePath = replace(@vDocsRelativePath, '~Order~', coalesce(@vPickTicket, ''));

  /* Get the full path to save the documents. This path may network path when both the DB and UI in different servers */
  select @vDocsFullPath = concat(@vDocsDBRootPath, '\', @vDocsRelativePath);

  /* Update old saved documents as Inactive */
  update DL
  set DL.Status = 'InActive', ModifiedDate = current_timestamp
  from DocumentLibrary DL
    join #Documents TD on (DL.EntityId = @EntityId) and (DL.EntityType = @EntityType) and (DL.DocumentSubType = TD.DocumentType /* Fedex Doc Type */);

  /* Save the documents into the Library */
  insert into DocumentLibrary(EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType,
                            DocumentSubType, DocumentFormat, DocumentSchema, PrintData, PrintDataBase64,
                            DocumentFileName, DocumentPath, ProcessedDateTime, BusinessUnit)
  select @EntityType, @EntityId, @EntityKey, 'REPORT', 'FILE',
         case when (DocumentType = 'CONDENSED_CRN_REPORT')                  then 'CCRN'
              when (DocumentType = 'COMMERCIAL_INVOICE')                    then 'CIF'
              when (DocumentType = 'CONSOLIDATED_COMMERCIAL_INVOICE')       then 'CCI'
              when (DocumentType = 'CONSOLIDATED_CUSTOMS_LINEHAUL_REPORT')  then 'CCLR'
              when (DocumentType = 'CONSOLIDATED_PARTY_REPORT')             then 'CPR'
              when (DocumentType = 'CONSOLIDATED_SOLD_TO_SUMMARY_REPORT')   then 'CSTSR'
              when (DocumentType = 'CRN_REPORT')                            then 'CRN'
              when (DocumentType = 'CUSTOMS_PACKING_LIST')                  then 'CPL'
              when (DocumentType = 'CUSTOM_CONSOLIDATION_DOCUMENT')         then 'CCD'
              when (DocumentType = 'COMMODITIES_BY_TRACKING_NUMBER_REPORT') then 'CCD'
              else 'UNKNOWN'
         end /* Document Type */,
         DocumentType /* Doc Sub Type - FedEx Doc Type */, ImageType, 'STATIC', null /* Print Data */, Image,
         @EntityKey + '_' + DocumentType, /* + '.' + ImageType */ -- Temp fix, Already we are adding .PDF in Print Manger, So until commented out until fix in PrinterManger
         @vDocsRelativePath, current_timestamp, @BusinessUnit
  from #Documents;

  /* Call the CLR to save the documents from DB to share UI path */
  select @vReturnCode = dbo.fn_CLR_SaveBase64EncodedDocument(Image, @vDocsFullPath, @EntityKey + '_' + DocumentType + '.' + ImageType)
  from #Documents

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_Response_SaveDocuments */

Go
