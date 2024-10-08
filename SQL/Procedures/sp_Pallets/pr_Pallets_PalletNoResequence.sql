/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/08  AY      pr_Pallets_PalletNoResequence : Changes to generate palletseq numbers (S2GCA-750)
  2019/01/22  RT      pr_Pallets_PalletNoResequence: Procedure to generate the PalletSeqNo for a Pallet on a Load (S2GMI-39)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_PalletNoResequence') is not null
  drop Procedure pr_Pallets_PalletNoResequence;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_PalletNoResequence:
    This procedure will order the Pallet Sequence number, if those are
    not in sequence or if there is no sequnce No is assigned .
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_PalletNoResequence
  (@LoadId     TRecordId,
   @PalletId   TRecordId = null)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vTotalPalletsOnLoad     TCount,
          @vLoadNumPallets         TCount,
          @vMinUsedPalletSeqNo     TInteger,
          @vPalletIdToCorrect      TInteger,
          @vPalletSeqNo            TRecordId,

          @vCountofPalletSeqNos    TCount,
          @vCountofLoadSeqNos      TCount,
          @vMinPalletSeqNo         TInteger,
          @vMaxPalletSeqNo         TInteger;

  declare @ttPallets Table
          (RecordId       TRecordId identity(1,1),
           PalletId       TRecordId,
           PalletSeqNo    TInteger);

  declare @ttPalletsToCorrect TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode      = 0,
         @vMessageName     = null,
         @vPalletSeqNo     = null,
         @vMinPalletSeqNo  = null,
         @vMaxPalletSeqNo  = null;

  /* Validations */
  if (@LoadId is null)
    begin
      set @vMessageName = 'InvalidLoadId';
      goto ErrorHandler;
    end

  /* Get the counts based upon Pallets */
  select @vTotalPalletsOnLoad  = count(*),
         @vMaxPalletSeqNo      = Max(coalesce(PalletSeqNo, 0)),
         @vMinPalletSeqNo      = Min(coalesce(PalletSeqNo, 0))
  from Pallets
  where (LoadId = @LoadId);

  /* Get the Counts on the Load */
  select @vLoadNumPallets = NumPallets
  from Loads
  where (LoadId = @LoadId);

  /* If there is a mis-match, then correct the Load */
  if (@vLoadNumPallets <> @vTotalPalletsOnLoad)
    update Loads
    set NumPallets = @vTotalPalletsOnLoad
    where (LoadId = @LoadId);

  /* if PalletId is not null then we retrieve PalletSeqNo and duplicate count whether Resequence is required or not for that Pallet */
  if (@PalletId is not null)
    begin
      select @vPalletSeqNo = PalletSeqNo
      from Pallets
      where (PalletId = @PalletId);

      /* Check how many other pallets have this seq no */
      select @vCountofPalletSeqNos = count(*)
      from Pallets
      where (LoadId = @LoadId) and (PalletSeqNo = @vPalletSeqNo);
    end
  else
    begin
      /* Check if there are duplicate seqnos on Load */
      select @vCountofLoadSeqNos = count(*)
      from Pallets
      where (LoadId = @LoadId)
      group by PalletSeqNo
      having count(*) > 1;
    end

  /* No Pallets on Load - Ignore and discontinue to process further or the Pallet Seq No is correct */
  if (@vTotalPalletsOnLoad = 0)
     goto Exithandler;

  /* If it is a Pallet and has a PalletSeqNo and it is within the valid range and no other
     Pallet uses a duplicate of this, then there is nothing to be corrected */
  if (@PalletId is not null) and
     (@vPalletseqNo <> 0) and
     (coalesce(@vPalletSeqNo, 0) <= @vTotalPalletsOnLoad) and
     (coalesce(@vCountofPalletSeqNos, 0) = 1 /* No duplicate */)
    begin
      goto Exithandler;
    end

  /* If it is a Load, then check the Pallet's Pallet Seq No against zero and total Pallets and duplicate PalletSeqNo */
  if (@LoadId is not null) and
     (@vMinPalletSeqNo > 0) and
     (coalesce(@vMaxPalletSeqNo, 0) <= @vTotalPalletsOnLoad) and
     (coalesce(@vCountofLoadSeqNos, 0) = 0/* No duplicate */)
    begin
      goto Exithandler;
    end;

   /* Update All Duplicates with 0 */
   with DuplicatePallets(DuplicateCount, PalletId) as
   (
      select row_number() over (partition by PalletSeqNo
                          order by PalletSeqNo) as RowNumber,
                          PalletId
      from Pallets
      where (LoadId = @LoadId) and (PalletSeqNo <> 0)
   )
   update P
     set P.PalletSeqNo = 0
   from Pallets P
     join DuplicatePallets D on (P.PalletId = D.PalletId)
   where (D.DuplicateCount > 1);

  /* Insert as many records as Pallets exists on Load */
  insert into @ttPallets (PalletId)
    select null
    from Pallets
    where (LoadId = @LoadId)
    order by PalletSeqNo;

  /* Update Pallets to temp table which are matching their PalletSeqNo with RecordId */
  update ttP
  set PalletId     = P.PalletId,
      PalletSeqNo  = P.PalletSeqNo
  from @ttPallets ttP
    join Pallets P on (P.PalletSeqNo = ttP.RecordId)
  where (P.LoadId = @LoadId)

  /* Get the list of Pallets to correct - Basically if any PalletSeqNo is greater than NumPallets on Load
     they would be corrected here */
  insert into @ttPalletsToCorrect (EntityId)
    select PalletId
    from Pallets
    where (LoadId = @LoadId) and
          ((PalletSeqNo > @vTotalPalletsOnLoad) or (coalesce(PalletSeqNo, 0) = 0))
    order by PalletSeqNo Desc;

  /* Loop through all Pallets to correct */
  while (exists (select * from @ttPalletsToCorrect))
    begin
      /* select the first Pallet in the to correct list */
      select top 1 @vPalletIdToCorrect = EntityId
      from @ttPalletsToCorrect
      order by RecordId;

      /* select the Minimum Missing Record */
      select @vMinUsedPalletSeqNo = Min(RecordId)
      from @ttPallets
      where (PalletId is null);

      /* Update the PalletSeqNo with Minimum missing PalletSeqNo */
      update Pallets
      set PalletSeqNo = @vMinUsedPalletSeqNo
      where (PalletId = @vPalletIdToCorrect);

      /* Update temp table as well */
      update @ttPallets
      set PalletId        = @vPalletIdToCorrect,
          PalletSeqNo = @vMinUsedPalletSeqNo
      where (RecordId = @vMinUsedPalletSeqNo);

      /* Delete the corrected Pallet from the   corrected list */
      delete from @ttPalletsToCorrect where (EntityId = @vPalletIdToCorrect);
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end  /* pr_Pallets_PalletNoResequence */

Go
