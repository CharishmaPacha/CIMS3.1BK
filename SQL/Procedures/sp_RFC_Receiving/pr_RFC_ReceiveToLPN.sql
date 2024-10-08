/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/30  SK      pr_RFC_ReceiveToLPN: Missing evaluation added to the result after validation (HA-2943)
  2021/05/06  VS/PK   pr_RFC_ReceiveToLPN, pr_RFC_ReceiveToLocation: Receive the inventory to the different LabelCodes for same SKU (HA-2727)
  2020/12/02  AY      pr_RFC_ReceiveToLPN: Changed to not update Locations of all LPNs on Pallet when only one is received (HA-1750)
  2020/06/19  RT      pr_RFC_ReceiveToLPN: Included ToLocationId to send Exports (HA-111)
  2020/05/07  MS      pr_RFC_ReceiveToLPN: Changes to get Receipt from LPN (HA-286)
  2020/04/30  MS      pr_RFC_ReceiveToLPN: Corrections to Validate LPNReceipt to given Receipt (HA-335)
  2020/04/29  MS      pr_RFC_ReceiveToLPN, pr_RFC_ReceiveToLocation: Changes to get ReceiverNumber (HA-228)
  2020/04/29  RT      pr_RFC_ReceiveToLPN: Calling pr_Exports_LPNReceiptConfirmation in place of pr_Exports_LPNData (HA-111)
  2020/04/20  RIA     pr_RFC_ReceiveToLPN, pr_RFC_ReceiveToLocation: Changes to get the DeviceId (HA-191)
  2020/04/18  TK      pr_RFC_ReceiveToLocation: We don't need to find the Logical LPN that is matching inventory class but
                        that will be validated further in ReceiveToLPN proc
                      pr_RFC_ReceiveToLPN: Corrected validations (HA-222)
  2020/04/17  AY      pr_RFC_ReceiveToLPN: Do not lot AT twice for Receive To LPN (CIMSV3-803)
  2020/04/16  MS      pr_RFC_ReceiveToLocation,pr_RFC_ReceiveToLPN; Changes to send WH (HA-187)
  2020/04/01  TK      pr_RFC_ReceiveToLocation & pr_RFC_ReceiveToLPN:
                        Changes to populate InventoryClass from receipt detail to LPN and validation
                        to restrict user receiving to an LPN with InventoryClass mismatch (HA-84)
  2020/03/19  TK      pr_RFC_ReceiveToLPN: Changes to update ReceiverId on LPNs (S2GMI-140)
  2019/02/08  RIA     pr_RFC_ReceiveToLPN: Added logging (CID-76)
  2018/06/05  YJ      pr_RFC_ReceiveToLPN: fn_SKUs_GetScannedSKUs commented where condition to get all the SKU statuses (S2G-727)
  2018/06/01  TK      pr_RFC_ReceiveToLPN: Bug fix to compute innerpacks value while receving in cases (S2G-896)
  2018/05/22  TK      pr_RFC_ReceiveToLPN: Changes to validate SKU Attributes (S2GCAN-26)
  2018/05/08  OK      pr_RFC_ReceiveToLocation, pr_RFC_ReceiveToLPN: moved the over receiving related changes to function (S2G-811)
  2018/03/20  SV      pr_RFC_ReceiveToLPN: Changed the default value if at all no control is defined (S2G-452)
  2018/02/23  SV      pr_RFC_ValidateReceipt: Added validation for Receiver# if at all provided from RF (S2G-225)
                      pr_RFC_ReceiveToLPN: Updated the Receiver# over the received LPN/Location (S2G-225)
  2018/02/14  CK      pr_RFC_ReceiveToLPN: Corrected the node name (S2G-155)
  2018/01/18  OK      pr_RFC_ReceiveToLPN: Considered both LPNId and LPN i/p params to identify the scanned LPN (S2G-121)
  2018/01/17  TK      pr_RFC_ReceiveToLPN: Changes to receive an external LPN (S2G-20)
  2015/12/07  AY      pr_RFC_ReceiveToLPN/Location: Handle duplicate UPCs i.e. diff SKUs having same UPC (SRI-422)
  2015/06/30  DK      pr_RFC_ReceiveToLPN: Bug fix to not consider Reserved, Directed, ReservedDirected Lines.
  2015/05/05  OK      pr_RFC_ReceiveToLocation, pr_RFC_ReceiveToLPN: Made system compatable to accept either Location or Barcode.
  2014/04/03  NY      pr_RFC_ReceiveToLPN: Passing Warehouse of PO to show in AT.
  2014/03/18  PKS     pr_RFC_ValidateReceipt: PackingSlip changed to ReceiverNumber, return XML was modified,
                      All receiptDetails records comes in detail XML.And added Qty and LPN related new fields in output XML for future use.
                      pr_RFC_ReceiveToLPN: parameters of pr_RFC_ValidateReceipt converted into XML.
  2014/03/13  NY      pr_RFC_ReceiveToLPN : Log RF Transactions while receiving to LPN.(XSC-514)
  2014/02/17  PKS     pr_RFC_ReceiveToLPN, pr_RFC_ReceiveToLocation: ReceiptId variable name corrected while calling AT procedure.
  2014/01/29  VM      pr_RFC_ReceiveToLocation, pr_RFC_ReceiveToLPN: Made fixes to receive to picklane location directly
  2013/09/06  PK      pr_RFC_ReceiveToLPN: Added new param UoM, and computing the received qty based on UoM.
  2013/08/14  TD      pr_RFC_ReceiveToLPN:Validate whether SKU is valid to receive or not.
  2013/07/15  TD      pr_RFC_ReceiveToLPN: Bug fix, filtering data with CustPO.
  2013/04/16  TD      pr_RFC_ReceiveToLPN, pr_RFC_ValidateReceipt, pr_RFC_ReceiveToLocation : Added
                          CustPO as inputparam and made custpo as controloption based.
  2013/04/11  AY      pr_RFC_ReceiveToLPN: Changed to make CustPO required
  2013/04/10  VM      pr_RFC_ReceiveToLPN: cast PackingSlip to varchar as CustPO is of varchar - might be temporary
  2013/03/25  VM      pr_RFC_ReceiveToLPN: Allow to scan SKU/Barcode/UPC
  2013/04/11  YA/PK   pr_RFC_ReceiveToLPN: Allow multiple SKUs into an LPN.
  2013/03/05  YA/PK   pr_RFC_ValidateReceipt, pr_RFC_ReceiveToLPN: Modified to receive inventory
                        in to a dock location.
  2012/07/20  YA      pr_RFC_ReceiveToLPN: Handling nested transactions
  2012/05/28  YA      Implemented Auditing on 'pr_RFC_ReceiveToLocation' and 'pr_RFC_ReceiveToLPN'.
  2011/03/05  VM      pr_RFC_ReceiveToLPN: Added validation to not to receive different SKU or
                        different Receipt into same LPN.
  2011/01/21  VM      pr_RFC_ReceiveToLPN: Return Receipt details dataset to use in RF to show updated.
                      pr_RFC_ValidateReceipt: Corrected a validation and added required where condition
                        in return query.
  2010/12/03  VM      pr_RFC_ReceiveToLPN,pr_RFC_ReceiveToLocation:
                        Funtionality implemented.
  2010/11/23  VM      Corrected signatures for pr_RFC_ReceiveToLocation, pr_RFC_ReceiveToLPN
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ReceiveToLPN') is not null
  drop Procedure pr_RFC_ReceiveToLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ReceiveToLPN:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ReceiveToLPN
  (@ReceiptId          TRecordId,
   @ReceiptNumber      TReceiptNumber,
   @ReceiptDetailId    TRecordId,
   @ReceiptLine        TReceiptLine,
   @SKUId              TRecordId,
   @SKU                TSKU,
   @InnerPacks         TInnerPacks,
   @Quantity           TQuantity,
   @UoM                TUoM,
   @LPNId              TRecordId,
   @LPN                TLPN,
   @CustPO             TCustPO,
   @PackingSlip        TPackingSlip output, /* Future use */
   @Warehouse          TWarehouse,
   @Location           TLocation,
   @Pallet             TPallet,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @DeviceId           TDeviceId)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessage,

          @vSKUId                  TRecordId,
          @vSKU                    TSKU,

          @vLPNId                  TRecordId,
          @vLPN                    TLPN,
          @vLPNType                TTypeCode,
          @vLPNLot                 TLot,
          @vLPNInventoryClass1     TInventoryClass,
          @vLPNInventoryClass2     TInventoryClass,
          @vLPNInventoryClass3     TInventoryClass,
          @vExternalLPNId          TRecordId,

          @vPalletId               TRecordId,
          @vLocationId             TRecordId,
          @vLocation               TLocation,
          @vLPNLineCount           TCount,
          @vLPNDetailId            TRecordId,
          @vLPNStatus              TStatus,
          @vOnHandStatus           TStatus,
          @vLPNReceiptId           TRecordId,
          @vReceiptId              TRecordId,
          @vReceiptType            TReceiptType,
          @vAllowMultiSKULPN       TFlag,

          @ReceiveToLocation       TLocation,
          @vLocationSubType        TTypeCode,
          @vControlCategory        TCategory,
          @ReceiveToPallet         TPallet,

          @vWarehouse              TWarehouse,
          @vReceiverId             TRecordId,
          @vReceiverNumber         TReceiverNumber,
          @vRDLot                  TLot,
          @vRDInventoryClass1      TInventoryClass,
          @vRDInventoryClass2      TInventoryClass,
          @vRDInventoryClass3      TInventoryClass,

          @vDeviceId               TDeviceId,
          @xmlResultvar            varchar(max),
          @xmlResult               xml,
          @xmlInput                xml,
          @vxmlResult              xml,
          @vActivityLogId          TRecordId,

          @vAcceptExternalLPN      TControlValue,
          @vIsReceiverRequired     TControlValue;
