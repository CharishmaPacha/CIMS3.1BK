/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_AMF_Returns_ValidateLPNOrLocation: Evaluate the I/P sent and provide the respective O/P (OB2-1784)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Returns_ValidateLPNOrLocation') is not null
  drop Procedure pr_AMF_Returns_ValidateLPNOrLocation;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Returns_ValidateLPNOrLocation: User scans LPN/Picklane to receive
  the Returns Inv. We are here to validate the scanned input. So, we need to evaluate
  the scanned i/p (whether it is LPN or Picklane) and return that info to RF in a generic way.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Returns_ValidateLPNOrLocation
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
          @vScannedEntity            TEntity,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vDeviceName               TName,
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vLPNType                  TTypeCode,
          @vLPNStatus                TStatus,
          @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vLocationType             TTypeCode,
          @vLocationStatus           TStatus,
          @vEntityId                 TRecordId,
          @vEntityKey                TEntityKey,
          @vScannedEntityType        TEntity,
          @vValue1                   TDescription,
          @vValue2                   TDescription,
          @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML,
          @vxmlData                  xml;
begin /* pr_AMF_Returns_ValidateLPNOrLocation */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId        = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId      = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vScannedEntity = Record.Col.value('(Data/LPN)[1]',                        'TLPN'         ),
         @vOperation     = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Device Name is used to update dataxml in devices */
  select @vDeviceName = @vDeviceId + '@' + @vUserId;

  /* Delete the RFFormAction */
  select @vxmlData = convert(xml, @DataXML);
  set @vxmlData.modify('delete /Data/RFFormAction');
  select @DataXML = convert(varchar(max), @vxmlData);

  /* Update the devices with the received/input xml */
  update Devices
  set DataXML = @DataXML
  where (DeviceId = @vDeviceName);

  /* Identify the LPN or Picklane */
  exec pr_LPNs_IdentifyLPNOrLocation @vScannedEntity, @vBusinessUnit, @vUserId,
                                     @vScannedEntityType out, @vLPNId out, @vLPN out,
                                     @vLocationId out, @vLocation out;

  /* Get the Location related Info */
  if (@vScannedEntityType = 'LOC')
    select @vScannedEntityType = 'Location',
           @vEntityId          = LocationId,
           @vEntityKey         = Location,
           @vLocation          = Location,
           @vLocationType      = LocationType,
           @vLocationStatus    = Status
    from Locations
    where (LocationId = @vLocationId);

  /* Get the LPN related Info */
  if (@vScannedEntityType = 'LPN')
    select @vEntityId  = LPNId,
           @vEntityKey = LPN,
           @vLPN       = LPN,
           @vLPNType   = LPNType,
           @vLPNStatus = Status
    from LPNs
    where (LPNId = @vLPNId);

  /* Currently checking for valid LPN with new status, more validations to be added */
  /* Validations */
  if (@vScannedEntityType = 'LPN')
    begin
      if (@vLPNType not in ('C', 'TO' /* Carton */))
        set @vMessageName = 'Returns_LPNTypeIsInvalid';
      else
      /* Currently limiting to New Status LPN, need to allow user to receive to same LPN */
      if (@vLPNStatus <> 'N' /* New */)
        set @vMessageName = 'Returns_LPNStatusIsInvalid';
    end
  else
  if (@vScannedEntityType = 'Location')
    begin
      if (@vLocationType not in ('K' /* Picklane */))
        select @vMessageName = 'Returns_LocationIsNotPicklane', @vValue1 = @vLocation;
      else
      /* Scanned location should be an Available location. */
      if (@vLocationStatus <> 'U' /* Available */)
        set @vMessageName = 'Returns_LocationStatusIsInvalid';
    end

  /* When there is an error then we will be updating the devices with dataxml */
  if (@vMessageName is not null)
    begin
      /* If it was not a valid LPN, then delete it so that it is cleared from the screen */
      select @vxmlData = convert(xml, @DataXML);
      set @vxmlData.modify('delete /Data/LPN');
      select @DataXML = convert(varchar(max), @vxmlData);

      /* Update the devices */
      update Devices
      set DataXML = @DataXML
      where (DeviceId = @vDeviceName);

      exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vValue1, @vValue2;
    end

  /* Build DataXML */
  select @DataXML = dbo.fn_XMLAddNode(@DataXML, 'Data', dbo.fn_XMLNode('ValidatedEntityType', @vScannedEntityType) +
                                                        dbo.fn_XMLNode('ValidatedEntityId',   @vEntityId) +
                                                        dbo.fn_XMLNode('ValidatedEntityKey',  @vEntityKey));

end /* pr_AMF_Returns_ValidateLPNOrLocation */

Go

