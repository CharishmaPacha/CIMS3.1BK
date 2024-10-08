/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/24  MS      pr_RFC_ReceiveASNLPN: Changes to insert Palletinfo in Audit trail (JL-306)
  2020/11/16  MS      pr_RFC_ReceiveASNLPN: Changes to return Pallet info & SuccesMsg (JL-306)
  2020/11/02  MS      pr_RFC_ReceiveASNLPN: Changes to send ReceiverNumber to caller & Code cleanup (JL-291)
  2019/05/24  VS      pr_RFC_ReceiveASNLPN: Added Control for SKU Volume Validation (CID-344)
  2019/04/10  RKC     pr_RFC_ReceiveASNLPN: Pass the ReceiverNumber to the pr_AuditTrail_Insert (CID-98)
  2019/02/08  RIA     pr_RFC_ReceiveASNLPN: Added logging (CID-76)
  2014/04/08  PV      pr_RFC_ReceiveASNLPN: Added UPC code validation and minor issue fix.
  2014/04/05  PV      pr_RFC_ValidateASNLPN, pr_RFC_ReceiveASNLPN:
                        Enhanced for multiple sku lpns.
  2014/04/04  PKS     pr_RFC_ReceiveASNLPN: Quantity on LPN and LPNDetail are updated with ConfirmQty.
  2014/03/23  PKS     pr_RFC_ReceiveASNLPN: Added Location and Pallet in InputXML for AT Log and passing to pr_Receipts_ReceiveASNLPN.
  2014/03/20  PKS     pr_RFC_ReceiveASNLPN pr_RFC_ValidateASNLPN: Made changes in XML Structure and
  2014/03/14  PKS     pr_RFC_ValidateASNLPN, pr_RFC_ReceiveASNLPN: Signatures changed, such that these two procedures will
                      have two XML parameters as Input and output.
  2012/06/29  YA      Modified pr_RFC_ReceiveASNLPN sub procedure call (to call pr_Receipts_ReceiveASNLPN)
  2011/03/11  VM      pr_RFC_ReceiveASNLPN: Consider the right line from ReceiptDetails
  2011/02/17  PK      pr_RFC_ReceiveASNLPN : Changed Parameter as LPN and validated Quantity.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ReceiveASNLPN') is not null
  drop Procedure pr_RFC_ReceiveASNLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ReceiveASNLPN:
  ConfirmASNLPN inputXML:
  <ReceiveASNLPNInput>
    <LPN></LPN>
    <ReceiptNumber></ReceiptNumber>
    <ReceiverNumber></ReceiverNumber>
    <SKU></SKU>
    <Pallet></Pallet>
    <Location></Location>
    <Quantity></Quantity>
    <Exception></Exception>
    <ConfirmSKU></ConfirmSKU>
    <ConfirmQuantity></ConfirmQuantity>
    <BusinessUnit></BusinessUnit>
    <UserId></UserId>
  </ReceiveASNLPNInput>


 <SUCCESSDETAILS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <SUCCESSINFO>
    <ReturnCode>0</ReturnCode>
    <Message>Hello</Message>
  </SUCCESSINFO>
