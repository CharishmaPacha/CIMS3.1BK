/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/20  TK      pr_OrderHeaders_Recount & pr_OrderHeaders_SetStatus:
  2019/02/07  TK      pr_OrderHeaders_Recount: LPNsAssigned would be the LPNs that are being shipped for order (HPI-2395)
  2016/12/06  VM      pr_OrderDetails_AddOrUpdate, pr_OrderHeaders_Recount (HPI-692):
  2016/10/01  VM      pr_OrderHeaders_Recount: By chance if counts are null set that to 0 (HPI-GoLive)
  2015/09/25  YJ      pr_OrderHeaders_Recount: fixed to show proper Reserved Qty (FB-403)
  2015/03/20  TK      pr_OrderHeaders_Recount: Migrated code from GNC and added code to not include directed quantity while updating UnitsAssigned
  2014/05/20  PKS     pr_OrderHeaders_Recount: Added Status output variable.
  2014/05/12  PK      pr_OrderHeaders_Recount: Updating NumLines on OrderHeader.
  2014/05/05  TD      pr_OrderHeaders_Recount : Get UnitsAssigned from LPNDetails instead of LPNHeaders.
  2014/03/04  PK      pr_OrderHeaders_Recount: Updating NumLPNs on Order.
  2014/01/16  PK      pr_OrderHeaders_Recount: Calling pr_OrderHeaders_SetStatus after order recounting to update the status.
  2014/01/02  TD      pr_OrderHeaders_Recount: Changes to update NumUnits(sum of unitsauthorizedtoship) on OrderHeaders.
  2013/08/14  AY      pr_OrderHeaders_Recount: Handle LPNsAssigned for various clients.
  2012/10/26  NY      pr_OrderHeaders_Recount: Set UnitsAssigned to zero when no LPNs exists for an orders
  2012/09/13  AY      pr_OrderHeaders_Recount: Compute LPNsAssigned
  2012/08/06  AY      pr_OrderHeaders_Recount: Update NumLPNs & UnitsAssigned
                      pr_OrderHeaders_Recount & fn_OrderHeaders_ValidateStatus
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_Recount') is not null
  drop Procedure pr_OrderHeaders_Recount;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_Recount: Recount the Number of LPNs and UnitsAssigned
    against the Order.
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_Recount
  (@OrderId      TRecordId,
   @PickTicket   TPickTicket = null,
   @Status       TStatus     = null output)
as
  declare @vLPNsOnOrder      TCount,
          @vLPNsPacked       TCount,
          @vUnitsToShip      TCount,
          @vODUnitsAssigned  TCount,
          @vLPNUnitsAssigned TCount,
          @vLPNsAssigned     TCount,
          @vShippingLPNs     TCount,
          @vNumLines         TCount,
          @vOrderType        TTypeCode,
          @vLPNCountMethod   TControlValue,
          @vBusinessUnit     TBusinessUnit;
begin
  select @vOrderType    = OrderType,
         @vBusinessUnit = BusinessUnit
  from OrderHeaders
  where (OrderId = @OrderId);

  /* Get authorized to ship details here to update OrderHeaders  */
  select @vUnitsToShip     = sum(UnitsAuthorizedToShip),
         @vNumLines        = count(*),
         @vODUnitsAssigned = sum(UnitsAssigned)
  from OrderDetails
  where (OrderId = @OrderId);

  select @vLPNsOnOrder   = sum(case when LPNType in ('A', 'L') then 0 else 1 end),
         @vLPNsPacked    = sum(case when Status in ('D', 'E', 'L', 'S') then 1 else 0 end),
         @vShippingLPNs  = sum(case when LPNType = 'S' or TrackingNo is not null then 1 else 0 end)
  from LPNs
  where (OrderId = @OrderId);

  /* Its better to get unitsassigned from LPNDetails instead of LPN Headers .*/
  /* if the LPNStatus is shipped we will mark the LPNdetails as unavailable */
  select @vLPNUnitsAssigned = coalesce(sum(LD.Quantity), 0)
  from LPNDetails LD join LPNs L on LD.LPNId = L.LPNId
  where (LD.OrderId = @OrderId) and
        (((LD.OnhandStatus not in ('U'/* Unavailable */, 'D' /*Directed*/)) and (L.Status <> 'S' /* Shipped */)) or
         ((LD.OnhandStatus = 'U' /* Unavailable */) and (L.Status = 'S' /* Shipped */))
        );

  /* LPNs assigned on an Order could vary for clients. So, we are using
     a control var to determine which way to compute
     Example: For OB, LPNsAssigned is the LPNs that are packed,
              For TD, LPNsAssigned is the LPNs that are picked (at least in CO1
              For XS, LPNsAssigned would be the LPNs picked
  */

  select @vLPNCountMethod = dbo.fn_Controls_GetAsString('Orders', 'LPNCount_' + @vOrderType, 'Picked',  @vBusinessUnit, null /* @UserId */);

  select @vLPNsAssigned = case when @vLPNCountMethod = 'Picked' then @vLPNsOnOrder
                               when @vLPNCountMethod = 'Packed' then @vLPNsPacked
                               else @vLPNsOnOrder
                          end;

  /* Update Order header */
  update OrderHeaders
  set @PickTicket   = PickTicket,
      LPNsAssigned  = coalesce(@vShippingLPNs, 0),
      /* For transfer orders when shipped we will clear order info on the LPNs, so use UnitsAssigned from order details */
      UnitsAssigned = case when @vOrderType in ('T', 'RW' /* Transfer, Rework */) then dbo.fn_MaxInt(@vODUnitsAssigned, 0)
                           else dbo.fn_MaxInt(coalesce(@vLPNUnitsAssigned, 0), 0)
                      end,
      NumUnits      = coalesce(@vUnitsToShip, 0),
      NumLPNs       = coalesce(@vLPNsOnOrder, 0),
      NumLines      = coalesce(@vNumLines, 0)
  where (OrderId = @OrderId);

  /* Updating the order status after recounting the order */
  exec pr_OrderHeaders_SetStatus @OrderId, @Status output;

end /* pr_OrderHeaders_Recount */

Go
