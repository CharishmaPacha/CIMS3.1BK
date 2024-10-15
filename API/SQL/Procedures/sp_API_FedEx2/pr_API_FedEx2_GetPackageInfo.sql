/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/06/06  RV      Changes have been made to send the declared value to cover the insurance based on the InsuranceRequired flag (CIMSV3-3659)
  2024/04/15  RV      Made changes to get the total declared value from commodities (FBV3-1726)
  2024/02/12  RV      Initial Version (CIMSV3-3395)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_GetPackageInfo') is not null
  drop Procedure pr_API_FedEx2_GetPackageInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_GetPackageInfo: Extract data from get shipment data JSON and
   build payment info JSON

   Package Level Special Service Types ref: https://developer.fedex.com/api/en-us/guides/api-reference.html#packagelevelspecialservicetypes
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_GetPackageInfo
  (@BusinessUnit           TBusinessUnit,
   @UserId                 TUserId,
   @CommoditiesRequired    TFlags,
   @TotalDeclaredValueJSON TNVarchar = null output,
   @PackageInfoJSON        TNVarchar = null output)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vRecordid                   TRecordId,

          @vPickTicket                 TPickTicket,
          @vShipVia                    TShipVia,
          @vCarrierOptions             TDescription,
          @vCurrency                   TCurrency,
          @vWeightJSON                 TNVarchar,
          @vDeclaredValueJSON          TNVarchar,
          @vDimensionsJSON             TNVarchar,
          @vCustomerReferencesJSON     TVarchar,
          @vPackagesJSON               TNVarchar,
          @vCommodities                TVarchar,
          @vCommoditiesInfo            TXML,
          @vSignatureOption            TVarchar,

          @vPackageSpecialServicesJSON TNVarchar;

  declare @ttCommodities               TCommoditiesInfo,
          @ttLPNs                      TEntityKeysTable;

begin /* pr_API_FedEx2_GetPackageInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vRecordid     = 0,
         @vPackagesJSON = '';

  select @vPickTicket         = PickTicket,
         @vShipVia            = ShipVia,
         @vCarrierOptions     = CarrierOptions,
         @vCurrency           = Currency
  from #OrderHeaders;

  /* Retrieve the total declared value from the commodities table */
  select @TotalDeclaredValueJSON = (select amount   = cast(sum(LineValue) as numeric(8,2)),
                                           currency = @vCurrency
                                    from #CommoditiesInfo
                                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

  select @vPackageSpecialServicesJSON = (select specialServiceTypes = JSON_QUERY('["SIGNATURE_OPTION"]'), /* Add required special sservices to the array */
                                                signatureOptionType = case
                                                                        when (dbo.fn_IsInList('SIG-FEDEX-ADULT' /* Signature Options */, @vCarrierOptions) > 0)
                                                                          then 'ADULT'
                                                                        when (dbo.fn_IsInList('SIG-FEDEX-DIRECT' /* Signature Options */, @vCarrierOptions) > 0)
                                                                          then 'DIRECT'
                                                                        when (dbo.fn_IsInList('SIG-FEDEX-INDIRECT' /* Signature Options */, @vCarrierOptions) > 0)
                                                                          then 'INDIRECT'
                                                                        when (dbo.fn_IsInList('SIG-FEDEX-NR' /* Signature Options */, @vCarrierOptions) > 0)
                                                                          then 'NO_SIGNATURE_REQUIRED'
                                                                        else 'SERVICE_DEFAULT'
                                                                      end
                                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

  -- ToDo: itemDescriptionForClearance, contentRecord, itemDescription,

  select @vPackagesJSON = (select sequenceNumber           = PackageSeqNo,
                                  subPackagingType         = 'CARTON',
                                  customerReferences       = JSON_QUERY(concat('[{"customerReferenceType": "', LabelReference1Type, '",',
                                                                                 '"value": "', LabelReference1Value, '"},',
                                                                                 '{"customerReferenceType": "', LabelReference2Type, '",',
                                                                                 '"value": "', LabelReference2Value, '"},',
                                                                                 '{"customerReferenceType": "', LabelReference3Type, '",',
                                                                                 '"value": "', LabelReference3Value, '"}]')),
                                                             /* Based on the declared value, insurance is charged.
                                                                SurePost does not support declaring package values at the individual package level */
                                  [declaredValue.amount]   = iif(InsuranceRequired = 'No' or @vShipVia = 'FEDXSP', 0, cast(InsuredValue as numeric(8,2))),
                                  [declaredValue.currency] = @vCurrency,
                                  [weight.units]           = 'LB',
                                  [weight.value]           = cast(LPNWeight    as numeric(5,1)),
                                  [dimensions.length]      = cast(CartonLength as numeric(5,1)),
                                  [dimensions.width]       = cast(CartonWidth  as numeric(5,1)),
                                  [dimensions.height]      = cast(CartonHeight as numeric(5,1)),
                                  [dimensions.units]       = 'IN',
                                  packageSpecialServices   = JSON_QUERY(@vPackageSpecialServicesJSON)
                               from #CarrierPackageInfo
                               FOR JSON PATH);

  select @PackageInfoJSON = @vPackagesJSON;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_GetPackageInfo */

Go
