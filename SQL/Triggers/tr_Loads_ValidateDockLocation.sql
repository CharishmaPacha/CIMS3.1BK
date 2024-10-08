/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('tr_Loads_ValidateDockLocation') is not null
  drop Trigger tr_Loads_ValidateDockLocation;
Go
/*------------------------------------------------------------------------------
  Trigger tr_Loads_ValidateDockLocation: This trigger on Load ensures that there is no other open Load
     for a Dock which is  being assigned for new Load
------------------------------------------------------------------------------*/
Create Trigger tr_Loads_ValidateDockLocation on Loads After Insert, Update
As
  declare @ttLoadsToEvaulate  TEntityKeysTable;
begin
  /* Get all Loads to Validate */
  insert into @ttLoadsToEvaulate (EntityId, EntityKey)
    select distinct INS.LoadId, INS.DockLocation
    from Inserted INS
      join Loads  ELoad on (INS.DockLocation = ELoad.DockLocation) -- existing Load
    where (ELoad.Status not in ('S', 'X' /* Shipped,Canceled */));

  if (@@rowcount > 0)
    begin
      RAISERROR  ('Cannot have multiple Loads assigned to single Dock',-1,-1)
      rollback transaction;
    end

end /* tr_Loads_ValidateDockLocation */

Go

/* Need to comment following code if this validation is necessary for any client */
drop Trigger tr_Loads_ValidateDockLocation;

Go

