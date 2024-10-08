/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/12  RIA     Added pr_AMF_Inventory_MovePallet, pr_AMF_Inventory_ValidatePallet (CID-911)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_MovePallet') is not null
  drop Procedure pr_AMF_Inventory_MovePallet;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_MovePallet:

  Processes the requests for Move Pallet work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_MovePallet
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
          @vPalletId                 TRecordId,
          @vPallet                   TPallet,
          @vLocation                 TLocation;
          /* Functional variables */
  declare @vSuccessMessage           TMessage,
          @vMessage                  TMessage;
begin /* pr_AMF_Inventory_MovePallet */

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
         @vPallet         = Record.Col.value('(Data/Pallet)[1]',                     'TPallet'      ),
         @vLocation       = Record.Col.value('(Data/ScannedLocation)[1]',            'TLocation'    )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Validate Pallet to make sure it can be moved, adjusted or what so ever */
  exec pr_RFC_Inv_MovePallet @vPallet, @vLocation, @vBusinessUnit, @vUserId, @vDeviceId, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output, @InfoXML output;

  /* If the transaction was successful, transform V2 format response into AMF Format Data element */
  if (@vTransactionFailed <= 0)
    begin
      /* On success do not return PalletId so we return back to menu */
      select @DataXML = (select 0 PalletId
                         for Xml Raw(''), elements, Root('Data'));
    end
end /* pr_AMF_Inventory_MovePallet */

Go

