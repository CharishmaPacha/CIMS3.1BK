/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/01  YJ      pr_RFC_SerialNos_Capture: Migrated from Prod (S2GCA-98)
  2019/03/13  RV      pr_RFC_SerialNos_Capture: Moved the code to pr_SerialNos_Capture (S2GCA-507)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_SerialNos_Capture') is not null
  drop Procedure pr_RFC_SerialNos_Capture;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_SerialNos_Capture: This procedure Add or Replaces Serial Nos for scanned LPN.

  @xmlInput XML Structure:
    <ScannedLPNResponse>
      <LPNInfo>
        <LPNId>6697</LPNId>
        <LPN>S000000206</LPN>
        <LPNQuantity>2</LPNQuantity>
        <UpdateOption>R</UpdateOption>
        <BusinessUnit>S2G</BusinessUnit>
        <UserId>cimsadmin</UserId>
      </LPNInfo>
      <CapturedSerialNosInfo>
        <SerialNos>
          <SerialNo>12232444asd</SerialNo>
        </SerialNos>
      </CapturedSerialNosInfo>
      <Options />
  </ScannedLPNResponse>

  update Option: A - Add, R-Replace
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_SerialNos_Capture
  (@xmlInput       xml,
   @xmlResult      xml   output)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TMessage,

          @LPN                      TLPN,
          @Operation                TOperation,
          @UpdateOption             TFlags,
          @DeviceId                 TDeviceId,
          @UserId                   TUserId,
          @BusinessUnit             TBusinessUnit,

          @vLPNId                   TRecordId,
          @vLPN                     TLPN,
          @vActivityLogId           TRecordId;
begin /* pr_RFC_SerialNos_Capture */
begin try
  SET NOCOUNT ON;

  /* Get the XML User inputs in to the local variables */
  select @LPN          = Record.Col.value('LPN[1]'           , 'TLPN'),
         @Operation    = Record.Col.value('Operation[1]'     , 'TOperation'),
         @UpdateOption = Record.Col.value('UpdateOption[1]'  , 'TFlags'),
         @BusinessUnit = Record.Col.value('BusinessUnit[1]'  , 'TBusinessUnit'),
         @UserId       = Record.Col.value('UserId[1]'        , 'TUserId'),
         @DeviceId     = Record.Col.value('DeviceId[1]'      , 'TDeviceId')
  from @xmlInput.nodes('ScannedLPNResponse/LPNInfo') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      null, @LPN, 'LPN', @Operation, @Value1 = @UpdateOption,
                      @ActivityLogId = @vActivityLogId output;

  exec pr_SerialNos_Capture @xmlInput, @xmlResult output, @vMessage output

  /* Build XML Result */
  exec pr_BuildRFSuccessXML @vMessage, @xmlResult output;

  /* Mark the end of the transaction */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;


end try
begin catch
  if (@@trancount > 0) rollback;

  /* Build Error XML */
  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_SerialNos_Capture */

Go
