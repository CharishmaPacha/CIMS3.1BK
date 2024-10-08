/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/14  VM      pr_ShipLabel_GetLabelsToPrintForEntity, pr_ShipLabel_GetLabelsToPrintProcess - renamed to obsolete (HA-2510)
  pr_ShipLabel_GetLabelsToPrintForEntity: changes when the Entity is Load and validated the input
  OK      pr_ShipLabel_GetLabelsToPrintForEntity: Enhanced to explod the LPNs/Pallets based on the Rules (S2G-706)
  2017/04/10  TK      pr_ShipLabel_GetLabelsToPrintForEntity:
  2016/08/19  RV      pr_ShipLabel_GetLabelsToPrintForEntity: Made changes to calculate the weight (HPI-483)
  pr_ShipLabel_GetLabelsToPrintForEntity: Do not prompt for weight if we have estimated weight
  2016/07/27  AY      pr_ShipLabel_GetLabelsToPrintForEntity: Corrections to earlier validations (NBD-474)
  2016/05/12  RV      pr_ShipLabel_GetLabelsToPrintForEntity: Don't allow to print the ship labels and update
  2015/12/05  RV      pr_ShipLabel_GetLabelsToPrintForEntity: Added procedure (NBD-53)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetLabelsToPrintForEntity') is not null
  drop Procedure pr_ShipLabel_GetLabelsToPrintForEntity;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GetLabelsToPrintForEntity: Returns all the info associated with the
    label formats to be printed for an LPN.

    InputXML:  <Root>
                 <EntityKey></EntityKey>
                 <LPNStatus></LPNStatus>
                 <PrinterName></PrinterName>     -- Not used
                 <LabelPrintSortOrder></LabelPrintSortOrder>
                 <ReprintOptions></ReprintOptions>
                 <IsLabelsRequired></IsLabelsRequired>
              </Root>

    ResultXML: <Root>
                 <LPNWeight></LPNWeight>
                 <LPNCartonType></LPNCartonType>
                 <LPNReturnTrackingNo></LPNReturnTrackingNo>
                 <IsWeightRequired></IsWeightRequired>
                 <IsCartonTypeRequired></IsCartonTypeRequired>
                 <IsReturnTrackingNoRequired></IsReturnTrackingNoRequired>
                 <Entity></Entity>
                 <EntityValue></EntityValue>
                 <EntityInfo></EntityInfo>
                 <Notes></Notes>
                 <OrderId></OrderId>
               </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetLabelsToPrintForEntity
  (@InputXML     TXML,
   @LabelTypes   XML,
   @UserId       TUserId,
   @BusinessUnit TBusinessUnit,
   @EntityInfo   TXML output,
   @ResultXML    TXML output,
   @DocListXML   TXML = null output,
   @LabelListXML TXML = null output)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TDescription,

          @vEntityKey                   TEntityKey,
          @vLPNStatus                   TStatus,
          @vPrinterName                 TDeviceId,
          @vWorkStation                 TName,
          @vLabelPrintSortOrder         TLookUpCode,
          @vReprintOptions              TPrintFlags = 'Y',
          @vIsLabelsRequired            TBoolean,

          @vNumUnitsPerLPN              TCount,
          @vUnitWeight                  TWeight,
          @vLPNWeight                   TWeight,
          @vLPNCartonType               TCartonType,
          @vEmptyCartonWeight           TWeight,
          @vLPNReturnTrackingNo         TTrackingNo,
          @vIsWeightRequired            TBoolean,
          @vIsCartonTypeRequired        TBoolean,
          @vIsReturnTrackingNoRequired  TBoolean,
          @vEntity                      TEntity,
          @vNotes                       TNote,
          @vOperation                   TOperation,

          @vLPNId                       TRecordId,
          @vLPN                         TLPN,
          @vLPNType                     TTypeCode,
          @vOrderId                     TRecordId,
          @vOrderType                   TTypeCode,
          @vCustPO                      TCustPO,
          @vShipToId                    TShipToId,
          @vSoldToId                    TCustomerId,
          @vOrderCategory1              TCategory,
          @vOwnership                   TOwnership,
          @vWarehouse                   TWarehouse,
          @vPickTicket                  TPickTicket,
          @vWaveNo                      TWaveNo,
          @vWaveType                    TTypeCode,
          @vWaveId                      TRecordId,
          @vPalletId                    TRecordId,
          @vPallet                      TPallet,
          @vLoadId                      TRecordId,
          @vLoadNumber                  TLoadNumber,
          @vPackageSeqNo                TInteger,
          @vLPNsAssigned                TCount,
          @vSourceSystem                TName,
          /* ShipVia */
          @vShipVia                     TShipVia,
          @vCarrier                     TCarrier,
          @vCarrierInterface            TCarrierInterface,
          @vCarrierType                 TCarrier,
          @vIsSmallPackageCarrier       TFlag,

          @vEntityXML                   TXML,
          @vInputXML                    XML,

          @vRulesDataXML                TXML,
          @vIsLPNExplodeRequired       TControlValue;

