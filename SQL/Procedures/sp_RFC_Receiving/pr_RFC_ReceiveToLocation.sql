/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/04  VS      pr_RFC_ReceiveToLocation: Find the existing logical LPN if Lot is null on Logical LPN and ReceiptDetails (HA-2864)
  2021/05/06  VS/PK   pr_RFC_ReceiveToLPN, pr_RFC_ReceiveToLocation: Receive the inventory to the different LabelCodes for same SKU (HA-2727)
  2020/04/29  MS      pr_RFC_ReceiveToLPN, pr_RFC_ReceiveToLocation: Changes to get ReceiverNumber (HA-228)
  2020/04/20  RIA     pr_RFC_ReceiveToLPN, pr_RFC_ReceiveToLocation: Changes to get the DeviceId (HA-191)
  2020/04/18  TK      pr_RFC_ReceiveToLocation: We don't need to find the Logical LPN that is matching inventory class but
                        that will be validated further in ReceiveToLPN proc
                      pr_RFC_ReceiveToLPN: Corrected validations (HA-222)
  2020/04/16  MS      pr_RFC_ReceiveToLocation,pr_RFC_ReceiveToLPN; Changes to send WH (HA-187)
  2020/04/01  TK      pr_RFC_ReceiveToLocation & pr_RFC_ReceiveToLPN:
                        Changes to populate InventoryClass from receipt detail to LPN and validation
                        to restrict user receiving to an LPN with InventoryClass mismatch (HA-84)
  2018/05/08  OK      pr_RFC_ReceiveToLocation, pr_RFC_ReceiveToLPN: moved the over receiving related changes to function (S2G-811)
  2018/04/11  YJ      pr_RFC_ReceiveToLocation, pr_RFC_ValidateReceipt: Added RF Log (S2G-514)
  2015/05/05  OK      pr_RFC_ReceiveToLocation, pr_RFC_ReceiveToLPN: Made system compatable to accept either Location or Barcode.
  2014/02/17  PKS     pr_RFC_ReceiveToLPN, pr_RFC_ReceiveToLocation: ReceiptId variable name corrected while calling AT procedure.
  2014/01/29  VM      pr_RFC_ReceiveToLocation, pr_RFC_ReceiveToLPN: Made fixes to receive to picklane location directly
  2013/06/18  YA      pr_RFC_ReceiveToLocation: Included code to add an LPN if LPN is not found.
  2013/04/16  TD      pr_RFC_ReceiveToLPN, pr_RFC_ValidateReceipt, pr_RFC_ReceiveToLocation : Added
                          CustPO as inputparam and made custpo as controloption based.
  2012/05/28  YA      Implemented Auditing on 'pr_RFC_ReceiveToLocation' and 'pr_RFC_ReceiveToLPN'.
  2010/12/03  VM      pr_RFC_ReceiveToLPN,pr_RFC_ReceiveToLocation:
                        Funtionality implemented.
  2010/11/23  VM      Corrected signatures for pr_RFC_ReceiveToLocation, pr_RFC_ReceiveToLPN
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ReceiveToLocation') is not null
  drop Procedure pr_RFC_ReceiveToLocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ReceiveToLocation:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ReceiveToLocation
  (@ReceiptId          TRecordId,
   @ReceiptNumber      TReceiptNumber,
   @ReceiptDetailId    TRecordId,
   @ReceiptLine        TReceiptLine,
   @SKUId              TRecordId,
   @SKU                TSKU,
   @InnerPacks         TInnerPacks,  /* Future use */
   @Quantity           TQuantity,
   @CustPO             TCustPO,
   @PackingSlip        TPackingSlip output,
   @LocationId         TRecordId,
   @Warehouse          TWarehouse,
   @Location           TLocation,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @DeviceId           TDeviceId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TDescription,
          @vActivityLogId    TRecordId,
          /* Location */
          @vLocationId       TRecordId,
          @vLocation         TLocation,
          @vLocationType     TLocationType,
          @vLocWarehouse     TWarehouse,
          @vLocOwnership     TOwnership,
          /* Receipt Hdr */
          @vReceiptId        TRecordId,
          @vRHOwnership      TOwnership,
          /* LPN */
          @vLPNId            TRecordId,
          @vReceiverNumber   TReceiverNumber,
          @vSKUId            TRecordId,
          @vSKU              TSKU,
          @vLot              TLot,
          @vInventoryClass1  TInventoryClass,
          @vInventoryClass2  TInventoryClass,
          @vInventoryClass3  TInventoryClass,
          /* Other */
          @xmlResultvar      varchar(max),
          @xmlInput          xml,
          @xmlResult         xml;

begin
begin try
  SET NOCOUNT ON;

  select @ReceiptDetailId = nullif(@ReceiptDetailId, 0),
         @CustPO          = nullif(@CustPO , ''),
         @vReceiverNumber = nullif(@PackingSlip, '');

  set @xmlInput = (select @ReceiptId       as ReceiptId,
                          @ReceiptNumber   as ReceiptNumber,
                          @ReceiptLine     as ReceiptLine,
                          @CustPO          as CustPO,
                          @Warehouse       as Warehouse,
                          @Location        as ReceiveToLocation,
                          @BusinessUnit    as BusinessUnit,
                          @DeviceId        as DeviceId,
                          @UserId          as UserId
                   for XML raw('ValidateReceiptInput'), type, elements);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @ReceiptId, @ReceiptNumber, 'Location', @Value1 = @Location,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get Location Info */
  select @vLocationId   = LocationId,
         @vLocation     = Location,
         @vLocationType = LocationType,
         @vLocWarehouse = Warehouse,
         @vLocOwnership = Ownership
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (@LocationId, @Location, null /* DeviceId */, @UserId, @BusinessUnit));

  /* Identify Receipt Id if not given */
  if (@ReceiptId is null)
    select @ReceiptId = ReceiptId from ReceiptHeaders where (ReceiptNumber = @ReceiptNumber) and (BusinessUnit = @BusinessUnit);

  select @vReceiptId   = ReceiptId,
         @vRHOwnership = Ownership
  from ReceiptHeaders
  where (ReceiptId = @ReceiptId);

  /* Note: Validate Receipt is done in pr_RFC_ReceiveToLPN call below */

  /* Get SKU Details, and ReceiptDetailId if one is not passed in */
  select top 1 @vSKUId          = SS.SKUId,
               @vSKU            = SS.SKU,
               @ReceiptDetailId = coalesce(nullif(@ReceiptDetailId, 0), RD.ReceiptDetailId)
  from dbo.fn_SKUs_GetScannedSKUs (@SKU, @BusinessUnit) SS
    join ReceiptDetails RD on (SS.SKUId = RD.SKUId) and (RD.ReceiptId = @vReceiptId)
  where (SS.Status = 'A' /* Active */);

  /* Validate Location exists and should be a Picklane */
  if (@vLocationId is null)
     set @vMessageName = 'LocationDoesNotExist';
  else
  if (@vLocationType <> 'K' /* PickLane */)
    set @vMessageName = 'RecvOnlyToPicklaneLoc';
  else
  if (@vReceiptId is null)
    set @vMessageName = 'ReceiptDoesNotExist';
  else
  if (@vLocOwnership <> @vRHOwnership)
    set @vMessageName = 'ReceiveToLoc_OwnershipMismatch'
  else
    set @vMessageName = dbo.fn_Receipts_ValidateOverReceiving(@ReceiptDetailId, @Quantity, @UserId);

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Get Receipt Details info */
  select @vLot             = Lot,
         @vInventoryClass1 = coalesce(InventoryClass1, ''),
         @vInventoryClass2 = coalesce(InventoryClass2, ''),
         @vInventoryClass3 = coalesce(InventoryClass3, '')
  from ReceiptDetails
  where (ReceiptDetailId = @ReceiptDetailId);

  /* Identify the Logical LPN to receive into */
  select @vLPNId = LPNId
  from LPNs
  where (LocationId        = @vLocationId) and
        (SKUId             = @vSKUId) and
        (Ownership         = @vRHOwnership) and
        (coalesce(Lot, '') = coalesce(@vLot, Lot, '')) and
        (InventoryClass1   = @vInventoryClass1) and
        (InventoryClass2   = @vInventoryClass2) and
        (InventoryClass3   = @vInventoryClass3);

  if (@vLPNId is null)
    begin
      /* Create Logical LPN as same as Location */
      exec @vReturnCode = pr_LPNs_Generate 'L'            /* Logical Carton */,
                                           1              /* NumberOfLPNs */,
                                           @vLocation     /* LPNFormat - same as Location */,
                                           @vLocWarehouse,
                                           @BusinessUnit,
                                           @UserId,
                                           @vLPNId output;

      /* Update Location info on the LPN */
      update LPNs
      set UniqueId        = concat_ws('-', @vLocation, @vSKU, @vInventoryClass1, @vInventoryClass2, @vInventoryClass3, @vLot),
          LocationId      = @vLocationId,
          Location        = @vLocation,
          Lot             = @vLot,
          InventoryClass1 = @vInventoryClass1,
          InventoryClass2 = @vInventoryClass2,
          InventoryClass3 = @vInventoryClass3,
          SKUId           = @vSKUId,
          SKU             = @vSKU
      where (LPNId = @vLPNId);
    end

  exec @vReturnCode = pr_RFC_ReceiveToLPN @vReceiptId,
                                          @ReceiptNumber,
                                          @ReceiptDetailId,
                                          @ReceiptLine,
                                          @vSKUId,
                                          @vSKU,
                                          @InnerPacks,
                                          @Quantity,
                                          null /* UOM */,
                                          @vLPNId,
                                          null /* @LPN */,
                                          @CustPO,
                                          @vReceiverNumber output,
                                          @Warehouse,
                                          @vLocation,
                                          null, /* Pallet */
                                          @BusinessUnit,
                                          @UserId,
                                          @DeviceId;

  if (@vReturnCode = 0)
    begin
      /* Audit Trail */
      exec pr_AuditTrail_Insert 'ReceiveToLocation', @UserId, null /* ActivityTimestamp */,
                                @LPNId          = @vLPNId,
                                @SKUId          = @vSKUId,
                                @Quantity       = @Quantity,
                                @LocationId     = @vLocationId,
                                @ReceiptId      = @vReceiptId,
                                @ReceiverNumber = @vReceiverNumber;
    end

  /* Pass ReceiverNumber to Param to use in caller */
  select @PackingSlip = @vReceiverNumber;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Mark the end of the transaction */
  exec pr_RFLog_End @xmlResultvar /* xmlResult */, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Mark the end of the transaction */
  exec pr_RFLog_End @xmlResult /* xmlResult */, @@ProcId, @ActivityLogId = @vActivityLogId output;

  exec @vReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_ReceiveToLocation */

Go
