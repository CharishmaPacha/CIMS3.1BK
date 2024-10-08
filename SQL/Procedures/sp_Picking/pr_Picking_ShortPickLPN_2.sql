/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ShortPickLPN_2') is not null
  drop Procedure pr_Picking_ShortPickLPN_2;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_ShortPickLPN_2: This procedure will be called when the user does
   a Short Pick due to inventory not being at or in the Location

    First we will unallocate all the lines reserved for any order.

    If the LPN is Picklane (Logical) type then we will update that qty to 0,
     else we will mark the LPN as Lost.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_ShortPickLPN_2
  (@LPNId           TRecordId,
   @SKUId           TRecordId,
   @OrderId         TRecordId,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @ReturnCode     TInteger,
          @CCMessage      TDescription,
          @MessageName    TMessageName,
          @vMessage       TDescription,

          @vRecordId      TRecordId,
          @vLPNId         TRecordId,
          @vSKUId         TRecordId,
          @vLPNDetailId   TRecordId,
          @vLPN           TLPN;

  /* temp table   declarations */
  declare @ttLPNDetails table (RecordId     TRecordId identity(1,1),
                               LPNId        TRecordId,
                               SKUId        TRecordId,
                               LPNDetailId  TRecordId);

begin /* pr_Picking_ShortPickLPN */

  select @ReturnCode  = 0,
         @vRecordId   = 0,
         @MessageName = null;

  /* Get all LPNDetails for the Order for the short picked SKU */
  insert into @ttLPNDetails (LPNId, SKUId, LPNDetailId)
    select LPNId, SKUId, LPNDetailId
    from LPNDetails
    where (LPNId   = @LPNId) and
          (SKUId   = @SKUId) and
          (OrderId = @OrderId);

  /* Loop through all the allocated detail lines of the order for that SKU to
     cancel the picks etc */
  while (exists (select * from @ttLPNDetails where RecordId > @vRecordId))
    begin
      /* Get the top 1 record from the temp table */
      select top 1 @vRecordId    = RecordId,
                   @vLPNId       = LPNId,
                   @vSKUId       = SKUId,
                   @vLPNDetailId = LPNDetailId
      from @ttLPNDetails
      where (RecordId > @vRecordId)
      order by RecordId

      /* Call pr_Picking_ShortPickLPN for each detail line */
      exec pr_Picking_ShortPickLPN @vLPNId, @vLPNDetailId, @vSKUId,
                                   @BusinessUnit, @UserId;
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Picking_ShortPickLPN_2 */

Go
