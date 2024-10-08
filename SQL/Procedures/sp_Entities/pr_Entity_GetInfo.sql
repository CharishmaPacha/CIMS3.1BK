/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/30  RV      pr_Entity_GetInfo: Included ReceiptHeader (FBV3-265)
  2021/07/27  RV      pr_Entity_GetInfo: Made changes to return the tracking URLs for carrier to track (BK-277)
  2020/09/22  RV      pr_Entity_GetInfo: Included LabelFormat (CIMSV3-1079)
  2020/09/08  RV      pr_Entity_GetInfo: Initial version (HA-1239)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Entity_GetInfo') is not null
  drop Procedure pr_Entity_GetInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Entity_GetInfo: Return the data set with respect to the Entity key and type.
------------------------------------------------------------------------------*/
Create Procedure pr_Entity_GetInfo
  (@EntityId     TRecordId,
   @EntityKey    TEntityKey,
   @EntityType   TEntity,
   @BusinessUnit TBusinessUnit)
as
begin

  if ((coalesce(@EntityType, '') = '') or ((coalesce(@EntityId, 0) = 0) and coalesce(@EntityKey, '') = ''))
    return;

  if (@EntityType = 'SKU')
    begin
      /* If EntityId not send then get EntityId from EntityKey and BU */
      if (coalesce(@EntityId, 0) = 0)
        select @EntityId = SKUId from SKUs where ((SKU = @EntityKey) and (BusinessUnit = @BusinessUnit));

      select *
      from vwSKUs
      where (SKUId = @EntityId)
      order by SKUId;
    end
  else
  if (@EntityType = 'ReceiptHeader')
    begin
      /* If EntityId not send then get EntityId from EntityKey and BU */
      if (coalesce(@EntityId, 0) = 0)
        select @EntityId = ReceiptId from ReceiptHeaders where ((ReceiptNumber = @EntityKey) and (BusinessUnit = @BusinessUnit));

      select *
      from vwReceiptHeaders
      where (ReceiptId = @EntityId)
      order by ReceiptId;
    end
  else
  /* Return entity info when only send EntityId, For entitykey random detail */
  if (@EntityType = 'ReceiptDetail') and (coalesce(@EntityId, 0) <> 0)
    select *
    from vwReceiptDetails
    where (ReceiptDetailId = @EntityId)
    order by ReceiptDetailId;
  else
  if (@EntityType = 'LPN')
    begin
      /* If EntityId not send then get EntityId from EntityKey and BU */
      if (coalesce(@EntityId, 0) = 0)
        select @EntityId = LPNId from LPNs where ((LPN = @EntityKey) and (BusinessUnit = @BusinessUnit));

      select *
      from vwLPNs
      where (LPNId = @EntityId)
      order by LPNId;
    end
  else
  if (@EntityType = 'Order')
    begin
      /* If EntityId not send then get EntityId from EntityKey and BU */
      if (coalesce(@EntityId, 0) = 0)
        select @EntityId = OrderId from OrderHeaders where ((PickTicket = @EntityKey) and (BusinessUnit = @BusinessUnit));

      select *
      from vwOrderHeaders
      where (OrderId = @EntityId)
      order by OrderId;
    end
  else /* Return entity info when only send EntityId for detail. If filter with EntityKey then returns random detail */
  if (@EntityType = 'OrderDetail') and (coalesce(@EntityId, 0) <> 0)
    select *
    from vwOrderDetails
    where (OrderDetailId = @EntityId)
    order by OrderDetailId;
  else
  if (@EntityType = 'LabelFormat')
    select *
    from vwLabelFormats
    where (LabelFormatName = @EntityKey) and (BusinessUnit = @BusinessUnit);
  else
  if (@EntityType = 'TRACKINGURL')
    begin
      select dbo.fn_GetMappedValue('CIMS', S.Carrier, 'CIMS', @EntityType, 'Tracking', @BusinessUnit) + TrackingNo as LinkURL
      from LPNs L
        join OrderHeaders OH on (L.LPNId = @EntityId) and (L.OrderId = OH.OrderId)
        join ShipVias S on (OH.ShipVia = S.ShipVia) and (OH.BusinessUnit = S.BusinessUnit);
    end
end /* pr_Entity_GetInfo */

Go
