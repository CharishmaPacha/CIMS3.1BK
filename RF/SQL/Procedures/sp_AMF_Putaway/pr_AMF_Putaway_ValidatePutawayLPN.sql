/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/24  RIA     pr_AMF_Putaway_ConfirmPutawayLPN, pr_AMF_Putaway_ValidatePutawayLPN: Variable declarations (CIMSV3-631)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Putaway_ValidatePutawayLPN') is not null
  drop Procedure pr_AMF_Putaway_ValidatePutawayLPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Putaway_ValidatePutawayLPN

  Processes the requests for putaway LPN work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Putaway_ValidatePutawayLPN
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vxmlInput                 xml,
          @vxmlOutput                xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vLPN                      TLPN,
          @vPAType                   TTypeCode,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLPNInfoXML               TXML,
          @vLPNId                    TRecordId,
          @vQuantity                 TQuantity,
          @vLPNOrderId               TRecordId,
          @vTaskId                   TRecordId,
          @vTrackingNo               TTrackingNo,
          @vUCCBarcode               TBarcode,
          @vLPNStatusDesc            TDescription,
          @vPickTicket               TPickTicket,
          @vWaveNo                   TPickBatchNo,
          @vConfirmQty               TFlag,
          @vPutawayMode              TFlag;
begin /* pr_AMF_ValidatePutawayLPN */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @InfoXML   = null,
         @ErrorXML  = null

  /* Read inputs from InputXML */
  select @vDeviceId      = Record.Col.value('(SessionInfo/DeviceId)[1]',     'TDeviceId'    ),
         @vUserId        = Record.Col.value('(SessionInfo/UserName)[1]',     'TUserId'      ),
         @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @vLPN           = Record.Col.value('(Data/LPN)[1]',                 'TLPN'         ),
         @vPAType        = Record.Col.value('(Data/PAType)[1]',              'TTypeCode'    )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Insert exec fails when the lpn is invalid for vas Inquiry
     This is because of the rollback statement which gets executed for invalid lpns
     Therefore, validations for lpn from lpn inquiry procedure are performed here, to avoid db error and show proper error */
  select @vLPNId         = LPNId,
         @vLPN           = LPN,
         @vLPNStatusDesc = StatusDescription,
         @vTaskId        = TaskId,
         @vWaveNo        = PickBatchNo,
         @vPickTicket    = PickTicket,
         @vQuantity      = Quantity,
         @vLPNOrderId    = OrderId,
         @vTrackingNo    = TrackingNo,
         @vUCCBarcode    = UCCBarcode
  from  vwLPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@vLPN, @vBusinessUnit, 'LTU'));

  /* Build the input for V2 procedure */
  select @vxmlRFCProcInput = (select @vDeviceId     as DeviceId,
                                     @vUserId       as UserId,
                                     @vBusinessUnit as BusinessUnit,
                                     @vLPN          as LPN,
                                     @vPAType       as PAType
                              for xml raw('VALIDATEPUTAWAYLPN'), elements);

  select @vRFCProcInputxml = coalesce(convert(varchar(max), @vxmlRFCProcInput), '');

  /* Call the V2 proc and get the info */
  exec pr_RFC_ValidatePutawayLPN @vRFCProcInputxml, @vRFCProcOutputxml output;

  select @vxmlRFCProcOutput = convert(xml, @vRFCProcOutputxml);

  /* Read the output from V2 procedure */
  select @vConfirmQty  = Record.Col.value('(OPTIONS/ConfirmQtyRequired)[1]',     'TFlag'),
         @vPutawayMode = Record.Col.value('(LPNINFO/PutawayMode)[1]',            'TFlag')
  from @vxmlRFCProcOutput.nodes('/PUTAWAYLPNDETAILS')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlRFCProcOutput = null));

  /* If putting away Units, then ConfirmQty is not required. V2 is sending it as Y, so turn it off */
  if ((@vPutawayMode in ('U')) and @vConfirmQty = 'Y')
    select @vRFCProcOutputxml = dbo.fn_XMLStuffValue(@vRFCProcOutputxml, 'ConfirmQtyRequired', 'N');

  select @vxmlRFCProcOutput = convert(xml, @vRFCProcOutputxml);

  /* Build required info which is not returned from V2 */
  select @vLPNInfoXML = dbo.fn_XMLNode('TaskId', @vTaskId) + dbo.fn_XMLNode('Status', @vLPNStatusDesc) +
                        dbo.fn_XMLNode('WaveNo', @vWaveNo) + dbo.fn_XMLNode('PickTicket', @vPickTicket) +
                        dbo.fn_XMLNode('LPNId', @vLPNId)   + dbo.fn_XMLNode('Quantity', @vQuantity);

  exec pr_AMF_Info_GetLPNInfoXML @vLPNId, @LPNInfoXML = @vLPNInfoXML output;

  /* Read the values from V2 to show */
  select @DataXML = '';
  with ResponseDetails as
  (
    select dbo.fn_XMLNode('' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
    from @vxmlRFCProcOutput.nodes('/PUTAWAYLPNDETAILS/LPNINFO/*') as t(c)
    union
    select dbo.fn_XMLNode('' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
    from @vxmlRFCProcOutput.nodes('/PUTAWAYLPNDETAILS/OPTIONS/*') as t(c)
    union
    select dbo.fn_XMLNode('' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
    from @vxmlRFCProcOutput.nodes('/PUTAWAYLPNDETAILS/MESSAGE/*') as t(c)
  )
  select @DataXML = @DataXML + ResponseDetail from ResponseDetails;

  /* Add the additional LPN Info */
  select @DataXml = dbo.fn_XmlNode('Data', @DataXML + coalesce(@vLPNInfoXML, ''));

end /* pr_AMF_Putaway_ValidatePutawayLPN */

Go

