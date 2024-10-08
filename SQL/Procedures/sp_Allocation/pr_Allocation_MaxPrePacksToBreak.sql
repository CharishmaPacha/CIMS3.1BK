/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/05/05  TK      pr_Allocation_ExplodePrepack & pr_Allocation_MaxPrePacksToBreak: Initial Revision (FB-648)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_MaxPrePacksToBreak') is not null
  drop Procedure pr_Allocation_MaxPrePacksToBreak;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_MaxPrePacksToBreak:
    This Procedure returns the number of Prepacks to be exploded to allocate an Order.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_MaxPrePacksToBreak
  (@SKUOrderDetailsToAllocate  TSKUOrderDetailsToAllocate READONLY,
   @SKUId                      TRecordId,
   @PrePackSKUId               TRecordId output,
   @MaxPrePacksToBreak         TQuantity = 0 output)
as
  declare @ReturnCode            TInteger,
          @MessageName           TMessageName,
          @Message               TDescription,

          @vRecordId             TRecordId;

  /* Temp Table */
  declare @ttPrePackDetails table (SKUId                     TRecordId,
                                   PrePackSKUId              TRecordId,

                                   UnitsToAllocate           TQuantity      DEFAULT 0,

                                   ComponentQty              TQuantity,
                                   NumPrePacks               as case when (UnitsToAllocate > 0) and (ComponentQty > 0)
                                                                       then ceiling(UnitsToAllocate * 1.0 / ComponentQty)
                                                                     else 0
                                                                end,

                                   RecordId                  TRecordId identity(1, 1));

begin
  SET NOCOUNT ON;

  select @ReturnCode         = 0,
         @MessageName        = null,
         @MaxPrePacksToBreak = 0;

  /* Get all the Orderlines which are for eaches */
  insert into @ttPrePackDetails(SKUId, PrePackSKUId, UnitsToAllocate, ComponentQty)
    select SOD.SKUId, SPP.MasterSKUId, sum(SOD.UnitsToAllocate), min(SPP.ComponentQty)
    from @SKUOrderDetailsToAllocate SOD
      left outer join SKUPrePacks SPP on (SOD.PrePackSKUId   = SPP.MasterSKUId) and
                                    (SOD.SKUId = SPP.ComponentSKUId) and
                                    (SPP.Status = 'A'/* Active */)
    where (SOD.PrePackSKUId = @PrePackSKUId)
    group by SPP.MasterSKUId, SOD.SKUId
    order by SPP.MasterSKUId;

   /* Return Max Number of PrePacks require to satisfy the order */
   select @MaxPrePacksToBreak  = max(NumPrePacks)
   from @ttPrePackDetails
   where (PrePackSKUId = @PrePackSKUId)
   group by PrePackSKUId
   order by PrePackSKUId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Allocation_MaxPrePacksToBreak */

Go
