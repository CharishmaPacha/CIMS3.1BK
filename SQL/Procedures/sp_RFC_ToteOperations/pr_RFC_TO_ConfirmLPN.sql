/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/01/10  SV      pr_RFC_TO_ConfirmLPN: Signature correction for pr_RFC_ConfirmPutawayLPN (S2G-72)
  2016/09/20  YJ      pr_RFC_TO_ConfirmLPN: Change to caller pr_RFC_TransferInventory to build xml (CIMS-1096)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_TO_ConfirmLPN') is not null
  drop Procedure pr_RFC_TO_ConfirmLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_TO_ConfirmLPN:

  Input:
<?xml version="1.0" encoding="utf-8"?>
<ConfirmProcessCarton xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <LPNId>10</LPNId>
  <LPN>L0909</LPN>
  <DestZone>Shelving</DestZone>
  <DestLocation>01-01</SuggestedLocation>
  <SKU>0013</SKU>
  <Quantity>21</Quantity>
  <ConfirmedLocation>021-12</ConfirmedLocation>
  <ScannedQuantity>21</ScannedQuantity>
  <Pallet>P12</Pallet>

  <Operation>Putaway</Warehouse>

  <Warehouse>PGH</Warehouse>
  <BusinessUnit>GNC</BusinessUnit>
  <UserId>teja</UserId>
  <DeviceId>Pocket_PC</DeviceId>
</ConfirmProcessCarton>
------------------------------------------------------------------------------*/

Create Procedure pr_RFC_TO_ConfirmLPN
  (@xmlInput   xml,
   @xmlResult  xml output)
as
  declare @vLPNId               TRecordId,
          @vLPN                 TLocation,
          @vSKU                 TSKU,
          @vLPNType             TTypeCode,
          @vLPNWarehouse        TWarehouseId,
          @vLPNDetailId         TRecordId,
          @vLPNPickBatchNo      TPickBatchNo,
          @vLPNDestZone         TZoneId,
          @vLPNOrderDetailId    TRecordId,
          @vLPNOrderId          TRecordId,
          @vPickTicket          TPickTicket,
          @vLPNPickTicket       TPickTicket,
          @vLPNLocationId       TRecordId,
          @vLPNQuantity         TQuantity,
          @vLPNInnerPacks       TQuantity,
          @vLPNLocation         TLocation,
          @vDestZone            TZoneId,
          @vDestLocation        TLocation,
          @vPAType              TTypeCode,
          @vToLPN               TLPN,
          @vToteId              TRecordId,
          @vTote                TLPN,
          @vToteLocationId      TRecordId,
          @vToteLocation        TLocation,
          @vToteOrderId         TRecordId,
          @vToteStatus          TStatus,
          @vToteQuantity        TQuantity,
          @QtyToExplode         TQuantity,
          @vPickType            TTypeCode,
          @vPickZone            TZoneId,
          @vConfirmedLocId      TRecordId,
          @vConfirmedLoc        TLocation,
          @vScannedQty          TQuantity,
          @vPallet              TPallet,
          @vPalletId            TRecordId,
          @vOperation           TDescription,
          @vTaskId              TRecordId,
          @vTaskdetailId        TRecordId,
          @vPickBatchNo         TPickBatchNo,
          @vWarehouse           TWarehouse,
          @vBusinessUnit        TBusinessUnit,
          @vDeviceId            TDeviceId,
          @vUserId              TUserId,
          @vNote1               TDescription,
          @vXmlData             TXML,
          @vxmlResult           xml,
          @vTIXMLInput          XML,

          /* picking related */
          @vOrderDetailIdToPick TRecordId,
          @vLPNIdToPickFrom     TRecordId,
          @vLPNDetailIdToPick   TRecordId,
          @vLPNToPickFrom       TLPN,
          @vSKUIdPick           TRecordId,
          @vLocToPickFrom       TLocation,
          @vUnitsToPick         TQuantity,
          @vSKUId               TrecordId,
          @vTDUnitsCompleted    TQuantity,
          @vPickBatchId         TRecordId,
          @vTaskDetailStatus    TStatus,

          @vConfirmLPNPickMsg TMessageName,

          @MessageName       TMessageName,
          @ReturnCode        TInteger;
