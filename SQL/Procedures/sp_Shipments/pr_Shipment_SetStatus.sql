/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/03  TK      pr_Shipment_SetStatus & pr_Shipment_MarkAsShipped: Code revamp (HA-1842)
  2020/14/24  TK      pr_Shipment_SetStatus: Removed code related to Transfer order shipping (HA-1830)
  2020/11/22  AY      pr_Shipment_SetStatus: Consider Shipment status of Loading (HA-1710)
  2020/08/25  OK      pr_Shipment_SetStatus: Bug fix to update the shipment status properly for Transfer orders (HA-1350)
  2020/06/16  RV      pr_Shipment_SetStatus: Consider In transit LPNs to mark shipment as shipped for Transfer shipments (HA-964)
  2012/10/06  TD      pr_Shipment_SetStatus: Calling pr_Load_SetStatus proc to update Load Status
  2012/08/28  PK      pr_Shipment_SetStatus: Moved the code of setting initial status
  2012/08/27  VM      pr_Shipment_SetStatus: Corrected code of LPN staged status
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipment_SetStatus') is not null
  drop Procedure pr_Shipment_SetStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipment_SetStatus:
    This procedure is used to change/set the 'Status' of the Shipment.

    Status:
     . If status is provided, it updates directly with the given status
     . If status is not provided - it calculates the status updates.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipment_SetStatus
  (@ShipmentId   TShipmentId,
   @Status       TStatus = null output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          /* vars for counts */
          @vInTransitLPNs     TCount,
          @vStagedLPNs        TCount,
          @vLoadedLPNs        TCount,
          @vTotalLPNs         TCount,
          @vShippedLPNs       TCount;
begin  /* pr_Shipment_SetStatus */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vLoadedLPNs    = 0,
         @vTotalLPNs     = 0,
         @vShippedLPNs   = 0;

  if (@Status is null)
    begin
      /* Consider Packed LPNs as Staged */
      select @vInTransitLPNs = sum(case when (Status = 'T' /* In Transit */ ) then 1 else 0 end),
             @vStagedLPNs    = sum(case when (Status in ('D' /* Packed */, 'E' /* Staged */ )) then 1 else 0 end),
             @vLoadedLPNs    = sum(case when (Status = 'L' /* Loaded */ ) then 1 else 0 end),
             @vShippedLPNs   = sum(case when (Status = 'S' /* Shipped */) then 1 else 0 end),
             @vTotalLPNs     = count(*)
      from LPNs
      where (ShipmentId = @ShipmentId);

      set @Status = case
                      when (@vShippedLPNs > 0) and
                           (@vShippedLPNs = @vTotalLPNs) then
                           'S' /* Shipped */
                      when (@vLoadedLPNs > 0) and
                           (@vLoadedLPNs = @vTotalLPNs) then
                           'L' /* Loaded */
                      when (@vLoadedLPNs > 0) and
                           (@vLoadedLPNs < @vTotalLPNs) then
                           'M' /* Loading */
                      when (@vStagedLPNs > 0) and
                           (@vStagedLPNs = @vTotalLPNs) then
                           'G' /* Staged */
                      when (@vStagedLPNs > 0) and
                           (@vStagedLPNs < @vTotalLPNs) then
                           'A' /* Staging */
                      when (@vTotalLPNs > 0) then
                           'I' /* Initial */
                      when (@vTotalLPNs = 0) then
                           'N' /* New */
                    end
    end

  if (@Status is not null)
    update Shipments
    set Status       = @Status,
        ShippedDate  = case when @Status = 'S' /* Shipped */ then current_timestamp else null end,
        ModifiedDate = current_timestamp,
        ModifiedBy   = System_User
    where (ShipmentId = @ShipmentId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipment_SetStatus */

Go
