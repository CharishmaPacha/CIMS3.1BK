/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_ValidateLPN') is not null
  drop Procedure pr_AMF_Inventory_ValidateLPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_ValidateLPN:

  We will call the V2 proc where all the LPN related validations are handled based
  on the operation.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_ValidateLPN
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  /* Standard variables */
  declare @vxmlInput                 xml,
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vReturnCode               TInteger,
          @vMessageName              TMessageName;
  /* LPN */
  declare @vLPN                      TLPN,
          @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML,
          @vLPNId                    TRecordId,
          @vLocation                 TLocation,
          @vOperation                TOperation;
begin /* pr_AMF_Inventory_ValidateLPN */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vUserId       = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vLPN          = Record.Col.value('(Data/LPN)[1]',                        'TLPN'         ),
         @vOperation    = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Validate LPN to make sure we can Add SKU, move or what ever */
  exec pr_RFC_ValidateLPN @vLPNId, @vLPN, @vOperation, @vBusinessUnit, @vUserId;

  /* Get the LPNId to build LPN Info and Details */
  select @vLPNId          = LPNId,
         @vLPN            = LPN
  from  LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@vLPN, @vBusinessUnit, 'LTU'));

  /* Get LPN Info */
  exec pr_AMF_Info_GetLPNInfoXML @vLPNId, 'LPNDetails' /* LPNDetails */, @vOperation, @vLPNInfoXML output, @vLPNDetailsXML output;

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', @vLPNInfoXML + @vLPNDetailsXML);

end /* pr_AMF_Inventory_ValidateLPN */

Go

