/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_GetAll') is not null
  drop Procedure pr_Locations_GetAll;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_GetAll:
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_GetAll
  (@LocationId     TRecordId,
   @PiLocation       TLocation)
as
begin
  select *
  from vwLocations
end /* pr_Locations_GetAll */

Go
