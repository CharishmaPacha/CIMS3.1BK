/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/23  RIA     pr_AMF_Inventory_AddSKUToLPN, pr_AMF_Inventory_AddSKUToLPN_ValidateSKU : Changes to include InventoryClass1 (HA-1794)
  2020/09/13  RIA     Made changes to pr_AMF_Inventory_AddSKUToLPN_ValidateSKU (CIMSV3-812)
  2020/04/11  RIA     Added pr_AMF_Inventory_AddSKUToLPN_ValidateSKU, made changes to pr_AMF_Inventory_AddSKUToLPN (CIMSV3-812)
  2019/08/20  RIA     pr_AMF_Inventory_BuildPallet_AddLPN, pr_AMF_Inventory_AddSKUToLPN: Changes for evaluating the if statements (CID-948)
  2019/08/17  RIA     Added pr_AMF_Inventory_AddSKUToLPN (CID-948)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_AddSKUToLPN') is not null
  drop Procedure pr_AMF_Inventory_AddSKUToLPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_AddSKUToLPN:

  Processes the requests for Add SKU To LPN work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_AddSKUToLPN
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TDescription,
          @vMessage                  TMessage,
          @vxmlInput                 xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vDeviceId                 TDeviceId,
          @vUserId                   TUserId,
          @vLPN                      TLPN,
          @vSKU                      TSKU,
          @vInnerPacks               TInnerPacks,
          @vUnitsPerIP               TQuantity,
          @vUnits                    TQuantity,
          @vUnits1                   TQuantity,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML,
          @vLPNId                    TRecordId,
          @vLPNDetailId              TRecordId,
          @vSKUId                    TRecordId,
          @vQuantity                 TQuantity,
          @vFormAction               TAction;
begin /* pr_AMF_Inventory_AddSKUToLPN */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read inputs, LPNId will be sent as input for info proc and units will be used to see
     whether user keyed in Units under Eaches/Cases Panel and take that input for ADDSKU proc input */
  select @vLPNId        = Record.Col.value('(Data/m_LPNInfo_LPNId)[1]',   'TRecordId'),
         @vUnits        = nullif(Record.Col.value('(Data/NewUnits)[1]',   'TQuantity'), ''),
         @vUnits1       = nullif(Record.Col.value('(Data/NewUnits1)[1]',  'TQuantity'), '')
  from @vxmlInput.nodes('/Root') as Record(Col);

  /* Build the input for V2 procedure */
  select @vrfcProcInputxml = (select Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'  ) as BusinessUnit,
                                     Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'      ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'        ) as UserId,
                                     Record.Col.value('(Data/m_LPNInfo_LPNId)[1]',            'TRecordId'      ) as LPNId,
                                     Record.Col.value('(Data/m_LPNInfo_LPN)[1]',              'TLPN'           ) as LPN,
                                     Record.Col.value('(Data/SKU)[1]',                        'TSKU'           ) as NewSKU,
                                     Record.Col.value('(Data/NewInnerPacks)[1]',              'TInnerPacks'    ) as NewInnerPacks,
                                     coalesce(@vUnits, @vUnits1)                                                 as NewQuantity,
                                     Record.Col.value('(Data/InventoryClass1)[1]',            'TInventoryClass') as InventoryClass1,
                                     Record.Col.value('(Data/InventoryClass2)[1]',            'TInventoryClass') as InventoryClass2, -- Future use
                                     Record.Col.value('(Data/InventoryClass3)[1]',            'TInventoryClass') as InventoryClass3  -- Future use
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('ConfirmAddSKUToLPN'), elements);

  exec pr_RFC_AddSKUToLPN @vrfcProcInputxml, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output, @InfoXML output;

  /* If there is error raised simply return */
  if (@vTransactionFailed > 0) return;

  /* Get the LPN Info */
  exec pr_AMF_Info_GetLPNInfoXML @vLPNId, 'LPNDetails' /* LPNDetails */, null, @vLPNInfoXML output, @vLPNDetailsXML output;

  /* Build the DataXML */
  select @DataXml = dbo.fn_XmlNode('Data', coalesce(convert(varchar(max), @vLPNInfoXML), '') +
                                           @vLPNDetailsXML);

end /* pr_AMF_Inventory_AddSKUToLPN */

Go

