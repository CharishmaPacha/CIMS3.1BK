/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/06/13  NB      pr_DaB_RetailWave_SKUDistribution: added SortSeq column for SKUDestZone
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DaB_RetailWave_SKUDistribution') is not null
  drop Procedure pr_DaB_RetailWave_SKUDistribution;
Go

/*------------------------------------------------------------------------------
  Proc pr_DaB_RetailWave_SKUDistribution:

------------------------------------------------------------------------------*/
Create Procedure pr_DaB_RetailWave_SKUDistribution
  (@PickBatchNo      TPickBatchNo)
as
begin
  SET NOCOUNT ON;

  with SKUDist(SKU, DistCount, SKUDestZone)
  as
  (
    select SKU, count(distinct DestZone),
           case when count(distinct DestZone) = 1 then min(DestZone) else 'Both' end
    from vwpickbatchdetails
    where (Pickbatchno = @PickBatchNo)
    group by SKU
   )
  select SKUDestZone, count(distinct SKUDist.SKU) SKUs, sum(UnitsAssigned) Units, 0 SKUDestZoneSortSeq
  from vwPickBatchDetails PBD
       join SKUDist on (PBD.SKU = SKUDist.SKU)
  where (PickBatchNo = @PickBatchNo)
  group by SKUDestZone;

end /* pr_DaB_RetailWave_SKUDistribution */

Go
