/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Putaway_PAByLoc_Validate') is not null
  drop Procedure pr_AMF_Putaway_PAByLoc_Validate;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Putaway_PAByLoc_Validate: Validates the scanned location before
   user starts putting away LPNs into it.

  Calls the V2 proc pr_RFC_ValidatePutawayByLocation, and if
  it is a valid location then we will return the data related to that location
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Putaway_PAByLoc_Validate
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
          @vStatus                   TStatus;
begin /* pr_AMF_Putaway_PAByLoc_Validate */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @InfoXML   = null,
         @ErrorXML  = null

  /* Read inputs from InputXML */
  select @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @vUserId        = Record.Col.value('(SessionInfo/UserName)[1]',     'TUserId'      ),
         @vDeviceId      = Record.Col.value('(SessionInfo/DeviceId)[1]',     'TDeviceId'    ),
         @vLocation      = Record.Col.value('(Data/Location)[1]',            'TLocation'    ),
         @vOperation     = Record.Col.value('(Data/Operation)[1]',           'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Call the V2 proc to validate the location */
  exec pr_RFC_ValidatePutawayByLocation @vLocationId, @vLocation, @vBusinessUnit, @vUserId;

  /* As V2 proc calls reraise error and if i there are any errors we will get here */
  /* Is there any best way, we need to use the same code twice, bcoz does not return anything */
  select @vLocationId   = LocationId,
         @vLocation     = Location,
         @vStatus       = Status
  from  Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (@vLocationId, @vLocation, @vDeviceId, @vUserId, @vBusinessUnit));

  /* Call Get Location Info XML proc to get the location information */
  exec pr_AMF_Info_GetLocationInfoXML @vLocationId, @LocationInfoXML = @vLocationInfoXML output,
                                      @LocationDetailsXML = @vLocationDetailsXML output;

  /* Build the Location Info */
  select @DataXml = dbo.fn_XmlNode('Data', coalesce(@vLocationInfoXML, '') +
                                           coalesce(@vLocationDetailsXML, ''));

end /* pr_AMF_Putaway_PAByLoc_Validate */

Go

