/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/16  MS      pr_LPNs_PackageNoResequence: Code Optimization (BK-287)
  2020/07/18  TK      pr_LPNs_PackageNoResequence: Exclude carton type LPNs (HA-1135)
                      pr_LPNs_PackageNoResequence: Corrected potential issues
  2015/08/25  NY      pr_LPNs_PackageNoResequence: Added code to correct LPNsAssigned on order (SRI-375)
  2015/07/28  AY      pr_LPNs_PackageNoResequence: Bug fixes (SRI-350)
  2015/04/06  RV      pr_LPNs_PackageNoResequence : Change input Parameter as PickTicket to OrderId
  2015/03/09  RV/VM   pr_LPNs_PackageNoResequence : Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_PackageNoResequence') is not null
  drop Procedure pr_LPNs_PackageNoResequence;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_PackageNoResequence:
    This procedure will Re order the Package Sequence number, if those are
    not in sequence.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_PackageNoResequence
  (@OrderId TRecordId,
   @LPNId   TRecordId = null)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vTotalLPNsOnOrder       TCount,
          @vLPNsAssigned           TCount,
          @vMinUnusedPackageSeqNo  TInteger,
          @vLPNIdToCorrect         TInteger,
          @vLPNPackageSeqNo        TRecordId,
          @vOrderNumLPNs           TCount,
          @vCountofSeqNos          TCount,
          @vCountofLPNSeqNos       TCount,
          @vCountofOrderSeqNos     TCount,
          @vMinPackageSeqNo        TInteger,
          @vMaxPackageSeqNo        TInteger;

  declare @ttLPNs Table
          (RecordId       TRecordId identity(1,1),
           LPNId          TRecordId,
           PackageSeqNo   TInteger,
           ProcessFlag    TFlag default 'N');

  declare @ttLPNsToCorrect TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode      = 0,
         @vMessageName     = null,
         @vLPNPackageSeqNo = null,
         @vCountofSeqNos   = null,
         @vMinPackageSeqNo = null,
         @vMaxPackageSeqNo = null;

  /* Validations */
  if (@OrderId is null)
    begin
      set @vMessageName = 'InvalidOrderId';
      goto ErrorHandler;
    end

  /* Get the counts based upon LPNs */
  select @vTotalLPNsOnOrder = count(*),
         @vMaxPackageSeqNo  = Max(coalesce(PackageSeqNo, 0)),
         @vMinPackageSeqNo  = Min(coalesce(PackageSeqNo, 0))
  from LPNs
  where (OrderId = @OrderId) and (LPNType not in ('C', 'A', 'TO' /* Carton, Cart */));

  /* Get the Counts on the Order */
  select @vOrderNumLPNs = NumLPNs,
         @vLPNsAssigned = LPNsAssigned
  from OrderHeaders
  where (OrderId = @OrderId);

  /* If there is a mis-match, then correct the order */
  if (@vOrderNumLPNs <> @vTotalLPNsOnOrder) or (@vLPNsAssigned <> @vTotalLPNsOnOrder)
    update OrderHeaders
    set NumLPNs      = @vTotalLPNsOnOrder,
        LPNsAssigned = @vTotalLPNsOnOrder
    where (OrderId = @OrderId);

  /* No LPNs on PT - Ignore and discontinue to process further or LPN Package sequence numer is correct*/
  if (@vTotalLPNsOnOrder = 0) goto Exithandler;

  /* if LPNId is not null then we retrieve PackageSeqNo and duplicate count For Resequence is required or not for that LPN */
  if (@LPNId is not null)
    begin
      select @vLPNPackageSeqNo = PackageSeqNo
      from LPNs
      where (LPNId = @LPNId);

      select @vCountofLPNSeqNos = count(*)
      from LPNs
      where (OrderId = @OrderId) and (PackageSeqNo = @vLPNPackageSeqNo);
    end
  else
    begin
      select @vCountofOrderSeqNos = count(*)
      from LPNs
      where (OrderId = @OrderId)
      group by PackageSeqNo
      having count(*) > 1;
    end

  /* If it is an LPN and has a Package seq no and it is within the valid range and no other
     LPN uses a duplicate of this, then there is nothing to be corrected */
  if (@LPNId is not null) and
     (@vLPNPackageSeqNo <> 0) and
     (coalesce(@vLPNPackageSeqNo, 0) <= @vTotalLPNsOnOrder) and
     (coalesce(@vCountofLPNSeqNos, 0) = 1 /* No duplicate */)
    begin
      goto Exithandler;
    end

  /* If it is an OrderId, then check the LPN's Package SeqNo against zero and total LPNs and duplicate PackageSeqNo */
  if (@OrderId is not null) and
     (@vMinPackageSeqNo > 0) and
     (coalesce(@vMaxPackageSeqNo, 0) <= @vTotalLPNsOnOrder) and
     (coalesce(@vCountofOrderSeqNos, 0) = 0/* No duplicate */)
    begin
      goto Exithandler;
    end;

  /* Get all LPNs on the Order */
  select LPNId, LPN, PackageSeqNo, LPNType
  into #OrderLPNs
  from LPNs
  where (OrderId = @OrderId) and
        (LPNType not in ('C', 'A', 'TO' /* Carton, Cart */));

   /* Update All Duplicates with 0 */
   ;with DuplicateLPNs(DuplicateCount, LPNId) as
   (
      select row_number() over (partition by PackageSeqNo order by PackageSeqNo) as RowNumber,
             LPNId
      from #OrderLPNs
      where (PackageSeqNo <> 0)
   )
   update L
   set L.PackageSeqNo = 0
   from LPNs L
     join DuplicateLPNs D on (L.LPNId = D.LPNId)
   where (D.DuplicateCount > 1);

  /* Insert as many records as LPNs exists on PT */
  insert into @ttLPNs (LPNId)
    select null
    from #OrderLPNs
    order by PackageseqNo;

  /* Update LPNs to temp table which are matching their PackageSeqNo with RecordId */
  update ttL
  set LPNId        = L.LPNId,
      PackageSeqNo = L.PackageSeqNo
  from @ttLPNs ttL
    join LPNs L on (L.PackageSeqNo = ttL.RecordId)
  where (L.OrderId = @OrderId)

  /* Get the list of LPNs to correct - Basically if any PackageSeqNo is greater than LPNs exists on PT would be collected here */
  insert into @ttLPNsToCorrect (EntityId)
    select LPNId
    from #OrderLPNs
    where ((PackageSeqNo > @vTotalLPNsOnOrder) or (coalesce(PackageSeqNo, 0) = 0))
    order by PackageseqNo Desc;

  /* Loop through all LPNs to correct */
  while (exists (select * from @ttLPNsToCorrect))
    begin
      /* select the first LPN in the to correct list */
      select top 1 @vLPNIdToCorrect = EntityId
      from @ttLPNsToCorrect
      order by RecordId;

      /* select the Minimum Missing Record */
      select @vMinUnusedPackageSeqNo = Min(RecordId)
      from @ttLPNs
      where (LPNId is null);

      /* Update temp table as well */
      update @ttLPNs
      set LPNId        = @vLPNIdToCorrect,
          PackageSeqNo = @vMinUnusedPackageSeqNo,
          ProcessFlag  = 'P' /* Processed */
      where (RecordId = @vMinUnusedPackageSeqNo);

      /* Delete the corrected LPN from the to be corrected list */
      delete from @ttLPNsToCorrect where (EntityId = @vLPNIdToCorrect);
    end

  /* Update the PackageSeqNo from #ttLPNs if modified above */
  update L
  set PackageSeqNo = TL.PackageSeqNo
  from LPNs L join @ttLPNs TL on L.LPNId = TL.LPNId
  where (TL.ProcessFlag = 'P');

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end  /* pr_LPNs_PackageNoResequence */

Go
