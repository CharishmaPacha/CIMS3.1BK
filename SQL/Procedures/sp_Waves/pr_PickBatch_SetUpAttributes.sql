/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/04/10  TD      Added pr_PickBatch_SetUpAttributes.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_SetUpAttributes') is not null
  drop Procedure pr_PickBatch_SetUpAttributes;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_SetUpAttributes
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_SetUpAttributes
  (@PickBatchId    TRecordId,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @Message           TDescription,

          @vCreatedDate      TDateTime,
          @vWaveId           TRecordId,
          @vWaveNo           TWaveNo,
          @vWaveType         TTypeCode,
          @vWarehouse        TWarehouse,
          @vIsReplenish      TFlags,

          /* controls related */
          @vControlCategory       TCategory,
          @vDefaultDestination    TName,
          @vAvgUnitsPerOrder      TControlValue,
          @vUnitsPerLine          TControlValue,
          @vNumSKUOrdersPerBatch  TControlValue;
begin
  select @vCreatedDate = current_timestamp,
         @ReturnCode   = 0;

  /* Assumption: Caller will handle validations */
  select @vWaveNo          = WaveNo,
         @vWaveId          = WaveId,
         @vWaveType        = WaveType,
         @vWarehouse       = Warehouse,
         @vControlCategory = 'PickBatch_' + BatchType,
         @vIsReplenish     = case
                               when BatchType in ('RU', 'RP', 'R') then 'NA'
                               else 'N'
                             end
  from Waves
  where (WaveId = @PickBatchId);

  if (@vWaveNo is null)
    return;

  /* Get default values from Controls here */
  select @vAvgUnitsPerOrder     = dbo.fn_Controls_GetAsString(@vControlCategory, 'AvgUnitsPerOrder', '20', @BusinessUnit, null /* UserId */),
         @vUnitsPerLine         = dbo.fn_Controls_GetAsString(@vControlCategory, 'UnitsPerLine', '10', @BusinessUnit, null /* UserId */),
         @vNumSKUOrdersPerBatch = dbo.fn_Controls_GetAsString(@vControlCategory, 'NumSKUOrdersPerBatch', '10', @BusinessUnit, null /* UserId */),
         @vDefaultDestination   = dbo.fn_Controls_GetAsString(@vControlCategory, 'DefaultDestination', 'RMS', @BusinessUnit, null /* UserId */);

  /* insert the data into table here  */
  insert into PickBatchAttributes (PickBatchId,
                                   PickBatchNo,
                                   AvgUnitsPerOrder,
                                   UnitsPerLine,
                                   NumSKUOrdersPerBatch,
                                   DefaultDestination,
                                   IsReplenished,
                                   Warehouse,
                                   BusinessUnit,
                                   CreatedDate,
                                   CreatedBy)
                            values(@vWaveId,
                                   @vWaveNo,
                                   @vAvgUnitsPerOrder,
                                   @vUnitsPerLine,
                                   @vNumSKUOrdersPerBatch,
                                   @vDefaultDestination,
                                   @vIsReplenish,
                                   @vWarehouse,
                                   @BusinessUnit,
                                   @vCreatedDate,
                                   @UserId);

ErrorHandler:
 if (@MessageName is not null)
   exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));

end /* pr_PickBatch_SetUpAttributes */

Go
