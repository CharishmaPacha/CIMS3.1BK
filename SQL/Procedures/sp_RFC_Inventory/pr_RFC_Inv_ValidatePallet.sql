/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/12  TK      pr_RFC_Inv_ValidatePallet: Allow pallets movement between Warehouses (HA-GoLive)
  2021/03/09  SK      pr_RFC_Inv_ValidatePallet: temp fix to bypass invalid pallet status validation if pallet is empty but with LPNs (HA-2206)
  2020/12/11  RKC     pr_RFC_Inv_ValidatePallet: Added validation to not allow to build the pallets with different WH if is a non empty pallets (HA-1736)
  2020/03/18  MS      pr_RFC_Inv_ValidatePallet: Added InTransit PalletType as well to move the Pallets (JL-132)
  2019/05/03  YJ      pr_RFC_Inv_ValidatePallet: Changed to check to consider Status instead of PalletType Migrated from Prod (S2GCA-98)
  2016/06/30  PK      pr_RFC_Inv_ValidatePallet, pr_RFC_TransferInventory: Bug fix for incorrect Received # over the received PO (NBD-641)
  2014/02/26  NY      pr_RFC_Inv_ValidatePallet: Added control variables to handle pallet statuses.
  2013/12/11  PK      pr_RFC_Inv_ValidatePallet: Returning values from vwLPNDetails.
              AY      pr_RFC_Inv_ValidatePallet: Fixed statuses for Pallet move
  2012/10/04  YA      pr_RFC_Inv_ValidatePallet: Could not move Lost pallet - Fixed.
                      pr_RFC_Inv_ValidatePallet: Validate for Shipping pallet.
  2012/09/04  AY      pr_RFC_Inv_ValidatePallet: Changed input param to Operations
  2012/05/04  PK      pr_RFC_Inv_ValidatePallet: Received is also valid status
  2012/02/27  PKS     Updated XML structure at top of pr_RFC_Inv_ValidatePallet
                      Added procedures pr_RFC_Inv_ValidatePallet, pr_RFC_Inv_AddLPNToPallet,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Inv_ValidatePallet') is not null
  drop Procedure pr_RFC_Inv_ValidatePallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Inv_ValidatePallet:
  XML Structure:
  <PALLETDETAILS>
   <PALLETINFO xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
     <PalletId>188</PalletId>
     <Pallet>C024</Pallet>
     <NumLPNs>2</NumLPNs>
     <Status>E</Status>
     <PalletSKU>630128600010002</PalletSKU>
     <PalletSKUDesc>GABRIEL 30" ASYM CLOSE W/LTHR</PalletSKUDesc>
     <LocationId>430578</LocationId>
     <Location>R-1312-1-0101</Location>
     <OrderId>158</OrderId>
   </PALLETINFO>
   <LPNS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
     <LPNId>59251</LPNId>
     <LPN>C024-01</LPN>
     <LPNDetailId>001<LPNDetailId>
     <SKU>073804000010002</SKU>
     <SKU1>073804000</SKU1>
     <SKU2>010002</SKU2>
     <SKU3>01</SKU3>
     <SKU4>   S</SKU4>
     <SKU5>00</SKU5>
     <SKUDescription>PONTE ELEPHANT PUFF SLV DRS</SKUDescription>
     <InnerPacks>0</InnerPacks>
     <Quantity>0</Quantity>
   </LPNS>
   <LPNS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
     <LPNId>59252</LPNId>
     <LPN>C024-02</LPN>
     <SKU>073804000010003</SKU>
     <SKU1>073804000</SKU1>
     <SKU2>010003</SKU2>
     <SKU3>01</SKU3>
     <SKU4>   M</SKU4>
     <SKU5>00</SKU5>
     <SKUDescription>PONTE ELEPHANT PUFF SLV DRS</SKUDescription>
     <InnerPacks>0</InnerPacks>
     <Quantity>0</Quantity>
   </LPNS>
  </PALLETDETAILS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Inv_ValidatePallet
  (@Pallet       TPallet,
   @Operation    TDescription = null,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId,
   @DeviceId     TDeviceId,
   @xmlResult    xml       output)
as
  declare @ReturnCode                   TInteger,
          @MessageName                  TMessageName,
          @Message                      TDescription,

          @vPalletId                    TRecordId,
          @vPallet                      TPallet,
          @vNumLPNs                     TCount,
          @vQuantity                    TInteger,
          @vStatus                      TStatus,
          @vPalletType                  TTypeCode,
          @vPalletSKU                   TSKU,
          @vPalletSKUDesc               TDescription,
          @vPalletOrderId               TRecordId,
          @vLocationId                  TRecordId,
          @vLocation                    TLocation,
          @vSKUId                       TRecordId,
          @vWarehouse                   TWarehouse,
          @vUserLogInWarehouse          TWarehouse,
          @xmlPallet                    TXML,
          @xmlLPNs                      TXML,
          @xmlResultvar                 TXML,
          @vMoveValidStatus             TCategory,
          @vTransferValidStatus         TCategory,
          @vTransferInvalidStatus       TCategory,
          @vAllowMoveBetweenWarehouses  TControlValue;
