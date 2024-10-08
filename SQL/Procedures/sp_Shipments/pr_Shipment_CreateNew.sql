/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/01  TK      pr_Shipment_CreateNew: Changes to create shipments for LPNs that are not associated with any order (HA-830)
  2015/06/10  VM      pr_Shipment_CreateNew: Take LoadNumber as well along with LoadId on Shipment
  2012/08/22  YA      pr_Shipment_CreateNew: Modified condition to filter on LoadId.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipment_CreateNew') is not null
  drop Procedure pr_Shipment_CreateNew;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipment_CreateNew:
     This proc will get the OrderInfo from OrderHeaders based on the passing OrderId,
     and validates the ShipmentId. If ShipmentId is exists then directly we insert
     shipmentId and OrderId into OrderShipments, else insert OrderId into Shipments.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipment_CreateNew
  (@OrderId        TRecordId,
   @LoadId         TLoadId,
   @AutoAssignLPNs TFlag,
   @UserId         TUserId = null,
   ------------------------------------
   @ShipmentId     TShipmentId  output)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          /* Order Info */
          @vSoldToId           TCustomerId,
          @vShipToId           TShipToId,
          @vReturnAddress      TReturnAddress,
          @vShipVia            TShipVia,
          @vShipFrom           TShipFrom,
          @vOrderId            TRecordId,
          @vOrderType          TTypeCode,
          @vBusinessUnit       TBusinessUnit,
          @vDesiredShipDate    TDateTime,
          @vFreightTerms       TDescription,
          /* LPN Info */
          @vCartonType         TCartonType,
          @vCustomerContactId  TRecordId,
          @VShipToContactId    TRecordId,
          /* Load Info */
          @vLoadType           TTypeCode,
          @vLoadSoldToId       TCustomerId,
          @vLoadShipToId       TShipToId,
          @vLoadShipVia        TShipVia,
          @vLoadShipFrom       TShipFrom,
          /* Carrier Info */
          @vCarrier            TCarrier,
          @vLoadNumber         TLoadNumber,
          /* Shipment Info */
          @vShipmentId         TShipmentId,
          @vShipmentLoadId     TLoadId,
          @vShipmentLoadNumber TLoadNumber,
          @vBillTo             TCustomerId;

  declare @Inserted table (ShipmentId TShipmentId);
begin /* pr_Shipment_CreateNew */
  select @ReturnCode     = 0,
         @AutoAssignLPNs = coalesce(@AutoAssignLPNs, 'N' /* No */),
         @Messagename    = null;

  /* At times, ShipFrom is not used at all by the Host.
     In such instances, the From Warehouse on the Order would serve as ShipFrom */
  select @vOrderId         = OrderId,
         @vSoldToId        = SoldToId,
         @vShipToId        = ShipToId,
         @vReturnAddress   = ReturnAddress,
         @vShipVia         = ShipVia,
         @vShipFrom        = coalesce(ShipFrom, Warehouse),
         @vFreightTerms    = FreightTerms,
         @vOrderType       = OrderType,
         @vDesiredShipDate = DesiredShipDate
  from OrderHeaders
  where (OrderId = @OrderId);

  select @vLoadNumber    = LoadNumber,
         @vLoadType      = LoadType,
         @vLoadShipToId  = ShipToId,
         @vLoadSoldToId  = SoldToId,
         @vLoadShipVia   = ShipVia,
         @vLoadShipFrom  = FromWarehouse,
         @vBusinessUnit  = BusinessUnit
  from Loads
  where (LoadId = @LoadId);

  /* If the LPN being loaded is not associated to any order then use Load info */
  if (@vLoadType = 'Transfer')
    select @vSoldToId = coalesce(@vSoldToId, @vLoadSoldToId, @vLoadShipToId),
           @vShipToId = coalesce(@vShipToId, @vLoadShipToId),
           @vShipVia  = coalesce(@vShipVia,  @vLoadShipVia),
           @vShipFrom = coalesce(@vShipFrom, @vLoadShipFrom);

  /* Below are future Use*/
  /* Get Customer AddressId */
  select @vCustomerContactId = CustomerContactId
  from Customers
  where (CustomerId = @vSoldToId);

  /* Get ShipToAddressId */
  select @vShipToContactId = ShipToAddressId
  from ShipTos
  where (ShipToId = @vShipToId);

  select @vCarrier = Carrier
  from ShipVias
  where (ShipVia = @vShipVia);

  /* Find a shipment that the order can be added to */
  select @ShipmentId          = ShipmentId,
         @vShipmentId         = ShipmentId,
         @vShipmentLoadId     = LoadId,
         @vShipmentLoadNumber = LoadNumber
  from Shipments
  where (SoldTo   = @vSoldToId) and
        (ShipTo   = @vShipToId) and
        (ShipVia  = @vShipVia)  and
        (ShipFrom = @vShipFrom) and
        (LoadId   = @LoadId);

  /* Create a New Shipment, for the specific criteria, if one does not exist */
  if (@vShipmentId is null)
    begin
      insert into Shipments(ShipFrom,
                            ShipTo,
                            ShipVia,
                            SoldTo,
                            BillTo,
                            FreightTerms,
                            ShipmentType,
                            LoadId,
                            LoadNumber,
                            DesiredShipDate,
                            BusinessUnit,
                            CreatedBy)
                     output inserted.ShipmentId
                       into @Inserted
                     select @vShipFrom,
                            @vShipToId,
                            @vShipVia,
                            @vSoldToId,
                            @vBillTo,
                            coalesce(@vFreightTerms, 'PREPAID'),
                            coalesce(@vOrderType, @vLoadType),  -- At present we are updating Shipment Type with Order Type.
                            @LoadId,
                            @vLoadNumber,
                            @vDesiredShipDate,
                            @vBusinessUnit,
                            coalesce(@UserId, system_user);

      select @vShipmentId = ShipmentId,
             @ShipmentId  = ShipmentId
      from @Inserted;
    end

  /* Add Order to Shipment */
  if (@vOrderId is not null)
    exec pr_Shipment_AddOrder @vOrderId, @ShipmentId, @AutoAssignLPNs, @vBusinessUnit, @UserId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipment_CreateNew */

Go
