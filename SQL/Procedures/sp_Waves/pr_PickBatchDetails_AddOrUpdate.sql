/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatchDetails_AddOrUpdate') is not null
  drop Procedure pr_PickBatchDetails_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatchDetails_AddOrUpdate:
    This procedure will create new records or will update existing record in pickbatchdetails

------------------------------------------------------------------------------*/
Create Procedure pr_PickBatchDetails_AddOrUpdate
  (@PickBatchId       TTypeCode,
   @PickBatchNo       TPickbatchNo = null,
   @OrderId           TPriority,
   @OrderDetailId     TShipVia,
   @Status            TStatus,
   @RuleId            TRecordId,
   @BusinessUnit      TBusinessUnit,
   -----------------------------------------------
   @RecordId          TRecordId        output,
   @CreatedDate       TDateTime = null output,
   @ModifiedDate      TDateTime = null output,
   @CreatedBy         TUserId   = null output,
   @ModifiedBy        TUserId   = null output)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription;

begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null,
         @Status      = coalesce(@Status, 'W' /* Batched */);

  /* Need  Validations */
  if (@BusinessUnit is null)
    set @MessageName = 'InvalidBusinessUnit';

  if (@MessageName is not null)
    goto ErrorHandler;

  if (coalesce(@RecordId, 0) = 0)
    begin
        /*if RecordId is null then it will insert.Ie.. add new one.  */
      insert into PickBatchDetails(PickBatchId,
                                   PickBatchNo,
                                   WaveId,
                                   WaveNo,
                                   OrderId,
                                   OrderDetailId,
                                   Status,
                                   RuleId,
                                   BusinessUnit,
                                   CreatedBy,
                                   CreatedDate )
                          select
                                   @PickBatchId,
                                   @PickBatchNo,
                                   @PickBatchId,
                                   @PickBatchNo,
                                   @OrderId,
                                   @OrderDetailId,
                                   @Status,
                                   @RuleId,
                                   @BusinessUnit,
                                   coalesce(@CreatedBy, System_user),
                                   coalesce(@CreatedDate, current_timestamp);
    end
  if (@ReturnCode = 0)
    goto ExitHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_PickBatchDetails_AddOrUpdate */

Go
