/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/08/04  TD      Added pr_PickBatchRules_AddOrUpdate, pr_PickBatch_Update
                      and pr_PickBatchRules_SwapSortseq
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatchRules_SwapSortseq') is not null
  drop Procedure pr_PickBatchRules_SwapSortseq;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatchRules_SwapSortseq:
    This proc will call when user wants to swap sortseq no from UI.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatchRules_SwapSortseq
  (@CurrentRuleId    TRecordId,
   @SwapRuleId       TRecordId)
as
  declare @ReturnCode     TInteger,
          @MessageName    TMessageName,
          @Message        TDescription,
          @CurSortSeqNum  TSortSeq,
          @SwapSortSeqNum TSortSeq;

begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null;

  /* Need  Validations */
  if (@CurrentRuleId is null)
    set @MessageName = 'InvalidCurrentRuleId';
  else
  if (@SwapRuleId is null)
    set @MessageName = 'InvalidSwapRuleId';

  select @CurSortSeqNum  = (select SortSeq from  PickBatchRules where (RuleId = @CurrentRuleId)),   /* It will return Sortseq no for currentRuleId */
         @SwapSortSeqNum = (select SortSeq from  PickBatchRules where (RuleId = @SwapRuleId));       /* It will return Sortseq no for Next Or Previous */

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Swap the seqnos */
  update PickBatchRules
  set SortSeq =  @SwapSortSeqNum
  where(RuleId = @CurrentRuleId);

  update PickBatchRules
  set  SortSeq = @CurSortSeqNum
  where(RuleId = @SwapRuleId);

  if (@ReturnCode = 0)
    goto ExitHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_PickBatchRules_SwapSortseq */

Go
