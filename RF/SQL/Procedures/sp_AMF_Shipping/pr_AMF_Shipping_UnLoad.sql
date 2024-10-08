/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_AMF_Shipping_RemoveFromLoad to pr_AMF_Shipping_UnLoad (CIMSV3-689)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Shipping_UnLoad') is not null
  drop Procedure pr_AMF_Shipping_UnLoad;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Shipping_UnLoad: Calls the V2 proc which will do all the
  validations and removes LPN/Pallet from the Load

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Shipping_UnLoad
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
  declare @vNumLPNs                  TCount,
          @vxmlLoadInfo              xml,
          @vLoadInfoXML              TXML;
begin /* pr_AMF_Shipping_UnLoad */

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
                                     Record.Col.value('(Data/LPNOrPallet)[1]',                'TLPN'         ) as ScanLPNOrPallet
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('ConfirmLoad'), elements);

  /* call the V2 proc */
  exec pr_RFC_Shipping_UnLoad @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is an error, return */
  if (@vTransactionFailed > 0) return (@vTransactionFailed);

  /* Build Success Message */
  select @vMessage = dbo.fn_Messages_Build('AMF_LPNOrPalletRemovedFromLoad', @vLPNOrPallet, @vLoadNumber, null, null, null);
  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  /* Get the LPNs count on the load */
  select @vNumLPNs = NumLPNs
  from Loads
  where (LoadNumber   = @vLoadNumber) and
        (BusinessUnit = @vBusinessUnit);

  /* If there are no more LPNs on the Load, then exit the screen, so do not return LoadId */
  if (@vNumLPNs = 0)
    begin
      select @DataXML = (select 0 LoadId
                         for Xml Raw(''), elements, Root('Data'));
      return;
    end

  select @vLoadInfoXML = '';
  with FlatXML as
  (
    select dbo.fn_XMLNode('LoadInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlRFCProcOutput.nodes('/LoadInfo/*') as t(c)
  )
  select @vLoadInfoXML = @vLoadInfoXML + DetailNode from FlatXML;

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', @vLoadInfoXML);

end /* pr_AMF_Shipping_UnLoad */

Go

