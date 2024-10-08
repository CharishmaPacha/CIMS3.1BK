/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DaB_Replenish_PickingStatus') is not null
  drop Procedure pr_DaB_Replenish_PickingStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_DaB_Replenish_PickingStatus
------------------------------------------------------------------------------*/
Create Procedure pr_DaB_Replenish_PickingStatus
as
begin
  SET NOCOUNT ON;

  (
   select PickBatchNo, DestZone,TaskStatusDesc, vwPT_UDF1 Area, vwPT_UDF2, Min(S.SortSeq) SortSeq,
          Min(TaskStatusDesc) as Status,
          count(distinct TaskId) Tasks, sum(DetailInnerPacks) Cases, sum(DetailQuantity) Units,
          0 DestZoneSortSeq, 0 AreaSortSeq
   from vwPickTasks PT
        join Statuses S on (PT.TaskStatus   = S.StatusCode  ) and
                           (PT.BusinessUnit = S.BusinessUnit) and
                           (S.Entity        = 'Task'        )
   where (PT.PickTicket like 'R%'   ) and
         (PT.Archived = 'N' /* No */)
   group by PickBatchNo, DestZone, TaskStatusDesc, vwPT_UDF1, vwPT_UDF2
   )
   union All
   (
    select distinct PickBatchNo, DestZone,TaskStatusDesc, vwPT_UDF1 Area, vwPT_UDF2, S.SortSeq SortSeq,
           StatusDescription as Status,
           0 Tasks, 0 Cases,0 Units,
           0 DestZoneSortSeq, 0 AreaSortSeq
    from Statuses S
        join vwPickTasks PT on (PT.TaskStatus   = S.StatusCode  ) and
                               (PT.BusinessUnit = S.BusinessUnit) and
                               (S.Entity        = 'Task'        )
   where (PT.PickTicket like 'R%'   ) and
         (PT.Archived = 'N' /* No */)
   )
end /* pr_DaB_Replenish_PickingStatus */

Go
