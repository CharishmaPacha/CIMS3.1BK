/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/14  RIA     pr_AMF_Inventory_AdjustQty, pr_AMF_Inventory_ValidateEntity: Changes to build data (HA-2938)
  2021/04/05  TK      pr_AMF_Inventory_ValidateEntity: Picklane may have multiple LPNs so validate based upon entity scanned (HA-2542)
  2020/05/07  RIA     pr_AMF_Inventory_ValidateEntity: Changes to validate when there is no Logical LPNs (OB2-1119)
  2019/11/11  RIA     pr_AMF_Inventory_ValidateEntity: Changes and clean up (CIMSV3-632)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_ValidateEntity') is not null
  drop Procedure pr_AMF_Inventory_ValidateEntity;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_ValidateEntity: In some of the RF operations, we
   allow user to input an LPN or Location. This procedure evaluates what the user
   has input and validates it accordingly.

  Operation: Example - AdjustQty. However the V2 validate functions expect it to
   be AdjustLPNQty or AdjustLocationQty and hence we also have two other parms
   LPNoperation and LocationOperation to be used for V2 validation proc
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_ValidateEntity
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TDescription,
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
          @vEntity                   TEntity,
          @vLPNOperation             TOperation,
          @vLocationOperation        TOperation,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vReasonCodeCategory       TCategory,
          @vReasonCodesXML           Txml,
          @vEntityType               TTypeCode,
          @vValidateOperation        TOperation,
          /* LPN */
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vLPNType                  TTypeCode,
          @vLPNQuantity              TQuantity,
          @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML,
          @vxmlLPNInfo               xml,
          /* Location */
          @vLocation                 TLocation,
          @vLocationId               TRecordId,
          @vLocationType             TTypeCode,
          @vLocationQty              TQuantity,
          @vLocationInfoXML          TXML,
          @vLocationDetailsXML       TXML;
