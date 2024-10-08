/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/11  RKC     pr_Pallets_TransferToPicklane: Revamped the code (FBV3-1109)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_TransferToPicklane') is not null
  drop Procedure pr_Pallets_TransferToPicklane;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_TransferToPicklane: Procedure to transfer each of the LPNs
    on the pallet to the given Picklane
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_TransferToPicklane
  (@xmlInput      xml,
   @xmlResult     xml = null output)
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
           @vWaveId           TRecordId,
           @vWaveNo           TWaveNo,

           @vReturnCode       TInteger,
           @vMessageName      TDescription,
           @vOperation        TOperation,
           @vBusinessUnit     TBusinessUnit,
           @vUserId           TUserId,
           @vDeviceId         TDeviceId,
           @vRecordId         TRecordId,

           @xmlTransferInfo   XML;

  declare @ttLPNsOnPallet Table
          (RecordId             TRecordId  identity (1,1),
           LPNDetailId          TRecordId,
           LPNId                TRecordId,
           LPN                  TLPN,
           SKUId                TRecordId,
           SKU                  TSKU,
           Quantity             TQuantity)
begin /* pr_Pallets_TransferToPicklane */
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId   = 0;

  /* Create #table if not exist */
  if (object_id('tempdb..#LPNsOnPallet') is null) select * into #LPNsOnPallet from @ttLPNsOnPallet;

  /* Get the values from Input XML */
  select @vPalletId     = Record.Col.value('PalletId[1]',      'TRecordId'   ),
         @vLocationId   = Record.Col.value('LocationId[1]',    'TPallet' ),
         @vOperation    = Record.Col.value('Operation[1]',     'TOperation'  ),
         @vDeviceId     = Record.Col.value('DeviceId[1]',      'TDeviceId'     ),
         @vUserId       = Record.Col.value('UserId[1]',        'TUserId'       ),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]',  'TBusinessUnit' )
  from @xmlInput.nodes('/Root') as Record(Col);

   /* Get the Location details*/
  select @vLocationId   = LocationId,
         @vLocation     = Location,
         @vLocationType = LocationType
  from Locations
  where (LocationId = @vLocationId);

  /* Get Pallet details */
  select @vPalletId = PalletId,
         @vPallet   = Pallet,
         @vWaveId   = PickBatchId,
         @vWaveNo   = PickBatchNo
  from Pallets
  where (PalletId = @vPalletId);

  /* Insert the LPN which are on the Pallet into a temp table */
  Insert #LPNsOnPallet (LPNDetailId, LPNId, LPN, SKUId, SKU, Quantity)
    select LD.LPNDetailId, LD.LPNId, L.LPN, LD.SKUId, S.SKU, LD.Quantity
    from LPNs L
      join LPNDetails LD on (L.LPNId = LD.LPNId)
      join SKUs        S on (LD.SKUId = S.SKUId)
    where (L.PalletId = @vPalletId)
    order by LD.LPNDetailId;

  /* Start the loop for transfering LPNs to Processing area */
  while exists(select * from #LPNsOnPallet where RecordId > @vRecordId)
    begin
      /* select the top 1 LPNDetail info to process */
      select top 1 @vLPNId       = LPNId,
                   @vLPN         = LPN,
                   @vSKUId       = SKUId,
                   @vSKU         = SKU,
                   @vQuantity    = Quantity,
                   @vLPNDetailId = LPNDetailId,
                   @vRecordId    = RecordId
      from #LPNsOnPallet
      where RecordId > @vRecordId
      order by RecordId

      /* build xml here to pass it procedure */
      select @xmlTransferInfo = (select @vLPNId           as FromLPNId,
                                        @vLPN             as FromLPN,
                                        @vLPNId           as CurrentLPNId,
                                        @vLPNDetailId     as CurrentLPNDetailId,
                                        @vSKUId           as CurrentSKUId,
                                        @vSKU             as CurrentSKU,
                                        @vQuantity        as TransferQuantity,
                                        @vLocationId      as ToLocationId,
                                        @vLocation        as ToLocation,
                                        @vLocation        as DestinationLocationOrLPN,
                                        @vOperation       as Operation,
                                        @vBusinessUnit    as BusinessUnit,
                                        @vUserId          as UserId,
                                        @vDeviceId        as DeviceId
                                 for xml raw('TransferInventory'), elements);

      exec pr_RFC_TransferInventory @xmlTransferInfo, @XmlResult output;

    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;
end try
begin catch
  /* Handling transactions in case it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  exec pr_ReRaiseError;

end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_Pallets_TransferToPicklane */

Go
