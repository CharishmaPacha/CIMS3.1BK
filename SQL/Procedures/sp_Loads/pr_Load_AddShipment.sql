/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/02  TK      pr_Load_AddShipment: Changes to mark LPN status as Loaded (HA-1177)
  2016/05/03  OK      pr_Load_AddShipment: Seperated the insert satement to restrict violation error if multiple LPNs doesn't have PalletId on it (NBD-452)
  2015/09/12  YJ      pr_Load_AddShipment: Added missign parameters in calling the pr_Pallets_Recount (ACME-336)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_AddShipment') is not null
  drop Procedure pr_Load_AddShipment;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_AddShipment:
     It will internally calls the another proc name is  Load_ValidateAddShipment.
     If the Shipment is valid, then create a Load and Shipment association by updating
     the Load Id onto the Shipment.

------------------------------------------------------------------------------*/
Create Procedure pr_Load_AddShipment
  (@LoadId      TLoadId,
   @ShipmentId  TShipmentId,
   @Recount     TFlag = 'N' /* No */)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          /* Load Info */
          @vLoadId          TLoadId,
          @vLoadNumber      TLoadNumber,
          @vLoadingMethod   TTypeCode,
          /* Shipment Info */
          @vShipmentLoadId  TLoadId,
          /* Controls */
          @vMarkLPNAsLoaded TControlValue,

          @ttPallets        TEntityKeysTable,
          @vBusinessUnit    TBusinessUnit,
          @vUserId          TUserId;
begin /* pr_Load_AddShipment */
  select @ReturnCode  = 0,
         @Messagename = null,
         @Recount     = coalesce(@Recount, 'N'/* No */);

  select @vLoadId        = LoadId,
         @vLoadNumber    = LoadNumber,
         @vLoadingMethod = LoadingMethod,
         @vBusinessUnit  = BusinessUnit
  from Loads
  where (LoadId = @LoadId);

  select @vShipmentLoadId = LoadId
  from Shipments
  where (ShipmentId = @ShipmentId);

  if (@vLoadId is null)
    set @MessageName = 'InvalidLoad';
  else
  if (@ShipmentId is null)
    set @MessageName = 'InvalidShipment';
  else
  if ((coalesce(@vShipmentLoadId, 0) > 0) and
      (@vShipmentLoadId <> @vLoadId))
    set @MessageName = 'Load_AddShipment_OnAnotherLoad';

  /* If Shipment is already on the load, then do nothing */
  if ((coalesce(@vShipmentLoadId, 0) > 0) and
      (@vShipmentLoadId = @vLoadId))
    goto ExitHandler;

  if (@MessageName is not null)
    goto ErrorHandler;

  exec @ReturnCode = pr_Load_ValidateAddShipment @LoadId, @ShipmentId;

  /* Get the autoassignLPNs value from Controls */
  select @vMarkLPNAsLoaded = dbo.fn_Controls_GetAsString('Shipping', 'UpdateLPNStatusOnLoad', 'Y' /* Yes */,  @vBusinessUnit, @vUserId);

  /* If it is valid then we need to update LoadId on the Shipments and LPNs */
  if (@ReturnCode = 0)
    begin
      update Shipments
      set LoadId     = @LoadId,
          LoadNumber = @vLoadNumber
      where (ShipmentId = @ShipmentId);

      /* Update the LPNs and then recalculate Pallets */
      update LPNs
      set Status     = case when @vLoadingMethod = 'Auto' then 'L' /* Loaded */ else Status end,
          LoadId     = @LoadId,
          LoadNumber = @vLoadNumber
      where (ShipmentId = @ShipmentId);

      insert into @ttPallets (EntityId, EntityKey)
        select distinct PalletId, Pallet
        from LPNs
        where (ShipmentId = @ShipmentId);

      /* Recount all Pallets are on LPN so that Pallets could also get updated with LoadId */
      exec pr_Pallets_Recount @ttPallets, @vBusinessunit, @vUserId;

      /* Every time recounts will takes much time.So this changed to optional.
         If user needs then he can enable the flag from controls.*/
      if (@Recount = 'Y')
        begin
          /* Get latest counts for the Load and shipments */
          exec pr_Shipment_Recount @ShipmentId;

          exec pr_Load_Recount @vLoadId;
        end
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Load_AddShipment */

Go
