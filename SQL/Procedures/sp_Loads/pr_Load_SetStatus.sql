/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/22  AY      pr_Load_SetStatus: Consider Shipment status of Loading (HA-1710)
  pr_Load_SetStatus: Load status is 'New' only when NumOrders & NumLPNs on Load are zero
  2012/08/28  VM      pr_Load_SetStatus: Corrrected LPNs 'Staged' status code
  2012/08/28  VM      pr_Load_SetStatus: Corrrected LPNs 'Staged' status code,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_SetStatus') is not null
  drop Procedure pr_Load_SetStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_SetStatus:
    This procedure is used to change/set the 'Status' of the Load. At present
      the procedure not implemented completely.

    Status:
     . If status is provided, it updates directly with the given status
     . If status is not provided - it calculates the status updates.
------------------------------------------------------------------------------*/
Create Procedure pr_Load_SetStatus
  (@LoadId      TLoadId,
   @Status      TStatus = null output)
as
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName,
          /* Count Vars */
          @vStagedShipments   TCount,
          @vLoadedShipments   TCount,
          @vShippedShipments  TCount,
          @vStagedLPNs        TCount,
          @vLoadedLPNs        TCount,
          @vTotalLPNs         TCount,
          @vTotalShipments    TCount,
          @vLoadOrders        TCount;
begin  /* pr_Load_SetStatus */
  SET NOCOUNT ON;

  select @ReturnCode         = 0,
         @MessageName        = null,
         @vStagedShipments   = 0,
         @vLoadedShipments   = 0,
         @vStagedLPNs        = 0,
         @vLoadedLPNs        = 0,
         @vTotalShipments    = 0,
         @vTotalLPNs         = 0,
         @vLoadOrders        = 0;

  if (@Status is null)
    begin
      /*
      set Status as New - By default load will create with New Status
      set Status as Inprogress  - if there at least one  shipment in the process of picking/packing and not fully completed
      set Status as ReadyToLoad - if all the Shipments are in Picked Status, No LPNs are Loaded yet
      set Status as Loading  - if at least one LPN is Loaded, and all the Shipments are Picked/Packed/Ready For Loading
      set Status as ReadyToShip - if all the shipments are in Loaded Status then mark as ReadyToShip
      set Status as Shipped - Load is confirmed as Shipped
      */

      /* Get the count of orders on the shipment which are in various  status */
      select @vStagedShipments  = sum(case when (Status in ('G', 'M' /* Staged  */)) then 1 else 0 end),
             @vLoadedShipments  = sum(case when (Status = 'L' /* Loaded  */) then 1 else 0 end),
             @vShippedShipments = sum(case when (Status = 'S' /* Shipped */) then 1 else 0 end),
             @vTotalShipments   = count(*)
      from Shipments
      where (LoadId = @LoadId);

      /* Get the #of order on load.If the count is 0 then status needs to be set as New.*/
      select @vLoadOrders  = NumOrders
      from Loads
      where (LoadId = @LoadId);

      select @vStagedLPNs  = sum(case when (Status = 'E' /* Staged */ ) then 1 else 0 end),
             @vLoadedLPNs  = sum(case when (Status = 'L' /* Loaded */ ) then 1 else 0 end),
             @vTotalLPNs   = count(*)
      from LPNs
      where (LoadId = @LoadId);

      set @Status =  Case
                       when (coalesce(@vLoadOrders, 0) = 0) and (coalesce(@vTotalLPNs, 0) = 0)  then
                         'N' /* New */
                       when (@vShippedShipments > 0) and
                            (@vShippedShipments = @vTotalShipments) then
                         'S' /* Shipped */
                       when (@vLoadedShipments > 0) and
                            (@vLoadedShipments  = @vTotalShipments) then
                         'L' /* Ready To Ship */
                       when (@vStagedShipments  > 0) and
                            (@vLoadedLPNs       > 0) and
                            (@vStagedShipments  = @vTotalShipments) then
                         'M' /* Loading */
                       when (@vStagedShipments  > 0) and
                            (@vLoadedLPNs       = 0) and
                            (@vStagedShipments  = @vTotalShipments) then
                         'R' /* Ready To Load */
                       else
                         'I' /* Inprocess */
                     end
    end

  if (@Status is not null)
    update Loads
    set Status       = coalesce(@Status, Status),
        ModifiedDate = current_timestamp,
        ModifiedBy   = System_User
    where (LoadId = @LoadId);

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Load_SetStatus */

Go
