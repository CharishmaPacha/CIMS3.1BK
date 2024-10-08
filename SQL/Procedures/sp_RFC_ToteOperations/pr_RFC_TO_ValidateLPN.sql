/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_TO_ValidateLPN') is not null
  drop Procedure pr_RFC_TO_ValidateLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_TO_ValidateLPN: All operations at the shelving area start out with
   the scanning of an LPN and this procedure is used to validate the given LPN
   as well as decide what needs to be done with the scanned LPN or Tote.

   The primary output that is sent back to the RF Device is the Operation and
   then the necessary relevant info associated needed to complete the operation.

  Input:
<?xml version="1.0" encoding="utf-8"?>
<ValidateLPN xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <LPN>I000000072</LPN>
  <PickZone />
  <Warehouse>IND</Warehouse>
  <DeviceId>Pocket_PC</DeviceId>
  <UserId>teja</UserId>
  <BusinessUnit>GNC</BusinessUnit>
</ValidateLPN>
------------------------------------------------------------------------------*/

Create Procedure pr_RFC_TO_ValidateLPN
  (@xmlInput   xml,
   @xmlResult  xml output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vRecordId            TRecordId,

          @vLPNId               TRecordId,
          @vLPN                 TLPN,
          @vLPNType             TTypeCode,
          @vLPNWarehouse        TWarehouseId,
          @vLPNDestZone         TZoneId,
          @vLPNDestLoc          TLocation,

          @vLPNSKUId            TRecordId,
          @vLPNSKU              TSKU,
          @vSKUDescription      TDescription,
          @vLPNCases            TInnerPacks,
          @vLPNQty              TQuantity,

          @vLPNOrderId          TRecordId,
          @vLPNBatchId          TRecordId,
          @vLPNBatchNo          TPickBatchNo,
          @vLPNLocationId       TRecordId,
          @vLPNLocation         TLocation,
          @vLPNOrderType        TTypeCode,

          @vPickZone            TZoneId,
          @vPickTicket          TPickTicket,
          @vBatchType           TTypeCode,
          @vSugLocation         TLocation,
          @vDisplayQty          TDescription,
          @vOperation           TDescription,
          @vSugPallet           TPallet,
          @vWarehouse           TWarehouse,
          @vBusinessUnit        TBusinessUnit,
          @vDeviceId            TDeviceId,
          @vUserId              TUserId,
          @vQtyEnabled          TControlValue,
          @vPalletEnabled       TControlValue,

          @vInputXMLToGetPick   xml,
          @xmlPickDetails       XML,
          @vxmlPickDetails      TXML,
          @vxmlLPNDetails       TXML,
          @vxmlResult           TXML,
          @vxmlOptions          TXML;
begin /* pr_RFC_TO_ValidateLPN */
begin try
  begin transaction;
  SET NOCOUNT ON;

  /* Get the Input params */
  select @vLPN          = Record.Col.value('LPN[1]',          'TLPN'),
         @vPickZone     = Record.Col.value('PickZone[1]',     'TZoneId'),
         @vOperation    = Record.Col.value('Operation[1]',    'TDescription'),
         @vWarehouse    = Record.Col.value('Warehouse[1]',    'TWarehouse'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]', 'TLPN'),
         @vDeviceId     = Record.Col.value('DeviceId[1]',     'TDeviceId'),
         @vUserId       = Record.Col.value('UserId[1]',       'TUserId')
  from @xmlInput.nodes('/ValidateLPN') as Record(Col);

  /* Get the LPN/Tote Info */
  select @vLPNId          = LPNId,
         @vLPN            = LPN,
         @vLPNType        = LPNType,
         @vLPNWarehouse   = DestWarehouse,
         @vLPNBatchNo     = PickBatchNo,
         @vLPNLocation    = Location,
         @vLPNCases       = InnerPacks,
         @vLPNQty         = Quantity,
         @vLPNOrderId     = OrderId,
         @vLPNDestZone    = DestZone,
         @vLPNDestLoc     = Destlocation,
         @vLPNSKUId       = SKUId,
         @vLPNSKU         = SKU,
         @vSKUDescription = SKUDescription,
         @vDisplayQty     = convert(varchar(5), @vLPNCases) + ' Case(s) / ' +
                            convert(varchar(5), @vLPNQty) + ' Units'
  from vwLPNs
  where (LPN          = @vLPN) and
        (BusinessUnit = @vBusinessUnit);

  /* Validations */
  if (@vLPNId is null)
    set @vMessageName = 'InvalidLPN';
  else
  if (coalesce(@vLPNWarehouse, '') <> @vWarehouse)
    set @vMessageName = 'SelectedLPNFromWrongWarehouse';

  /* Get OrderHeaders here */
  if (@vLPNOrderId is not null)
    select @vPickTicket   = PickTicket,
           @vLPNOrderType = OrderType
    from OrderHeaders
    where (OrderId = @vLPNOrderId);

  /* Get Batch Type here */
  if (@vLPNBatchNo is not null)
    select @vBatchType = BatchType
    from PickBatches
    where (BatchNo = @vLPNBatchNo);

  /* set operation here - If the scanned input is a tote then we need to do Picking,
                          if the batch is of replenishment type then we need to do Putaway
                          If the batchtype is Ecom-S then we will transfer the LPN to tote and
                            will suggest to pick additional items */
  select  @vOperation = case
                          when (@vBatchType = 'ECOM-S') then 'Transfer'
                          when (@vLPNOrderId is not null) and (@vLPNOrderType not in ('RU', 'RP', 'R')) then 'Picking'
                          when (@vBatchType in ('RP', 'RU' /* Replenishments */)) then 'Putaway'

                          else null
                        end;

  if (@vOperation is null)
    set @vMessageName = 'InvalidLPNToSelectOperation';
  else
  if (@vOperation = 'Picking') and (coalesce(@vPickZone, '') = '')
    set @vMessageName = 'PickZoneIsRequired';

  if (@vOperation = 'Picking')
    begin
      /* Prepare an xml with the list of needed inputs to get the next
         pick into the Tote */
      select @vInputXMLToGetPick  = (select @vLPN              as LPN,
                                            @vPickZone         as PickZone,
                                            @vLPNOrderId       as OrderId,
                                            @vLPNBatchNo       as PickBatchNo,
                                            @vWarehouse        as Warehouse ,
                                            @vBusinessUnit     as BusinessUnit,
                                            @vDeviceId         as DeviceId,
                                            @vUserId           as UserId
                                     FOR XML raw('INPUTPARAMS'), elements);

      /* if the user scan tote then we need to suggest the next pick */
      exec pr_RFC_Picking_GetPickForLPN @vInputXMLToGetPick, @xmlPickDetails output;

      /* if there is no picks found then we will raise an error */
      if (@xmlPickDetails is null)
        begin
          set @vMessageName = 'NoUnitsAvailToPickForBatch';

          goto ErrorHandler;
        end

      /* convert this xml as varchar */
      select @vxmlPickDetails = convert(varchar(max), @xmlPickDetails);
    end
  else
  if (@vOperation = 'Putaway')
    begin
      select @vLPNDestZone = PutawayZone
      from Locations
      where (Location     = @vLPNDestLoc) and
            (BusinessUnit = @vBusinessUnit);
    end

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* build xml here */
  set @vxmlLPNDetails = (select @vLPNId             as LPNId,
                                @vLPN               as LPN,
                                @vLPNType           as LPNType,
                                @vLPN               as Tote,
                                @vLPNLocationId     as LocationId,
                                @vLPNLocation       as Location,
                                @vLPNDestZone       as DestZone,
                                @vLPNDestLoc        as DestLocation,
                                @vLPNSKUId          as SKUId,
                                @vLPNSKU            as SKU,
                                @vSKUDescription    as SKUDescription,
                                @vLPNCases          as InnerPacks,
                                @vLPNQty            as Quantity,
                                @vDisplayQty        as DisplayQuantity,
                                @vLPNBatchNo        as BatchNo,
                                @vBatchType         as BatchType,
                                @vSugLocation       as SuggestedLocation,
                                @vSugPallet         as SuggestedPallet,
                                @vPickTicket        as PickTicket,
                                @vOperation         as Operation
                         FOR XML raw('LPNDetails'), elements );

  /* 4. Get Options from Controls */
  set @vxmlOptions = (select @vQtyEnabled         as QuantityEnabled,
                             @vPalletEnabled      as PalletEnabled
                      for XML raw('PROCESSLPN'), elements );

  select @vxmlResult = (select '<LPN>' +
                                    coalesce(@vxmlLPNDetails, '') +
                                 '<LPNPICKINFO>' +
                                    coalesce(@vxmlPickDetails, '') +
                                 '</LPNPICKINFO>' +
                                 '<OPTIONS>' +
                                    coalesce(@vxmlOptions, '') +
                                 '</OPTIONS>' +
                               '</LPN>');

  /* convert the result ot xml here */
  select @xmlResult = convert(xml, @vxmlResult);

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, null;

  commit transaction;
end try
begin catch
  rollback transaction;
  exec pr_BuildRFErrorXML @xmlResult output;
end catch;
end /* pr_RFC_TO_ValidateLPN */

Go
