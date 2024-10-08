/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/04/03  VS      fn_Pickbatch_IsBulkBatch: If it is not Bulk Wave return 'N' (CID-247)
  2019/02/19  TK      fn_Pickbatch_IsBulkBatch: Code Revamp (S2GCA-465)
  2015/10/17  DK      fn_Pickbatch_IsBulkBatch: Addded function fn_Pickbatch_IsBulkBatch (FB-440).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Pickbatch_IsBulkBatch') is not null
  drop Function fn_Pickbatch_IsBulkBatch;
Go
/*------------------------------------------------------------------------------
  Proc fn_Pickbatch_IsBulkBatch:
------------------------------------------------------------------------------*/
Create Function fn_Pickbatch_IsBulkBatch
  (@WaveId      TRecordId)
  -------------------
   returns      TFlag
as
begin
  declare @vIsBulkPullBatch TFlag;

  if exists(select * from OrderHeaders where PickBatchId = @WaveId and OrderType = 'B'/* Bulk Pull */)
    set @vIsBulkPullBatch = 'Y'/* Yes */
  else
    set @vIsBulkPullBatch = 'N'/* No */;

  return(@vIsBulkPullBatch);
end /* fn_Pickbatch_IsBulkBatch */

Go
