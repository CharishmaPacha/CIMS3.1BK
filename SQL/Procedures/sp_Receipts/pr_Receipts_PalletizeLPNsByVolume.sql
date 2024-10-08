/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/31  MS      pr_Receipts_PalletizeLPNsByVolume: Added proc to palletize the LPNs of selected receipt (JL-280)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_PalletizeLPNsByVolume') is not null
  drop Procedure pr_Receipts_PalletizeLPNsByVolume;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_PalletizeLPNsByVolume: When the receiving LPNs (in #LPNsToSort have
    to be grouped together into Pallets by volume, this procedure is invoked. It
    creates a Pallet Number for each group of LPNs to not exceed the given Pallet Volume.

  Note: Done extensive evaluation to see if we could avoid while loop and do this in
        one query, but exhuasted all approaches. we could not just divide SumVolume/PalletVolume
        as that was creating with some Pallets being slightly more than expected due to rounding

  #LPNsToSort: TEntityKeysTable
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_PalletizeLPNsByVolume
  (@PalletVolume  TInteger,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName,
          @vRecordId     TRecordId;

  declare @vPalletNumber TInteger,
          @vLPNCount     TCount;

begin /* pr_Receipts_PalletizeByVolume */
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vRecordId     = 0,
         @vPalletNumber = 0; --Initialize

  select @vLPNCount = count(*) from #LPNsToSort;

  /* Take the next pallet group and take the first N LPNs not exceeding the Pallet Volume
     and assign a pallet number. Repeat until we exhaust all LPNs. Worst case, each LPN
     may be on a pallet and hence loop that many times. PalletNumber check is needed
     to ensure it doesn't go into infinite loop */
  while (@vPalletNumber <= @vLPNCount) and
        (exists (select * from #LPNsToSort where Palletized = 'N'))
    begin
      /* Get the remaining LPNs with cumulative volume computed */
      ;with NextLPNs as
      (
        select LTS.LPNId, LTS.PalletGroup, LTS.Palletized, LTS.PalletNumber,
               sum(CartonVolume) over (partition by LTS.PalletGroup order by LTS.CartonVolume, LTS.SeqIndex) as SumVolume
        from #LPNsToSort LTS
        where (LTS.PalletGroup in (select top 1 PalletGroup from #LPNsToSort where Palletized = 'N')) and
              (LTS.Palletized = 'N')
      )
      update NextLPNs
      set PalletNumber = @vPalletNumber + 1,
          Palletized   = 'Y'
      where (SumVolume <= @PalletVolume);

      /* Prepare for next pallet */
      set @vPalletNumber += 1;
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_PalletizeLPNsByVolume */

Go
