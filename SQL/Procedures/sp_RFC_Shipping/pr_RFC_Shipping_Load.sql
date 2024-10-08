/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/07  PHK     pr_RFC_Shipping_Load: Changes to insert OrderType in #LPNsToLoad (HA-1941)
  2021/04/26  RIA     pr_RFC_Shipping_Load: Changes to consider the operation (HA-2675)
  2021/02/16  AY/MS   pr_RFC_Shipping_Load, pr_RFC_Shipping_UnLoad: Renamed Status to LPNStatus (HA-2002)
  2020/07/21  RKC     pr_RFC_Shipping_Load: Changes to pass the Scanned DockLocation to pr_Loading_ValidateLoadPalletOrLPN (HA-1073)
  2020/06/30  TK      pr_RFC_Shipping_Load: Changes to load LPNs that are not associated to any order (HA-830)
  2020/01/24  RIA     pr_RFC_Shipping_Load, pr_RFC_Shipping_UnLoad : Included AuditTrail (CIMSV3-689)
  2020/01/21  TK      pr_RFC_Shipping_Load: Code Revamp
  2019/05/06  YJ      pr_RFC_Shipping_Load: Get the LPNs with Temp Status Migrated from Prod (S2GCA-98)
  2018/12/14  RIA     pr_RFC_Shipping_Load & pr_RFC_Shipping_ValidateLoad (S2GCA-396)
  2018/11/13  RIA     pr_RFC_Shipping_Load: Added Markers to track the log in order to identify the root cause (S2GCA-396)
  2018/09/19  TK      pr_RFC_Shipping_Load: Find shipment matching the ship to of Order (S2GCA-272)
  2018/08/07  TK      pr_RFC_Shipping_Load & pr_RFC_Shipping_UnLoad: Fixed several issues related to Loading (S2GCA-117 & S2GCA-118)
  2018/06/09  YJ      pr_RFC_Shipping_Load: Excluded LoadTypes 'FEDEX', 'UPS', 'USPS', 'DHL' if Load has different shipments: Migrated from onsite staging (S2G-727)
  2018/05/26: RV      pr_RFC_Shipping_Load : Included changes to consider LoadType : Migrated from onsite staging (S2G-727)
  2013/10/29  PK      pr_RFC_Shipping_Load: Added Validation.
  2013/10/18  PK      pr_RFC_Shipping_Load: Updating LPN and Pallet with the load info.
  2013/10/11  PK      Added pr_RFC_Shipping_Load, pr_RFC_Shipping_UnLoad.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Shipping_Load') is not null
  drop Procedure pr_RFC_Shipping_Load;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Shipping_Load:

  Input:
  <ConfirmLoad>
    <Load>LD130912001</Load>
    <ShipTo>1114</ShipTo>
    <ScanLPNOrPallet></ScanLPNOrPallet>
    <BusinessUnit></BusinessUnit>
    <UserId></UserId>
    <DeviceId></DeviceId>
  </ConfirmLoad>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Shipping_Load
  (@xmlInput   xml,
   @xmlResult  xml output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage               TMessage,

          @vLoadId                TRecordId,
          @vLoadNumber            TLoadNumber,
          @vLoadType              TTypeCode,
          @vLoadDockLocation      TLocation,
          @vLoadStatus            TStatus,
          @vLoadShipToId          TShipToId,

          @vLPNOrPallet           TLPN,
          @vLPNId                 TRecordId,
          @vLPN                   TLPN,
          @vPalletId              TRecordId,
          @vPallet                TPallet,

          @vEntityId              TRecordId,
          @vShipToId              TShipToId,
          @vScannedDockLocation   TLocation,
          @vBusinessUnit          TBusinessUnit,
          @vDeviceId              TDeviceId,
          @vUserId                TUserId,
          @vOperation             TOperation,

          @vDebug                 TFlags,
          @vActivityLogId         TRecordId;

  declare @ttLPNsToLoad           TLPNsToLoad,
          @ttMarkers              TMarkers;
begin /* pr_RFC_Shipping_Load */
begin try
  SET NOCOUNT ON;

  /* Get the Input params */
  select @vBusinessUnit         = Record.Col.value('BusinessUnit[1]',     'TBusinessUnit'),
         @vUserId               = Record.Col.value('UserId[1]',           'TUserId'      ),
         @vDeviceId             = Record.Col.value('DeviceId[1]',         'TDeviceId'    ),
         @vLoadNumber           = Record.Col.value('Load[1]',             'TLoadNumber'  ),
         @vShipToId             = Record.Col.value('ShipTo[1]',           'TShipToId'    ),
         @vLPNOrPallet          = Record.Col.value('ScanLPNOrPallet[1]',  'TLPN'         ),
         @vScannedDockLocation  = Record.Col.value('Dock[1]',             'TLocation'    ),
         @vOperation            = Record.Col.value('Operation[1]',        'TOperation'   )
  from @xmlInput.nodes('/ConfirmLoad') as Record(Col);

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @vBusinessUnit, @vDebug output;

  /* Create required hash tables if they does not exist */
  if (object_id('tempdb..#Markers') is null) select * into #Markers from @ttMarkers;
  if (object_id('tempdb..#LPNsToLoad') is null) select * into #LPNsToLoad from @ttLPNsToLoad;

  /* Marker */ if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Get_XMLParams', @@ProcId;

  /* Add to RF Log */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      null, @vLPNOrPallet, 'LPN/Pallet', @Value1 = @vLoadNumber,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get the Load Info */
  select @vLoadId           = LoadId,
         @vLoadNumber       = LoadNumber,
         @vLoadType         = LoadType,
         @vLoadDockLocation = DockLocation,
         @vLoadStatus       = Status,
         @vLoadShipToId     = ShipToId
  from Loads
  where (LoadNumber   = @vLoadNumber) and
        (BusinessUnit = @vBusinessUnit);

  /* Check whether the user scanned LPN or Pallet */
  if (@vLPNOrPallet is not null)
    select @vLPNId    = LPNId,
           @vLPN      = LPN,
           @vEntityId = LPNId
    from LPNs
    where (LPNId = dbo.fn_LPNs_GetScannedLPN(@vLPNOrPallet, @vBusinessUnit, default));

  /* If LPN is null then assuming that User has scanned Pallet */
  if (@vLPNId is null)
    select @vPalletId = PalletId,
           @vPallet   = Pallet,
           @vEntityId = PalletId
    from Pallets
    where (Pallet       = @vLPNOrPallet) and
          (BusinessUnit = @vBusinessUnit);

  /* Marker */ if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'After Get Info', @@ProcId;

  /* Insert the LPNs into a temp table */
  if (@vLPNId is not null)
    insert into #LPNsToLoad (LPNId, LPN, LPNStatus, OrderId, WaveId, WaveNo, ShipToId, LoadId, ShipmentId, OrderType)
      select L.LPNId, L.LPN, L.Status, L.OrderId, L.PickBatchId, L.PickBatchNo, coalesce(OH.ShipToId, @vLoadShipToId), L.LoadId, L.ShipmentId, OH.OrderType
      from LPNs L left outer join OrderHeaders OH on (L.OrderId = OH.OrderId)
      where (L.LPNId = @vLPNId) and (L.Status <> 'S' /* Shipped */);
  else
  if (@vPalletId is not null)
    insert into #LPNsToLoad (LPNId, LPN, LPNStatus, OrderId, WaveId, WaveNo, ShipToId, LoadId, ShipmentId, OrderType)
      select L.LPNId, L.LPN, L.Status, L.OrderId, L.PickBatchId, L.PickBatchNo, coalesce(OH.ShipToId, @vLoadShipToId), L.LoadId, L.ShipmentId, OH.OrderType
      from LPNs L left outer join OrderHeaders OH on (L.OrderId = OH.OrderId)
      where (L.PalletId = @vPalletId) and (L.Status <> 'S' /* Shipped */);

  /* Marker */ if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'After building #ttLPNs', @@ProcId;

  /* Validate scanned pallet/LPN can be added to load or not */
  exec pr_Loading_ValidateLoadPalletOrLPN @vLoadId, @vPalletId, @vLPNId, @vScannedDockLocation, @vOperation, @vBusinessUnit, @vUserId, @vMessage output;

  /* Marker */ if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Validations', @@ProcId;

  if (@vMessage is not null)
    goto ErrorHandler;

  /* Load Pallet or LPN */
  exec pr_Loading_LoadPalletOrLPN @vLoadId, @vPalletId, @vLPNId, @vOperation, @vBusinessUnit, @vUserId;

  /* Marker */ if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'LPNs Loaded', @@ProcId;

  /* Get the Load Details of scanned Load */
  exec @xmlResult = pr_Loading_GetLoadInfo @vLoadId, @xmlResult output;

  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log default, 'Load', @vLoadId, @vLoadNumber, 'Shipping_Load', @@ProcId, 'Markers_Shipping_Load';

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vEntityId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vEntityId, @ActivityLogId = @vActivityLogId output;

end catch;
end /* pr_RFC_Shipping_Load */

Go
