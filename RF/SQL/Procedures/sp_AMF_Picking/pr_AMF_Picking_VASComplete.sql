/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/06/21  RIA     pr_AMF_Picking_VASComplete: Changes to move LPN into location (CID-577)
  2019/06/17  RIA     Added pr_AMF_Picking_VASComplete (CID-577)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_VASComplete') is not null
  drop Procedure pr_AMF_Picking_VASComplete;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_VASComplete:

  Processes the requests for VAS complete work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_VASComplete
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  declare @vMessageName            TMessageName,
          @vInputXML               xml,
          @vrfcProcInputxml        xml,
          @vrfcProcOutputxml       xml,
          @vPalletDetails          xml,
          @vTaskInfoxml            xml,
          @vSuccessMessage         TMessage,
          @vLPNId                  TRecordId,
          @vLPN                    TLPN,
          @vLocationId             TRecordId,
          @vLocation               TLocation,
          @vCurrentLocation        TLocation,
          @vLPNStatus              TStatus,
          @vNewLocation            TLocation,
          @vRFFormAction           TMessageName,
          @vUserId                 TUserId,
          @vBusinessUnit           TBusinessUnit,
          @vMessage                TMessage,
          @vTaskId                 TRecordId,
          @vActivityLogId          TRecordId,
          @vTransactionFailed      TBoolean;

begin /* pr_AMF_Picking_VASComplete */

  /* Clean up Input XML */
  select @InputXML = replace (@InputXML, '&lt;', '<');
  select @InputXML = replace (@InputXML, '&gt;', '>');
  select @vInputXML = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vInputXML.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vInputXML.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read the necessary inputs from Inputs xml */
  select @vLPN           = Record.Col.value('(Data/m_LPNInfo_LPN)[1]',              'TLPN'         ),
         @vRFFormAction  = Record.Col.value('(Data/RFFormAction)[1]',               'TMessageName' ),
         @vUserId        = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit')
  from @vInputXML.nodes('/Root') as Record(Col);

  /* Get the LPNId */
  select @vLPNId            = LPNId,
         @vLPN              = LPN,
         @vCurrentLocation  = Location,
         @vLPNStatus        = Status
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@vLPN, @vBusinessUnit, 'LTU'));

  if (@vCurrentLocation not like 'VASDrop%')
    select @vMessageName = 'AMF_VASComplete_CartonNotInVASArea';
  else
  if (@vLPNStatus = 'U' /* Picking */)
    select @vMessageName = 'AMF_VASComplete_LPNPicking';
  else
  if (@vLPNStatus <> 'K' /* Picked */)
    select @vMessageName = 'AMF_VASComplete_LPNNotPicked';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    exec pr_Messages_ErrorHandler @vMessageName;

  /* Fetch a Staging Location in PTC Drop area to move the LPN to */
  select top 1 @vLocationId = LocationId,
               @vLocation   = Location
  from Locations
  where (LocationType = 'S' /* Staging */) and (PutawayZone like 'Drop-PTC%') and (@vBusinessUnit = BusinessUnit)
  order by Status;

  /* Execute V2 procedure */
  exec pr_RFC_MoveLPN @vLPNId, @vLPN, @vLocationId, @vLocation, @vBusinessUnit, @vUserId;

  select @vNewLocation = Location
  from LPNs
  where (LPNId = @vLPNId);

  if (@vNewLocation in ('PTCDrop-01', 'PTCDrop-02', 'PTCDrop-03'))
    begin
      select @vMessage = dbo.fn_Messages_Build('AMF_VASLPNMove_Successfull', @vLPN, @vNewLocation, null, null, null);
      select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);
      select @DataXML = (select 0 LPNId
                         for Xml Raw(''), elements, Root('Data'));
    end
  else
    begin
      exec pr_AMF_RaiseErrorAndReset 'AMF_VASLPNMove_Unsuccessful', @ErrorXML = @ErrorXML output;
    end

end /* pr_AMF_Picking_VASComplete */

Go

