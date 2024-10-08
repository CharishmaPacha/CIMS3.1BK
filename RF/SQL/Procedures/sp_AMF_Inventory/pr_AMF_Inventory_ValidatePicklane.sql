/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_AMF_Inventory_MP_ValidateSelectedOptions, Made changes to pr_AMF_Inventory_ValidatePicklaneLocation (CIMSV3-655)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_ValidatePicklane') is not null
  drop Procedure pr_AMF_Inventory_ValidatePicklane;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_ValidatePicklane: Validates the scanned or entered
  location as a Picklane. If a picklane is not scanned, it would raise an error
  as well. The validations depend upon the Operation.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_ValidatePicklane
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
  declare @vAvailableQty             TQuantity,
          @vReservedQty              TQuantity,
          @vDirectedQty              TQuantity,
          @vDisplayOptions           TXML,
          /* Location */
          @vLocationId               TRecordId,
          @vLocationStatus           TStatus,
          @vLocationType             TLocationType,
          @vNumSKUs                  TCount,
          @vAllowMultipleSKUs        TFlags,
          @vInvClass                 TInventoryClass,
          @vLocationInfoXML          TXML,
          @vLocationDetailsXML       TXML;
begin /* pr_AMF_Inventory_ValidatePicklane */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML         = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML       = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML        = null,
         @InfoXML         = null,
         @vDisplayOptions = '';

  /*  Read inputs from InputXML */
  select @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId       = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId     = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vLocation     = Record.Col.value('(Data/ScannedPicklane)[1]',            'TLocation'    ),
         @vOperation    = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get the LocationId from the scanned location */
  select @vLocationId        = LocationId,
         @vLocation          = Location,
         @vLocationStatus    = Status,
         @vLocationType      = LocationType,
         @vNumSKUs           = NumLPNs,
         @vAllowMultipleSKUs = AllowMultipleSKUs
  from Locations
  where (locationId = dbo.fn_Locations_GetScannedLocation(null, @vLocation, @vDeviceId, @vUserId, @vBusinessUnit));

  /* Get the LPN Details, considering scanned Location is a Picklane using the same */
  select @vAvailableQty = sum(Quantity),
         @vReservedQty  = sum(ReservedQty),
         @vDirectedQty  = sum(DirectedQty)
  from LPNs
  where (LocationId = @vLocationId) and (LPNType = 'L') and (Status <> 'I');

  /* Validate Location */
  if (@vLocationId is null)
    set @vMessageName = 'LocationDoesNotExist';
  else
  if (@vLocationType <> 'K')
    set @vMessageName = 'LocationIsNotAPicklane';
  else
  /* We should not allow any activity on Inactive locations, but can remove SKUs */
  if (@vLocationStatus = 'I' /* Inactive */) and (@vOperation <> 'RemoveSKU')
    set @vMessageName = 'LocationIsNotActive';
  else
  -- if (@vLocationStatus = 'E' /* Empty */) and (@vOperation = 'TransferPicklane') -- We should be able to transfer an empty picklane
  --   set @vMessageName = 'LocationIsEmpty';
  -- else
  if (@vNumSKUs = 0) and (@vOperation in ('TransferPicklane'))
    set @vMessageName = @vOperation + '_NoSKU'; -- error message would be different for each operation
  else
  /* Check for reserved or directed quantity */
  if (@vDirectedQty > 0) and (@vOperation = 'TransferPicklane')
    set @vMessageName = 'AMF_TransferPicklane_HasDirectedQty';
  else
  if (@vReservedQty > 0) and (@vOperation = 'TransferPicklane')
    set @vMessageName = 'AMF_TransferPicklane_HasReservedQty';

  /* This will raise an exception, and the caller ExecuteAction procedure would
     capture and return error to UI */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get Location Info */
  exec pr_AMF_Info_GetLocationInfoXML @vLocationId, 'LPNList', @vOperation, @vLocationInfoXML output, @vLocationDetailsXML output;

  /* Call the proc to validate and get all possible options */
  if (@vOperation = 'ManagePicklane')
    exec pr_Inventory_ManagePicklane_GetValidOptions @vLocationId, @vBusinessUnit, @vDisplayOptions output;

  /* We will give user an option to add inv class while Adding SKU to picklane,
     and it is completely dependent on whether client needed it or not. It is handled
     based on the below control variable */
  select @vInvClass = dbo.fn_Controls_GetAsString(@vOperation, 'InventoryClasses', '' /* default */, @vBusinessUnit, @vUserId);

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', @vLocationInfoXML + @vLocationDetailsXML +
                                           coalesce(@vDisplayOptions, '') +
                                           dbo.fn_XMLNode('InventoryClasses', @vInvClass));
end /* pr_AMF_Inventory_ValidatePicklane */

Go

