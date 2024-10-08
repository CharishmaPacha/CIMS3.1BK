/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/27  RIA     pr_AMF_Picking_ShipCartonActivation_Validate, pr_AMF_Picking_ShipCartonActivation_Confirm Changes to promptpallet (BK-541)
  2021/03/20  TK      pr_AMF_Picking_ShipCartonActivation_Confirm: Bug fix to compute allocable quantity (HA-2661)
  2021/02/26  AY      pr_AMF_Picking_ShipCartonActivation_Confirm: Reorganized error message to be more appropriate
  2021/01/19  TK      pr_AMF_Picking_ShipCartonActivation_Confirm: Use Key value to identify LPNs (HA-1918)
  pr_AMF_Picking_ShipCartonActivation_Confirm: Included LPNAutoConfirmed (HA-1790)
  2020/06/01  SK      pr_AMF_Picking_ShipCartonActivation_Confirm: change to consider FromLPNs with no orderid (HA-753)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_ShipCartonActivation_Confirm') is not null
  drop Procedure pr_AMF_Picking_ShipCartonActivation_Confirm;
Go
/*------------------------------------------------------------------------------
  Proc pr_AMF_Picking_ShipCartonActivation_Confirm:

  Procedure to confirm Ship cartons generated during wave release or allocation
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_ShipCartonActivation_Confirm
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vMessage                   TMessage,
          @vValue1                    TDescription,
          @vValue2                    TDescription,
          @vResult                    TVarChar,
          @vRecordId                  TRecordId,
          @vxmlInput                  xml,
          @vxmlOutput                 xml,
          @vxmlRFCProcInput           xml,
          @vxmlRFCProcOutput          xml,
          /* Input variables */
          @vBusinessUnit              TBusinessUnit,
          @vUserId                    TUserId,
          @vDeviceId                  TDeviceId,
          @vLocation                  TLocation,
          @vOperation                 TOperation,
          @vAutoConfirm               TFlags;
          /* Functional variables */
  declare @vDeviceName                TName,
          @vPrevDataXML               TXML,
          @vInvalidLocationTypes      TControlValue,
          @vSortOrder                 TSortOrder,
          @vPromptPallet              TFlags,
          /* To LPN */
          @vScannedLPN                TLPN,
          @vToLPNId                   TRecordId,
          @vToLPNStatus               TStatus,
          @vToLPNStatusDesc           TDescription,
          @vToLPNOnhandStatus         TStatus,
          @vToLPNWarehouse            TWarehouse,
          @vToLPNType                 TTypeCode,
          @vToLPNPalletId             TRecordId,
          @vToLPNDetailsCount         TCount,
          @vToLPNDetailsTotQty        TQuantity,
          @vInvalidToLPNStatus        TControlValue,
          /* To & From LPN Wave, Order Info */
          @vWaveId                    TRecordId,
          @vWaveNo                    TPickBatchNo,
          @vWaveType                  TTypeCode,
          @vBulkOrderId               TRecordId,
          /* Pallet */
          @vScannedPalletId           TRecordId,
          @vScannedPallet             TPallet,
          @vPalletId                  TRecordId,
          @vPallet                    TPallet,
          @vPalletLocationId          TRecordId,
          /* Location */
          @vScannedLocation           TLocation,
          @vLocationId                TRecordId,
          @vLocationType              TTypeCode,
          /* From LPN */
          @vFromLPNId                 TRecordId,
          @vFromLPNDetailsCount       TCount,
          @vFromLPNDetailsTotQty      TQuantity,
          /* XMLs */
          @vProcInputXML              TXML,
          @vSQLToExecute              TSQL,
          /* Temporary table */
          @ttLPNDetails               TLPNDetails,
          @ttWavesList                TEntityKeysTable;
