/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/22  MS      pr_Printing_CreatePrintJobs: Enhanced changes to use PrintJobDetails
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_GroupPrintJobDetails') is not null
  drop Procedure pr_Printing_GroupPrintJobDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printing_GroupPrintJobDetails: Evaluates #PrintJobDetails and groups
    them together and creates entries in #PrintJobs.

  #PrintJobDetails : PrintJobDetails
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_GroupPrintJobDetails
  (@NumDetailsPerJob   TQuantity)
as
declare @vEntityId           TRecordId,
        @vEntityType         TTypecode,
        @vEntityKey          TEntityKey,

        @vPrintJobType       TDescription,
        @vPrintJobOperation  TName,
        @vPrintRequestId     TRecordId,
        @vThreshold          TQuantity,
        @vNumJobsToCreate    TCount,
        @vJobsCreated        TCount;
begin /* pr_Printing_GroupPrintJobDetails */
  SET NOCOUNT ON;

  select @NumDetailsPerJob   = coalesce(@NumDetailsPerJob, 99999),
         @vJobsCreated = 0; --Initiate

  if not exists(select * from #PrintJobDetails) return;

  /*----------Sequence the PrintjobDetails --------*/
  /* Setup SeqIdex for #PrintJobDetails */
  ;with SeqIndexUpdate (EntityId, EntityKey, SeqIndex)
  as
  (
   select PJD.EntityId, PJD.ParentEntityKey, row_number() over(partition by PJD.ParentEntityKey order by PJD.EntityId, newid()) As SeqIndex
   from #PrintJobDetails PJD
  )
  update PJD
  set SeqIndex = SI.SeqIndex
  from SeqIndexUpdate SI
    join #PrintJobDetails PJD on (SI.EntityId = PJD.EntityId);

  /*----------Split the PrintjobDetails into printjobs --------*/

  /* Divide the available details into several print jobs each with NumDetailsPerJob - approximately */
  if (@NumDetailsPerJob > 0)
    update PJD
    set PJD.PrintJobNumber = ceiling(PJD.SeqIndex * 1.0 / @NumDetailsPerJob)
    from #PrintJobDetails PJD

  /*------------------------------------------------------------------------------------------*/
  select @vNumJobsToCreate = count(distinct(PrintJobNumber)) from #PrintJobDetails;

  select top 1 @vPrintJobType      = PrintJobType,
               @vPrintJobOperation = PrintJobOperation,
               @vPrintRequestId    = PrintRequestId,
               @vEntityType        = ParentEntityType,
               @vEntityId          = ParentEntityId,
               @vEntityKey         = ParentEntityKey
  from #PrintJobDetails

  insert into #PrintJobs(PrintRequestId, PrintJobType, PrintJobOperation, EntityType, EntityId, EntityKey)
    select @vPrintRequestId, @vPrintJobType, @vPrintJobOperation, @vEntityType, @vEntityId, @vEntityKey
    from fn_GenerateSequence (1, @vNumJobsToCreate, null);

end /* pr_Printing_GroupPrintJobDetails */

Go
