/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_CartCubing_FindCartType') is not null
  drop Procedure pr_Allocation_CartCubing_FindCartType;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_CartCubing_FindCartType: This procedure returns Cart Type to cube task
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_CartCubing_FindCartType
  (@WaveId            TRecordId,
   @CartType          TTypeCode    output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,

          @vControlCategory     TCategory,
          @vBusinessUnit        TBusinessUnit;
begin /* pr_Allocation_CartCubing_FindCartType */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Wave Info */
  select @vControlCategory = 'Wave_' + BatchType,
         @vBusinessUnit    = BusinessUnit
  from Waves
  where (RecordId = @WaveId);

  /* Get Cart Type from Controls */
  select @CartType = dbo.fn_Controls_GetAsString(@vControlCategory, 'CartTypeToCube', 'C1', @vBusinessUnit, null /* UserId */);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_CartCubing_FindCartType */

Go