begin /* pr_AMF_Picking_ShipCartonActivation_Confirm */
  select  @vRecordId      = 0,
          @vReturnCode    = 0,
          @vMessageName   = null,
          @vMessage       = null,
          @vResult        = null,
          @vValue1        = null,
          @vValue2        = null,
          @vSQLToExecute  = null;

  /* Hash tables to store Ship Carton (ToLPN) details, From LPN Details */
  select * into #ToLPNDetails   from @ttLPNDetails;
  alter table #ToLPNDetails add KeyValue as cast(SKUId as varchar) + '-' + Warehouse + '-' + Ownership + '-' +
                                            InventoryClass1 + '-' + InventoryClass2 + '-' + InventoryClass3;
  select * into #FromLPNDetails from @ttLPNDetails;
  alter table #FromLPNDetails drop column AllocableQty;
  alter table #FromLPNDetails add AllocableQty as Quantity - coalesce(ReservedQty, 0);
  alter table #FromLPNDetails add KeyValue as cast(SKUId as varchar) + '-' + Warehouse + '-' + Ownership + '-' +
                                              InventoryClass1 + '-' + InventoryClass2 + '-' + InventoryClass3;

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read inputs from InputXML */
  select @vBusinessUnit     = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId           = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'),
         @vDeviceId         = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'),
         @vOperation        = Record.Col.value('(Data/Operation)[1]',                  'TOperation'),
         /* LPN Info */
         @vScannedLPN       = Record.Col.value('(Data/LPN)[1]',                        'TLPN'),
         @vToLPNId          = Record.Col.value('(Data/LPNId)[1]',                      'TRecordId'),
         /* Pallet Info */
         @vScannedPallet    = Record.Col.value('(Data/Pallet)[1]',                     'TPallet'),
         @vPalletId         = Record.Col.value('(Data/m_PalletInfo_PalletId)[1]',      'TRecordId'),
         /* Location Info */
         @vScannedLocation  = Record.Col.value('(Data/Location)[1]',                   'TLocation'),
         @vLocationId       = Record.Col.value('(Data/m_LocationInfo_LocationId)[1]',  'TRecordId'),
         /* Auto Confirm */
         @vAutoConfirm      = Record.Col.value('(Data/m_AutoConfirm)[1]',              'TFlags')
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* set value for DeviceName to replace current data set to Devices table */
  select @vDeviceName = @vDeviceId + '@' + @vUserId;

  /* Reset - useful in the event of exceptions */
  select @vPrevDataXML = DataXML from devices where (DeviceId = @vDeviceName);
  select @vPrevDataXML = dbo.fn_XMLStuffValue(@vPrevDataXML, 'AutoConfirm',           ''); /* reset */
  select @vPrevDataXML = dbo.fn_XMLStuffValue(@vPrevDataXML, 'LPN',                   ''); /* reset */

  update Devices
  set DataXML =  @vPrevDataXML
  where (DeviceId = @vDeviceName);

  /* Get controls */
  select @vInvalidToLPNStatus   = dbo.fn_Controls_GetAsString('LPNShipCartonActivate', 'InvalidToLPNStatuses', 'C,V,O,S,L,I' /* default: consumed/void/lost/shipped/loaded/inactive */,
                                                              @vBusinessUnit, @vUserId);

  /* Identify To LPN if needed */
  if (@vToLPNId is null) select @vToLPNId = dbo.fn_LPNs_GetScannedLPN(@vScannedLPN, @vBusinessUnit, default);

  /* Get LPN Info */
  select  @vToLPNId           = LPNId,
          @vToLPNStatus       = Status,
          @vToLPNStatusDesc   = dbo.fn_Status_GetDescription('LPN', Status, @vBusinessUnit),
          @vToLPNOnhandStatus = OnhandStatus,
          @vToLPNWarehouse    = DestWarehouse,
          @vToLPNType         = LPNType,
          @vToLPNPalletId     = PalletId,
          @vWaveId            = PickBatchId,
          @vWaveNo            = PickBatchNo
  from LPNs
  where (LPNId = @vToLPNId);

  /* Get Wave Info */
  select @vWaveId   = WaveId,
         @vWaveType = WaveType
  from Waves
  where (WaveNo = @vWaveNo) and (BusinessUnit = @vBusinessUnit);

  /* Find the bulk order associated with the wave */
  select @vBulkOrderId = OrderId
  from OrderHeaders
  where (PickBatchId = @vWaveId) and (OrderType = 'B' /* Bulk Order */);

  /* Populate LPN Info for activation. If the LPN was already activated, then
     this would be empty list */
  insert into #ToLPNDetails(LPNId, LPNDetailId, LPNLines, SKUId, InventoryClass1, InventoryClass2, InventoryClass3,
                            InnerPacks, UnitsPerPackage, Quantity, ReservedQty, Ownership, Warehouse,
                            ReceiptId, ReceiptDetailId, OrderId, OrderDetailId,
                            WaveId, Lot, CoO, ProcessedFlag)
    select LD.LPNId, LD.LPNDetailId, L.NumLines, LD.SKUId, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3,
           LD.InnerPacks, LD.UnitsPerPackage, LD.Quantity, 0 /* ReservedQty */, L.Ownership, L.DestWarehouse,
           LD.ReceiptId, LD.ReceiptDetailId, LD.OrderId, LD.OrderDetailId,
           L.PickBatchId, LD.Lot, LD.CoO, 'N' /* No */
    from LPNDetails LD
      join LPNs L on LD.LPNId = L.LPNId
    where (LD.LPNId = @vToLPNId) and (LD.OnhandStatus = 'U' /* Unavailable */);

  /* Get From LPN Info from the Wave Id associated above
     Assumptions:
      1. LPN Reservation is done againt the Wave
      2. Hence either wave or bulk order id is associated with FromLPNs that are reserved
      3. The quantities may not be exact match and hence the join is based on SKUId only
         Should work for Single-SKU LPNs
         TODO: May need to enhance Multi-SKU Activate code under sp_LPNs.sql */
  insert into #FromLPNDetails (LPNId, LPNDetailId, LPNLines, SKUId, InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                               ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Lot, CoO, Ownership, Warehouse,
                               InventoryClass1, InventoryClass2, InventoryClass3, SortOrder)
    select FLD.LPNId, FLD.LPNDetailId, FL.NumLines, FLD.SKUId, FLD.InnerPacks, FLD.UnitsPerPackage, FLD.Quantity, 0 /* ReservedQty */,
           FLD.ReceiptId, FLD.ReceiptDetailId, FLD.OrderId, FLD.OrderDetailId, FLD.Lot, FLD.CoO, FL.Ownership, FL.DestWarehouse,
           FL.InventoryClass1, FL.InventoryClass2, FL.InventoryClass3, nullif(@vSortOrder, '')
    from LPNs FL
      join LPNDetails FLD on FL.LPNId = FLD.LPNId
      join #ToLPNDetails TLD on (FLD.SKUId          = TLD.SKUId) and
                                (FL.DestWarehouse   = TLD.Warehouse) and
                                (FL.Ownership       = TLD.Ownership) and
                                (FL.InventoryClass1 = TLD.InventoryClass1) and
                                (FL.InventoryClass2 = TLD.InventoryClass2) and
                                (FL.InventoryClass3 = TLD.InventoryClass3)
    where (FL.PickBatchId = @vWaveId) and
          ((coalesce(FL.OrderId, 0) = 0) or (FL.OrderId = @vBulkOrderId)) and
          (FL.LPNType not in ('S' /* Ship cartons */)) and
          (FLD.Quantity > 0)
    order by FLD.Quantity asc;

  /* Get To & From LPNs distinct sku lines & quantities for validation
     For Ship carton to be activated, all of its sku lines & quantity should have been reserved */
  select @vToLPNDetailsCount   = count(distinct SKUId),
         @vToLPNDetailsTotQty  = sum(Quantity)
  from #ToLPNDetails;

  select @vFromLPNDetailsCount  = count(distinct SKUId),
         @vFromLPNDetailsTotQty = sum(Quantity)
  from #FromLPNDetails;

  /* Get waves list to be recounted later */
  insert into @ttWavesList (EntityId, EntityKey) select @vWaveId, @vWaveNo;

  /* Identify the scanned Pallet if needed */
  if ((coalesce(@vScannedPallet, '') <> '') and (@vPalletId is null))
    select @vPalletId = dbo.fn_Pallets_GetPalletId(@vScannedPallet, @vBusinessUnit);
  else
  /* Fetch current palletId only if a pallet was not given earlier */
  if (coalesce(@vScannedPallet, '') <> '')
    select @vScannedPalletId = dbo.fn_Pallets_GetPalletId(@vScannedPallet, @vBusinessUnit);

  /* Get other Pallet info */
  select  @vPallet           = Pallet,
          @vPalletLocationId = LocationId
  from Pallets
  where (PalletId = @vPalletId);

  /* Identify the scanned Location if needed */
  if (coalesce(@vScannedLocation, '') <> '') and (@vLocationId is null)
    select @vLocationId = dbo.fn_Locations_GetScannedLocation(null, @vScannedLocation, @vDeviceId, @vUserId, @vBusinessUnit);

  /* Get other Location info */
  select @vLocationId         = LocationId,
         @vLocationType       = LocationType
  from Locations
  where (LocationId = coalesce(@vLocationId, @vPalletLocationId));

  /* Check if user is just trying to palletize. If so skip and proceed to update pallet only */
  if (@vToLPNOnhandStatus = 'R' /* Reserved */) and (coalesce(@vPalletId, 0) <> coalesce(@vToLPNPalletId, 0))
    begin
      select @vMessage  = dbo.fn_Messages_Build('AMF_ShipCartonsActv_SuccessfulPalletized', @vScannedLPN, @vScannedPallet, null, null, null);

      goto SkipActivation;
    end

  /* Validations */
  if (dbo.fn_IsInList(@vToLPNStatus, @vInvalidToLPNStatus) > 0)
    begin
      select @vMessageName = 'LPNActv_ShipCartons_InvalidLPNStatus',
             @vValue1      = @vToLPNStatusDesc;
    end
  else
  /* Error out if the To LPN is already activated and on the same pallet */
  if (@vToLPNOnhandStatus = 'R' /* Reserved */) and (coalesce(@vPalletId, 0) = coalesce(@vToLPNPalletId, 0))
    set @vMessageName = 'LPNActv_ShipCartons_AlreadyActivatedandOnPallet';
  else
  if (@vFromLPNDetailsCount = 0)
    begin
      set @vMessageName = 'LPNActv_ShipCartons_NoInventoryToActivate';
      select @vValue1   = @vWaveNo;
    end
  else
  if ((coalesce(@vScannedLocation, '') <> '') and (@vLocationId is null))
    set @vMessageName = 'LPNActv_ShipCartons_InvalidLocation';
  else
  if ((coalesce(@vScannedPallet, '') <> '') and (@vPalletId is null))
    set @vMessageName = 'LPNActv_ShipCartons_InvalidPallet';
  else
  if (dbo.fn_IsInList(@vLocationType, 'C' /* conveyor */) > 0)
    set @vMessageName = 'LPNActv_ShipCartons_InvalidLocationType'
  else
  /* Ship carton has more quantity than the quantity reserved */
  if (@vToLPNDetailsTotQty > @vFromLPNDetailsTotQty)
    begin
      select @vMessageName = 'LPNActv_ShipCartons_InsufficientInvToActivate',
             @vValue1      = @vFromLPNDetailsTotQty,
             @vValue2      = @vToLPNDetailsTotQty;
    end
  else
  if (@vToLPNDetailsCount > @vFromLPNDetailsCount)
    set @vMessageName = 'LPNActv_ShipCartons_AllLinesCannotBeActivated';
  else
  /* Important to check if Pallet given has changed, only if a prior Pallet existed */
  if (coalesce(@vScannedPalletId, '') <> '') and (@vScannedPalletId <> @vPalletId)
    begin
      select @vMessageName = 'LPNActv_ShipCartons_PalletMismatch',
             @vValue1      = @vPallet,
             @vValue2      = @vScannedPallet;
    end

  /* Raise error if validation fails */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vValue1, @vValue2;

  /* Populate XML input for activating LPNs procedure: Driven by ToLPNs */
  select @vProcInputXML = dbo.fn_XMLNode('ConfirmLPNReservations',
                            dbo.fn_XMLNode('LPNType',       @vToLPNType) +
                            dbo.fn_XMLNode('BusinessUnit',  @vBusinessUnit) +
                            dbo.fn_XMLNode('UserId',        @vUserId) +
                            dbo.fn_XMLNode('Warehouse',     @vToLPNWarehouse));

  /* Activate pre-generated Ship Carton LPN */
  exec pr_Reservation_ActivateLPNs @vProcInputXML;

  select @vToLPNStatusDesc  = dbo.fn_Status_GetDescription('LPN', Status, @vBusinessUnit)
  from LPNs
  where (LPNId = @vToLPNId);

