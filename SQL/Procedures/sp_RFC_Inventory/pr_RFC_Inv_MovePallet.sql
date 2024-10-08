/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/31  TK      pr_RFC_MoveLPN & pr_RFC_Inv_MovePallet: Pass Order info to log AT (HA-3031)
  2021/03/19  RKC     pr_RFC_Inv_MovePallet : Made changes to get the NumLPNs counts on the AT message (HA-2340)
  2020/08/19  AY/RIA  pr_RFC_Inv_MovePallet: Merge Pallets (HA-1245)
  2020/04/07  VM      pr_RFC_Inv_MovePallet: Run Inv_ValidateTransferInv rules (HA-118)
                      pr_RFC_Inv_MovePallet, pr_RFC_MoveLPN, pr_RFC_RemoveSKUFromLocation, pr_RFC_TransferInventory,
  2012/12/07  VM      pr_RFC_Inv_MovePallet: Storage type validation corrected
  2012/11/06  YA      pr_RFC_Inv_MovePallet: Modified to include Warehouse mismatch validation.
                      pr_RFC_Inv_MovePallet: Modified to move pallet to locations with storage type Pallets or Pallet&LPNs.
  2012/06/22  AY      pr_RFC_Inv_MovePallet: Changed building of response
                      pr_RFC_Inv_DropBuildPallet, pr_RFC_Inv_MovePallet on 21-Feb-2012.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Inv_MovePallet') is not null
  drop Procedure pr_RFC_Inv_MovePallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Inv_MovePallet: Used to Move a Pallet to a Location or merge the
    Pallet to another Pallet

  <MOVEDPALLETDETAILS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
   <MOVEDPALLETINFO>
    <ErrorNumber>0</ErrorNumber>
    <ErrorMessage>PalletMovedSuccessfully</ErrorMessage>
   </MOVEDPALLETINFO>
  </MOVEDPALLETDETAILS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Inv_MovePallet
  (@Pallet       TPallet,
   @NewLocation  TLocation, -- New Location or Pallet
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId,
   @DeviceId     TDeviceId,
   @xmlResult    xml      output)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TDescription,

          @vPalletId                TRecordId,
          @vNewLocationId           TRecordId,
          @vNewLocation             TLocation,
          @vLocationType            TLocationType,
          @vLocStorageType          TStorageType,
          @vNumLPNs                 TCount,
          @vLocationId              TRecordID,
          @vPalletStatus            TStatus,
          @vQuantity                TQuantity,
          @vLocation                TLocation,
          @vSKUId                   TRecordId,
          @vPalletSKU               TSKU,
          @vPalletSKUDesc           TDescription,
          @vPalletOrderId           TRecordId,
          @vPalletType              TTypeCode,
          @vPalletWarehouse         TWarehouse,
          @vReservedLPNsOnPallet    TCount,
          @vLocWarehouse            TWarehouse,

          @vNewPalletId             TRecordId,
          @vNewPallet               TPallet,
          @vNewPalletWarehouse      TWarehouse,
          @vNewPalletLocId          TRecordId,
          @vNewPalletStatus         TStatus,
          @vNewPalletLPNs           TCount,
          @vScannedEntity           TEntity,

          @vToLocationId            TRecordId,

          @xmlResultvar             varchar(Max),
          @ttPalletLPNs             TEntityKeysTable,
          @vAuditRecordId           TRecordId,
          @vAuditActivity           TActivityType,

          @vLPNId                   TRecordId,
          @vLPN                     TLPN,
          @vRecordId                TRecordId,
          @vSourceLPNWH             TWarehouse,
          @vDestLPNWH               TWarehouse,
          @Note1                    TDescription,

          @vAllowMoveBetweenWarehouses
                                    TControlValue,
          @vxmlResult               xml,
          @xmlRulesData             TXML;

  declare @ttLPNs            TEntityKeysTable;
