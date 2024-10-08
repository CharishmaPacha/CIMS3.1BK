/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_GetAllLines') is not null
  drop Procedure pr_LPNDetails_GetAllLines;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_GetAllLines:
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_GetAllLines
  (@LPNId  TRecordId,
   @LPN    TLPN)
as
begin
  select *
  from vwLPNDetails
  where ((LPNId = @LPNId) or
         (LPN   = @LPN))
  order by LPNDetailId;
end /* pr_LPNDetails_GetAllLines */

Go