begin
begin try
begin transaction

  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null;

  /* B:Built, R:Received, P:Putaway, A:Allocated, P:Picked, SG:Staged, L:Loaded, O:Lost, T: InTransit */
  select @vMoveValidStatus            = dbo.fn_Controls_GetAsString('MovePallet', 'ValidPalletStatuses', 'B,R,P,A,K,SG,L,O,T', @BusinessUnit, @UserId),
         @vTransferValidStatus        = dbo.fn_Controls_GetAsString('TransferPallet_ValidStatus', 'ValidPalletStatuses', '' /*  */, @BusinessUnit, @UserId),
         @vTransferInValidStatus      = dbo.fn_Controls_GetAsString('TransferPallet_InvalidStatus', 'InvalidPalletStatuses', '' /*  */, @BusinessUnit, @UserId),
         @vAllowMoveBetweenWarehouses = dbo.fn_Controls_GetAsString('Inventory', 'MoveBetweenWarehouses', 'Y' /* Yes */, @BusinessUnit, @UserId);

  /* Get Pallet Info */
  select @vPalletId      = PalletId,
         @vPallet        = Pallet,
         @vNumLPNs       = NumLPNs,
         @vQuantity      = Quantity,
         @vStatus        = Status,
         @vPalletType    = PalletType,
         @vLocationId    = LocationId,
         @vLocation      = Location,
         @vSKUId         = SKUId,
         @vPalletSKU     = SKU,
         @vPalletSKUDesc = SKUDescription,
         @vPalletOrderId = OrderId,
         @vWarehouse     = Warehouse
  from vwPallets
  where (PalletId = dbo.fn_Pallets_GetPalletId (@Pallet, @BusinessUnit));

  /* Get the User Log in Warehouse from the Devices table */
  select @vUserLogInWarehouse  = Warehouse
  from Devices
  where DeviceId = @DeviceId + '@' + @UserId;;

  /* Checking pallet is exist or not. */
  if (@vPalletId is null)
    set @MessageName = 'PalletIsInvalid'
  else
  -- temp fix: HAGoLive: bypass this validation if pallet is empty but has LPNs on it
  if ((@Operation = 'MovePallet') and
      (((dbo.fn_IsInList(@vStatus, @vMoveValidStatus) = 0) and (@vStatus <> 'E' /* Empty */)) or
       ((dbo.fn_IsInList(@vStatus, @vMoveValidStatus) = 0) and (@vStatus = 'E' /* Empty */) and (@vNumLPNs = 0))))
    set @MessageName = 'PalletStatusInvalid';
  else
  /* Check whether pallet is Empty / Putaway / Built */
  if (coalesce(@Operation, '') not in ('MovePallet', 'TransferPallet')) and
     (@vStatus not in ('B' /* Built */,
                       'R' /* Received */,
                       'P' /* Putaway */,
                       'A' /* Allocated */,
                       'C' /* Picking */,
                       'K' /* Picked */,
                       'SG' /* Staged */,
                       'E' /* Empty */))
    set @MessageName = 'PalletStatusInvalid';
  else
  if (@vStatus in ('S'/* Shipped */))
    set @MessageName = 'PalletAlreadyShipped';
  else
  if (@Operation = 'MovePallet') and
     ((@vNumLPNs = 0) or (@vQuantity = 0))
    set @MessageName = 'CannotMoveEmptyPallet';
  else
  if (@Operation = 'TransferPallet') and
     ((@vNumLPNs = 0) or (@vQuantity = 0))
    set @MessageName = 'CannotTransferEmptyPallet';
  else
  if (@vWarehouse <> @vUserLogInWarehouse) and
     (@vAllowMoveBetweenWarehouses <> 'Y') and
     (@vStatus <> 'E' /* Empty*/)
    set @MessageName = 'Pallet_LoginWarehouseMismatch'

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Build xml of Pallet details */
  set @xmlPallet = (select @vPalletId                    as PalletId,
                           @vPallet                      as Pallet,
                           @vNumLPNs                     as NumLPNs,
                           @vStatus                      as Status,
                           @vPalletSKU                   as PalletSKU,
                           @vPalletSKUDesc               as PalletSKUDesc,
                           @vLocationId                  as LocationId,
                           @vLocation                    as Location,
                           @vPalletOrderId               as OrderId
                    for xml raw('PALLETINFO'), elements xsinil);

  /* Build xml of LPNs on the Pallet */
  set @xmlLPNs = (select LPNId, LPN, LPNDetailId,
                         SKU, SKU1, SKU2, SKU3, UPC as SKU4, SKU5,
                         SKUDescription, InnerPacks, Quantity
                  from vwLPNDetails
                  where (PalletId = @vPalletId)
                  for xml raw('LPNS'), elements xsinil);

  set @xmlResult = '<PALLETDETAILS>' +
                    coalesce(@xmlPallet, '') +
                    coalesce(@xmlLPNs,   '') +
                   '</PALLETDETAILS>';

  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'ValidatePallet', @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;
end catch;
end /* pr_RFC_Inv_ValidatePallet */

Go
