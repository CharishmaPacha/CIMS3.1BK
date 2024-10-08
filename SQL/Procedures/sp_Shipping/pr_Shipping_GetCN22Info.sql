/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/10/01  OK      pr_Shipping_GetShipmentData: Enhanced to return the CN22 details and required shipping docs in xml
                      pr_Shipping_GetCN22Info: Added tp return the CN22 details (OB-577)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetCN22Info') is not null
  drop Procedure pr_Shipping_GetCN22Info;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetCN22Info: CN22 Info, which is used for International shipemnts
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetCN22Info
  (@LPNId            TRecordId,
   @CN22InfoXML      Txml output)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,

          @vCN22OtherDescription TDescription,
          @vCN22CountryOfOrigin  TCountry,
          @vCN22Quantity         TQuantity,
          @vUSPSEndorsement      int,
          @vWeightUnit           TDescription,
          @vSignatureTypes       TDescription;
begin
  SET NOCOUNT ON;

  select @vReturnCode           = 0,
         @vMessageName          = null,

         /* TODO: all the below values should read from Rules/Control vars */
         @vCN22OtherDescription = 'Apparel',
         @vUSPSEndorsement      = 0, /* 0 - No Service, 1 - return Service Selected, 2 - Forwarding Service Requested etc */
         @vWeightUnit           = 'LBS',
         @vSignatureTypes       = 'Service Default'; /* Service Default/Adult/Direct/Indirect/No Signature Required/Adult19/USPS Delivery Confirmation */

  /* CN22Quantity determines the total number of items associated with the content for the CN22 Form */
  select @vCN22Quantity        = Quantity,
         @vCN22CountryOfOrigin = CoO
  from LPNs
  where (LPNId = @LPNId);

  select @CN22InfoXML = '<CN22INFO>' +
                           dbo.fn_XMLNode('CN22OtherDescription', @vCN22OtherDescription) +
                           dbo.fn_XMLNode('CN22CountryOfOrigin',  @vCN22CountryOfOrigin) +
                           dbo.fn_XMLNode('CN22Quantity',         @vCN22Quantity) +
                           dbo.fn_XMLNode('USPSEndorsement',      @vUSPSEndorsement) +
                           dbo.fn_XMLNode('WeightUnit',           @vWeightUnit) +
                           dbo.fn_XMLNode('SignatureTypes',       @vSignatureTypes) +
                        '</CN22INFO>'

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_GetCN22Info */

Go
