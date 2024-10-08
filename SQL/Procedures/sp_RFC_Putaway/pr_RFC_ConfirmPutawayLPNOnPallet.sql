/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/01/10  SV      pr_RFC_ConfirmPutawayLPNOnPallet: Signature correction while calling pr_RFC_ConfirmPutawayLPN (S2G-72)
  2016/03/14  DK      pr_RFC_ConfirmPutawayLPNOnPallet, pr_RFC_ConfirmPutawayLPNOnPallet: Validate if LPN is on Pallet.(CIMS-807).
  2014/08/18  TK      pr_RFC_ConfirmPutawayLPNOnPallet: Updated not to update Audit Trail.
  2014/07/16  PK      pr_RFC_ConfirmPutawayLPN, pr_RFC_ConfirmPutawayLPNOnPallet: Included TransCount for transactions.
  2103/06/04  TD      pr_RFC_PA_ValidatePutawayPallet,pr_RFC_ConfirmPutawayLPNOnPallet: Allow LPNs to add  to Putaway type Pallet.
  2013/03/31  PK      pr_RFC_ConfirmPutawayLPNOnPallet: Changes for accepting UPC and SKU.
  2013/03/25  PK      pr_RFC_ConfirmPutawayLPN, pr_RFC_ConfirmPutawayLPNOnPallet, pr_RFC_ValidatePutawayLPNOnPallet:
                       Changes related to Putaway MultiSKU LPNs
  2012/12/24  NY      pr_RFC_ConfirmPutawayLPNOnPallet: Added Pallet type of Inventory.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ConfirmPutawayLPNOnPallet') is not null
  drop Procedure pr_RFC_ConfirmPutawayLPNOnPallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ConfirmPutawayLPNOnPallet:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ConfirmPutawayLPNOnPallet
  (@Pallet             TPallet,
   @PutawayLPN         TLPN,
   @ScannedLPN         TLPN,
   @SKU                TSKU,
   @PutawayZone        TLookUpCode,
   @PutawayLocation    TLocation,
   @ScannedLocation    TLocation,
   @PAInnerPacks       TInnerPacks, /* Future Use */
   @PAQuantity         TQuantity,
   @ScanOption         TFlag,
   @Operation          TOperation,
   @SubOperation       TOperation,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @DeviceId           TDeviceId,
   @xmlResult          xml       output)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @Message             TDescription,

          @vPALPNId            TRecordId,
          @vPASKUId            TRecordId,
          @vSKU                TSKU,
          @vPalletId           TRecordId,
          @vLPNPalletId        TRecordId,
          @vPallet             TPallet,
          @vNumLPNs            TCount,
          @vPalletType         TTypeCode,
          @vPalletLocation     TLocation,
          @vPalletStatus       TStatus,
          @vQuantity           TQuantity,
          @vNumLPNsOnPallet    TCount,

          @vActivityLogId      TRecordId,
          @vXmlData            TXML,
          @xmlresultvar        TXML;

