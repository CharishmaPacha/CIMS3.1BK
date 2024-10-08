/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/06  RIA     pr_RFC_ExplodePrepack, pr_RFC_ConfirmCreateLPN, pr_RFC_TransferPallet: Changes to pr_LPNs_AddSKU signature (HA-1794)
  2020/08/25  TK      pr_RFC_TransferPallet: Changes to recount order during partial pallet transfers (S2GCA-1243)
  2019/05/20  YJ      pr_RFC_TransferPallet: Migrated from staging (S2G-727)
  2019/05/02  AY      pr_RFC_TransferPallet: Update Ownership on new LPN (S2GCA-666)
  2018/11/22  RT      pr_RFC_TransferPallet: Added Audit Trail for LPN when we transfer Ful Pallet (HPI-2169)
  2013/12/20  TD      pr_RFC_TransferPallet: Changes to merge LPNs if those were picked for same Order Line.
  2013/12/14  PK      pr_RFC_TransferPallet: Changes in logging Audit Trail comments
                      pr_RFC_TransferPallet: Included a validation for not allowing to transfer pallets of different stores,
                        not allowing to transfer pallets of different Loads, and pallets of different status if they are already on load.
                      pr_RFC_TransferPallet: Logging AuditTrail, returning success messages and fixed few fixes.
  2013/11/13  PK      Added pr_RFC_TransferPallet.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_TransferPallet') is not null
  drop Procedure pr_RFC_TransferPallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_TransferPallet:

<?xml version="1.0" encoding="utf-16"?>
<TRANSFERPALLETDETAILS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <PALLETINFO>
    <FromPallet>P000003</FromPallet>
    <ToPallet>P000004</ToPallet>
    <Operation>F</Operation>
  </PALLETINFO>
  <PALLETLPNDETAILS>
    <LPNINFO>
      <LPN>W000001957</LPN>
      <LPNDetailId>123</LPNDetailId>
      <Quantity>2</Quantity>
      <UoM>CS</UoM>
      <SKU>28134</SKU>
    </LPNINFO>
    <LPNINFO>
      <LPN>W000002252</LPN>
      <LPNDetailId>124</LPNDetailId>
      <Quantity>6</Quantity>
      <UoM>CS</UoM>
      <SKU>57352</SKU>
    </LPNINFO>
  </PALLETLPNDETAILS>
</TRANSFERPALLETDETAILS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_TransferPallet
  (@xmlInput     xml,
   @xmlResult    xml output)
