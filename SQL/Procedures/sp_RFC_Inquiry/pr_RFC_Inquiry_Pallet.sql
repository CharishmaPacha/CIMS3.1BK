/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/12/24  DK      pr_RFC_Inquiry_Location, pr_RFC_Inquiry_LPN, pr_RFC_Inquiry_Pallet: Enhanced to return Warehouse as well (FB-584).
  2014/01/03  NY      pr_RFC_Inquiry_Pallet: Show Captions from layout instead of fields.
  2013/12/13  NY      pr_RFC_Inquiry_Pallet: Added pallet weight and volume
  2013/11/13  PK      pr_RFC_Inquiry_Pallet: Added #Cases.
  2013/05/16  PKS     pr_RFC_Inquiry_Pallet: LPNTypeDesc fetch from LPNs before inserting data into @ttPalletInquiry
  2013/04/11  AY      pr_RFC_Inquiry_Pallet: Partial fix to handle RF crash when Pallet has multi SKU LPNs
  2013/03/28  TD      pr_RFC_Inquiry_Pallet: Enhance to use SKU1..SKU5 captions
  2012/10/11  AY      pr_RFC_Inquiry_Pallet: Allow Pallet inquiry by scanning a LPN on the Pallet
  2012/10/09  PKS     pr_RFC_Inquiry_LPN, pr_RFC_Inquiry_Pallet: Added Style, Color, Size, BatchNo, ShipToStore, CustPO for RF details grid.
  2012/03/27  YA      Created pr_RFC_Inquiry_Pallet.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Inquiry_Pallet') is not null
  drop Procedure pr_RFC_Inquiry_Pallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Inquiry_Pallet:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Inquiry_Pallet
  (@Pallet           TPallet,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @DeviceId         TDeviceId)
as
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName,
          @Message            TDescription,

          @vLPNId             TRecordId,
          @vLPN               TLPN,
          @vLPNType           TTypeCode,
          @vSKU               TSKU,
          @vSKU1              TSKU,
          @vSKU2              TSKU,
          @vSKU3              TSKU,
          @vSKU4              TSKU,
          @vSKU5              TSKU,
          @vQuantity          TQuantity,

          @vPalletId          TRecordId,
          @vPalletStatus      TStatus,
          @vPalletStatusDesc  TDescription,
          @vPalletType        TTypeCode,
          @vPalletTypeDesc    TDescription,
          @vNumLPNs           TQuantity,
          @vInnerPacks        TQuantity,
          @vLocation          TLocation,
          @vOrderId           TRecordId,
          @vPickTicket        TPickTicket,
          @vPickBatchNo       TPickBatchNo,
          @vShipToStore       TShipToStore,
          @vCustPO            TCustPO,
          @vWeight            TWeight,
          @vVolume            TVolume,
          @vContextName       TName,
          @vWarehouse         TWarehouse,
          @DestZone           TLookUpCode;

  declare @ttPalletInquiry Table
          (RecordId       TRecordId identity (1,1),
           RecordType     varchar(20) default 'PalletInfo',
           LPN            TLPN,
           LPNType        TSKU,
           SKU            TSKU,
           SKU1           TSKU,
           SKU2           TSKU,
           SKU3           TSKU,
           SKU4           TSKU,
           SKU5           TSKU,
           SKUDescription TDescription,
           UoM            TUoM,
           Quantity       TQuantity,

           FieldName      TEntity,
           FieldValue     TDescription,
           FieldVisible   TInteger Default 1,  /* 2: Always Show, 1 - Show if not null, -1 do not show */
           SortSeq        TInteger Default 0);

begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  /* Assume user scanned a pallet */
  select @vPalletId = PA.PalletId
  from vwPallets PA
  where (PA.Pallet       = @Pallet) and
        (PA.BusinessUnit = @BusinessUnit);

  /* If it was not a pallet, then check if the user scanned a case on the pallet */
  if (@vPalletId is null)
    select @vPalletId = PalletId
    from vwLPNs
    where (LPN          = @Pallet) and
          (BusinessUnit = @BusinessUnit);

   /* Set ContextName */
   select @vContextName = 'RFInquiry.Pallet';

  /* Get all the details */
  select @vPalletId         = PA.PalletId,
         @vPalletStatus     = PA.Status,
         @vPalletType       = PA.PalletType,
         @vPalletStatusDesc = PA.StatusDesc,
         @vPalletTypeDesc   = PA.PalletTypeDesc,
         @vNumLPNs          = PA.NumLPNs,
         @vWarehouse        = PA.Warehouse,
         @vLocation         = PA.Location,
         @vPickTicket       = PA.PickTicket,
         @vSKU              = PA.SKU,
         @vSKU1             = PA.SKU1,
         @vSKU2             = PA.SKU2,
         @vSKU3             = PA.SKU3,
         @vSKU4             = PA.SKU4,
         @vSKU5             = PA.SKU5,
         @vInnerPacks       = PA.InnerPacks,
         @vQuantity         = PA.Quantity,
         @vPickBatchNo      = PA.PickBatchNo,
         @vOrderId          = PA.OrderId,
         @vShipToStore      = PA.ShipToId,
         @vWeight           = cast(PA.Weight as numeric(8,2)),
         @vVolume           = cast(PA.Volume as numeric(8,2))
  from vwPallets PA
  where (PA.PalletId = @vPalletId);

  select-- @vShipToStore = ShipToStore,
         @vCustPO      = CustPO
  from OrderHeaders
  where (OrderId = @vOrderId);

  if (@Pallet is null)
    set @MessageName = 'PalletIsRequired';
  else
  if (@vPalletId is null)
    set @MessageName = 'PalletDoesNotExist';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Insert the basic data */
  insert into @ttPalletInquiry (RecordType, FieldName, FieldValue, FieldVisible)
                      select    'Pallet',   'Pallet',  @Pallet, 2 /* Always Show */;

  /* Retrieving information from PalletDetails for given Pallet and inserting into temp table
     For the info which is returned from vwLPNs table will be inserted into temp table
     with RecordType as 'PalletDetails'*/
  insert into @ttPalletInquiry (RecordType, LPN, LPNType, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, SKUDescription, UoM, Quantity, FieldVisible)
    select 'PalletDetails', LD.LPN, ET.TypeDescription, LD.SKU,
           coalesce(LD.SKU1, ''), coalesce(LD.SKU2, ''), coalesce(LD.SKU3, ''), coalesce(LD.SKU4, ''), coalesce(LD.SKU5, ''),
           coalesce(LD.SKUDescription, SKU), LD.UoM, LD.Quantity, 2 /* Always show */
    from vwLPNDetails LD
      left outer join EntityTypes ET on (LD.LPNType = ET.TypeCode) and
                                        (ET.Entity  = 'LPN')
    where ((LD.PalletId = @vPalletId) and
           (LD.Quantity > 0))
    order by SKU;

  /* Retrieving information from Pallets for given Pallet and inserting into temp table.
     For the info which is returned from Pallets table will be inserted into temp table
     with RecordType as 'PalletInfo' */
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'ShipToStore',   @vShipToStore
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'Status',        coalesce(@vPalletStatusDesc, @vPalletStatus)
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'PalletType',    coalesce(@vPalletTypeDesc, @vPalletType)
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'NumLPNs',       @vNumLPNs
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'InnerPacks',    @vInnerPacks
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'Quantity',      @vQuantity
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'Warehouse',     @vWarehouse
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'Location',      coalesce(@vLocation,   'None')
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'PickTicket',    coalesce(@vPickTicket, '')
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'PickBatchNo',   @vPickBatchNo
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'SKU',           @vSKU
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'SKU1',          @vSKU1
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'SKU2',          @vSKU2
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'SKU3',          @vSKU3
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'SKU4',          @vSKU4
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'SKU5',          @vSKU5
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'CustPO',        @vCustPO
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'Weight',        @vWeight
  insert into @ttPalletInquiry (FieldName, FieldValue) select 'Volume',        @vVolume

  /* Use defined captions for all fields. If the field is not defined to be visible
    or does not have a caption defined, we would not show it in RF */
  update L
  set L.FieldName    = coalesce(FC.FieldCaption, L.FieldName),
      L.FieldVisible = coalesce(FC.FieldVisible, L.FieldVisible),
      L.SortSeq      = coalesce(FC.SortSeq,      L.SortSeq)
  from @ttPalletInquiry L left outer join vwFieldCaptions FC on L.FieldName    = FC.FieldName and
                                                             FC.ContextName = @vContextName;

  /* Return all PalletDetails records and all Pallet Info records which have
     some value - we do not want to show null values */
  select *
  from @ttPalletInquiry
  where (FieldVisible > 1) or (FieldVisible = 1 and FieldValue is not null)
  order by SortSeq, RecordId;

  exec pr_Device_Update @DeviceId, @UserId, 'PalletInquiry' /* CurrentOperation */, 'PalletInquiry' /* CurrentResponse */, @@ProcId;

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
end /* pr_RFC_Inquiry_Pallet */

Go
