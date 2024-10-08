/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/07  TK      pr_Allocation_AddPrintServiceRequests: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_AddPrintServiceRequests') is not null
  drop Procedure pr_Allocation_AddPrintServiceRequests;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_AddPrintServiceRequests issues print requests for Wave entity
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_AddPrintServiceRequests
  (@WaveId             TRecordId,
   @Operation          TOperation = null,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vOperation              TOperation,

          @vWaveId                 TRecordId,
          @vWaveNo                 TWaveNo;
begin /* pr_Allocation_AddPrintServiceRequests */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Wave Info */
  select @vWaveId = RecordId,
         @vWaveNo = BatchNo
  from Waves
  where (RecordId  = @WaveId);

 /* Trim unwanted string from operation */
 select @vOperation = right(@Operation, len(@Operation) - charindex('_', @Operation))

  /* Add print request for the wave */
  exec pr_Printing_EntityPrintRequest 'Allocation' /* Module */, @vOperation, 'Wave', @vWaveId, @vWaveNo, @BusinessUnit, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_AddPrintServiceRequests */

Go
