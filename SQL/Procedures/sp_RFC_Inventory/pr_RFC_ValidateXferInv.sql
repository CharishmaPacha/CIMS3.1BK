/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ValidateXferInv') is not null
  drop Procedure pr_RFC_ValidateXferInv;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ValidateXferInv:
    Validate From and ToEntity and returns the view to the RF.

  <ValidateXferInv>
    <FromEntity></FromEntity>
    <ToEntity></ToEntity>
    <Operation></Operation>
    <BusinessUnit></BusinessUnit>
    <DeviceId></DeviceId>
    <UserId></UserId>
  </ValidateXferInv>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ValidateXferInv
  (@xmlInput  XML)
as
  /* I/P Variable declaration */
  declare @vFromEntity    TEntity,
          @vToEntity      TEntity,
          @vOperation     TOperation,
          @vBusinessUnit  TBusinessUnit,
          @vDeviceId      TDeviceId,
          @vUserId        TUserId;

  /* From Entity info */
  declare @vReturnCode          TInteger,
          @vFromLocationId      TRecordId,
          @vFromLocation        TLocation,
          @vFromLocationType    TlocationType,
          @vFromLocationStatus  TStatus,
          @vFromLPNId           TRecordId,
          @vFromLPN             TLPN,
          @vFromLPNType         TTypeCode,
          @vFromLPNStatus       TStatus,
          @vFromLPNQty          TQuantity,
          @vFromLPNLocId        TRecordId,
          @vFromLPNLoc          TLocation,
          @vValidateFromEntityId
                                TRecordId,
          @vValidateFromEntity  TLocation,
          @UserId               TUserId,
          @vFromLPNOnhandStatus TStatus;


  /* To Entity info */
  declare @vToLocationId        TRecordId,
          @vToLocation          TLocation,
          @vToLocationType      TlocationType,
          @vToLocationStatus    TStatus,
          @vToLPNId             TRecordId,
          @vToLPN               TLPN,
          @vToLPNType           TTypeCode,
          @vToLPNStatus         TStatus,
          @vToLPNQty            TQuantity,
          @vToLPNLocId          TRecordId,
          @vToLPNLoc            TLocation,
          @vValidateToEntityId  TRecordId,
          @vValidateToEntity    TLocation,
          @vToLPNOnhandStatus   TStatus,
          @vTransferSKUId       TRecordId,
          @vFromLocQty          TQuantity,
          @xmlInputvar          Txml,
          @vActivityLogId       TRecordId;


  /* Internal Variable declaration */
  declare @vSource                     TEntity,
          @vDestination                TEntity,
          @vMessageName                TMessageName,
          @vAllowMoveBetweenWarehouses TControlValue,
          @vInvalidFromLPNStatuses     TControlValue,
          @vInvalidToLPNStatuses       TControlValue,
          @BusinessUnit                TBusinessUnit = (select BusinessUnit from vwBusinessUnits);
