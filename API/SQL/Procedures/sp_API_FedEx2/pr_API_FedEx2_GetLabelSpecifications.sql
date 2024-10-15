/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/03/28  RV      Made changes to send the label stock for PNG format (BK-1102)
  2024/03/22  RV      Bug fixed to format the json for printed label origin (SRIV3-450)
  2024/02/12  RV      Initial Version (CIMSV3-3395)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_GetLabelSpecifications') is not null
  drop Procedure pr_API_FedEx2_GetLabelSpecifications;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_GetLabelSpecifications:
    This procedure returns the label specifications in JSON format.
    LabelImageFromat : Valid values are PDF, PNG, ZPLII and EPL2
    LabelStockSize: We can find valid combinations in the following reference
      https://developer.fedex.com/api/en-us/guides/api-reference.html#labelstocktypes

  Sample:
  "labelSpecification": {
    "labelFormatType": "COMMON2D",
    "labelOrder": "SHIPPING_LABEL_FIRST",
    "printedLabelOrigin": {
      "address": {
        "streetLines": [
          "10 FedEx Parkway",
          "Suite 302"
        ],
        "city": "Beverly Hills",
        "stateOrProvinceCode": "CA",
        "postalCode": "38127",
        "countryCode": "US",
        "residential": false
      },
      "contact": {
        "personName": "person name",
        "emailAddress": "email address",
        "phoneNumber": "phone number",
        "phoneExtension": "phone extension",
        "companyName": "company name",
        "faxNumber": "fax number"
      }
    },
    "labelStockType": "STOCK_4X6",
    "labelRotation": "UPSIDE_DOWN",
    "imageType": "ZPLII",
    "labelPrintingOrientation": "TOP_EDGE_OF_TEXT_FIRST"
  }
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_GetLabelSpecifications
  (@BusinessUnit           TBusinessUnit,
   @UserId                 TUserId,
   @Options                TString,
   @LabelSpecificationJSON TNVarchar output)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          /* Label attributes */
          @vLabelFormatType            TTypeCode,
          @vLabelStockType             TTypeCode,
          @vImageType                  TTypeCode,
          @vLabelOrder                 TDescription,
          @vLabelRotation              TDescription,
          @vlabelPrintingOrientation   TDescription,
          /* Order Info */
          @vPrintedLabelOriginJSON     TNVarchar,
          @vShipVia                    TShipVia,
          @vShipFrom                   TShipFrom,
          @vReturnAddress              TContactRefId,
          @vWarehouse                  TWarehouse,
          /* Controls */
          @vClearanceFacility          TControlValue,
          /* Label Origin info */
          @vPLOContactType             TTypeCode,
          @vPLOContactRefId            TContactRefId;

begin /* pr_API_FedEx2_GetLabelSpecifications */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  exec pr_Markers_Save 'FedEx_GetLabelSpecs', @@ProcId;

  select @vLabelFormatType = LabelFormatType,
         @vLabelStockType  = LabelStockType,
         @vImageType       = LabelImageType
  from #CarrierShipmentData

  if (object_id('tempdb..#OrderHeaders') is not null)
    select @vShipFrom      = ShipFrom,
           @vReturnAddress = ReturnAddress,
           @vWarehouse     = Warehouse,
           @vShipVia       = ShipVia
    from #OrderHeaders;

  /* Default for FedEx */
  select @vLabelFormatType          = coalesce(@vLabelFormatType, 'COMMON2D'),
         @vLabelOrder               = 'SHIPPING_LABEL_FIRST',
         @vLabelRotation            = 'UPSIDE_DOWN',
         @vlabelPrintingOrientation = 'TOP_EDGE_OF_TEXT_FIRST';

  /* Get the Clearance facility */
  select @vClearanceFacility = dbo.fn_Controls_GetAsString('FEDEX_IPD', 'ClearanceFacility', 'IDSI', @BusinessUnit, @UserId);

  /* If Label Origin is required, then use the Return address and if that is not available,
     use the ShipFrom address */
  if (charindex('PrintedLabelOrigin', @Options) > 0)
    begin
      /* Determine which address to print as Origin on the label */

      /* If IPD, use Importer of Record */
      if (@vShipVia = 'FEDEXIPD')
        select @vPLOContactType = 'IOR', @vPLOContactRefId = @vClearanceFacility;
      else
      /* If there is return address, then use that */
      if (coalesce(@vReturnAddress, '') <> '')
        select @vPLOContactType = 'F', @vPLOContactRefId = @vReturnAddress;
      else
      /* If ShipFrom is dff. than WH then use the ShipFrom */
      if (coalesce(@vShipFrom, '') <> coalesce(@vWarehouse, ''))
        select @vPLOContactType = 'F', @vPLOContactRefId = @vReturnAddress;

      /* If we include Account Number in PLO, then we get error, so make sure we don't send any Account Number */
      if (@vPLOContactRefId is not null)
        exec pr_API_FedEx2_GetAddress null /* ContactId */, @vPLOContactType, @vPLOContactRefId, null /* Account Number */, null /* Root Node */,
                                      'No' /* ArrayRequired */, @BusinessUnit, @UserId, @vPrintedLabelOriginJSON out;
    end

  /* If LabelType is ZPL then map to ZPL Values to support FedEx */
  If (@vImageType = 'ZPL')
    select @vImageType      = 'ZPLII',
           @vLabelStockType = 'STOCK_4X6';
  else
  if (@vImageType = 'PNG')
    select @vLabelStockType = 'PAPER_4X6',
           @vLabelRotation  = 'LEFT'; /* Usually, PNG labels are printed on PL from the left */

  /* Build the JSON for FEDEX Label */
  select @LabelSpecificationJSON = (select labelFormatType          = @vLabelFormatType,
                                           labelOrder               = @vLabelOrder,
                                           printedLabelOrigin       = JSON_QUERY(@vPrintedLabelOriginJSON),
                                           labelStockType           = @vLabelStockType,
                                           labelRotation            = @vLabelRotation,
                                           imageType                = @vImageType,
                                           labelPrintingOrientation = @vlabelPrintingOrientation
                                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_GetLabelSpecifications */

Go
