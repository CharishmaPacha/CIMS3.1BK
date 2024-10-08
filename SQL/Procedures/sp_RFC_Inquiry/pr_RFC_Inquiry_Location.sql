/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/08/16  AY      pr_RFC_Inquiry_Location: Show Pallet (OB2-Support)
  2018/08/01  AY      pr_RFC_Inquiry_Location: Enhance to show summary by LPN List or SKU (OB2-456)
  2015/12/24  DK      pr_RFC_Inquiry_Location, pr_RFC_Inquiry_LPN, pr_RFC_Inquiry_Pallet: Enhanced to return Warehouse as well (FB-584).
  2015/05/01  SV      pr_RFC_Inquiry_Location: Made changes to continue the Inquiry process even if the Barcode is scanned.
  2013/11/17  AY      pr_RFC_Inquiry_Location: Added #Cases.
  2013/05/23  AY      pr_RFC_Inquiry_Location: Changed to show zero qty SKUs also for static picklanes.
  2013/01/24  PKS     pr_RFC_Inquiry_Location: varchar size was increased from 4 to 6 chars for many fields.
  2013/01/22  YA/VM   pr_RFC_Inquiry_Location: Return empty if Pallet or UoM is null as binding null in RF causes issue
  2012/07/12  NY      pr_RFC_Inquiry_Location: Showing number of pallets as well in Location Details.
  2012/07/12  NY      pr_RFC_Inquiry_Location: Showing number of pallets as well in Location Details.
  2011/09/07  TD      Created pr_RFC_Inquiry_Location.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Inquiry_Location') is not null
  drop Procedure pr_RFC_Inquiry_Location;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Inquiry_Location:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Inquiry_Location
  (@LocationId    TRecordId,
   @Location      TLocation,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @ReturnCode           TInteger,
          @MessageName          TMessageName,
          @Message              TDescription,

          @vLocationId          TRecordId,
          @vLocation            TLocation,
          @vLocationType        TTypeCode,
          @vLocationStorageType TTypeCode,
          @vLocationTypeDesc    TDescription,
          @vStatusDesc          TDescription,
          @vStorageTypeDesc     TDescription,
          @vNumLPNs             TCount,
          @vNumPallets          TCount,
          @vNumInnerPacks       TCount,
          @vPutawayZone         TDescription,
          @vPickZone            TDescription,
          @vTotalQuantity       TQuantity,
          @vContextName         TName,
          @vWarehouse           TWarehouse,
          @vLocDetails          TControlValue,

          @vAvailableQty        TQuantity,
          @vReservedQty         TQuantity,
          @vPendingResvQty      TQuantity,
          @vDirectedQty         TQuantity;

  declare @ttLocationInquiry Table
          (RecordId       TRecordId identity (1,1),
           RecordType     TTypeCode default 'LocInfo',
           LPN            TLPN,
           Pallet         TPallet,
           SKU            TSKU,
           SKU1           TSKU,
           SKU2           TSKU,
           SKU3           TSKU,
           SKU4           TSKU,
           SKU5           TSKU,
           UoM            TUoM,
           Quantity       TQuantity,
           Status         TDescription,
           FieldName      TEntity,
           FieldValue     TDescription,
           FieldVisible   TInteger Default 1,  /* 2: Always Show, 1 - Show if not null, -1 do not show */
           SortSeq        TInteger Default 0);
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @vContextName = 'RFInquiry.Location',
         @vLocDetails  = dbo.fn_Controls_GetAsString('RFInquiry_Location', 'DetailLevel', 'SummaryBySKU' , @BusinessUnit, null /* UserId */);

  select @vLocationId          = LocationId,
         @vLocation            = Location,
         @vLocationType        = LocationType,
         @vLocationTypeDesc    = LocationTypeDesc,
         @vLocationStorageType = StorageType,
         @vStorageTypeDesc     = StorageTypeDesc,
         @vStatusDesc          = StatusDescription,
         @vWarehouse           = Warehouse,
         @vPutawayZone         = PutawayZoneDisplayDesc,
         @vPickZone            = PickingZoneDisplayDesc,
         @vNumPallets          = NumPallets,
         @vNumLPNs             = NumLPNs,
         @vNumInnerPacks       = InnerPacks,
         @vTotalQuantity       = Quantity
  from  vwLocations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (@LocationId, @Location, null /* DeviceId */, @UserId, @BusinessUnit));

  if (@vLocationId is null)
    set @MessageName = 'LocationDoesNotExist';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Insert the basic data */
  insert into @ttLocationInquiry (RecordType, FieldName,  FieldValue, FieldVisible)
                          select  'Location', 'Location', @vLocation, 2 /* Always Show */;

  /* Retrieving information from LPNDetails for given Location and inserting into temp table
     For the info which is returned from LPNDetails table will be insterted into temp table
     with RecordType as 'LocDetails'

     Show all LPNs in Location even if there is no quantity i.e. for Static SKUs */
  if (@vLocDetails = 'SummaryBySKU')
    insert into @ttLocationInquiry (RecordType, LPN, Pallet, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UOM, Quantity, FieldVisible)
      select 'LocDetails', count (distinct L.LPNId), L.Pallet, S.SKU + '   ',
             coalesce(S.SKU1, ''), coalesce(S.SKU2, ''), coalesce(S.SKU3, ''), coalesce(S.SKU4, ''), coalesce(S.SKU5, ''),
             coalesce(S.UoM, ''), sum(case when charindex(LD.OnhandStatus, 'AR') > 0 then LD.Quantity else 0 end),
             2 /* Always show */
      from LPNs L join LPNDetails LD on L.LPNId = LD.LPNId
           left join Pallets P on L.PalletId = P.PalletId
           left join SKUs    S on LD.SKUId   = S.SKUId
      where (L.LocationId = @vLocationId)
      group by S.SKU, S.SKU1, S.SKU2, S.SKU3, S.SKU4, S.SKU5, S.UoM, S.SKUSortOrder, L.Pallet
      order by S.SKUSortOrder, S.SKU
  else
    insert into @ttLocationInquiry (RecordType, LPN, Pallet, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UOM, Quantity, FieldVisible)
      select 'LocDetails', L.LPN, coalesce(P.Pallet, ''), S.SKU,
             coalesce(S.SKU1, ''), coalesce(S.SKU2, ''), coalesce(S.SKU3, ''), coalesce(S.SKU4, ''), coalesce(S.SKU5, ''),
             coalesce(S.UoM, ''), LD.Quantity, 2 /* Always show */
      from LPNs L join LPNDetails LD on L.LPNId = LD.LPNId
           left join Pallets P on L.PalletId = P.PalletId
           left join SKUs    S on LD.SKUId   = S.SKUId
      where (L.LocationId = @vLocationId)
      order by LPN, SKU;

  /* Summarize counts */
  select @vAvailableQty   = sum(case when LD.OnhandStatus = 'A'  then LD.Quantity else 0 end),
         @vReservedQty    = sum(case when LD.OnhandStatus = 'R'  then LD.Quantity else 0 end),
         @vPendingResvQty = sum(case when LD.OnhandStatus = 'PR' then LD.Quantity else 0 end),
         @vDirectedQty    = sum(case when LD.OnhandStatus = 'D'  then LD.Quantity else 0 end)
  from LPNs L join LPNDetails LD on L.LPNId = LD.LPNId
  where (L.LocationId = @vLocationId);

  /* Retrieving information from Locations for given Location and inserting into temp table.
     For the info which is returned from Locations table will be insterted into temp table
     with RecordType as 'LocInfo' */
  if (@vLocationType = 'K' /* Pick Lanes */)
    insert into @ttLocationInquiry (FieldName, FieldValue)
                            select  'NumSKUs',    cast(@vNumLPNs as varchar(4))

  if (@vLocationStorageType in ('A' /* Pallets */, 'LA' /* Pallets & LPNs */))
    insert into @ttLocationInquiry (FieldName, FieldValue)
                            select 'NumPallets', cast(@vNumPallets as varchar(4))

  if (@vLocationStorageType in ('A' /* Pallets */, 'L' /* LPNs */, 'LA' /* Pallets & LPNs */))
    insert into @ttLocationInquiry (FieldName, FieldValue)
                            select 'NumLPNs',    cast(@vNumLPNs as varchar(4))

  insert into @ttLocationInquiry (FieldName, FieldValue) select 'NumInnerPacks',  cast(nullif(@vNumInnerPacks, 0) as varchar(5))
  insert into @ttLocationInquiry (FieldName, FieldValue) select 'Quantity',       cast(@vTotalQuantity as varchar(5))
  insert into @ttLocationInquiry (FieldName, FieldValue) select 'AvailableQty',   cast(@vAvailableQty  as varchar(5))
  insert into @ttLocationInquiry (FieldName, FieldValue) select 'ReservedQty',    cast(nullif(@vReservedQty,    0) as varchar(5))
  insert into @ttLocationInquiry (FieldName, FieldValue) select 'DemandQty',      cast(nullif(@vPendingResvQty, 0) as varchar(5))
  insert into @ttLocationInquiry (FieldName, FieldValue) select 'OnReplenishQty', cast(nullif(@vDirectedQty,    0) as varchar(5))
  insert into @ttLocationInquiry (FieldName, FieldValue) select 'Status',         @vStatusDesc
  insert into @ttLocationInquiry (FieldName, FieldValue) select 'LocationType',   @vLocationTypeDesc
  insert into @ttLocationInquiry (FieldName, FieldValue) select 'StorageType',    @vStorageTypeDesc
  insert into @ttLocationInquiry (FieldName, FieldValue) select 'PutawayZone',    coalesce(@vPutawayZone, 'Not defined')
  insert into @ttLocationInquiry (FieldName, FieldValue) select 'PickZone',       coalesce(@vPickZone,    'Not defined')
  insert into @ttLocationInquiry (FieldName, FieldValue) select 'Warehouse',      @vWarehouse

  /* Use defined captions for all fields */
  update L
  set L.FieldName    = coalesce(FC.FieldCaption, L.FieldName),
      L.FieldVisible = coalesce(FC.FieldVisible, L.FieldVisible),
      L.SortSeq      = coalesce(FC.SortSeq,      L.SortSeq)
  from @ttLocationInquiry L left outer join vwFieldCaptions FC on L.FieldName    = FC.FieldName and
                                                             FC.ContextName = @vContextName;

  /* Return all LocDetails records and all Location Info records which have
     some value - we do not want to show null values */
  select *
  from @ttLocationInquiry
  where (FieldVisible > 1) or (FieldVisible = 1 and FieldValue is not null)
  order by SortSeq, RecordId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;
  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_Inquiry_Location */

Go
