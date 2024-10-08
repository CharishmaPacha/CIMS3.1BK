/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/20  RT      pr_AMF_Inventory_MoveLPN: Changes to return error message (HA-219)
  2020/04/04  RT      pr_AMF_Inventory_MoveLPN: Changes to return the Message when the Pallet scanned to move the LPN (HA-182)
  2019/07/30  AY      pr_AMF_Inventory_MoveLPN: Added begin-end for success message (CID-871)
  2019/07/29  RIA     Added pr_AMF_Inventory_MoveLPN (CID-871)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_MoveLPN') is not null
  drop Procedure pr_AMF_Inventory_MoveLPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_MoveLPN: Reads the input and sends to V2 proc to
    Move the LPN to either Location or Pallet.

  Processes the requests for Move LPN work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_MoveLPN
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
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vScannedEntity            TEntity,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vNewLocation              TLocation,
          @vNewPallet                TPallet,
          @vSuccessMessage           TMessage;
begin /* pr_AMF_Inventory_MoveLPN */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vUserId           = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vBusinessUnit     = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vLPN              = Record.Col.value('(Data/m_LPNInfo_LPN)[1]',              'TLPN'         ),
         @vLPNId            = Record.Col.value('(Data/m_LPNInfo_LPNId)[1]',            'TRecordId'    ),
         @vScannedEntity    = Record.Col.value('(Data/ScannedEntity)[1]',              'TEntity'      )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Validate LPN */
  select @vLPNId  = LPNId
  from  LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@vLPN, @vBusinessUnit, 'LTU'));

  /* Validate LPN to make sure it can be moved, adjusted or what so ever */
  exec pr_RFC_MoveLPN @vLPNId, @vLPN, null, @vScannedEntity, @vBusinessUnit, @vUserId;

  /* Check if LPN got moved as V2 does not return any result */
  select @vNewLocation = Location,
         @vNewPallet   = Pallet
  from LPNs
  where (LPNId = @vLPNId);

  /* If V2 proc raises error then these steps will not be executed as LPN. Irrespective
     of any Entity fetch the success message from vwATEntity, as we are already raising error
     in the Move LPN if any */
  select top 1 @vSuccessMessage = Comment
  from vwATEntity
  where (EntityType = 'LPN') and (EntityId = @vLPNId)
  order by AuditId desc

  if (@vSuccessMessage is not null)
    begin
      select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vSuccessMessage);
      select @DataXML = (select 0 LPNId
                         for Xml Raw(''), elements, Root('Data'));
    end

end /* pr_AMF_Inventory_MoveLPN */

Go

