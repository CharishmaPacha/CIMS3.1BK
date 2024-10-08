/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_ValidatePackingDetails') is not null
  drop Procedure pr_Packing_ValidatePackingDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_ValidatePackingDetails: #PackDetails has the items and qtys
    being packed and the From LPNs being packed from. This procedure validates
    the details ensuring that we don't over pack and that the contents packed
    are of same packing group

  @FromLPNId -- Not used as of 2021/06/16 - AY
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_ValidatePackingDetails
  (@FromLPNId       TRecordId,
   @ToLPNId         TRecordId,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vDebug                TControlValue,

          @vPackingGroupCount    TCount,
          @vToLPNPackingGroup    TVarChar,
          @vOrdDtlPackingGroup   TVarChar;

  declare @PackingQty table(
    Id               TRecordId Identity(1,1),
    ScannedInfo      TSKU,
    SKUId            TRecordId,
    SKU              TSKU,
    LPNId            TRecordId,
    Quantity         TQuantity);

  declare @ttPackingInfo table(
    LPNId            TRecordId,
    PalletId         TRecordId,
    SKUId            TRecordId,
    SKU              TSKU,
    Quantity         TQuantity);

  declare @QtyToPack table(
    SKUId            TRecordId,
    SKU              TSKU,
    Quantity         TQuantity);

begin /* pr_Packing_ValidatePackingDetails */

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get the quantity of each sku being packed */
  insert into @PackingQty (ScannedInfo, LPNId, Quantity)
    select SKU, FromLPNId, sum(UnitsPacked)
    from #PackDetails
    group by SKU, FromLPNId;

  /* Scanned info could be SKU or UPC, get actual SKU in the context of the From LPN */
  update @PackingQty
  set SKUId = SS.SKUId,
      SKU   = SS.SKU
  from @PackingQty PQ cross apply fn_SKUs_GetScannedSKUs(PQ.ScannedInfo, @BusinessUnit) SS
    join LPNDetails LD on (LD.LPNId = PQ.LPNId) and (LD.SKUId = SS.SKUId);

  if (charindex('Y', @vDebug) > 0) insert into #Markers (Marker) select 'Updated SKU with cross Apply';

  /* Get the quantity of each sku on cart
     TD-Some times, we wont have pallet information on LPNS/Totes */
  insert into @ttPackingInfo (LPNId, PalletId, SKUId, SKU, Quantity)
    select L.LPNId, L.PalletId, LD.SKUId, S.SKU, LD.Quantity
    from #PackDetails PD
      join LPNDetails LD on (LD.LPNId = PD.FromLPNId)
      join LPNs L on (L.LPNId = LD.LPNId)
      join SKUs S on (S.SKUId = LD.SKUId);

  /* Get the quantity from LPN, which are not Pallet, also we are exclude if SKU have both LPN and Pallet */
  if (@FromLPNId is not null) and
     (not exists (select * from @ttPackingInfo where LPNId = @FromLPNId))
    insert into @ttPackingInfo (LPNId, PalletId, SKUId, SKU, Quantity)
      select L.LPNId, L.PalletId, LD.SKUId, S.SKU, LD.Quantity
      from LPNs L
        join LPNDetails LD on (L.LPNId = LD.LPNId)
        join SKUs S        on (S.SKUId = LD.SKUId)
      where (L.LPNId = @FromLPNId);

  /* Get the quantity of each sku on cart */
  insert into @QtyToPack (SKUId, SKU, Quantity)
    select SKUId, SKU, sum(Quantity)
    from @ttPackingInfo
    group by SKUId, SKU;

  /* Do not allow to pack more units than avaiable to pack */
  if (exists (select *
              from @PackingQty PQ
                full join @QtyToPack QP on (PQ.SKUId = QP.SKUId)
              where coalesce(PQ.Quantity,0) > coalesce(QP.Quantity,0)))
    set @vMessageName = 'ScannedMoreThanPicked';

  if (charindex('Y', @vDebug) > 0) insert into #Markers (Marker) select 'Validated to not allow pack more units than on cart';

  /* Do not allow to pack, if package has multiple Packing Groups */
  select @vPackingGroupCount  = count(distinct(OD.PackingGroup)),
         @vOrdDtlPackingGroup = min(OD.PackingGroup)
  from #PackDetails PD
    join OrderDetails OD on (PD.OrderDetailId = OD.OrderDetailId);

  /* If package ReOpens, get the packing group of LPN and new pack detail */
  select top 1 @vToLPNPackingGroup = OD.PackingGroup
  from LPNDetails LD
    join OrderDetails OD on (OD.OrderDetailId = LD.OrderDetailId)
  where (LD.LPNId = @ToLPNId);

  /* Validate the packing group */
  if (@vPackingGroupCount > 1) or
     ((@vToLPNPackingGroup is not null) and (@vToLPNPackingGroup <> @vOrdDtlPackingGroup))
    set @vMessageName = 'PackageHasMultiplePackingGroups';

  if (charindex('Y', @vDebug) > 0) insert into #Markers (Marker) select 'Validated to not allow pack, package has multiple PackingGroups';

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_ValidatePackingDetails */

Go
