/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/13  RIA     Added pr_AMF_Inventory_ModifySKU, pr_AMF_Inventory_ValidateSKU (CIMSV3-1108)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_ModifySKU') is not null
  drop Procedure pr_AMF_Inventory_ModifySKU;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Receiving_ModifySKU: In this proc we will build the xml needed
    in V2 format and call the SKUs_Modify procedure.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_ModifySKU
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
          @vSKUId                    TRecordId,
          @vSKU                      TSKU,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vDataXML                  TXML,
          @vSKUInfoXML               TXML,
          @vSKUDetailsXML            TXML,
          @vScannedEntityXML         TXML;
begin /* pr_AMF_Inventory_ModifySKU */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit    = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId          = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId        = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vSKUId           = Record.Col.value('(Data/m_SKUInfo_SKUId)[1]',            'TRecordId'    ),
         @vSKU             = Record.Col.value('(Data/m_SKUInfo_SKU)[1]',              'TSKU'         ),
         @vOperation       = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Build the input for V2 procedure */
  select @vxmlRFCProcInput = (select Record.Col.value('(Data/UnitLength)[1]',          'TFloat'  ) as UnitLength,
                                     Record.Col.value('(Data/UnitWidth)[1]',           'TFloat'  ) as UnitWidth,
                                     Record.Col.value('(Data/UnitHeight)[1]',          'TFloat'  ) as UnitHeight,
                                     Record.Col.value('(Data/UnitVolume)[1]',          'TFloat'  ) as UnitVolume,
                                     Record.Col.value('(Data/UnitWeight)[1]',          'TFloat'  ) as UnitWeight,
                                     Record.Col.value('(Data/InnerPacksPerLPN)[1]',    'TInteger') as InnerPacksperLPN,
                                     Record.Col.value('(Data/UnitsPerInnerPack)[1]',   'TInteger') as UnitsPerInnerPack,
                                     Record.Col.value('(Data/UnitsPerLPN)[1]',         'TInteger') as UnitsPerLPN
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for Xml Raw('Data'), elements XSINIL, Root('ModifySKUs'));

  select @vrfcProcInputxml = coalesce(convert(varchar(max), @vxmlRFCProcInput), '');

  /* Build SKUs in V2 desired format */
  select @vScannedEntityXML = dbo.fn_XmlNode('SKUs', dbo.fn_XmlNode('SKUId',    @vSKUId) +
                                                     dbo.fn_XmlNode('SKU',      @vSKU));

  select @vrfcProcInputxml = dbo.fn_XMLAddNode(@vrfcProcInputxml, 'ModifySKUs',
                                               dbo.fn_XmlNode('Action', @vOperation) + @vScannedEntityXML);

  /* call the V2 proc */
  exec pr_SKUs_Modify @vrfcProcInputxml, @vBusinessUnit, @vUserId, @vrfcProcOutputxml output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is an error, return */
  if (@vTransactionFailed > 0) return (@vTransactionFailed);

  /* Build info xml */
  select @InfoXML  = dbo.fn_AMF_BuildSuccessXML(@vrfcProcOutputxml);

  /* Get the SKU Info */
  exec pr_AMF_Info_GetSKUInfoXML @vSKUId, 'N', @vOperation,
                                 @vSKUInfoXML output, @vSKUDetailsXML output;

  /* Build the DataXML */
  select @DataXML = dbo.fn_XmlNode('Data', coalesce(@vSKUInfoXML, '') + coalesce(@vSKUDetailsXML, ''));

end /* pr_AMF_Inventory_ModifySKU */

Go

