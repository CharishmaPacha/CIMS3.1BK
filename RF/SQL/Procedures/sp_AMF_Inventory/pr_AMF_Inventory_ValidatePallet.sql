/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/22  RIA     pr_AMF_Inventory_BuildPallet_AddLPN, pr_AMF_Inventory_ValidatePallet: Made changes (CID-947)
  2019/10/20  RIA     pr_AMF_Inventory_BuildPallet_AddLPN, pr_AMF_Inventory_ValidatePallet,
  2019/10/11  RIA     pr_AMF_Inventory_BuildPallet_AddLPN, pr_AMF_Inventory_ValidatePallet (CID-911)
  2019/08/12  RIA     Added pr_AMF_Inventory_MovePallet, pr_AMF_Inventory_ValidatePallet (CID-911)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_ValidatePallet') is not null
  drop Procedure pr_AMF_Inventory_ValidatePallet;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_ValidatePallet: Validates the Pallet for the operation
   being performed. This is typically utilized when a Pallet is scanned for an
   operation i.e. for example on Move Pallet or Build Pallet
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_ValidatePallet
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
          @vOperation                TOperation;
          /* Functional variables */
  declare @vPalletId                 TRecordId,
          @vPalletInfoXML            TXML,
          @vPalletDetailsXML         TXML;
begin /* pr_AMF_Inventory_ValidatePallet */

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
         @vPallet         = Record.Col.value('(Data/Pallet)[1]',                     'TPallet'      ),
         @vOperation      = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Validate Pallet to make sure it can be moved, adjusted or whatsoever */
  exec pr_RFC_Inv_ValidatePallet @vPallet, @vOperation, @vBusinessUnit, @vUserId, @vDeviceId, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* if transactions is successful, return Pallet info with List of LPNs on Pallet */
  if (@vTransactionFailed <= 0)
    begin
      /* Get the palletId, considering the scanned pallet is a valid Pallet */
      select @vPalletId   = Record.Col.value('(PalletId)[1]',        'TRecordId'),
             @vPallet     = Record.Col.value('(Pallet)[1]',          'TPallet'  )
      from @vxmlRFCProcOutput.nodes('/PALLETDETAILS/PALLETINFO') as Record(Col)
      OPTION (OPTIMIZE FOR (@vxmlRFCProcOutput = null));

     /* Get Pallet Info */
      exec pr_AMF_Info_GetPalletInfoXML @vPalletId, 'L' /* LPNsOnPallet */, @vOperation, @vPalletInfoXML output, @vPalletDetailsXML output;

      /* Build the DataXML */
      select @DataXml = dbo.fn_XMLNode('Data', coalesce(@vPalletInfoXML, '') + @vPalletDetailsXML);
    end

end /* pr_AMF_Inventory_ValidatePallet */

Go