as
  declare @ReturnCode             TInteger,
          @MessageName            TMessageName,

          /* Input params */
          @FromPallet             TPallet,
          @SKU                    TSKU,
          @InnerPacks             TInnerPacks, /* Future Use */   -- names inconsistent, one is called just innerpacks and other is called 'TransferQty'
          @Quantity               TQuantity,
          @ToPallet               TPallet,
          @BusinessUnit           TBusinessUnit,
          @UserId                 TUserId,

          /* From Pallet Info */
          @vFromPallet            TPallet,
          @vFromPalletId          TRecordId,
          @vFromWarehouse         TWarehouse,
          @vFromPalletQty         TQuantity,
          @vFromPalletNumLPNs     TCount,
          @vFromPalletStatus      TStatus,
          @vFromPalletLoadId      TLoadId,
          @vFromPalletShipToId    TShipToId,

          @vFromLPNId             TRecordId,
          @vFromLPNDetailId       TRecordId,
          @vFromLPNSKUId          TRecordId,
          @vFromLPNSKU            TSKU,
          @vFromLPNStatus         TStatus,
          @vFromLPNOnhandStatus   TStatus,
          @vFromLPNDetailOnhandStatus
                                  TStatus,
          @vFromLocationId        TRecordId,
          @vFromLPNOrderId        TRecordId,
          @vFromLPNOrderDetailId  TRecordId,
          @vFromLPNLoadId         TLoadId,
          @vFromLPNShipmentId     TShipmentId,
          @vFromLPNQuantity       TQuantity,
          @vFromLPNOwnership      TOwnership,
          @vUnitsPerInnerpack     TInteger,

          /* To Pallet Info */
          @vToPallet              TPallet,
          @vToPalletId            TRecordId,
          @vToWarehouse           TWarehouse,
          @vToPalletStatus        TStatus,
          @vToPalletLoadId        TLoadId,
          @vToPalletShipToId      TShipToId,

          @vToLPN                 TLPN,
          @vToLPNId               TRecordId,
          @vToLPNDetailId         TRecordId,

          /* SKU Info */
          @vSKU                   TSKU,
          @vSKUId                 TRecordId,

          @vUoM                   TUoM,
          @vRecordId              TRecordId,
          @ReasonCode             TReasonCode,
          @vRowCount              TCount,
          @vFlag                  TFlag,
          @TransferOption         TVarChar,
          @vTransferQuantity      TQuantity,
          @vFromPalletTransQty    TQuantity,
          @vFromPalletTransNumLPNs
                                  TCount,
          @vFromLPNTotalQty       TQuantity,
          @vMessage               TVarChar,
          @vAuditComment          TVarChar,
          @vActivityLogId         TRecordId,
          @xmlSuccessResult       XML,

          @xmlLPNs                TXML;

  /* Declare Temp table to insert the Pallet Details */
  declare @ttPalletLPNs Table
          (RecordId               TRecordId  identity (1,1),
           LPNId                  TRecordId,
           LPN                    TLPN,
           LPNDetailId            TRecordId,
           Status                 TStatus,
           LPNOnhandStatus        TStatus,
           LPNDetailOnhandStatus  TStatus,
           SKUId                  TRecordId,
           SKU                    TSKU,
           LocationId             TRecordId,
           OrderId                TRecordId,
           OrderDetailId          TRecordId,
           LoadId                 TLoadId,
           ShipmentId             TShipmentId,
           Quantity               TQuantity,
           UnitsPerInnerpack      TInteger,
           UoM                    TUoM,
           Ownership              TOwnership,
           Warehouse              TWarehouse)
