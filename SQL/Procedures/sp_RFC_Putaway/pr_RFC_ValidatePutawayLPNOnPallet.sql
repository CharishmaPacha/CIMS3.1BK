/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/29  RIA     pr_RFC_ValidatePutawayLPNOnPallet: Changes to validate PalletStatuses (CIMSV3-727)
  2013/03/25  PK      pr_RFC_ConfirmPutawayLPN, pr_RFC_ConfirmPutawayLPNOnPallet, pr_RFC_ValidatePutawayLPNOnPallet:
                       Changes related to Putaway MultiSKU LPNs
  2012/08/21  VM/NY   pr_RFC_ValidatePutawayLPNOnPallet: Allow Receiving/Inventory pallets to PA.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ValidatePutawayLPNOnPallet') is not null
  drop Procedure pr_RFC_ValidatePutawayLPNOnPallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ValidatePutawayLPNOnPallet:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ValidatePutawayLPNOnPallet
  (@Pallet              TPallet,
   @NumCases            TCount,
   @BusinessUnit        TBusinessUnit,
   @UserId              TUserId,
   @DeviceId            TDeviceId,
   @xmlResult           xml      output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage                TDescription,

          @vPalletId              TRecordId,
          @vPallet                TPallet,
          @vNumLPNs               TCount,
          @vPalletType            TTypeCode,
          @vPalletLocation        TLocation,
          @vPalletStatus          TStatus,
          @vQuantity              TQuantity,
          @vScanOption            TFlag,
          @vPalletWH              TWarehouse,
          @vLoggedInWarehouse     TWarehouse,
          @vNote1                 TDescription,
          @vValidPalletStatuses   TControlValue,
          @vValidPalletTypes      TControlValue,

          @vActivityLogId         TRecordId,
          @vNumLPNsOnPallet       TCount,
          @vValidateLPNsonPallet  TFlag,
          @xmlresultvar           TXML;
begin
begin try
  SET NOCOUNT ON;

  select @NumCases = nullif(@NumCases, 0);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      null, @Pallet, 'Pallet',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get Pallet Info into local variables */
  select @vPalletId          = P.PalletId,
         @vPallet            = P.Pallet,
         @vNumLPNs           = P.NumLPNs,
         @vPalletType        = P.PalletType,
         @vPalletLocation    = L.Location,
         @vPalletStatus      = P.Status,
         @vQuantity          = P.Quantity,
         @vPalletWH          = P.Warehouse
  from Pallets P left outer join Locations L on P.LocationId = L.LocationId
  where (P.Pallet       = @Pallet      ) and
        (P.BusinessUnit = @BusinessUnit);

  /* Count the number of Cases and the number of cases used on the pallet/Carts
     are treated in the system as pallets and they have a number of LPNs
     on them, however, they may not be in use all the time, hence for that
     purpose we would need to check the number of empty cases on the pallet */
  select @vNumLPNsOnPallet = count(*)
  from LPNs
  where (PalletId = @vPalletId) and
        (Quantity > 0);

  /* Fetch the control variables */
  select @vValidateLPNsOnPallet = dbo.fn_Controls_GetAsBoolean('Putaway', 'ValidateLPNsOnPallet', 'Y', @BusinessUnit, @UserId),
         @vValidPalletStatuses  = dbo.fn_Controls_GetAsString('Putaway_LPNsOnPallet', 'ValidPalletStatuses', 'PB', @BusinessUnit, @UserId),
         @vValidPalletTypes     = dbo.fn_Controls_GetAsString('Putaway_LPNsOnPallet', 'ValidPalletTypes', 'RICU', @BusinessUnit, @UserId),
         @vScanOption           = dbo.fn_Controls_GetAsString('Putaway', 'ScanOption', 'LS' /* LPN/SKU */, @BusinessUnit, @UserId);

  /* Get user logged in Warehouse */
  select @vLoggedInWarehouse = dbo.fn_Users_LoggedInWarehouse(@DeviceId, @UserId, @BusinessUnit);

  /* Validate i/p params */
  if (@vPalletId is null)
    set @vMessageName = 'PalletDoesNotExist';
  else
  if (@vPalletWH not in (select TargetValue
                         from dbo.fn_GetMappedValues('CIMS', @vLoggedInWarehouse,'CIMS', 'Warehouse', 'Putaway', @BusinessUnit)))
    select @vMessageName = 'PA_ScannedPalletIsOfDifferentWH', @vNote1 = @vPalletWH;
  else
  if (@vNumLPNsOnPallet = 0) -- or (@vPalletStatus = 'E' /* Empty */)
    set @vMessageName = 'PalletIsEmpty';
  else
  if (dbo.fn_IsInList(@vPalletStatus, @vValidPalletStatuses) = 0)
    set @vMessageName = 'PALPNsOnPallet_PalletStatusInvalid';
  else
  if (dbo.fn_IsInList(@vPalletType, 'RICU' /* Receiving/Inventory/Putaway */) = 0)
    set @vMessageName = 'NotaPutawayPallet';
  else
  if (@vNumLPNs = 0)
    set @vMessageName = 'NoLPNsOnThisPallet';
  else
  if (@vValidateLPNsOnPallet = 'Y') and
     (@vNumLPNsOnPallet <> coalesce(@NumCases, @vNumLPNsOnPallet))
    set @vMessageName = 'NumCasesOnPalletMismatch';

  if (@vMessageName is not null) goto ErrorHandler;

  /* All validations have passed, so identify the Next Case on the Pallet that
     needs to be putaway and respond to RF with that. */
  exec pr_Putaway_PAPalletNextLPNResponse @vPalletId,
                                          null /* Last LPN PA */,
                                          null /* Last SKU PA */,
                                          @vScanOption /* Scan Option */,
                                          @BusinessUnit,
                                          @UserId,
                                          @DeviceId,
                                          @xmlResult output;

  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'ValidatePutawayPallet', @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vNote1;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPalletId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPalletId, @ActivityLogId = @vActivityLogId output;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_ValidatePutawayLPNOnPallet */

Go
