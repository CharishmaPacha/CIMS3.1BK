/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/28  SJ/RV   pr_Packing_GetDetailsToPack: Made changes to exclude LineType(C) SKUs (OB2-1959)
  2016/08/11  MV      pr_Packing_GetDetailsToPack: Maintain a log details (HPI-422)
  2015/03/24  NB      pr_Packing_GetDetailsToPack: Enhanced to handle the condition where the Picked inventory
  2015/02/20  DK      Added pr_Packing_GetOrdersToPack and pr_Packing_GetDetailsToPack
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_GetDetailsToPack') is not null
  drop Procedure pr_Packing_GetDetailsToPack;
Go
/*------------------------------------------------------------------------------
  pr_Packing_GetDetailsToPack:
    procedure returns all details to be displayed in packing screen

  XML Structure:
  Procedure accepts parameter in the xml format as below

  <InputParams>
    <ParamInfo>
      <Name></Name>
      <Value></Value>
    </ParamInfo>
  </InputParams>

------------------------------------------------------------------------------*/
Create Procedure pr_Packing_GetDetailsToPack
  (@PackingCriteria TXML)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,

          @vOrderId        TRecordId,
          @ValidOrderId    TRecordId,
          @vBulkOrderId    TRecordId,
          @vPallet         TPallet,
          @vPalletId       TRecordId,
          @ValidPalletId   TRecordId,
          @vPickBatchNo    TPickBatchNo,
          @vBusinessUnit   TBusinessUnit,
          @vShowLinesWithNoPickedQty
                           TFlag,
          @vShowComponentSKUsLines
                           TFlag,
          @vInputParams    TInputParams,
          @vOutputXML      TXML,
          @vActivityLogId  TRecordId,
          @vReturnDataSet  TFlags,
          @vDebugOptions   TFlags;