begin
begin try
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode = 0;

  /* Read values from input xml */
  select @vFromEntity   = Record.Col.value('FromEntity[1]',   'TEntity'),
         @vToEntity     = Record.Col.value('ToEntity[1]',     'TEntity'),
         @vOperation    = Record.Col.value('Operation[1]',    'TOperation'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
         @vDeviceId     = Record.Col.value('DeviceId[1]',     'TDeviceId'),
         @vUserId       = Record.Col.value('UserId[1]',       'TUserId')
  from @XmlInput.nodes('ValidateXferInv') as Record(Col);

  /* convert input TXML to XML */
  select @xmlInputvar = convert(varchar(max), @xmlInput);

  /* Get the control variables */
  select @vAllowMoveBetweenWarehouses = dbo.fn_Controls_GetAsString('Inventory', 'MoveBetweenWarehouses', 'N' /* No */,
                                                                    @vBusinessUnit, @vUserId),
         @vInvalidFromLPNStatuses     = dbo.fn_Controls_GetAsString('TransferInventory', 'InvalidFromLPNStatuses', 'CFISTOV' /* Consumed, New Temp, Inactive, Shipped, In Transit, Lost, Voided */,
                                                                    @vBusinessUnit, @vUserId),
         @vInvalidToLPNStatuses       = dbo.fn_Controls_GetAsString('TransferInventory', 'InvalidToLPNStatuses', 'CISTOV' /* Consumed, Inactive, Shipped, In Transit, Lost, Voided */,
                                                                    @vBusinessUnit, @vUserId);

  /* Identify From and To entities */

  /* Identify the source */
  exec pr_LPNs_IdentifyLPNOrLocation @vFromEntity, @vBusinessUnit, @vUserId,
                                     @vSource out, @vFromLPNId out, @vFromLPN out,
                                     @vFromLocationId out, @vFromLocation out;

  /* Identify the destination */
  exec pr_LPNs_IdentifyLPNOrLocation @vToEntity, @vBusinessUnit, @vUserId,
                                     @vDestination out, @vToLPNId out, @vToLPN out,
                                     @vToLocationId out, @vToLocation out;

  /* If source is Location, get From Location info */
  if (@vFromLocationId is not null)
    select @vFromLocationType   = LocationType,
           @vFromLocationStatus = Status,
           @vFromLocQty         = Quantity
    from Locations
    where (LocationId = @vFromLocationId);

  /* If source is LPN, get From LPN info */
  if (@vFromLPNId is null)
    select @vFromLPNType         = LPNType,
           @vFromLPNStatus       = Status,
           @vFromLPNQty          = Quantity,
           @vFromLPNLocId        = LocationId,
           @vFromLPNLoc          = Location,
           @vFromLPNOnhandStatus = OnhandStatus
    from LPNs
    where (LPN = @vFromLPNId);

  select @vValidateFromEntityId = coalesce(@vFromLocationId, @vFromLPNId),
         @vValidateFromEntity   = coalesce(@vFromLocation, @vFromLPN);

  /* If Destination is Location, get Location info */
  if (@vToLocationId is not null)
    select @vToLocationType   = LocationType,
           @vToLocationStatus = Status
    from Locations
    where (Location = @vToLocationId);

  /* If Destination is LPN, get LPN info */
  if (@vToLPNId is not null)
    select @vToLPNType         = LPNType,
           @vToLPNStatus       = Status,
           @vToLPNQty          = Quantity,
           @vToLPNLocId        = LocationId,
           @vToLPNLoc          = Location,
           @vToLPNOnhandStatus = OnhandStatus,
           @vTransferSKUId     = coalesce(skuid,'')
    from LPNs
    where (LPN = @vToLPNId);

  select @vValidateToEntityId = coalesce(@vTolocationId, @vToLPNId),
         @vValidateToEntity   = coalesce(@vToLocation, @vToLPN);

  /* Validations */

  if ((@vSource is null) or (@vDestination is null))
    set @vMessageName = 'InvalidParameters'
  else

  /* If the FromLPN is not null then it validates FromLPN and TransferSKU */
  if (@vSource = 'LPN')
    begin
      if (@vFromLPNId is null)
        set @vMessageName = 'FromLPNDoesNotExist';
      else
      if (charindex(@vFromLPNStatus, @vInvalidFromLPNStatuses) > 0)
        set @vMessageName = 'TransferInv_LPNFromStatusIsInvalid';
      else
      if (@vFromLPNOnhandStatus = 'U' /* Unavailable */ and @vFromLPNStatus <> 'R' /* Received */)
        set @vMessageName = 'TransferInv_FromLPNUnavailable';
      else
      if (@vFromLPNQty = 0)
        set @vMessageName = 'NoInventoryToTransferFromLPN'
      else
      if (not exists(select *
                     from LPNDetails
                     where (SKUId        = @vTransferSKUId) and
                           (LPNId        = @vFromLPNId) and
                           (BusinessUnit = @BusinessUnit)))
         set @vMessageName = 'SKUDoesNotExistInLPN';

      if (@vSource = 'LOC')
        /* @Source = 'Location' */
      if (@vFromLocationId is null)
        set @vMessageName = 'FromLocationDoesNotExist';
      else
      if (@vFromLocationType <> 'K' /* Picklane */)
        set @vMessageName = 'CannotTransferFromNonPicklaneLoc';
      else
      if (@vFromLocQty <= 0)
        set @vMessageName = 'NoInventoryToTransferFromLoc'
      else
      if(not exists(select *
                    from vwLPNs
                    where (SKUId        = @vTransferSKUId) and
                          (LocationId   = @vFromLocationId) and
                          (BusinessUnit = @BusinessUnit)))
        set @vMessageName = 'SKUDoesNotExistInLocation';
    end

  if (@vMessageName is not null)
    goto ErrorHandler;

  if (@vDestination = 'LPN')
    begin
      if (@vToLPNId is null)
        set @vMessageName = 'ToLPNDoesNotExist';
      else
      if (@vToLPNType = 'L'/* Logical */)
        set @vMessageName = 'LPNTypeIsInvalid';
      else
      if (@vFromLPNId = @vToLPNId)
        set @vMessageName  = 'CannotTransferInventoryToSameLPN';
      else
      if (charindex(@vToLPNStatus, @vInValidToLPNStatuses) > 0)
        set @vMessageName = 'TransferInv_LPNToStatusIsInvalid';
      else
      if (@vToLPNOnhandStatus = 'U' /* Unavailable */) and (@vToLPNStatus <> 'N' /* New */)
        set @vMessageName = 'TransferInv_ToLPNUnavailable';

      if (@vDestination = 'LOC') /* @Destination = 'Location' */
        begin
      if (@vToLocationId is null)
        set @vMessageName = 'ToLocationDoesNotExist';
      else
      if (@vToLocationType <> 'K'/* PickLane */)
        set @vMessageName = 'SKUCanTransferIfLocTypeIsPickLane';
      else
      if (@vFromLocationId = @vToLocationId) --and (@vSource = 'LOC')
        set @vMessageName = 'CannotTransferInventoryToSameLocation';
        end
    end

  if (@vMessageName is not null)
    goto ErrorHandler;

declare @xmlFromLoc XML,@xmlInputvarLoc Txml;

set @xmlFromLoc = '<ValidateLocation>
                   <LocationId></LocationId>
                   <Location>@vFromLocation</Location>
                   <SKU>null</SKU>
                   <Operation></Operation>
                   <BusinessUnit>S2G</BusinessUnit>
                   <DeviceId>@vDeviceId</DeviceId>
                   <UserId></UserId>
                   <Warehouse></Warehouse>
                   </ValidateLocation>';

  /* convert input XML to TXML */
  select @xmlInputvarLoc = convert(varchar(max),@xmlFromLoc);

  /* The following call will validation the scanned FroEntity and returns the O/P */
  if (@vSource = 'LPN')
    /* Validate LPN */
    exec pr_RFC_ValidateLPN @vFromLPNId, @vFromLPN, @vOperation, @BusinessUnit, @UserId;
  else
    /* Validate Location */
    exec pr_RFC_ValidateLocation @xmlInputvarLoc;

  /* The following call will validation the scanned ToEntity and returns the O/P */
  if (@vDestination = 'LPN')
    /* Validate LPN */
    exec pr_RFC_ValidateLPN @vToLPNId, @vToLPN, @vOperation, @BusinessUnit, @UserId;
  else
    /* Validate Location */
    exec pr_RFC_ValidateLocation @xmlInputvarLoc;

  if (@vMessageName is not null)
    goto ErrorHandler;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

end try
begin catch
  exec @vReturnCode = pr_ReRaiseError;

end catch;

  return(@vReturnCode);
end /* pr_RFC_ValidateXferInv */

Go
