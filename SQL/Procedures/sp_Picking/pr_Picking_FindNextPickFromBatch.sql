/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/31  RIA     pr_Picking_FindNextPickFromBatch: Made changes to consider PickSequence (OB2-796)
  2015/05/08  TK      pr_Picking_FindNextPickFromBatch: Look for the available inventory and suggest LPN and Location if the
  2014/08/23  VM      pr_Picking_FindNextPickFromBatch: PickSequence data type changed
                      pr_Picking_FindNextPickFromBatch: Added TaskId and TaskDetailId and returning Next pick if the batch
  2013/04/04  PK      pr_Picking_FindNextPickFromBatch: Allowing to pick units/partial picks from Picklane locations as well.
  2012/11/21  YA      pr_Picking_FindNextPickFromBatch: Modifed not to suggest SKU's for a Pre-Pack batch.
  2012/10/29  PK/VM   pr_Picking_FindNextPickFromBatch: Retreive LPNs which are matching with UnitsPerCarton, based on control var
  2012/10/11  AY      pr_Picking_FindNextPickFromBatch: Allow LPN Picks from Bulk
                      pr_Picking_FindNextPickFromBatch: Do not issue Piece picks from Reserve.
  2012/07/04  PK      pr_Picking_FindNextPickFromBatch: Fixed Issue of clearing parameter while looping.
                      pr_Picking_FindNextPickFromBatch: Returing LPNId and LPNDetailIds as we are validating on the Id's in
  2012/05/15  PK      pr_Picking_BatchPickResponse, pr_Picking_FindNextPickFromBatch: Migrated from FH related to LPN/Piece Pick.
  2012/05.15  YA      pr_Picking_FindNextPickFromBatch: Migration from FH.
  2011/10/21  PK      pr_Picking_FindNextPickFromBatch: Bug fix - Mixed zone batches
  2011/08/26  PK      pr_Picking_BatchPickResponse, pr_Picking_FindNextPickFromBatch
  2011/08/08  DP      pr_Picking_FindNextPickFromBatch: Implemented the procedure.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_FindNextPickFromBatch') is not null
  drop Procedure pr_Picking_FindNextPickFromBatch;
Go
Create Procedure pr_Picking_FindNextPickFromBatch
  (@PickBatchNo     TPickBatchNo,
   @PickZone        TZoneId,
   @SearchType      TFlag        = 'F',        /* Refer to Notes above, for valid values and their usage */
   @SKU             TSKU         = null,
   @LPNToPick       TLPN         output,
   @LPNIdToPick     TRecordId    output,
   @LPNDetailId     TRecordId    output,
   @OrderDetailId   TRecordId    output,
   @UnitsToPick     TInteger     output,
   @LocToPick       TLocation    output,
   @PickType        TFlag        output)
as
  declare  @LocationType            TLookUpCode,
           @vPickSequence           TPickSequence,
           @vPrevPickSequence       TPickSequence,
           @iNumPicks               TInteger,
           @vBatchType              TLookUpCode,
           @vBusinessUnit           TBusinessUnit,
           @vValidateUnitsPerCarton TFlag;

  declare @ttPickDetails Table
          (RecordId             TRecordId  identity (1,1),

           OrderDetailId        TRecordId,
           OrderId              TRecordId,
           PickZone             TZoneId,
           LPNId                TRecordId,
           LPN                  TLPN,
           LPNDetailId          TRecordId,
           Location             TLocation,
           LocationRow          TLocation,
           LocationSection      TLocation,
           PickSequence         TPickSequence,
           LocationType         TLookUpCode,

           OHUDF1               TUDF,
           OHUDF2               TUDF,
           OHUDF3               TUDF,
           OHUDF4               TUDF,
           OHUDF5               TUDF,

           ODUDF1               TUDF,
           ODUDF2               TUDF,
           ODUDF3               TUDF,
           ODUDF4               TUDF,
           ODUDF5               TUDF,

           SKU                  TSKU,
           SKU1                 TSKU,
           SKU2                 TSKU,
           SKU3                 TSKU,
           SKU4                 TSKU,

           UnitsToPick          TQuantity,
           UnitsToAllocate      TQuantity,
           LPNQuantity          TQuantity,
           LPNReservedQuantity  TQuantity);

  declare @ttSKUPickDetails Table
          (RecordId             TRecordId  identity (1,1),

           OrderDetailId        TRecordId,
           OrderId              TRecordId,
           PickZone             TZoneId,
           LPNId                TRecordId,
           LPN                  TLPN,
           LPNDetailId          TRecordId,
           Location             TLocation,
           LocationRow          TLocation,
           LocationSection      TLocation,
           PickSequence         TPickSequence,
           LocationType         TLookUpCode,

           OHUDF1               TUDF,
           OHUDF2               TUDF,
           OHUDF3               TUDF,
           OHUDF4               TUDF,
           OHUDF5               TUDF,

           ODUDF1               TUDF,
           ODUDF2               TUDF,
           ODUDF3               TUDF,
           ODUDF4               TUDF,
           ODUDF5               TUDF,

           SKU                  TSKU,
           SKU1                 TSKU,
           SKU2                 TSKU,
           SKU3                 TSKU,
           SKU4                 TSKU,

           UnitsToPick          TQuantity,
           UnitsToAllocate      TQuantity,
           LPNQuantity          TQuantity,
           LPNReservedQuantity  TQuantity);