begin
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vReturnDataSet = 'Y';

  /* read the values for parameters */
  insert into @vInputParams
    select * from dbo.fn_GetInputParams(@PackingCriteria);

  /* Initialize param variables */
  select @vOrderId  = null,
         @vPalletId = null;

  /* read param variables */
  select @vOrderId   = case when ParamName = 'ORDERID'  then ParamValue else @vOrderId  end,
         @vPalletId  = case when ParamName = 'PALLETID' then nullif(ParamValue,0) else @vPalletId end
  from @vInputParams;

  /* Validate Pallet  given */
  if (@vPalletId is not null)
    begin
      select @ValidPalletId = PalletId
      from Pallets
      where (PalletId = @vPalletId);

      if (@ValidPalletId is null)
        set @vMessageName = 'PalletDoesNotExist';
    end

  /* Validate Order  given */
  if (@vOrderId is not null)
    begin
      select @ValidOrderId  = OrderId,
             @vBusinessUnit = BusinessUnit
      from OrderHeaders
      where (OrderId = @vOrderId)

      if (@ValidOrderId is null)
        set @vMessageName = 'PickTicketIsInvalid';
    end

  if (@vMessageName is not null)
    goto ErrorHandler;

  select @vShowComponentSKUsLines = dbo.fn_Controls_GetAsBoolean('Packing', 'ShowComponentSKUsLines', 'N', @vBusinessUnit, null /* UserId */);

  /* create the return table from vwOrderToPackDetails structure */
  if object_id('tempdb..#PackingDetails') is null
    select * into #PackingDetails from vwOrderToPackDetails where 1 = 2
  else
    select @vReturnDataSet = 'N';

  /* Identify if the Order belongs to a Bulk Pick Batch */
  select @vPickBatchNo = PickBatchNo
  from OrderHeaders
  where (OrderId = @vOrderId);

  select @vBulkOrderId = null;
  select @vBulkOrderId = OrderId
  from OrderHeaders
  where ((PickBatchNo = @vPickBatchNo) and (OrderType = 'B' /* Bulk Pull*/));

  if (@vBulkOrderId is not null)
    begin
      /* we have arrived at an order belonging to bulk pick batch */
      /* Assuming if order packing is being done, the input will always contain the orderid */
      insert into #PackingDetails
        select *
        from vwBulkOrderToPackDetails
        where (OrderId = @vOrderId) and (LPNId is null);  --to pack

      /* get the pick information from the bulk PickTicket details */
      update #PackingDetails
      set PalletId           = OPD.PalletId,
          Pallet             = OPD.Pallet,
          LPNId              = OPD.LPNId,
          LPN                = OPD.LPN,
          LPNDetailId        = OPD.LPNDetailId,
          PickedQuantity     = OPD.PickedQuantity,
          PickedFromLocation = OPD.PickedFromLocation,
          PickedBy           = OPD.PickedBy,
          SerialNo           = OPD.SerialNo
      from vwOrderToPackDetails OPD
      where ((OPD.OrderId = @vBulkOrderId) and (#PackingDetails.SKUId = OPD.SKUId));

      /* There could be instances when nothing was picked for a SKU or all picked inventory was consumed already
         update such details with 0 picked quantity */
      update #PackingDetails
      set PickedQuantity = 0
      where (coalesce(LPN, '') = '');

      /* set the picked quantity to minimum of unitstoallocate on the order details of order to pack and
         the units picked in the bulk order sku line
         There are instances when the order lines in Bulk order are picked partially or not picked at all.
         In such cases, the Picked Quantity must reflect the actual physical inventory, instead of the UnitsToAllocate
         as this could lead to packer getting confused between the discrepancy in what is displayed and physically available
      */
      update #PackingDetails
      set PickedQuantity = dbo.fn_MinInt(PickedQuantity, OD.UnitsToAllocate)
      from OrderDetails OD
      where ((OD.OrderId = @vOrderId) and (#PackingDetails.SKUId = OD.SKUId));

      /* Remove all the lines where the PickedQuantity is 0. There is nothing to be packed */
      select @vShowLinesWithNoPickedQty = dbo.fn_Controls_GetAsBoolean('Packing', 'ShowLinesNotPicked', 'N', @vBusinessUnit, System_User);

      if (@vShowLinesWithNoPickedQty = 'N' /* No */)
        delete from #PackingDetails
        where (PickedQuantity = 0);
    end
  else
  if (@vPalletId is null) and (@vOrderId is not null)
    begin
      /* If Packing by Order, then give only the picked details */
      insert into #PackingDetails
        select *
        from vwOrderToPackDetails
        where (OrderId = @vOrderId) and
              ((LPNType = 'A') or (LPNStatus = 'K' /* Picked */));
    end
  else
    begin
      /* Assuming if batch packing is being done, the input will always contain the orderid and palletid */
      insert into #PackingDetails
        select *
        from vwOrderToPackDetails
        where ((OrderId = @vOrderId) and (PalletId = @vPalletId));
    end

  /* Get Debug Options */
  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @vBusinessUnit, @vDebugOptions output;

  /* Maintain packing details log based on the control variable */
  if (charindex('L', @vDebugOptions) > 0)
    begin
      /* result set convert into XML  */
      set @vOutputXML = (select * from #PackingDetails for xml path ('OrderDetail'), root('PackingDetails'),  ELEMENTS xsinil);

      /* Get the pallet  */
      set @vPallet = (select top 1 Pallet from #PackingDetails);

      /* ActivityLog */
      exec pr_ActivityLog_AddMessage 'GetDetailsToPack', @vPalletId, @vPallet, 'Pallet',
                                     'Details', @@ProcId, @vOutputXML, @vBusinessUnit;
    end

  if (@vShowComponentSKUsLines = 'N')
    delete from #PackingDetails where LineType = 'C' /* Component SKU */;

  /* return result set - assumption is if caller has created #PackingDetails
     then we just fill it in and don't have to return the data set again */
  if (@vReturnDataSet = 'Y')
    select * from #PackingDetails;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_GetDetailsToPack */

Go
