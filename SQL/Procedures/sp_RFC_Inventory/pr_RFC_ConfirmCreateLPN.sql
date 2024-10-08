/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/06  RIA     pr_RFC_ExplodePrepack, pr_RFC_ConfirmCreateLPN, pr_RFC_TransferPallet: Changes to pr_LPNs_AddSKU signature (HA-1794)
  2015/05/05  OK      pr_RFC_AddSKUToLocation, pr_RFC_AdjustLocation, pr_RFC_ConfirmCreateLPN, pr_RFC_Inv_DropBuildPallet,
                      pr_RFC_Inv_MovePallet, pr_RFC_MoveLPN, pr_RFC_RemoveSKUFromLocation, pr_RFC_TransferInventory,
                      pr_RFC_ValidateLocation: Made system compatable to accept either Location or Barcode.
  2010/12/31  VM      pr_RFC_MoveLPN, pr_RFC_ConfirmCreateLPN:
                        Sent value to newly added param in pr_LPNs_Move
  2010/12/16  VM      pr_RFC_ConfirmCreateLPN: Continue to exectute next set of statements after
                        the success call to pr_LPNs_AddSKU.
  2010/12/15  PK      Created pr_RFC_CreateLPN, pr_RFC_ConfirmCreateLPN, Minor Corrections.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ConfirmCreateLPN') is not null
  drop Procedure pr_RFC_ConfirmCreateLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ConfirmCreateLPN:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ConfirmCreateLPN
  (@LPN          TLPN,
   @SKU          TSKU,
   @Quantity     TQuantity,
   @Location     TLocation,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @ReturnCode     TInteger,
          @MessageName    TMessageName,
          @Message        TDescription,

          @LocationId     TRecordId,
          @SKUId          TRecordId,
          @vSKUId         TRecordId,
          @vSKU           TSKU,
          @vLPNId         TRecordId,
          @vLPN           TLPN,
          @vLPNStatus     TStatus,
          @vLocationId    TRecordId,
          @vLocation      TLocation;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @vLocationId = LocationId,
         @vLocation   = Location
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @Location, null /* DeviceId */, @UserId, @BusinessUnit));

  select @vSKUId = SKUId,
         @vSKU   = SKU
  from SKUs
  where ((SKUId        = @SKUId)or
         (SKU          = @SKU)) and
         (BusinessUnit = @BusinessUnit);

  /* Fetching LPNId and LPN to call pr_LPNs_AddSKU and pr_LPNs_Move */
  select @vLPNId     = LPNId,
         @vLPN       = LPN,
         @vLPNStatus = Status
  from LPNs
  where (LPN          = @LPN) and
        (BusinessUnit = @BusinessUnit);

  /* Validate SKU */
  if (@vSKUId is null)
     set @MessageName = 'SKUDoesNotExist';
  else
  if (@vLocationId is null)
     set @MessageName = 'LocationDoesNotExist';
  else
   /* Validate Quantity */
  if (@Quantity <= 0)
     set @MessageName = 'InvalidQuantity';

  if (@MessageName is not null)
     goto ErrorHandler;

  /* Set LPN's SKU */
  exec @ReturnCode = pr_LPNs_AddSKU @vLPNId,
                                    @vLPN,
                                    null, /* SKUId */
                                    @vSKU,
                                    null /* @InnerPacks */,
                                    @Quantity,
                                    0, /* Reason Code */
                                    '', /* InventoryClass1 */
                                    '', /* InventoryClass2 */
                                    '', /* InventoryClass3 */
                                    @BusinessUnit,
                                    @UserId;

  if (@ReturnCode > 0)
    goto ErrorHandler;

  /* Set LPN's Location */
  exec @ReturnCode = pr_LPNs_Move @vLPNId,
                                  @vLPN,
                                  @vLPNStatus,
                                  @vLocationId,
                                  @vLocation,
                                  @BusinessUnit,
                                  @UserId;

  if (@ReturnCode = 0)
    begin
      /* Audit Trail */
      exec pr_AuditTrail_Insert 'LPNCreated', @UserId, null /* ActivityTimestamp */,
                                @LPNId      = @vLPNId,
                                @SKUId      = @vSKUId,
                                @LocationId = @vLocationId,
                                @Quantity   = @Quantity;


      end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_ConfirmCreateLPN */

Go