begin
begin try
  SET NOCOUNT ON;

  /* Insert the XML result into a temp table */
  select @FromPallet      = Record.Col.value('FromPallet[1]', 'TPallet'),
         @ToPallet        = Record.Col.value('ToPallet[1]', 'TPallet'),
         @TransferOption  = Record.Col.value('Operation[1]', 'TVarChar'),
         @BusinessUnit    = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
         @UserId          = Record.Col.value('UserId[1]', 'TUserId')
  from @xmlInput.nodes('TRANSFERPALLETDETAILS/PALLETINFO') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, null,
                      null /* EntityId */, @FromPallet, 'Pallet',
                      @Value1 = @ToPallet, @Value2 = @TransferOption,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get From Pallet info */
  select @vFromPallet          = Pallet,
         @vFromPalletId        = PalletId,
         @vFromWarehouse       = Warehouse,
         @vFromPalletQty       = Quantity,
         @vFromPalletNumLPNs   = NumLPNs,
         @vFromPalletStatus    = Status,
         @vFromPalletLoadId    = LoadId,
         @vFromPalletShipToId  = ShipToId
  from Pallets
  where (Pallet       = @FromPallet) and
        (BusinessUnit = @BusinessUnit);

  /* Get To Pallet info */
  select @vToPallet          = Pallet,
         @vToPalletId        = PalletId,
         @vToWarehouse       = Warehouse,
         @vToPalletShipToId  = ShipToId,
         @vToPalletStatus    = Status,
         @vToPalletLoadId    = LoadId
  from Pallets
  where (Pallet       = @ToPallet    ) and
        (BusinessUnit = @BusinessUnit);

  /* Update the flag with the user choosen option whether to transfer partial or full pallet */
  select @vFlag = @TransferOption;

  /* Validations */
  if (@vFromPalletId is null)
    set @MessageName = 'FromPalletIsInvalid';
  else
  if (@vToPalletId is null)
    set @MessageName = 'ToPalletIsInvalid';
  else
  if (@SKU is not null) and (@vSKUId is null)
    set @MessageName = 'InvalidSKU';
  else
  if (@vFromWarehouse <> @vToWarehouse)
    set @MessageName = 'WarehouseMismatch';
  else
  /* If FromPallet ShipTo is not null and ToPallet ShipTo is not null and are not equal
     then raise error
     ex: 1. FromPalletShipToId = null, ToPalletShipToId = null - This will not trigger
             because ToPalletShipToId is null
         2. FromPalletShipToId = 1, ToPalletShipToId = null - This will not trigger because
              ToPalletShipToId is null
         3. FromPalletShipToId = 1, ToPalletShipToId = 1 - This will not trigger because
             Both the Pallet ShipTo's are equal
         4. FromPalletShipToId = '', ToPalletShipToId = 1 - This will trigger because
             FromPalletShipTo is null, but ToPalletShipTo is not null and is different, cannot
             transfer inventory to this pallet.
         5. FromPalletShipTo = 1, ToPaleltShipTo = 2 - This will trigger because both
              Pallet ShipTo's are different
     */
  if (coalesce(@vFromPalletShipToId, '') <> nullif(@vToPalletShipToId, ''))
    set @MessageName = 'PalletStoreMismatch';
  else
  /* If ToPallet is not empty and FromPallet Status and ToPallet Status are different then raise error
     ex: 1. If FromPalletStatus = 'K' (Picked, Putaway, Loaded ect), ToPalletStatus = 'E'  - This will
              not trigger as To Pallet is Empty, we can transfer to Empty Pallet
         2. If FromPalletStatus = 'K' (Picked, Putaway, Loaded ect), ToPalletStatus = 'P' (Putaway) -
              This will trigger as FromPalletStatus and ToPallet statuses are different
         3. If FromPalletStatus = 'K' (Picked, Putaway, Loaded ect), ToPalletStatus = 'K' (Picked) -
              This will not trigger as both From and To Pallet Statuses are same */
  if (@vToPalletStatus <> 'E'/* Empty */) and (@vFromPalletStatus <> @vToPalletStatus)
    set @MessageName = 'PalletStatusMismatch';
  else
  /* If the FromPalletLoadId is greater or equal to zero and ToPalletLoadId is greater than zero,
     and if the LoadId of From and To Pallets are different then raise error
     ex: 1. If FromPalletLoadId = 0, ToPalletLoadId = 0 - This will not trigger as ToPalletLoadId is
              zero and can be transfered.
         2. If FromPalletLoadId = 1, ToPalletLoadId = 0 - This will not trigger as ToPalletLoadId is zero
         3. If FromPalletLoadId = 0, ToPalletLoadId = 1 - This will trigger as ToPalletId is greater
              than zero and both are different.
         4. If FromPalletLoadId = 1, ToPalletLoadId = 1 - This will not trigger because both the Pallets
              are for same Load.
         5. If FromPalletLoadId = 1, ToPalletLoadId = 2 - This will trigger because both the Pallets are
              for different Loads.
     */
  if ((@vFromPalletLoadId >= 0) and (@vToPalletLoadId > 0)) and
     (@vFromPalletLoadId <> @vToPalletLoadId)
    set @MessageName = 'PalletLoadMismatch';

  if (@MessageName is not null)
     goto ErrorHandler;

  /* Insert the LPNs which are on the FromPallet into a temp table */
  insert into @ttPalletLPNs(LPN, LPNDetailId, SKU, Quantity, UoM)
    select Record.Col.value('LPN[1]', 'TLPN'),
           Record.Col.value('LPNDetailId[1]', 'TRecordId'),
           Record.Col.value('SKU[1]', 'TSKU'),
           Record.Col.value('Quantity[1]', 'TQuantity'),
           Record.Col.value('UoM[1]', 'TUoM')
    from @xmlInput.nodes('TRANSFERPALLETDETAILS/PALLETLPNDETAILS/LPNINFO') as Record(Col);

  /* Update the details */
  update PL
  set PL.LPNId             = LD.LPNId,
      PL.SKUId             = S.SKUId,
      PL.Status            = L.Status,
      PL.LPNOnhandStatus   = L.OnhandStatus,
      PL.LPNDetailOnhandStatus
                           = LD.OnhandStatus,
      PL.LocationId        = L.LocationId,
      PL.OrderId           = LD.OrderId,
      PL.OrderDetailId     = LD.OrderDetailId,
      PL.LoadId            = L.LoadId,
      PL.ShipmentId        = L.ShipmentId,
      PL.UnitsPerInnerpack = S.UnitsPerInnerPack,
      PL.Ownership         = L.Ownership,
      PL.Warehouse         = L.DestWarehouse
  from @ttPalletLPNs PL
    left outer join SKUs         S  on ((S.SKU          = PL.SKU   ) or
                                        (S.UPC          = PL.SKU   ))
    left outer join LPNDetails   LD on  (LD.LPNDetailId = PL.LPNDetailId) and
                                        (LD.SKUId       = S.SKUId )
    left outer join LPNs         L  on  (L.LPNId        = LD.LPNId)
  where (L.PalletId = @vFromPalletId);

  /* Get the inserted row count */
  select @vRowCount = @@rowcount;

  /* Get the total transfer quantity */
  select @vFromPalletTransQty = sum(Quantity)
  from @ttPalletLPNs
  where ((LPNId is not null) and (LPNId <> 0));

  /* Get the total transfer LPNs */
  select @vFromPalletTransNumLPNs = Count(distinct LPNId)
  from @ttPalletLPNs
  where ((LPNId is not null) and (LPNId <> 0));

  /* If user is trying to transfer the whole pallets from one Pallet to another then update the palletId
     on the source pallet LPNs */
  if (@vFromPalletTransQty = @vFromPalletQty) and (@vFromPalletTransNumLPNs = @vFromPalletNumLPNs)
    begin
      update L
      set L.PalletId = @vToPalletId,
          L.Pallet   = @vToPallet,
          L.UDF5     = @vFromPalletId
      from LPNs L
        join @ttPalletLPNs PL on (L.LPNId = PL.LPNId)
      where ((PL.LPNId is not null) and (PL.LPNId <> 0));

      goto UpdateCounts;
    end

  /* Loop through each record and transfer the details */
  while (@vRowCount > 0)
    begin
      /* Get the first row */
      select top 1 @vRecordId             = RecordId,
                   @vFromLPNId            = LPNId,
                   @vFromLPNDetailId      = LPNDetailId,
                   @vFromLPNSKUId         = SKUId,
                   @vFromLPNSKU           = SKU,
                   @vFromLPNStatus        = Status,
                   @vFromLPNOnhandStatus  = LPNOnhandStatus,
                   @vFromLPNDetailOnhandStatus
                                          = LPNDetailOnhandStatus,
                   @vFromLocationId       = LocationId,
                   @vFromLPNOwnership     = Ownership,
                   @vFromLPNOrderId       = OrderId,
                   @vFromLPNOrderDetailId = OrderDetailId,
                   @vFromLPNLoadId        = LoadId,
                   @vFromLPNShipmentId    = ShipmentId,
                   @vFromLPNQuantity      = Quantity,
                   @vUnitsPerInnerpack    = UnitsPerInnerpack,
                   @vUoM                  = UoM
      from @ttPalletLPNs
      order by RecordId;

      /* Get the LPN which has the same SKU on the ToPallet */
      select @vToLPN         = LPN,
             @vToLPNId       = LPNId,
             @vToLPNDetailId = LPNDetailId
      from vwLPNDetails
      where (PalletId = @vToPalletId) and
            (coalesce(OrderId, 0)       = coalesce(@vFromLPNOrderId, OrderId, 0)) and
            (coalesce(OrderDetailId, 0) = coalesce(@vFromLPNOrderDetailId, OrderDetailId, 0)) and
            (coalesce(LoadId, 0)        = coalesce(@vFromLPNLoadId, LoadId, 0)) and
            (coalesce(ShipmentId, 0)    = coalesce(@vFromLPNShipmentId, ShipmentId, 0)) and
            (SKUId    = @vFromLPNSKUId);

      /* Get the from LPN total qty */
      select @vFromLPNTotalQty = sum(Quantity)
      from LPNDetails
      where (LPNId = @vFromLPNId);

      /* If the Unit of Measure is Case packs then get the actual units from the sannced cases */
      if (@vUoM = 'CP'/* Case Pack */)
        select @vTransferQuantity = case when @vFlag = 'F' /* Full Transfer */ then @vFromLPNQuantity
                                         when @vFlag = 'P' /* Partial Transfer */ then (@vFromLPNQuantity * @vUnitsPerInnerpack)
                                    end;
      else
        select @vTransferQuantity = case when @vFlag = 'F' /* Full Transfer */ then @vFromLPNQuantity
                                         when @vFlag = 'P' /* Partial Transfer */ then @vFromLPNQuantity
                                    end;

      /* If there is no LPN with the same SKU on the ToPallet, then create a
         new LPN and then transfer the units into it */
      if (coalesce(@vToLPN, '') = '')
        begin
          exec @ReturnCode = pr_LPNs_Generate 'C',             /* Carton */
                                              1,               /* NumLPNsToCreate */
                                              null,            /* LPNFormat     */
                                              @vFromWarehouse, /* Warehouse */
                                              @BusinessUnit,   /* TBusinessUnit, */
                                              @UserId,         /* TUserId, */
                                              @vToLPNId     output,
                                              @vToLPN       output;

          /* Add LPN to the SKU */
          if (@vToLPNId is not null)
            begin
              exec @ReturnCode = pr_LPNs_AddSKU @vToLPNId,
                                                @vToLPN,
                                                null, /* SKUId */
                                                @vFromLPNSKU,
                                                @InnerPacks,
                                                @vTransferQuantity,
                                                @ReasonCode,
                                                '', /* InventoryClass1 */
                                                '', /* InventoryClass2 */
                                                '', /* InventoryClass3 */
                                                @BusinessUnit,
                                                @UserId;

              /* Get the recently created LPNDetailId */
              select @vToLPNDetailId = LPNDetailId
              from LPNDetails
              where (LPNId = @vToLPNId);
            end
        end
      else
      if (@vToLPN is not null)
        begin
          /* Increment To LPN */
          exec @ReturnCode = pr_LPNs_AdjustQty @vToLPNId,
                                               @vToLPNDetailId output,
                                               @vFromLPNSKUId,
                                               @vFromLPNSKU,
                                               @InnerPacks,
                                               @vTransferQuantity,
                                               '+', /* '=' - Exact Qty, '+' - Add Qty, '-' - Subtract Qty */
                                               'N' /* ExportOption = No */,
                                               @ReasonCode,
                                               null, /* Reference */
                                               @BusinessUnit,
                                               @UserId;
        end

      /* Decrement from LPN */
      exec @ReturnCode = pr_LPNs_AdjustQty @vFromLPNId,
                                           @vFromLPNDetailId output,
                                           @vFromLPNSKUId,
                                           @vFromLPNSKU,
                                           @InnerPacks,
                                           @vTransferQuantity,
                                           '-', /* '=' - Exact Qty, '+' - Add Qty, '-' - Subtract Qty */
                                           'N' /* ExportOption = No */,
                                           @ReasonCode,
                                           null, /* Reference */
                                           @BusinessUnit,
                                           @UserId;

      /* Update the ToLPN with the ToPallet Info */
      update LPNs
      set PalletId     = @vToPalletId,
          Pallet       = @vToPallet,
          LocationId   = @vFromLocationId,
          OrderId      = @vFromLPNOrderId,
          LoadId       = @vFromLPNLoadId,
          ShipmentId   = @vFromLPNShipmentId,
          Status       = @vFromLPNStatus,
          OnhandStatus = @vFromLPNOnhandStatus,
          Ownership    = @vFromLPNOwnership
      where (LPNId = @vToLPNId);

      /* Update LPNDetails with the Order info */
      update LPNDetails
      set OnhandStatus  = @vFromLPNDetailOnhandStatus,
          OrderId       = @vFromLPNOrderId,
          OrderDetailId = @vFromLPNOrderDetailId
      where (LPNDetailId = @vToLPNDetailId);

      /* While transferring pallets paritally i,e. LPNs, system would generate
         new LPN, adds SKU & inventory and then decrements the inventory in From LPN
         Recount order in this scenario to update LPN counts */
      exec pr_OrderHeaders_Recount @vFromLPNOrderId

      /* Build Audit Trail Comment */
      if ((@TransferOption = 'P' /* Partial Pallet */) and
          (@vFromLPNTotalQty = @vTransferQuantity))
        select @vAuditComment = 'PalletTransferLPN';
      else
      if ((@TransferOption = 'P' /* Partial Pallet */) and
          (@vTransferQuantity < @vFromLPNTotalQty))
        select @vAuditComment = 'PalletTransferUnits';

      if (@vAuditComment is not null)
        exec pr_AuditTrail_Insert @vAuditComment, @UserId, null /* ActivityTimestamp */,
                                  @PalletId      = @vFromPalletId,
                                  @ToPalletId    = @vToPalletId,
                                  @LPNId         = @vFromLPNId,
                                  @ToLPNId       = @vToLPNId,
                                  @SKUId         = @vFromLPNSKUId,
                                  @Quantity      = @vTransferQuantity;

      /* Added Audit Trail on Each LPN while Transfer Full Pallet
         Note: Included Note1 and Note2 Instead of passing PalletId, so that to display Audit message
               only on LPN since we are already displaying the Audit trail for Full Pallet below */
      if (@TransferOption = 'F' /* Full Pallet */)
        exec pr_AuditTrail_Insert 'FullPalletTransferEachLPN', @UserId, null /* ActivityTimestamp */,
                                  @LPNId         = @vFromLPNId,
                                  @ToLPNId       = @vToLPNId,
                                  @Note1         = @FromPallet,
                                  @Note2         = @ToPallet,
                                  @SKUId         = @vFromLPNSKUId,
                                  @Quantity      = @vTransferQuantity;

      /* Delete the processed records from the temp table */
      delete from @ttPalletLPNs where (RecordId = @vRecordId);

      /* Unassign the variables */
      select @vRecordId = null, @vFromLPNId = null, @vFromLPNDetailId = null, @vFromLocationId = null,
             @vFromLPNOrderId = null, @vFromLPNOrderDetailId = null, @vFromLPNLoadId = null,
             @vFromLPNShipmentId = null, @vFromLPNOnhandStatus = null,@vFromLPNDetailOnhandStatus = null,
             @vFromLPNSKUId = null, @vFromLPNSKU = null, @vFromLPNQuantity = null, @vUoM = null,
             @vUnitsPerInnerpack = null, @vToLPN = null, @vTransferQuantity = null, @vToLPNId = null, @vToLPNDetailId = null;

      /* Update the RowCount after each record is processed */
      select @vRowCount = @vRowCount - 1;
    end

