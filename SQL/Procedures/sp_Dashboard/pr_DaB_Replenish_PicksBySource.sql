/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DaB_Replenish_PicksBySource') is not null
  drop Procedure pr_DaB_Replenish_PicksBySource;
Go
/*------------------------------------------------------------------------------
  Proc pr_DaB_Replenish_PicksBySource

------------------------------------------------------------------------------*/
Create Procedure pr_DaB_Replenish_PicksBySource
as
begin
  SET NOCOUNT ON;

  select PickBatchNo, DestZone, vwPT_UDF1 Area, vwPT_UDF2, TaskDetailStatusDesc Status,
         count(distinct TaskId) Tasks, sum(Detailinnerpacks) Cases, sum(DetailQuantity) Units,
         Min(S.SortSeq) StatusSortSeq, 0 as DestZoneSortSeq, 0 as AreaSortSeq
  from vwPickTasks PT
        join Statuses S on (PT.TaskDetailStatus  = S.StatusCode  ) and
                           (PT.BusinessUnit      = S.BusinessUnit) and
                           (S.Entity             = 'Task'        )
  where (PickTicket like 'R%'   ) and
        (Archived = 'N' /* No */)
  group by PickBatchNo, DestZone, vwPT_UDF1, vwPT_UDF2, TaskDetailStatusDesc;

end /* pr_DaB_Replenish_PicksBySource */

Go
