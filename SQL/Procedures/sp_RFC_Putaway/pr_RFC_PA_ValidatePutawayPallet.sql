/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/23  AY      pr_RFC_PA_ValidatePutawayPallet: Performance optimizations (HA-3110)
  2020/05/13  RT      pr_RFC_PA_ValidatePutawayPallet: Included Built Status to Putaway (HA-504)
  2020/04/07  VM      pr_RFC_PA_ValidatePutawayPallet: Included custom validations through rules (HA-118)
  2015/10/19  TK      pr_RFC_PA_ValidatePutawayPallet: Enhanced to prevent PA of multi SKU Pallet if
                        Allow multiple SKUs flag option is set to 'N' (ACME-375)
  2103/06/04  TD      pr_RFC_PA_ValidatePutawayPallet,pr_RFC_ConfirmPutawayLPNOnPallet: Allow LPNs to add  to Putaway type Pallet.
  2012/04/11  PK      pr_RFC_PA_ValidatePutawayPallet: Added a validation for not allowing the pallet
                       to putaway if the LPNs on the pallet has different destWarehouse.
  2012/03/16  PK      Added pr_RFC_PA_ValidatePutawayPallet, pr_RFC_PA_ConfirmPutawayPallet.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_PA_ValidatePutawayPallet') is not null
  drop Procedure pr_RFC_PA_ValidatePutawayPallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_PA_ValidatePutawayPallet:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_PA_ValidatePutawayPallet
  (@Pallet              TPallet,
   @NumLPNsonPallet     TCount,
   @BusinessUnit        TBusinessUnit,
   @UserId              TUserId,
   @DeviceId            TDeviceId,
   @xmlResult           xml      output)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vOperation                  TOperation,

          @vPalletId                   TRecordId,
          @vPallet                     TPallet,
          @vPalletWH                   TWarehouse,
          @vNumLPNs                    TCount,
          @vPalletType                 TTypeCode,
          @vPalletLocation             TLocation,
          @vPalletStatus               TStatus,
          @vSKUCount                   TCount,
          @vQuantity                   TQuantity,

          @vNumLPNsOnPallet            TCount,
          @vDestWarehouseCount         TCount,
          @vValidateLPNsonPallet       TFlag,
          @xmlresultvar                varchar(max),

          @vActivityLogId              TRecordId,
          @vNote1                      TDescription,
          @vLoggedInWarehouse          TWarehouse,
          @vAllowMultipleSKUsOnPallet  TFlag,
          @xmlRulesData                TXML;
begin
begin try
  SET NOCOUNT ON;

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
  from Pallets P
    left outer join Locations L on P.LocationId = L.LocationId
  where (PalletId = dbo.fn_Pallets_GetPalletId (@Pallet, @BusinessUnit));

  /* Get control values */
  select @vOperation                 = 'ValidatePutawayPallet',
         @vAllowMultipleSKUsOnPallet = dbo.fn_Controls_GetAsString('Pallets', 'AllowMultipleSKUs', 'Y'/* Yes */, @BusinessUnit, @UserId),
         @vValidateLPNsOnPallet      = dbo.fn_Controls_GetAsBoolean('Putaway', 'ValidateLPNsOnPallet', 'Y', @BusinessUnit, @UserId);

  /* Get user logged in Warehouse */
  select @vLoggedInWarehouse = dbo.fn_Users_LoggedInWarehouse(@DeviceId, @UserId, @BusinessUnit);

  /* To validate Warehouse of the lpns on pallet we are getting Count of DestWarehouse */
  select @vDestWarehouseCount = count(distinct DestWarehouse)
  from LPNs
  where (PalletId = @vPalletId);

  select @vSKUCount = count(distinct LD.SKUId)
  from LPNs L join LPNDetails LD on L.LPNId = LD.LPNId
  where (PalletId = @vPalletId);

  /* Build the XML for custom validations */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                         dbo.fn_XMLNode('Operation',      @vOperation) +
                         dbo.fn_XMLNode('PalletId',       @vPalletId));

  /* Validations */
  if (@vPalletId is null)
    set @vMessageName = 'PalletDoesNotExist';
  else
  if (@vPalletWH not in (select TargetValue
                         from dbo.fn_GetMappedValues('CIMS', @vLoggedInWarehouse,'CIMS', 'Warehouse', 'Putaway', @BusinessUnit)))
   select @vMessageName = 'PA_ScannedPalletIsOfDifferentWH', @vNote1 = @vPalletWH;
  else
  if (@vNumLPNs = 0)
    set @vMessageName = 'NoLPNsOnThisPallet';
  else
  /* Do not allow Pallets other than Received and Putaway Status to putaway */
  if (charindex(@vPalletStatus, 'PRB' /* Putaway, Received, Built */) = 0)
    set @vMessageName = 'PalletStatusInvalid';
  else
  if (charindex(@vPalletType, 'RI' /* Receiving, Inventory */) = 0)
    set @vMessageName = 'NotaPutawayPallet';
  else
  /* Return if it is a multi SKU Pallet and we are not allowing Multi SKU Pallet to Putaway */
  if (@vAllowMultipleSKUsOnPallet = 'N' /* No */) and (@vSKUCount > 1)
    set @vMessageName = 'CannotPutawayMultiSKUPallet';
  else
  if (@vValidateLPNsOnPallet = 'Y') and
     (@NumLPNsonPallet <> coalesce(@vNumLPNs, @vNumLPNsOnPallet))
    set @vMessageName = 'NumLPNsOnPalletMismatch';
  else
  /* If the count of LPNs destWarehouse on the pallet is not equal to 1,
     then we will not allow the Pallet to putaway */
  if (@vDestWarehouseCount <> 1)
    set @vMessageName = 'MultipleDestinedWarehouses';
  else
    /* Other custom validations */
    exec pr_RuleSets_Evaluate 'Putaway_Validations', @xmlRulesData, @vMessageName output;

  if (@vMessageName is not null)
     goto ErrorHandler;

  /* All validations have passed, so identify the Locations for the Pallet to
     putaway and respond to RF with that. */
  exec pr_Putaway_FindLocationForPallet @vPalletId,
                                        @BusinessUnit,
                                        @UserId,
                                        @DeviceId,
                                        @xmlResult output;

  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, @vOperation, @xmlResultvar, @@ProcId;

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
end /* pr_RFC_PA_ValidatePutawayPallet */

Go
