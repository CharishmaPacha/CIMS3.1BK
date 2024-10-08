/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/20  RV      Initial Version (CIMSV3-3434)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_GetCommoditiesInfo') is not null
  drop Procedure pr_API_FedEx2_GetCommoditiesInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_GetCommoditiesInfo: #Commodities info is already populated
    by pr_Carrier_GetShipmentData. This procedure just summarizes that.

  Sample JSON:
  [
        {
            "unitPrice": {
                "amount": 12.45,
                "currency": "USD"
            },
            "additionalMeasures": [
                {
                    "quantity": 12.45,
                    "units": "KG"
                }
            ],
            "numberOfPieces": 12,
            "quantity": 125,
            "quantityUnits": "Ea",
            "customsValue": {
                "amount": "1556.25",
                "currency": "USD"
            },
            "countryOfManufacture": "US",
            "cIMarksAndNumbers": "87123",
            "harmonizedCode": "0613",
            "description": "description",
            "name": "non-threaded rivets",
            "weight": {
                "units": "KG",
                "value": 68
            },
            "exportLicenseNumber": "26456",
            "exportLicenseExpirationDate": "2024-02-16T09:08:32Z",
            "partNumber": "167",
            "purpose": "BUSINESS",
            "usmcaDetail": {
                "originCriterion": "A"
            }
        }
    ],
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_GetCommoditiesInfo
  (@LPNId                TRecordId,
   @BusinessUnit         TBusinessUnit,
   @UserId               TUserId,
   @CommoditiesInfoJSON  TNVarchar output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vHTSCodeCount          TCount,
          @vMaxHTSCount           TCount;

  /* Temp table to capture Commodities data */
  declare @ttCommodities          TCommoditiesInfo;

begin /* pr_API_FedEx2_GetCommoditiesInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vMaxHTSCount  = 999;

  if (object_id('tempdb..#CommoditySummary') is null)
    select * into #CommoditySummary from @ttCommodities;

  /* Handle nulls for HTS and CoO */
  update #CommoditiesInfo
  set HTSCode = coalesce(HTSCode, ''), Coo = coalesce(Coo, '');

  select @vHTSCodeCount = count(distinct HTSCode + CoO) from #CommoditiesInfo;

  /* If we have less than 10 distinct HTS codes, then summarize by that. If we have more, the summarize it all */
  if (@vHTSCodeCount <= @vMaxHTSCount)
    begin
      insert into #CommoditySummary (HTSCode, NumberOfPieces, SKU, Description,
                                     ProductInfo1, ProductInfo2, ProductInfo3,
                                     UPC, Quantity, QuantityUoM, Currency,
                                     UnitCost, UnitPrice, UnitValue,
                                     LineTotalCost, LineTotalPrice, LineValue, UnitWeight, QtyWeight, WeightUoM,
                                     CoO, FreightClass, Manufacturer, EntityKey, EntityId)
        select HTSCode, max(PackageSeqNo), max(SKU), max(coalesce(Description, ProductInfo1)),
               max(coalesce(nullif(ProductInfo1, ''), Description)), max(ProductInfo2), max(ProductInfo3),
               max(UPC), sum(Quantity), max(QuantityUoM), max(Currency),
               sum(cast(LineTotalCost as float))/sum(cast(Quantity as float)),
               sum(cast(LineTotalPrice as float))/sum(cast(Quantity as float)),
               sum(cast(LineValue as float))/sum(cast(Quantity as float)),
               sum(LineTotalCost), sum(LineTotalPrice), sum(LineValue), avg(cast(UnitWeight as float)), sum(cast(QtyWeight as float)), max(WeightUoM),
               CoO, max(FreightClass), max(Manufacturer), max(EntityKey), max(EntityId)
        from #CommoditiesInfo
        where (EntityId = coalesce(@LPNId, EntityId))
        group by HTSCode, CoO;
    end
  else
    begin
      insert into #CommoditySummary (HTSCode, NumberOfPieces, SKU, Description,
                                     ProductInfo1, ProductInfo2, ProductInfo3,
                                     UPC, Quantity, QuantityUoM, Currency,
                                     UnitCost, UnitPrice, UnitValue,
                                     LineTotalCost, LineTotalPrice, LineValue, UnitWeight, QtyWeight, WeightUoM,
                                     CoO, FreightClass, Manufacturer, EntityKey, EntityId)
        select 'Multiple', max(PackageSeqNo), max(SKU),max(coalesce(Description, ProductInfo1)),
                max(coalesce(nullif(ProductInfo1, ''), Description)), max(ProductInfo2), max(ProductInfo3),
                max(UPC), sum(Quantity), max(QuantityUoM), max(Currency),
                sum(cast(LineTotalCost as float))/sum(cast(Quantity as float)),
                sum(cast(LineTotalPrice as float))/sum(cast(Quantity as float)),
                sum(cast(LineValue as float))/sum(cast(Quantity as float)),
                sum(LineTotalCost), sum(LineTotalPrice), sum(LineValue), avg(cast(UnitWeight as float)), sum(cast(QtyWeight as float)), max(WeightUoM),
                CoO, max(FreightClass), max(Manufacturer), max(EntityKey), max(EntityId)
        from #CommoditiesInfo
        where (EntityId = coalesce(@LPNId, EntityId))
        group by CoO;
    end

  /* Build the XML */
  select @CommoditiesInfoJSON = (select [unitPrice.amount]          = cast(UnitValue as numeric(8,2)),
                                        [unitPrice.currency]        = Currency,
                                        numberOfPieces              = NumberOfPieces,
                                        quantity                    = Quantity,
                                        quantityUnits               = QuantityUoM,
                                        [customsValue.amount]       = cast(LineValue as numeric(8,2)),
                                        [customsValue.currency]     = Currency,
                                        countryOfManufacture        = CoO,
                                        cIMarksAndNumbers           = EntityKey,    -- LPN
                                        harmonizedCode              = HTSCode,
                                        description                 = ProductInfo1, -- Includes detailed info that is necessary for CI
                                        name                        = Description,  -- short description of product
                                        [weight.units]              = WeightUoM,
                                        [weight.value]              = cast(UnitWeight    as numeric(5,1)),
                                        -- exportLicenseNumber         = '',        -- future use
                                        -- exportLicenseExpirationDate = '',        -- future use
                                        partNumber                  = coalesce(UPC, SKU)
                                 from #CommoditySummary
                                 FOR JSON PATH);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_GetCommoditiesInfo */

Go
