/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/10  TK      pr_BoL_Recalculate: Initial Revision (S2GCA-970)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoL_Recalculate') is not null
  drop Procedure pr_BoL_Recalculate;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoL_Recalculate: Loops thru each BoL from the temp table and recounts it
------------------------------------------------------------------------------*/
Create Procedure pr_BoL_Recalculate
  (@BoLsToReCalculate    TEntityKeysTable readonly)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,

          @vRecordId           TRecordId,
          @vBoLId              TRecordId;
begin  /* pr_BoL_Recalculate */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Loop thru each Load and recount it */
  while exists(select * from @BoLsToReCalculate where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId = RecordId,
                   @vBoLId    = EntityId
      from @BoLsToReCalculate
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Invoke Proc to recount BoL */
      exec pr_BoL_Recount @vBoLId;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_BoL_Recalculate */

Go
