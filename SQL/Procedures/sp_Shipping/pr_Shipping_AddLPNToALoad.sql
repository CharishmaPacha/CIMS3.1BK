/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/23  AY      pr_Shipping_GetBoLData: Print ShipToName with Consolidator addres (HA-2054)
                      pr_Shipping_AddLPNToALoad: Do not mark LPN as loaded when added to Load (HA-2002)
  2021/01/23  TK      pr_Shipping_AddLPNToALoad: Do not log audit trail as caller will be taking care of it (HA-1947)
  2013/11/14  TD      pr_Shipping_AddLPNToALoad:Audit Log changes.
  2013/10/19  PK      pr_Shipping_AddLPNToALoad: Calling pallet recount to update the status and load and shipment on the pallet.
  2013/10/11  PK      Added pr_Shipping_GetLoadInfo, pr_Shipping_AddLPNToALoad.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_AddLPNToALoad') is not null
  drop Procedure pr_Shipping_AddLPNToALoad;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_AddLPNToALoad: This procedure updates LPNs with the Loads on an order
    it belongs to. This would be useful when a Load is already created without
    LPNs and the LPNs are picked later.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_AddLPNToALoad
  (@LPNId          TRecordId,
   @LoadId         TLoadId,
   @ShipmentId     TShipmentId,
   @LoadRecount    TFlag = 'N' /* No */,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId = null)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,

          @vOrderId          TRecordId,
          @vShipmentId       TRecordId,
          @vLoadId           TRecordId,
          @vLoadNumber       TLoadNumber,
          @vLoadingMethod    TTypeCode,
          @vBoLNumber        TBoLNumber,
          @vBoLId            TBoLId,
          @vPalletId         TRecordId;
begin
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* select the LoadNumber */
  select @vLoadId        = LoadId,
         @vLoadNumber    = LoadNumber,
         @vLoadingMethod = LoadingMethod
  from Loads
  where (LoadId       = @LoadId) and
        (BusinessUnit = @BusinessUnit);

  /* select the Shipment Info */
  select @vBolId      = BolId,
         @vBoLNumber  = BoLNumber,
         @vShipmentId = ShipmentId
  from Shipments
  where (ShipmentId   = @ShipmentId) and
        (BusinessUnit = @BusinessUnit);

  /* Update LPNs */
  update LPNs
  set @vPalletId = PalletId,
      LoadId     = @vLoadId,
      LoadNumber = @vLoadNumber,
      ShipmentId = @vShipmentId,
      BoL        = @vBoLNumber,
      Status     = case when @vLoadingMethod = 'Auto' and  (charindex(Status, 'KGDE') <> 0) then 'L' /* Loaded */ else Status end
  where (LPNId = @LPNId);

  /* Pallet Recount */
  if (@vPalletId is not null)
    exec pr_Pallets_UpdateCount @vPalletId, @UpdateOption = '*';

  /* Recount */
  if (@LoadRecount = 'Y' /* Yes */)
    begin
      exec pr_Load_Recount @vLoadId;
      exec pr_Shipment_Recount @vShipmentId;

      /* Recalculate  if the order is already on the BoL*/
      if (coalesce(@vBoLId, 0) <> 0)
        exec pr_BoL_Recount @vBoLId;
    end

  /* Insert Audit Trail */
  exec pr_AuditTrail_Insert 'LPNAddedToLoad', @UserId, null /* ActivityTimestamp */,
                            @LPNId         = @LPNId,
                            @PalletId      = @vPalletId,
                            @ShipmentId    = @vShipmentId,
                            @LoadId        = @vLoadId;
ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_AddLPNToALoad */

Go
