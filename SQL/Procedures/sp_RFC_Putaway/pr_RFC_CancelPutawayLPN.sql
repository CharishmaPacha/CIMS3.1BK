/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/11/03  AJ      pr_RFC_CancelPutawayLPN: Added RFLog
  2018/10/28  VS      pr_RFC_ValidatePutawayLPNs, pr_RFC_CancelPutawayLPNs: Added Logging
  2017/07/07  RV      pr_RFC_CancelPutawayLPN, pr_RFC_ConfirmPutawayLPN, pr_RFC_ValidatePutawayLPN: Procedure id
                      pr_RFC_CancelPutawayLPNs: Initial Revision
  2015/09/25  TK      pr_RFC_CancelPutawayLPN & pr_RFC_ConfirmPutawayLPN: Added Activity Logs (ACME-348)
  2014/08/18  PV      pr_RFC_CancelPutawayLPN: Added to clear the Destination location, store zone when putaway operation is canceled.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_CancelPutawayLPN') is not null
  drop Procedure pr_RFC_CancelPutawayLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_CancelPutawayLPN: This procedure will clear DestLocation, DestZone and the suggested Location status,
  when user cancells putaway. This procedure will take xml as input.

  Input:
<?xml version="1.0" encoding="utf-8"?>
<CancelPutawayLPN xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <LPN>P01-002-1</LPN>
  <Warehouse>PGH</Warehouse>
  <BusinessUnit>GNC</BusinessUnit>
  <UserId>prasad</UserId>
  <DeviceId>Pocket_PC</DeviceId>
</CancelPutawayLPN>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_CancelPutawayLPN
  (@xmlInput   TXML,
   @xmlResult  TXML output)
as
  declare @vLPNId     TRecordId,
          @vLPN       TLPN,

          @vLocationId     TRecordId,
          @vLocation       TLocation,
          @vWarehouse      TWarehouse,
          @vBusinessUnit   TBusinessUnit,
          @vDeviceId       TDeviceId,
          @vUserId         TUserId,

          @vXMLInput     XML,
          @vXMLResult    XML,

          @vActivityLogId TRecordId,

          @ReturnCode    TInteger,
          @MessageName   TMessageName,
          @Message       TDescription;
begin
begin try
  SET NOCOUNT ON;

  set @vxmlInput =  convert(XML, @xmlInput);

  /* Get the Input params */
  select @vLPN            = Record.Col.value('LPN[1]', 'TLPN'),
         @vWarehouse      = Record.Col.value('Warehouse[1]',    'TWarehouse'),
         @vBusinessUnit   = Record.Col.value('BusinessUnit[1]', 'TLPN'),
         @vDeviceId       = Record.Col.value('DeviceId[1]', 'TDeviceId'),
         @vUserId         = Record.Col.value('UserId[1]', 'TUserId')
  from @vXMLInput.nodes('/CancelPutawayLPN') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @vxmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      null, @vLPN, 'LPN',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get LPN Info into local variables */
  select @vLPNId       = LPNId,
         @vLPN         = LPN,
         @vLocation    = DestLocation
  from LPNs
  where (LPN           = @vLPN         ) and
        (BusinessUnit  = @vBusinessUnit) and
        (DestWarehouse = @vWarehouse   );

  /* Call pr_LPNs_SetLocation to clear the DestLocation,
     DestZone and the suggested Location status updated during putaway suggestion */
  exec @ReturnCode = pr_LPNs_SetDestination @vLPNId, 'ClearDestination';

  if (@ReturnCode = 0)
    begin
      exec pr_BuildRFSuccessXML 'CancelPutawayLPNSuccessful', @vXMLResult output, @vLPN;
      set @xmlResult = convert(varchar(max), @vXMLResult);
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_CancelPutawayLPN */

Go
