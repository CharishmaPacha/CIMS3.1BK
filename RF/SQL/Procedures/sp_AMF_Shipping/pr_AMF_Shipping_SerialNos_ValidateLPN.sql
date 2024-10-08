/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/18  RIA     Added pr_AMF_Shipping_SerialNos_Capture, pr_AMF_Shipping_SerialNos_ValidateLPN (CIMSV3-1211)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Shipping_SerialNos_ValidateLPN') is not null
  drop Procedure pr_AMF_Shipping_SerialNos_ValidateLPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Shipping_SerialNos_ValidateLPN: Validates the scanned lpn and gives the
  response to show the information required

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Shipping_SerialNos_ValidateLPN
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
          @vScannedLPN               TLPN,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vStatus                   TStatus,
          @vStatusDesc               TDescription,
          @vMsgEntity                TDescription,
          @vOrderId                  TRecordId,

          @vLoggedInWarehouse        TWarehouse,
          @vLPNDestWarehouse         TWarehouse,

          @vxmlLPNInfo               xml,
          @vxmlLPNDetails            xml,
          @vxmlSerialNos             xml,
          @vSerialNosXML             TXML,
          @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML;

  declare @ttSerialNos               TEntityKeysTable;
begin /* pr_AMF_Shipping_SerialNos_ValidateLPN */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId       = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId     = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vScannedLPN   = Record.Col.value('(Data/ScannedLPN)[1]',                 'TLPN'         ),
         @vOperation    = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Build V2 Procedure input */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/DeviceId)[1]',                  'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',                  'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',              'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(Data/ScannedLPN)[1]',                       'TLPN'         ) as LPN,
                                     Record.Col.value('(Data/Operation)[1]',                        'TDescription' ) as Operation
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('ScannedLPNInfo'), elements);

  exec pr_RFC_SerialNos_ValidateScannedLPN @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is error raised simply return */
  if (@vTransactionFailed > 0) return;

  /* Fetch the LPNId */
  select @vLPNId   = Record.Col.value('(LPNInfo/LPNId)[1]',            'TRecordId')
  from @vxmlRFCProcOutput.nodes('/ScannedLPNResponse') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlRFCProcOutput = null));

  /* Create # table */
  select * into #SerialNo from @ttSerialNos;

  insert into #SerialNo(EntityKey)
    select Record.Col.value('(SerialNo)[1]',      'TSerialNo')
    from @vxmlRFCProcOutput.nodes('/ScannedLPNResponse/SerialNosInfo/SerialNos') as Record(Col);

  select @vSerialNosXML = (select EntityKey      as SerialNo
                           from #SerialNo
                           for xml path('SerialNo'), root('SerialNos'));

  /* As the validations are passed, call the LPNInfo proc to build needed info */
  exec pr_AMF_Info_GetLPNInfoXML @vLPNId, null /* LPNDetails */, @vOperation, @vLPNInfoXML output, @vLPNDetailsXML output;

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', @vLPNInfoXML + coalesce(@vSerialNosXML, ''));

end /* pr_AMF_Shipping_SerialNos_ValidateLPN */

Go

