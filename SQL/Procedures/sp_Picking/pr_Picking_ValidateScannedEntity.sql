/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/03  TK      pr_Picking_ValidateScannedEntity: Changes to get ConfirmScanOption from latest xml (HA-1392)
  2018/08/12  RV      pr_Picking_ValidateScannedEntity: Made changes to get the current picking response from separate field,
  2018/08/03  SK      pr_Picking_ValidateScannedEntity: By passing Entity Scan for short pick (OB2-415)
  2018/05/07  RV      pr_Picking_ValidateScannedEntity: Initial version
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ValidateScannedEntity') is not null
  drop Procedure pr_Picking_ValidateScannedEntity;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_ValidateScannedEntity: In Picking, user is given multiple choices
   to confirm that he/she is picking the right inventory. The valid options are
   sent to RF and are confirmed right off in RF. However, when user is allowed
   to scan an LPN, user may not always be scanning the suggested LPN as user is
   trying to substitute - in that case we cannot validate on RF. Hence, the validation
   to see if user scanned the right entity is being done on RF and if considered
   valid, all necessary values are returned to confirm the picks.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_ValidateScannedEntity
  (@xmlInput            xml,
   @SKUPicked           TSKU         output,
   @LPNPicked           TLPN         output,
   @PickedFromLocation  TLocation    output,
   @MessageName         TMessageName = null output,
   @ScannedEntityType   TTypeCode    = null output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,

          @DeviceId                            TDeviceId,
          @UserId                              TUserId,
          @BusinessUnit                        TBusinessUnit,
          @PickBatchNo                         TPickBatchNo,
          @vWaveType                           TTypeCode,
          @PickZone                            TZoneId,
          @PickTicket                          TPickTicket,
          @vOrderCategory3                     TCategory,
          @SuggestedLPNPickingClass            TPickingClass,
          @PickedLPNPickingClass               TPickingClass,
          @PickingPallet                       TPallet,
          @vPalletType                         TTypeCode,
          @OrderDetailId                       TRecordId,
          @FromSKU                             TSKU,
          @FromLPN                             TLPN,
          @vFromLPNId                          TRecordId,
          @FromLPNId                           TRecordId,
          @vFromLPNDetailId                    TRecordId,
          @LPNDetailId                         TRecordId,
          @PickType                            TLookUpCode,
          @OrgPickType                         TLookUpCode,
          @TaskId                              TRecordId,
          @vTaskId                             TRecordId,
          @TaskDetailId                        TRecordId,
          @ToLPN                               TLPN,
          @ScannedEntity                       TEntityKey,
          @PickUoM                             TUoM,
          @vShipPack                           TInteger,
          @UnitsPicked                         TInteger,
          @ShortPick                           TFlag,
          @EmptyLocation                       TFlags,
          @ConfirmEmptyLocation                TFlags,
          @DestZone                            TLookUpCode,
          @Operation                           TOperation,
          @PickingType                         TDescription,
          @PickGroup                           TPickGroup,

          @vScannedEntityType                  TEntity,
          @vScannedEntityKey                   TEntityKey,
          @vSKU                                TSKU,
          @vSKUId                              TRecordId,
          @vUPC                                TUPC,
          @vCaseUPC                            TUPC,
          @vBarcode                            TBarcode,
          @vAlternateSKU                       TSKU,
          @vLPN                                TLPN,
          @vFromLocation                       TLocation,
          @vTDPickType                         TTypeCode,

          @vGetBatchPickResponse               TXML,
          @vXMLGetBatchPickResponse            xml,
          @vConfirmScanOption                  TControlValue;

begin /* pr_Picking_ValidateScannedEntity */

  select @vReturnCode  = 0,
         @vMessageName = null;

  if (@xmlInput is not null)
    select @DeviceId             = Record.Col.value('DeviceId[1]',             'TDeviceId'),
           @UserId               = Record.Col.value('UserId[1]',               'TUserId'),
           @BusinessUnit         = Record.Col.value('BusinessUnit[1]',         'TBusinessUnit'),
           @PickBatchNo          = nullif(Record.Col.value('PickBatchNo[1]',   'TPickBatchNo'), ''),
           @PickZone             = nullif(Record.Col.value('PickZone[1]',      'TZoneId'), ''),
           @PickTicket           = nullif(Record.Col.value('PickTicket[1]',    'TPickTicket'), ''),
           @PickingPallet        = Record.Col.value('PickingPallet[1]',        'TPallet'),
           @OrderDetailId        = Record.Col.value('OrderDetailId[1]',        'TRecordId'),
           @FromSKU              = Record.Col.value('FromSKU[1]',              'TSKU'),
           @FromLPN              = Record.Col.value('FromLPN[1]',              'TLPN'),
           @FromLPNId            = Record.Col.value('FromLPNId[1]',            'TRecordId'),
           @LPNDetailId          = Record.Col.value('FromLPNDetailId[1]',      'TRecordId'),
           @PickType             = Record.Col.value('PickType[1]',             'TTypeCode'),
           @TaskId               = Record.Col.value('TaskId[1]',               'TRecordId'),
           @TaskDetailId         = Record.Col.value('TaskDetailId[1]',         'TRecordId'),
           @ToLPN                = nullif(Record.Col.value('ToLPN[1]',         'TLPN'), ''),
           @ScannedEntity        = Record.Col.value('ScannedEntity[1]',        'TEntityKey'),
           @UnitsPicked          = Record.Col.value('UnitsPicked[1]',          'TInteger'),
           @PickedFromLocation   = Record.Col.value('PickedFromLocation[1]',   'TLocation'),
           @PickUoM              = Record.Col.value('PickUoM[1]',              'TUoM'),
           @ShortPick            = Record.Col.value('ShortPick[1]',            'TFlag'),
           @EmptyLocation        = Record.Col.value('LocationEmpty[1]',        'TFlags'),
           @ConfirmEmptyLocation = Record.Col.value('ConfirmLocationEmpty[1]', 'TFlags'),
           @DestZone             = Record.Col.value('DestZone[1]',             'TLookUpCode'),
           @Operation            = Record.Col.value('Operation[1]',            'TDescription'),
           @PickingType          = Record.Col.value('PickingType[1]',          'TDescription'),
           @PickGroup            = Record.Col.value('PickGroup[1]',            'TPickGroup'),
           @vConfirmScanOption   = Record.Col.value('ConfirmScanOption[1]',    'TControlValue')
    from @xmlInput.nodes('ConfirmBatchPick') as Record(Col);

  select @vSKU          = SKU,
         @vLPN          = LPN,
         @vFromLocation = Location,
         @vTDPickType   = TDPickType,
         @vUPC          = UPC,
         @vCaseUPC      = CaseUPC,
         @vBarcode      = SKUBarcode,
         @vAlternateSKU = AlternateSKU
  from vwTaskDetails
  where (TaskDetailId = @TaskDetailId);

  /* Determine what the user scanned to confirm the Pick */
  if (@ScannedEntity = @vSKU) and (charindex('S' /* SKU */, @vConfirmScanOption) > 0)
    select @vScannedEntityType = 'SKU';
  else
  if (@ScannedEntity = @vUPC) and (charindex('U' /* UPC */, @vConfirmScanOption) > 0)
    select @vScannedEntityType = 'UPC';
  else
  if (@ScannedEntity = @vCaseUPC) and (charindex('C' /* CaseUPC */, @vConfirmScanOption) > 0)
    select @vScannedEntityType = 'CaseUPC';
  else
  if (@ScannedEntity = @vBarcode) and (charindex('B' /* Barcode */, @vConfirmScanOption) > 0)
    select @vScannedEntityType = 'Barcode';
  else
  if (@ScannedEntity = @vAlternateSKU) and (charindex('A' /* Alternate SKU */, @vConfirmScanOption) > 0)
    select @vScannedEntityType = 'AlternateSKU';
  else
  if (@ScannedEntity = @vFromLocation) and (charindex('O' /* From Location */, @vConfirmScanOption) > 0)
    select @vScannedEntityType = 'Location';
  else
  if (@ScannedEntity = @FromLPN) and (charindex('L' /* LPN */, @vConfirmScanOption) > 0)
    select @vScannedEntityType = 'LPN';
  else
  /* If user was allowed to scan confirm using an LPN, check if user scanned another LPN */
  if (charindex('L' /* LPN */, @vConfirmScanOption) > 0)
    begin
      /* If user scanned another valid LPN, then get its' details. We don't care about
         the validity of the substitution here, that is done later. We are only confirming
         what the user scanned */
      select @vScannedEntityType = 'LPN',
             @vLPN               = LPN,
             @vFromLocation      = Location,
             @vSKU               = SKU
      from vwLPNs
      where (LPN = @ScannedEntity) and (BusinessUnit = @BusinessUnit);
    end

  /* If user scan valid entity then we confirm with the values of the Task Details or
    those of the valid LPN that user is trying to substitute with */
  if (@vScannedEntityType is not null)
    select @SKUPicked          = @vSKU,
           @LPNPicked          = @vLPN,
           @PickedFromLocation = @vFromLocation,
           @ScannedEntityType  = @vScannedEntityType
  else
  if (@vScannedEntityType is null and coalesce(@ShortPick, '') not in ('', 'N'/* No */))
    select @MessageName = @vMessageName; /* Do nothing */
  else
    select @MessageName = 'InvalidScannedEntity';

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_ValidateScannedEntity */

Go