begin
begin try
  SET NOCOUNT ON;

  select @ReceiptDetailId = nullif(@ReceiptDetailId, 0),
         @Pallet          = nullif(@Pallet, ''),
         @CustPO          = nullif(@CustPO, ''),
         @vReceiverNumber = nullif(@PackingSlip, ''),
         @vLPNLineCount   = 0;

  set @xmlInput = (select @vReceiverNumber as ReceiverNumber,
                          @ReceiptId       as ReceiptId,
                          @ReceiptNumber   as ReceiptNumber,
                          @CustPO          as CustPO,
                          @Warehouse       as Warehouse,
                          @Location        as ReceiveToLocation,
                          @Pallet          as ReceiveToPallet,
                          @LPNId           as LPNId,
                          @LPN             as LPN,
                          'V'              as ValidateOption /* Validate Only */,
                          @BusinessUnit    as BusinessUnit,
                          @DeviceId        as DeviceId,
                          @UserId          as UserId
                   for XML raw('ValidateReceiptInput'), type, elements);

  /* Get Device Details */
  select @vDeviceId = @DeviceId + '@' + @UserId;

  -- This was done earlier because we did not get DeviceId as input
  -- select top 1 @vDeviceId = DeviceName
  -- from Devices
  -- where CurrentUserId = @UserId
  -- order by LastLogindatetime desc;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @LPNId, @LPN, 'LPN', @Value1 = @ReceiptNumber,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  exec @vReturnCode = pr_RFC_ValidateReceipt @xmlInput, @vxmlResult output;

  /* Above procedure does not raise an exception, so check if there is an error and exit if so */
  select @vMessageName = Record.Col.value('ErrorMessage[1]', 'TMessage')
  from @vxmlResult.nodes('/ERRORDETAILS/ERRORINFO') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlResult = null));

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Get LPN Details */
  select @vLPNId              = LPNId,
         @vLPN                = LPN,
         @vLPNStatus          = Status,
         @vLPNType            = LPNType,
         @vLPNReceiptId       = ReceiptId,
         @vLPNInventoryClass1 = InventoryClass1,
         @vLPNInventoryClass2 = InventoryClass2,
         @vLPNInventoryClass3 = InventoryClass3
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(coalesce(@LPN, cast(@LPNId as varchar)), @BusinessUnit, 'ILTU' /* Options */));

  /* Identify Receipt Id if not given */
  if (@ReceiptId is null)
    select @ReceiptId = ReceiptId from ReceiptHeaders where (ReceiptNumber = @ReceiptNumber) and (BusinessUnit  = @BusinessUnit);

  /* Get the ReceiptId to get ReceiptDetailId */
  select @vReceiptId   = ReceiptId,
         @vReceiptType = ReceiptType,
         @vWarehouse   = Warehouse
  from ReceiptHeaders
  where (ReceiptId = @ReceiptId);

  /* This below lines are moved here as we need to get @vLocationId which needs to be sent to
       pr_Receipts_ReceiveExternalLPN as a parameter */
  if (@Location is not null)
    select @vLocationId      = LocationId,
           @vLocation        = Location,
           @vLocationSubType = LocationSubType
    from Locations
    where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @Location, null /* DeviceId */, @UserId, @BusinessUnit));

  /* Get controls */
  select @vControlCategory = 'Receiving_' + @vReceiptType;

  select @vAcceptExternalLPN  = dbo.fn_Controls_GetAsBoolean(@vControlCategory, 'AcceptExternalLPN', 'N' /* No */,  @BusinessUnit, @UserId),
         @vAllowMultiSKULPN   = dbo.fn_Controls_GetAsBoolean(@vControlCategory, 'AllowMultiSKULPN',  'Y' /* Yes */, @BusinessUnit, @UserId),
         @vIsReceiverRequired = dbo.fn_Controls_GetAsString(@vControlCategory, 'IsReceiverRequired', 'AUTO' /* Auto Create */, @BusinessUnit, @UserId);

  /* Get the ReceiverId value to log the Receiver# over AT */
  if (@vReceiverNumber is not null)
    select @vReceiverId = ReceiverId
    from Receivers
    where (ReceiverNumber = @vReceiverNumber) and
          (BusinessUnit   = @BusinessUnit);
  else
  if (@vIsReceiverRequired = 'AUTO' /* Auto Create */)
    exec pr_Receivers_AutoCreateReceiver @vReceiptId, @CustPO, @vLocationId, @BusinessUnit, @UserId,
                                         @vReceiverId output, @vReceiverNumber output;

  if (@vLPNId is null) and (@vAcceptExternalLPN  = 'Y'/* Yes */)
    begin
      /* Check if user scanned a valid external LPN
         Need to sent the @vLocationId, as to get the WH and update over the LPN.
         If at all user scans or didn't scan an external LPN, then @vLPNId will be null and @LPN will be holding
           value(scanned external LPN or null) which will validated(with Prefix control) at pr_Receipts_ValidateExternalLPN.
           So there won't be any issue if user didn't scan an external and @vAcceptExternalLPN is having value as 'Y' */
      exec pr_Receipts_ReceiveExternalLPN @vReceiptId, @vLocationId, @LPN, @BusinessUnit, @UserId, @vExternalLPNId output;

      /* Get LPN Details */
      if (@vExternalLPNId is not null)
        select @vLPNId        = LPNId,
               @vLPN          = LPN,
               @vLPNStatus    = Status,
               @vLPNType      = LPNType,
               @vLPNReceiptId = ReceiptId
        from LPNs
        where (LPNId = @vExternalLPNId);
    end

  /* Get SKU Details - if user gave UPC there could be multiple SKUs that match UPC
     so join with ReceiptDetails to narrow down to the SKUs on the RO */
  select top 1 @vSKUId = SS.SKUId,
               @vSKU   = SS.SKU
  from dbo.fn_SKUs_GetScannedSKUs (@SKU, @BusinessUnit) SS
    join ReceiptDetails RD on (SS.SKUId = RD.SKUId) and RD.ReceiptId = @vReceiptId;
  --where (SS.Status = 'A' /* Active */);

  /* While receiving inventory in cases, we are passing innerpack value to quantity and we
     are computing quantity, we need to treat Quantity as Innerpacks */
  if (@UoM = 'CS'/* Cases */)
    select @InnerPacks = @Quantity,
           @Quantity   = (@Quantity * coalesce(nullif(UnitsPerInnerPack, 0), 1) ) /* Assumption - If UnitsPerInnerPack is null we consider it is 1 */
    from SKUs
    where (SKUId = @vSKUId);

  /* Get Receipt Line based on SKU, if ReceiptDetailId is null/0 passed */
  if (@ReceiptDetailId is null) or (@CustPO is not null)
    begin
      /* If receiving against a CustPO, then ignore the line that is given and find
         the appropriate line */
      select @ReceiptDetailId = null;

      select @ReceiptDetailId = ReceiptDetailId
      from ReceiptDetails
      where ((ReceiptId            = @vReceiptId) and
             (SKUId                = @vSKUId)     and
             (coalesce(CustPO, '') = coalesce(@CustPO, CustPO, '')));
    end;

  /* Get Receipt Details info */
  select @vRDLot             = Lot,
         @vRDInventoryClass1 = coalesce(InventoryClass1, ''),
         @vRDInventoryClass2 = coalesce(InventoryClass2, ''),
         @vRDInventoryClass3 = coalesce(InventoryClass3, '')
  from ReceiptDetails
  where (ReceiptDetailId = @ReceiptDetailId);

  /* Get LPN Line Count */
  select @vLPNLineCount = count(*)
  from LPNDetails
  where (LPNId = @vLPNId);

  /* Get LPNDetailId */
  select @vLPNDetailId  = LPNDetailId
  from LPNDetails LD
    join LPNs L on L.LPNId = LD.LPNId
  where (LD.LPNId     = @vLPNId) and
        (LD.SKUId     = @vSKUId) and
        (LD.OnhandStatus not in ('R'/* Reserved */, 'D'/* Directed */, 'DR'/* Directed Reserved */)) and
        (L.InventoryClass1 = @vRDInventoryClass1) and
        (L.InventoryClass2 = @vRDInventoryClass2) and
        (L.InventoryClass3 = @vRDInventoryClass3);

  /* Validate SKU */
  if (@vSKUId is null)
    set @vMessageName = 'SKUDoesNotExist';
  else
  /* Validate Quantity to Receive */
  if (coalesce(@Quantity, 0) = 0)
    set @vMessageName = 'QuantityToReceiveCantBeNullOrZero';
  else
  /* Validate LPN, if given - > exists > Appropriate Status to receive */
  if (((@LPNId is not null) or (@LPN is not null)) and
      (@vLPNId is null))
    set @vMessageName = 'LPNDoesNotExist';
  else
  /* As we are using this procedure to receive to location as well, we need exclude the validation of LPNStatus */
  if ((@vLPNType <> 'L' /* Logical */) and
      (@vLPNStatus not in ('N', 'R', 'T')  /* New, Received, Intransit */))
    set @vMessageName = 'InvalidLPNStatus';
  else
  if (@vLPNLineCount > 0) and (@vLPNDetailId is null) and (@vAllowMultiSKULPN = 'N'/* No */)
    set @vMessageName = 'CannotReceiveMultipleSKUsintoLPN';
  else
  /* As we are using this procedure to receive to location as well, we need exclude the validation of LPNStatus */
  if  (@vLPNLineCount > 0) and (@vLPNType <> 'L' /* Logical */) and (coalesce(@vLPNReceiptId, '0') <> @vReceiptId)
    set @vMessageName = 'CannotReceiveMultipleReceiptsIntoOneLPN';
  else
  if (@ReceiptDetailId is null)
    set @vMessageName = 'CannotFindSKU';
  else
  if (@vLPNStatus <> 'N'/* New */) and (@vLocationSubType <> 'D') and
     ((@vLPNInventoryClass1 <> @vRDInventoryClass1) or
      (@vLPNInventoryClass2 <> @vRDInventoryClass2) or
      (@vLPNInventoryClass3 <> @vRDInventoryClass3))
    set @vMessageName = 'Recv_InventoryClassMismatch'
  else
    set @vMessageName = dbo.fn_Receipts_ValidateOverReceiving(@ReceiptDetailId, @Quantity, @UserId);

  if (@vMessageName is null)
    set @vMessageName = dbo.fn_SKUs_IsOperationAllowed(@vSKUId, 'ReceiveSKU');

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Receive Inventory */
  exec @vReturnCode = pr_Receipts_ReceiveInventory @vReceiptId,
                                                   @ReceiptDetailId,
                                                   @vReceiverId,
                                                   @vSKUId,
                                                   @InnerPacks,
                                                   @Quantity,
                                                   @vWarehouse, /* Scanned Warehouse */
                                                   @vLocationId, /* Scanned Location */
                                                   @CustPO,
                                                   @BusinessUnit,
                                                   @UserId,
                                                   @vLPNId output,
                                                   @vLPNDetailId output;

  select @vLPN     = LPN,
         @vLPNType = LPNType
  from LPNs
  where (LPNId = @vLPNId)

  /* If it is not logical LPN and user did not scan the LPN, then print an LPN label */
  if (@vLPNType <> 'L' /* Logical */) and (@LPNId is null)
    exec pr_Printing_EntityPrintRequest 'Receiving', 'ReceiveToLPN', 'LPN', @vLPNId, @vLPN, @BusinessUnit, @UserId,
                                        @vDeviceId, 'IMMEDIATE', default /* PrinterName */;

  select @xmlResult = dbo.fn_XMLNode('LPNDetails',
                        dbo.fn_XMLNode('LPNId', @vLPNId) +
                        dbo.fn_XMLNode('LPNDetailId', @vLPNDetailId));

  /* Save Device State */
  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, null, @xmlResultvar, @@ProcId;

  /* Update Receiver of LPN */
  update LPNs
  set ReceiverId     = @vReceiverId,
      ReceiverNumber = @vReceiverNumber
  where (LPNId = @vLPNId);

  /* If provided pallet is not null, then add the LPNs in to the pallet and then set it in to a location */
  if (@Pallet is not null)
    begin
      /* Fetch PalletId to pass in to set pallets procedure */
      select @vPalletId = PalletId from Pallets where (Pallet = @Pallet);

      /* Set LPNs with the Pallet if valid pallet(Empty or the ones in the location) is provided */
      exec pr_LPNs_SetPallet @vLPNId, @vPalletId, @UserId;

      -- /* Set Pallet type */ .. The above calls Pallet set status which updates it!
      -- Update Pallets set PalletType = 'R' /* Receiving */ where PalletId = @vPalletId;

      /* Set location to the pallet if Location is passed as i/p */
      if (@vLocationId is not null)
        exec pr_Pallets_SetLocation @vPalletId, @vLocationId, 'NIT', /* Update LPNs Location, excluding Intransit ones */
                                    @BusinessUnit, @UserId;
    end

  /* Check the Onhand Status of the LPNDetail the new inventory was received against */
  select @vOnhandStatus = OnhandStatus
  from LPNDetails
  where (LPNDetailId = @vLPNDetailid);

  /* If new inventory was received into an LPN with OnhandStatus as available
     then the newly received inventory becomes available immediately, hence
     we need to export a receipt

     ToDo: Send ROH and ROD info in exports */
  if (@vReturnCode = 0) and (@vOnhandStatus = 'A' /* Available */)
    exec @vReturnCode = pr_Exports_LPNReceiptConfirmation @LPNId         = @vLPNId,
                                                          @LPNDetailId   = @vLPNDetailId,
                                                          @PAQuantity    = @Quantity,
                                                          @ToLocationId  = @vLocationId,
                                                          @FromWarehouse = @vWarehouse,
                                                          @CreatedBy     = @UserId;

  /* Receive To LPN is used for ReceiveToLocation as well, so if the LPN we received to is a
     logical LPN, then do not create AT here as caller is doing that */
  if (@vLPNType <> 'L' /* Logical LPN */)
    exec pr_AuditTrail_Insert 'ReceiveToLPN', @UserId, null /* ActivityTimestamp */,
                              @SKUId          = @vSKUId,
                              @Quantity       = @Quantity,
                              @LPNId          = @vLPNId,
                              @ReceiptId      = @vReceiptId,
                              @ReceiverId     = @vReceiverId,
                              @Warehouse      = @vWarehouse;

  /* The return dataset if requested is used for RF to show Receipt details */
  exec pr_ReceiptHeaders_GetToReceiveDetails @vReceiptId, @CustPO, @vReceiverNumber, @ReceiveToPallet, @ReceiveToLocation,
                                             'ReceiveToLPN', null /* Options */, @BusinessUnit, @UserId;

  /* Pass ReceiverNumber to Param to use in caller */
  select @PackingSlip = @vReceiverNumber;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Log the end of the transaction */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  /* Handling transactions in case it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  exec @vReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_ReceiveToLPN */

Go