begin /* pr_Picking_FindNextPickFromBatch */

  /* initialize all o/p vars to null */
  select  @LPNToPick         = null,
          @LPNDetailId       = null,
          @OrderDetailId     = null,
          @UnitsToPick       = null,
          @iNumPicks         = 0,
          @vPickSequence     = '',
          @vPrevPickSequence = '';

  /* Get Batch Type of the given Batch - picks are issued based upon the Batch Type */
  select @vBatchType    = BatchType,
         @vBusinessUnit = BusinessUnit
  from PickBatches
  where (BatchNo = @PickBatchNo);

  /* Get the control variable to validate if the LPN Quantity is not equal to the UnitsPerCarton on Order */
  select @vValidateUnitsPerCarton  = dbo.fn_Controls_GetAsBoolean('Picking', 'ValidateUnitsperCarton', 'Y' /* Yes */, @vBusinessUnit, null /* UserId */);

  /* Fetch the available pick details for all the Pick Batches Order Lines
     For a Piece Pick Batch, only consider Bulk Order that needs to be pulled */
  insert into @ttPickDetails(OrderDetailId, OrderId, PickZone, LPNId, LPN, LPNDetailId, Location, LocationRow, LocationSection,
                             PickSequence, LocationType, OHUDF1,  OHUDF2, OHUDF3, OHUDF4, OHUDF5, ODUDF1,
                             ODUDF2, ODUDF3, ODUDF4, ODUDF5, SKU, SKU1,SKU2, SKU3, SKU4, UnitsToPick, UnitsToAllocate,
                             LPNQuantity, LPNReservedQuantity)
    select   OrderDetailId, OrderId, PickZone, LPNId, LPN, LPNDetailId, Location, LocationRow, LocationSection,
             PickSequence, LocationType, OHUDF1, OHUDF2, OHUDF3, OHUDF4, OHUDF5, ODUDF1, ODUDF2,
             ODUDF3, ODUDF4, ODUDF5,SKU, SKU1,SKU2, SKU3, SKU4, UnitsToAllocate, UnitsToAllocate,
             Quantity, ReservedQuantity
    from vwPickDetails
    where (PickBatchNo = @PickBatchNo) and
          (coalesce(PickZone, '') = coalesce(@PickZone, PickZone, '')) and
          (UnitsToAllocate > 0) and
          ((@vBatchType <> 'U' /* Piece Picks */) or (OrderType = 'B' /* Bulk */)) and
          ((@vValidateUnitsPerCarton = 'N' /* No */) or (UoM = 'PP') or (UnitsPerCarton = Quantity))
    order by PickSequence;

  while (coalesce(@LocToPick, '') = '')
    begin
      /* find the top 1 PickSequence and find out all the picks equal to that seq num and process it. */

      /* select the next Pick sequence from the temp Table.*/
      select  top 1
              @vPickSequence = PickSequence
      from @ttPickDetails
      where (PickSequence > @vPrevPickSequence)
      order by PickSequence;

      /* Get all the Picks for the next pick sequence */
      insert into @ttSKUPickDetails(OrderDetailId, OrderId, PickZone, LPNId, LPN, LPNDetailId, Location, LocationRow, LocationSection,
                                    PickSequence, LocationType, OHUDF1,  OHUDF2, OHUDF3, OHUDF4, OHUDF5, ODUDF1,
                                    ODUDF2, ODUDF3, ODUDF4, ODUDF5, SKU, SKU1,SKU2, SKU3, SKU4, UnitsToPick, UnitsToAllocate,
                                    LPNQuantity, LPNReservedQuantity)
        select   OrderDetailId, OrderId, PickZone, LPNId, LPN, LPNDetailId, Location, LocationRow, LocationSection,
                 PickSequence, LocationType, OHUDF1,  OHUDF2, OHUDF3, OHUDF4, OHUDF5, ODUDF1,
                 ODUDF2, ODUDF3, ODUDF4, ODUDF5, SKU, SKU1,SKU2, SKU3, SKU4, UnitsToPick, UnitsToAllocate,
                 LPNQuantity, LPNReservedQuantity
        from @ttPickDetails
        where (PickSequence = @vPickSequence);

      select @iNumPicks = @@rowcount;

      /* we have arrived at a condition where there are no more picks
         If the Last Pick Sequence is the same the current one, then
         there is no more pick information to process
         in such an instance, break the processing and respond with
         message for no more picks */

      if (@iNumPicks = 0)
        break;

      /* Search for full Carton picks from Reserve */
      select Top 1
             @OrderDetailId  = OrderDetailId,
             @LPNToPick      = LPN,
             @LPNIdToPick    = LPNId,
             @LPNDetailId    = LPNDetailId,
             @LocToPick      = Location,
             @UnitsToPick    = LPNQuantity,
             @PickType       = 'L' /* LPN Pick */
      from @ttSKUPickDetails
      where ((LocationType = 'R' /* Reserve */) and
             (UnitsToAllocate >= LPNQuantity) and
             (LPNQuantity         > 0 ) and
             (LPNReservedQuantity > 0 ) and
             (coalesce(LPN, '')   <>  ''))
      order by LPNQuantity;

      if (coalesce(@LPNToPick, '') <> '')
        break;

      /* Search for full Carton picks from Bulk */
      select Top 1
             @OrderDetailId  = OrderDetailId,
             @LPNToPick      = LPN,
             @LPNIdToPick    = LPNId,
             @LPNDetailId    = LPNDetailId,
             @LocToPick      = Location,
             @UnitsToPick    = LPNQuantity,
             @PickType       = 'L' /* LPN Pick */
      from @ttSKUPickDetails
      where ((LocationType = 'B' /* Bulk */) and
             (UnitsToAllocate >= LPNQuantity) and
             (LPNQuantity         > 0 ) and
             (LPNReservedQuantity > 0 ) and
             (coalesce(LPN, '')   <>  ''))
      order by LPNQuantity;

      if (coalesce(@LPNToPick, '') <> '')
        break;

      /* Search For Piece Picks from Reserve */
      if (@SearchType = 'P' /* Partial LPN Pick */)
        select Top 1
               @OrderDetailId  = OrderDetailId,
               @LPNToPick      = LPN,
               @LPNIdToPick    = LPNId,
               @LPNDetailId    = LPNDetailId,
               @LocToPick      = Location,
               @UnitsToPick    = dbo.fn_MinInt(LPNQuantity, UnitsToAllocate),
               @PickType       = 'U' /* Unit Pick */
        from @ttSKUPickDetails
        where ((LocationType    in ('R' /* Reserve */, 'K'/* PickLane */)) and
               (UnitsToAllocate <= LPNQuantity ) and
               (LPNQuantity     > 0 ))
        order by LPNQuantity;

      if (coalesce(@LocToPick, '') <> '')
        break;

      /* Delete the details for the current pick sequence and move on further */
      delete from @ttSKUPickDetails;
      select @vPrevPickSequence = @vPickSequence, /* set the previous one so that we go past these now */
             @vPickSequence     = null; /* clear the value of the parameter */
    end /* while  (@LocToPick, '') = '' */

  if (coalesce(@LocToPick, '') <> '') or (coalesce(@LPNToPick, '') <> '')
    goto FoundLPNToPick;

  /* It doesn't  matter with QTY and Loc type. What ever it may be, it will gives the
     Pick from carton or Location */
  if (@vBatchType not in ('P' /* Pre-Packs */))
    select Top 1
            @OrderDetailId  = OrderDetailId,
            @LPNToPick      = LPN,
            @LPNIdToPick    = LPNId,
            @LPNDetailId    = LPNDetailId,
            @LocToPick      = Location,
            @UnitsToPick    = dbo.fn_MinInt((LPNQuantity-LPNReservedQuantity), UnitsToAllocate),
            @PickType       = 'U' /*Unit Pick*/
    from @ttSKUPickDetails
    where (LocationType in ('R' /* Reserve */ , 'B' /* Bulk */) and
          (LPNQuantity  > 0 ))
    order by LPN, LPNQuantity;

FoundLPNToPick:
/*
  select @OrderDetailId as OrderDetailId,
         @LPNToPick     as LPNToPick,
         @LPNIdToPick   as LPNIdToPick,
         @LPNDetailId   as LPNDetailId,
         @LocToPick     as LocationToPick,
         @UnitsToPick   as UnitsToPick;
*/

end /* pr_Picking_FindNextPickFromBatch */

Go
