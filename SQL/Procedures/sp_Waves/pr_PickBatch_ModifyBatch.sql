/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/02/06  SP      pr_PickBatch_ModifyBatch:Added validation for batches in  canceled, shipped, completed  statuses.
  2012/10/17  SP      "pr_PickBatch_ModifyBatch" corrected the "UDF1" to "UDF3".
  2012/10/15  SP      Added "pr_PickBatch_ModifyBatch".
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_ModifyBatch') is not null
  drop Procedure pr_PickBatch_ModifyBatch;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_ModifyBatch:
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_ModifyBatch
  (@BatchNo          TPickBatchNo,
   @BatchType        TTypeCode,
   @PickDate         TDate,
   @ShipDate         TDate,
   @Description      TDescription,
   @Priority         TPriority,
   @UDF3             TUDF,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @Message          TMessage output)
as
  declare @ReturnCode            TInteger,
          @MessageName           TMessageName,

          @vBatchId              TRecordId,
          @vStatus               TStatus,
          @vInvalidBatchStatuses TStatus;
begin /* pr_PickBatch_ModifyBatch */
begin try
  /* Fetching of batch Information */
  select  @vBatchId  = RecordId,
          @vStatus   = Status
  from PickBatches
  where (BatchNo      = @BatchNo) and
        (BusinessUnit = @BusinessUnit);

  /* Fetch the valid batch status */
  select @vInvalidBatchStatuses = dbo.fn_Controls_GetAsString('ModifyBatch', 'InvalidBatchStatus', 'XSD' /* Canceled, Shipped, Completed */, @BusinessUnit, @UserId);

  /* Validations */
  if (@vBatchId is null)
    set @MessageName = 'BatchIsInvalid';
  else
  if (charindex(@vStatus, @vInvalidBatchStatuses) > 0)
    set @MessageName = 'ModifyBatch_InvalidStatus';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Updating  Wave */
  update Waves
  set BatchType    = @BatchType,
      WaveType     = @BatchType,
      PickDate     = @PickDate,
      ShipDate     = @ShipDate,
      Description  = @Description,
      Priority     = @Priority,
      UDF3         = @UDF3,
      ModifiedBy   = @UserId,
      ModifiedDate = current_timestamp
  where (RecordId  = @vBatchId);

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

end try
begin catch

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_PickBatch_ModifyBatch */

Go
