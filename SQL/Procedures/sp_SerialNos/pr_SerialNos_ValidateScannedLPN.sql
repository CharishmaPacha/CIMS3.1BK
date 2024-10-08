/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/18  RIA     pr_SerialNos_Capture, pr_SerialNos_ValidateScannedLPN, pr_SerialNos_Clear: Changes and corrections (CIMSV3-1211)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SerialNos_ValidateScannedLPN') is not null
  drop Procedure pr_SerialNos_ValidateScannedLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_SerialNos_ValidateScannedLPN: This procedure validates the Scanned LPN

    @xmlInput Structure:
      <ScannedLPNInfo>
        <LPN></LPN>
        <Operation></Operation>
        <DeviceId></DeviceId>
        <BusinessUnit></BusinessUnit>
        <UserId></UserId>
      </ScannedLPNInfo>

    @xmlResult Structure:
      <ScannedLPNResponse>
        <LPNInfo>
          <LPN>C000000802</LPN>
          <LPNQuantity>2</LPNQuantity>
        </LPNInfo>
        <SerialNosInfo>
           <SerialNos>
             <SerialNo>AA10000431</SerialNo>
             <Status>A</Status>
           </SerialNos>
           <SerialNos>
             <SerialNo>AA1212132</SerialNo>
             <Status>A</Status>
           </SerialNos>
        </SerialNosInfo>
        <Options>
          <ScanOption>O</ScanOption>
          <ConfirmationMessage>Scanned LPN has valid Serial Nos</ConfirmationMessage>
        </Options>
      </ScannedLPNResponse>
------------------------------------------------------------------------------*/
Create Procedure pr_SerialNos_ValidateScannedLPN
  (@xmlInput       xml,
   @xmlResult      xml      output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vMessage             TMessage,

          @LPN                  TLPN,
          @Operation            TOperation,
          @DeviceId             TDeviceId,
          @UserId               TUserId,
          @BusinessUnit         TBusinessUnit,

          @vSKUId               TRecordId,
          @vUnitsPerInnerPack   TQuantity,

          @vLPNId               TRecordId,
          @vLPN                 TLPN,
          @vLPNStatus           TStatus,
          @vLPNQuantity         TQuantity,
          @vSerialNoCount       TCount,

          @vValidLPNStatuses    TControlValue,
          @vActivityLogId       TRecordId,
          @vScanOption          TFlags,
          @vConfirmationMsg     TMessage,

          @vLPNInfoXml          TXML,
          @vSerialNosXml        TXML,
          @vOptionsXml          TXML;
begin /* pr_SerialNos_ValidateScannedLPN */
  SET NOCOUNT ON;

  /* Get the XML User inputs in to the local variables */
  select @LPN          = Record.Col.value('LPN[1]'           , 'TLPN'),
         @Operation    = Record.Col.value('Operation[1]'     , 'TOperation'),
         @BusinessUnit = Record.Col.value('BusinessUnit[1]'  , 'TBusinessUnit'),
         @UserId       = Record.Col.value('UserId[1]'        , 'TUserId'),
         @DeviceId     = Record.Col.value('DeviceId[1]'      , 'TDeviceId')
  from @xmlInput.nodes('ScannedLPNInfo') as Record(Col);

  /* get Controls */
  select @vValidLPNStatuses = dbo.fn_Controls_GetAsString('SerialNos', 'ValidLPNStatuses', 'RPAKDEL', @BusinessUnit, @UserId);

  /* get LPN info */
  select @vLPNId       = LPNId,
         @vLPN         = LPN,
         @vLPNStatus   = Status,
         @vSKUId       = SKUId,
         @vLPNQuantity = Quantity
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@LPN, @BusinessUnit, 'LTU'));

  select @vUnitsPerInnerPack = UnitsPerInnerPack
  from SKUs
  where (SKUId = @vSKUId);

  /* get Serial Nos count */
  select @vSerialNoCount = count(*)
  from SerialNos
  where (LPNId  = @vLPNId) and
        (SerialNoStatus = 'A'/* Assigned */);

  /* Validations */
  if (@vLPNId is null)
    set @vMessageName = 'SerialNos_InvalidScannedLPN';
  else
  if (@vLPNQuantity = 0)
    set @vMessageName = 'SerialNos_ScannedEmptyLPN';
  else
  if (dbo.fn_IsInList(@vLPNStatus, @vValidLPNStatuses) = 0)
    set @vMessageName = 'SerialNos_InvalidLPNStatus';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* If LPN Quantity matches with the serial no count then scanning Serial Nos should be optional */
  if (@vLPNQuantity = coalesce(@vSerialNoCount, 0))
    begin
      select @vScanOption = 'O'/* Optional */,
             @vConfirmationMsg = dbo.fn_Messages_GetDescription('SerialNos_ScannedLPNHasValidSerialNos')
    end
  else
    select @vScanOption = 'Y'/* Yes */;

  /* Build LPN xml */
  set @vLPNInfoXml = (select @vLPNId             as LPNId,
                             @vLPN               as LPN,
                             @vUnitsPerInnerPack as UnitsPerInnerPack,
                             @vLPNQuantity       as LPNQuantity,
                             @vSerialNoCount     as SerialNoCount
                      for XML raw('LPNInfo'), elements);

  /* Build Serial Nos xml */
  set @vSerialNosXml = dbo.fn_XMLNode('SerialNosInfo',
                                        (select *
                                         from SerialNos
                                         where (LPNId = @vLPNId)
                                         for XML raw('SerialNos'), elements));

  /* Build Options xml */
  set @vOptionsXml = (select @vScanOption       as ScanOption,
                             @vConfirmationMsg  as ConfirmationMessage
                      for XML raw('Options'), elements);

  /* Build XML Result */
  set @xmlResult = dbo.fn_XMLNode('ScannedLPNResponse',
                                    coalesce(@vLPNInfoXml,   '') +
                                    coalesce(@vSerialNosXml, '') +
                                    coalesce(@vOptionsXml,   ''));

/* On Error, return Error Code/Error Message */
ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;
end /* pr_SerialNos_ValidateScannedLPN */

Go