</SUCCESSDETAILS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ReceiveASNLPN
  (@xmlInput   xml,
   @xmlResult  xml output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vMessage             TMessage,
          /* Receipts Info */
          @vReceiptNumber       TReceiptNumber,
          @vReceiverNumber      TReceiverNumber,
          @vReceiptId           TRecordId,
          @vReceiptDetailId     TRecordId,
          @vCustPO              TCustPO,
          @vWarehouse           TWarehouse,
          @vUnitsReceived       TQuantity,
          @vLPNsReceived        TCount,
          @vUnitsInTransit      TQuantity,
          @vLPNsInTransit       TCount,
          @vReceivedLPNsCount   TCount,
          @vTotalLPNsCount      TCount,
          /* LPN Info */
          @vLPNId               TRecordId,
          @vLPN                 TLPN,
          @vLPNReceiptId        TRecordId,
          @vLPNDetailId         TRecordId,
          @vLPNDestZone         TTypeCode,
          @vLPNOwnership        TOwnership,
          @vLPNWarehouse        TWarehouse,
          @vLPNPallet           TPallet,
          @vSKUId               TRecordId,
          @vSKU                 TSKU,
          @vUPC                 TUPC,
          @vQuantity            TQuantity,
          @curLPNId             TRecordId,
          @curLPN               TLPN,
          @curLPNDetailId       TRecordId,
          @curSKUId             TRecordId,
          @curQuantity          TQuantity,
          /* Pallet Info */
          @vPalletId            TRecordId,
          @vPallet              TPallet,
          @vPalletDestZone      TTypeCode,
          @vLocationId          TRecordId,
          @vLocation            TLocation,
          @vException           TFlag,
          @vConfirmSKU          TSKU,
          @vConfirmQuantity     TQuantity,
          @vQtyConfirmed        TString,
          @vDisplayReceivedQty  TDescription,
          @vExportOption        TFlag,
          @vActivityLogId       TRecordId,
          @vAuditActivity       TDescription,
          @vBusinessUnit        TBusinessUnit,
          @vUserId              TUserId;
begin
begin try
  SET NOCOUNT ON;

  select @vLPN             = nullif(Record.Col.value('LPN[1]',             'TLPN'), ''),
         @vReceiptNumber   = nullif(Record.Col.value('ReceiptNumber[1]',   'TReceiptNumber'), ''),
         @vReceiverNumber  = nullif(Record.Col.value('ReceiverNumber[1]',  'TReceiverNumber'), ''),
         @vSKU             = nullif(Record.Col.value('SKU[1]',             'TSKU'), ''),
         @vPallet          = nullif(Record.Col.value('Pallet[1]',          'TPallet'), ''),
         @vLocation        = nullif(Record.Col.value('Location[1]',        'TLocation'), ''),
         @vQuantity        = nullif(Record.Col.value('Quantity[1]',        'TQuantity'), ''),
         @vException       = nullif(Record.Col.value('Exception[1]',       'TFlag'), ''),
         @vConfirmSKU      = nullif(Record.Col.value('ConfirmSKU[1]',      'TSKU'), ''),
         @vConfirmQuantity = nullif(Record.Col.value('ConfirmQuantity[1]', 'TQuantity'), ''),
         @vBusinessUnit    = nullif(Record.Col.value('BusinessUnit[1]',    'TLPN'), ''),
         @vUserId          = nullif(Record.Col.value('UserId[1]',          'TUserId'), ''),
         @vQtyConfirmed    = nullif(Record.Col.value('QtyConfirmed[1]',    'TString'), '')
  from @xmlInput.nodes('/ReceiveASNLPNInput') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, null /* DeviceId */,
                      null, @vLPN, 'LPN',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* If the value is not returned from caller, assumed confirmed as N */
  select @vQtyConfirmed = coalesce(@vQtyConfirmed,'N');

  /* Fetch LPN from given ASNCase */
  select @vLPNId          = LPNId,
         @vLPN            = LPN,
         @vLPNDestZone    = DestZone,
         @vLPNWarehouse   = DestWarehouse,
         @vLPNOwnership   = Ownership,
         @vLPNReceiptId   = ReceiptId,
         @vLPNPallet      = Pallet,
         @vReceiverNumber = coalesce(@vReceiverNumber, ReceiverNumber),
         @vExportOption   = case when (OH_UDF1 = 'CrossDock') then 'Y' else 'N' end
  from vwLPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@vLPN, @vBusinessUnit, 'LA' /* Options */));

  /* Fetch SKUId from given SKU. If user scanned UPC or some other SKU identifier, we may
     have issues, to limit the scope to the Receipt of the LPN being received */
  select @vSKUId = SS.SKUId,
         @vSKU   = SS.SKU
  from dbo.fn_SKUs_GetScannedSKUs (@vSKU, @vBusinessUnit) SS
    join ReceiptDetails RD on (SS.SKUId = RD.SKUId) and (RD.ReceiptId = @vLPNReceiptId)

  select @vLPNDetailId     = LPNDetailId,
         @vReceiptDetailId = ReceiptDetailId
  from LPNDetails
  where (LPNId = @vLPNId) and
        (SKUId = @vSKUId);

  select @vLocationId = LocationId
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @vLocation, null /* DeviceId */, @vUserId, @vBusinessUnit));

  select @vPallet = coalesce(@vPallet, @vLPNPallet);
  select @vPalletId       = PalletId,
         @vPalletDestZone = DestZone
  from Pallets
  where (Pallet = @vPallet) and (BusinessUnit = @vBusinessUnit);

  /* Fetch ReceiptId from given ReceiptNumber */
  select @vReceiptId     = ReceiptId,
         @vReceiptNumber = ReceiptNumber,
         @vWarehouse     = Warehouse
  from ReceiptHeaders
  where (ReceiptNumber = @vReceiptNumber) and
        (BusinessUnit  = @vBusinessUnit);

  select @vReceiptDetailId = ReceiptDetailId
  from ReceiptDetails
  where (ReceiptDetailId = @vReceiptDetailId);

  if (@vLPNId is null)
    set @vMessageName = 'ASNCaseDoesNotExist';
  else
  if (@vReceiptId is null)
    set @vMessageName = 'ReceiptDoesNotExist';
  else
  if ((@vQtyConfirmed = 'N') and(@vReceiptDetailId is null))
    set @vMessageName = 'ReceiptLineDoesNotExist';
  else
  if ((@vQtyConfirmed = 'N') and (@vSKUId is null))
    set @vMessageName = 'SKUDoesNotExist';
  else
  if ((@vSKU <> @vConfirmSKU) and (@vUPC <> @vConfirmSKU))
    set @vMessageName = 'SKUMismatch';/* SKU and confirm-SKU must match unless raise error */
  else
  if (@vConfirmQuantity < 0)   /* Quantity must not be less than 0 */
    set @vMessageName = 'InvalidQuantity';
  else
    set @vMessageName = dbo.fn_SKUs_IsOperationAllowed(@vSKUId, 'Receiving');

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Iterate through all the confirmed LPN details if QtyConfirmed is 'true',
     else process only the confirmed sku */
  declare LPNLinesToReceive Cursor Local Forward_Only Static Read_Only
  For select LPNId,LPN,LPNDetailId, SKUId,
             Case
              when (@vQtyConfirmed = 'N') then
                coalesce(@vConfirmQuantity,0)
              else
                Quantity
             end
      from vwLPNDetails
      where ((@vQtyConfirmed = 'Y') or (SKUId = @vSKUId)) and
            (LPNId = @vLPNId) and
            (ReceivedUnits = 0) and
            (Quantity > 0);

  Open LPNLinesToReceive;
  Fetch next from LPNLinesToReceive into @curLPNId,
                                         @curLPN,
                                         @curLPNDetailId,
                                         @curSKUId,
                                         @curQuantity;

  while (@@fetch_status = 0)
    begin
      /* Call Receipts Receive ASNLPN procedure */
      exec @vReturnCode = pr_Receipts_ReceiveASNLPN @curLPNId,
                                                    @curLPN,
                                                    @curLPNDetailId,
                                                    @curQuantity,
                                                    @vPallet,
                                                    @vLocation,
                                                    @vExportOption,
                                                    @vBusinessUnit,
                                                    @vUserId,
                                                    @vReceiverNumber output,
                                                    @vMessage output;

      if (@vReturnCode = 0)
        begin
          select @vAuditActivity = case when coalesce(@vPallet, '') <> ''
                                   then 'PalletizeLPN'
                                   else 'ReceiveToLPN'
                                   end;

          exec pr_AuditTrail_Insert @vAuditActivity, @vUserId, null /* ActivityTimestamp */,
                                    @SKUId          = @curSKUId,
                                    @ToLocationId   = @vLocationId,
                                    @PalletId       = @vPalletId,
                                    @Quantity       = @vConfirmQuantity,
                                    @LPNId          = @vLPNId,
                                    @ReceiptId      = @vReceiptId,
                                    @ReceiverNumber = @vReceiverNumber,
                                    @Warehouse      = @vWarehouse;
        end

      Fetch next from LPNLinesToReceive into @curLPNId,
                                             @curLPN,
                                             @curLPNDetailId,
                                             @curSKUId,
                                             @curQuantity;
    end

  /* When first LPN is added to pallet, set several parameters on the Pallet */
  if (@vPalletId is not null)
    update Pallets
    set DestZone    = @vLPNDestZone,
        Warehouse   = @vLPNWarehouse,
        LocationId  = @vLocationId,
        Ownership   = @vLPNOwnership
    where (PalletId = @vPalletId) and (Quantity = 0);

  if (exists (select * from LPNDetails
              where (LPNId = @vLPNId) and
                    (ReceivedUnits = 0) and
                    (Quantity > 0)))
    begin
     set @xmlInput = (select coalesce(@vLPNId,'')                as LPNId,
                             coalesce(@vLPN,'')                  as LPN,
                             coalesce(@vReceiverNumber,'')       as ReceiverNumber,
                             coalesce(@vReceiptNumber,'')        as ReceiptNumber,
                             coalesce(@vCustPO,'')               as CustPO,
                             coalesce(@vLocation,'')             as Location,
                             coalesce(@vPallet, @vLPNPallet, '') as Pallet,
                             coalesce(@vBusinessUnit,'')         as BusinessUnit,
                             coalesce(@vUserId,'')               as UserId
                      for XML raw(''), type, elements, root('ValidateASNLPNInput'));

      exec @vReturnCode = pr_RFC_ValidateASNLPN @xmlInput, @xmlResult output;
    end
  else
    begin
      select @vReceiptNumber  = ReceiptNumber,
             @vUnitsReceived  = UnitsReceived,
             @vLPNsReceived   = LPNsReceived,
             @vUnitsInTransit = UnitsInTransit,
             @vLPNsInTransit  = LPNsInTransit,
             @vTotalLPNsCount = NumLPNs
      from ReceiptHeaders
      where (ReceiptId = @vLPNReceiptId);

      /* Build the Received qty info to display in RF */
      set @vDisplayReceivedQty = cast(coalesce(@vLPNsReceived, 0) as varchar(max)) + ' of ' +
                                 cast(coalesce(@vTotalLPNsCount, 0) as varchar(max)) + ' LPNs';

      set @xmlResult = (select coalesce(@vReturnCode,0)            as ReturnCode,
                               coalesce(@vMessage,'')              as Message,
                               coalesce(@vReceiverNumber,'')       as ReceiverNumber,
                               coalesce(@vReceiptNumber,'')        as ReceiptNumber,
                               coalesce(@vPallet, @vLPNPallet, '') as Pallet,
                               coalesce(@vUnitsReceived,0)         as UnitsReceived,
                               coalesce(@vLPNsReceived,0)          as LPNsReceived,
                               coalesce(@vUnitsInTransit,0)        as UnitsInTransit,
                               coalesce(@vLPNsInTransit,0)         as LPNsInTransit,
                               @vDisplayReceivedQty                as DisplayReceivedQty
                        For XML raw(''), type, elements, root('ReceiveASNLPNResult'));
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  select @vMessageName = ERROR_MESSAGE(),
         @vReturnCode  = 1;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;
end catch;

  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_ReceiveASNLPN */

Go
