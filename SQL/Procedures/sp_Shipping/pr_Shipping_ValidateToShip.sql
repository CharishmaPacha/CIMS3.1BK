/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/26  RV      pr_Shipping_ShipLabelsInsert, pr_Shipping_ValidateToShip: Made changes to show messages with entity details (HA-745)
  2020/02/24  YJ      pr_Shipping_GetShipmentData, pr_Shipping_RegenerateTrackingNumbers,
                      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData, pr_Shipping_ValidateToShip,
                      pr_Shipping_VoidShipLabels: Changes to update PickTicket, WaveNo, WaveId on ShipLabels (CID-1335)
  2018/06/13  RV      pr_Shipping_ValidateToShip: Removed validation to verify SoldTo, ShipTo countries for international orders
                      pr_Shipping_GetShipmentData: Made changes to return ShipTo address country code (S2G-950)
  2017/10/25  OK      pr_Shipping_ValidateToShip: Enhanced to insert the Shiplabel record, if there is any error (CIMS-1677)
  2017/10/21  VM      pr_Shipping_ValidateToShip: (OB-576, 577)
                        Included a new validation to verify SoldTo, ShipTo countries for international orders.
  2016/04/26  RV      pr_Shipping_ValidateToShip: Added an optional and output parameter to return Message Name.
  2016/02/26  TK      pr_Shipping_ValidateToShip: Enhanced to use rules to evalute Shipping Account Details
  2015/08/29  RV      pr_Shipping_ValidateToShip: Added Procedure to validate shipping requirements (OB-388)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_ValidateToShip') is not null
  drop Procedure pr_Shipping_ValidateToShip;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_ValidateToShip: Check if the order is valid to be shipped by
    a small package carrier i.e. UPS, FedEx, USPS. These carriers have some
    requirements and if they are not met, then there is no point in trying
    to hit their service and get a tracking no and shipping label. So, all
    elements that are needed should be pre-validated here so that we can skip
    calling their web services if we know we will error out.

  Assumption: This procedure assumes that it is always a single Order for the
              given entity of Load or Pallet.

  Usage: Used in Packing and in Shipping_GetShipmentData, Shipping_GetLPNData &
         Shipping_GetPalletShipmentData procedures
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_ValidateToShip
  (@LoadId             TRecordId    = null,
   @OrderId            TRecordId,
   @PalletId           TRecordId    = null,
   @LPNId              TRecordId    = null,
   @Message            TMessage            output,
   @MessageName        TMessageName = null output,
   @ShippingAccountXML TXML         = null output)
as
  declare @vLPNId               TRecordId,
          @vLPN                 TLPN,
          @vLPNWeight           TWeight,
          @vLPNCartonType       TCartonType,
          @vShipFrom            TShipFrom,
          @vSoldToId            TCustomerId,
          @vSoldToCountry       TCountry,
          @vSoldToAddressRegion TAddressRegion,
          @vShipToId            TShipToId,
          @vShipToCountry       TCountry,
          @vShipToAddressRegion TAddressRegion,
          @vCarrier             TCarrier,
          @vShipVia             TShipVia,
          @vFreightTerms        TDescription,
          @vBillToAddress       TContactRefId,
          @vBillToAccount       TBillToAccount,

          @vSalesOrder          TSalesOrder,
          @vPickTicket          TPickTicket,
          @vPickBatchId         TRecordId,
          @vPickBatchNo         TPickBatchNo,
          @vAccount             TAccount,
          @vAccountName         TAccountName,
          @vOwnership           TOwnership,
          @vWarehouse           TWarehouse,

          @xmlData              TXML,
          @vBusinessUnit        TBusinessUnit,
          @vUserId              TUserId;

  declare @ttOrders             TEntityKeysTable,
          @ttResultMessages     TResultMessagesTable;
