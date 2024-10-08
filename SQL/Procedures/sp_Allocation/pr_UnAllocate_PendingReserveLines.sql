/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/07/28  TK      pr_UnAllocate_PendingReserveLines: When same SKU is allocated from multiple picklanes, we need to debit reserved quantity from that particular picklane only (OBV3-969)
                      pr_UnAllocate_PendingReserveLines & pr_UnAllocate_ReservedLines : Initial revision (CIMSV3-1490)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_UnAllocate_PendingReserveLines') is not null
  drop Procedure pr_UnAllocate_PendingReserveLines;
Go
/*------------------------------------------------------------------------------
  Proc pr_UnAllocate_PendingReserveLines: As part of the unallocation process
    some PR lines have to be unallocated. The lines to unallocate are in #LPNDetails
    which includes PR and other lines. This procedure handles the unallocation of
    the PR lines.

    The process of unallocation of PR lines invovles reducing the reserved quantity on
    either directed/available lines in that sequence. When the complete reserved qty
    is reduced the PR line is finally deleted.

    Note that PR lines exists only for Logical LPNs i.e. Picklanes and each logical
    LPN has only one SKU (i.e. if it is a multi SKU picklane, the are multiple
    logical LPNs for each SKU)

  #LPNDetails -> TLPNDetails
------------------------------------------------------------------------------*/
Create Procedure pr_UnAllocate_PendingReserveLines
  (@Operation          TOperation = null,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,

          @vRecordId              TRecordId,
          @vRLRecordId            TRecordId,

          @vLPNId                 TRecordId,
          @vLPNDetailId           TRecordId,
          @vLDOnhandStatus        TStatus,
          @vRLLPNDetailId         TRecordId,
          @vRLOnhandStatus        TStatus,

          @vQuantity              TQuantity,
          @vReservedQtyToUpdate   TQuantity,
          @vReservedQtyUpdated    TQuantity,
          @vKeyValue              TKeyValue;

  declare @ttLPNDetailsUpdated    TEntityKeysTable;
begin /* pr_UnAllocate_PendingReserveLines */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vKeyValue    = '';

  /* Create required temp tables */
  select * into #LPNsToRecompute from @ttLPNDetailsUpdated;

  /* Get all the Available/Directed LPN Details to process for the LPNDetails of the
     PR lines being processed */
  select LD.LPNId, LD.LPNDetailId, LD.OnhandStatus, LD.Quantity, LD.ReservedQty,
         TLD.KeyValue, 'N' as ProcessedFlag, null as Reference,
         row_number() over (order by LD.OnhandStatus desc, LD.Quantity desc) as RecordId  -- Process Directed lines first
  into #AvailableLPNDetails
  from LPNDetails LD
    join #LPNDetails TLD on (LD.LPNId = TLD.LPNId) and
                            (LD.SKUId = TLD.SKUId)
  where (TLD.OnhandStatus = 'PR' /* Pending Reservation */) and
        (LD.OnhandStatus in ('A', 'D' /* Avail., Directed */)) and
        (LD.ReservedQty > 0)
  order by LD.OnhandStatus desc; /* Directed first, then available */

  /* Get summary of all Pending Reserve lines by Key Value */
  select KeyValue, sum(Quantity) as Quantity
  into #PendingReserveLines
  from #LPNDetails
  where (OnhandStatus = 'PR' /* PendingReserve */)
  group by KeyValue;

  /*-------------- Process Pending Reserved Lines ---------------*/
  /* Loop thru each Key Value and reduce ReservedQty on the D/A Lines */
  while exists (select * from #PendingReserveLines where KeyValue > @vKeyValue)
    begin
      select top 1 @vKeyValue            = KeyValue,
                   @vReservedQtyToUpdate = Quantity
      from #PendingReserveLines
      where (KeyValue > @vKeyValue)
      order by KeyValue;

      /* Initialize */
      select @vRLRecordId    = 0,
             @vRLLPNDetailId = null;

      /* Loop thru each line and reduce reserved quantity until we exhaust reserved quantity to be unallocated.
         Deduct reserved quantity from directed lines first and then from Available line */
      while (@vReservedQtyToUpdate > 0) and
            (exists (select *
                     from #AvailableLPNDetails
                     where (KeyValue = @vKeyValue) and
                           (RecordId > @vRLRecordId)))
        begin
          select top 1 @vRLRecordId    = RecordId,
                       @vRLLPNDetailId = LPNDetailId
          from #AvailableLPNDetails
          where (KeyValue = @vKeyValue) and
                (RecordId > @vRLRecordId)
          order by RecordId;

          /* Reduce Reserved Qty */
          update #AvailableLPNDetails
          set @vReservedQtyUpdated = dbo.fn_MinInt(ReservedQty, @vReservedQtyToUpdate),
              ReservedQty         -= dbo.fn_MinInt(ReservedQty, @vReservedQtyToUpdate),
              ProcessedFlag        = 'Y'/* Yes */
          where (LPNDetailId = @vRLLPNDetailId);

          /* Reduce the Reserved quantity updated on temp table */
          update #PendingReserveLines
          set Quantity -= @vReservedQtyUpdated
          where (KeyValue = @vKeyValue);

          /* Reduce from the total quantity that needs to be unallocated */
          select @vReservedQtyToUpdate -= @vReservedQtyUpdated;
        end
    end

  /* Update KeyValue matching Records in temp table as processed when Quantity for that KeyValue is completely deducted */
  update TLD
  set ProcessedFlag = 'Y' /* Yes */
  from #LPNDetails TLD
    join #PendingReserveLines PRL on (TLD.KeyValue = PRL.KeyValue)
  where (PRL.Quantity = 0 ) and
        (TLD.OnhandStatus = 'PR' /* Pending Reserve */) and
        (TLD.ProcessedFlag = 'N' /* No */);

  /* Update reserved qty on Available/Directed lines, only when reserved quantity is completely deducted */
  update LD
  set LD.ReservedQty  = ALD.ReservedQty,
      LD.ModifiedBy   = @UserId,
      LD.ModifiedDate = current_timestamp
  from LPNDetails LD
    join #AvailableLPNDetails ALD on (LD.LPNDetailId = ALD.LPNDetailId)
    join #PendingReserveLines PRL on (ALD.KeyValue = PRL.KeyValue)
  where (PRL.Quantity = 0 ) and
        (ALD.ProcessedFlag = 'Y'/* Yes */);

  /* Delete the Pending Reserve line whose reserved quantity is reduced to zero */
  delete LD
  from LPNDetails LD
    join #LPNDetails TLD on (LD.LPNDetailId = TLD.LPNDetailId)
  where (TLD.ProcessedFlag = 'Y' /* Yes */) and
        (TLD.OnhandStatus = 'PR' /* Pending Reserve */) and
        (LD.OnhandStatus = 'PR');

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_UnAllocate_PendingReserveLines */

Go
