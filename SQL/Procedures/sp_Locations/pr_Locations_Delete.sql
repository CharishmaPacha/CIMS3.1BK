/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2010/11/26  PK      Modified file added Error Handler in pr_Locations_AddOrUpdate,
                        and Made to update Status to 'I' Inactive instead of deleting the record
                        in pr_Locations_Delete.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Delete') is not null
  drop Procedure pr_Locations_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Delete:
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Delete
  (@LocationId     TRecordId,
   @Location       TLocation)
as
begin
  SET NOCOUNT ON;

  update Locations
  set Status = 'I'/* Inactive */
  where (LocationId = @LocationId) or
        (Location   = @Location)
end /* pr_Locations_Delete */

Go
