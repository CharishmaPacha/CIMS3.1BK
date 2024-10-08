/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Get') is not null
  drop Procedure pr_Locations_Get;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Get:
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Get
  (@LocationId     TRecordId,
   @Location       TLocation)
as
begin
  select *
  from vwLocations
  where (Location = @Location) or
        (LocationId = @LocationId);
end /* pr_Locations_Get */

Go
