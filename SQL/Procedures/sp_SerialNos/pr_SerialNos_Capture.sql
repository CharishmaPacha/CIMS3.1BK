/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/18  RIA     pr_SerialNos_Capture, pr_SerialNos_ValidateScannedLPN, pr_SerialNos_Clear: Changes and corrections (CIMSV3-1211)
  2019/04/25  RV      pr_SerialNos_Capture: Made changes to return list of serial numbers for LPN (S2GCA-605)
              RV      pr_SerialNos_Capture: Do not required to send label format as provided options to select
  2019/04/02  RV      pr_SerialNos_Capture: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SerialNos_Capture') is not null
  drop Procedure pr_SerialNos_Capture;
Go
/*------------------------------------------------------------------------------
  Proc pr_SerialNos_Capture: This procedure Add or Replaces Serial Nos for scanned LPN.

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
Create Procedure pr_SerialNos_Capture
  (@xmlInput      xml,
   @xmlOutput     xml      output,
   @Message       TMessage output)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TMessage,

          @LPN                      TLPN,
          @Operation                TOperation,
          @UpdateOption             TFlags,
          @PrintRequired            TFlags,
          @DeviceId                 TDeviceId,
          @UserId                   TUserId,
          @BusinessUnit             TBusinessUnit,

          @vLPNId                   TRecordId,
          @vLPN                     TLPN,
          @vLPNStatus               TStatus,
          @vLPNQuantity             TQuantity,
          @vValidLPNStatuses        TControlValue,
          @vLPNOrderId              TRecordId,

          @vScannedSerialNoCount    TCount,
          @vShippedSerialNoCount    TCount,
          @vNextPrintSerialNosBatch TBatch,
          @vShippedSerialNo         TSerialNo,
          @vAuditActivity           TActivityType,
          @vNote1                   TDescription,
          @vActivityLogId           TRecordId;

  declare @xmlRulesData             TXML,
          @vSerialNosXml            TXML,
          @vPrintSerialNosXML       TXML;

  declare @ttSerialNos              TEntityKeysTable;
begin /* pr_SerialNos_Capture */
begin try
  SET NOCOUNT ON;

  select @vNextPrintSerialNosBatch = 0;

  /* Get the XML User inputs in to the local variables */
  select @LPN           = Record.Col.value('LPN[1]'           , 'TLPN'),
         @Operation     = Record.Col.value('Operation[1]'     , 'TOperation'),
         @UpdateOption  = Record.Col.value('UpdateOption[1]'  , 'TFlags'),
         @PrintRequired = Record.Col.value('PrintRequired[1]' , 'TFlags'),
         @BusinessUnit  = Record.Col.value('BusinessUnit[1]'  , 'TBusinessUnit'),
         @UserId        = Record.Col.value('UserId[1]'        , 'TUserId'),
         @DeviceId      = Record.Col.value('DeviceId[1]'      , 'TDeviceId')
  from @xmlInput.nodes('ScannedLPNResponse/LPNInfo') as Record(Col);

  begin transaction;

  /* Create # table */
  select * into #SerialNos from @ttSerialNos;

  /* Extract serial nos from xml */
  insert into #SerialNos(EntityKey)
    select Record.Col.value('.',  'TSerialNo')
    from @xmlInput.nodes('ScannedLPNResponse/SerialNos/SerialNo') as Record(Col);

  set @vScannedSerialNoCount = @@rowcount;

  /* get LPN info */
  select @vLPNId       = LPNId,
         @vLPN         = LPN,
         @vLPNStatus   = Status,
         @vLPNQuantity = Quantity,
         @vLPNOrderId  = OrderId
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@LPN, @BusinessUnit, 'LTU'));

  /* Check if there are invalid serial nos */
  select @vShippedSerialNocount = count(*),
         @vShippedSerialNo      = Min(SN.SerialNo)
  from SerialNos SN join #SerialNos ttSN on SN.SerialNo = ttSN.EntityKey and SN.SerialNoStatus = 'S';

  /* get Controls */
  select @vValidLPNStatuses = dbo.fn_Controls_GetAsString('SerialNos', 'ValidLPNStatuses', 'RPAKDEL', @BusinessUnit, @UserId),
         @vAuditActivity    = 'SerialNo_' + @UpdateOption;

 /* Build the data for evaluation of rules */
 select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                          dbo.fn_XMLNode('LPNId',      @vLPNId) +
                          dbo.fn_XMLNode('LPNStatus',  @vLPNStatus) +
                          dbo.fn_XMLNode('OrderId',    @vLPNOrderId));

  /* Validations */
  if (@vLPNId is null)
    select @vMessageName = 'SerialNos_InvalidScannedLPN';
  else
  if (dbo.fn_IsInList(@vLPNStatus, @vValidLPNStatuses) = 0)
    select @vMessageName = 'SerialNos_InvalidLPNStatus';
  else
  if (@vScannedSerialNoCount = 0)
    select @vMessageName = 'SerialNos_NoSerialNosToAssign';
  else
  if (@vLPNQuantity < @vScannedSerialNoCount)
    select @vMessageName = 'SerialNos_ScannedSerialNosAreMoreThanUnits';
  else
  if (@vShippedSerialNocount > 0)
    select @vMessageName = 'SerialNos_SomeAlreadyUsed',
           @vNote1       = @vShippedSerialNo;
  else
    exec pr_RuleSets_Evaluate 'SerialNos_Validations', @xmlRulesData, @vMessageName output;

  if (@vMessageName is not null)
    goto ErrorHandler;

  if (@Operation = 'UI_CaptureSerialNos')
    /* Get the Print serial numbers batch */
    exec pr_Controls_GetNextSeqNo 'PrintSerialNosBatch', 1, @UserId, @BusinessUnit,
                                   @vNextPrintSerialNosBatch output;

  /* if we are replacing serial numbers for the current LPN, then unassign the previously assinged ones */
  if (@UpdateOption = 'R'/* Replace */)
    begin
      /* unassign current serial nos for scanned LPN and then assign new ones */
      update SerialNos
      set SerialNoStatus  = 'R'/* Ready To Use */,
          LPNId           = 0,
          PrintBatch      = 0,
          ModifiedDate    = current_timestamp
      where (LPNId = @vLPNId);
    end

  /* Insert any new serial Nos that don't exist */
  insert into SerialNos(SerialNo, SerialNoStatus, BusinessUnit, CreatedBy)
    select EntityKey, 'R', @BusinessUnit, @UserId
    from #SerialNos ttSN left outer join SerialNos SN on ttSN.EntityKey = SN.SerialNo
    where SN.SerialNo is null

  /* Assign all the scanned serial numbers to the scanned LPN */
  update SN
  set LPNId           = @vLPNId,
      SerialNoStatus  = 'A' /* Assigned */,
      PrintBatch      = @vNextPrintSerialNosBatch,
      Modifieddate    = current_timestamp,
      ModifiedBy      = @UserId
  from #SerialNos ttSN join SerialNos SN on (ttSN.EntityKey = SN.SerialNo)

  /* Log AT for the LPN */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @LPNId = @vLPNId, @Note1 = @vScannedSerialNoCount;

  select @Message = dbo.fn_Messages_GetDescription('SerialNos_AddedOrReplacedSuccessfully');

  /* Build Serial Nos xml */
  set @vSerialNosXml = dbo.fn_XMLNode('SerialNosInfo',
                                        (select SerialNo
                                         from SerialNos
                                         where (LPNId = @vLPNId)
                                         for XML raw('SerialNos'), elements));

  /* Build print serial number if printing required */
  if (@PrintRequired = 'Y' /* Yes */)
    select @vPrintSerialNosXML = dbo.fn_XMLNode('PrintSerialNosInfo',
                                   dbo.fn_XMLNode('LPN',                 @vLPN) +
                                   dbo.fn_XMLNode('PrintSerialNosBatch', @vNextPrintSerialNosBatch));

  /* Build output xml with SerialNos and print batch details */
  select @xmlOutput = dbo.fn_XMLNode('ResultXML',
                        coalesce(@vSerialNosXml,      '') +
                        coalesce(@vPrintSerialNosXML, ''));

/* On Error, return Error Code/Error Message */
ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vNote1;

  commit;
end try
begin catch
  if (@@trancount > 0) rollback;

  exec @vReturnCode = pr_ReRaiseError;
end catch;
end /* pr_SerialNos_Capture */

Go
