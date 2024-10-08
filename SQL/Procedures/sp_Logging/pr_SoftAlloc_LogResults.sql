/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SoftAlloc_LogResults') is not null
  drop Procedure pr_SoftAlloc_LogResults;
Go
/*------------------------------------------------------------------------------
  Proc pr_SoftAlloc_LogResults:
------------------------------------------------------------------------------*/
Create Procedure pr_SoftAlloc_LogResults
  (@Operation         TOperation,
   @OnHandInventory   TOnHandInventory       Readonly,
   @SAResults         TSoftAllocationDetails Readonly,
   @BatchNo           TBatch  output,
   @BusinessUnit      TBusinessUnit = null,
   @UserId            TUserId       = null)
as
  declare @vReturnCode  TInteger;
begin /* pr_SoftAlloc_LogResults */

  select @vReturnCode = 0,
         @BatchNo     = nullif(@BatchNo, 0);

  /* Get next batch no */
  if (@BatchNo is null)
    exec pr_Controls_GetNextSeqno 'SoftAlloc_LogResults', 1 /* SeqNoCount */,
                                  @UserId, @BusinessUnit, @BatchNo output;

  /* create persistant table if it does not exist and insert results into it */
  if object_id('tmp_SA_Results') is null
    select * into tmp_SA_Results from @SAResults;
  else
    insert into tmp_SA_Results
      select * from @SAResults;

  /* create persistant table if it does not exist and insert results into it */
  if object_id('tmp_SA_OnHandInv') is null
    select * into tmp_SA_OnHandInv from @OnHandInventory;
  else
    insert into tmp_SA_OnHandInv
      select * from @OnHandInventory;

  /* Update tmp tables with current BatchNo */
  update tmp_SA_Results
  set Operation = coalesce(Operation, @Operation),
      SABatchNo = @BatchNo
  where (SABatchNo is null);

  update tmp_SA_OnHandInv
  set Operation = coalesce(Operation, @Operation),
      SABatchNo = @BatchNo
  where (SABatchNo is null);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_SoftAlloc_LogResults */

Go
