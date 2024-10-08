/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/13  VS      pr_Locations_Recalculate, pr_Locations_UpdateCount: Passed EntityStatus Parameter (BK-910)
  2020/06/21  TK      pr_Locations_Recalculate: Initial Revision (HA-833)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Recalculate') is not null
  drop Procedure pr_Locations_Recalculate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Recalculate: Loops thru each Location from the temp table and recounts it
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Recalculate
  (@LocationsToRecalculate    TRecountKeysTable readonly,
   @UpdateOption              TFlag = '*',
   @BusinessUnit              TBusinessUnit)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,

          @vLocationId         TRecordId;
begin /* pr_Locations_Recalculate */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vLocationId  = 0;

  /* defer Location re-count for later */
  if (charindex('$', @UpdateOption) > 0)
    begin
      /* invoke RequestRecalcCounts to defer Location count updates */
      exec pr_Entities_RequestRecalcCounts 'Location', null, null, 'C'/* RecalcOption */,
                                           @@ProcId, null, @BusinessUnit, null /* EntityStatus */, @LocationsToRecalculate;

      goto ExitHandler;
    end

  /* Loop thru each Location and recount it */
  while exists(select * from @LocationsToRecalculate where EntityId > @vLocationId)
    begin
      select top 1 @vLocationId = EntityId
      from @LocationsToRecalculate
      where (EntityId > @vLocationId)
      order by EntityId;

      /* Invoke Proc to recount Location */
      exec pr_Locations_UpdateCount @vLocationId, null, @UpdateOption;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Locations_Recalculate */

Go