UpdateCounts:

  /* Update the Counts on From Pallet */
  exec pr_Pallets_UpdateCount @vFromPalletId, @vFromPallet, '*' /* @UpdateOption */;

  /* Update the Counts on To Pallet */
  exec pr_Pallets_UpdateCount @vToPalletId, @vToPallet, '*' /* @UpdateOption */;

  /* Audit Trail on Pallet while Transfer Full Pallet */
  /* Build Message */
  if (@TransferOption = 'F' /* Full Pallet */)
    begin
      select @vMessage = 'SuccessfullyTransferredPallet';

      exec pr_AuditTrail_Insert 'PalletTransferFull', @UserId, null /* ActivityTimestamp */,
                                @PalletId      = @vFromPalletId,
                                @ToPalletId    = @vToPalletId,
                                @Quantity      = @vFromPalletQty,
                                @NumLPNs       = @vFromPalletNumLPNs;
    end
  else
    select @vMessage = 'SuccessfullyTransferredPartialPallet';

  /* XmlMessage to RF, after Pallet is Moved to a Location */
  exec pr_BuildRFSuccessXML @vMessage, @xmlSuccessResult output, @vFromPallet, @vToPallet;

  /* Build xml of LPNs on the Pallet */
  set @xmlLPNs = (select LPNId, LPN, LPNDetailId,
                         SKU, SKU1, SKU2, SKU3, UPC as SKU4, SKU5,
                         SKUDescription, InnerPacks, Quantity
                  from vwLPNDetails
                  where (PalletId = @vFromPalletId)
                  for xml raw('LPNS'), elements xsinil);

  set @xmlResult = '<PALLETDETAILS>' +
                    coalesce(@xmlLPNs,   '') +
                    coalesce(convert(varchar(max), @xmlSuccessResult), '') +
                   '</PALLETDETAILS>';

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vFromPalletId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vFromPalletId, @ActivityLogId = @vActivityLogId output;

end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_TransferPallet */

Go
