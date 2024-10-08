/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/10/28  RT      pr_RFC_PA_ConfirmPutawayPallet, pr_RFC_PutawayLPNsGetNextLPN: Added Logs
  2016/02/25  TK      pr_RFC_ValidatePutawayLPNs: Initial Revision
                      pr_RFC_CancelPutawayLPNs: Initial Revision
                      pr_RFC_PutawayLPNsGetNextLPN: InitialRevision (GNC-1247)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_PutawayLPNsGetNextLPN') is not null
  drop Procedure pr_RFC_PutawayLPNsGetNextLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_PutawayLPNsGetNextLPN: This proc will return next LPN to be putaway on the Pallet
                                        in the desired Sequence

  @xmlInput Structure:
   <GETNEXTLPN>
      <Pallet></Pallet>
      <Operation></Operation>
      <SubOperation></SubOperation>
      <DeviceId></DeviceId>
      <BusinessUnit></BusinessUnit>
      <UserId></UserId>
   </GETNEXTLPN>

  @xmlResult Structure:
   <PUTAWAYLPNS>
      <PALPNDETAILS>
        <Pallet></Pallet>
        <LPN></LPN>
        <SKU></SKU>
        <UPC></UPC>
        <SKUDescription></SKUDescription>
        <Quantity></Quantity>
        <DestZone></DestZone>
        <DestLocation></DestLocation>
        <NumCasesOnPallet></NumCasesOnPallet>
        <AllowScan>Y</AllowScan>
        <SubOperation></SubOperation>
      </PALPNDETAILS>
   </PUTAWAYLPNS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_PutawayLPNsGetNextLPN
  (@xmlInput         TXML,
   @xmlResult        TXML       output)
as
  declare @ReturnCode           TInteger,
          @vMessageName         TMessageName,
          @Message              TDescription,
          @ConfirmMessage       TDescription,
          @SubOperation         TOperation,

          @vRecordId            TRecordId,
          @BusinessUnit         TBusinessUnit,
          @UserId               TUserId,
          @DeviceId             TUserId,
          @vActivityLogId       TRecordId,

          @vPalletId            TRecordId,
          @Pallet               TPallet,
          @vPallet              TPallet,

          @xmlInputInfo         xml,
          @vxmlResult           xml;
begin
begin try
  SET NOCOUNT ON;

  /* convert into xml */
  select @xmlInputInfo = convert(xml, @xmlInput);

  /* Get the XML User inputs into the local variables */
  select @Pallet       = Record.Col.value('Pallet[1]'        , 'TPallet'),
         @SubOperation = Record.Col.value('SubOperation[1]'  , 'TOperation'),
         @BusinessUnit = Record.Col.value('BusinessUnit[1]'  , 'TBusinessUnit'),
         @UserId       = Record.Col.value('UserId[1]'        , 'TUserId'),
         @DeviceId     = Record.Col.value('DeviceId[1]'      , 'TDeviceId')
  from @xmlInputInfo.nodes('GETNEXTLPN') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      null, @Pallet, 'Pallet', @Value1 = @SubOperation,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get the Pallet Details */
  select @vPalletId = PalletId,
         @vPallet   = Pallet
  from Pallets
  where (Pallet       = @Pallet      ) and
        (BusinessUnit = @BusinessUnit);

  /* Find the next LPN to be Putaway and build the response with it */
  exec @ReturnCode = pr_Putaway_PutawayLPNsBuildResponse @vPalletId,
                                                         @vPallet,
                                                         @SubOperation,
                                                         @BusinessUnit,
                                                         @UserId,
                                                         @vxmlResult output;

  /* Update Device Current Operation Details, etc... */
  set @xmlResult = convert(varchar(max), @vxmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'PutawayLPNs', @xmlResult, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPalletId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPalletId, @ActivityLogId = @vActivityLogId output;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_PutawayLPNsGetNextLPN */

Go
