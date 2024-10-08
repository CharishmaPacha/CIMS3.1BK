/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/07/12  PKK     pr_OrderHeaders_UpdateTrackingNo: Initial revision (OBV3-BK-866)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_UpdateTrackingNo') is not null
  drop Procedure pr_OrderHeaders_UpdateTrackingNo;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_UpdateTrackingNo: Get the TrackingNumbers against the Order
    from ShipLabels table and update that on a OH UDF. This procedure is just
    a placeholder only and does not do any updates as in standard V3 there is
    no field on OH to update TrackingNos. When needed, this proc would be copied
    to client custom version and the available UDF updated.
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_UpdateTrackingNo
  (@OrderId      TRecordId)
 as
begin
  SET NOCOUNT ON;

   /* Update LPN TrackingNo on Orders  */
  ;with TrackingInfo (OrderId, TrackingNo) as
  (
   select top 2 OrderId, TrackingNo
   from ShipLabels
   where (OrderId = @OrderId) and
         (Status = 'A' /* Active */)
   order by RecordId
  )
  select OrderId, string_agg(TrackingNo, ',') TrackingNo
  into #TrackingInfo
  from TrackingInfo
  group by OrderId;

--   /* UDF can only hold 50 chars, so limit to that only */
--   update OH
--   set OH.UDF9 = substring(TI.TrackingNo, 1, 50)
--   from OrderHeaders OH
--     join #TrackingInfo TI on (OH.OrderId = TI.OrderId);

end /* pr_OrderHeaders_UpdateTrackingNo */

Go
