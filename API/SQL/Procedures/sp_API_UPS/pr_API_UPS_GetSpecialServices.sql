/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/10/11  VS      pr_API_UPS_GetSpecialServices: Corrected the code to build proper JSON format for Special Service (BK-Support)
  2022/06/30  RV      pr_API_UPS_GetSpecialServices: Made changes to get the specail services from ShipVia and append
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_GetSpecialServices') is not null
  drop Procedure pr_API_UPS_GetSpecialServices;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_GetSpecialServices: Special services would be included in the
    OrderHeader.CarrierOptions and have to be included in the Request. The
    services we use for UPS are:
    -  Saturday Delivery,
    - Saturday Pickup
    - Delivery Confirmation,
    - Signature Required
    - Adult Signature Required
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS_GetSpecialServices
  (@InputXML           xml,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @ServiceOptionsJSON TNVarchar output,
   @ReturnServiceJSON  TNVarchar output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vRecordId               TRecordId,

          @vShipViaServices        TString,
          @vCarrierOptions         TString;

  declare @ttSpecialServices table(RecordId    TRecordId identity(1,1),
                                   ServiceType TTypeCode
                                  );
begin /* pr_API_UPS_GetSpecialServices */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null,
         @vRecordId          = 0,
         @ServiceOptionsJSON = '',
         @ReturnServiceJSON  = '';

  /* Get special services */
  select @vCarrierOptions = Record.Col.value('(CarrierOptions)[1]',    'TDescription')
  from @InputXML.nodes('/SHIPPINGINFO/REQUEST/ORDERHEADER') Record(Col)
  OPTION (OPTIMIZE FOR ( @InputXML = null ));

  /* Get all the special services from shipvia */
  insert into @ttSpecialServices (ServiceType)
    select Record.Col.value('(SERVICETYPE)[1]',    'TTypeCode')
    from @InputXML.nodes('/SHIPPINGINFO/REQUEST/SPECIALSERVICES') Record(Col)
    OPTION (OPTIMIZE FOR ( @InputXML = null ));

  /* Append all the special services to the Carrier options and separated with comma */
  select @vShipViaServices = string_agg(ServiceType, ',') from @ttSpecialServices;
  select @vCarrierOptions = concat_ws(',', @vCarrierOptions, @vShipViaServices);

  if (dbo.fn_IsInList('SD', @vCarrierOptions) > 0) /* Saturday Delivery */
    select @ServiceOptionsJSON += '"SaturdayDeliveryIndicator":""'

  if (dbo.fn_IsInList('SP', @vCarrierOptions) > 0) /* Saturday Pickup */
    select @ServiceOptionsJSON = concat_ws(',', nullif(@ServiceOptionsJSON, ''), '"SaturdayPickupIndicator":""');

  if (dbo.fn_IsInList('DC-SR', @vCarrierOptions) > 0) /* DCISType: 1 - Delivery Confirmation Signature Required */
    select @ServiceOptionsJSON = concat_ws(',', nullif(@ServiceOptionsJSON, ''), '"DeliveryConfirmation":{"DCISType":"1", "DCISNumber":""}');

  if (dbo.fn_IsInList('DC-ASR', @vCarrierOptions) > 0) /* DCISType: 2 - Delivery Confirmation Adult Signature Required */
    select @ServiceOptionsJSON = concat_ws(',', nullif(@ServiceOptionsJSON, ''), '"DeliveryConfirmation":{"DCISType":"2", "DCISNumber":""}')

  if (dbo.fn_IsInList('RS', @vCarrierOptions) > 0) /* Return Shipment */
    /* We have different return service codes, but as of now we are using UPS Print Return Label in CIMSSI,
       In future we need to map the other service codes.
       Code: 9: UPS Print return
       Ref: UPS API document Page No: 22 */
    select @ReturnServiceJSON = '"ReturnService":{
                                   "Code":"9",
                                   "Description":"UPS Print Return Label"
                                  },';

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_GetSpecialServices */

Go
