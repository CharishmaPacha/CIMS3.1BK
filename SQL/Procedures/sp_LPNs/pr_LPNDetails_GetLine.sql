/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_GetLine') is not null
  drop Procedure pr_LPNDetails_GetLine;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_GetLine:
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_GetLine
  (@LPNId        TRecordId,
   @LPN          TLPN,
   @LPNDetailId  TRecordId,
   @LPNLine      TDetailLine)
as
begin
  select *
  from vwLPNDetails
  where (((LPNId = @LPNId) or
          (LPN   = @LPN)) and
         ((LPNDetailId = @LPNDetailId) or
          (LPNLine     = @LPNLine)))
  order by LPNDetailId;
end /* pr_LPNDetails_GetLine */

Go
