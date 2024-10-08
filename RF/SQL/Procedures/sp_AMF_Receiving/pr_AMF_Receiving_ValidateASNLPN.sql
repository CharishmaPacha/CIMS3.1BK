/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/02  MS      pr_AMF_Receiving_ReceiveASNLPN, pr_AMF_Receiving_ValidateASNLPN: Made changes to show ReceiverNumber (JL-291)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Receiving_ValidateASNLPN') is not null
  drop Procedure pr_AMF_Receiving_ValidateASNLPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Receiving_ValidateASNLPN: In the ASN Receiving process, user
    scans the inbound ASN and we need to validate it and also suggest how to palletize
    or locate the scanned LPN. This proc accomplishes these steps.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Receiving_ValidateASNLPN
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
          @vLPN                      TLPN,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vDataXML                  TXML,
          @vPrevDataXML              TXML,
          @vReceiptInfoXML           TXML,
          @vReceiptDetailsXML        TXML,
          @vROInfoXML                TXML,
          @vReceiptPrevInfoXML       TXML,
          @vSKU                      TSKU,
          @vQuantity                 TQuantity,
          @vSuggestedPallet          TPallet,
          @vPalletRight              TPallet,
          @vIsPalletizationRequired  TControlValue,
          @vLPNsInTransit            TCount,
          @vDeviceName               TName;
begin /* pr_AMF_Receiving_ValidateASNLPN */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML    = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML  = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML   = null,
         @InfoXML    = null,
         @vROInfoXML = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]',           'TBusinessUnit'),
         @vUserId        = Record.Col.value('(SessionInfo/UserName)[1]',               'TUserId'      ),
         @vDeviceId      = Record.Col.value('(SessionInfo/DeviceId)[1]',               'TDeviceId'    ),
         @vReceiptId     = Record.Col.value('(Data/m_ReceiptInfo_ReceiptId)[1]',       'TRecordId'     ),
         @vReceiptNumber = Record.Col.value('(Data/m_ReceiptInfo_ReceiptNumber)[1]',   'TReceiptNumber'),
         @vLPN           = Record.Col.value('(Data/LPN)[1]',                           'TLPN'          ),
         @vOperation     = Record.Col.value('(Data/Operation)[1]',                     'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Build the input for V2 procedure */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/DeviceId)[1]',               'TDeviceId'      ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',               'TUserId'        ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',           'TBusinessUnit'  ) as BusinessUnit,
                                     Record.Col.value('(Data/m_ReceiverNumber)[1]',              'TReceiverNumber') as ReceiverNumber,
                                     Record.Col.value('(Data/m_ReceiptInfo_ReceiptNumber)[1]',   'TReceiptNumber' ) as ReceiptNumber,
                                     Record.Col.value('(Data/LPN)[1]',                           'TLPN'           ) as LPN,
                                     Record.Col.value('(Data/Operation)[1]',                     'TOperation'     ) as Operation
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('ValidateASNLPNInput'), elements);

  /* call the V2 proc */
  exec pr_RFC_ValidateASNLPN @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is an error, return */
  if (@vTransactionFailed > 0) return (@vTransactionFailed);

  select @vrfcProcOutputxml = convert(varchar(max), @vxmlRFCProcOutput)

  /* In V3, we would like to show the last 4 digits of the suggested pallet in highlighted font
     so that the user can easily identify the pallet */
  select @vSuggestedPallet          = Record.Col.value('(Header/SuggestedPallet)[1]',          'TPallet'      ),
         @vIsPalletizationRequired  = Record.Col.value('(Header/IsPalletizationRequired)[1]',  'TControlValue'),
         @vSKU                      = Record.Col.value('(Details/Detail/SKU)[1]',              'TSKU'         ),
         @vQuantity                 = Record.Col.value('(Details/Detail/Quantity)[1]',         'TQuantity'    )
  from @vxmlRFCProcOutput.nodes('/ValidateASNLPNResult') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlRFCProcOutput = null));

  select @vPalletRight = right(@vSuggestedPallet, 4);
  if (IsNumeric(@vPalletRight) = 0) select @vPalletRight = ''; -- if not numeric, then clear it

  select @vDataXML = '';
  with ResponseDetails as
  (
    select dbo.fn_XMLNode('LPNInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
    from @vxmlRFCProcOutput.nodes('/ValidateASNLPNResult/Header/*') as t(c)
    union
    select dbo.fn_XMLNode('SKUInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
    from @vxmlRFCProcOutput.nodes('/ValidateASNLPNResult/Details/Detail/*') as t(c)
  )
  select @vDataXML = @vDataXML + ResponseDetail from ResponseDetails;

  /* set value for DeviceName to get value from Devices table */
  select @vDeviceName = @vDeviceId + '@' + @vUserId;

  /* Get the prev dataxml */
  select @vPrevDataXML = DataXML
  from Devices
  where (DeviceId = @vDeviceName);

  /* Get the req info */
  select @vReceiptPrevInfoXML = dbo.fn_XMLGetValue(@vPrevDataXML, 'Data');

  /* Build the DataXML */
  select @DataXML = dbo.fn_XmlNode('Data', coalesce(@vDataXML, '') +
                                           dbo.fn_XMLNode('PalletRight', @vPalletRight) +
                                           coalesce(@vReceiptPrevInfoXML,''));

end /* pr_AMF_Receiving_ValidateASNLPN */

Go

