/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/27  RIA     pr_AMF_Picking_ShipCartonActivation_Validate, pr_AMF_Picking_ShipCartonActivation_Confirm Changes to promptpallet (BK-541)
  2021/05/20  TK      pr_AMF_Picking_ShipCartonActivation_Validate: Validate UCCBarcode (HA-2816)
  2020/12/29  AY/RIA  pr_AMF_Picking_ShipCartonActivation_Validate: Allow Packed Pallets
  2020/06/15  SK      pr_AMF_Picking_ShipCartonActivation_Validate: Fixes to pass in values to populate error messages.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_ShipCartonActivation_Validate') is not null
  drop Procedure pr_AMF_Picking_ShipCartonActivation_Validate;
Go
/*------------------------------------------------------------------------------
  Proc pr_AMF_Picking_ShipCartonActivation_Validate:

  Procedure to validate Ship carton LPN that is scan
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_ShipCartonActivation_Validate
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  declare @vReturnCode                TInteger,
          @vMessage                   TMessage,
          @vMessageName               TMessageName,
          @vValue1                    TDescription,
          @vRecordId                  TRecordId,
          @vxmlInput                  xml,
          @vxmlOutput                 xml,
          @vxmlRFCProcInput           xml,
          @vxmlRFCProcOutput          xml,
          @vTempXML                   TXML,
          /* Input variables */
          @vBusinessUnit              TBusinessUnit,
          @vUserId                    TUserId,
          @vDeviceId                  TDeviceId,
          @vOperation                 TOperation,
          @vScannedPallet             TPallet,
          @vScannedLocation           TLocation;
          /* Functional variables */
  declare @vDeviceName                TName,
          @vUserLoggedInWH            TWarehouse,
          @vScannedLPN                TLPN,
          /* LPN Info */
          @vToLPNId                   TRecordId,
          @vToLPN                     TLPN,
          @vToLPNType                 TTypeCode,
          @vToLPNStatus               TStatus,
          @vToLPNPalletId             TRecordId,
          @vToLPNInvalidStatus        TControlValue,
          @vToLPNValidTypes           TControlValue,
          @vToLPNActivatedStatuses    TControlValue,
          @vToLPNStatusDesc           TDescription,
          @vToLPNWarehouse            TWarehouse,
          @vToLPNUCCBarcode           TBarcode,
          @vToLPNInfoXML              TXML,
          @vToLPNDetailsXML           TXML,
          /* Order Info */
          @vOrderId                   TRecordId,
          @vOrderInfoXML              TXML,
          /* Wave Info */
          @vWaveId                    TRecordId,
          @vWaveType                  TTypeCode,
          @vWaveInfoXML               TXML,
          @vAutoConfirmWavetypes      TControlValue,
          /* Pallet Info */
          @vPalletId                  TRecordId,
          @vPallet                    TPallet,
          @vPalletType                TTypeCode,
          @vPalletStatus              TStatus,
          @vPalletInfoXML             TXML,
          @vInvalidPalletTypes        TControlValue,
          @vInvalidPalletStatus       TControlValue,
          @vValidPalletStatuses       TControlValue,
          /* Location Info */
          @vLocationId                TRecordId,
          @vLocation                  TLocation,
          @vLocationType              TTypeCode,
          @vLocationStatus            TStatus,
          @vLocationInfoXML           TXML,
          @vInvalidLocationTypes      TControlValue,
          @vInvalidLocationStatus     TControlValue,
          @vPromptPallet              TFlags;
