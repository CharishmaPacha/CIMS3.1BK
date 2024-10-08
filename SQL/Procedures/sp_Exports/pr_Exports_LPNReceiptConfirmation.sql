/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/12  SV      pr_Exports_LPNReceiptConfirmation: Changes to send the InvCh transactions for the Host sent receipts only (OB2-1794)
  2021/05/06  SV      pr_Exports_LPNReceiptConfirmation: Changes to manage TransType over the exoports (OB2-1791)
  2020/05/15  RT      pr_Exports_LPNReceiptConfirmation: Made chnages to send +ve and -ve InvCh trans for transfer orders (HA-111)
  2020/04/29  MS      pr_Exports_OnhandInventory, pr_Exports_LPNData, pr_Exports_LPNReceiptConfirmation: Changes to send InventoryClasses in Exports (HA-323)
  2019/12/12  MS      pr_Exports_LPNReceiptConfirmation: Changes to do not send the WHXfer Transactins (CID-1169)
  2018/05/08  RV      pr_Exports_LPNReceiptConfirmation: Added new parameter to send a from Warehouse (S2G-714)
  2017/09/14  SV      pr_Exports_LPNReceiptConfirmation: This proc evaluates which TransType to be invoke (HPI-1327)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_LPNReceiptConfirmation') is not null
  drop Procedure pr_Exports_LPNReceiptConfirmation;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_LPNReceiptConfirmation:
    This procedure generates the Recv export records for the given ReceiptId.
    If the New LPN moved to a new Location(Same/Diff WH), then this procedure
      evaluates the type of Export which needs to be generated.

  Note that the LPN's Warehouse would have already been updated by the time this
  procedure is called. The @FromWarehouse is the original WH the LPN was received
  into and the current L.DestWarehouse is the Wh the LPN was putaway into.

  If doing Putaway into a picklane, then we have to consider the ToWH to be that
  of the Location.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_LPNReceiptConfirmation
 (@ReceiptId        TRecordId     = null,
  @LPNId            TRecordId     = null,
  @LPNDetailId      TRecordId     = null,
  @PAQuantity       TQuantity     = null,
  @ToLocationId     TRecordId     = null,
  @FromWarehouse    TWarehouse    = null,
  @CreatedBy        TUserId       = null)
as
  declare @vReceiptId             TRecordId,
          @vReceiptNumber         TReceiptNumber,
          @vReceiptType           TReceiptType,
          @vSourceSystem          TName,
          @vWHOverReceipt         TWarehouse,
          @vReceiptDetailId       TRecordId,

          @vLPNId                 TRecordId,
          @vLPNStatus             TStatus,
          @vLPNLocation           TLocation,
          @vLPNDetailId           TRecordId,
          @vLPNLocationId         TRecordId,
          @vLPNDestWarehouse      TWarehouse,

          @vToLocationId          TRecordId,
          @vToLocation            TLocation,
          @vToLocType             TLocationType,
          @vToLPNId               TRecordId,
          @vToLPN                 TLPN,
          @vToLocationWH          TWarehouse,

          @vOwnership             TOwnership,
          @vTransType             TTypeCode,
          @vPAQuantity            TQuantity,
          @vLogicalLPNId          TRecordId,
          @vToWH                  TWarehouse,
          @vBusinessUnit          TBusinessUnit,
          @vCreatedBy             TUserId,
          @vWHXfer                TFlag = 'N',
          @vControlCategory       TCategory,
          @vSendInvChTransForRecv TFlag,
          @vMessageName           TMessageName,
          @vReturnCode            TInteger;

