/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/12  RV      Initial Version (CIMSV3-3434)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_GetSmartPostDetail') is not null
  drop Procedure pr_API_FedEx2_GetSmartPostDetail;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_GetSmartPostDetail:
    This procedure returns the details for SmartPost service

  Hub Ids: https://developer.fedex.com/api/en-us/guides/api-reference.html#smartposthubids

  Smart Post Detail Sample output:
  "smartPostInfoDetail": {
    "ancillaryEndorsement": "RETURN_SERVICE",
    "hubId": "5015",
    "indicia": "PRESORTED_STANDARD",
    "specialServices": "USPS_DELIVERY_CONFIRMATION"
  }
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_GetSmartPostDetail
  (@BusinessUnit              TBusinessUnit,
   @UserId                    TUserId,
   @SmartPostDetailJSON       TNVarchar output)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          /* Ship Via    */
          @vShipVia                    TShipVia,
          @vSmartPostIndiciaType       TDescription,
          @vSmartPostHubId             TDescription,
          @vSmartPostEndorsement       TDescription,
          @vDeliveryConfirmation       TDescription;
begin /* pr_API_FedEx2_GetShipmentSpecialServices */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get the AddressRegion */
  select @vShipVia              = ShipVia,
         @vSmartPostIndiciaType = SmartPostIndiciaType,
         @vSmartPostHubId       = SmartPostHubId,
         @vSmartPostEndorsement = SmartPostEndorsement
  from #CarrierShipmentData;

  /* Check if the Order requires a delivery confirmation */
  select @vDeliveryConfirmation = 'USPS_DELIVERY_CONFIRMATION'
  from #OrderHeaders
  where (dbo.fn_IsInList('DC-REQ', CarrierOptions) > 0);

  /* If it is not smart post, then don't need SmartPostDetail */
  if (@vShipVia <> 'FEDXSP') return;

  /* Build the JSON for Smart Post Detail */
  select @SmartPostDetailJSON = (select ancillaryEndorsement = @vSmartPostEndorsement,
                                        hubId                = @vSmartPostHubId,
                                        indicia              = @vSmartPostIndiciaType,
                                        specialServices      = @vDeliveryConfirmation
                                 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_GetSmartPostDetail */

Go