begin /* pr_AMF_Picking_ShipCartonActivation_Validate */
  select  @vRecordId    = 0,
          @vReturnCode  = 0,
          @vMessageName = null,
          @vValue1      = null;

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML             = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML           = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML            = null,
         @InfoXML             = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit     = Record.Col.value('(SessionInfo/BusinessUnit)[1]',     'TBusinessUnit'),
         @vUserId           = Record.Col.value('(SessionInfo/UserName)[1]',         'TUserId'      ),
         @vDeviceId         = Record.Col.value('(SessionInfo/DeviceId)[1]',         'TDeviceId'    ),
         @vOperation        = Record.Col.value('(Data/Operation)[1]',               'TOperation'   ),
         @vScannedLPN       = Record.Col.value('(Data/LPN)[1]',                     'TLPN'         ),
         @vScannedPallet    = Record.Col.value('(Data/Pallet)[1]',                  'TPallet'      ),
         @vScannedLocation  = Record.Col.value('(Data/Location)[1]',                'TLocation'    )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* set value for DeviceName to replace current data set to Devices table */
  select @vDeviceName = @vDeviceId + '@' + @vUserId;

  /* Get the user logged in Warehouse */
  select @vUserLoggedInWH = dbo.fn_Users_LoggedInWarehouse(@vDeviceId, @vUserId, @vBusinessUnit);

  /* Fetch details related of the Ship carton LPN scanned */
  select @vToLPNId         = L.LPNId,
         @vToLPN           = L.LPN,
         @vToLPNType       = L.LPNType,
         @vToLPNStatus     = L.Status,
         @vToLPNStatusDesc = dbo.fn_Status_GetDescription('LPN', L.Status, @vBusinessUnit),
         @vToLPNPalletId   = L.PalletId,
         @vToLPNWarehouse  = L.DestWarehouse,
         @vOrderId         = L.OrderId,
         @vWaveId          = L.PickBatchId,
         @vToLPNUCCBarcode = L.UCCBarcode
  from LPNs L
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@vScannedLPN, @vBusinessUnit, default));

  /* Fetch Wave details */
  select @vWaveType = WaveType
  from Waves
  where (WaveId = @vWaveId);

  /* Fetch pallet details */
  if (coalesce(@vScannedPallet, '') <> '')
    select @vPalletId     = PalletId,
           @vPallet       = Pallet,
           @vPalletType   = PalletType,
           @vPalletStatus = Status
    from Pallets
    where PalletId = dbo.fn_Pallets_GetPalletId(@vScannedPallet, @vBusinessUnit);

  /* Get Location Info */
  if (coalesce(@vScannedLocation, '') <> '')
    select @vLocationId     = LocationId,
           @vLocation       = Location,
           @vLocationType   = LocationType,
           @vLocationStatus = Status
    from Locations
    where LocationId = dbo.fn_Pallets_GetLocationId(null, @vScannedLocation, @vDeviceId, @vUserId, @vBusinessUnit);

  /* Get control values */
  select  @vToLPNInvalidStatus     = dbo.fn_Controls_GetAsString('LPNShipCartonActivate', 'InvalidToLPNStatuses', 'C,V,O,S,L,I' /* default: consumed/void/lost/shipped/loaded/inactive */,
                                                                 @vBusinessUnit, @vUserId),
          @vToLPNValidTypes        = dbo.fn_Controls_GetAsString('LPNShipCartonActivate', 'ValidToLPNTypes', 'S' /* default: shipcarton */,
                                                                 @vBusinessUnit, @vUserId),
          @vToLPNActivatedStatuses = dbo.fn_Controls_GetAsString('LPNShipCartonActivate', 'ActivatedToLPNStatus', 'K,D,E,L' /* default: picked, packed, loaded, staged */,
                                                                 @vBusinessUnit, @vUserId),
          @vInvalidLocationTypes   = dbo.fn_Controls_GetAsString('LPNShipCartonActivate', 'InvalidLocationTypes', 'C' /* default: conveyor */,
                                                                 @vBusinessUnit, @vUserId),
          @vInvalidLocationStatus  = dbo.fn_Controls_GetAsString('LPNShipCartonActivate', 'InvalidLocationStatus', 'I,E,D,N' /* default: Inactive/Empty/Deleted/NA */,
                                                                 @vBusinessUnit, @vUserId),
          @vInvalidPalletTypes     = dbo.fn_Controls_GetAsString('LPNShipCartonActivate', 'InvalidPalletType', 'C,T,U' /* default: PickingCart/Trolley/PutawayPallet */,
                                                                 @vBusinessUnit, @vUserId),
          @vInvalidPalletStatus    = dbo.fn_Controls_GetAsString('LPNShipCartonActivate', 'InvalidPalletStatus', 'V,O,S' /* default: Voided/Lost/Shipped */,
                                                                 @vBusinessUnit, @vUserId),
          @vValidPalletStatuses    = dbo.fn_Controls_GetAsString('LPNShipCartonActivate', 'ValidPalletStatus', 'D,SG' /* default: Packed/Staged */,
                                                                 @vBusinessUnit, @vUserId),
          @vAutoConfirmWavetypes   = dbo.fn_Controls_GetAsString('LPNShipCartonActivate', 'AutoConfirmWaves', 'CP,BCP' /* default: CasePick/BulkCasePick */,
                                                                 @vBusinessUnit, @vUserId);

  /* Validations */
  if (@vToLPNId is null)
    set @vMessageName = 'LPNActv_ShipCartons_InvalidLPN';
  else
  if (@vUserLoggedInWH is not null) and (@vUserLoggedInWH <> @vToLPNWarehouse)
    set @vMessageName = 'LPNActv_ShipCartons_WarehouseMismatch'
  else
  if (dbo.fn_IsInList(@vToLPNType, @vToLPNValidTypes) = 0)
    set @vMessageName = 'LPNActv_ShipCartons_InvalidLPNType';
  else
  if (dbo.fn_IsInList(@vToLPNStatus, @vToLPNActivatedStatuses) > 0) and (coalesce(@vPalletId, 0) = coalesce(@vToLPNPalletId, 0))
    begin
      select @vMessageName = 'LPNActv_ShipCartons_LPNActivated',
             @vValue1      = @vToLPNStatusDesc;
    end
  else
  if (dbo.fn_IsInList(@vToLPNStatus, @vToLPNInvalidStatus) > 0)
    begin
      select @vMessageName = 'LPNActv_ShipCartons_InvalidLPNStatus',
             @vValue1      = @vToLPNStatusDesc;
    end
  else
  if (@vOrderId is null)
    set @vMessageName = 'LPNActv_ShipCartons_InvalidOrder';
  else
  if (dbo.fn_IsInList(@vLocationType, @vInvalidLocationTypes) > 0)
    begin
      select @vMessageName = 'LPNActv_ShipCartons_InvalidLocationType',
             @vValue1      = dbo.fn_Status_GetDescription('Location', @vLocationType, @vBusinessUnit);
    end
  else
  if (dbo.fn_IsInList(@vLocationStatus, @vInvalidLocationStatus) > 0)
    begin
      select @vMessageName = 'LPNActv_ShipCartons_InvalidLocationStatus',
             @vValue1      = dbo.fn_Status_GetDescription('Location', @vLocationStatus, @vBusinessUnit);
    end
  else
  if ((coalesce(@vScannedPallet, '') <> '') and (@vPalletId is null))
    set @vMessageName = 'LPNActv_ShipCartons_InvalidPallet';
  else
  if (dbo.fn_IsInList(@vPalletType, @vInvalidPalletTypes) > 0)
    begin
      select @vMessageName = 'LPNActv_ShipCartons_InvalidPalletType',
             @vValue1      = dbo.fn_Status_GetDescription('Pallet', @vPalletType, @vBusinessUnit);
    end
  else
  if (dbo.fn_IsInList(@vPalletStatus, @vInvalidPalletStatus) > 0) or
     (dbo.fn_IsInList(@vPalletStatus, @vValidPalletStatuses) = 0)
    begin
      select @vMessageName = 'LPNActv_ShipCartons_InvalidPalletStatus',
             @vValue1      = dbo.fn_Status_GetDescription('Pallet', @vPalletStatus, @vBusinessUnit);
    end

  /* Raise error if validation fails. However, send the valid Pallet/Location the
     user scanned (if they were in fact valid) so that the user does not have to scan them again */
  if (@vMessageName is not null)
    begin
      /* output Params */
      select @DataXML = dbo.fn_XMLNode('Data',
                          dbo.fn_XMLNode('LocationInfo_Location', @vLocation) +
                          dbo.fn_XMLNode('PalletInfo_Pallet',     @vPallet));

      /* Save Pallet & Location info before exiting */
      update Devices
      set DataXML = @DataXml
      where (DeviceId = @vDeviceName);

      exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vValue1;
    end

  /* Get LPN Info */
  exec pr_AMF_Info_GetLPNInfoXML @vToLPNId, 'LPNDetails' /* LPN Details */, 'ShipCartonActivation',
                                 @vToLPNInfoXML output, @vToLPNDetailsXML output;

  /* Get LPN Info */
  exec pr_AMF_Info_GetOrderInfoXML @vOrderId, 'N' /* No Details */, 'ShipCartonActivation', @vOrderInfoXML output;

  /* Get Pallet Info */
  if (@vPalletId is not null)
    exec pr_AMF_Info_GetPalletInfoXML @vPalletId, 'N' /* No Details */, 'ShipCartonActivation', @vPalletInfoXML output;

  /* Get Location Info */
  if (@vLocationId is not null)
    exec pr_AMF_Info_GetLocationInfoXML @vLocationId, 'N' /* No Details */, 'ShipCartonActivation', @vLocationInfoXML output;
  /* Get the control to prompt pallet input for user */
  select @vPromptPallet = dbo.fn_Controls_GetAsBoolean('LPNShipCartonActivate', 'PromptPallet', 'Y' /* Yes */, @vBusinessUnit, @vUserId)

  /* Build the DataXML, send the scanned LPN so it can be auto confirmed */
  select @DataXml = dbo.fn_XMLNode('Data', coalesce(@vToLPNInfoXML,       '') +
                                           coalesce(@vToLPNDetailsXML,    '') +
                                           coalesce(@vOrderInfoXML,       '') +
                                           coalesce(@vPalletInfoXML,      '') +
                                           coalesce(@vLocationInfoXML,    '') +
                                           dbo.fn_XMLNode('LPN',          @vToLPN) +
                                           dbo.fn_XMLNode('PromptPallet', @vPromptPallet));

  /* Flag to proceed to confirm skipping user interaction */
  if (dbo.fn_IsInList(@vWaveType, @vAutoConfirmWavetypes) > 0)
    select @DataXML = dbo.fn_XMLAddNode(@DataXML, 'Data', dbo.fn_XMLNode('AutoConfirm', 'Y'));
end /* pr_AMF_Picking_ShipCartonActivation_Validate */

Go

