/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/15  TK      pr_API_6River_Inbound_PickTaskPicked & pr_API_6River_Inbound_ContainerTakenOff: Fixed issues faced during integration testing
  2020/11/28  TK      pr_API_6River_Inbound_ContainerTakenOff: Initial Revision (CID-1565)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_6River_Inbound_ContainerTakenOff') is not null
  drop Procedure pr_API_6River_Inbound_ContainerTakenOff;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_6River_Inbound_ContainerTakenOff: When a container has been dropped at any location,
    we would get an message from 6River stating that the container is taken off the chuck
    with the drop location info. This procedures unloads the container from the pallet/chuck and
    drops the ship carton or tote into drop location specified
------------------------------------------------------------------------------*/
Create Procedure pr_API_6River_Inbound_ContainerTakenOff
  (@TransactionRecordId   TRecordId)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vRawInput               TVarchar,

          @vOrderId                TRecordId,
          @vPickTicket             TPickTicket,

          @vLPNId                  TRecordId,
          @vLPN                    TLPN,
          @vLPNType                TTypeCode,

          @vPalletId               TRecordId,
          @vPallet                 TPallet,

          @vDropLocationId         TRecordId,
          @vDropLocation           TLocation,

          @vBusinessUnit           TBusinessUnit,
          @vUserId                 TUserId;
begin /* pr_API_6River_Inbound_ContainerTakenOff */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Transaction Info */
  select @vRawInput     = RawInput,
         @vBusinessUnit = BusinessUnit
  from APIInboundTransactions
  where (RecordId = @TransactionRecordId);

  /* Read input JSON data & extract necessary info */
  select @vDropLocation = json_value(@vRawInput, '$.takeoff.destination.name'),
         @vPickTicket   = json_value(@vRawInput, '$.groupID'),
         @vLPN          = json_value(@vRawInput, '$.container.containerID'),
         @vPallet       = json_value(@vRawInput, '$.takeoff.deviceID'),
         @vUserId       = json_value(@vRawInput, '$.takeoff.userID');

  /* Get Pick Ticket info */
  select @vOrderId = OrderId
  from OrderHeaders
  where (PickTicket   = @vPickTicket  ) and
        (BusinessUnit = @vBusinessUnit);

  /* Get LPN info */
  select @vLPNId   = LPNId,
         @vLPNType = LPNType
  from LPNs
  where (LPN          = @vLPN         ) and
        (BusinessUnit = @vBusinessUnit);

  /* Get Drop Location info */
  select @vDropLocationId = LocationId
  from Locations
  where (Location     = @vDropLocation) and
        (BusinessUnit = @vBusinessUnit);

  /* Validations */
  if (@vLPN is null)
    set @vMessageName = 'LPNIsRequired';
  else
  if (@vLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (@vDropLocation is null)
    set @vMessageName = 'LocationIsRequired';
  else
  if (@vDropLocationId is null)
    set @vMessageName = 'LocationDoesNotExist';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Unload ship carton or tote from pallet */
  exec pr_LPNs_SetPallet @vLPNId, null /* PalletId */, @vUserId, 'ContainerTakenOff';

  /* Set drop location on ship carton or tote */
  exec pr_LPNs_SetLocation @vLPNId, @vDropLocationId;

  /* Update LPN Status as picked
     For PTC & SLB waves inventory will be picked into cartons so mark them as picked
     but for PTS inventory will be picked into cubed cartons mark it as picked only if all the details are reserved */
  if not exists (select * from LPNDetails where LPNId = @vLPNId and OnhandStatus = 'U' /* Unavailable */)
    update L
    set Status = 'K' /* Picked */
    from LPNs L
    where (L.LPNId = @vLPNId);

  /* Log Audit Trail */
  exec pr_AuditTrail_Insert 'LPNDropped', @vUserId, null /* ActivityTimestamp */,
                            @LPNId      = @vLPNId,
                            @PalletId   = @vPalletId,
                            @LocationId = @vDropLocationId,
                            @OrderId    = @vOrderId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_6River_Inbound_ContainerTakenOff */

Go
