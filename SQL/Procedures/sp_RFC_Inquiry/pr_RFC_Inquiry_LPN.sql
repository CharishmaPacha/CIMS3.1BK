/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/04/10  TK      pr_RFC_Inquiry_LPN:
                        Changes to Validate Scanned LPN signature (HPI-1490)
  2016/10/26  TK      pr_RFC_Inquiry_LPN: changed to display Task Id (HPI-GoLive)
  2016/09/13  AY      pr_RFC_Inquiry_LPN: More enhancements to show summary of Qty (HPI-GoLive)
  2016/02/18  TK      pr_RFC_Inquiry_LPN: Changes made to retrieve scanned LPN using function (CIMS-723)
  2015/12/24  DK      pr_RFC_Inquiry_Location, pr_RFC_Inquiry_LPN, pr_RFC_Inquiry_Pallet: Enhanced to return Warehouse as well (FB-584).
  2014/05/27  PV      pr_RFC_Inquiry_LPN: Enhanced to return SKUDescription along with other details.
  2014/04/15  YJ      pr_RFC_Inquiry_LPN: Added DestZone & DestLocation .
  2013/05/27  NY      pr_RFC_Inquiry_LPN: Retrieving LoadNumber by LoadId.
  2013/05/22  NY      pr_RFC_Inquiry_LPN: Get CustomerName from contacts if there is no data for customers.
  2013/05/13  NY      pr_RFC_Inquiry_LPN: Added SoldToId,CustomerName and LoadNumber.
  2013/05/13  NY      pr_RFC_Inquiry_LPN: Show ShipToId instead of ShipToStore.
  2013/03/27  AY      pr_RFC_Inquiry_LPN: Enhance to use SKU1..SKU5 captions and show RO
  2012/10/09  PKS     pr_RFC_Inquiry_LPN, pr_RFC_Inquiry_Pallet: Added Style, Color, Size, BatchNo, ShipToStore, CustPO for RF details grid.
  2011/09/05  PK      Created pr_RFC_Inquiry_LPN.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Inquiry_LPN') is not null
  drop Procedure pr_RFC_Inquiry_LPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Inquiry_LPN:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Inquiry_LPN
  (@LPNId         TRecordId,
   @LPN           TLPN,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @ReturnCode     TInteger,
          @MessageName    TMessageName,
          @Message        TDescription,
          @vStatus        TStatus,
          @vLPNTaskId     TRecordiD,
          @vLPNId         TRecordId,
          @vLocation      TLocation,
          @vPallet        TPallet,
          @vOrderId       TRecordId,
          @vPickTicket    TPickTicket,
          @vSalesOrder    TSalesOrder,
          @vLPNTypeDesc   TDescription,
          @vUDF1          TUDF,
          @vUDF2          TUDF,
          @vUDF3          TUDF,
          @vUDF4          TUDF,
          @vUDF5          TUDF,
          @vSKU1          TSKU,
          @vSKU2          TSKU,
          @vSKU3          TSKU,
          @vSKU4          TSKU,
          @vSKU5          TSKU,
          @vInnerPacks    TInnerpacks,
          @vQuantity      TQuantity,
          @vPickBatchNo   TPickBatchNo,
          @vShipToId      TShipToId,
          @vShipToStore   TShipToStore,
          @vSoldToId      TCustomerId,
          @vLoadId        TLoadId,
          @vLoadNumber    TLoadNumber,
          @vCustomerName  TName,
          @vCustPO        TCustPO,
          @vReceiptNumber TReceiptNumber,
          @vContextName   TName,
          @vDestWarehouse TWarehouse,
          @vDestZone      TLookUpCode,
          @vDestLocation  TLocation,
          @vAlternateLPN  TLPN;

  declare @vAvailableQty    TQuantity,
          @vReservedQty     TQuantity,
          @vDirectedQty     TQuantity,
          @vDirectedResvQty TQuantity;

  declare @ttLPNInquiry Table
          (RecordId       TRecordId identity (1,1),
           RecordType     TTypeCode default 'LPNInfo',
           LPN            TLPN,
           SKU            TSKU,
           SKU1           TSKU,
           SKU2           TSKU,
           SKU3           TSKU,
           SKU4           TSKU,
           SKU5           TSKU,
           UoM            TUoM,
           SKUDescription TDescription,
           InnerPacks     TInnerPacks,
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

  select @vContextName = 'RFInquiry.LPN';

  select @vLPNId         = LPNId,
         @LPN            = LPN,
         @vStatus        = StatusDescription,
         @vLPNTypeDesc   = LPNTypeDescription,
         @vSKU1          = nullif(SKU1, ''),
         @vSKU2          = nullif(SKU2, ''),
         @vSKU3          = nullif(SKU3, ''),
         @vSKU4          = nullif(SKU4, ''),
         @vSKU5          = nullif(SKU5, ''),
         @vInnerPacks    = InnerPacks,
         @vQuantity      = Quantity,
         @vOrderId       = OrderId,
         @vLocation      = Location,
         @vPallet        = Pallet,
         @vPickTicket    = PickTicket,
         @vReceiptNumber = ReceiptNumber,
         @vLPNTaskId     = TaskId,
         @vLoadId        = LoadId,
         @vUDF1          = UDF1,
         @vUDF2          = UDF2,
         @vUDF3          = UDF3,
         @vUDF4          = UDF4,
         @vUDF5          = UDF5,
         @vDestWarehouse = DestWarehouse,
         @vDestZone      = DestZone,
         @vDestLocation  = DestLocation,
         @vAlternateLPN  = AlternateLPN
  from  vwLPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@LPN, @BusinessUnit, default /* Options */));

  if(@vLoadId is not null)
    select @vLoadNumber = LoadNumber
    from Loads
    where (LoadId = @vLoadId);

  if (@vOrderId is not null)
    select @vPickBatchNo = PickBatchNo,
           @vShipToStore = ShipToStore,
           @vShipToId    = ShipToId,
           @vSoldToId    = SoldToId,
           @vCustPO      = CustPO
    from OrderHeaders
    where (OrderId = @vOrderId);

  if (@vSoldToId is not null)
    select @vCustomerName = CustomerName
    from Customers
    where (CustomerId = @vSoldToId);

  if (@vCustomerName is null)
    select @vCustomerName = Name
    from vwSoldToAddress
    where (ContactRefId = @vSoldToId);

  if (@vLPNId is null)
    set @MessageName = 'LPNDoesNotExist';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get Summary of LPN Details */
  select @vAvailableQty     = sum(case when OnhandStatus = 'A' then Quantity else 0 end),
         @vReservedQty      = sum(case when OnhandStatus = 'R' then Quantity else 0 end),
         @vDirectedQty      = sum(case when OnhandStatus = 'D' then Quantity else 0 end),
         @vDirectedResvQty  = sum(case when OnhandStatus = 'DR' then Quantity else 0 end)
  from LPNDetails
  where (LPNId = @vLPNId);

  /* Insert the basic data */
  insert into @ttLPNInquiry (RecordType, FieldName, FieldValue, FieldVisible)
                     select  'LPN',      'LPN',     @LPN, 2 /* Always Show */;

  /* Retrieving information from LPNDetails for given LPN and inserting into temp table
     For the info which is returned from LPNDetails table will be insterted into temp table
     with RecordType as 'LPNDetails'*/
  insert into @ttLPNInquiry (RecordType, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UOM, SKUDescription, Quantity, FieldVisible)
    select 'LPNDetails', SKU,
           coalesce(SKU1, ''), coalesce(SKU2, ''), coalesce(SKU3, ''), coalesce(SKU4, ''), coalesce(SKU5, ''),
           UoM, coalesce(SKUDescription, SKU), Quantity, 2 /* Always show */
    from vwLPNDetails
    where ((LPNId    = @vLPNId) and
           (Quantity > 0))
    order by SKU;

  select @vAvailableQty    = coalesce(@vAvailableQty,    0),
         @vReservedQty     = coalesce(@vReservedQty,     0),
         @vDirectedQty     = coalesce(@vDirectedQty,     0),
         @vDirectedResvQty = coalesce(@vDirectedResvQty, 0);

  /* Retrieving information from LPNs for given LPN and inserting into temp table.
     For the info which is returned from LPNs table will be insterted into temp table
     with RecordType as 'LPNInfo' */
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'TotalQty',     nullif(@vAvailableQty + @vReservedQty, 0)
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'AvailableQty', nullif(@vAvailableQty, 0)
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'ReservedQty',  nullif(@vReservedQty, 0)
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'Replenishing', nullif(@vDirectedQty + @vDirectedResvQty, 0)
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'DemandFor',    nullif(@vDirectedResvQty, 0)

  insert into @ttLPNInquiry (FieldName, FieldValue) select 'Status',      @vStatus
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'LPNType',     @vLPNTypeDesc
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'SKU1',        @vSKU1
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'SKU2',        @vSKU2
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'SKU3',        @vSKU3
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'SKU4',        @vSKU4
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'SKU5',        @vSKU5
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'InnerPacks',  @vInnerPacks
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'Quantity',    @vQuantity
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'Location',    coalesce(@vLocation,   'None')
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'CartPosition',@vAlternateLPN
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'Warehouse',   @vDestWarehouse
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'DestLocation',@vDestLocation
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'Pallet',      @vPallet
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'ReceiptNumber',
                                                                          @vReceiptNumber
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'SalesOrder',  @vSalesOrder
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'PickTicket',  @vPickTicket
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'PickBatchNo', @vPickBatchNo
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'CustPO',      @vCustPO
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'SoldToId',    @vSoldToId
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'CustomerName',@vCustomerName
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'ShipToId',    @vShipToId
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'ShipToStore', nullif(@vShipToStore, '')
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'LoadNumber',  @vLoadNumber
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'DestZone',    @vDestZone
  insert into @ttLPNInquiry (FieldName, FieldValue) select 'TaskId',      @vLPNTaskId;

  /* Use defined captions for all fields */
  update L
  set L.FieldName    = coalesce(FC.FieldCaption, L.FieldName),
      L.FieldVisible = coalesce(FC.FieldVisible, L.FieldVisible),
      L.SortSeq      = coalesce(FC.SortSeq,      L.SortSeq)
  from @ttLPNInquiry L left outer join vwFieldCaptions FC on L.FieldName    = FC.FieldName and
                                                             FC.ContextName = @vContextName;

  /* Return all LPNDetails records and all LPN Info records which have
     some value - we do not want to show null values */
  select *
  from @ttLPNInquiry
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
end /* pr_RFC_Inquiry_LPN */

Go
