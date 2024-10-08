/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/18  SK      pr_RFC_CC_ValidateEntity: Add validation for Invalid pallet scan and other cosmetic changes (HA-1428)
  2020/04/14  AY      pr_RFC_CC_ValidateEntity: More validations included by calling a different proc (HA-161)
  2018/02/12  OK      pr_RFC_CC_ValidateEntity: Changed to send UnitsPerInnerPack in xml response to RF (S2G-203)
  2018/02/12  SV      pr_RFC_CC_ValidateEntity: Added InnerPacksPerLPN value to the O/P xml on SKU scan.
                        This is used as to calculate the total qty of the carton (InnerPacksPerLPN * UnitsPerInnerPack) in RF (S2G-202)
  2018/02/06  SV      pr_RFC_CC_ValidateEntity: Message correction if the user scanned an Inactive sku (S2G-194)
  2017/02/20  OK      pr_RFC_CC_ValidateEntity: Allowed to cycle count the inventory less than reserved quantity (GNC-1426)
  2016/11/29  PSK     pr_RFC_CC_ValidateEntity:Added validations to not allow the invalid status LPNs (HPI-1026)
  2016/11/10  TK      pr_RFC_CC_ValidateEntity-Bug fix to show Quantity on Cyclecounting.(HPI-1020)
  2016/09/23  SV      pr_RFC_CC_CompleteLocationCC: Bug Fix - Not able to CC the Location when selecting empty Location (HPI-751)
                      pr_RFC_CC_ValidateEntity: Redirecting the Res Qty over the LPN to validate from RF end (CIMS-1069)
  2016/08/18  SV      pr_RFC_CC_StartDirectedLocCC, pr_RFC_CC_StartLocationCC: Changes to show the actual error message which occured in internal procedure call
                      pr_RFC_CC_ValidateEntity: Added validation when entering the SKU instead of Location (HPI-453)
  2015/12/11  SV      pr_RFC_CC_CompleteLocationCC, pr_RFC_CC_ValidateEntity: Handle duplicate UPCs i.e. diff SKUs having same UPC (SRI-422)
  2015/10/30  TK      pr_RFC_CC_StartLocationCC & pr_RFC_CC_ValidateEntity: Enhanced to allow user enter Cases,
                        Inner Packs and Units(ACME-379)
  2015/08/07  RV      pr_RFC_CC_ValidateEntity: Condition Changed for CC (FB-233).
  2015/05/05  OK      pr_RFC_CC_StartLocationCC,pr_RFC_CC_ValidateEntity: Made system compatable to accept either Location or Barcode
  2014/03/04  PK      pr_RFC_CC_ValidateEntity:Revereted the changes
  2014/01/08  PK      pr_RFC_CC_CompleteLocationCC: Considering Bulk Location as well.
                      pr_RFC_CC_ValidateEntity: Fix for returning LPNDetails if it is allocated partially.
  2013/11/22  PK      pr_RFC_CC_ValidateEntity: Bug fix to send SKU Count.
  2013/10/31  PK      pr_RFC_CC_ValidateEntity: Verifying the Warehouses from Mappings to validate Warehouse mismatch.
  2013/04/09  AY      pr_RFC_CC_ValidateEntity: Turn of LocationsPAZoneMismatch validation
                        based upon control var as some may not need to use it.
  2012/09/13  VM/YA   pr_RFC_CC_ValidateEntity: Handle null PutawayClass in PA Rules.
  2012/09/12  PK      pr_RFC_CC_ValidateEntity: Allowing Lost LPNs as well.
                       Included an additional check to raise error, if the user scan's an Invalid LPN.
  2012/09/03  AY      pr_RFC_CC_ValidateEntity: New Parms TaskId, TaskDetailId to update
                        status of the location.
  2012/08/30  AY      pr_RFC_CC_ValidateEntity: New validation to prevent from picked LPNs into Reserve/Bulk Locations
  2012/08/24  AY/PK   pr_RFC_CC_ValidateEntity: Code optimizations & Bug fixes related to Pallet CC
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_CC_ValidateEntity') is not null
  drop Procedure pr_RFC_CC_ValidateEntity;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_CC_ValidateEntity:

  This is a multi use procedure and the operation would vary based upon the context.
  When scanning location contents, user may be scanning a SKU or an LPN and when
  scanning LPN contents only a SKU is expected. The combinations of ValidateOptions and
  Control var which overrides it are described below (note that Control var AllowEntity is
  Location Type specific i.e. diff. location types would have different control vars):

  ValidateOption  ControlVar       Interpretation and Validation
  LS                L                In the context of the RF an LPN or SKU could be scanned
                                     but the control var overrides this with L - meaning
                                     that only an LPN would be accepted for this Location Type
                                     and if a SKU is scanned by user an error would be raised
  LS                S                In the context of the RF an LPN or SKU could be scanned
                                     but the control var overrides this with S - meaning
                                     that only a SKU would be accepted for this Location Type
                                     and if a LPN is scanned by user an error would be raised
  LS                LS               In the context of the RF an LPN or SKU could be scanned
                                     and the control var is the same, hence user would be allowed
                                     to scan SKU or LPN and anything else would raise an error.
  S                 N/A              RF expects a SKU scan only, so a control var is not necessary
                                     to override and only a valid SKU would be accepted.
  P                 N/A              RF expects a Pallet scan only, so a control var is not necessary
                                     to override and only a valid Pallet would be accepted.

  Usage:
  In Locator System Install:
    For Reserve Locations, control var would be L
    For Picklanes, control var would be S
  In AX install:
    For Reserve Locations, control var could be L or LS (depending upon the client)
    For Picklanes, control var would be S
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_CC_ValidateEntity
  (@xmlInput         xml,
   @xmlResult        xml  output)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @Message           TDescription,

          @vLPNId            TRecordId,
          @vLPN              TLPN,
          @vLPNSKUId         TRecordId,
          @vLPNType          TTypeCode,
          @vLPNStatus        TStatus,
          @vLineCount        TCount,
          @vLPNQuantity      TQuantity,
          @vSKUId            TRecordId,
          @vSKU              TSKU,
          @vSKUStatus        TStatus,
          @vSKUCount         TCount,
          @vSKUPutawayClass  TCategory,
          @vStatus           TStatus,
          @vRuleId           TRecordId,
          @vSKUScanned       TFlag,
          @vLPNScanned       TFlag,

          @vPalletId         TRecordId,
          @vPallet           TPallet,
          @vPalletScanned    TFlag,
          @vPalletWarehouse  TWarehouse,

          @vLocationId       TRecordId,
          @vLocation         TLocation,
          @vLocationType     TTypeCode,
          @vStorageType      TTypeCode,
          @vLPNDestWarehouse TWarehouse,
          @vLocWarehouse     TWarehouse,
          @vControlCategory  TCategory,
          @vAllowLPNScan     TFlag,
          @vAllowEntity      TFlag,
          @vAllowSKUScan     TFlag,
          @xmlResultvar      varchar(max),
          @vTransaction      TDescription,
          @vxmlPalletInfo    xml,
          @vxmlPalletDetails xml,

          @Location          TLocation,
          @ScannedEntity    TSKU,
          @LPN              TLPN,
          @Pallet           TPallet,
          @ValidateOption   TFlag, /* see comments above */
          @TaskId           TRecordId,
          @TaskDetailId     TRecordId,
          @ScannedQty       TQuantity,
          @ScannedUoM       TUoM,
          @BusinessUnit     TBusinessUnit,
          @UserId           TUserId,
          @DeviceId         TDeviceId;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  /* Initialize local variables and retreive values  from i/p xml */
  select @Location       = nullif(Record.Col.value('Location[1]' , 'TLocation'),''),
         @ScannedEntity  = nullif(Record.Col.value('ScannedEntity[1]', 'TLPN'), ''),
         @LPN            = nullif(Record.Col.value('LPN[1]', 'TLPN'), ''),
         @Pallet         = nullif(Record.Col.value('Pallet[1]', 'TPallet'), ''),
         @ValidateOption = nullif(Record.Col.value('ValidateOption[1]', 'TFlag'), ''),
         @TaskId         = nullif(Record.Col.value('TaskId[1]', 'TRecordId'), ''),
         @TaskDetailId   = nullif(Record.Col.value('TaskDetailId[1]', 'TRecordId'), ''),
         @ScannedQty     = nullif(Record.Col.value('ScannedQty[1]', 'TQuantity'), ''),
         @ScannedUoM     = nullif(Record.Col.value('ScannedUoM[1]', 'TUoM'), ''),
         @BusinessUnit   = nullif(Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'), ''),
         @UserId         = nullif(Record.Col.value('UserId[1]', 'TUserId'), ''),
         @DeviceId       = nullif(Record.Col.value('DeviceId[1]', 'TDeviceId'), '')
  from @xmlInput.nodes('ValidateCCEntity') as Record(Col)

  /* Assume scanned Entity is SKU and fetch SKU Details */
  select @vSKUId           = SKUId,
         @vSKU             = SKU,
         @vSKUStatus       = Status,
         @vSKUPutawayClass = PutawayClass
  from dbo.fn_SKUs_GetScannedSKUs (@ScannedEntity, @BusinessUnit);

  select @vSKUScanned = case when @vSKUId is not null then 'Y' else 'N' end;

  /* If not a valid SKU, then assume it is LPN. If a specific LPN is given
     then use it and fetch LPN Details */
  if (@vSKUScanned = 'N') or (@LPN is not null)
    select @vLPNId            = L.LPNId,
           @vLPN              = L.LPN,
           @vLPNSKUId         = L.SKUId,
           @vLPNStatus        = L.Status,
           @vLPNType          = L.LPNType,
           @vLPNDestWarehouse = L.DestWarehouse,
           @vSKUPutawayClass  = S.PutawayClass
    from  LPNs L left outer join SKUs S on L.SKUId = S.SKUId
    where (L.LPN          = coalesce(@LPN, @ScannedEntity)) and
          (L.BusinessUnit = @BusinessUnit);

  select @vLPNScanned = case when @ScannedEntity = @vLPN then 'Y' else 'N' end;

  /* For now we are verifying the Pallets from LPNS only, So if the pallet is empty then there will not be
     any LPNs on it, So If the Pallet on the is LPN is null, we are verify whether the Pallet exists in
     Pallets or not, if Scanned Pallet doesnot exists in Pallets as well, we will raise the error */
  if ((@vSKUScanned = 'N') and (@vLPNScanned = 'N')) or
     (@Pallet is not null)
    select @vPalletId        = PalletId,
           @vPallet          = Pallet,
           @vPalletWarehouse = Warehouse
    from vwPallets
    where Pallet = coalesce(@Pallet, @ScannedEntity);

  select @vPalletScanned = case when @ScannedEntity = @vPallet then 'Y' else 'N' end;

  /* Get Location Details */
  select @vLocationId   = LocationId,
         @vLocation     = Location,
         @vLocationType = LocationType,
         @vStorageType  = StorageType,
         @vLocWarehouse = Warehouse
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @Location, @DeviceId, @UserId, @BusinessUnit));

  /* select  Control Category */
  select @vControlCategory = 'CycleCount_' + @vLocationType + @vStorageType;

  /* Based upon Validate Option and Control var determine what is allowed */
  /* if @ScanOption is LS, here L stands for LPN and S stands for SKU, for Loehmanns we will scan only LPN, even if they scan SKU then we will
     validate it. */
  if (@ValidateOption = 'LS')
    begin
      /* Fetching ControlValues as boolean value */
      select @vAllowEntity   = dbo.fn_Controls_GetAsString(@vControlCategory, 'AllowEntity', 'LS',
                                                           @BusinessUnit, @UserId);
      select @vAllowLPNScan  = case when @vAllowEntity like '%L%' then 'Y' else 'N' end,
             @vAllowSKUScan  = case when @vAllowEntity like '%S%' then 'Y' else 'N' end;
    end
  else
  if (@ValidateOption = 'S' /* SKU */)
    begin
      select @vAllowSKUScan = 'Y' /* Yes */,
             @vAllowLPNScan = 'N' /* No */;
    end
  else
  if (@ValidateOption = 'P' /* Pallet */)
    begin
      select @vAllowSKUScan = 'N' /* No */,
             @vAllowLPNScan = 'N' /* No */;
    end

  /* Validations */

  /* If LPN was scanned, and it is a Logical LPN, then raise error */
  if ((@vSKUId is null) and (@vLPNId is not null) and
      (@vLPNType = 'L'/* Logical */))
    select @MessageName = 'CC_InvalidLPNType'
  else
  /* Expecting a SKU, but user scanned LPN  */
  if (@ValidateOption = 'S') and (@vLPNScanned = 'Y')
    select @MessageName = 'CC_ScanSKUNotLPN';
  else
  /* Expecting a SKU only, so ensure there is one */
  if (@ValidateOption = 'S') and (@vSKUId is null)
    select @MessageName = 'CC_InvalidSKU';
  else
  if (@ValidateOption = 'S') and (@vSKUId is not null) and (@vSKUStatus = 'I') and
     (dbo.fn_Controls_GetAsString('CycleCount', 'ConsiderOnlyActiveSKU',  'N' /* No */, @BusinessUnit, System_User) = 'Y')
    select @MessageName = 'CC_InactiveSKU';
  else
  /* Expecting a LPN only, so ensure there is one */
  if (@ValidateOption = 'L') and (@vLPNId is null)
    select @MessageName = 'CC_InvalidLPN';
  else
  /* Expecting a LPN only, so ensure there is one */
  if (@ValidateOption = 'LS') and (@vLPNId is null) and (@vSKUId is null)
    select @MessageName = 'CC_InvalidSKUorLPN';
  else
  /* Expecting a Pallet only, so ensure there is one */
  if (@ValidateOption = 'P') and (@vPalletId is null)
    select @MessageName = 'CC_InvalidPallet';
  else
  if ((@vSKUId is null) and (@vLPNId is null) and (@vPalletId is null))   /* Scanned entry is neither SKU nor LPN nor Pallet */
    select @MessageName = 'CC_InvalidEntity';
  else
  /* If valid SKU has been scanned but SKU is not accepted, then raise an error */
  if ((@vSKUId is not null) and (@vAllowSKUScan = 'N' /* No */))
    select @MessageName = 'CC_CannotScanSKU'
  else
  /* If valid LPN has been scanned but LPN is not accepted, then raise an error */
  if ((@LPN is null) and (@vLPNId is not null) and (@vAllowLPNScan = 'N' /* No */))
    select @MessageName = 'CC_CannotScanLPN'
  else
  if ((@vLPNId is not null) and (@vStatus = 'N' /* Empty/New */))
    select @MessageName = 'CC_LPNIsEmpty'
  else
  if (@vLPNScanned = 'Y') and
     (@vLPNStatus not in ('P', 'A', 'N', 'T', 'R', 'O' /* Putaway/Allocated/New/Intransit/Received/Lost */)) and
     (@vLocationType in ('R' /* Reserve */, 'B'/* Bulk */))
     select @MessageName = 'CC_LPNStatusInvalid'
  else
  if (@vLPNScanned = 'Y') and
     (@vLPNStatus in ('S' /* Shipped */)) and
     (@vLocationType in ('R' /* Reserve */, 'B'/* Bulk */))
     select @MessageName = 'CC_LPNAlreadyShipped'
  else
  if (@vLPNScanned = 'Y') and
     (@vLPNStatus in ('V', 'C' /* Voided/Consumed */)) and
     (@vLocationType in ('R' /* Reserve */, 'B'/* Bulk */))
     select @MessageName = 'CC_LPNVoidOrConsumed'
  else
  if ((Right(@vStorageType, 1) not in ('A' /* Pallets */,  'L' /* LPNs */)) and
      (@ValidateOption <> 'P'/* Pallets */) and
      (@vLPNScanned = 'Y') and
      (@vLocationType in ('R' /* Reserve */, 'B'/* Bulk */, 'K'/* PickLane */)))
    set @MessageName = 'LPNAndStorageTypeMismatch'
  else
  if ((@vPallet is not null) and (charindex('A'/* Pallets */, @vStorageType) = 0) and (@ValidateOption = 'P'/* Pallets */)) and
      (@vLocationType in ('R' /* Reserve */, 'B'/* Bulk */, 'K'/* PickLane */))
    set @MessageName = 'PalletAndStorageTypeMismatch'
  else
  /* Cannot move LPN into any location which does not match the Warehouse
     of the LPN - the exception however is PHOTO-OUT Location i.e. an LPN
     of DestWarehouse = 199P can be moved into PHOTO-OUT location
  if (((@vLocationType = 'R'/* Reserve */) and (@ValidateOption <> 'P'/* Pallets */) and
       (coalesce(@vLPNDestWarehouse, '') <> coalesce(@vLocWarehouse, '')) and
       ((not (@vLocation like 'PHOTO-OUT%')) or (@vLPNDestWarehouse <> @vLocWarehouse)))
     or
     ((@vLocationType = 'R'/* Reserve */) and (@ValidateOption = 'P'/* Pallets */) and
      (@vPalletWarehouse <> '') and
      (@vPalletWarehouse <> coalesce(@vLocWarehouse, ''))))
    set @MessageName = 'WarehouseMismatch'*/
  if (((@vLocationType = 'R'/* Reserve */) and (@ValidateOption <> 'P'/* Pallets */) and
       (@vLocWarehouse not in (select TargetValue
                               from dbo.fn_GetMappedValues('CIMS', @vLPNDestWarehouse,'CIMS', 'Warehouse', null /* @Operation */, @BusinessUnit))) and
       ((not (@vLocation like 'PHOTO-OUT%')) or
             (@vLocWarehouse not in (select TargetValue
                                     from dbo.fn_GetMappedValues('CIMS', @vLPNDestWarehouse,'CIMS', 'Warehouse', null /* @Operation */, @BusinessUnit)))))
     or
     ((@vLocationType = 'R'/* Reserve */) and (@ValidateOption = 'P'/* Pallets */) and
      (@vPalletWarehouse <> '') and
      (@vLocWarehouse not in (select TargetValue
                                 from dbo.fn_GetMappedValues('CIMS', @vPalletWarehouse,'CIMS', 'Warehouse', null /* @Operation */, @BusinessUnit)))))
    set @MessageName = 'WarehouseMismatch'
  else
  if (@vSKUPutawayClass is not null) and (@vLocationType = 'K' /* Picklane */) and
     (dbo.fn_Controls_GetAsString('CycleCount', 'RestrictSKUToPAZone', 'N', @BusinessUnit, @UserId) = 'Y')
    begin
      /* Check if the scanned SKU or scanned LPNs' SKU matches with the
         Locations' PA Zone as per the Putaway rules */
      select @vRuleId = RecordId
      from PutawayRules PR
        join Locations  L on (PR.PutawayZone    = L.PutawayZone ) and
                             (PR.LocationType   = L.LocationType) and
                             (PR.StorageType    = L.StorageType ) and
                             (coalesce(PR.Location, @vLocation) = L.Location)
      where (coalesce(PR.SKUPutawayClass, @vSKUPutawayClass) = @vSKUPutawayClass);

      if (@vRuleId is null)/* check for Putaway rule */
        set @MessageName = 'SKU-LocationsPAZoneMismatch';
    end

  if (@MessageName is not null)
    goto ErrorHandler;

  /* More validations - if there are any exceptions, catch block catches to raise the error */
  if (@vLPNId is not null)
    exec pr_LPNs_ValidateInventoryMovement @vLPNId, null /* PalletId */, @vLocationId, 'CycleCount', @BusinessUnit, @UserId;

  /* If the cycle count is associated with a task, then update it's status */
  if (@TaskDetailId > 0)
    update TaskDetails
    set Status     = 'I' /* In Progress */,
        ModifiedBy = @UserId
    where (TaskDetailId = @TaskDetailId) and
          (Status <> 'I' /* In Progress */);


  if (@vSKUId is not null)
    begin
      select @vTransaction = 'CC_ValidateSKU'

      /* Return XML with UnitsPerLPN, UnitsPerIP */
      select @xmlResult = (select SKU, UnitsPerLPN, UnitsPerInnerPack, InnerPacksPerLPN
                           from SKUs
                           where (SKUId = @vSKUId)
                           for XML RAW('SKUINFO'), TYPE, ELEMENTS XSINIL, ROOT('CYCLECOUNTSKUDETAILS'))
    end
  else
  if (@vLPNId is not null)
    begin
      /* Get SKUCount from LPN details */
      select @vSKUCount    = count(distinct SKUId),
             @vLineCount   = count(*),
             @vLPNQuantity = sum(Quantity)
      from vwLPNDetails
      where (LPNId = @vLPNId);

      /* Build XML with the scanned LPN Details */
      select @xmlResult = (select LPNId, LPN, LPNDetailId, LPNLine, LPNType, CoO,
                                  SKUId, SKU, @vSKUCount SKUCount, Quantity, ReservedQuantity, InnerPacks, UnitsPerInnerPack, BusinessUnit
                           from vwLPNDetails
                           where (LPNId = @vLPNId)
                           for XML RAW('LPNINFO'), TYPE, ELEMENTS XSINIL, ROOT('CYCLECOUNTLPNDETAILS'));

      select @vTransaction = 'CC_ValidateLPN';
    end
  else
  if (@vPalletId is not null)
    begin
       /* Get NumLPNs and Qty on the Pallet to show to user */
      select @vxmlPalletInfo = (select NumLPNs, Pallet, Quantity
                                from Pallets
                                where (PalletId = @vPalletId)
                                for XML RAW('PALLETINFO'), ELEMENTS );

      /* Build XML with the scanned Pallet LPN Details */
      select @vxmlPalletDetails = (select LPNId, LPN, LPNDetailId, LPNLine, LPNType, CoO,
                                     SKUId, SKU, Quantity, InnerPacks, BusinessUnit
                                   from vwLPNDetails
                                   where (PalletId = @vPalletId)
                                   for XML RAW('PALLETDETAILS'), ELEMENTS );

      /* Build XML with the Complete Pallet Information(PalletInfo and PalletDetails) */
      select @xmlresult    = (select /* <PALLETINFO> */
                                     @vxmlPalletInfo,
                                     /* </PALLETDETAILS> */
                                     @vxmlPalletDetails
                              for XML RAW('CYCLECOUNTPALLETDETAILS'), ELEMENTS),
             @vTransaction = 'CC_ValidatePallet';
    end

  /* Update Devices table with transaction detail */
  set @xmlResultvar = convert(varchar(max), @xmlResult)
  exec pr_Device_Update @DeviceId, @UserId, @vTransaction, @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_BuildRFErrorXML @xmlResult output;
end catch;

  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_CC_ValidateEntity */

Go
