/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/07/07  MS      pr_API_FinalizeResponses: Consider OnHold Printjobs and reset the status (BK-263)
  2021/08/03  OK      pr_API_FinalizeResponses: Initial Revision (BK-408)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FinalizeResponses') is not null
  drop Procedure pr_API_FinalizeResponses;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FinalizeResponses: This procedure will be run from a job for Carrier
    API integration to process all the waves after the API transaction responses
    are processed. This will call pr_Wave_UpdatePrintDependencies
    to evaluate the Print status of Tasks and waves.
------------------------------------------------------------------------------*/
Create Procedure pr_API_FinalizeResponses
  (@IntegrationName        TName,
   @APIWorkFlow            TCategory     = null,
   @BusinessUnit           TBusinessUnit = null,
   @UserId                 TUserId       = null)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vMessage                TMessage,
          @vRecordId               TRecordId,

          @vWaveId                 TRecordId;

  declare @ttWavesToEvaluate       TPrintEntities;
begin /* pr_API_FinalizeResponses */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId = 0;

  /* Create required temp tables */
  select * into #ttEntitiesToEvaluate from @ttWavesToEvaluate;

  /* Get the distinct waves of processed API outbound transactions for given Integration to evaluate the print status */
  insert into #ttEntitiesToEvaluate (EntityId, Entitykey, EntityType)
    select distinct L.PickBatchId, L.PickBatchNo, 'Wave'
    from APIOutboundTransactions APIOT
      join LPNs  L on (APIOT.EntityId = case when APIOT.EntityType = 'LPN'   then L.LPNId
                                             when APIOT.EntityType = 'Order' then L.OrderId
                                             when APIOT.EntityType = 'Wave'  then L.PickBatchId  -- Future use
                                        end)
      join PrintJobs PJ on (PJ.EntityId = case when PJ.EntityType = 'Order' then L.OrderId
                                               when PJ.EntityType = 'Wave'  then L.PickBatchId
                                          end)
    where (APIOT.IntegrationName = @IntegrationName) and
          (APIOT.APIWorkFlow     = coalesce(@APIWorkFlow, APIOT.APIWorkFlow)) and
          (APIOT.ProcessStatus   = 'Processed') and
          (APIOT.Archived        = 'N') and
          (APIOT.BusinessUnit    = @BusinessUnit) and
          (PJ.PrintJobStatus     = 'O' /* On-Hold */)

  if (exists (select * from #ttEntitiesToEvaluate))
    exec pr_PrintJobs_EvaluatePrintStatus @BusinessUnit, @UserId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FinalizeResponses */

Go
