/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/11  RIA     pr_pr_RFC_ValidateLocation: Added coalesce to update the UoM to EA (OB2-778)
  2018/03/15  KSK     pr_RFC_ValidateLocation: Made changes to allow LPNs for ReplenishUoM (S2G-365)
  2018/01/18  OK      pr_RFC_ValidateLocation: Made changes to allow AddSKUAndInventory for dynamic locations (S2G-117)
  2017/03/02  RV      pr_RFC_ValidateLocation: Reverted previous changes against HPI-597 and
  2016/11/10  TK      pr_RFC_ValidateLocation: There are instances where LPN doesn't contain any details, if so return the details
  2016/10/21  SV      pr_RFC_ValidateLocation: Displaying the detail lines in RF grid based on the OnHandStatus (HPI-904)
  2016/05/03  SV      pr_RFC_ValidateLocation: Made changes to show appropriate message upon not providing the SKU in Manage PickLane actions (HPI-86)
  2016/02/23  OK      pr_RFC_ValidateLocation: Included the Setup Picklane Operation (SRI-467)
  2016/02/16  OK      pr_RFC_ValidateLocation: Enhanced to send Default ReplenishUoM and Valid Replenish UoMs (NBD-129)
  2016/02/10  OK      pr_RFC_ValidateLocation: Enhanced to send the EnableUoM field from control variable to control UI(NBD-124)
  2015/12/18  TK      pr_RFC_ValidateLocation : Return InnerPacksPerLPN also
  2015/12/11  SV      pr_RFC_AddSKUToLocation, pr_RFC_RemoveSKUFromLocation, pr_RFC_UpdateSKUAttributes, pr_RFC_ValidateLocation,
  2015/04/12  DK      pr_RFC_ValidateLocation: Made changes to get UoM based on StorageType while adding inventory (FB -321).
                      pr_RFC_ValidateLocation: Made system compatable to accept either Location or Barcode.
  2015/04/17  RV      pr_RFC_ValidateLocation:Changes to adjust Location when there is only one reservedline.
  2015/03/17  RV      pr_RFC_ValidateLocation: Validation added to Remove SKU.
  2015/01/12  VM/PV   pr_RFC_AdjustLocation: Changes to use param changes of pr_RFC_ValidateLocation
  2014/11/12  DK      pr_RFC_ValidateLocation: Modified to return UnitsPerLPN
  2014/11/10  DK      pr_RFC_ValidateLocation: Modified to return dataset for operation 'AddSKUToLocation'.
                      pr_RFC_ValidateLocation: Added new parameter 'SKU'
  2014/07/09  TD      pr_RFC_ValidateLocation: sending set up SKUs for static Locations while doing location adjust.
  2014/06/14  PV      pr_RFC_ValidateLocation: Changed procedure to accept TXML as input parameter.
  2014/06/03  PV      pr_RFC_ValidateLocation: Returning only lines with quantity > 0 and moved calculations to view.
  2014/05/16  PV      pr_RFC_ValidateLocation, pr_RFC_ValidateLPN: Enhanced to return reserved quantity and PickTicket number.
  2014/05/05  PV      pr_RFC_ValidateLocation, pr_RFC_ValidateLPN: Enhanced to return DisplayQuantity.
  2014/05/02  TD      pr_RFC_ValidateLocation: Return InnerPacksPerLPN, UnitsPerInnerPack, UnitsPerLPN as well to use it for LocationSetup
                      pr_RFC_ValidateLocation: Changes to pass default UoM to RF.
  2013/06/10  TD      pr_RFC_ValidateLocation: Senmd UoM from the UoM instead of SKU4.
  2103/05/23  TD      pr_RFC_ValidateLPN, pr_RFC_ValidateLocation: Added UPC.
  2012/07/27  YA      pr_RFC_ValidateLocation: Allow adjust location in case NumLPNs <> 0 (by reverting previous change).
  2012/07/25  YA      pr_RFC_ValidateLocation: Modified to allow adjust on static location even if location is empty.
  2012/07/17  YA/AY   pr_RFC_ValidateLocation, pr_RFC_ValidateLPN: Added new param
  2011/10/10  PK      pr_RFC_ValidateLocation: Reverted changes done for Putaway By Location
  2011/09/26  AY      pr_RFC_ValidateLocation: Modified to return count of LPNs, LocationType as well
  2011/01/05  PK      pr_RFC_ValidateLocation: Removed the validation of PickLane, which is
  2010/12/23  PK      pr_RFC_ValidateLocation: Changes vwLocations to vwLPNDetails.
  2010/12/01  VK      pr_RFC_ValidateLocation: Completed the functionality
  2010/11/23  PK      Created wrapper signature for pr_RFC_ValidateLocation,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ValidateLocation') is not null
  drop Procedure pr_RFC_ValidateLocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ValidateLocation:

    This Procudure is to validate the scanned location and return the dataset based on operation
    1. AddSKU                 - To Add SKUs without quantity
    2. RemoveSKUs             - To remove SKUs with only zero quantity in static picklanes
    3. SetupPicklane          - To setup Picklane after SKU added
    4. AddSKUandSetupPicklane - To add SKU and setup Picklane location
    5. AddSKUAndInventory     - To Add SKU with Inventory
    6. PickingLocationSetUp   - To setup the picklane location
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ValidateLocation
  (@xmlInput    TXML)
