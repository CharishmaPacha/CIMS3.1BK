/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/27  RV      pr_API_FedEx2_GetShipmentSpecialServices: Integrated ETD special service (CIMSV3-3453)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_GetShipmentSpecialServices') is not null
  drop Procedure pr_API_FedEx2_GetShipmentSpecialServices;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_GetShipmentSpecialServices:
    This procedure returns the special services to be included in the request.

  Saturday Delivery:
  Saturday Delivery is an option that is specified on the Order. If the Order is enabled
  for Saturday Delivery, then it means that we turn on the flag when applicable. For
  FedEx - Saturday delivery is only applicable for certain ShipVias. Also, the request
  is allowed only when shipping on Thursday with a 2 day delivery service or shipping
  on Friday with a 1 day delivery i.e. it would normally be delivered on Monday, but
  this flag allows to be delivered on Saturday.

  ELECTRONIC TRADE DOCUMENTS:
  This refers to the digital or electronic versions of traditional paper-based trade documents
  used in international trade and commerce. The transmission of Electronic Trade Document (ETD)
  details to FedEx is contingent upon the control variable. By default, the commercial invoice is sent.

  FedEx-One Rate: A ship via can be taggged as OneRate which means any orders shipped
  using that ShipVia would be considered under the One Rate Program. Alternatively
  it could also be that the order is particularly tagged as OneRate in which case
  it would beome a OneRate service shipment as well.

  Special Service Types Sample output:
   {
     "specialServiceTypes": [
       "ELECTRONIC_TRADE_DOCUMENTS",
       "FEDEX_ONE_RATE"
     ],
     "etdDetail": {
       "requestedDocumentTypes": [
         "COMMERCIAL_INVOICE"
        ]
   }
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_GetShipmentSpecialServices
  (@InternationalDocsRequired TVarchar,
   @BusinessUnit              TBusinessUnit,
   @UserId                    TUserId,
   @SpecialServiceTypesJSON   TNVarchar output,
   @SpecialServiceDetailsJSON TNVarchar output)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vShipToAddressRegion     TAddressRegion,
          @vOrderShipVia            TShipVia,
          @vCarrierOptions          TDescription,
          @vDesiredShipDate         TDate,
          @vDayName                 TName,
          @vETDDetailJSON           TNVarchar,
          @vETDRequired             TControlValue,
          @vOneRateShipVia          TDescription;

  declare @ttSpecialServiceTypes    TEntityKeysTable;

begin /* pr_API_FedEx2_GetShipmentSpecialServices */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get the control values */
  select @vETDRequired = dbo.fn_Controls_GetAsString('Shipping_FedEx', 'ETDRequired', 'No', @BusinessUnit, @UserId);

  /* Get the AddressRegion
     if ShipVia has been flagged as a FedEx One Rate service, then add the special service */
  select @vShipToAddressRegion = ShipToAddressRegion,
         @vOneRateShipVia      = iif(charindex('FEDEX_ONE_RATE', SpecialServices) > 0, 'FEDEX_ONE_RATE', null)
  from #CarrierShipmentData;

  select @vOrderShipVia    = ShipVia,
         @vCarrierOptions  = CarrierOptions,
         @vDesiredShipDate = DesiredShipDate,
         @vDayName         = datename(dw, DesiredShipDate)
  from #OrderHeaders;

  /* Saturday Delivery is included for some shipvias based upon day of shipping - see comments above */
  if (dbo.fn_IsInList('SD-REQ' /* Saturday Delivery Required */, @vCarrierOptions) > 0)
    begin
      if ((@vDayName = 'Thursday' and @vOrderShipVia in ('FEDX2', 'FEDX2AM' /* FedEx - 2 Day, 2 Day AM */)) or
          (@vDayName = 'Friday' and @vOrderShipVia in ('FEDX1P' /* PRIORITY_OVERNIGHT */)))
        insert into @ttSpecialServiceTypes(EntityKey)
          select 'SATURDAY_DELIVERY';
    end

  /* When shipping internationally, clients can opt for ETD i.e. Electronic delivery of the documents.
     This is controlled by control var. ETD should however be enabled only when Documents are required.
     For example, even if we need documents for international shipment, we enable it only for the last
     package, so earlier packages of the shipment would not have Documents request and hence should not
     have ETD either */
  if (@vETDRequired = 'Yes') and (@vShipToAddressRegion = 'I' /* International */) and
     (coalesce(@InternationalDocsRequired, '') <> '')
    begin
      insert into @ttSpecialServiceTypes(EntityKey)
        select 'ELECTRONIC_TRADE_DOCUMENTS';

      select @vETDDetailJSON = (select requestedDocumentTypes = JSON_QUERY('["COMMERCIAL_INVOICE"]')
                                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    end

  /* FedEx one rate special service is enabled when send in carrier options */
  if (@vOneRateShipVia = 'FEDEX_ONE_RATE') or
     (dbo.fn_IsInList('SS-FOR' /* FEDEX ONE RATE */, @vCarrierOptions) > 0)
    insert into @ttSpecialServiceTypes(EntityKey)
      select 'FEDEX_ONE_RATE';

  /* Build the special serivce types array */
  if exists(select * from @ttSpecialServiceTypes)
    select @SpecialServiceTypesJSON = (select specialServiceTypes = JSON_QUERY('[' + string_agg('"' + EntityKey + '"', ',') + ']'),
                                              etdDetail           = JSON_QUERY(@vETDDetailJSON)
                                       from @ttSpecialServiceTypes
                                       FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_GetShipmentSpecialServices */

Go