begin
begin try
begin transaction
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get Pallet Info */
  select @vPalletId        = PalletId,
         @vPalletType      = PalletType,
         @vNumLPNs         = NumLPNs,
         @vQuantity        = Quantity,
         @vPalletStatus    = Status,
         @vLocationId      = LocationId,
         @vLocation        = Location,
         @vSKUId           = SKUId,
         @vPalletSKU       = SKU,
         @vPalletSKUDesc   = SKUDescription,
         @vPalletOrderId   = OrderId,
         @vPalletWarehouse = Warehouse
  from vwPallets
  where (PalletId = dbo.fn_Pallets_GetPalletId (@Pallet, @BusinessUnit));

  select @vNewLocationId = LocationId,
         @vNewLocation   = Location,
         @vScannedEntity = 'Location',
         @vAuditActivity = 'PalletMoved'
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @NewLocation, @DeviceId, @UserId, @BusinessUnit));

  /* If user hasn't scanned a Location, check if it is a pallet */
  if (@vNewLocationId is null)
    select @vNewPalletId        = PalletId,
           @vNewPallet          = Pallet,
           @vNewPalletStatus    = Status,
           @vNewPalletLPNs      = NumLPNs,
           @vNewPalletWarehouse = Warehouse,
           @vNewPalletLocId     = LocationId,
           @vScannedEntity      = 'Pallet',
           @vAuditActivity      = 'PalletsMerged'
    from Pallets
    where PalletId = dbo.fn_Pallets_GetPalletId (@NewLocation, @BusinessUnit);

  /* Get attributes of the scanned Location or the Location the Destination Pallet is in */
  select @vToLocationId   = LocationId,
         @vLocationType   = LocationType,
         @vLocStorageType = StorageType,
         @vLocWarehouse   = Warehouse
  from Locations
  where (LocationId = coalesce(@vNewLocationId, @vNewPalletLocId));

  select @vReservedLPNsOnPallet = sum(case when OrderId is not null then 1 else 0 end)
  from LPNs
  where (PalletId = @vPalletId);

  select @vAllowMoveBetweenWarehouses = dbo.fn_Controls_GetAsString('Inventory', 'MoveBetweenWarehouses', 'Y' /* Yes */,
                                                                    @BusinessUnit, @UserId);

  /* Build the XML for custom validations */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                         dbo.fn_XMLNode('Operation',      'MovePallet'    ) +
                         dbo.fn_XMLNode('PalletId',       @vPalletId      ) +
                         dbo.fn_XMLNode('ScannedEntity',  @vScannedEntity ) +
                         dbo.fn_XMLNode('NewLocationId',  @vNewLocationId ) +
                         dbo.fn_XMLNode('NewPalletId',    @vNewPalletId   ));

  /* Validations */
  if (@vPalletId is null)
    set @vMessageName = 'PalletDoesNotExist';
  else
  if (@vNewLocationId is null) and (@vNewPalletId is null)
    set @vMessageName = 'MovePallet_InvalidLocationorPallet';
  else
  if (@vNumLPNs = 0) or (@vQuantity = 0)
    set @vMessageName = 'MovePallet_CannotMoveEmptyPallet';
  else
  if (@vScannedEntity = 'Pallet') and (@vNewPalletStatus = 'E' /* Empty */)
    set @vMessageName = 'MovePallet_CannotMergeWithEmptyPallet';
  else
  if (@vReservedLPNsOnPallet > 0) and
     (@vLocationType in ('R' /* Reserve */, 'B' /* Bulk */))
    set @vMessageName = 'MovePallet_ResvLPNsInvalidLocationType';
  else
  if (@vScannedEntity = 'Location') and (charindex('A' /* Pallets */, @vLocStorageType) = 0)  /* If storage type does not have A, then Pallet is not allowed */
    set @vMessageName = 'PalletAndStorageTypeMismatch';
  else
  if (@vAllowMoveBetweenWarehouses = 'N') and
     (@vScannedEntity = 'Location') and
     (coalesce(@vPalletWarehouse, '') <> '') and
     (coalesce(@vPalletWarehouse, '') <> coalesce(@vLocWarehouse, ''))
    set @vMessageName = 'PalletsWarehouseMismatch';
  else
  if (@vAllowMoveBetweenWarehouses = 'N') and
     (@vScannedEntity = 'Pallet') and
     (coalesce(@vPalletWarehouse, '') <> '') and
     (coalesce(@vPalletWarehouse, '') <> coalesce(@vNewPalletWarehouse, ''))
    set @vMessageName = 'PalletsWarehouseMismatch';

  /* Apply custom rules to verify */
  if (@vMessageName is null)
    exec pr_RuleSets_Evaluate 'Inv_ValidateTransferInv', @xmlRulesData, @vMessageName output;

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Set Location of Pallet and LPNs on the Pallet to the new Location */
  if (@vScannedEntity = 'Location')
    exec pr_Pallets_SetLocation @vPalletId, @vNewLocationId, 'Y' /* Yes, Update LPNs as well */, @BusinessUnit, @UserId;
  else
  if (@vScannedEntity = 'Pallet') /* Move all LPNs to new Pallet */
    begin
      insert into @ttLPNs (EntityId, EntityKey)
        select LPNId, LPN
        from LPNs
        where (PalletId = @vPalletId)
        order by LPNId;

      /* Get the Total LPN counts */
      select @Note1 = @@rowcount;

      /* Loop thru all LPNs on the Pallet and call pr_LPNs_SetPallet for each */
      while exists (select * from @ttLPNs where RecordId > @vRecordId)
        begin
          select top 1 @vRecordId = RecordId,
                       @vLPNId    = EntityId,
                       @vLPN      = EntityKey
          from @ttLPNs
          where (RecordId > @vRecordId)
          order by RecordId;

          exec pr_RFC_Inv_AddLPNToPallet @vNewPallet, @vLPN, @BusinessUnit, @UserId,
                                         @DeviceId, @vxmlResult output;
        end
    end

  /* Update Pallet status */
  exec pr_Pallets_SetStatus @vPalletId, @UserId = @UserId;

  /* Get Confirmation Message */
  select @vMessage = case when (@vNewPalletId is not null) then 'PalletsMerged_Successful1y'
                          when (@vLocation is null) then 'MovePallet_Successful'
                          else 'MovePallet_Successful2'
                     end;

  /* XmlMessage to RF, after Pallet is Moved to a Location */
  if (@vNewPalletId is not null)
    exec pr_BuildRFSuccessXML @vMessage, @xmlResult output, @Pallet, @vNewPallet, @vNumLPNs;
  else
    exec pr_BuildRFSuccessXML @vMessage, @xmlResult output, @vLocation, @vNewLocation;

  /* Update Device details */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'MovePallet', @xmlResultvar, @@ProcId;

  /* Get all LPNs on Pallet to link to AT */
  insert into @ttPalletLPNs(EntityId, EntityKey)
    select LPNId, LPN from LPNs where (PalletId = @vPalletId);

  /* Audit Trail */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @PalletId      = @vPalletId,
                            @Quantity      = @vQuantity,
                            @ToPalletId    = @vNewPalletId,
                            @LocationId    = @vLocationId,
                            @ToLocationId  = @vToLocationId,
                            @OrderId       = @vPalletOrderId,
                            @Note1         = @Note1,
                            @AuditRecordId = @vAuditRecordId output;

  /* Now insert all the LPNs into Audit Entities i.e link above Audit Record
     to all the LPNs on Pallet which are Moved to new Location */
  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'LPN', @ttPalletLPNs, @BusinessUnit;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;
end catch;
end /* pr_RFC_Inv_MovePallet */

Go
