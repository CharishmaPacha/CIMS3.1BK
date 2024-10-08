/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DaB_Replenish_Counts') is not null
  drop Procedure pr_DaB_Replenish_Counts;
Go
/*------------------------------------------------------------------------------
  Proc pr_DaB_Replenish_Counts:
  Pivot Procedure to show Replenish Locations
------------------------------------------------------------------------------*/
Create Procedure pr_DaB_Replenish_Counts
as
begin
  SET NOCOUNT ON;

  declare @vPTBInProgress      TCount,
          @vPTBBelowMin        TCount,
          @vPTBToFill          TCount,
          @vShelvingInProgress TCount,
          @vShelvingBelowMin   TCount;

  declare @ttLocations table
    (LocationId           TRecordId,
     LocationType         TTypeCode,
     StorageType          TTypeCode,
     Quantity             TQuantity,
     InnerPacks           TInnerPacks,
     MinReplenishLevel    TQuantity,
     MaxReplenishLevel    TQuantity,
     ReplenishUoM         TUoM,
     ReplenishType        TTypeCode,
     OnHandStatus         TStatus,
     UnitsPerInnerPack    TCount,
     InnerPacksPerLPN     TCount,
     UnitsPerLPN          TCount);


  /* get all the picklane locations which need to be replensih */
  insert into @ttLocations
    select LTR.LocationId, LTR.LocationType, LTR.StorageType, LTR.Quantity, LTR.InnerPacks,
           LTR.MinReplenishLevel, LTR.MaxReplenishLevel, LTR.ReplenishUoM, LTR.ReplenishType,
           PT.OnHandStatus, LTR.UnitsPerInnerPack, LTR.InnerPacksPerLPN,LTR.UnitsPerLPN
    from vwPickTasks PT
      join vwLocationsToReplenish LTR on (LTR.Location = PT.Location)
    where (PT.Archived = 'N' /* No */);

  /* select values here */
  select @vPTBInProgress = count (distinct TL.LocationId)
  from @ttLocations  TL
  join vwLPNDetails  LD on (LD.LocationId = TL.LocationId)
  where (LD.OnhandStatus in ('D', 'DR')) and
        (LD.StorageType = 'P' );

  select @vShelvingInProgress = count(distinct TL.LocationId)
  from @ttLocations  TL
  join vwLPNDetails  LD on (LD.LocationId = TL.LocationId)
  where (LD.OnhandStatus in ('D', 'DR')) and
        (LD.StorageType = 'U');

  select @vPTBBelowMin  =  count (distinct LocationId)
  from @ttLocations  TL
  where (TL.InnerPacks < (TL.MinReplenishLevel * TL.InnerPacksPerLPN)) and
        (TL.StorageType = 'P');

  select @vShelvingBelowMin =  count (distinct LocationId)
  from @ttLocations  TL
  where (TL.Quantity < (TL.MinReplenishLevel * TL.UnitsPerInnerPack)) and
        (TL.StorageType = 'U');

  select @vPTBToFill = count(distinct LocationId)
  from @ttLocations
  where (ReplenishType = 'F') and
        (OnhandStatus not in ('DR', 'D'));

  select null                 as  BatchNo,
         @vPTBInProgress      as 'PTB In progress',
         @vPTBBelowMin        as 'PTB Below Min',
         @vPTBToFill          as 'PTB To Fill',
         @vShelvingInProgress as 'Shelving in progress',
         @vShelvingBelowMin   as 'Shelving below Min';

  /*
  select BatchNo, '5434' as 'PTB In progress', '6565' as 'PTB Below Min', '2323' as 'PTB To Fill',
  '2543' as 'Shelving in progress', '1236' as 'Shelving below Min'
  from vwpicktasks
  */

end /* pr_DaB_Replenish_Counts */

Go
