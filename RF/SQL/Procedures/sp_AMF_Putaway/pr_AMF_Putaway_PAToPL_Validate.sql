/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/10  RIA     pr_AMF_Putaway_PAToPL_Validate, pr_AMF_Putaway_PAToPL_Confirm, pr_AMF_Putaway_PAToPL_SkipSKU: CleanUp (OB2-1197)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Putaway_PAToPL_Validate') is not null
  drop Procedure pr_AMF_Putaway_PAToPL_Validate;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Putaway_PAToPL_Validate: User scans a Pallet to start
    PA To picklane functiona and this procedure is to validate it and show the
    the next SKU to be putaway from the Pallet and the destination for it.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Putaway_PAToPL_Validate
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
          @vxmlOutput                xml,
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
          @vRFFormAction             TMessageName,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vPalletInfoXML            TXML,
          @vPalletId                 TRecordId,
          @vPADetailsXML             TXML,
          @vActivityLogId            TRecordId,
          @vSuccessMessage           TMessage;
begin /* pr_AMF_Putaway_PAToPL_Validate */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @InfoXML   = null,
         @ErrorXML  = null

  /* Read inputs from InputXML */
  select @vDeviceId      = Record.Col.value('(SessionInfo/DeviceId)[1]',     'TDeviceId'    ),
         @vUserId        = Record.Col.value('(SessionInfo/UserName)[1]',     'TUserId'      ),
         @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @vPallet        = Record.Col.value('(Data/Pallet)[1]',              'TPallet'      ),
         @vOperation     = Record.Col.value('(Data/Operation)[1]',           'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* clear the putawaypath position from devices here
     may be we can use the same device update procedure here to clear the devices table  */
  update Devices
  set PickSequence = null
  where DeviceId = (@vDeviceId + '@' + @vUserId);

  /* Call the V2 proc and get the info */
  exec pr_RFC_ValidatePutawayLPNOnPallet @vPallet, null, @vBusinessUnit, @vUserId, @vDeviceId, @vxmlRFCProcOutput output;

  /* Verify whether there are any errors or not */
  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output, @ErrorXML = @ErrorXML output;

  /* If there are no errors then proceed */
  if (@vTransactionFailed <= 0)
    begin
      select @vPalletId = PalletId,
             @vPallet   = Pallet
      from Pallets
      where (PalletId = dbo.fn_Pallets_GetPalletId (@vPallet, @vBusinessUnit));

      /* Get Pallet Info */
      exec pr_AMF_Info_GetPalletInfoXML @vPalletId, 'N' /* LPNDetails */, @vOperation, @vPalletInfoXML output;

      /* Get the putaway SKU info to show */
      exec pr_Putaway_PAtoPL_GetSKUToPutaway @vPalletId, @vDeviceId, @vUserId, null, @vBusinessUnit, @vPADetailsXML output;

      /* Build the DataXML */
      select @DataXml = dbo.fn_XMLNode('Data', coalesce(convert(varchar(max), @vPalletInfoXML), '') +
                                               @vPADetailsXML);
    end
end /* pr_AMF_Putaway_PAToPL_Validate */

Go

