/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/05/28  SV      pr_RFC_ConfirmLPNDisposition: Changes as per the changes in the signature of pr_LPNs_Void (HPI-1921)
  2018/01/10  SV      pr_RFC_ConfirmLPNDisposition: Signature correction for pr_RFC_ConfirmPutawayLPN (S2G-72)
  2015/09/28  DK      Added Procedure pr_RFC_ConfirmLPNDisposition(FB-389).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ConfirmLPNDisposition') is not null
  drop Procedure pr_RFC_ConfirmLPNDisposition;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ConfirmLPNDisposition:
  ConfirmLPNDisposition inputXML:
  <ReturnDisposition>
    <DeviceId>DeviceId1</DeviceId>
    <UserId>cimsadmin</UserId>
    <LPN>RO000001</LPN>
    <Operation>BackToInventory</Operation> -- Scrap
    <ReasonCode>101</ReasonCode>
    <Location>01-002-4-B1</Location>
    <BusinessUnit>FB</BusinessUnit>
  </ReturnDisposition>

  output XML:
  <RESULTDETAILS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <RESULTINFO>
      <ReturnCode>0</ReturnCode>
      <Message>LPN Putaway successfully</Message>
    </RESULTINFO>
  </RESULTDETAILS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ConfirmLPNDisposition
  (@XMLInput   xml,
   @XMLResult  xml output)
as
  declare @vReturnCode           TInteger,
          @MessageName           TMessageName,
          @vMessageDesc          TDescription,

          @vDeviceId             TDeviceId,
          @vUserId               TUserId,

          @vLPNId                TRecordId,
          @vLPN                  TLPN,
          @vSKUId                TRecordId,
          @vSKU                  TSKU,
          @vLPNQuantity          TQuantity,
          @vLPNInnerPacks        TQuantity,
          @vPAType               TTypeCode,

          @vLPNToVoid            TXML,
          @vXmlData              TXML,

          @vLocation             TLocation,
          @vLocPutawayZone       TLookUpCode,

          @vOperation            TOperation,
          @vReasonCode           TReasonCode,
          @vActivityLogId        TRecordId,
          @vBusinessUnit         TBusinessUnit;
begin
begin try
  SET NOCOUNT ON;

  /* Read values from input xml */
  select @vLPN              = Record.Col.value('LPN[1]',            'TLPN'),
         @vLocation         = Record.Col.value('Location[1]',       'TLocation'),
         @vOperation        = Record.Col.value('Operation[1]',      'TOperation'),
         @vReasonCode       = Record.Col.value('ReasonCode[1]',     'TReasonCode'),
         @vBusinessUnit     = Record.Col.value('BusinessUnit[1]',   'TBusinessUnit'),
         @vDeviceId         = Record.Col.value('DeviceId[1]',       'TDeviceId'),
         @vUserId           = Record.Col.value('UserId[1]',         'TUserId')
  from @xmlInput.nodes('ReturnDisposition') as Record(Col);

  /* Add to RF Log */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      @vLPNId, @vLPN, 'LPN', @vOperation, @Value1 = @vLocation,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get LPN Info */
  select @vLPN            = L.LPN,
         @vLPNId          = L.LPNId,
         @vSKUId          = L.SKUId,
         @vSKU            = S.SKU,
         @vLPNInnerPacks  = L.InnerPacks,
         @vLPNQuantity    = L.Quantity,
         @vPAType         = 'L'
  from LPNs L
    left outer join SKUs S on (L.SKUId = S.SKUId)
  where (L.LPN          = @vLPN) and
        (L.BusinessUnit = @vBusinessUnit);

  /* Get Location Info */
  select @vLocPutawayZone = PutawayZone
  from Locations
  where (Location = @vLocation);

  /* Update ReasonCode on LPN */
  update LPNs
  set Reasoncode = @vReasonCode
  where (LPN = @vLPN);

  if (@vOperation = 'BackToInventory')
    begin
      select @vXmlData = '<CONFIRMPUTAWAYLPN>' +
                            dbo.fn_XMLNode('LPN',             @vLPN) +
                            dbo.fn_XMLNode('SKU',             @vSKU) +
                            dbo.fn_XMLNode('DestZone',        @vLocPutawayZone) +
                            dbo.fn_XMLNode('DestLocation',    @vLocation) +
                            dbo.fn_XMLNode('ScannedLocation', @vLocation) +
                            dbo.fn_XMLNode('PAInnerPacks',    @vLPNInnerPacks) +
                            dbo.fn_XMLNode('PAQuantity',      @vLPNQuantity) +
                            dbo.fn_XMLNode('PAType',          @vPAType) +
                            dbo.fn_XMLNode('DeviceId',        @vDeviceId) +
                            dbo.fn_XMLNode('UserId',          @vUserId) +
                            dbo.fn_XMLNode('BusinessUnit',    @vBusinessUnit) +
                         '</CONFIRMPUTAWAYLPN>';

      /* if the operation is BackToInventory then we need to putaway the whole contents into picklane location and exports is generated once putaway is done*/
      exec @vReturnCode = pr_RFC_ConfirmPutawayLPN @vXmlData;

      if (@vReturnCode = 0)
        set @vMessageDesc = 'PutawaySuccessful';
    end
  else
  if (@vOperation = 'Scrap')
    begin
      /* Build xml here */
      select @vLPNToVoid = ('<ModifyLPNs>' +
                            (select @vLPNId as LPNId
                             for xml Path('LPNContent'), root('LPNs')) +
                             '</ModifyLPNs>')

      /* Call LPNs void procedure here and exports are generated once LPN is voided */
      exec @vReturnCode = pr_LPNs_Void @vLPNToVoid, @vBusinessUnit, @vUserId, @vReasonCode,
                                      default /* Reference */, default /* Operation */, @vMessageDesc output;
    end

  /* Build XmlMessage to RF */
  exec pr_BuildRFSuccessXML @vMessageDesc, @xmlResult output;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @MessageName, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;

end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @vMessageDesc, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;
end catch;
  return(coalesce(@vReturnCode, 0));
end  /* pr_RFC_ConfirmLPNDisposition */

Go
