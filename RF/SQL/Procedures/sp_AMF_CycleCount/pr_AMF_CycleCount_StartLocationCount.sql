/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/03  PK      pr_AMF_CycleCount_StartLocationCount: Bug fix to consider scanned location if location is null (HA-1971)
  pr_AMF_CycleCount_ConfirmPicklaneCC, pr_AMF_CycleCount_StartLocationCount (HA-1079)
  2020/08/31  AY      pr_AMF_CC_ConfirmReserveLoc_LPND2, pr_AMF_CycleCount_StartLocationCount:
  2020/08/25  RIA     pr_AMF_CycleCount_StartLocationCount: Clean up and changes (CIMSV3-773)
  2020/08/22  RIA     pr_AMF_CycleCount_StartLocationCount: Code revamp and sending data to form (HA-1079)
  2020/07/11  MS      pr_AMF_CycleCount_StartLocationCount: Changes to call DirectLc CC (HA-1080)
  2020/04/01  SK      pr_AMF_CycleCount_StartLocationCount: changes to populate data for Location CC
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_CycleCount_StartLocationCount') is not null
  drop Procedure pr_AMF_CycleCount_StartLocationCount;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_CycleCount_StartLocationCount: Validates the scanned entity and
    raises an error if scanned entity is not a valid Location and returns LocationInfo
    if valid.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_CycleCount_StartLocationCount
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
          @Location                  TLocation,
          @vPickZone                 TZoneId,
          @vBatchNo                  TTaskBatchNo,
          @vScannedLocation          TLocation,      -- Location scanned in 2nd screen in Directed CC
          @vIsSuggLocScanned         TFlags,         -- Used to check whether user scanned suggested location or not
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vTaskSubType              TFlag,
          @vTaskDetailId             TRecordId,
          @vLocationInfoXML          TXML,
          @vLocationDetailsXML       TXML,
          @vAdditionalInfoXML        TXML,
          @vDirectedCCInfoXML        TXML;
begin /* pr_AMF_CycleCount_StartLocationCount */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML             = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML           = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML            = null,
         @InfoXML             = null,
         @vLocationInfoXML    = null,
         @vLocationDetailsXML = null,
         @vTaskSubType        = 'N' /* Default: Non-Directed CC */;

  /*  Read inputs from InputXML */
  select @vBusinessUnit     = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId           = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId         = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @Location          = Record.Col.value('(Data/Location)[1]',                   'TLocation'    ),
         @vBatchNo          = Record.Col.value('(Data/BatchNo)[1]',                    'TTaskBatchNo' ),
         @vPickZone         = Record.Col.value('(Data/PickZone)[1]',                   'TZone'        ),
         @vScannedLocation  = Record.Col.value('(Data/ScannedLocation)[1]',            'TLocation'    ),
         @vIsSuggLocScanned = Record.Col.value('(Data/IsSuggLocScanned)[1]',           'TFlags'       ),
         @vOperation        = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get Location */
  select @Location = coalesce(@Location, @vScannedLocation);

  /* Call Directed or Non Directed workflow based on the user inputs given */
  if (coalesce(@vBatchNo, '') <> '') or (coalesce(@vPickZone, '') <> '')
    begin
      set @vxmlRFCProcInput = dbo.fn_XMLNode('DIRECTEDLOCCC',
                                  dbo.fn_XMLNode('BatchNo', @vBatchNo) +
                                  dbo.fn_XMLNode('PickZone', @vPickZone));

      exec pr_RFC_CC_StartDirectedLocCC @vxmlRFCProcInput, @vBusinessUnit,
                                        @vUserId, @vDeviceId, @vxmlRFCProcOutput output;

      select @vTaskSubType = 'D' /* Directed CC */;
    end
  else
    exec pr_RFC_CC_StartLocationCC @Location, null /* TaskDetailId */, @vBusinessUnit,
                                   @vUserId, @vDeviceId, @vxmlRFCProcOutput output;

  /* Evaluate the result from the above call */
  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is an error, return */
  if (coalesce(@vTransactionFailed, 0) <> 0) return (@vTransactionFailed);

  /* For non-directed cc as user scans location and for directed cc in scan sugg loc
     screen, we are setting the IsSuggLocScanned value, based on these build the data xml */
  if ((@vIsSuggLocScanned = 'Y') or (coalesce(@Location, '') <> ''))
    /* Pass the output xml to the proc and we will build necessary info there along with
       the manipulating the node names of V2 returned data set */
    exec pr_CycleCount_BuildInfo @vxmlRFCProcOutput, @vOperation, @vLocationInfoXML output,
                                 @vLocationDetailsXML output, @vAdditionalInfoXML output;
  else
    /* Build xml to send only suggested location to user */
    exec pr_CycleCount_BuildDataForDirectedCC @vxmlRFCProcOutput, @vDirectedCCInfoXML output;

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', coalesce(@vLocationInfoXML, '') + coalesce(@vLocationDetailsXML, '') +
                                           coalesce(@vAdditionalInfoXML, '') + coalesce(@vDirectedCCInfoXML, '') +
                                           dbo.fn_XMLNode('TaskSubType', @vTaskSubType));

end /* pr_AMF_CycleCount_StartLocationCount */

Go

