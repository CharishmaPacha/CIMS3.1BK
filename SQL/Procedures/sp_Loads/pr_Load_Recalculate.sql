/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/10  TK      pr_Load_Recalculate: Initial Revision (S2GCA-970)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_Recalculate') is not null
  drop Procedure pr_Load_Recalculate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_Recalculate: Loops thru each load from the temp table and recounts it
------------------------------------------------------------------------------*/
Create Procedure pr_Load_Recalculate
  (@LoadsToReCalculate    TEntityKeysTable readonly)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,

          @vRecordId           TRecordId,
          @vLoadId             TRecordId;
begin  /* pr_Load_Recalculate */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Loop thru each Load and recount it */
  while exists(select * from @LoadsToReCalculate where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId = RecordId,
                   @vLoadId   = EntityId
      from @LoadsToReCalculate
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Invoke Proc to recount Load */
      exec pr_Load_Recount @vLoadId;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Load_Recalculate */

Go
