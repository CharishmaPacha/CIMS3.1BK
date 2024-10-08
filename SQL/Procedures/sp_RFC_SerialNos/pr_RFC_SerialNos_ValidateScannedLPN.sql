/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/08  TK      pr_RFC_SerialNos_ValidateScannedLPN & pr_RFC_SerialNos_AddOrReplace:
                        Initial Revision (S2GMI-81)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_SerialNos_ValidateScannedLPN') is not null
  drop Procedure pr_RFC_SerialNos_ValidateScannedLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_SerialNos_ValidateScannedLPN: This procedure validates the Scanned LPN

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
Create Procedure pr_RFC_SerialNos_ValidateScannedLPN
  (@xmlInput       xml,
   @xmlResult      xml   output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vMessage             TMessage,

          @LPN                  TLPN,
          @Operation            TOperation,
          @DeviceId             TDeviceId,
          @UserId               TUserId,
          @BusinessUnit         TBusinessUnit,

          @vLPNId               TRecordId,
          @vLPN                 TLPN,

          @vActivityLogId       TRecordId;

begin /* pr_RFC_SerialNos_ValidateScannedLPN */
begin try
  SET NOCOUNT ON;

  /* Get the XML User inputs in to the local variables */
  select @LPN          = Record.Col.value('LPN[1]'           , 'TLPN'),
         @Operation    = Record.Col.value('Operation[1]'     , 'TOperation'), -- Not used currently
         @BusinessUnit = Record.Col.value('BusinessUnit[1]'  , 'TBusinessUnit'),
         @UserId       = Record.Col.value('UserId[1]'        , 'TUserId'),
         @DeviceId     = Record.Col.value('DeviceId[1]'      , 'TDeviceId')
  from @xmlInput.nodes('ScannedLPNInfo') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      null, @LPN, 'LPN', @Operation, @ActivityLogId = @vActivityLogId output;

  /* get LPN info */
  select @vLPNId = LPNId,
         @vLPN   = LPN
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@LPN, @BusinessUnit, 'LTU'));

  exec pr_SerialNos_ValidateScannedLPN @xmlInput, @xmlResult output;

/* On Error, return Error Code/Error Message */
ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Mark the end of the transaction */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

end try
begin catch
  /* Build Error XML */
  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_SerialNos_ValidateScannedLPN */

Go