begin
  select @Message = '';

  /* Create #ResultMessages if it doesn't exist */
  if object_id('tempdb..#ResultMessages') is null
    select * into #ResultMessages from @ttResultMessages;

  /* Get the Order info for the given Entity */
  if (@LPNId is not null)
    begin
      select @vLPNId         = LPNId,
             @vLPN           = LPN,
             @vLPNWeight     = LPNWeight,
             @vLPNCartonType = CartonType
      from LPNs
      where (LPNId = @LPNId);

      insert into @ttOrders(EntityId)
        select OrderId from LPNs where (LPNId = @LPNId);
    end
  else
  if (@PalletId is not null)
    insert into @ttOrders(EntityId)
      select distinct OrderId from LPNs where (PalletId = @PalletId);
  else
  if (@LoadId is not null) -- not used for Load as of now AY 2021/08/17
    insert into @ttOrders(EntityId)
      select distinct OH.OrderId
      from OrderHeaders OH
        join OrderShipments OS on (OS.OrderId   = OH.OrderId)
        join Shipments      S  on (S.ShipmentId = OS.ShipmentId)
        join Loads          L  on (L.LoadId     = S.LoadId)
      where (L.LoadId = @LoadId);
  else
  if (@OrderId is not null)
    insert into @ttOrders(EntityId) select @OrderId;

  select @vSalesOrder          = OH.SalesOrder,
         @vPickTicket          = OH.PickTicket,
         @vPickBatchId         = OH.PickBatchId,
         @vPickBatchNo         = OH.PickBatchNo,
         @vShipFrom            = OH.ShipFrom,
         @vSoldToId            = OH.SoldToId,
         @vSoldToAddressRegion = SOTA.AddressRegion,
         @vSoldToCountry       = SOTA.Country,
         @vShipToId            = OH.ShipToId,
         @vShipToCountry       = SHTA.Country,
         @vShipToAddressRegion = SHTA.AddressRegion,
         @vShipVia             = OH.ShipVia,
         @vCarrier             = SV.Carrier,
         @vFreightTerms        = OH.FreightTerms,
         @vBillToAddress       = OH.BillToAddress,
         @vBillToAccount       = OH.BillToAccount,
         @vAccount             = OH.Account,
         @vAccountName         = OH.AccountName,
         @vOwnership           = OH.Ownership,
         @vWarehouse           = OH.Warehouse,
         @vBusinessUnit        = OH.BusinessUnit
  from OrderHeaders OH
    left join vwSoldToAddress SOTA on (OH.SoldToId = SOTA.ContactRefId)
    left join vwShipToAddress SHTA on (OH.ShipToId = SHTA.ContactRefId)
    left join ShipVias          SV on (OH.ShipVia  = SV.ShipVia)
  where (OrderId = @OrderId);

  /* Build data to retrieve Shipping account Details */
  select @xmlData = dbo.fn_XMLNode('RootNode',
                       dbo.fn_XMLNode('OrderId',       @OrderId) +
                       dbo.fn_XMLNode('PickTicket',    @vPickTicket) +
                       dbo.fn_XMLNode('SalesOrder',    @vSalesOrder) +
                       dbo.fn_XMLNode('Carrier',       @vCarrier) +
                       dbo.fn_XMLNode('ShipToId',      @vShipToId) +
                       dbo.fn_XMLNode('SoldToId',      @vSoldToId) +
                       dbo.fn_XMLNode('ShipVia',       @vShipVia) +
                       dbo.fn_XMLNode('Account',       @vAccount) +
                       dbo.fn_XMLNode('AccountName',   @vAccountName) +
                       dbo.fn_XMLNode('BillToAccount', @vBillToAccount) +
                       dbo.fn_XMLNode('Ownership',     @vOwnership) +
                       dbo.fn_XMLNode('Warehouse',     @vWarehouse));

  /* Use the rules and get the Shipping Account Name and then the corresponding details */
  exec pr_Shipping_GetShippingAccountDetails @xmlData, @vBusinessUnit, @vUserId, @ShippingAccountXML output;

  /* Validate Ship From is available or not */
  if (not exists (select *
                  from Contacts
                  where (ContactRefId = @vShipFrom) and
                        (ContactType = 'F' /* Ship From */)))
    select @MessageName = 'Shipping_ShipFromNotAvailable';
  else
  /* Validate Account Details is available or not */
  if (@ShippingAccountxml is null)
    select @MessageName = 'Shipping_AccountDetailsNotAvailable';
  else
  /* Validate Sold To is available or not */
  if (coalesce(@vFreightTerms, '') in ('RECEIVER', 'RECIPIENT')) and
     (not exists (select *
                  from vwSoldToAddress
                  where (SoldToId = @vSoldToId)))
    select @MessageName = 'Shipping_SoldToNotAvailable';
  else
  /* Validate Ship To is available or not */
  if (not exists (select *
                  from vwShipToAddress
                  where (ShipToId = @vShipToId)))
    select @MessageName = 'Shipping_ShipToNotAvailable';
  /* This validation is not for all ShipVias, we need to evaluate which ShipVias required this validation later.
     Anyway Shippers can validate this return error messages, so as of now commented this */
  --else
  --if (((@vSoldToAddressRegion = 'I' /* International */) or (@vShipToAddressRegion = 'I' /* International */)) and
  --    (@vSoldToCountry <> @vShipToCountry))
  --  select @MessageName = 'Shipping_I_SoldShipCountriesDifferent';
  else
  /* Validate Bill To Address is available or not */
  if (coalesce(@vFreightTerms, '') = '3RDPARTY')
    begin
      if (not exists (select *
                      from Contacts
                      where (ContactRefId = @vBillToAddress) and
                            (ContactType = 'B' /* BillTo Address */)))
        select @MessageName = 'Shipping_BillToNotAvailable';
    end
  else
  /* Validate LPN's Actual weight is greater than or not */
  if (@LPNId is not null) and (coalesce(@vLPNWeight, 0) < 0.01)
    select @MessageName = 'Shipping_LPNWeightRequired';
  else
  /* Validate LPN's Carton Type is available or not */
  if (@LPNId is not null) and (coalesce(@vLPNCartonType, '') = '')
    select @MessageName = 'Shipping_LPNCartonTypeRequired';

  /* Build message if invalid data is present */
  if (coalesce(@MessageName, '') <> '')
    begin
      select @Message = dbo.fn_Messages_Build(@MessageName, @vPickTicket, @vLPN, null, null, null);

      /* Log into ResultMessages */
      insert into #ResultMessages (MessageType, MessageName)
        select 'E' /* Error */, @Message;

      /* Save Validations to AuditTrail */
      exec pr_Notifications_SaveValidations 'Order', @OrderId, @vPickTicket, 'NO', 'ShipValidations', @vBusinessUnit, null /* UserId */;

      /* If LPN entity is passed and there is no Entity is available in ShipLabels table insert with message, otherwise update with error and Process status */
      if (@vLPNId is not null) and (not exists(select EntityKey from ShipLabels where EntityId = @vLPNId))
        insert into Shiplabels (EntityId, EntityKey, OrderId, PickTicket, WaveId, WaveNo, ShipVia, TrackingNo, ProcessStatus, Notifications, BusinessUnit)
          select @LPNId, @vLPN, @OrderId, @vPickTicket, @vPickBatchId, @vPickBatchNo, @vShipVia, '', 'E' /* Error */, @Message, @vBusinessUnit;
      else
      if (@vLPNId is not null)
        update S
        set S.Notifications = @Message,
            S.ProcessStatus = 'LGE' /* Label Generation Error */
        from ShipLabels S
        where (EntityId = @vLPNId);
    end
end /* pr_Shipping_ValidateToShip */

Go
