/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/21  RKC     pr_AMF_Shipping_Load:Changes to get Dock Location (HA-1073)
  2020/01/25  RIA     Renamed pr_AMF_Shipping_AddToLoad to pr_AMF_Shipping_Load,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Shipping_Load') is not null
  drop Procedure pr_AMF_Shipping_Load;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Shipping_Load: Calls the V2 proc which will do all the
  validations and adds LPN/Pallet to Load

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Shipping_Load
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
          @vLoadNumber               TLoadNumber,
          @vShipTo                   TName,
          @vLPNOrPallet              TLPN,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vxmlLoadInfo              xml,
          @vLoadInfoXML              TXML;
begin /* pr_AMF_Shipping_Load */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */-- This can be ignored
  select @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId       = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId     = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vLoadNumber   = Record.Col.value('(Data/m_LoadInfo_LoadNumber)[1]',      'TLoadNumber'  ),
         @vShipTo       = Record.Col.value('(Data/m_LoadInfo_ShipTo)[1]',          'TName'        ),
         @vLPNOrPallet  = Record.Col.value('(Data/LPNOrPallet)[1]',                'TLPN'         ),
         @vOperation    = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Build the input for V2 procedure */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(Data/m_LoadInfo_LoadNumber)[1]',      'TLoadNumber'  ) as Load,
                                     Record.Col.value('(Data/m_LoadInfo_ShipTo)[1]',          'TName'        ) as ShipTo,
                                     Record.Col.value('(Data/LPNOrPallet)[1]',                'TLPN'         ) as ScanLPNOrPallet,
                                     Record.Col.value('(Data/Dock)[1]',                       'TLocation'    ) as Dock,
                                     Record.Col.value('(Data/Operation)[1]',                  'TOperation'   ) as Operation
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('ConfirmLoad'), elements);

  /* call the V2 proc */
  exec pr_RFC_Shipping_Load @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is an error, return */
  if (@vTransactionFailed > 0) return (@vTransactionFailed);

  select @vLoadInfoXML = '';
  with FlatXML as
  (
    select dbo.fn_XMLNode('LoadInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlRFCProcOutput.nodes('/LoadInfo/*') as t(c)
  )
  select @vLoadInfoXML = @vLoadInfoXML + DetailNode from FlatXML;

  /* Build Success Message */
  select @vMessage = dbo.fn_Messages_Build('AMF_LPNOrPalletAddedToLoad', @vLPNOrPallet, @vLoadNumber, null, null, null);
  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', @vLoadInfoXML);

end /* pr_AMF_Shipping_Load */

Go

