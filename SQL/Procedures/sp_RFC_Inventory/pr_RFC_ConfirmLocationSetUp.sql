/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/07/25  KL      pr_RFC_ConfirmLocationSetUp: Allow Min/Max Replenish Qty to zero (HPI-1610)
  2014/05/25  TD      pr_RFC_ConfirmLocationSetUp: Added Procedure.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ConfirmLocationSetUp') is not null
  drop Procedure pr_RFC_ConfirmLocationSetUp;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ConfirmLocationSetUp: This procedure will update Location Min and
      Max levels. This procedure will take xml as input.

  Input:
<?xml version="1.0" encoding="utf-8"?>
<ConfirmLocationSetUp xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <SKU>00120840</SKU>
  <Location>P01-002-1</Location>
  <MinimumQuantity>1</MinimumQuantity>
  <MaximumQuantity>6</MaximumQuantity>
  <ReplenishUoM>CS</ReplenishUoM>
  <Warehouse>PGH</Warehouse>
  <BusinessUnit>GNC</BusinessUnit>
  <UserId>teja</UserId>
  <DeviceId>Pocket_PC</DeviceId>
</ConfirmLocationSetUp>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ConfirmLocationSetUp
  (@xmlInput   xml,
   @xmlResult  xml output)
as
  declare @vLocationId     TRecordId,
          @vLocation       TLocation,
          @vLocationtype   TTypeCode,
          @vLocStorageType TTypeCode,
          @vLocMinQty      TQuantity,
          @vLocMaxQty      TQuantity,
          @vReplenishUoM   TUoM,

          @vWarehouse      TWarehouse,
          @vBusinessUnit   TBusinessUnit,
          @vDeviceId       TDeviceId,
          @vUserId         TUserId,

          @vOperation      TDescription,
          @vNote1          TDescription,
          @vAuditComment   TVarChar,
          @MessageName     TMessageName,
          @ReturnCode      TInteger,
          @vActivityLogId TRecordId;
begin /* pr_RFC_ConfirmLocationSetUp */
begin try
  SET NOCOUNT ON;

  /* Get the Input params */
  select @vLocation       = Record.Col.value('Location[1]', 'TLocation'),
         @vLocMinQty      = Record.Col.value('MinimumQuantity[1]', 'TQuantity'),
         @vLocMaxQty      = Record.Col.value('MaximumQuantity[1]', 'TQuantity'),
         @vReplenishUoM   = Record.Col.value('ReplenishUoM[1]', 'TUoM'),
         @vWarehouse      = Record.Col.value('Warehouse[1]',    'TWarehouse'),
         @vBusinessUnit   = Record.Col.value('BusinessUnit[1]', 'TLPN'),
         @vDeviceId       = Record.Col.value('DeviceId[1]', 'TDeviceId'),
         @vUserId         = Record.Col.value('UserId[1]', 'TUserId')
  from @xmlInput.nodes('/ConfirmLocationSetUp') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      @vLocationId, @vLocation, 'Location',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get the Location Info */
  select @vLocationId     = LocationId,
         @vLocationtype   = LocationType,
         @vLocStorageType = StorageType
  from Locations
  where (Location     = @vLocation    ) and
        (Warehouse    = @vWarehouse   ) and
        (BusinessUnit = @vBusinessUnit);

  /* Validations */
  if (@vLocationId is null)
    set @MessageName = 'InvalidLocation';
  else
  if (coalesce(@vLocMinQty, 0) < 0)
    set @MessageName = 'LocMinQtyShouldbegrtZero';
  else
  if (coalesce(@vLocMaxQty, 0) <= 0)
    set @MessageName = 'LocMaxQtyShouldbegrtZero';
  else
  if (coalesce(@vLocMaxQty, 0) < coalesce(@vLocMinQty, 0))
    set @MessageName = 'LocMaxQtyShouldbegrtMin';
  else
  if ((@vLocStorageType = 'P'/* Cases */) and (@vReplenishUoM = 'EA' /* Eaches */))
    set @MessageName = 'LocReplenishUOMShouldbegrtCS';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Update Location */
  update Locations
  set MinReplenishLevel = @vLocMinQty,
      MaxReplenishLevel = @vLocMaxQty,
      ReplenishUoM      = @vReplenishUoM
  where (LocationId = @vLocationId);

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'LocationSetUpSuccessful', @vUserId, null /* ActivityTimestamp */,
                            @LocationId = @vLocationId,
                            @Comment = @vAuditComment output;

  exec pr_BuildRFSuccessXML @vAuditComment, @xmlResult output;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName, @vNote1;

  /* Log the Result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the Error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_ConfirmLocationSetUp */

Go
