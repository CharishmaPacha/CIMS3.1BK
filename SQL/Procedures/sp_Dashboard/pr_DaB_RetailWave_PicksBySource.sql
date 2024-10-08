/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/06/13  NB      pr_DaB_RetailWave_PicksBySource: added SortSeq columns for Status, DestZone, Area
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DaB_RetailWave_PicksBySource') is not null
  drop Procedure pr_DaB_RetailWave_PicksBySource;
Go
/*------------------------------------------------------------------------------
  Proc pr_DaB_RetailWave_PicksBySource

------------------------------------------------------------------------------*/
Create Procedure pr_DaB_RetailWave_PicksBySource
  (@PickBatchNo      TPickBatchNo)
as
begin
  SET NOCOUNT ON;

  select PickBatchNo, DestZone, vwPT_UDF1 Area, TaskDetailStatusDesc Status,
         count(distinct TaskId) Tasks, sum(Detailinnerpacks) Cases, sum(DetailQuantity) Units,
         Min(S.SortSeq) StatusSortSeq, 0 as DestZoneSortSeq, 0 as AreaSortSeq
  from vwPickTasks PT
        join Statuses S on (PT.TaskDetailStatus  = S.StatusCode  ) and
                           (PT.BusinessUnit      = S.BusinessUnit) and
                           (S.Entity             = 'Task'        )
  where (PickBatchNo = @PickBatchNo)
  group by PickBatchNo, DestZone, vwPT_UDF1, TaskDetailStatusDesc;

end /* pr_DaB_RetailWave_PicksBySource */

Go
