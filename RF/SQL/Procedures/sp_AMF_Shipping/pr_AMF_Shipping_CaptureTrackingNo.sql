/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/23  RIA     Added pr_AMF_Shipping_CaptureTrackingNo, pr_AMF_Shipping_ValidateLPN (CIMSV3-691)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Shipping_CaptureTrackingNo') is not null
  drop Procedure pr_AMF_Shipping_CaptureTrackingNo;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Shipping_CaptureTrackingNo: Calls the V2 proc which will do all the
  validations and updates the TrackingNo on LPN

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Shipping_CaptureTrackingNo
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
          @vLPN                      TLPN,
          @vTrackingNo               TTrackingNo,
          @vFreightCharge            TVarChar,
          @vUCCBarcode               TBarcode,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vDataXML                  TXML;
begin /* pr_AMF_Shipping_CaptureTrackingNo */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */-- This can be ignored
  select @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId        = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId      = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vLPN           = Record.Col.value('(Data/m_LPNInfo_LPN)[1]',              'TLPN'         ),
         @vTrackingNo    = Record.Col.value('(Data/TrackingNo)[1]',                 'TTrackingNo'  ),
         @vFreightCharge = Record.Col.value('(Data/FreightCharge)[1]',              'TVarChar'     ),
         @vUCCBarcode    = Record.Col.value('(Data/m_LPNInfo_UCCBarcode)[1]',       'TBarcode'     ),
         @vOperation     = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Build the input for V2 procedure */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(Data/m_LPNInfo_LPN)[1]',              'TLPN'         ) as LPN,
                                     Record.Col.value('(Data/TrackingNo)[1]',                 'TTrackingNo'  ) as TrackingNumber,
                                     Record.Col.value('(Data/FreightCharge)[1]',              'TVarChar'     ) as FreightCharge,
                                     Record.Col.value('(Data/m_LPNInfo_UCCBarcode)[1]',       'TBarcode'     ) as UCCBarcode,
                                     Record.Col.value('(Data/Operation)[1]',                  'TOperation'   ) as Operation
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('CAPTURETRACKINGNOINFO'), elements);

  /* Convert into varchar */
  select @vrfcProcInputxml = convert(varchar(max), @vxmlRFCProcInput);

  /* call the V2 proc */
  exec pr_RFC_Shipping_CaptureTrackingNoInfo @vrfcProcInputxml, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is an error, return */
  if (@vTransactionFailed > 0) return (@vTransactionFailed);

  select @vMessage = Record.Col.value('(ErrorMessage)[1]', 'TMessage')
  from @vxmlRFCProcOutput.nodes('/CAPTURETRACKINGNOINFO') as Record(Col);

  /* Build Success Message */
  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  select @vDataXML = '';
  with ResponseDetails as
  (
    select dbo.fn_XMLNode('CAPTUREINFORESPONSE_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
    from @vxmlRFCProcOutput.nodes('/CAPTURETRACKINGNOINFO/*') as t(c)
  )
  select @vDataXML = @vDataXML + ResponseDetail from ResponseDetails;

  /* Build the DataXML */
  select @DataXML = dbo.fn_XmlNode('Data', @vDataXML);

end /* pr_AMF_Shipping_CaptureTrackingNo */

Go

