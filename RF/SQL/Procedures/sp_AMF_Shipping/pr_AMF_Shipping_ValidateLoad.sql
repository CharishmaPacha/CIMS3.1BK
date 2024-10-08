/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Shipping_ValidateLoad') is not null
  drop Procedure pr_AMF_Shipping_ValidateLoad;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Shipping_ValidateLoad: Validates the scanned load and gives the
  response to show the information required

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Shipping_ValidateLoad
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
          @vOperation                TOperation;
          /* Functional variables */
  declare @vNumLPNs                  TCount,
          @vxmlLoadInfo              xml,
          @vLoadInfoXML              TXML;
begin /* pr_AMF_Shipping_ValidateLoad */

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
         @vLoadNumber   = Record.Col.value('(Data/LoadNumber)[1]',                 'TLoadNumber'  ),
         @vOperation    = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* call the V2 proc */
  exec pr_RFC_Shipping_ValidateLoad @vDeviceId, @vUserId, @vBusinessUnit,
                                    @vLoadNumber, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is an error, return */
  if (@vTransactionFailed > 0) return (@vTransactionFailed);

  /* If user is attempting to UnloadLPNs from the Load and there are none, return */
  if (@vOperation = 'UnloadLPNOrPallet')
    begin
      /* Get the LPNs count on the load */
      select @vNumLPNs = NumLPNs
      from Loads
      where (LoadNumber   = @vLoadNumber) and
            (BusinessUnit = @vBusinessUnit);

      /* If NumLPNs is 0 return */
      if (@vNumLPNs = 0)
        begin
          exec @vReturnCode = pr_Messages_ErrorHandler 'AMF_NoLPNsAssociatedWithLoad';
          select @DataXML = (select 0 LoadId
                             for Xml Raw(''), elements, Root('Data'));
          return;
        end
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

end /* pr_AMF_Shipping_ValidateLoad */

Go

