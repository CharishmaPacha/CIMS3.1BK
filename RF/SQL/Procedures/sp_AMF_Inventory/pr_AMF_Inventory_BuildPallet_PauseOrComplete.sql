/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/11/11  RIA     pr_AMF_Inventory_BuildPallet_PauseOrComplete: Changes to move pallet if it has qty (OB2-1006)
  pr_AMF_Inventory_BuildPallet_PauseOrComplete: Code cleanup (CID-947)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_BuildPallet_PauseOrComplete') is not null
  drop Procedure pr_AMF_Inventory_BuildPallet_PauseOrComplete;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_BuildPallet_PauseOrComplete:

  Processes the requests for Complete/Puase Build Pallet work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_BuildPallet_PauseOrComplete
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  declare @vxmlInput                 xml,
          @vPallet                   TPallet,
          @vLPNInfo                  TXML,
          @vLPNDetails               xml,
          @vxmlPalletInfo            xml,
          @vPalletId                 TRecordId,
          @vSuccessMessage           TMessage,
          @vPalletStatus             TStatus,
          @vQuantity                 TQuantity,
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vReturnCode               TInteger,
          @vMessage                  TMessage,
          @vMessageName              TMessageName;
begin /* pr_AMF_Inventory_BuildPallet_PauseOrComplete */

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
         @vPallet         = Record.Col.value('(Data/m_PalletInfo_Pallet)[1]',        'TPallet'      ),
         @vPalletId       = Record.Col.value('(Data/m_PalletInfo_PalletId)[1]',      'TRecordId'    )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* get pallet status */
  select @vPalletStatus = Status,
         @vQuantity     = Quantity
  from Pallets
  where (PalletId = @vPalletId);

  /* Currently considering only Empty statuses, based on the future issues or findings
     can use validate proc or add more statuses */
  if (@vPalletStatus = 'E' /* Empty */) and (@vQuantity = 0)
    begin
      select @vMessage = 'AMF_PalletNeedNotBeLocated';
      select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);
      select @DataXML = (select 0 PalletId
                         for Xml Raw(''), elements, Root('Data'));
      return;
    end

  /* If Pallet is not empty, then we will direct user to place pallet into a Location */
  select @DataXML = dbo.fn_XMLAddNode(@DataXML, 'Data', dbo.fn_XMLNode('Operation', 'MovePallet'));

end /* pr_AMF_Inventory_BuildPallet_PauseOrComplete */

Go