begin
begin try
  SET NOCOUNT ON;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      null, @ScannedLPN, 'LPN', @Value1 = @Pallet,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get Pallet Info */
  select @vPalletId          = P.PalletId,
         @vPallet            = P.Pallet,
         @vNumLPNs           = P.NumLPNs,
         @vPalletType        = P.PalletType,
         @vPalletLocation    = L.Location,
         @vPalletStatus      = P.Status,
         @vQuantity          = P.Quantity
  from Pallets P left outer join Locations L on P.LocationId = L.LocationId
  where ((P.Pallet       = @Pallet      ) and
         (P.BusinessUnit = @BusinessUnit))

  /* Get the SKU information even when the user has scanned UPC/SKU/Barcode */
  if (@SKU is not null)
    select @vSKU  = SKU
    from dbo.fn_SKUs_GetScannedSKUs (@SKU, @BusinessUnit);

  /* Get the Id of the scanned LPN */
  select @vPALPNId     = LPNId,
         @vPASKUId     = SKUId,
         @vLPNPalletId = PalletId
  from vwLPNDetails
  where (LPN          = @ScannedLPN) and
        (SKU          = @vSKU) and
        (BusinessUnit = @BusinessUnit);

    /* Count the number of Cases and the number of cases used on the pallet/Carts
     are treated in the system as pallets and they have a number of LPNs
     on them, however, they may not be in use all the time, hence for that
     purpose we would need to check the number of empty cases on the pallet */
  select @vNumLPNsOnPallet = count(*)
  from LPNs
  where (PalletId = @vPalletId) and
        (Quantity > 0);

  /* Validations */
  /* Validations for Pallet as it is not validated by ConfirmPutawayLPN */

  if (@vPalletId is null)
    set @MessageName = 'PalletDoesNotExist';
  else
  if (@vLPNPalletId is null)
    set @MessageName = 'LPNNotOnaPallet';
  else
  if (@vPalletId <> coalesce(@vLPNPalletId, ''))
    set @MessageName = 'LPNNotOnPAPallet';
  else
  if (@vNumLPNsOnPallet = 0) -- or (@vPalletStatus = 'E' /* Empty */)
    set @MessageName = 'PalletIsEmpty';
  else
  if (charindex(@vPalletStatus, '?') <> 0) /* Currently not enforced */
    set @MessageName = 'PalletStatusInvalid';
  else
  if (charindex(@vPalletType, 'RICU' /* Receiving,Inventory, Putaway */) = 0)
    set @MessageName = 'NotaPutawayPallet';

  if (@MessageName is not null)
     goto ErrorHandler;

  select @vXmlData = '<CONFIRMPUTAWAYLPN>' +
                         dbo.fn_XMLNode('LPN',             @ScannedLPN) +
                         dbo.fn_XMLNode('SKU',             @vSKU) +
                         dbo.fn_XMLNode('DestZone',        @PutawayZone) +
                         dbo.fn_XMLNode('DestLocation',    @PutawayLocation) +
                         dbo.fn_XMLNode('ScannedLocation', @ScannedLocation) +
                         dbo.fn_XMLNode('PAInnerPacks',    @PAInnerPacks) +
                         dbo.fn_XMLNode('PAQuantity',      @PAQuantity) +
                         dbo.fn_XMLNode('PAType',          @ScanOption) +
                         dbo.fn_XMLNode('DeviceId',        @DeviceId) +
                         dbo.fn_XMLNode('UserId',          @UserId) +
                         dbo.fn_XMLNode('BusinessUnit',    @BusinessUnit) +
                    '</CONFIRMPUTAWAYLPN>';

  /* Putaway Case on a pallet is accomplished by an existing procedure */
  exec @ReturnCode = pr_RFC_ConfirmPutawayLPN @vXmlData;

  /* If there is an exception in ConfirmPutawayLPN an exception is raised, so
     no additional error checking is required here, Catch block does
     what is needed */

  /* Last LPN was successfully Putaway, give the next LPN to Putaway */
  if (@Operation = 'PutawayLPNs')
    exec @ReturnCode = pr_Putaway_PutawayLPNsBuildResponse @vPalletId,
                                                           @vPallet,
                                                           @SubOperation,
                                                           @BusinessUnit,
                                                           @UserId,
                                                           @xmlResult output;
  else
    exec @ReturnCode = pr_Putaway_PAPalletNextLPNResponse @vPalletId,
                                                          @vPALPNId, /* Last LPN Putaway */
                                                          @vPASKUId, /* Last SKU Putaway */
                                                          @ScanOption,
                                                          @BusinessUnit,
                                                          @UserId,
                                                          @DeviceId,
                                                          @xmlResult output;

  /* Update Device Current Operation Details, etc... */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'ConfirmPutawayLPNOnPallet', @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPALPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPALPNId, @ActivityLogId = @vActivityLogId output;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_ConfirmPutawayLPNOnPallet */

Go
