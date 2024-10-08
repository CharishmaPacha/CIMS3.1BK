/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/24  RV      pr_API_FedEx2_GetDocumentSpecifications: Initial Version (CIMSV3-3434)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_GetDocumentSpecifications') is not null
  drop Procedure pr_API_FedEx2_GetDocumentSpecifications;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_GetDocumentSpecifications:
    This procedure returns the document specifications in JSON format with required
    shippng documents details.

  Parameters:
    DocumentTypes is a comma separated values ex 'CI,RI'

  Ex: declare @DocumentSpecification TVarchar
      exec pr_API_FedEx2_GetDocumentSpecifications 'CI', 'BU', 'UserID', @DocumentSpecification  output

  Sample output expecting by FedEx:
  {
      "shippingDocumentTypes": [
          "COMMERCIAL_INVOICE",
      "RETURN_INSTRUCTIONS"
      ],
      "commercialInvoiceDetail": {
      "customerImageUsages":[
        {
          "id": "IMAGE_1",
          "type": "LETTER_HEAD",
          "providedImageType": "LETTER_HEAD"
        },
        {
          "id": "IMAGE_2",
          "type": "SIGNATURE",
          "providedImageType": "SIGNATURE"
        }
      ]
          "documentFormat": {
              "stockType": "PAPER_LETTER",
              "docType": "PDF"
          }
      }
  }
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_GetDocumentSpecifications
  (@DocumentTypes              TName,
   @BusinessUnit               TBusinessUnit,
   @UserId                     TUserId,
   @DocumentSpecificationJSON  TVarchar output)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vIsLetterHeadRequired        TControlValue,
          @vLetterHeadImageId           TControlValue,
          @vIsSignatureRequired         TControlValue,
          @vSignatureImageId            TControlValue,
          @vDocumentTypesJSON           TNVarchar,
          @vDocumentFormatJSON          TNVarchar,
          @vCustomerImagesInfoJSON      TNVarchar,
          @vCommercialInvoiceDetailJSON TNVarchar;

  declare @ttCustomerImagesInfo table
          (RecordId          TRecordId identity(1,1),
           Id                TName,
           Type              TTypeCode,
           ProvidedImageType TTypeCode);

begin /* pr_API_FedEx2_GetDocumentSpecifications */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null;

  /* Get the control values */
  select @vIsLetterHeadRequired = dbo.fn_Controls_GetAsString('Shipping_FedEx', 'IsLetterHeadRequired', 'No', @BusinessUnit, @UserId),
         @vLetterHeadImageId    = dbo.fn_Controls_GetAsString('Shipping_FedEx', 'LetterHeadImageId', 'IMAGE_1', @BusinessUnit, @UserId),
         @vIsSignatureRequired  = dbo.fn_Controls_GetAsString('Shipping_FedEx', 'IsSignatureRequired', 'No', @BusinessUnit, @UserId),
         @vSignatureImageId     = dbo.fn_Controls_GetAsString('Shipping_FedEx', 'SignatureImageId', 'IMAGE_2', @BusinessUnit, @UserId);

  select * into #CustomerImagesInfo from @ttCustomerImagesInfo;

  /* Fetch the list of documents required and return if there aren't any */
  select Value as DocType, cast('' as varchar(50)) as CarrierDocType into #ShippingDocsTypes from string_split(@DocumentTypes, ',');
  if (@@rowcount = 0) return;

  /* Get carrier doc type */
  update SDT
  set CarrierDocType = MS.TargetValue
  from #ShippingDocsTypes SDT
    join dbo.fn_GetMappedSet('CIMS', 'CIMSFedEx2', 'CarrierShippingDocumentType', null, @BusinessUnit) MS on (SDT.DocType = MS.SourceValue);

  /* Build the documents array with mapped document types */
  set @vDocumentTypesJSON = (select '[' + string_agg('"' + CarrierDocType + '"', ',') + ']'
                             from #ShippingDocsTypes);

  set @vDocumentFormatJSON = (select stockType = 'PAPER_LETTER',
                                     docType   = 'PDF'
                              FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

  /*-------------------- Populate Customer Images --------------------*/
  /* Populate the letter head image info */
  if (@vIsLetterHeadRequired = 'Yes')
    insert into #CustomerImagesInfo(Id, Type, ProvidedImageType)
      select @vLetterHeadImageId, 'LETTER_HEAD', 'LETTER_HEAD';

  /* Populate the signature image info */
  if (@vIsSignatureRequired = 'Yes')
    insert into #CustomerImagesInfo(Id, Type, ProvidedImageType)
      select @vSignatureImageId, 'SIGNATURE', 'SIGNATURE';

  /* Build customer image info */
  if exists(select * from #CustomerImagesInfo)
    set @vCustomerImagesInfoJSON = (select id                = Id,
                                           type              = Type,
                                           providedImageType = ProvidedImageType
                                    from #CustomerImagesInfo
                                    FOR JSON PATH);

  /*-------------------- Build the Commercial Invoice Details --------------------*/
  if exists(select * from #ShippingDocsTypes where DocType = 'CI' /* Commercial Invoice */)
    set @vCommercialInvoiceDetailJSON = (select customerImageUsages = JSON_QUERY(@vCustomerImagesInfoJSON),
                                                documentFormat      = JSON_QUERY(@vDocumentFormatJSON)
                                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

  /* TODO: Build the other documents detials: CERTIFICATE_OF_ORIGIN, DANGEROUS_GOODS_SHIPPERS_DECLARATION,
           OP_900, PRO_FORMA_INVOICE, RETURN_INSTRUCTIONS */

  /*-------------------- Build the Document Specification JSON --------------------*/
  set @DocumentSpecificationJSON = (select shippingDocumentTypes   = JSON_QUERY(@vDocumentTypesJSON),
                                           commercialInvoiceDetail = JSON_QUERY(@vCommercialInvoiceDetailJSON)
                                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_GetDocumentSpecifications */

Go