begin /* pr_Exports_LPNReceiptConfirmation */

  select @vPAQuantity = @PAQuantity,
         @vCreatedBy  = @CreatedBy,
         @vWHXfer     = 'N',
         @vTransType  = '';

  if (@LPNId is not null)
    select @vLPNId            = LPNId,
           @vLPNStatus        = Status,
           @vLPNLocationId    = LocationId,
           @vReceiptId        = ReceiptId,
           @vReceiptNumber    = ReceiptNumber,
           @vLPNDestWarehouse = DestWarehouse,
           @vOwnership        = Ownership,
           @vBusinessUnit     = BusinessUnit
    from LPNs
    where (LPNId = @LPNId);

  /* Get LPN Location */
  if (@vLPNLocationId is not null)
    select @vLPNLocation = Location
    from Locations
    where (LocationId = @vLPNLocationId);

  /* Get To Location Info */
  if (@ToLocationId is not null)
    select @vToLocationId = LocationId,
           @vToLocation   = Location,
           @vToLocType    = LocationType,
           @vToLocationWH = Warehouse
    from Locations
    where (LocationId = @ToLocationId);

  /* If the LPN is putaway into PickLane Loc, then we need to send the trans which corresponds
     to the picklane location */
  if (@vToLocType = 'K' /* PickLane */)
    begin
      select @vLogicalLPNId = LPNId
      from LPNs
      where (LPN = @vToLocation);

      /* If inventory is being PA to a picklane, then ToWH is the Warehouse of the Location
         not that of the LPN */
      select @vToWH = @vToLocationWH;
    end
  else
    select @vToWH = @vLPNDestWarehouse;

  if (coalesce(@vReceiptId, 0) <> 0)
    select @vReceiptType  = ReceiptType,
           @vSourceSystem = SourceSystem
    from ReceiptHeaders
    where (ReceiptId = @vReceiptId);

  select @vControlCategory =  'Receipts_' + @vReceiptType;

  select @vSendInvChTransForRecv = dbo.fn_Controls_GetAsBoolean(@vControlCategory, 'SendInvChTransForRecv', 'N' /* No */, @vBusinessUnit, @CreatedBy);

  /* If Receipt Info is present over the LPN, at any cost we will be sending "Recv" trans once after receiving the LPN */
  if ((coalesce(@vReceiptId, 0) <> 0) or (@vReceiptNumber is not null))
    begin
      /* If RH was not generated by Host, we send InvCh or Recv Transactions based upon control var */
      if (@vSendInvChTransForRecv = 'Y') and (@vSourceSystem <> 'Host')
        select @vTransType = 'InvCh';
      else
        /* If inbound transfer, no Recv transaction is sent, only WHXfer */
        select @vTransType = 'Recv';

      /* After receiving the LPN, if we putaway LPN into a diff WH than that of RO, then we would want to
         also send a WH transfer following the receipt
         If receiving an inbound transfer, we send a WHXFer as well - whether that is one record
         of WXfer or two records of InvCh -/+ is determined in pr_Exports_WarehouseTransfer */
      if (@FromWarehouse <> @vToWH)
        select @vWHXfer = 'Y';
    end
  else
    /* Irrespective of the WH over LPN and Putaway Loc, we do generate InvCh trans */
    select @vTransType = 'InvCh';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Send the appropriate TransType i.e. Recv or InvCh */
  if (coalesce(@vTransType, '') <> '')
    exec @vReturnCode = pr_Exports_LPNData @TransType       = @vTransType,
                                           @TransQty        = @vPAQuantity,
                                           @BusinessUnit    = @vBusinessUnit,
                                           @LPNId           = @vLPNId,
                                           @LPNDetailId     = @LPNDetailId,
                                           @LocationId      = @ToLocationId,
                                           @ReceiptId       = @vReceiptId,
                                           @Warehouse       = @FromWarehouse,
                                           @Ownership       = @vOwnership,
                                           @CreatedBy       = @vCreatedBy;

  /* In case if the Inv is moved across Warehouses, CIMS sends either InvCh/WHXfer transactions as per the
     controls configured for the client. These trans will be evaluated in pr_Exports_WarehouseTransfer  */
  if (@vWHXfer = 'Y')
    exec pr_Exports_WarehouseTransfer @TransQty     = @vPAQuantity,
                                      @BusinessUnit = @vBusinessUnit,
                                      @LPNId        = @vLogicalLPNId,
                                      @LPNDetailId  = @LPNDetailId,
                                      @LocationId   = @ToLocationId,
                                      @FromLPNId    = @vLPNId,
                                      @OldWarehouse = @FromWarehouse,
                                      @NewWarehouse = @vToWH,
                                      @CreatedBy    = @vCreatedBy;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_LPNReceiptConfirmation */

Go
