/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/10/28  VS      pr_RFC_ValidatePutawayLPNs, pr_RFC_CancelPutawayLPNs: Added Logging
                      pr_RFC_CancelPutawayLPNs: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_CancelPutawayLPNs') is not null
  drop Procedure pr_RFC_CancelPutawayLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_CancelPutawayLPNs: This procedure will clear Pallet information &
                                   Package sequnce number on the Scanned LPNs

  @xmlInput Structure:
  <CANCELPALPNS>
    <Pallet></Pallet>
    <DeviceId></DeviceId>
    <BusinessUnit></BusinessUnit>
    <UserId></UserId>
  </CANCELPALPNS>

  @xmlResult Structure:
  <SUCCESSDETAILS>
    <SUCCESSINFO>
       <ReturnCode></ReturnCode>
       <Message>/<Message>
    </SUCCESSINFO>
  </SUCCESSDETAILS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_CancelPutawayLPNs
  (@xmlInput   TXML,
   @xmlResult  TXML output)
as
  declare @vRecordId      TRecordId,
          @vLPNId         TRecordId,

          @Pallet         TPallet,
          @vPalletId      TRecordId,
          @BusinessUnit   TBusinessUnit,
          @DeviceId       TDeviceId,
          @UserId         TUserId,

          @xmlInputInfo   xml,
          @vActivityLogId TRecordId;

  declare @ttLPNsToCancel TEntityKeysTable;

begin
begin try
  SET NOCOUNT ON;

  select @vRecordId    = 0,
         @xmlInputInfo =  convert(xml, @xmlInput);

  /* Get the Input params */
  select @Pallet         = Record.Col.value('Pallet[1]', 'TPallet'),
         @BusinessUnit   = Record.Col.value('BusinessUnit[1]', 'TLPN'),
         @DeviceId       = Record.Col.value('DeviceId[1]', 'TDeviceId'),
         @UserId         = Record.Col.value('UserId[1]', 'TUserId')
  from @xmlInputInfo.nodes('/CANCELPALPNS') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInputInfo, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      null, @Pallet, 'Pallet',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get PalletId */
  select @vPalletId = PalletId
  from Pallets
  where (Pallet       = @Pallet      ) and
        (BusinessUnit = @BusinessUnit);

  /* Get all the LPNs needs to be cancelled */
  insert into @ttLPNsToCancel
    select LPNId, LPN
    from LPNs
    where (PalletId = @vPalletId);

  /* Loop thru the LPNs and clear pallet information */
  while exists(select * from @ttLPNsToCancel where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId = RecordId,
                   @vLPNId    = EntityId
      from @ttLPNsToCancel
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Call set pallet to clear pallet information on LPNs */
      exec pr_LPNs_SetPallet @vLPNId, null /* PalletId */, @UserId;

      /* Call pr_LPNs_SetLocation to clear the DestLocation,
         DestZone and the suggested Location status updated during putaway suggestion */
      exec pr_LPNs_SetDestination @vLPNId, 'ClearDestination';

      /* clear Package Seq No */
      update LPNs
      set PackageSeqNo = null
      where (LPNId = @vLPNId);
    end

  /* Update device and build result xml */
  exec pr_BuildRFSuccessXML 'CancelPutawayLPNsSuccessful', @Result = @xmlResult output;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPalletId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;
  exec pr_BuildRFErrorXML @Result = @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPalletId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_CancelPutawayLPNs */

Go