begin /* pr_ShipLabel_GetLabelsToPrintForEntity */
  select @vReturnCode           = 0,
         @vMessagename          = null,
         @vEntity               = null,
         @vIsWeightRequired     = 0,
         @vIsCartonTypeRequired = 0,
         @vUnitWeight           = 0,
         @vNumUnitsPerLPN       = 0,
         @vEmptyCartonWeight    = 0,
         @vIsReturnTrackingNoRequired
                                = 0,
         @vLPNWeight            = 0,
         @vLPNCartonType        = null,
         @vLPNReturnTrackingNo  = null,
         @vOperation            = 'ShippingDocs';

  select @vInputXML = cast(@InputXML as xml);

  select @vEntityKey           = Record.Col.value('EntityKey[1]'           , 'TEntityKey'),
         @vLPNStatus           = nullif(Record.Col.value('LPNStatus[1]'    , 'TStatus'), ''),
         @vPrinterName         = Record.Col.value('PrinterName[1]'         , 'TName'),
         @vWorkStation         = Record.Col.value('WorkStation[1]'         , 'TName'),
         @vLabelPrintSortOrder = Record.Col.value('LabelPrintSortOrder[1]' , 'TLookUpCode'),
         @vReprintOptions      = Record.Col.value('ReprintOptions[1]'      , 'TPrintFlags'),
         @vIsLabelsRequired    = Record.Col.value('IsLabelsRequired[1]'    , 'TBoolean')
  from @vInputXML.nodes('/Root') as Record(Col);

  /* Most often it is an LPN, so let us assume it to be and check for that first
     If numeric and greater than 8 digits or not numeric, then try LPN Id */
  if ((IsNumeric(@vEntityKey) = 0) or (Len(@vEntityKey) > 8) or (Len(@vEntityKey) = 4))
    select @vLPNId               = LPNId,
           @vLPN                 = LPN,
           @vLPNStatus           = Status,
           @vPalletId            = PalletId,
           @vLPNType             = LPNType,
           @vOrderId             = OrderId,
           @vNumUnitsPerLPN      = Quantity,
           @vOwnership           = Ownership,
           @vLPNWeight           = coalesce(nullif(ActualWeight, 0), EstimatedWeight),
           @vLPNCartonType       = CartonType,
           @vLPNReturnTrackingNo = ReturnTrackingNo,
           @vEntity              = 'LPN',
           @vEntityKey           = LPN,
           @vOrderType           = OrderType,
           @vPackageSeqNo        = PackageSeqNo,
           @vWaveId              = PickBatchId,
           @vWaveNo              = PickBatchNo
    from vwLPNs
    where (LPNId = dbo.fn_LPNs_GetScannedLPN(@vEntityKey, @BusinessUnit, default /* Options */));

  /* If it is not an LPN, then check if it is a pallet */
  if (@vEntity is null)
    select @vPalletId  = PalletId,
           @vPallet    = Pallet,
           @vOrderId   = OrderId,
           @vOwnership = Ownership,
           @vEntity    = 'Pallet'
    from Pallets
    where (Pallet       = @vEntityKey) and
          (BusinessUnit = @BusinessUnit);

  /* If we have not yet identified it, then check if it is a PickTicket */
  if (@vEntity is null)
    select @vOrderId = OrderId,
           @vEntity  = 'PickTicket'
    from OrderHeaders
    where (PickTicket   = @vEntityKey) and
          (BusinessUnit = @BusinessUnit)

  select @vOrderId        = OrderId,
         @vPickTicket     = PickTicket,
         @vCustPO         = CustPO,
         @vShipToId       = ShipToId,
         @vSoldToId       = SoldToId,
         @vOwnership      = Ownership,
         @vOrderType      = OrderType,
         @vLPNsAssigned   = LPNsAssigned,
         @vOrderCategory1 = OrderCategory1,
         @vWarehouse      = Warehouse,
         @vShipVia        = ShipVia,
         @vSourceSystem   = SourceSystem
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* If we have not yet identified it, then check if it is a Wave */
  if (@vEntity is null)
    select @vWaveNo      = BatchNo,
           @vEntity      = 'PickBatchNo',
           @vWaveType    = BatchType,
           @vWaveId      = RecordId
    from PickBatches
    where (BatchNo      = @vEntityKey) and
          (BusinessUnit = @BusinessUnit);

  /* If we have not yet identified it, then check if it is a Load */
  if (@vEntity is null)
    select @vLoadId      = LoadId,
           @vLoadNumber  = LoadNumber,
           @vEntity      = 'Load'
    from Loads
    where (LoadNumber   = @vEntityKey) and
          (BusinessUnit = @BusinessUnit);

   /* Wave information */
   if (@vWaveType is null)
     select @vWaveType = WaveType
     from Waves
     where (WaveId = @vWaveId);

  /* Get the Ship Via on the carrier */
  select @vCarrier               = Carrier,
         @vCarrierType           = CarrierType,
         @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from vwShipVias
  where (ShipVia = @vShipVia);

  if (@vEntityKey is null)
    select @vMessageName = 'ShipLabel_InvalidInput';
  else
  if (@vEntity is null)
    select @vMessageName = 'ShipLabel_NotaValidEntity';
  else
  if (@vOrderType in ('RU', 'RP' /* Replenish Units, Replenish packages */))
    select @vMessageName = 'ShipLabel_ReplenishOrder';
  else
  if (@vWaveType in ('REP', 'R' /* Replenish */))
    select @vMessageName = 'ShipLabel_ReplenishWave';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* if Printer is not given, identify the printer setup for the Workstation */
  if (coalesce(@vPrinterName, '') = '')
    exec pr_Devices_GetConfiguredPrinter @vWorkStation, 'ShippingDocs', @BusinessUnit, @vPrinterName out;

  select @vEntityXML = dbo.fn_XMLNode('Root',
                       dbo.fn_XMLNode('Entity',    @vEntity) +
                       dbo.fn_XMLNode('EntityKey', @vEntityKey));

  exec pr_ShipLabel_GetEntityInfo @vEntityXML, @UserId, @BusinessUnit, @EntityInfo output;

  /* Build the data for rule evaluation */
  select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('Entity',                 @vEntity        ) +
                            dbo.fn_XMLNode('Operation',              'ShippingDocs'  ) +
                            dbo.fn_XMLNode('LabelTypesXML',          cast(@LabelTypes as varchar(max))) +
                            dbo.fn_XMLNode('Printer',                @vPrinterName   ) +
                            -- LPN
                            dbo.fn_XMLNode('LPNId',                  @vLPNId         ) +
                            dbo.fn_XMLNode('LPN',                    @vLPN           ) +
                            dbo.fn_XMLNode('LPNType',                @vLPNType       ) +
                            dbo.fn_XMLNode('PackageSeqNo',           @vPackageSeqNo  ) +
                            dbo.fn_XMLNode('PalletId',               @vPalletId      ) +
                            dbo.fn_XMLNode('LoadId',                 @vLoadId        ) +
                            dbo.fn_XMLNode('LPNStatus',              @vLPNStatus     ) +
                            -- Wave
                            dbo.fn_XMLNode('WaveId',                 @vWaveId        ) +
                            dbo.fn_XMLNode('WaveType',               @vWaveType      ) +
                            dbo.fn_XMLNode('WaveNo',                 @vWaveNo        ) +
                            -- Order
                            dbo.fn_XMLNode('OrderId',                @vOrderId       ) +
                            dbo.fn_XMLNode('PickTicket',             @vPickTicket    ) +
                            dbo.fn_XMLNode('OrderType',              @vOrderType     ) +
                            dbo.fn_XMLNode('CustPO',                 @vCustPO        ) +
                            dbo.fn_XMLNode('ShipToId',               @vShipToId      ) +
                            dbo.fn_XMLNode('SoldToId',               @vSoldToId      ) +
                            dbo.fn_XMLNode('OrderCategory1',         @vOrderCategory1) +
                            dbo.fn_XMLNode('LPNsAssigned',           @vLPNsAssigned  ) +
                            dbo.fn_XMLNode('Ownership',              @vOwnership     ) +
                            dbo.fn_XMLNode('Warehouse',              @vWarehouse     ) +
                            dbo.fn_XMLNode('SourceSystem',           @vSourceSystem  ) +
                            -- ShipVia
                            dbo.fn_XMLNode('IsSmallPackageCarrier',  @vIsSmallPackageCarrier) +
                            dbo.fn_XMLNode('ShipVia',                @vShipVia) +
                            dbo.fn_XMLNode('Carrier',                @vCarrier) +
                            dbo.fn_XMLNode('CarrierInterface',       @vCarrierInterface)
                            );

  /* Get the comments to be shown for the related Order */
  if (@vOrderId is not null)
    select @vNotes = dbo.fn_Notes_GetNotesAsHTML('PT', @vOrderId, null /* PT */, 'Default', @BusinessUnit, @UserId)

  if (@vEntity in ('LPN', 'Pallet', 'PickTicket'))
    begin
      /* For particular order only we need to explode the LPN. Rules will determine whether exploding is required or not */
      exec pr_RuleSets_Evaluate 'OnShipping_ExplodeLPN', @vRulesDataXML, @vIsLPNExplodeRequired output;

      if (@vIsLPNExplodeRequired = 'Y' /* Yes */)
        exec pr_LPNs_ExplodeLPNs @vLPNId, default /* ttLPNs */, @vPalletId, @vOrderId, null /* Options */,
                                 @BusinessUnit, @UserId;

    end

  if (@vIsLabelsRequired = 1)
    begin
      /* we do not need CartonType or Weight for Totes/Cart positions, we may still be printing Price stickers using them */
      if (@vEntity = 'LPN') and (coalesce(@vLPNStatus, '') in ('K', 'D' /* Picked, Packed */)) and
         (@vLPNType not in ('A', 'TO'))
        begin
          /* If LPN does not have weight or CartonType, then set flags for them to be captured from UI */
          if (coalesce(@vLPNWeight, 0) < 0.01)
            begin
              /* Get the estimated carton weight by getting weight of empty carton + weight of items inside */
              -- ToDo: refactor this into a function or procedure pr_LPNs_GetEstimatedWeight input LPNId, Options
              -- Options: C - if no cartontype, then estimatedweight would be null, U - If no unit weight on any SKUs, then return null as well.
              if (coalesce(@vLPNCartonType, '') <> '')
                select @vEmptyCartonWeight = EmptyWeight
                from CartonTypes
                where (CartonType = @vLPNCartonType);

              select @vLPNWeight = sum(UnitWeight * Quantity)
              from vwLPNDetails
              where LPNId = @vLPNId
              group by LPNId;

              select @vLPNWeight = @vLPNWeight + @vEmptyCartonWeight

              select @vIsWeightRequired = 1;
            end

          if (coalesce(@vLPNCartonType, '') = '')
            select @vIsCartonTypeRequired = 1;

          if (coalesce(@vLPNReturnTrackingNo, '') = '')
            select @vIsReturnTrackingNoRequired = 1;  -- this is not required for HPI.
        end

      exec pr_ShipLabel_GetLabelsToPrintProcess @vLoadNumber, @vWaveNo, @vPickTicket, @vPallet, @vLPN,
                                                @vLPNStatus, @LabelTypes, @vOperation, @vPrinterName, @vLabelPrintSortOrder,
                                                @vReprintOptions, @UserId, @BusinessUnit;
    end

  /* Get list of all relevant documents to print based upon the input Rules data */
  exec pr_Shipping_GetDocumentListToPrint @vRulesDataXML, @DocListXML output;

  /* Get list of all relevant labels to print based upon the input Rules data */
  exec pr_Shipping_GetLabelListToPrint @vRulesDataXML, @LabelListXML output;

  select @ResultXML = dbo.fn_XMLNode('Root',
                        dbo.fn_XMLNode('LPNWeight',            coalesce(@vLPNWeight, 0)) +
                        dbo.fn_XMLNode('LPNCartonType',        @vLPNCartonType) +
                        dbo.fn_XMLNode('LPNReturnTrackingNo',  @vLPNReturnTrackingNo) +
                        dbo.fn_XMLNode('IsWeightRequired',     @vIsWeightRequired) +
                        dbo.fn_XMLNode('IsCartonTypeRequired', @vIsCartonTypeRequired) +
                        dbo.fn_XMLNode('IsReturnTrackingNoRequired',
                                                               @vIsReturnTrackingNoRequired) +
                        dbo.fn_XMLNode('Entity',               @vEntity) +
                        dbo.fn_XMLNode('EntityValue',          @vEntityKey) +
                        dbo.fn_XMLNode('Notes',                @vNotes) +
                        dbo.fn_XMLNode('Ownership',            @vOwnership) +
                        dbo.fn_XMLNode('OrderId',              @vOrderId));

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ShipLabel_GetLabelsToPrintForEntity */

Go

/* V2 proc - not required in V3. Will remove after certain time (HA-2510) */
exec sp_Rename 'pr_ShipLabel_GetLabelsToPrintForEntity', 'pr_ShipLabel_GetLabelsToPrintForEntity_Obsolete'

Go