SkipActivation:
  /* Associate Pallet and/or Location to ToLPN */
  if (@vPalletId is not null)
    begin
      exec pr_LPNs_SetPallet @vToLPNId, @vPalletId, @vUserId, 'ShipCartonActivation';

      /* If Pallet is not in the Location, locate it - should be the first time around */
      if (@vPalletLocationId is null) and (@vLocationId is not null)
        exec pr_Pallets_SetLocation @vPalletId, @vLocationId, default /* Update LPNs */, @vBusinessUnit, @vUserId;
    end
  else
  /* Pallet is not given, but location is */
  if (@vLocationId is not null)
    exec pr_LPNs_SetLocation @vToLPNId, @vLocationId;

  /* Wave Recount & Status update */
  exec pr_PickBatch_Recalculate @ttWavesList, '$CS' /* defer status */, @vUserId, @vBusinessUnit;

  /* Populate DataXML based on the wave type */
  if (@vAutoConfirm = 'Y' /* Yes */)
    begin
      /* Clear the values so that we don't try to auto confirm the LPN again */
      select @DataXML = dbo.fn_XMLStuffValue(@DataXML, 'LPN',            '');
      select @DataXML = dbo.fn_XMLStuffValue(@DataXML, 'm_LPN',          '');
      select @DataXML = dbo.fn_XMLStuffValue(@DataXML, 'm_AutoConfirm',  '');

      /* Update the new status after LPN is activated */
      select @DataXML = dbo.fn_XMLStuffValue(@DataXML, 'm_LPNInfo_LPNStatusDesc',
                                                                         @vToLPNStatusDesc);

      /* Replace node name for the form to pick up these values */
      select @DataXML = replace(replace(@DataXML, '<m_LPNDETAILS',  '<LPNDETAILS'),
                                                  '</m_LPNDETAILS', '</LPNDETAILS');

      select @DataXML = dbo.fn_XMLAddNode(@DataXML, 'Data', dbo.fn_XMLNode('LPNAutoConfirmed', 'Y'));
    end
  else
    select @DataXML = dbo.fn_XMLNode('Data',
                        dbo.fn_XMLNode('PalletInfo_Pallet',      @vScannedPallet) +
                        dbo.fn_XMLNode('LocationInfo_Location',  @vScannedLocation));

  /* Get the control to prompt pallet input for user */
  select @vPromptPallet = dbo.fn_Controls_GetAsBoolean('LPNShipCartonActivate', 'PromptPallet', 'Y' /* Yes */, @vBusinessUnit, @vUserId)

  /* Move onto the next LPN to validate and there by confirm later */
  select @DataXML = dbo.fn_XMLAddNode(@DataXML, 'Data', dbo.fn_XMLNode('PrevLPN', @vScannedLPN) +
                                                        dbo.fn_XMLNode('PromptPallet', @vPromptPallet));

  /* Build Success Message */
  select @vMessage  = coalesce(@vMessage, dbo.fn_Messages_Build('AMF_ShipCartonsActv_Successful', @vScannedLPN, null, null, null, null));
  select @InfoXML   = dbo.fn_AMF_BuildSuccessXML(@vMessage);
end /* pr_AMF_Picking_ShipCartonActivation_Confirm */

Go