begin /* pr_RFC_TO_ConfirmLPN */
begin try
  begin transaction;
  SET NOCOUNT ON;

  /* Get the Input params */
  select @vLPNId            = Record.Col.value('LPNId[1]',             'TRecordId'),
         @vLPN              = Record.Col.value('LPN[1]',               'TLPN'),
         @vLPNDetailId      = Record.Col.value('LPNDetailId[1]',       'TLPN'),
         @vLPNQuantity      = Record.Col.value('Quantity[1]',          'TQuantity'),
         @vDestZone         = Record.Col.value('DestZone[1]',          'TZoneId'),
         @vDestLocation     = Record.Col.value('DestLocation[1]',      'TLocation'),
         @vConfirmedLoc     = Record.Col.value('ScannedLocation[1]',   'TLocation'),
         @vPallet           = Record.Col.value('Pallet[1]',            'TPallet'),
         @vTote             = Record.Col.value('Tote[1]',              'TLPN'),
         @vLPNToPickFrom    = Record.Col.value('FromLPN[1]',           'TLPN'),
         @vPickBatchNo      = Record.Col.value('PickBatchNo[1]',       'TPickBatchNo'),
         @vSKU              = Record.Col.value('SKU[1]',               'TSKU'),
         @vTaskId           = Record.Col.value('TaskId[1]',            'TRecordId'),
         @vTaskDetailId     = Record.Col.value('TaskDetailId[1]',      'TRecordId'),
         @vLPNOrderId       = Record.Col.value('OrderId[1]',           'TRecordId'),
         @vLPNOrderDetailId = Record.Col.value('OrderDetailId[1]',     'TRecordId'),
         @vPickZone         = Record.Col.value('PickZone[1]',          'TZoneId'),
         @vPickType         = Record.Col.value('PickType[1]',          'TTypeCode'),
         @vOperation        = Record.Col.value('Operation[1]',         'TDescription'),
         @vToLPN            = Record.Col.value('ToLPN[1]',             'TLPN'),
         @vWarehouse        = Record.Col.value('Warehouse[1]',         'TWarehouse'),
         @vBusinessUnit     = Record.Col.value('BusinessUnit[1]',      'TBusinessUnit'),
         @vDeviceId         = Record.Col.value('DeviceId[1]',          'TDeviceId'),
         @vUserId           = Record.Col.value('UserId[1]',            'TUserId')
  from @xmlInput.nodes('/ConfirmTOLPN') as Record(Col);

  /* Get the LPN/Tote Info */
  select @vLPNId            = LPNId,
         @vLPN              = LPN,
         @vLPNType          = LPNType,
         @vLPNWarehouse     = DestWarehouse,
         @vLPNDestZone      = DestZone,
         @vLPNPickBatchNo   = PickBatchNo,
         @vLPNLocationId    = LocationId,
         @vLPNLocation      = Location,
         @vLPNOrderId       = OrderId,
         @vLPNInnerPacks    = InnerPacks
  from vwLPNs
  where (LPN          = @vLPN) and
        (BusinessUnit = @vBusinessUnit);

  /* Get SKU details here */
  select @vSKUId = SKUId
  from SKUs
  where (SKU          = @vSKU) and
        (BusinessUnit = @vBusinessUnit);

  /* Get Pickbatch details */
  select @vPickBatchId = RecordId
  from PickBatches
  where (BatchNo      = @vPickBatchNo) and
        (BusinessUnit = @vBusinessUnit);

  /* Get confirmed Location details here */
  select @vConfirmedLocId = LocationId
  from Locations
  where (Location = @vConfirmedLoc);

  /* Get order details here */
  if (@vLPNOrderId is not null)
    select @vLPNPickTicket = PickTicket
    from OrderHeaders
    where (OrderId = @vLPNOrderId);

  /* select tote details here */
  if (@vTote is not null)
    select @vToteId       = LPNId,
           @vTote         = LPN,
           @vToteLocation = Location,
           @vToteOrderId  = OrderId,
           @vToteStatus   = Status
    from LPNs
    where (LPN = @vTote);

  /* Validations */
  if ((@vLPNId is null) and (@vToteId is null))
    set @MessageName = 'InvalidLPN';
  else
  if (@vOperation = 'Putaway') and
     (@vDestLocation <> @vConfirmedLoc)
    set @MessageName = 'LocationDiffFromSuggested';
  else
  if (@vOperation = 'Transfer') and
     (@vToteStatus <> 'N')
    set @MessageName = 'InvalidToteStatus';

  if (@MessageName is not null)
    goto ErrorHandler;

  if (@vOperation = 'Palletize')
    begin
      /* if the operation is palletize then we need to add  the tote to pallet here */
      exec @ReturnCode = pr_RFC_Inv_AddLPNToPallet @vPallet, @vLPN, @vBusinessUnit, @vUserId, @vxmlResult output;

      if (@ReturnCode = 0)
        set @vConfirmLPNPickMsg = 'PalletizeSuccessful';
    end
  else
  if (@vOperation = 'Putaway')
    begin
      /* if the operation is Putaway then we need to putawy the whole contents into picklane location */
      select @vXmlData = '<CONFIRMPUTAWAYLPN>' +
                            dbo.fn_XMLNode('LPN',             @vLPN) +
                            dbo.fn_XMLNode('SKU',             @vSKU) +
                            dbo.fn_XMLNode('DestZone',        @vDestZone) +
                            dbo.fn_XMLNode('DestLocation',    @vDestLocation) +
                            dbo.fn_XMLNode('ScannedLocation', @vConfirmedLoc) +
                            dbo.fn_XMLNode('PAInnerPacks',    @vLPNInnerPacks) +
                            dbo.fn_XMLNode('PAQuantity',      @vLPNQuantity) +
                            dbo.fn_XMLNode('PAType',          @vPAType) +
                            dbo.fn_XMLNode('DeviceId',        @vDeviceId) +
                            dbo.fn_XMLNode('UserId',          @vUserId) +
                            dbo.fn_XMLNode('BusinessUnit',    @vBusinessUnit) +
                         '</CONFIRMPUTAWAYLPN>';

      if (@ReturnCode = 0)
        set @vConfirmLPNPickMsg = 'PutawaySuccessful';
    end
  else
  if (@vOperation = 'Transfer')
    begin
      select @vTIXMLInput = (select @vLPNId           as LPNId,
                                    @vLPN             as LPN,
                                    @vLPNLocationId   as LPNLocationId,
                                    @vLPNLocation     as LPNLocation,
                                    @vSKUId           as SKUId,
                                    @vSKU             as SKU,
                                    @QtyToExplode     as QtyToExplode,
                                    @vLPNQuantity     as LPNQuantity,
                                    @vToteId          as ToteId,
                                    @vTote            as Tote,
                                    @vToteLocationId  as LocationId,
                                    @vToteLocation    as Location,
                                    @vBusinessunit    as Businessunit,
                                    @vUserId          as UserId
                             FOR XML PATH('TransferInventory'));

        /* if the operation is ecom picking then we need to tranfer inventory from LPN to Tote  */
        exec @ReturnCode = pr_RFC_TransferInventory @vTIXMLInput,
                                                    @XmlResult  output;
      if (@ReturnCode = 0)
        set @vConfirmLPNPickMsg = 'TransferSuccessful';
    end
  else   /* if the user confirms the picking action */
  if (@vOperation = 'Picking')
    begin
      exec @ReturnCode = pr_Picking_ConfirmUnitPick @vLPNPickTicket, @vLPNOrderDetailId, @vLPNToPickFrom, @vToLPN, @vSKUId, @vLPNQuantity,
                                                    @vTaskId, @vTaskDetailId, @vBusinessUnit, @vUserId, null, /* activity type */
                                                    @vPalletId;

      /* if there is no error then we need to give next pick if there is any */
      if (@ReturnCode = 0)
        begin
          /* Update taskdetails */
          if (@vTaskId is not null)
            begin
              update TD
              set @vTDUnitsCompleted =
                  TD.UnitsCompleted  = (coalesce(TD.UnitsCompleted, 0) + @vLPNQuantity),
                  @vTaskDetailStatus =
                  TD.Status          = Case
                                         when (@vTDUnitsCompleted = TD.Quantity)               then 'C' /* Completed */
                                         when (@vTDUnitsCompleted <> OD.UnitsAuthorizedToShip) then 'I' /* In Progress */
                                       end,
                  TD.ModifiedDate    = current_timestamp,
                  TD.ModifiedBy      = @vUserId
              from TaskDetails TD
                join OrderDetails OD on (OD.OrderDetailId = TD.OrderDetailId)
              where (TD.TaskId       = @vTaskId) and
                    (TD.TaskDetailId = @vTaskDetailId);

              /* Update the counts of the tasks */
              exec pr_Tasks_SetStatus @vTaskId, @vUserId, null /* Status */, 'Y' /* Recount */;

              /* Update num picks completed   here */
              If (@vTaskDetailStatus in ('C' /* completed */, 'X' /* Cancelled */))
                update Pickbatches
                set NumPicksCompleted = NumPicksCompleted + 1
                where (RecordId = @vPickBatchId);

               select @vOrderDetailIdToPick = null, @vLPNIdToPickFrom = null, @vLPNToPickFrom = null, @vLPNDetailIdToPick = null,
                     @vSKUIdPick = null, @vLocToPickFrom = null, @vTaskId = null, @vTaskDetailId = null, @vUnitsToPick= null
            end

          /* Call procedure here to get next pick details  */
          exec pr_Picking_FindNextTaskForLPN @vLPNOrderId, @vPickZone, @vOrderDetailIdToPick output, @vLPNIdToPickFrom output,
                                             @vLPNToPickFrom output, @vLPNDetailIdToPick output, @vSKUIdPick output,
                                             @vLocToPickFrom output, @vTaskId output, @vTaskDetailId output,
                                             @vUnitsToPick output;

          /* if there is next available */
          if (@vLPNToPickFrom is not null)
            exec pr_Picking_BuildPickResponseForLPN @vPallet, @vLPNIdToPickFrom, @vLPNToPickFrom, @vLPNDetailIdToPick,
                                                    @vLocToPickFrom, @vOrderDetailIdToPick, @vPickBatchNo, @vPickZone,
                                                    @vSKUIdPick, @vTaskId, @vTaskDetailId, @vUnitsToPick, @vBusinessUnit,
                                                    @vUserId, @xmlResult output;
          else
            set @vConfirmLPNPickMsg = 'PickingSuccessful';
        end
    end

  /* we need to send final result here
  build xml here --- */
  if (@vConfirmLPNPickMsg is not null) and (@xmlResult is null)
    exec pr_BuildRFSuccessXML @vConfirmLPNPickMsg, @xmlResult output;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName, @vNote1;

  commit transaction;
end try
begin catch
  rollback transaction;
  exec pr_BuildRFErrorXML @xmlResult output;
end catch;
end /* pr_RFC_TO_ConfirmLPN */

Go
