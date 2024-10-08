/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/07/14  SV      pr_ReceiptHeaders_TransformToPrepacks: Bug fix - resolved the issue of importing RDs with QtyToReceive as 0 (FB-727).
  2016/04/16  TK      pr_ReceiptHeaders_TransformToPrepacks: Consider SKUPrePack Status (FB-672)
  2016/04/01  AY      pr_ReceiptHeaders_TransformToPrepacks: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptHeaders_TransformToPrepacks') is not null
  drop Procedure pr_ReceiptHeaders_TransformToPrepacks;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptHeaders_TransformToPrepacks: This Procedure converts Receipts in Eaches
      into multiple of PrePacks and creates a new PrePack line.
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptHeaders_TransformToPrepacks
  (@ReceiptId        TRecordId,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,

          @vPrePackSKUId      TRecordId,
          @vMaxPrepacks       TQuantity,
          @vReceiptLine       TDetailLine,
          @vOwnership         TOwnership;

  /* Temp Table */
  declare @ttOrigReceiptDetails table (ReceiptDetailId           TRecordId,
                                       OrigSKUId                 TRecordId,
                                       LineType                  TTypeCode,

                                       QtyOrdered                TQuantity      DEFAULT 0,
                                       OrigQtyOrdered            TQuantity      DEFAULT 0,

                                       PrePackSKUId              TRecordId,
                                       ComponentSKUId            TRecordId,

                                       ComponentQty              TQuantity,
                                       NumPrePacks               as case when (QtyOrdered > 0) and (ComponentQty > 0)
                                                                           then floor(QtyOrdered / ComponentQty)
                                                                         else 0
                                                                    end,
                                       Ownership                 TOwnership,

                                       RecordId                  TRecordId identity(1, 1));
begin
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vPrePackSKUId = 0,
         @UserId        = 'CIMS'; /* Need to hardcode to figure out that the new lines are created by CIMS */

  /* Get all the Receipt Details which are for eaches and .. */
  insert into @ttOrigReceiptDetails(ReceiptDetailId, OrigSKUId, QtyOrdered, OrigQtyOrdered,
                                    PrePackSKUId, ComponentSKUId, ComponentQty, Ownership)
    select ROD.ReceiptDetailId, ROD.SKUId, ROD.QtyOrdered, ROD.QtyOrdered,
           S.SKUId, SPP.ComponentSKUId, SPP.ComponentQty, ROD.Ownership
    from ReceiptDetails ROD
      join SKUs S                on (ROD.UDF4 = S.SKU)
      right join SKUPrePacks SPP on (SPP.MasterSKUId    = S.SKUId)   and
                                    (SPP.ComponentSKUId = ROD.SKUId) and
                                    (SPP.Status = 'A' /* Active */)
    where (ROD.ReceiptId = @ReceiptId)
    order by S.SKUId;

  /* Delete the lines if all components of the SKU are not represented i.e. if the Receipt has only 2 items
     and the SKUPrepack has 3 components, then discard those lines - It shouldn't be sent from host
     that way, but better be cautious.

     if the Prepack has S, M, L, but the order came down only with S & M, then we cannot convert this
     to pre-pack.
  */
  delete from @ttOrigReceiptDetails
  where PrePackSKUId in
    (select distinct MasterSKUId
     from (select *
           from SKUPrePacks where MasterSKUId in (select distinct PrePackSKUId from @ttOrigReceiptDetails) and
                                  Status = 'A' /* Active */
          ) SPP
          left outer join @ttOrigReceiptDetails ROD on SPP.MasterSKUId = ROD.PrepackSKUId and SPP.ComponentSKUId = ROD.OrigSKUId
     where OrigSKUId is null)

  /* If any of the component SKUs cannot be converted to prepacks then delete all lines of the prepack.
     For example, if Prepack is S-2, M-5 and L-2 and Order details are for 3, 3 & 3 units respectively
     then NumPrePacks need to satisfy are 1, 0 & 1. So, in summary we cannot take even one pre-pack */
  delete from @ttOrigReceiptDetails
  where PrePackSKUId in (select distinct PrePackSKUId from @ttOrigReceiptDetails where NumPrePacks = 0);

  /* Insert pre-pack lines for the order detail from what remains */
  while exists(select * from @ttOrigReceiptDetails where PrePackSKUId > @vPrePackSKUId)
    begin
      /* Get the min number of Prepacks that can be Shipped against given order */
      select top 1 @vMaxPrepacks  = min(NumPrePacks),
                   @vPrePackSKUId = PrePackSKUId,
                   @vOwnership    = min(Ownership)
      from @ttOrigReceiptDetails
      where (PrePackSKUId > @vPrePackSKUId)
      group by PrePackSKUId
      order by PrePackSKUId;

      /* Get the max Order Line */
      select @vReceiptLIne = max(coalesce(ReceiptLine, 0)) + 1
      from ReceiptDetails
      where (ReceiptId = @ReceiptId);

      /* Insert min number PrePacks that can be shipped for the Order */
      insert into ReceiptDetails(SKUId, ReceiptId, ReceiptLine, HostReceiptLine, QtyOrdered, Ownership,
                                 BusinessUnit, CreatedBy, CreatedDate)
        select @vPrePackSKUId, @ReceiptId, @vReceiptLine, '$'/* HostReceiptLine */, @vMaxPrepacks /* QtyOrdered */, @vOwnership,
               @BusinessUnit, @UserId, current_timestamp;

      /* After creating a PrePack Line reduce the UnitsAuthorizedToShip against its Component SKU */
      update ROD
      set ROD.QtyOrdered = ttOD.QtyOrdered - (@vMaxPrepacks * ttOD.ComponentQty)
      from @ttOrigReceiptDetails ttOD
        join ReceiptDetails ROD on (ttOD.ComponentSKUId = ROD.SKUId) and (ROD.ReceiptId = @ReceiptId)
      where (PrePackSKUId = @vPrePackSKUId);

      /* Recompute ExtraQtyAllowed on all lines */
      update ReceiptDetails
      set ExtraQtyallowed = cast(((QtyOrdered * (dbo.fn_Controls_GetAsinteger('Receipts', 'OverReceiptPercent', '5', @BusinessUnit, @UserId))) /100) as Int)
      where (ReceiptId = @ReceiptId);
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ReceiptHeaders_TransformToPrepacks */

Go
