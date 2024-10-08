/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DaB_RetailWave_BatchCounts') is not null
  drop Procedure pr_DaB_RetailWave_BatchCounts;
Go
/*------------------------------------------------------------------------------
  Proc pr_DaB_RetailWave_BatchCounts:
  Pivot Procedure to show by DestZone
------------------------------------------------------------------------------*/
Create Procedure pr_DaB_RetailWave_BatchCounts
  (@PickBatchNo      TPickBatchNo)
as
begin
  SET NOCOUNT ON;

  select BatchNo, DestZone, vwPT_UDF1 Area, substring(Location, 1, 1) Location,
         count(distinct TaskId) Tasks, sum(Detailinnerpacks) Cases, sum(Detailquantity) Units
  from vwpicktasks
  where (BatchNo=@PickBatchNo)
  group by BatchNo, DestZone, vwPT_UDF1, substring(Location, 1, 1);

end /* pr_DaB_RetailWave_BatchCounts */

Go
