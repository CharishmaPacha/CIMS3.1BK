/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/11/15  PK      pr_Picking_FindAllocableLPN: Added Warehouse to filter data based on Warehouse,
                      pr_Picking_FindLPN: changed the callers of pr_Picking_FindAllocableLPN to pass in Warehouse. 
  2012/06/29  AY      pr_Picking_UnitPickResponse: New procedure to stream line response.
                      pr_Picking_FindLPN: Enhanced to return LPNId so that there is no
                        ambiguity when picking from MultiSKU picklane
                      pr_Picking_ValidatePallet: Ensure we are picking to a picking Pallet.
  2012/06/21  YA      pr_Picking_FindLPN: Removed loehmanns specific code and added TD specific code.
  2011/10/10  SHR     pr_Picking_FindLPN: Fixed bug @OrderType -> @curOrderType
  2011/10/09  AY      pr_Picking_FindLPN: Changed to Pick E-Comm/Transfer Orders
  2011/09/26  PK      pr_Picking_FindLPN/pr_Picking_FindAllocableLPN: Modified to find LPN from both Bulk & Reserve.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_FindLPN') is not null
  drop Procedure pr_Picking_FindLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_FindLPN:

  This procedure is used to find allocable LPNs of the given SKU for the
  given OrderId.

  - @SearchType
    'F' - Default - Search for Allocable Full LPNs
    'P' - Search for Allocable LPNs to allocate Partially
  - Assumes Full LPNs are requested when QtyToAllocate is 0
  - if SKUId is null, then the procedure iterates through all lines of the PickTicket
    and returns the first allocable LPN
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_FindLPN
  (@OrderId         TRecordId,
   @PickZone        TLookUpCode,               /* TZoneId */
   @SearchType      TFlag        = 'F',        /* Refer to Notes above, for valid values and their usage */
   @SKU             TSKU         = null,
   @LPNToPick       TLPN         output,
   @LPNIdToPick     TRecordId    output,
   @LocToPick       TLocation    output,
   @SKUToPick       TSKU         output,
   @UnitsToPick     TInteger     output,
   @OrderDetailId   TRecordId    output)
as
  declare  @curValidPickTicket                      TPickTicket,
           @curOrderId                              TRecordId,
           @curOrderDetailId                        TRecordId,
           @curSKU                                  TSKU,
           @curUnitsAuthorizedToShip                TInteger,
           @curUnitsAssigned                        TInteger,
           @curUnitsToAssign                        TInteger,
           @curOrderType                            TOrderType,
           @curUDF1                                 TUDF,
           @curWarehouse                            TWarehouse;
begin /* pr_Picking_FindLPN */

  Create Table #ttAllocableLPNs
    (SKU                  varchar(50),
     Plant                varchar(20),
     Building             varchar(20),
     BatchNo              integer,
     Location             varchar(50),
     LocationType         varchar(10),
     PickZone             varchar(20),
     LPN                  varchar(50),
     SerialNumber         varchar(50),
     AllocableQuantity    integer,
     ReservedQuantity     integer
     );

  /* Iterate through all Pickable Lines of the Order or PickTicket */
  declare PTLinesToAllocate Cursor Local Forward_Only Static Read_Only
  For select PickTicket, OrderId, OrderDetailId, SKU, UnitsAuthorizedToShip,
             UnitsAssigned, UnitsToAllocate, OrderType, OH_UDF1, Warehouse
      from vwOrderDetailsToAllocate
      where (OrderId = @OrderId);

  Open PTLinesToAllocate;
  Fetch next from PTLinesToAllocate into @curValidPickTicket, @curOrderId,
                                         @curOrderDetailId, @curSKU,
                                         @curUnitsAuthorizedToShip,
                                         @curUnitsAssigned, @curUnitsToAssign,
                                         @curOrderType, @curUDF1, @curWarehouse;

  while (@@fetch_status = 0)
    begin
      /* When searching for Full LPNs, search Bulk/Reserve locations only,
         when searching for less than LPN quantity, first try to find the
         inventory in the Picklane. If there is none in the Picklane, then
         try to pick from an LPN in Bulk/Reserve */
      if (@SearchType = 'F' /* Full LPNs */)
        begin
          /* Find a Full LPN from Bulk/Reserve Locations */
          exec pr_Picking_FindAllocableLPN @curSKU, @SearchType, @curUnitsToAssign,
                                           @curOrderId, @PickZone, 'BR' /* Bulk/Reserve locations */,
                                           @curWarehouse, @LPNToPick output,
                                           @LPNIdToPick output, @LocToPick output,
                                           @SKUToPick output, @UnitsToPick output;
        end
      else
      if (@SearchType = 'P' /* Piece Quantity */)
        begin
          /* Find a Picklane to Pick from */
          if (@curUDF1 = 'PiecePicks') /* TD specific for now */
            exec pr_Picking_FindAllocableLPN @curSKU, @SearchType, @curUnitsToAssign,
                                             @curOrderId, @PickZone, 'K' /* Picklanes */,
                                             @curWarehouse, @LPNToPick output,
                                             @LPNIdToPick output, @LocToPick output,
                                             @SKUToPick output, @UnitsToPick output;

          /* If no inventory in Picklane, then try to pick from an LPN from Bulk */
          if (nullif(@LPNToPick, '') is null) and (@LocToPick is null) and (@curUDF1 <> 'PiecePicks' /* TD specific for now */)
            exec pr_Picking_FindAllocableLPN @curSKU, @SearchType, @curUnitsToAssign,
                                             @curOrderId, @PickZone, 'BR' /* Bulk/Reserve Locations */,
                                             @curWarehouse, @LPNToPick output,
                                             @LPNIdToPick output, @LocToPick output,
                                             @SKUToPick output, @UnitsToPick output;

        end

      /* Skip Other Lines, on finding the first LPN which can be picked */
      if (@LPNToPick is not null)
        begin
          select @OrderDetailId = @curOrderDetailId;
          goto FoundLPNToPick;
        end

      /*
        Caller will do the below

        Collect Information of LPN to pick
        return Details LPN to Pick along with Order Info */

      Fetch next from PTLinesToAllocate into @curValidPickTicket, @curOrderId,
                                             @curOrderDetailId, @curSKU,
                                             @curUnitsAuthorizedToShip,
                                             @curUnitsAssigned,
                                             @curUnitsToAssign,
                                             @curOrderType,
                                             @curUDF1,
                                             @curWarehouse;

    end /* while @@fetch_status... */

FoundLPNToPick:
  Close PTLinesToAllocate;
  Deallocate PTLinesToAllocate;

end /* pr_Picking_FindLPN */

Go
