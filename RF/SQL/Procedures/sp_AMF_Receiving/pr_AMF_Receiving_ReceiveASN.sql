/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/24  MS      pr_AMF_Receiving_ReceiveASN, pr_AMF_Receiving_ReceiveASNLPN: Changes to display Pallet in successmsg (JL-306)
  2020/11/05  RIA     Added pr_AMF_Receiving_ReceiveASNLPN (JL-283)
  2020/11/05  RIA     Renamed pr_AMF_Receiving_ReceiveASNLPN to pr_AMF_Receiving_ReceiveASN (JL-296)
  2020/11/02  MS      pr_AMF_Receiving_ReceiveASNLPN, pr_AMF_Receiving_ValidateASNLPN: Made changes to show ReceiverNumber (JL-291)
  2020/10/27  RIA     pr_AMF_Receiving_ReceiveASNLPN: Changes to send the Location scanned (JL-211)
  2020/10/24  MS      pr_AMF_Receiving_ReceiveASNLPN: Made changes to pass Location info (JL-210)
  2020/10/22  AJM     pr_AMF_Receiving_ReceiveASNLPN: Correction to messagename to display proper description (JL-208)
  2020/03/17  RIA     pr_AMF_Receiving_ReceiveASNLPN, pr_AMF_Receiving_ValidateEntity: Changes
  2020/03/05  RIA     pr_AMF_Receiving_ReceiveASNLPN, pr_AMF_Receiving_ValidateEntity: Changes
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Receiving_ReceiveASN') is not null
  drop Procedure pr_AMF_Receiving_ReceiveASN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Receiving_ReceiveASN: Confirms the receipt of the ASN LPN
    by palletizing it or locating it.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Receiving_ReceiveASN
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vMessage                  TMessage,
          @vxmlInput                 xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vReceiptId                TRecordId,
          @vReceiptNumber            TReceiptNumber,
          @vReceiverNumber           TReceiverNumber,
          @vNewReceiverNumber        TReceiverNumber,
          @vLPN                      TLPN,
          @vPallet                   TPallet,
          @vReceivingLocation        TLocation,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vDataXML                  TXML,
          @vReceiptInfoXML           TXML,
          @vReceiptDetailsXML        TXML,
          @vSKU                      TSKU,
          @vQuantity                 TQuantity,
          @vQtyToReceive             TQuantity,
          @vTotalLPNs                TCount,
          @vTotalUnits               TCount,
          @vLPNsReceived             TCount,
          @vQtyReceived              TCount,
          @vLPNsInTransit            TCount,
          @vScannedLocation          TLocation;
begin /* pr_AMF_Receiving_ReceiveASN */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit      = Record.Col.value('(SessionInfo/BusinessUnit)[1]',           'TBusinessUnit' ),
         @vUserId            = Record.Col.value('(SessionInfo/UserName)[1]',               'TUserId'       ),
         @vDeviceId          = Record.Col.value('(SessionInfo/DeviceId)[1]',               'TDeviceId'     ),
         @vReceiptId         = Record.Col.value('(Data/m_ReceiptInfo_ReceiptId)[1]',       'TRecordId'     ),
         @vReceiptNumber     = Record.Col.value('(Data/m_ReceiptInfo_ReceiptNumber)[1]',   'TReceiptNumber'),
         @vReceiverNumber    = Record.Col.value('(Data/m_ReceiverNumber)[1]',              'TReceiverNumber'),
         @vReceivingLocation = Record.Col.value('(Data/m_ReceivingLocation)[1]',           'TLocation'     ),
         @vScannedLocation   = nullif(Record.Col.value('(Data/ConfirmedLocation)[1]',      'TLocation'), ''),
         @vLPN               = Record.Col.value('(Data/LPN)[1]',                           'TLPN'          ),
         @vSKU               = Record.Col.value('(Data/m_SKUInfo_SKU)[1]',                 'TSKU'          ),
         @vQuantity          = Record.Col.value('(Data/m_SKUInfo_Quantity)[1]',            'TQuantity'     ),
         @vOperation         = Record.Col.value('(Data/Operation)[1]',                     'TOperation'    )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Build the input for V2 procedure */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/DeviceId)[1]',               'TDeviceId'      ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',               'TUserId'        ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',           'TBusinessUnit'  ) as BusinessUnit,
                                     Record.Col.value('(Data/m_ReceiverNumber)[1]',              'TReceiverNumber') as ReceiverNumber,
                                     Record.Col.value('(Data/m_ReceiptInfo_ReceiptNumber)[1]',   'TReceiptNumber' ) as ReceiptNumber,
                                     coalesce(@vScannedLocation, @vReceivingLocation)                               as Location,
                                     Record.Col.value('(Data/LPN)[1]',                           'TLPN'           ) as LPN,
                                     Record.Col.value('(Data/m_SKUInfo_SKU)[1]',                 'TSKU'           ) as SKU,
                                     Record.Col.value('(Data/Pallet)[1]',                        'TPallet'        ) as Pallet,
                                     Record.Col.value('(Data/m_SKUInfo_Quantity)[1]',            'TQuantity'      ) as ConfirmQuantity,
                                     Record.Col.value('(Data/Operation)[1]',                     'TOperation'     ) as Operation,
                                     'Y' as QtyConfirmed
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('ReceiveASNLPNInput'), elements);

  /* call the V2 proc */
  exec pr_RFC_ReceiveASNLPN @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is an error, return */
  if (@vTransactionFailed > 0) return (@vTransactionFailed);

  /* Get the LPNs in transit value and others needed */
  select @vLPNsInTransit     = Record.Col.value('(LPNsInTransit)[1]',   'TCount'),
         @vNewReceiverNumber = Record.Col.value('(ReceiverNumber)[1]',  'TReceiverNumber'),
         @vPallet            = Record.Col.value('(Pallet)[1]',          'TPallet'),
         @vMessage           = Record.Col.value('(Message)[1]',         'TMessage')
  from @vxmlRFCProcOutput.nodes('/ReceiveASNLPNResult') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlRFCProcOutput = null));

  /* Build Success Message */
  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  /* If there are no LPNs left to be received then return */
  if (@vLPNsInTransit = 0)
    begin
      select @vMessage = dbo.fn_Messages_Build('AMF_AllLPNsReceivedAgainstTheReceipt', @vReceiptNumber, null, null, null, null);
      select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);
      select @DataXML = dbo.fn_XmlNode('Data', dbo.fn_XmlNode('LPNsInTransit', @vLPNsInTransit));
      return;
    end

  /* get the Receipt Info */
  exec pr_AMF_Info_GetROInfoXML @vReceiptId, 'Y' /* Receipt Details */, @vOperation,
                                @vReceiptInfoXML output, @vReceiptDetailsXML output;

  /* Build the DataXML */
  select @DataXML = dbo.fn_XmlNode('Data', @vReceiptInfoXML + @vReceiptDetailsXML +
                                           dbo.fn_XmlNode('ReceiverNumber',    coalesce(nullif(@vReceiverNumber, ''), @vNewReceiverNumber)) +
                                           dbo.fn_XmlNode('ReceivingLocation', @vReceivingLocation));

end /* pr_AMF_Receiving_ReceiveASN */

Go

