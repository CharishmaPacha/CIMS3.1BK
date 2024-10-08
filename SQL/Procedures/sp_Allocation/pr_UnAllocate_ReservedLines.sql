/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_UnAllocate_PendingReserveLines & pr_UnAllocate_ReservedLines : Initial revision (CIMSV3-1490)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_UnAllocate_ReservedLines') is not null
  drop Procedure pr_UnAllocate_ReservedLines;
Go
/*------------------------------------------------------------------------------
  Proc pr_UnAllocate_ReservedLines: As part of the unallocation process
    some Reserved lines have to be unallocated. The lines to unallocate are in #LPNDetails
    which includes Reserved and other lines. This procedure handles the unallocation of
    the Reserved lines only.

    The process of unallocating Reserved Lines adding the unallocated quantity back
    to available line if there is one and deleting the Reserve Line.
    If there isn't an available line, the Reserved line is converted to available line
    and the Reserved Qty and Order info are cleared.

  #LPNDetails -> TLPNDetails
------------------------------------------------------------------------------*/
Create Procedure pr_UnAllocate_ReservedLines
  (@Operation          TOperation = null,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName;

  declare @ttLPNDetailsUpdated    TEntityKeysTable;
begin /* pr_UnAllocate_ReservedLines */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /*-------------- Processed Reserved Lines ---------------*/
  /* If Un-allocating an Reserved line, then find an Available line to add Quantity */
  ;with LPNAvailableLines as
   (
     select LD.LPNId, LD.LPNDetailId, LD.SKUId, TLD.RecordId, TLD.Quantity,
            row_number() over (partition by LD.LPNId, LD.SKUId order by LD.LPNId, LD.SKUId) as ALRecordId  -- Partitions the dataset by LPNId & SKUId
     from #LPNDetails TLD
       join LPNDetails LD on (TLD.LPNId = LD.LPNId) and
                             (TLD.SKUId = LD.SKUId)
     where (LD.OnhandStatus = 'A' /* Available */) and  -- Find an available line to add reserved quantity
           (TLD.OnhandStatus = 'R' /* Reserved */)
   )
  update LD
  set LD.Quantity += LAL.Quantity
  output LAL.RecordId into @ttLPNDetailsUpdated (EntityId)
  from LPNDetails LD
    join LPNAvailableLines LAL on (LD.LPNDetailId = LAL.LPNDetailId) and
                                  (LAL.ALRecordId = 1); -- If there are multiple available lines then this will update increment quantity on the first available line only

  /* If there is an Available line and Quantity is added to the available line then just delete
     the Reserved Line */
  if exists(select * from @ttLPNDetailsUpdated)
    delete LD
    from LPNDetails LD
      join #LPNDetails TLD on (LD.LPNDetailId = TLD.LPNDetailId)
      join @ttLPNDetailsUpdated LDU on (TLD.RecordId = LDU.EntityId);

  /* If there is no Available line in the LPN then just convert the Reserved line to Available line, clear reserved quantity and order info */
  update LD
  set OnhandStatus  = 'A' /* Available */,
      ReservedQty   = 0,
      OrderId       = null,
      OrderDetailId = null,
      ModifiedBy    = @UserId,
      ModifiedDate  = current_timestamp
  output TLD.RecordId into @ttLPNDetailsUpdated (EntityId)
  from LPNDetails LD
    join #LPNDetails TLD on (LD.LPNDetailId = TLD.LPNDetailId)
    left outer join @ttLPNDetailsUpdated LDU on (TLD.RecordId = LDU.EntityId)
  where (TLD.OnhandStatus = 'R' /* Reserved */) and
        (LDU.EntityId is null);

  /* By this time we would have processed all Reserved lines, so update process flag */
  update TLD
  set ProcessedFlag = 'Y' /* Yes */
  from #LPNDetails TLD
    join @ttLPNDetailsUpdated LDU on (TLD.RecordId = LDU.EntityId);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_UnAllocate_ReservedLines */

Go
