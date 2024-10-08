/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/19  RV      pr_Packing_LoadPackDetails: Made changes to break the look when raise the error (FBV3-1118)
  2021/10/13  RV      pr_Packing_LoadPackDetails: Made changes to identify the order details
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_LoadPackDetails') is not null
  drop Procedure pr_Packing_LoadPackDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_LoadPackDetails: When user packs some inventory, the list of
    SKUs and Units packed is sent back from UI as xml and this procedure parses
    and processes the input and inserts the packed item details into #PackDetails.

  Packing could happen in two modes
  a. Consolidated: i.e. multiple lines may have been consolidated and presented to
     the user and in this case, the user packed bulk qty which would have to be
     split back into the OrderDetails packed and populated into #PackeDaetails
  b. Order Details: The items to pack was presented to the user broken by OrderDetailId
     and in this scenario, the given list can used as is and populated into #PackDetails

  output:
  #PackDetails -> TPackDetails
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_LoadPackDetails
  (@XMLInput            XML,
   @OrderId             TRecordId,
   @BusinessUnit        TBusinessUnit,
   @UserId              TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,
          @vOrderId               TRecordId,
          @vPickTicket            TPickTicket,
          @vWaveId                TRecordId,
          @vWaveNo                TPickBatchNo,
          @vWaveType              TTypeCode,

          @vBulkOrderId           TRecordId,

          @vPickedRecordId        TRecordId,
          @vPackGroupKey          TVarchar,
          @vTotalPackedQuantity   TQuantity,
          @vPackDetailsMode       TControlValue;

  declare @ttPackDetails          TPackDetails,
          @ttPickedOrderDetails   TPackDetails;
begin /* pr_Packing_LoadPackDetails */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  select @vPackDetailsMode = dbo.fn_Controls_GetAsString('Packing', 'PackDetailsMode', 'Default', @BusinessUnit, @UserId);

  /* Create hash tables */
  select * into #PickedOrderDetails from @ttPickedOrderDetails;

  /* get the Order Information */
  select @vOrderId     = OrderId,
         @vPickTicket  = PickTicket,
         @vWaveId      = PickBatchId,
         @vWaveNo      = PickBatchNo
  from OrderHeaders
  where (OrderId = @OrderId);

  /* Get the WaveType */
  select @vWaveType    = WaveType
  from Waves
  where (WaveId = @vWaveId);

  select @vBulkOrderId = OrderId
  from OrderHeaders
  where (PickBatchId = @vWaveId) and
        (OrderType   = 'B' /* Bulk */);

  /* Extract user given packed details from xml and insert into temp table for processing */
  insert into @ttPackDetails (SKUId, SKU, UnitsPacked, OrderId, OrderDetailId, FromLPNId, FromLPNDetailId, PalletId,
                              SerialNo, PackingGroup, PackGroupKey, InventoryKey)
    select Record.Col.value('SKUId[1]',                 'TRecordId'),
           Record.Col.value('SKU[1]',                   'TSKU'     ),
           Record.Col.value('UnitsPacked[1]',           'TQuantity'),
           Record.Col.value('OrderId[1]',               'TRecordId'),
           Record.Col.value('OrderDetailId[1]',         'TRecordId'),
           Record.Col.value('LPNId[1]',                 'TRecordId'),
           Record.Col.value('LPNDetailId[1]',           'TRecordId'),
           Record.Col.value('PalletId[1]',              'TRecordId'),
           nullif(Record.Col.value('SerialNo[1]',       'TSerialNo'), ''),
           Record.Col.value('PackingGroup[1]',          'TCategory'),
           coalesce(Record.Col.value('PackGroupKey[1]', 'TVarChar'),  ''),
           Record.Col.value('InventoryKey[1]',          'TInventoryKey')
    from @XMLInput.nodes('/Root/Data/PackedDetails/PackedDetail') as Record(Col)

  /* If any empty lines sent, exclude them */
  delete from @ttPackDetails where UnitsPacked = 0;

  /*-------------------- Process lines that are not grouped --------------------*/

  /* When PackGroupKey is not given, then we just use the given Pack details as is */
  insert into #PackDetails (SKU, UnitsPacked, OrderId, OrderDetailId, FromLPNId, FromLPNDetailId, PalletId,
                            SerialNo, PackingGroup, PackGroupKey, InventoryKey)
    select SKU, UnitsPacked, OrderId, OrderDetailId, FromLPNId, FromLPNDetailId, PalletId,
           SerialNo, PackingGroup, PackGroupKey, InventoryKey
    from @ttPackDetails
    where (PackGroupKey = '');

  delete from @ttPackDetails where (PackGroupKey = '');

  /*-------------------- Process lines that are grouped --------------------*/

  /* Get all the possible pack details for Order being packed i.e. the the possible lines
     that the user has packed */
  if (@vWaveType = 'SLB')
    begin
      /* Override packing details mode here, we need to return it through rules */
      select @vPackDetailsMode = 'GroupBy-Order-SKU';

      /* For SLB and Bulk wave we will pick the inventory against the bulk order and packing against original order,
         retrieve the picked information for packing SKU */
      insert into #PickedOrderDetails (SKUId, SKU, UnitsPicked, OrderId, OrderDetailId,
                                       FromLPNId, FromLPNDetailId, PalletId, SerialNo, PackingGroup, InventoryKey)
        select OPD.SKUId, OPD.SKU, OPD.PickedQuantity, PD.OrderId, PD.OrderDetailId,
               OPD.LPNId, OPD.LPNDetailId, OPD.PalletId, OPD.SerialNo, OPD.PackingGroup, OPD.InventoryKey
        from vwOrderToPackDetails OPD
          join @ttPackDetails PD on PD.SKUId = OPD.SKUId
        where (OPD.OrderId = @vBulkOrderId) and
              (OPD.LPNStatus in ('K', 'G' /* Picked, Packing */)) and
              (OPD.PickedQuantity > 0);
    end
  else
    insert into #PickedOrderDetails (SKUId, SKU, UnitsPicked, OrderId, OrderDetailId,
                                     FromLPNId, FromLPNDetailId, PalletId, SerialNo, PackingGroup, InventoryKey)
      select OPD.SKUId, OPD.SKU, OPD.PickedQuantity, OPD.OrderId, OPD.OrderDetailId,
             OPD.LPNId, OPD.LPNDetailId, OPD.PalletId, OPD.SerialNo, OPD.PackingGroup, OPD.InventoryKey
      from vwOrderToPackDetails OPD
      where (OPD.OrderId = @OrderId) and
            (OPD.LPNStatus in ('K', 'G' /* Picked, Packing */)) and
            (OPD.PickedQuantity > 0);

  /* If the packing mode is default then pack group key is empty as don't need to group pack details with key */
  update #PickedOrderDetails
  set PackGroupKey = case when (@vPackDetailsMode = 'GroupBy-LPN-SKU')  then concat_ws('-', OrderId, FromLPNId, SKUId, PackingGroup)
                          when (@vPackDetailsMode = 'GroupBy-Order-SKU') then concat_ws('-', OrderId, SKUId)
                          else ''
                     end;

  /* Of the packed units, we need to map them to the Picked Order details based upon the group. So,
     if we send consolidated pack details to user and user packed some of those units, then we need
     to apply those packed units only to the corresponding picked lines - all based upon the PackGroupKey */
  while exists(select * from @ttPackDetails where (RecordId > @vRecordId))
    begin
      select top 1 @vPackGroupKey        = PackGroupKey,
                   @vTotalPackedQuantity = UnitsPacked,
                   @vRecordId            = RecordId
      from @ttPackDetails
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Loop through all the picked details while grouped Packed quantity is zero from details */
      while (@vTotalPackedQuantity != 0)
        begin
          select @vPickedRecordId = 0;

          /* Identify the picked line to pack */
          select top 1 @vPickedRecordId = RecordId
          from #PickedOrderDetails
          where (PackGroupKey = @vPackGroupKey) and
                (UnitsPicked  > coalesce(UnitsPacked, 0))
          order by UnitsPicked, RecordId;

          /* if there are no more lines to satisfy, then we are over packing... raise error */
          if (@vPickedRecordId = 0)
            begin
              raiserror('OverPacking', 16, 1);

              /* break the infinite loop */
              break;
            end

          /* Identify the line quantity to pack from grouped pack quantity */
          update ttOTP
          set UnitsPacked            = dbo.fn_MinInt(UnitsPicked, @vTotalPackedQuantity),
              @vTotalPackedQuantity -= dbo.fn_MinInt(UnitsPicked, @vTotalPackedQuantity)
          from #PickedOrderDetails ttOTP
          where (RecordId = @vPickedRecordId);
        end
    end

  /* insert the identified line details to pack */
  insert into #PackDetails(SKU, UnitsPacked, OrderId, OrderDetailId,
                           FromLPNId, FromLPNDetailId, PalletId, SerialNo)
    select SKU, UnitsPacked, OrderId, OrderDetailId,
           FromLPNId, FromLPNDetailId, PalletId, SerialNo
    from #PickedOrderDetails
    where (UnitsPacked > 0);

  /* update Line Type from Order Detail */
  update PD
  set LineType = OD.LineType
  from #PackDetails PD
  join OrderDetails OD on(OD.OrderId = PD.OrderId) and (OD.OrderDetailId = PD.OrderDetailId);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_LoadPackDetails */

Go
