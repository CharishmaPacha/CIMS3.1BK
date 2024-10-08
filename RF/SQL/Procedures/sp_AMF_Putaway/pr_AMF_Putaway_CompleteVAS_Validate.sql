/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/12/11  RIA     Added pr_AMF_Putaway_CompleteVAS_Confirm, pr_AMF_Putaway_CompleteVAS_Validate (CID-1211)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Putaway_CompleteVAS_Validate') is not null
  drop Procedure pr_AMF_Putaway_CompleteVAS_Validate;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Putaway_CompleteVAS_Validate: Validates the Location being
   scanned when Complete VAS operation is initiated
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Putaway_CompleteVAS_Validate
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
          @vLocation                 TLocation,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLocationInfoXML          TXML,
          @vLocationDetailsXML       TXML,
          @vLocationId               TRecordId,
          @vLocationType             TLocationType,
          @vLocationStatus           TStatus,
          @vRFFormAction             TMessageName,
          @vMessage                  TMessage,
          @vTaskId                   TRecordId,
          @vActivityLogId            TRecordId,
          @vSuccessMessage           TMessage;
begin /* pr_AMF_Putaway_CompleteVAS_Validate */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read the inputs */
  select @vBusinessUnit     = Record.Col.value('(SessionInfo/BusinessUnit)[1]',     'TBusinessUnit'),
         @vUserId           = Record.Col.value('(SessionInfo/UserName)[1]',         'TUserId'      ),
         @vDeviceId         = Record.Col.value('(SessionInfo/DeviceId)[1]',         'TDeviceId'    ),
         @vLocation         = Record.Col.value('(Data/Location)[1]',                'TLocation'    ),
         @vOperation        = Record.Col.value('(Data/Operation)[1]',               'TOperation'   )
  from @vxmlInput.nodes('/Root')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get the Location Type */
  select @vLocationId     = LocationId,
         @vLocation       = Location,
         @vLocationType   = LocationType,
         @vLocationStatus = Status
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @vLocation, @vDeviceId, @vUserId, @vBusinessUnit));

  /* Validations */
  if (nullif(@vLocationId, 0) is null)
    set @vMessageName = 'LocationDoesNotExist';
  else
  if (@vLocationStatus in ('I' /* Inactive */))
    set @vMessageName = 'PALocationIsInactive';
  else
  if (@vLocationType not in ('D', 'S', 'R'/* Dock, Staging, Reserve */))
    set @vMessageName = 'LocationTypeIsInvalid';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to RF */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get Location Info */
  exec pr_AMF_Info_GetLocationInfoXML @vLocationId, null /* LOCDETAILS */, @vOperation,
                                      @vLocationInfoXML output, @vLocationDetailsXML output;

  /* Build the Location Info */
  select @DataXml = dbo.fn_XmlNode('Data', coalesce(@vLocationInfoXML, '') +
                                           coalesce(@vLocationDetailsXML, ''));
end /* pr_AMF_Putaway_CompleteVAS_Validate */

Go

