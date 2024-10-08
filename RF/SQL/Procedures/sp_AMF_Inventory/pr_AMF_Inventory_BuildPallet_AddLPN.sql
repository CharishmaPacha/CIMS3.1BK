/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/22  RIA     pr_AMF_Inventory_BuildPallet_AddLPN, pr_AMF_Inventory_ValidatePallet: Made changes (CID-947)
  2019/10/20  RIA     pr_AMF_Inventory_BuildPallet_AddLPN, pr_AMF_Inventory_ValidatePallet,
  2019/10/11  RIA     pr_AMF_Inventory_BuildPallet_AddLPN, pr_AMF_Inventory_ValidatePallet (CID-911)
  2019/08/20  RIA     pr_AMF_Inventory_BuildPallet_AddLPN, pr_AMF_Inventory_AddSKUToLPN: Changes for evaluating the if statements (CID-948)
  2019/08/19  RIA     pr_AMF_Inventory_BuildPallet_AddLPN: Changes to pause build (CID-967)
  2019/08/16  RIA     Added pr_AMF_Inventory_BuildPallet_AddLPN (CID-947)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_BuildPallet_AddLPN') is not null
  drop Procedure pr_AMF_Inventory_BuildPallet_AddLPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_BuildPallet_AddLPN:

  Processes the requests for Build Pallet work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_BuildPallet_AddLPN
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
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vPallet                   TPallet,
          @vLPN                      TLPN,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vPalletId                 TRecordId,
          @vPalletInfoXML            TXML,
          @vPalletDetailsXML         TXML,
          @vMessage                  TMessage;
begin /* pr_AMF_Inventory_BuildPallet_AddLPN */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit   = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId         = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId       = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vPalletId       = Record.Col.value('(Data/m_PalletInfo_PalletId)[1]',      'TRecordId'    ),
         @vPallet         = Record.Col.value('(Data/m_PalletInfo_Pallet)[1]',        'TPallet'      ),
         @vLPN            = Record.Col.value('(Data/LPN)[1]',                        'TLPN'         ),
         @vOperation      = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Call the V2 proc to associate LPN to Pallet */
  exec pr_RFC_Inv_AddLPNToPallet @vPallet, @vLPN, @vBusinessUnit, @vUserId, @vDeviceId, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* if transactions is successful, return Pallet info with List of LPNs on Pallet */
  if (@vTransactionFailed <= 0)
    begin
      /*  Read results from result XML */
      select @vReturnCode = Record.Col.value('(PALLETINFO/ReturnCode)[1]',   'TInteger'    ),
             @vMessage    = Record.Col.value('(PALLETINFO/Message)[1]',      'TMessage'    )
      from @vxmlRFCProcOutput.nodes('/PALLETDETAILS') as Record(Col)
      OPTION (OPTIMIZE FOR (@vxmlRFCProcOutput = null));

      select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);
    end

  /* Even on failure we need to build the info to show to user */
  /* Get Pallet Info */
  exec pr_AMF_Info_GetPalletInfoXML @vPalletId, 'L' /* PalletDetails */, @vOperation, @vPalletInfoXML output, @vPalletDetailsXML output;

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', coalesce(@vPalletInfoXML, '') + @vPalletDetailsXML);

end /* pr_AMF_Inventory_BuildPallet_AddLPN */

Go

