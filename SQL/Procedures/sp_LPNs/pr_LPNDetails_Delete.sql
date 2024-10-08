/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/30  RT      pr_LPNDetails_Delete: Considering only LPNDetailId, as we are not using LPNLine, all the Details are getting deleted (FB-1484)
  2010/11/04  PK      Created pr_LPNDetails_AddOrUpdate, pr_LPNDetails_Delete,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_Delete') is not null
  drop Procedure pr_LPNDetails_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_Delete:
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_Delete
  (@LPNDetailId  TRecordId)
as
begin
  SET NOCOUNT ON;

  delete
  from LPNDetails
  where (LPNDetailId = @LPNDetailId);
end /* pr_LPNDetails_Delete */

Go
