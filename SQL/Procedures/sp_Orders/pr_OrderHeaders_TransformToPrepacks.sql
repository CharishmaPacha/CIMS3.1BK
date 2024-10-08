/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/04/16  TK      pr_OrderHeaders_TransformToPrepacks: Consider SKUPrePack Status (FB-672)
  2016/03/30  TK/AY   pr_OrderHeaders_TransformToPrepacks: Initial Revision (FB-642)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_TransformToPrepacks') is not null
  drop Procedure pr_OrderHeaders_TransformToPrepacks;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_TransformToPrepacks: This Procedure converts Orders in Eaches
      into multiple of PrePacks and creates a new PrePack line.
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_TransformToPrepacks
  (@OrderId          TRecordId,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,

          @vPrePackSKUId      TRecordId,
          @vMaxPrepacks       TQuantity,
          @vOrderLine         TDetailLine;

  /* Temp Table */
  declare @ttOrigOrderDetails table (OrderDetailId             TRecordId,
                                     OrigSKUId                 TRecordId,
                                     LineType                  TTypeCode,

                                     UnitsOrdered              TQuantity      DEFAULT 0,
                                     UnitsAuthorizedToShip     TQuantity      DEFAULT 0,
                                     OrigUnitsAuthorizedToShip TQuantity      DEFAULT 0,

                                     PrePackSKUId              TRecordId,
                                     ComponentSKUId            TRecordId,

                                     ComponentQty              TQuantity,
                                     NumPrePacks               as case when (UnitsAuthorizedToShip > 0) and (ComponentQty > 0)
                                                                         then floor(UnitsAuthorizedToShip / ComponentQty)
                                                                       else 0
                                                                  end,

                                     RecordId                  TRecordId identity(1, 1));
begin
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vPrePackSKUId = 0;

  /* Get all the Orderlines which are for eaches and .. */
  insert into @ttOrigOrderDetails(OrderDetailId, OrigSKUId, LineType, UnitsOrdered, UnitsAuthorizedToShip,
                                  OrigUnitsAuthorizedToShip, PrePackSKUId, ComponentSKUId, ComponentQty)
    select OD.OrderDetailId, OD.SKUId, OD.LineType, OD.UnitsOrdered, OD.UnitsAuthorizedToShip,
           OD.OrigUnitsAuthorizedToShip, S.SKUId, SPP.ComponentSKUId, SPP.ComponentQty
    from OrderDetails OD
      join SKUs S                on (OD.UDF4 = S.SKU)
      right join SKUPrePacks SPP on (SPP.MasterSKUId    = S.SKUId)  and
                                    (SPP.ComponentSKUId = OD.SKUId) and
                                    (SPP.Status = 'A'/* Active */)
    where (OD.OrderId = @OrderId) and
          ((OD.LineType is null) or (OD.LineType <> 'F' /* Fees */))
    order by S.SKUId;

  /* Delete the lines if all components of the SKU are not represented i.e. if the Order has only 2 items
     and the SKUPrepack has 3 components, then discard those lines - It shouldn't be sent from host
     that way, but better be cautious.

     if the Prepack has S, M, L, but the order came down only with S & M, then we cannot convert this
     to pre-pack.
  */
  delete from @ttOrigOrderDetails
  where PrePackSKUId in
    (select distinct MasterSKUId
     from (select *
           from SKUPrePacks where MasterSKUId in (select distinct PrePackSKUId from @ttOrigOrderDetails) and
                                  Status = 'A' /* Active */
          ) SPP
          left outer join @ttOrigOrderDetails OD on SPP.MasterSKUId = OD.PrepackSKUId and SPP.ComponentSKUId = OD.OrigSKUId
     where OrigSKUId is null)

  /* If any of the component SKUs cannot be converted to prepacks then delete all lines of the prepack.
     For example, if Prepack is S-2, M-5 and L-2 and Order details are for 3, 3 & 3 units respectively
     then NumPrePacks need to satisfy are 1, 0 & 1. So, in summary we cannot take even one pre-pack */
  delete from @ttOrigOrderDetails
  where PrePackSKUId in (select distinct PrePackSKUId from @ttOrigOrderDetails where NumPrePacks = 0);

  /* Insert pre-pack lines for the order detail from what remains */
  while exists(select * from @ttOrigOrderDetails where PrePackSKUId > @vPrePackSKUId)
    begin
      /* Get the min number of Prepacks that can be Shipped against given order */
      select top 1 @vMaxPrepacks  = min(NumPrePacks),
                   @vPrePackSKUId = PrePackSKUId
      from @ttOrigOrderDetails
      where (PrePackSKUId > @vPrePackSKUId)
      group by PrePackSKUId
      order by PrePackSKUId;

      /* Get the max Order Line */
      select @vOrderLine = max(coalesce(OrderLine, 0)) + 1
      from OrderDetails
      where (OrderId = @OrderId);

      /* Insert min number PrePacks that can be shipped for the Order */
      insert into OrderDetails(SKUId, OrderId, OrderLine, HostOrderLine, UnitsOrdered, UnitsAuthorizedToShip,
                               OrigUnitsAuthorizedToShip, BusinessUnit, CreatedBy, CreatedDate)
        select @vPrePackSKUId, @OrderId, @vOrderLine, ''/* HostOrderLine */, @vMaxPrepacks /* UnitsOrdered */, @vMaxPrepacks /* UATS */,
               @vMaxPrepacks /* OUATS */, @BusinessUnit, @UserId, current_timestamp;

      /* After creating a PrePack Line reduce the UnitsAuthorizedToShip against its Component SKU */
      update OD
      set OD.UnitsAuthorizedToShip = ttOD.UnitsAuthorizedToShip - (@vMaxPrepacks * ttOD.ComponentQty),
          OD.LineType              = coalesce(OD.LineType, '') + '$'  -- to indicate that line is transformed to PPs
      from @ttOrigOrderDetails ttOD
        join OrderDetails OD on (ttOD.ComponentSKUId = OD.SKUId)
      where (PrePackSKUId = @vPrePackSKUId);
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_TransformToPrepacks */

Go