as
  declare @LocationId    TRecordId,
          @Location      TLocation,
          @SKU           TSKU,
          @Operation     TDescription,
          @BusinessUnit  TBusinessUnit,
          @DeviceId      TDeviceId,
          @UserId        TUserId,
          @Warehouse     TWarehouse;

  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,
          @vStatus            TStatus,
          @vLocationType      TTypeCode,
          @vLocationSubType   TTypeCode,
          @vLocationId        TRecordId,
          @vNumLPNs           TCount,
          @vLPNId             TRecordId,
          @vLPN               TLPN,
          @vLPNSKUId          TRecordId,
          @vSKUId             TRecordId,
          @vSKUDescription    TDescription,
          @vSKUUoM            TUoM,
          @vUnitsPerInnerPack TInnerpacks,
          @vInnerPacksPerLPN  TInnerpacks,
          @vAllowMultipleSKUs TFlag,
          @vNumSKUs           TCount,
          @vDefaultUoM        TUoM,
          @vStorageType       TTypeCode,
          @vUOMEADescription  TDescription,
          @vUOMCSDescription  TDescription,
          @xmlInputvar        XML,
          @vIsAllowRemoveSKUs TControlValue,
          @vIncludeEmptyLine  TFlags,
          @vEnableUoM         TControlValue,
          @vDefaultReplUoM    TUoM,
          @vValidReplUoMs     TControlValue;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode       = 0,
         @vIncludeEmptyLine = 'N';

  /* convert input TXML to XML */
  select @xmlInputvar = convert(xml,@xmlInput);

  /* Read Values from input xml */
  select @LocationId    = nullif(Record.Col.value('LocationId[1]', 'TRecordId'),0),
         @Location      = Record.Col.value('Location[1]', 'TLocation'),
         @SKU           = nullif(Record.Col.value('SKU[1]', 'TSKU'),''),
         @Operation     = nullif(Record.Col.value('Operation[1]', 'TDescription'),''),
         @BusinessUnit  = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
         @DeviceId      = Record.Col.value('DeviceId[1]',  'TDeviceId'),
         @UserId        = Record.Col.value('UserId[1]',    'TUserId'),
         @Warehouse     = Record.Col.value('Warehouse[1]', 'TWarehouse')
  from @xmlInputvar.nodes('ValidateLocation') as Record(Col);

  /* RemoveSKU, RemoveSKUs: Don't know why we have two operations, but we need to fix this later */

  select @LocationId         = LocationId,
         @vLocationId        = LocationId,
         @vLocationType      = LocationType,
         @Location           = Location,
         @vStatus            = Status,
         @vAllowMultipleSKUs = AllowMultipleSKUs,
         @vNumLPNs           = NumLPNs,
         @vStorageType       = StorageType,
         @vLocationSubType   = LocationSubType
  from  Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (@LocationId, @Location, @DeviceId, @UserId, @BusinessUnit));

  /* Get the SKU that matches with the user scanned entity (SKU or UPC), order by Status to get the active ones
     and if there are multiple get the latest one */
  select top 1 @vSKUId = SKUId
  from dbo.fn_SKUs_GetScannedSKUs (@SKU, @BusinessUnit)
  order by Status, SKUId desc;

  /* Get the SKU if already added to the location */
  if (@Operation = 'SetupPicklane') and (@vNumLPNs = 1)
    select @vSKUId = SKUId /* We should return the SKU details if only one SKU is added to location */
    from LPNs
    where (LocationId = @vLocationId);

  /* Get SKU details from SKUs */
  select @vSKUId             = SKUId,
         @vSKUDescription    = Description,
         @vSKUUoM            = coalesce(UoM, 'EA'),
         @vUnitsPerInnerPack = UnitsPerInnerPack,
         @vInnerPacksPerLPN  = InnerPacksPerLPN
  from SKUs
  where (SKUId = @vSKUId);

  /* Get the Logical LPN for given Location and SKU */
  select @vLPNId    = LPNId,
         @vLPN      = LPN,
         @vLPNSKUId = SKUId
  from LPNs
  where (LocationId = @vLocationId) and
        (SKUId      = @vSKUId);

  /* Get Allow Remove Information from Control */ -- this should be user permission

  select @vIsAllowRemoveSKUs = dbo.fn_Controls_GetAsBoolean('Remove_SKU','RemoveSKUFromLocation','N',@BusinessUnit,@UserId),
         @vEnableUoM         = dbo.fn_Controls_GetAsString('Inv_' + @Operation, 'EnableUoM', 'N' /* No */, @BusinessUnit, @UserId);

  if (@vLocationId is null)
    set @vMessageName = 'LocationDoesNotExist';
  else
  if (@vIsAllowRemoveSKUs = 'N' /* No */) and (@Operation = 'RemoveSKUs')
    set @vMessageName = 'LocationRemoveSKU_NotAllowed';
  else
  if (coalesce(@SKU, '') = '') and
     (@Operation in ('AddSKUAndInventory', 'AddSKU', 'AddSKUandSetupPicklane', 'RemoveSKU'))
    set @vMessageName = 'SKUIsRequired';
  else
  if (@vSKUId is null) and (@Operation in ('AddSKUAndInventory', 'AddSKU', 'AddSKUandSetupPicklane', 'RemoveSKU'))
    set @vMessageName = 'SKUIsInvalid';
  else
  /* We should not allow any activity on Inactive locations, but can remove SKUs */
  if (@vStatus = 'I' /* InActive */) and (@Operation <> 'RemoveSKU')
    set @vMessageName = 'LocationIsNotActive';
  else
  if (@vLocationType <> 'K' /* Picklane */) and (@Operation = 'AdjustLocation')
    set @vMessageName = 'LocationAdjust_NotAPicklane';
  else
  if (@vLocationType <> 'K' /* Picklane */) and
     (@Operation in ('AddSKUAndInventory', 'AddSKU', 'AddSKUandSetupPicklane'))
    set @vMessageName = 'LocationAddSKU_NotAPicklane';
  else
  if (@vLocationType <> 'K' /* Picklane */) and (@Operation in ('RemoveSKU', 'RemoveSKUs'))
    set @vMessageName = 'LocationRemoveSKU_NotAPicklane';
  else
  if (@vNumLPNs = 0) and (@Operation = 'RemoveSKUs')
    set @vMessageName = 'LocationRemoveSKU_NoSKUs';
  else
  if (@Operation = 'RemoveSKU') and (not exists (select * from vwLPNDetails where (Location = @Location) and (SKUId = @vSKUId) and (Quantity = 0)))
    set @vMessageName = 'SKURemove_InventoryExists_CannotRemove';
  else
  if (@Operation = 'RemoveSKUs') and (not exists (select * from vwLPNDetails where (Location = @Location) and (Quantity = 0)))
    set @vMessageName = 'LocationRemoveSKU_NoSKUsWithZeroQty';
  else
  if (@vLocationType <> 'K' /* Picklane */) and (@Operation = 'TransferInventory')
    set @vMessageName = 'CannotTransferFromNonPicklaneLoc';
  else
  /* Validate if the user trying to setup location which is not picklane */
  if (@vLocationType <> 'K' /* Picklane */) and (@Operation in ('PickingLocationSetUp', 'SetupPicklane'))
    set @vMessageName = 'PicklaneSetUp_NotAPicklane';
  else
  if (@vLocationSubType <> 'S' /* Static */) and (@Operation in ('AddSKU', 'AddSKUandSetupPicklane'))
    set @vMessageName = 'LocationAddSKU_NotStaticLocation';
  else
  /* Check for allow multiple SKUs flag if Operation is AddSKU and AddSKUandSetupPicklane */
  if (@vAllowMultipleSKUs = 'N' /* No */) and (@Operation in ('AddSKUAndInventory', 'AddSKU', 'AddSKUandSetupPicklane')) and
     (@vLPNId is null) and  /* There is no SKU in the location */
     (@vNumLPNs > 0)        /* But there are other SKU(s) */
    set @vMessageName = 'LocationAddSKU_NoMultipleSKUs';
  else
  if (@vLPNId is null) and (@Operation = 'RemoveSKU')
    set @vMessageName = 'LocationRemoveSKU_SKUDoesNotExist';
  else
  if (@vLPNId <> '') and (@Operation in ('AddSKU'))
    set @vMessageName = 'LocationAddSKU_SKUAlreadyInLocation';
  else
  /* If NumLPNs is 0 then for dynamic locations we cannot perform adjustment by hitting the below code,
     and since for static locations as NumLPNs would not be 0 (once a SKU is added), it skips the below code.*/
  if (@vNumLPNs = 0) and (@Operation = 'AdjustLocation')
    set @vMessageName = 'LocationAdjust_NoItems';
  else
  /* Can only setup Replenish Levels if Location has SKU(s) assigned to it */
  if (@vNumLPNs = 0) and (@Operation in ('SetupPicklane'))
    set @vMessageName = 'PicklaneSetUp_SKUIsNotAdded';
  else
  /* This is for RF use- If the user scans Empty location for picklane setup then we need to issue error */
  if ((@Operation = 'PickingLocationSetUp') and (not exists(select * from vwLPNDetails where Location = @Location)))
    set @vMessageName = 'LocationSKUIsNotDefined';

  if (@vMessageName is not null)
     goto ErrorHandler;

  /* Override the DefaultUoM for PickLane - Case or Unit storage as the case may be */
  if ((@vLocationType   = 'K' /* Picklane */) and (Left(@vStorageType, 1) = 'U' /* Units */))
    select @vDefaultUoM     = coalesce(@vSKUUoM, 'EA'),
           @vDefaultReplUoM = 'EA', /* Eaches */
           @vValidReplUoMs  = case
                                when (@vUnitsPerInnerPack = 0) then coalesce(@vSKUUoM, 'EA')
                              else
                                coalesce(@vSKUUoM, 'EA') + ',CS,LPN'/* EACS - Eaches, Cases and LPNs */
                              end;
  else
  if ((@vLocationType = 'K' /* Picklane */) and (Left(@vStorageType, 1) = 'P' /* Package */))
    select @vDefaultUoM     = 'CS',
           @vDefaultReplUoM = 'CS', /* Cases */
           @vValidReplUoMs  = case
                                when (@vInnerPacksPerLPN = 0) then 'CS' /* Cases */
                              else
                                'CS,LPN' /* CSLPN - Cases and LPNs/Pallets */
                              end;

  /* Fetch the UOM descriptions */
  select @vUOMEADescription = dbo.fn_LookUps_GetDesc('UoM', coalesce(@vSKUUoM, 'EA'), @BusinessUnit, default),
         @vUOMCSDescription = dbo.fn_LookUps_GetDesc('UoM', 'CS', @BusinessUnit, default);

  /* Return the dataset based on the operation */
  if (@Operation = 'RemoveSKU')
    begin
    /* There are instances where LPN doesn't contain any details, if so return the details
       of LPN is scanned LPN SKUs is same as scanned SKU */
      if exists(select *
                from LPNDetails
                where (LPNId = @vLPNId) and
                      (SKUId = @vSKUId))
        select LPNId, LPN, LPNDetailId, LPNLine, LPNType, CoO,
               SKUId, SKU, coalesce(SKU1, '') SKU1, coalesce(SKU2,'') SKU2,
               coalesce(SKU3, '') SKU3, coalesce(SKU4, '') SKU4, coalesce(SKU5, '') SKU5, UOM,
               coalesce(SKUDescription, SKU) SKUDescription,
               OnhandStatus, OnhandStatusDescription,
               InnerPacks, Quantity,UnitsPerPackage, ReceivedUnits,
               ShipmentId, LoadId, ASNCase, LocationId, Location, Barcode, OrderId, PickTicket,
               SalesOrder, OrderDetailId, OrderLine, ReceiptId, ReceiptNumber,
               ReceiptDetailId, ReceiptLine, Weight, Volume, Lot, LastPutawayDate,
               UDF1, UDF2, UDF3, UDF4, UDF5, BusinessUnit
        from vwLPNDetails
        where (Location = @Location) and
              (SKUId    = @vSKUId);
      else
      if (@vLPNSKUId = @vSKUId)
        select LPNId, LPN, 0 as LPNDetailId, 0 as LPNLine, L.LPNType, CoO,
               S.SKUId, S.SKU, coalesce(S.SKU1, '') SKU1, coalesce(S.SKU2,'') SKU2,
               coalesce(S.SKU3, '') SKU3, coalesce(S.SKU4, '') SKU4, coalesce(S.SKU5, '') SKU5, S.UOM,
               coalesce(S.Description, S.SKU) SKUDescription,
               OnhandStatus, OnhandStatusDescription,
               InnerPacks, Quantity, 0 as UnitsPerPackage, 0 as ReceivedUnits,
               ShipmentId, LoadId, ASNCase, LocationId, Location, Barcode, OrderId, PickTicket,
               SalesOrder, 0 as OrderDetailId, 0 as OrderLine, ReceiptId, ReceiptNumber,
               0 as ReceiptDetailId, 0 as ReceiptLine, Lot, null as LastPutawayDate,
               L.UDF1, L.UDF2, L.UDF3, L.UDF4, L.UDF5, S.BusinessUnit
        from vwLPNs L
          join SKUs S on (L.SKUId = S.SKUId)
        where (LPNId = @vLPNId);
    end
  else
  /* Return the SKU details to display in RF */
  if (@Operation in ('AddSKUAndInventory', 'AddSKUandSetupPicklane', 'AddSKU') or ((@Operation = 'SetupPicklane') and @vNumLPNs = 1))
    select 0 as LPNId, '' as LPN, 0 as LPNDetailId, 0 as LPNLine, '' as LPNType, '' as CoO,
           SKUId, SKU, coalesce(SKU1, '') SKU1, coalesce(SKU2,'') SKU2, coalesce(SKU3, '') SKU3,
           coalesce(SKU4, '') SKU4, coalesce(SKU5, ''), @vDefaultUoM as UOM, @vDefaultReplUoM as ReplenishUoM,
           @vValidReplUoMs as ValidReplenishUoMs, coalesce(Description, '') as SKUDescription, '' as OnhandStatus,
           '' as OnhandStatusDescription, 0 as InnerPacks, 0 as UnitsPerPackage, 0 as Quantity, UnitsPerInnerPack,
           UnitsPerLPN, InnerPacksPerLPN, 0 as ReceivedUnits, 0 as ShipmentId, 0 as LoadId,
           '' as  ASNCase, 0 as LocationId, @Location as Location, '' as Barcode, 0 as OrderId,
           '' as PickTicket, '' as SalesOrder, 0 as OrderDetailId, 0 as OrderLine, 0 as ReceiptId,
           '' as ReceiptNumber, 0 as ReceiptDetailId,0 as ReceiptLine, '' as Lot,
           UDF1, UDF2, UDF3, UDF4, UDF5, BusinessUnit
    from SKUs
    where (SKUId = @vSKUId);
  else
  /* If location have multiple SKUs then return the generic SKU details to display in RF instead of single SKU */
  if ((@Operation = 'SetupPicklane') and (@vNumLPNs > 1))
    select 0 as LPNId, '' as LPN, 0 as LPNDetailId, 0 as LPNLine, '' as LPNType, '' as CoO,
           0 as SKUId, 'Multiple' as SKU, '' as SKU1, '' as SKU2, '' as SKU3,
           '' as SKU4, '' as SKU5, @vDefaultUoM as UOM, @vDefaultReplUoM as ReplenishUoM,
           @vValidReplUoMs as ValidReplenishUoMs, '' as SKUDescription, '' as OnhandStatus,
           '' as OnhandStatusDescription, 0 as InnerPacks, 0 as UnitsPerPackage, 0 as Quantity,0 as UnitsPerInnerPack,
           0 as UnitsPerLPN, 0 as InnerPacksPerLPN, 0 as ReceivedUnits, 0 as ShipmentId, 0 as LoadId,
           '' as  ASNCase, 0 as LocationId, @Location as Location, '' as Barcode, 0 as OrderId,
           '' as PickTicket, '' as SalesOrder, 0 as OrderDetailId, 0 as OrderLine, 0 as ReceiptId,
           '' as ReceiptNumber, 0 as ReceiptDetailId,0 as ReceiptLine, '' as Lot,
           '' as UDF1, '' as UDF2, '' as UDF3, '' as UDF4, '' as UDF5, @BusinessUnit as BusinessUnit;
  else
  if (@Operation = 'RemoveSKUs')
     select LPNId, LPN, LPNDetailId, LPNLine, LPNType, CoO, SKUId, SKU, coalesce(SKU1, '') SKU1,
           coalesce(SKU2,'') SKU2, coalesce(SKU3, '') SKU3, coalesce(SKU4, '') SKU4, coalesce(SKU5, ''),
           UOM, OnhandStatus, OnhandStatusDescription, coalesce(SKUDescription, SKU),
           InnerPacks, Quantity, UnitsPerPackage, ReceivedUnits, ShipmentId,
           LoadId, ASNCase, LocationId, Location, Barcode, OrderId, PickTicket,
           SalesOrder, OrderDetailId, OrderLine, ReceiptId, ReceiptNumber,
           ReceiptDetailId, ReceiptLine, Weight, Volume, Lot, LastPutawayDate,
           UDF1, UDF2, UDF3, UDF4, UDF5, BusinessUnit
    from vwLPNDetails
    where (Location = @Location) and
          (Quantity = 0);
  /* if the Location is not empty or it is been assosiated with SKU, then get the location
     details to show */
  else
  if (exists(select * from vwLPNDetails where (Location = @Location)))
    begin
      /* If all Quantity reserved to adjust location then we set the flag as 'Y' for Creating new line */
      if (@Operation = 'AdjustLocation') and
         (@vLocationType = 'K' /* Picklane */) and
         (not exists(select * from vwLPNDetails where (Location = @Location) and OnhandStatus = 'A'))
        select @vIncludeEmptyLine = 'Y';

      select LPNId, LPN, LPNDetailId, LPNLine, LPNType, CoO, SKUId, SKU, UPC,
             coalesce(SKU1, '') SKU1, coalesce(SKU2, '') SKU2, coalesce(SKU3, '') SKU3,
             coalesce(SKU4,'') SKU4, coalesce(SKU5,'') SKU5, coalesce(SKUDescription, SKU) SKUDescription,
             UOM, InnerPacksPerLPN, UnitsPerInnerPack, UnitsPerLPN, MinReplenishLevel, MaxReplenishLevel,
             OnhandStatus, OnhandStatusDescription,InnerPacks, Quantity, ReservedQuantity, UnitsPerPackage,
             ReceivedUnits, ShipmentId, LoadId, ASNCase, LocationId, Location, Barcode,
             OrderId, PickTicket, SalesOrder, OrderDetailId, OrderLine, ReceiptId, ReceiptNumber,
             ReceiptDetailId, ReceiptLine, Weight, Volume, Lot, LastPutawayDate,
             UDF1, UDF2, UDF3, UDF4, UDF5, BusinessUnit, @vDefaultUoM DefaultUoM, @vEnableUoM as EnableUoM,
             case when InnerPacks >0 then convert(varchar(5),InnerPacks) + ' ' + @vUOMCSDescription + '/'+ convert(varchar(5),Quantity) + ' ' + @vUOMEADescription
                  else convert(varchar(5),Quantity)    + ' ' + @vUOMEADescription
             end DisplayQuantity
      from vwLPNDetails
      where ((Location = @Location) and
             ((@vLocationSubType = 'S') or (Quantity > 0)))

      union

      select top 1 LPNId, LPN, 0 as LPNDetailId, 0 as LPNLine, LPNType, CoO, SKUId, SKU, UPC,
                 coalesce(SKU1,'') SKU1, coalesce(SKU2, '') SKU2, coalesce(SKU3, '') SKU3,
                 coalesce(SKU4,'') SKU4, coalesce(SKU5, '') SKU5, coalesce(SKUDescription, SKU) SKUDescription,
                 UOM, InnerPacksPerLPN, UnitsPerInnerPack, UnitsPerLPN, MinReplenishLevel, MaxReplenishLevel,
                 'A'  as OnhandStatus, 'Available' as OnhandStatusDescription,InnerPacks, 0 as Quantity, 0 as ReservedQuantity, UnitsPerPackage,
                 ReceivedUnits, ShipmentId, LoadId, ASNCase, LocationId, Location, Barcode,
                 null as OrderId, '-' as PickTicket, null as SalesOrder, null as OrderDetailId, null as OrderLine, null as ReceiptId, null as ReceiptNumber,
                 null as ReceiptDetailId, null as ReceiptLine, 0 as Weight, 0 as Volume, null as Lot, null as LastPutawayDate,
                 null as  UDF1, null as UDF2, null as UDF3,null as  UDF4, UDF5, BusinessUnit, @vDefaultUoM DefaultUoM, @vEnableUoM as EnableUoM,
                 '0 ' +@vUOMEADescription
                 as DisplayQuantity
      from vwLPNDetails
      where (Location = @Location) and (@vIncludeEmptyLine = 'Y')
      order by OnhandStatus /* Available, Directed, Directed Reserved, Reserved, Unavailable */;
    end

  /* this is for RF Use- If the user scans Empty location to add SKU then we need send Default UoM.
     So that RF will suggest to scan cases if the Location is Case Storage, or that will suggest
     to scan Units if the Location is UnitStorage */
  if ((@@rowcount = 0) and (@Operation = 'AddSKUToLocation'))
    select @Location Location, @vDefaultUoM DefaultUoM;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_ValidateLocation */

Go
