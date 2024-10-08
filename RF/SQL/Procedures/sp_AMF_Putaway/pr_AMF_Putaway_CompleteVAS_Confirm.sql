/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/12/11  RIA     Added pr_AMF_Putaway_CompleteVAS_Confirm, pr_AMF_Putaway_CompleteVAS_Validate (CID-1211)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Putaway_CompleteVAS_Confirm') is not null
  drop Procedure pr_AMF_Putaway_CompleteVAS_Confirm;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Putaway_CompleteVAS_Confirm: When VAS is completed on a LPN
    user scans the LPN into a Location by invoking this procedure. Based upon
    various Wave Types and processes, the LPN status may be updated and inventory
    changes made.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Putaway_CompleteVAS_Confirm
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
          @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vScannedLPN               TLPN,
          @vScannedLPNs              TCount,
          @vRFFormAction             TMessageName,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLocationInfoXML          TXML,
          @vLocationDetailsXML       TXML,
          @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML,
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vActivityLogId            TRecordId,
          @vSuccessMessage           TMessage;
begin /* pr_AMF_Putaway_CompleteVAS_Confirm */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read the inputs */
  select @vBusinessUnit       = Record.Col.value('(SessionInfo/BusinessUnit)[1]',              'TBusinessUnit'),
         @vUserId             = Record.Col.value('(SessionInfo/UserName)[1]',                  'TUserId'      ),
         @vDeviceId           = Record.Col.value('(SessionInfo/DeviceId)[1]',                  'TDeviceId'    ),
         @vLocationId         = Record.Col.value('(Data/m_LocationInfo_LocationId)[1]',        'TRecordId'    ),
         @vLocation           = Record.Col.value('(Data/m_LocationInfo_Location)[1]',          'TLocation'    ),
         @vScannedLPN         = Record.Col.value('(Data/LPN)[1]',                              'TLPN'         ),
         @vOperation          = Record.Col.value('(Data/Operation)[1]',                        'TOperation'   ),
         @vScannedLPNs        = Record.Col.value('(Data/ScannedLPNs)[1]',                      'TCount'       )
  from @vxmlInput.nodes('/Root')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get the info of the scanned LPN */
  select @vLPNId       = LPNId,
         @vLPN         = LPN
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@vScannedLPN, @vBusinessUnit, 'LTU'));

   /* Build the input for V2 procedure */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(Data/m_LocationInfo_LocationId)[1]',  'TRecordId'    ) as LocationId,
                                     Record.Col.value('(Data/m_LocationInfo_Location)[1]',    'TLocation'    ) as Location,
                                     Record.Col.value('(Data/LPN)[1]',                        'TLPN'         ) as LPN,
                                     Record.Col.value('(Data/Operation)[1]',                  'TOperation'   ) as ScannedLocation
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('CompleteVAS'), elements);

  select @vRFCProcInputxml = convert(varchar(max), @vxmlRFCProcInput);

 /* Call the V2 proc and get the info */
  exec pr_RFC_PA_CompleteVAS @vRFCProcInputxml, @vRFCProcOutputxml output;

  select @vxmlRFCProcOutput = convert(xml, @vRFCProcOutputxml);

  /* Get the success or error xml */
  exec pr_AMF_EvaluateExecResult @vrfcProcOutputxml, @vTransactionFailed output,
                                 @ErrorXML output, @InfoXML = @InfoXML output;

  if (@ErrorXML is null)
    begin
      /* Update scanned LPNs count */
      select @vScannedLPNs  = coalesce(@vScannedLPNs, 0) + 1;

      /* Call Get Location info XML proc to get the location information */
      exec pr_AMF_Info_GetLocationInfoXML @vLocationId, null /* Location Details */, @vOperation,
                                          @vLocationInfoXML output, @vLocationDetailsXML output;

      /* Call Get Location info XML proc to get the location information */
      exec pr_AMF_Info_GetLPNInfoXML @vLPNId, null /* LPN Details */, @vOperation,
                                     @vLPNInfoXML output, @vLPNDetailsXML output;

      /* Build the Location Info */
      select @DataXml = dbo.fn_XmlNode('Data', coalesce(@vLocationInfoXML, '') +
                                               coalesce(@vLPNInfoXML, '') +
                                               dbo.fn_XMLNode('ScannedLPNs', @vScannedLPNs));
    end
end /* pr_AMF_Putaway_CompleteVAS_Confirm */

Go

