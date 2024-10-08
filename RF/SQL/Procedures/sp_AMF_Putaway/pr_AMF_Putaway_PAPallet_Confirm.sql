/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Putaway_PAPallet_Confirm') is not null
  drop Procedure pr_AMF_Putaway_PAPallet_Confirm;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Putaway_PAPallet_Confirm:

  Processes the requests for confirm Putaway Pallet
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Putaway_PAPallet_Confirm
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vxmlInput                 xml,
          @vxmlOutput                xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vReturnCode               TInteger,
          @vTransactionFailed        TBoolean,
          @vMessageName              TMessageName,
          /* Inputs */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vPalletId                 TRecordId,
          @vPallet                   TPallet,
          @vScannedLocation          TLocation,
          @vPutawayLocation          TLocation,
          @vPutawayZone              TZone,
          @vPAQuantity               TQuantity,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vPalletInfoXML            TXML,
          @vPalletDetailsXML         TXML,
          @vMessage                  TMessage;
begin /* pr_AMF_Putaway_PAPallet_Confirm */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  select @vBusinessUnit    = Record.Col.value('(SessionInfo/BusinessUnit)[1]',     'TBusinessUnit'),
         @vDeviceId        = Record.Col.value('(SessionInfo/DeviceId)[1]',         'TDeviceId'    ),
         @vUserId          = Record.Col.value('(SessionInfo/UserName)[1]',         'TUserId'      ),
         @vPalletId        = Record.Col.value('(Data/m_PalletInfo_PalletId)[1]',   'TRecordId'    ),
         @vPallet          = Record.Col.value('(Data/m_PalletInfo_Pallet)[1]',     'TPallet'      ),
         @vScannedLocation = Record.Col.value('(Data/ScannedLocation)[1]',         'TLocation'    ),
         @vPutawayLocation = Record.Col.value('(Data/m_DestLocation)[1]',          'TLocation'    ),
         @vPutawayZone     = Record.Col.value('(Data/m_DestZone)[1]',              'TZone'        ),
         @vPAQuantity      = Record.Col.value('(Data/m_PalletQuantity)[1]',        'TQuantity'    )
  from @vxmlInput.nodes('/Root')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Call the V2 proc and get the info */
  exec pr_RFC_PA_ConfirmPutawayPallet @vPallet, @vPutawayLocation, @vScannedLocation,
                                      @vPutawayZone, null /* InnerPacks */, @vPAQuantity,
                                      @vBusinessUnit, @vUserId, @vDeviceId, @vxmlRFCProcOutput output;

  /* Verify whether there are any errors or not */
  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output, @ErrorXML = @ErrorXML output;

  /* If there is an error, return */
  if (@vTransactionFailed > 0) return (@vTransactionFailed);

  /* V2 proc returns a success message, but that is not informative, so get the message
     from AT which is more descriptive to the user */
  select top 1 @vMessage = Comment
  from vwATEntity
  where (EntityId     = @vPalletId) and
        (ActivityType in ('PutawayPallet'))
  order by AuditId desc;

  /* Build success message */
  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  /* If successfully updated, do not return any PalletInfo as it would revert to prior screen */
  select @DataXML = (select 0 PalletId
                     for Xml Raw(''), elements, Root('Data'));

end /* pr_AMF_Putaway_PAPallet_Confirm */

Go

