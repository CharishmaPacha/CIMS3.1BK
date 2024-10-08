/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_ActivateFromLPNs') is not null
  drop Procedure pr_Reservation_ActivateFromLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_ActivateFromLPNs:

  1. Assumption is that all validations are taken care of before this call is made
      No status updates are made here.
      No recounts are called
      Recounts & Status updates are made later to this call
  2. #FromLPNs - already populated with LPN Details of Inventory LPNs
  3. #ToLPNs   - already populated with LPN Details of Ship Cartons
  4. Loop through #FromLPN details and deduct the respective quantity from #ToLPN details
------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_ActivateFromLPNs
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @vFromLPNId         TRecordId,
          @vLPNNumLines       TCount,
          @vLPNSKUId          TRecordId,
          @vLPNInnerPacks     TInnerPacks,
          @vLPNQuantity       TQuantity,
          @vKeyValue          TVarchar,

          @vTLLPNId           TRecordId,
          @vTLQuantity        TQuantity,
          @vInnerLoopId       TRecordId,

          @vAvailableQty      TQuantity,
          @vActivatedQty      TQuantity;
begin
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Loop through LPN Details */
  while (exists(select * from #FromLPNDetails where RecordId > @vRecordId))
    begin
      select top 1 @vFromLPNId     = LPNId,
                   @vLPNNumLines   = LPNLines,
                   @vLPNSKUId      = SKUId,
                   @vLPNInnerPacks = InnerPacks,
                   @vLPNQuantity   = Quantity,
                   @vRecordId      = RecordId,
                   @vKeyValue      = KeyValue,
                   @vActivatedQty  = 0,
                   @vTLLPNId       = 0,
                   @vInnerLoopId   = 0
      from #FromLPNDetails
      where (RecordId > @vRecordId)
      order by RecordId;

      if (object_id('tempdb..#PossibleTLs') is not null)
        delete from #PossibleTLs;

      /* If it is a multi SKU LPN, then see if the entire LPN can be allocated to a PT */
      if (@vLPNNumLines > 1)
        begin
          /* Check all possible LPN combinations where there is an overlap between TempLabels and From LPN */
          select TLL.LPNId TLLPNId, TLL.SKUId TLSKUId, TLL.Quantity TLQuantity,
                 LD.SKUId FromSKUId, LD.Quantity FromQty, LD.LPNId FromLPNId, LD.LPNDetailId FromLPNDetailId
          into #PossibleTLs
          from #ToLPNDetails TLL
            full outer join #FromLPNDetails LD on TLL.KeyValue = LD.KeyValue and TLL.Quantity = LD.Quantity
          where ((LD.LPNId = @vFromLPNId) and (TLL.ProcessedFlag = 'N'));

          /* Delete any LPNs where both records do not match */
          delete
          from #PossibleTLs
          where TLLPNId in (select distinct TLLPNId from #PossibleTLs where TLSKUId is null or FromSKUId is null);

          /* Get one matching Temp label from the remaining list */
          select top 1 @vTLLPNId = TLLPNId from #PossibleTLs;

          /* Mark the temp label for activation */
          update #ToLPNDetails set ProcessedFlag = 'A' /* Activate */ where (LPNId = @vTLLPNId);

          /* Update Matched Quantity on #FromLPNId */
          update FL
          set FL.ReservedQty = coalesce((select sum(TLQuantity) from #PossibleTLs where TLLPNId = @vTLLPNId), 0)
          from #FromLPNDetails FL
          where (LPNId = @vFromLPNId);
        end
      else
        begin
          select @vAvailableQty = @vLPNQuantity;

          /* Loop through the list of temp labels already generated and activate them */
          while (@vAvailableQty > 0) and
                (exists (select * from #ToLPNDetails where KeyValue = @vKeyValue and ProcessedFlag = 'N' /* No */ and RecordId > @vInnerLoopId))
            begin
              select top 1 @vTLLPNId     = LPNId,
                           @vTLQuantity  = Quantity,
                           @vInnerLoopId = RecordId
              from #ToLPNDetails
              where (KeyValue      = @vKeyValue) and
                    (ProcessedFlag = 'N' /* No */) and
                    (RecordId      > @vInnerLoopId)
              order by RecordId;

              /* If current selected Temp label can be activated, do so */
              if (@vTLQuantity <= @vAvailableQty)
                begin
                  select @vAvailableQty -= @vTLQuantity,
                         @vActivatedQty += @vTLQuantity;

                  update #ToLPNDetails
                  set ProcessedFlag = 'A' /* Activate */
                  where (RecordId = @vInnerLoopId);
                end
            end /* End of loop through temp labels for given Order + SKU */

          update #FromLPNDetails
          set ReservedQty += coalesce(@vActivatedQty, 0)
          where (LPNId = @vFromLPNId);
        end /* procesing of single SKU LPN */
    end /* End loop #FromLPNs */

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Reservation_ActivateFromLPNs */

Go
