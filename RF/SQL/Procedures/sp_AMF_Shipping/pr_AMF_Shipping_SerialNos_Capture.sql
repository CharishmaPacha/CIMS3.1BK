/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/18  RIA     Added pr_AMF_Shipping_SerialNos_Capture, pr_AMF_Shipping_SerialNos_ValidateLPN (CIMSV3-1211)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Shipping_SerialNos_Capture') is not null
  drop Procedure pr_AMF_Shipping_SerialNos_Capture;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Shipping_SerialNos_Capture:

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Shipping_SerialNos_Capture
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
          @vTempXML                  TXML,
          @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML;

  declare @ttSerialNos               TEntityKeysTable;
begin /* pr_AMF_Shipping_SerialNos_Capture */

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
                                     Record.Col.value('(Data/Option)[1]',                           'TFlags'       ) as UpdateOption,
                                     Record.Col.value('(Data/Operation)[1]',                        'TDescription' ) as Operation
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml path('LPNInfo'), root('ScannedLPNResponse'));

  select @vrfcProcInputxml = convert(varchar(max), @vxmlRFCProcInput);

  /* Create # table */
  select * into #SerialNo from @ttSerialNos;

  insert into #SerialNo(EntityKey)
    select Record.Col.value('(SerialNo)[1]',      'TSerialNo')
    from @vxmlInput.nodes('/Root/Data/SerialNos/SerialNo') as Record(Col);

  select @vTempXML = (select EntityKey      as SerialNo
                      from #SerialNo
                      for xml path(''), root('SerialNos'));

  select @vxmlRFCProcInput = convert(xml, dbo.fn_XMLAddNode(@vrfcProcInputxml, 'ScannedLPNResponse', @vTempXML));

  exec pr_RFC_SerialNos_Capture @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output, @InfoXML output;

  /* If there is error raised simply return */
  if (@vTransactionFailed > 0) return;

  /* Build the DataXML */
  select @DataXML = (select 'Done' as Resolution
                     for Xml Raw(''), elements, Root('Data'));

end /* pr_AMF_Shipping_SerialNos_Capture */

Go

