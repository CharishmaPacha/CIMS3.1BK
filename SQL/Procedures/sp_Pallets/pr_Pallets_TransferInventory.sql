/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/09/14  TK      pr_Pallets_TransferInventory: Pass DestinationLocationOrLPN for TransferInventory proc (S2GCA-216)
  2016/05/09  TD      pr_Pallets_TransferInventory:Changes to send xml to the main procedure.
  2015/02/26  TK      pr_Pallets_TransferInventory: Added missing variable in the procedure signature
  2012/07/10  YA      pr_Pallets_TransferInventory: Handling transactions in case if transactions is rolled back from subprocedure.
  2012/07/03  VM      pr_Pallets_TransferInventory: Implement transaction controls as it is callin another RFC proc
  2012/06/29  PK      Added pr_Pallets_TransferInventory.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_TransferInventory') is not null
  drop Procedure pr_Pallets_TransferInventory;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_TransferInventory: Procedure to transfer each of the LPNs
    on the pallet to the given Location
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_TransferInventory
  (@PalletId       TRecordId,
   @LocationId     TRecordId,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare  @vLocationId       TRecordId,
           @vLocation         TLocation,
           @vLocationType     TTypeCode,
           @vPalletId         TRecordId,
           @vPallet           TPallet,
           @vLPNCount         TCount,
           @vLPNId            TRecordId,
           @vLPN              TLPN,
           @vSKUId            TRecordId,
           @vSKU              TSKU,
           @vLPNDetailId      TRecordId,
           @vQuantity         TQuantity,
           @xmlTransferInfo   XML,
           @xmlResult         XML,

           @ReturnCode        TInteger,
           @MessageName       TDescription;

  declare @ttLPNsOnPallet Table
          (RecordId             TRecordId  identity (1,1),
           LPNDetailId          TRecordId,
           LPNId                TRecordId,
           LPN                  TLPN,
           SKUId                TRecordId,
           SKU                  TSKU,
           Quantity             TQuantity)

begin /* pr_Pallets_TransferInventory */
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @ReturnCode = 0,
         @MessageName = null;

   /* Get the Location details*/
  select @vLocationId   = LocationId,
         @vLocation     = Location,
         @vLocationType = LocationType
  from Locations
  where (LocationId = @LocationId);

  /* Get Pallet details */
  select @vPalletId = PalletId,
         @vPallet   = Pallet
  from Pallets
  where (PalletId = @PalletId);

  /* Insert the LPN which are on the Pallet into a temp table */
  Insert @ttLPNsOnPallet (LPNDetailId, LPNId, LPN, SKUId, SKU, Quantity)
    select LPNDetailId, LPNId, LPN, SKUId, SKU, Quantity
    from vwLPNDetails
    where (PalletId = @vPalletId);

  /* Fetch the count of LPNs on the pallet */
  select @vLPNCount = @@rowcount;

  /* Start the loop for transfering LPNs to Processing area */
  while (@vLPNCount > 0)
    begin
      /* select the top 1 LPNDetail info to process */
      select top 1 @vLPNId       = LPNId,
                   @vLPN         = LPN,
                   @vSKUId       = SKUId,
                   @vSKU         = SKU,
                   @vQuantity    = Quantity,
                   @vLPNDetailId = LPNDetailId
      from @ttLPNsOnPallet;

      /* build xml here to pass it procedure */
      select @xmlTransferInfo = (select @vLPNId           as FromLPNId,
                                        @vLPN             as FromLPN,
                                        @vSKUId           as CurrentSKUId,
                                        @vSKU             as CurrentSKU,
                                        @vQuantity        as TransferQuantity,
                                        @vLocationId      as ToLocationId,
                                        @vLocation        as ToLocation,
                                        @vLocation        as DestinationLocationOrLPN,
                                        @BusinessUnit     as BusinessUnit,
                                        @UserId           as UserId
                                 for xml raw('TransferInventory'), elements);

      exec pr_RFC_TransferInventory @xmlTransferInfo, @XmlResult output;

      /* delete the line from the temp table as it is already transfered to the location */
      delete from @ttLPNsOnPallet
      where (LPNDetailId = @vLPNDetailId) and (LPNId = @vLPNId) and
            (SKUId = @vSKUId) and (Quantity = @vQuantity);

      /* Get the updated count of LPNs */
      select @vLPNCount = count(*)
      from @ttLPNsOnPallet;
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  /* Handling transactions in case it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  select @MessageName = ERROR_MESSAGE(),
         @ReturnCode = 1;

  raiserror(@MessageName, 16, 1);
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_Pallets_TransferInventory */

Go