begin /* pr_AMF_Inventory_ValidateEntity */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit      = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId            = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId          = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vEntity            = Record.Col.value('(Data/Entity)[1]',                     'TEntity'      ),
         @vLPNOperation      = Record.Col.value('(Data/LPNOperation)[1]',               'TOperation'   ),
         @vLocationOperation = Record.Col.value('(Data/LocationOperation)[1]',          'TOperation'   ),
         @vOperation         = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Identify the Entity */
  exec pr_LPNs_IdentifyLPNOrLocation @vEntity, @vBusinessUnit, @vUserId,
                                     @vEntityType out, @vLPNId out, @vLPN out,
                                     @vLocationId out, @vLocation out;

  /* Get Location Info */
  select @vLocationId   = LocationId,
         @vLocation     = Location,
         @vLocationType = LocationType,
         @vLocationQty  = Quantity
  from Locations
  where (LocationId = @vLocationId);

  /* Get LPN Info - for Picklane, we get the Logical LPN */
  /* This is not true, we may have multiple SKUs in a picklane which will intrun have multiple LPNs */
  --if (@vLocationId is not null) and (@vLocationType = 'K')
  --  select @vLPNId       = LPNId,
  --         @vLPN         = LPN,
  --         @vLPNQuantity = Quantity,
  --         @vLPNType     = LPNType
  --  from LPNs
  --  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@vLocation, @vBusinessUnit, 'LTU'))  -- This will not work, GetScannedLPN will identify LPN matching with @vLocation only when length of the @vLocation is either 10 or 5
  --else

  /* Get LPN Info */
  if (@vEntityType = 'LPN')
    select @vLPNQuantity = Quantity,
           @vLPNType     = LPNType
    from LPNs
    where (LPNId = @vLPNId);

  -- If user scanned Location, we cannot determine the Logical LPN with just that at this stage.

  /* Validate Location/LPN */
  if ((@vLPNId is null) and (@vLocationId is null))
    set @vMessageName = 'LPNOrLocationDoesNotExist';
  else
  /* For Transfer/Xfer Inventory FromLocation/LPN cannot be zero */
  if (@vLocationId is not null) and (@vLocationType <> 'K' /* Picklane */) and (@vOperation = 'TransferInventory')
    set @vMessageName = 'CannotTransferFromNonPicklaneLoc';
  else
  if (@vEntityType = 'LPN') and (@vLPNQuantity = 0) and (@vOperation not in ('AdjustQty'))
    set @vMessageName = 'AMF_Transfer_LPNQtyIsZero';
  else
  if (@vEntityType = 'LOC') and (@vLocationQty = 0) and (@vOperation not in ('AdjustQty'))
    set @vMessageName = 'AMF_Transfer_LocationIsEmpty';

  /* This will raise an exception, and the caller ExecuteAction procedure would
     capture and return error to UI */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If user scanned a valid location */
  if (@vEntityType = 'LOC')
    begin
      /* We are doing this for AdjustQty as the validate proc expects AdjustLocation as Operation */
      select @vValidateOperation = case when @vOperation = 'AdjustQty'
                                        then @vLocationOperation else @vOperation end;

      select @vrfcProcInputxml = (select @vDeviceId           as DeviceId,
                                         @vUserId             as UserId,
                                         @vBusinessUnit       as BusinessUnit,
                                         @vLocationId         as LocationId,
                                         @vLocation           as Location,
                                         @vValidateOperation  as Operation
                                  for xml raw('ValidateLocation'), elements);

      exec pr_RFC_ValidateLocation @vrfcProcInputxml;

      /* If we are adjusting Location Quantity, then show the available qty and reserved qty */
      if (@vOperation in ('AdjustQty', 'TransferInventory'))
        exec pr_AMF_Info_GetLocationInfoXML @vLocationId, 'SKUOnhand', @vLocationOperation,
                                            @vLocationInfoXML output, @vLocationDetailsXML output;
      else
        exec pr_AMF_Info_GetLocationInfoXML @vLocationId, 'SKUDETAILS', @vLocationOperation,
                                            @vLocationInfoXML output, @vLocationDetailsXML output;
    end
  else
  /* Validate LPN to make sure it can be moved, adjusted or whatsoever */
  if (@vEntityType = 'LPN')
    begin
      /* We are doing this for AdjustQty as the validate proc expects AdjustLPN as Operation */
      select @vValidateOperation = case when @vOperation = 'AdjustQty'
                                        then @vLPNOperation else @vOperation end;

      exec pr_RFC_ValidateLPN @vLPNId, @vLPN, @vValidateOperation, @vBusinessUnit, @vUserId;

      /* If we are Transferring LPN Quantity, then show the available qty and reserved qty */
      if (@vOperation in ('AdjustQty', 'TransferInventory'))
        exec pr_AMF_Info_GetLPNInfoXML @vLPNId, 'SKUOnhand' /* LPNDETAILS */, @vLPNOperation,
                                            @vLPNInfoXML output, @vLPNDetailsXML output;
      else
        exec pr_AMF_Info_GetLPNInfoXML @vLPNId, 'LPNDetails' /* LPNDETAILS */, @vLPNOperation,
                                            @vLPNInfoXML output, @vLPNDetailsXML output;
    end

  /* get the Reason codes for as we need them for AdjustLPN/Location */
  select @vReasonCodeCategory = case when (@vOperation = 'AdjustQty') and (@vLocationId is not null) then 'RC_LocAdjust'
                                     when (@vOperation = 'AdjustQty') then 'RC_LPNAdjust'
                                     when (@vOperation = 'TransferInventory') then 'RC_TransferInv'
                                end;

  /* Fetch the reason codes */
  exec pr_AMF_BuildLookUpList @vReasonCodeCategory, 'ReasonCodes', 'select a reason', @vBusinessunit, @vReasonCodesXML output;

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', coalesce(@vLPNInfoXML, @vLocationInfoXML, '') +
                                           coalesce(@vLPNDetailsXML, @vLocationDetailsXML, '') +
                                           coalesce(@vReasonCodesXML, '') +
                                           dbo.fn_XMLNode('EntityType', @vEntityType) +
                                           dbo.fn_XMLNode('LPNType', @vLPNType));

end /* pr_AMF_Inventory_ValidateEntity */

Go

