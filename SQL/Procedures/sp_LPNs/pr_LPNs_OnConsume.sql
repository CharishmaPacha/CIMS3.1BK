/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/04  SK      pr_LPNs_OnConsume: Update to tackle different operatiLPN when consumed.
  2019/05/06  TK      pr_LPNs_OnConsume: Clear Load Number on LPN (S2GCA-GoLive)
  2017/10/12  TK      pr_LPNs_OnConsume: On Consume clear Dest Location on the LPN (HPI-1512)
  2015/11/30  SV      pr_LPNs_OnConsume: Restricting for recounting the LPNs over the respective Loads and Shipments if the LoadId/ShimentId is 0 (CIMS-699)
  2013/12/21  AY      pr_LPNs_OnConsume: New procedure to clear info on LPN when consumed
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_OnConsume') is not null
  drop Procedure pr_LPNs_OnConsume;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_OnConsume: If an LPN is consumed, then based upon the situation
    it was consumed in, there may be several relevant updates to do. This procedure
    is expected to all of that.

  As of now, it only is used for an LPN that is consumed when on a Load/Shipment
  due to consolidation of Pallets.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_OnConsume
  (@LPNId        TRecordId,
   @OrderId      TRecordId      = null,
   @ShipmentId   TShipmentId    = null,
   @LoadId       TLoadId        = null,
   @Operation    TOperation     = null,
   @BusinessUnit TBusinessUnit  = null,
   @UserId       TUserId        = null)
as
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vMessage                   TDescription,
          @vBusinessUnit              TBusinessUnit,

          @vDestLocation              TLocation,
          @vShipmentId                TShipmentId,
          @vLoadId                    TLoadId,
          @vLocationId                TRecordId,
          @vLocation                  TLocation;

begin /* pr_LPNs_OnConsume */
  select  @vMessageName = null,
          @vReturnCode  = 0;

  /* Validations */
  if (@LPNId is null)
    select @vMessageName = 'NoLPNProvided'

  if (@vMessageName is not null)
    goto ErrorHandler;

  update LPNs
  set @vShipmentId   = coalesce(nullif(ShipmentId, 0), nullif(@ShipmentId, 0)),
      @vLoadId       = coalesce(nullif(LoadId,     0), nullif(@LoadId, 0)),
      @vLocationId   = nullif(LocationId, 0),
      @vLocation     = nullif(Location, ''),
      @vBusinessUnit = coalesce(@BusinessUnit, BusinessUnit),
      @vDestLocation = DestLocation,
      ShipmentId     = 0,
      LoadId         = 0,
      LoadNumber     = null,
      --ReceiptId      = 0,
      --ReceiptNumber  = null,
      PackageSeqNo   = 0,
      TrackingNo     = null,
      Location       = null,
      LocationId     = null
  where (LPNId = @LPNId);

  if (@vLocationId is not null)
    exec pr_Locations_UpdateCount @LocationId   = @vLocationId, @Location = @vLocation,
                                  @UpdateOption = '$' /* defered counts */, @ProcId = @@ProcId;

  if (@vShipmentId is not null)
    exec pr_Shipment_Recount @vShipmentId;

  if (@vLoadId is not null)
    exec pr_Load_Recount @vLoadId;

  /* Clear Destination on LPN */
  if (@vDestLocation is not null)
    exec pr_LPNs_SetDestination @LPNId, 'ClearDestination' /* Operation */;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_OnConsume */

Go
