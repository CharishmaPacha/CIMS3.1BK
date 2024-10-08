/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_LPNDetails_AddDirectedQty: Changes to recompute Task Dependencies when directed quantity is added to Location
  pr_LPNDetails_AddDirectedQty: Recount LPN so that Directed Qty would be updated on LPN (S2G-499)
  2018/03/21  AY      pr_LPNDetails_AddDirectedQty: Update InnerPacks on Directed Line
  2018/03/14  TK      pr_LPNDetails_AddDirectedQty: Only case storage Locations should have innerpacks (S2G-367)
  2018/03/11  TK      pr_LPNDetails_AddDirectedQty: Changes to update UnitsPerPackage & Innerpacks on Directed line
  2017/11/08  YJ      pr_LPNDetails_AddDirectedQty, pr_LPNDetails_SplitLine: Changes to update ReplenishPickTicket when add directed quantity
  2016/12/13  TK      pr_LPNDetails_AddDirectedQty: Corrected computing max LPNLine (HPI-1170)
  2016/10/18  VM      pr_LPNDetails_AddDirectedQty: Create separate (D)irected lines for each replenish order (HPI-879)
  2015/12/08  TK      pr_LPNDetails_AddDirectedQty: Update ReplenishOrderId and ReplenishOrderDetailId instead of OrderId & OrderDetailId (ACME-419)
  2014/06/26  TD      Added new procedure pr_LPNDetails_AddDirectedQty.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_AddDirectedQty') is not null
  drop Procedure pr_LPNDetails_AddDirectedQty;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_AddDirectedQty: This procedure will add directed line to the
      LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_AddDirectedQty
  (@SKUId            TRecordId,
   @LocationId       TRecordId,

   @InnerPacks       TInnerPacks,
   @Quantity         TQuantity,

   @OrderId          TRecordId,
   @OrderDetailId    TRecordId,

   @BusinessUnit     TBusinessUnit,
   -----------------------------------
   @NewLPNDetailId   TRecordId output)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,

          @vRLPNId               TRecordId,
          @vRLPNQuantity         TQuantity,
          @vRLPNDetailId         TRecordId,
          @vLocStorageType       TTypeCode,
          @vUnitsPerPackage      TQuantity,
          @vOrderId              TRecordId,
          @vReplenishPickTicket  TPickTicket;
begin
  SET NOCOUNT ON;

  select @vReturnCode      = 0,
         @vMessageName     = null;

  /* select the LPN here for the SKU and Location.
     For picklanes, the assumption is we will have static Locations, i.e one logical LPN has one SKU only */
  select @vRLPNId       = LPNId,
         @vRLPNQuantity = Quantity
  from LPNs
  where (LocationId = @LocationId) and
        (SKUId      = @SKUId);

  if (@vRLPNId is null)
    goto ExitHandler;

  select @vLocStorageType = StorageType
  from Locations
  where (LocationId = @LocationId);

  /* Get Units Per package on the LPN */
  select @vUnitsPerPackage = UnitsPerPackage
  from LPNDetails
  where (LPNId = @vRLPNId);

  /* If there are no line on LPN then get UnitsPerPackage from SKU Standards */
  if (@vUnitsPerPackage is null)
    select @vUnitsPerPackage = UnitsPerInnerpack
    from SKUs
    where (SKUId = @SKUId);

  /* Check whether the LPN is already having any directed qty or not for
     the same ReplenishOrderId/ReplenishOrderDetailId (This may not be possible in regular scenario)
     But, our intention is that we cannot club two replenish orders Directed lines into one and having
     one replenish order info on that line. So, we will create separate (D)irected lines from here on */
  select @vRLPNDetailId = LD.LPNDetailId,
         @vRLPNId       = LD.LPNId
  from LPNDetails LD
  where (LD.LPNId        = @vRLPNId) and
        (LD.SKUId        = @SKUId) and
        (LD.OnhandStatus = 'D' /* Directed */) and
        (LD.ReplenishOrderId       = @OrderId) and
        (LD.ReplenishOrderDetailId = @OrderDetailId);

  select @vReplenishPickTicket = PickTicket
  from OrderHeaders
  where (OrderId = @OrderId);

  /* Insert the Replenish Directed line into LPNDetail */
  /* We would update RepelenishOrderId and ReplenishOrderDetailId on the LPN Detail while we are creating a Directed
     line and we would update OrderId and OrderDetailId on the Directed line while it is allocated against an Order */
  if (@vRLPNDetailId is null)
    begin
      insert into LPNDetails (LPNId, LPNLine, SKUId, OnhandStatus, Quantity, Innerpacks, UnitsPerPackage,
                              ReplenishOrderId, ReplenishPickTicket, ReplenishOrderDetailId, BusinessUnit)
        select @vRLPNId, coalesce(Max(LPNLine) + 1, 1), @SKUId, 'D' /* Directed */, @Quantity,
               case
                 when (@vUnitsPerPackage > 0) and (@vLocStorageType = 'P' /* Cases */)
                   then floor(@Quantity/@vUnitsPerPackage)
                 else 0
               end/* Innerpacks */,
               @vUnitsPerPackage, @OrderId, @vReplenishPickTicket, @OrderDetailId, @BusinessUnit
        from LPNDetails
        where (LPNId = @vRLPNId);

      select @NewLPNDetailId = Scope_Identity();
    end
  else
    update LPNDetails
    set InnerPacks      = InnerPacks + case when (@vUnitsPerPackage > 0) and (@vLocStorageType = 'P' /* Cases */)
                                            then @Quantity / @vUnitsPerPackage
                                            else 0
                                       end,
        Quantity        = Quantity + @Quantity,
        @NewLPNDetailId = @vRLPNDetailId
    where (LPNDetailId  = @vRLPNDetailId) and
          (LPNId        = @vRLPNId) and
          (OnhandStatus = 'D' /* Directed */) and
          (ReplenishOrderId       = @OrderId) and
          (ReplenishOrderDetailId = @OrderDetailId);

  /* Recount LPN so the Directed Qty would be updated on LPN */
  exec pr_LPNs_Recount @vRLPNId;

  if (@vReturnCode > 0)
    goto ExitHandler;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNDetails_AddDirectedQty */

Go
