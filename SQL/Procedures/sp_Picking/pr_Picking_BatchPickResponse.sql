/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/07/06  SRP     pr_Picking_BatchPickResponse and pr_Picking_BuildPickResponseForLPN: Changed datatype For SKUImageURL (BK-832)
  2021/10/21  RT      pr_Picking_BatchPickResponse: Get the TotalUnitsToPick and if the quantity is more than the UnitsToPick against TaskDetail
  2021/02/17  TK      pr_Picking_BatchPickResponse & pr_Picking_ConfirmPicks:
  2020/12/15  RIA     pr_Picking_BatchPickResponse: Changes to show label code (HA-1778)
  2020/11/02  OK      pr_Picking_BatchPickResponse: Bug fix to get the UnitsToPick value for the Picking TaskDetailsId and removed unnecessary where clause (HA-1613)
  2020/09/19  TK      pr_Picking_BatchPickResponse: Changes to suggest Cart Position for PTC waves (CIMS-3160)
  2020/09/17  AY      pr_Picking_BatchPickResponse, pr_Picking_BatchPickResponseLPN: (CIMSV3-733)
  2020/08/28  AJM     pr_Picking_BatchPickResponse : Validation (Migrated from OB) (HA-1321)
  2020/06/11  RIA     pr_Picking_BatchPickResponse: Show Location and LPN in picklist for LPN Pick,case/unit picking from Reserve/Bulk (HA-889)
  2020/05/21  AY      pr_Picking_BatchPickResponse: Show LPN/Location when Picking from Reserve (HA-556)
  2019/06/10  RIA     pr_Picking_BatchPickResponse: Changes to show blank after picking all the units (CID-523)
  2019/05/29  AY      pr_Picking_BatchPickResponse: Show more info on RF during picking (CID-UAT)
  2019/02/12  AY      pr_Picking_BatchPickResponse: Enhance to show PickList for V3 tablet version
  2019/02/12  AY      pr_Picking_BatchPickResponse: Enhance to show PickList for V3 tablet version
  2018/08/06  SV      pr_Picking_BatchPickResponse: Made changes to show remaining units for a task to pick in RF (OB2-492)
  2018/07/11  TK      pr_Picking_BatchPickResponse: Suggested units to pick from scanned task only (S2G-GoLive)
                      pr_Picking_BatchPickResponse: Made changes to get scan entity options from rules (S2G-474)
  2018/05/03  OK      pr_Picking_BatchPickResponse: Made changes to suggest in cases for unit picks based on the rules (S2G-688)
  2018/04/17  TK      pr_Picking_BatchPickResponse: Changes to suggest UnitsToPick properly (S2G-662)
  2018/04/10  RV      pr_Picking_BatchPickResponse: Bug fixed to show in cases units to pick quanity for case picks (S2G-616)
  2018/04/06  AY/RV   pr_Picking_BatchPickResponse: Made changes with respect to the picking configurations (S2G-579)
  2018/04/04  OK      pr_Picking_BatchPickResponse: Changes to use TaskDetailPickType instead of TaskSubType (S2G-569)
  2018/03/30  RV      pr_Picking_BatchPickResponse: Made changes to return xml node to whether do auto initialize for ToLPN (S2G-534)
  2018/03/21  RV      pr_Picking_BatchPickResponse: Made changes to determine the default value control (S2G-421)
  2016/07/30  TK      pr_Picking_BatchPickResponse & pr_Picking_ConfirmUnitPick: Changes made to return ToLPN based on the packing group (HPI-380)
  2016/05/08  TK      pr_Picking_BatchPickResponse: Enhanced to use rules to evaluate picking options (NBD-459)
  2016/04/07  OK      pr_Picking_BatchPickResponse: Added the code to Display the allocated/Reserved qty to user (NBD-327)
  2016/03/22  TK      pr_Picking_BatchPickResponse: If PickMode is Unit Scan Pick, then Quantity must be enabled irrespective of control variable (FB-631)
  2016/03/15  RV      pr_Picking_BatchPickResponse: We do not consider as Unit Pick if Units Per InnerPack is 1 and pick type is LPN (NBD-287)
  2016/03/21  TK      pr_Picking_BatchPickResponse: Pass empty string in case of null to avoid application crash (NBD-255)
  2015/12/24  RV      pr_Picking_BatchPickResponse: Corrected Confirm Empty Location flags Based upon the Task Sub Typ (FB-454)
  2015/12/08  TK      pr_Picking_BatchPickResponse: If the pick type is LPN Pick then, Default Qty must be LPN Qty and Qty input should be disabled (ACME-419)
  2015/11/20  RV      pr_Picking_BatchPickResponse: Check empty location popup required or not through control variable (FB-505)
  2015/10/16  RV      pr_Picking_BatchPickResponse: Modified to Display Units and LPNs while Pallet Pick (FB-440)
  2015/08/19  TK      pr_Picking_BatchPickResponse: Enable Pick to LPN & Pick Mode must be MultiScanPick if
  2015/08/06  TK      pr_Picking_BatchPickResponse: Changes made to display Total number of Units/InnerPacks required for the  SKU to
  2015/07/18  TK      pr_Picking_BatchPickResponse: Enhanced to use Wave specific control vars
  2015/07/17  DK      pr_Picking_BatchPickResponse: Enhanced to allow picking on Pallets(FB-226).
  2015/07/07  TK      pr_Picking_BatchPickResponse: Update UnitsToPick after calculating PickUoM.
  2015/07/02  SV      pr_Picking_BatchPickResponse: Enhancement for UnitScanPick in BatchPicking
  2015/07/01  TK      pr_Picking_BatchPickResponse: Suggest picks in Multiple of ShipPack first and then Eaches.
  2015/06/25  RV      pr_Picking_FindDropLocationAndZone: Separated code from pr_Picking_BatchPickResponse and called
  2015/06/07  AY/TK   pr_Picking_BatchPickResponse: Show the cart position to pick to for Unit Picks.
  2015/05/09  TK      pr_Picking_BatchPickResponse: DisplaySKU must be combination of Style, Color Desc, Size Desc
  2015/02/27  TK      pr_Picking_BatchPickResponse: Enhanced to suggest Drop Location for Bulk Batch based upon rules.
  2015/02/04  VM      pr_Picking_BatchPickResponse: Added more validations to calculate UnitsPerInnerPack
  2015/01/21  VM      pr_Picking_BatchPickResponse: Show ShipToId beside batch/cart/ (might be specific to SRI for now)
  2014/09/01  PK      pr_Picking_BatchPickResponse: Handling Packs.
                      pr_Picking_BatchPickResponse:sending DestZone,DestLocation to drop if the batch is manually done.
                      pr_Picking_BatchPickResponse:Changes to to set PickType based on the task subtype.
  2014/05/28  PK      pr_Picking_BatchPickResponse: Getting UnitsPerInnerPack from LPNDetails.
  2014/04/28  TD      pr_Picking_BatchPickResponse:Changes to pass pickzone if the from location is Picklane.
  2014/03/05  PK      pr_Picking_BatchPickResponse: Added PicksLeftForDisplay.
  2013/10/03  PK      pr_Picking_BatchPickResponse: Displaying UoM as Cases.
  2013/09/25  PK      pr_Picking_BatchPickResponse: Added TaskId and TaskDetailId
  2013/09/19  TD      pr_Picking_BatchPickResponse:Sending optional value to enable or disable picktoLPN.
  2013/09/19  PK      pr_Picking_BatchPickResponse: Changed the PickBatch Response XML nodes.
  2013/09/17  PK      pr_Picking_BatchPickResponse: Retrieving PickBatchNo from OrderDetails.
  2012/10/15  NY      pr_Picking_BatchPickResponse: Changed variables to show PickFrom pallet
  2012/10/10  PK      pr_Picking_BatchPickResponse: Returning QtyForDisplay, StyleColorSize.
  2012/10/03  VM      pr_Picking_BatchPickResponse: Performance improvements in showing LPNsToPick
                      pr_Picking_BatchPickResponse: Displaying NumLPNs to Pick from Location in RF.
  2012/08/28  PK      pr_Picking_BatchPickResponse: Migrated changes from LOEH for
  2012/08/17  PK      pr_Picking_BatchPickResponse: Modified to pass values for Pallet Picking as well
  2012/05/15  PK      pr_Picking_BatchPickResponse, pr_Picking_FindNextPickFromBatch: Migrated from FH related to LPN/Piece Pick.
  2012/02/01  VM      pr_Picking_BatchPickResponse: Enhanced to take BatchPicking options to return to caller.
  2011/10/18  PK      pr_Picking_BatchPickResponse : Added PickingZone and returning in XML
  2011/10/12  PK      pr_Picking_BatchPickResponse: Added UPC and Returning in xml,
  2011/08/26  PK      pr_Picking_BatchPickResponse, pr_Picking_FindNextPickFromBatch
  2011/08/04  DP      pr_Picking_BatchPickResponse: Added Procedure.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_BatchPickResponse') is not null
  drop Procedure pr_Picking_BatchPickResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_BatchPickResponse: This Procedure returns the details of the
    Pick to be issued from the Batch as an XML String.

  Parameters:
    LPNIdToPickFrom - LPNId of the LPN
    LPNToPickFrom   - LPN (why do we need both of these parms? LPNId is the unique
                      field that identifies the LPN that will be picked (LPN is
                      not unique, however in AX we do not have LPNId and so we
                      use LPN)

    PickType        - L for LPN, U for Units, P Pallets
                      PickType will be decide based on the task sub type here.
                      if the TaskSubType is LPN and if we generated the temp labels
                      then we need to consider that as UnitPick.
                      If the taskSubtype is Case / Units then we will decide that
                      as unit type pick.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_BatchPickResponse
  (@PickPallet      TPallet,
   @PalletIdToPick  TRecordId,
   @PalletToPick    TPallet,
   @LPNIdToPickFrom TRecordId,
   @LPNToPickFrom   TLPN,
   @LPNDetailId     TRecordId,
   @OrderDetailId   TRecordId,
   @UnitsToPick     TInteger,
   @LocToPickFrom   TLocation,
   @PickType        TLookUpCode,
   @PickGroup       TPickGroup,
   @TaskId          TRecordId,
   @TaskDetailId    TRecordId,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @xmlResult       xml        output)
as
  declare @PickingZone                           TZoneId,
          @LPNPallet                             TPallet,
          @ToLPN                                 TLPN,
          @vAlternateLPN                         TLPN,
          @vLPNType                              TTypecode,
          @vTempLabelId                          TRecordId,
          @vTempLabel                            TLPN,
          @PalletId                              TRecordId,
          @PalletSKUId                           TRecordId,
          @vPalletType                           TTypeCode,
          @NumLPNs                               TCount,
          @vPickToLPN                            TLPN,
          @vLPNTypeToPickFrom                    TTypeCode,
          @vLocationType                         TTypeCode,
          @vLocPickingZone                       TZoneId,
          @vLocPickZoneDesc                      TDescription,
          @vLocationInnerPacks                   TCount,
          @vLocationQuantity                     TQuantity,
          /* Order Header */
          @OrderId                               TRecordId,
          @ValidPickTicket                       TPickTicket,
          @PickBatchNo                           TPickBatchNo,
          @PickBatchId                           TRecordId,
          @UnitsAssigned                         TQuantity,
          @vBatchWarehouse                       TWarehouse,
          @BatchDropLoc                          TLocation,
          /* Order Detail and SKU */
          @vOrderDetailSKUId                     TRecordId,
          @vHostOrderLine                        THostOrderLine,
          @vLocIdtoPickFrom                      TRecordId,
          @vSKUIdToPick                          TRecordId,
          @vSKUToPick                            TSKU,
          @AlternateSKU                          TSKU,
          @SKU1                                  TSKU,
          @SKU2                                  TSKU,
          @SKU3                                  TSKU,
          @SKU4                                  TSKU,
          @SKU5                                  TSKU,
          @vSKUDesc1                             TDescription,
          @vSKUDesc2                             TDescription,
          @vSKUDesc3                             TDescription,
          @vSKUDesc4                             TDescription,
          @vSKUDesc5                             TDescription,
          @vSKUBarcode                           TBarcode,
          @UPC                                   TUPC,
          @CaseUPC                               TUPC,
          @UoM                                   TUoM,
          @vShipPack                             TInteger,
          @PickUoM                               TUoM,
          @vSKUDescription                       TDescription,
          @vDisplaySKU                           TSKU,
          @vDisplaySKUDesc                       TDescription,
          @vSKUImageURL                          TURL,
          @vStdPackQty                           TInteger,
          @vNumUnitsToAllocate                   TCount,
          @vNumUnitsInLocation                   TCount,
          @vTotalUnitsToPick                     TCount,
          @vTotalUnitsToPickForSKU               TCount,
          @vTotalUnitsToPickForToLPN             TCount,
          @UnitsPerInnerPack                     TInteger,
          @vNumLPNsToPick                        TCount,
          @vPackingGroup                         TCategory,
          /* DropPallet */
          @PickBatchRuleId                       TRecordId,
          @DestDropZone                          TZoneId,
          @DestDropLoc                           TLocation,
          /* Display */
          @vDisplayLPN                           TVarChar,
          @PickFromDisplay                       TVarChar,
          @BatchForDisplay                       TVarChar,
          @QtyForDisplay                         TVarChar,
          @vDisplayToPickQty                     TVarChar,
          @PicksLeftForDisplay                   TVarChar,
          @DefaultPicksLeftForDisplay            TVarChar,
          @TotalUnitsToPickForDisplay            TVarchar,
          @vBatchType                            TLookUpCode,
          @vShipToId                             TShipToId,
          @vBP_UDF1                              TUDF,
          @vBP_UDF2                              TUDF,
          @vBP_UDF3                              TUDF,
          @vBP_UDF4                              TUDF,
          @vBP_UDF5                              TUDF,
          @xmlBatchPickInfo                      TXML,
          @xmlOptions                            TXML,
          @xmlRulesData                          TXML,
          @vNumTaskLinesLeftToPick               TQuantity,
          @vNumTasksLeftToPick                   TQuantity,
          @vNumUnitsLeftToPick                   TQuantity,
          @vRemainingUnitsToPickForTask          TQuantity,
          @vPickEntityCaption                    TName,
          @vSuggPickToCaption                    TName,
          @vScanPickToCaption                    TName,
          @vConsolidatePickMode                  TControlValue,

          /* Picking Options */
          @vUnitsToPick                          TInteger,
          @vOrgUnitsToPick                       TInteger,
          @vControlCategory                      TCategory,
          @vDefaultQty                           TControlValue,
          @vQtyEnabled                           TControlValue,
          @vPickMode                             TControlValue,
          @vEnablePickToLPN                      TControlValue,
          @vEnableSingleScanSKU                  TControlValue,
          @vAutoInitializeToLPN                  TControlValue,
          @vForcePalletToDrop                    TControlValue,
          @vDisplayScreen                        TVarChar,
          @vPickBatchRuleId                      TRecordId,

          @vUseInnerPacks                        TFlag,
          /* general */
          @vGenerateTempLabel                    TControlValue,
          @vIsLabelGenerated                     TFlags,
          @vTaskSubType                          TTypeCode,
          @vTaskDetailPickType                   TTypeCode,
          /* Task Counts */
          @vTaskDetailCount                      TCount,
          @vTaskRemainingPicks                   TCount,
          @vTaskNumOrders                        TCount,
          @vTaskNumLocations                     TCount,
          @vTaskTotalInnerPacks                  TCount,
          @vTaskTotalUnits                       TCount,
          @vTaskRemainingInnerPacks              TCount,
          @vTaskRemainingUnits                   TCount,

          @vAllowPickMultipleSKUsintoLPN         TControlValue,
          @vDestZone                             TZoneId,
          @vPickMultiSKUCategory                 TCategory,
          @vConfirmEmptyLocation                 TFlags,
          @vConfirmScanOption                    TControlValue,
          @vMaskDisplayLPN                       TControlValue,
          @vMaskDisplaySKU                       TControlValue,
          @vPickPosition                         TLPN,
          @vIsCoORequired                        TFlag,
          @vUserRole                             TCategory,
          @vUserNameDisplay                      TName,
          @vXMLData                              TXML,
          @vxmlRulesData                         TXML,
          @xmlPickList                           TXML,
          @vPickListSummary                      TDescription,
          @vPickListRemaining                    TDescription,
          @vSuggestInCasesForUnitPicks           TControlValue;
begin /* pr_Picking_BatchPickResponse */
begin try
  /* set default to Yes - Y */
  select @vEnablePickToLPN      = 'Y' /* Yes */,
         @vUnitsToPick          = @UnitsToPick; /* do not ovverride parameter value */

  /* UserRole is required to use it in some rules (ex: pickingmode etc) */
  select @vUserRole        = R.RoleName,
         @vUserNameDisplay = U.UserName + ', ' + U.Name
  from Users U
    join UserRoles UR on (U.UserId  = UR.UserId)
    join Roles     R  on (UR.RoleId = R.RoleId)
  where (U.UserName = @UserId);

  /* Get the default PicksLeftForDisplay control variable*/
  select @DefaultPicksLeftForDisplay = dbo.fn_Controls_GetAsString('BatchPicking', 'PicksLeftForDisplay', 'TD'/* Task Details */, @BusinessUnit, @UserId),
       --@vUseInnerPacks             = dbo.fn_Controls_GetAsBoolean('System',  'UseInnerPacks',        'N' /* No */, @BusinessUnit, @UserId),
         @vConfirmEmptyLocation      = dbo.fn_Controls_GetAsBoolean('Picking', 'ConfirmEmptyLocation', 'N' /* No */, @BusinessUnit, @UserId);

  /* select LPN Information */
  if (@LPNIdToPickFrom is not null)
    select @LPNToPickFrom      = LPN,
           @LPNIdToPickFrom    = LPNId,
           @vLPNTypeToPickFrom = LPNType,
           @vLocIdtoPickFrom   = LocationId,
           @LocToPickFrom      = coalesce(Location, @LocToPickFrom),
           @PickingZone        = PickingZone,
           @LPNPallet          = Pallet,
           @UPC                = UPC
    from vwLPNs                       /* TODo: We have to create a view which returns few fields which are needed */
    where (LPNId = @LPNIdToPickFrom);

  /* get the LPNDetail info */
  if (@LPNDetailId is not null)
    select @UnitsPerInnerPack = UnitsPerPackage
    from LPNDetails
    where (LPNDetailId = @LPNDetailId);

  /* get Location type here */
  if (@vLocIdtoPickFrom is not null)
   select @vLocationType       = LocationType,
          @vLocPickingZone     = PickingZone,
          @vLocPickZoneDesc    = PickingZoneDisplayDesc,
          @vLocationInnerPacks = InnerPacks,
          @vLocationQuantity   = Quantity
   from vwLocations
   where (LocationId = @vLocIdtoPickFrom);

  /* select Pallet Information */
  if (@PalletIdToPick is not null)
    select @PalletToPick     = Pallet,
           @PalletIdToPick   = PalletId,
           @PickBatchNo      = PickBatchNo,
           @PickBatchId      = PickBatchId,
           @vLocIdtoPickFrom = coalesce(@vLocIdtoPickFrom, LocationId),
           @LocToPickFrom    = coalesce(@LocToPickFrom, Location),
           @PickingZone      = PickingZone,
           @vSKUIdToPick     = SKUId,
           @vSKUToPick       = SKU,
           @SKU1             = SKU1,
           @SKU2             = SKU2,
           @SKU3             = SKU3,
           @SKU4             = SKU4,
           @SKU5             = SKU5,
           @UPC              = UPC,
           @vSKUDescription  = SKUDescription,
           @vUnitsToPick     = Quantity,
           @NumLPNs          = NumLPNs
    from vwPallets
    where (PalletId = @PalletIdToPick);

  /* select PickTicket Line Information */
  if (@OrderDetailId is not null)
    select @OrderDetailId     = OrderDetailId,
           @OrderId           = OrderId,
           @UnitsAssigned     = UnitsAssigned,
           @vHostOrderLine    = HostOrderLine,
           @PickBatchNo       = PickBatchNo,
           /* select SKU Information */
           @vSKUIdToPick      = SKUId,
           @vSKUToPick        = SKU,
           @SKU1              = SKU1,
           @SKU2              = SKU2,
           @SKU3              = SKU3,
           @SKU4              = SKU4,
           @SKU5              = SKU5,
           @vSKUDescription   = SKUDesc,
           @vOrderDetailSKUId = SKUId,
           @vPackingGroup     = PackingGroup
    from vwOrderDetails
    where (OrderDetailId = @OrderDetailId);

   /* If the inventory allocated partially then we should display allocated/available qty to user ,
      need to get all avaible qty to pick for the given order */
  if (@vLPNTypeToPickFrom <> 'L')
    select @vUnitsToPick  = coalesce(LD.Quantity, @UnitsToPick)
    from LPNDetails LD
      join TaskDetails TD on (LD.LPNDetailId = TD.LPNDetailId)
    where (LD.LPNId         = @LPNIdToPickFrom) and
          (LD.OrderDetailId = @OrderDetailId) and
          (LD.OnhandStatus  = 'R' /* Reserved */) and
          (TD.TaskDetailId  = @TaskDetailId);
  else
    select @vUnitsToPick  = sum(TD.UnitsToPick)
    from LPNDetails LD
      join TaskDetails TD on (LD.LPNDetailId = TD.LPNDetailId)
    where (LD.LPNId         = @LPNIdToPickFrom) and
          (LD.OrderId       = @OrderId) and
          (LD.OnhandStatus  = 'R' /* Reserved */) and
          (TD.TaskDetailId  = @TaskDetailId);

  /* select PickTicket Information */
  if (@OrderId is not null)
    select @ValidPickTicket = PickTicket,
           @PickBatchNo     = coalesce(PickBatchNo, @PickBatchNo)
    from OrderHeaders
    where (OrderId = @OrderId);

  /* Whether we have a PickBatchNo or PickBatchId, we need to get Batch info */
  --if (@PickBatchNo is null)
    select @PickBatchId      = RecordId,
           @PickBatchNo      = BatchNo,
           @vPickBatchRuleId = RuleId,
           @vBatchType       = BatchType,
           @vShipToId        = ShipToId,
           @BatchDropLoc     = DropLocation,
           @vBP_UDF1         = UDF1,
           @vBP_UDF2         = UDF2,
           @vBP_UDF3         = UDF3,
           @vBP_UDF4         = UDF4,
           @vBP_UDF5         = UDF5,
           @vBatchWarehouse  = Warehouse
    from PickBatches
    where (RecordId = @PickBatchId) or (BatchNo = @PickBatchNo);

  /* select PalletId  */
  if (@PickPallet is not null)
    select @PalletId    = PalletId,
           @vPalletType = PalletType
    from Pallets
    where (Pallet = @PickPallet);

  /* we will be doing this while we are about to drop Pallet, this will be taken care in RFC_Picking_ValidatePallet */
  /* we don't need to evaluate Drop Location for every pick, we need to do that for last pick only */

  /* Get the SKU Info */
  select  @UPC               = coalesce(UPC, SKU),
          @CaseUPC           = coalesce(rtrim(ltrim(CaseUPC)), ''),
          @UoM               = coalesce(UoM,  ''),
          @AlternateSKU      = coalesce(AlternateSKU, ''),
          @vSKUBarcode       = coalesce(Barcode, ''),
          @SKU2              = SKU2,
          @vSKUDesc4         = SKU4Description,
          @vSKUDesc5         = SKU5Description,
          @UnitsPerInnerPack = coalesce(@UnitsPerInnerPack, nullif(UnitsPerInnerPack, 0), 1) /* If null or zero, make it 1 to avoid div by zero errors */,
          @vShipPack         = ShipPack,
          @vSKUImageURL      = SKUImageURL
  from SKUs
  where (SKUId = @vSKUIdToPick);

  /* If is a wave with 6 orders in it. And there is a SKU1 which is in all 6 orders and 2 units per order, so the total units to be picked
     into the cart are 12 then we would want to display Total units to be picked from that LPN in the Location for the SKU in RF so that user will
     bring all 12 units to the cart and then they will start scanning each item into the cart-positions as usually.  */
  /* Pre-condition: Each Task would be associated with once Cart */
  select @vTotalUnitsToPickForSKU = sum(TD.UnitsToPick)
  from TaskDetails TD
  where (TD.TaskId = @TaskId         ) and
        (TD.SKUId  = @vSKUIdToPick   ) and
        (TD.LPNId  = @LPNIdToPickFrom) and
        (TD.Status not in ('C' /* Completed */, 'X' /* Cancelled */))

  /* When user needs to pick an item from a Location, instead of scaning each time going to location, user could scan Total UnitsPick
     for Example: In case of Order having Multiple OrderDetails with same SKU, then multiple TaskDetails get created for each OrderDetails
     Instead of scanning each TaskDetail, get the Total UnitsToPick quantity to scan and pick at once */
  select @vTotalUnitsToPickForToLPN = sum(TD.UnitsToPick)
  from TaskDetails TD
  where (TD.TaskId  = @TaskId         ) and
        (TD.SKUId   = @vSKUIdToPick   ) and
        (TD.LPNId   = @LPNIdToPickFrom) and
        (TD.OrderId = @OrderId        ) and
        (coalesce(TD.TempLabel, '') = coalesce(@vTempLabel, TD.TempLabel, '')) and
        (TD.Status not in ('C' /* Completed */, 'X' /* Cancelled */))

  /* Get Num Tasks, Num Units left to pick for the batch */
  select @vNumTasksLeftToPick = count(T.TaskId),
         @vNumUnitsLeftToPick = (sum(TD.Quantity) - sum(coalesce(TD.UnitsCompleted, 0)))
  from Tasks T
    join TaskDetails TD on (T.TaskId  = TD.TaskId) and
                           (TD.Status not in ('C'/* Completed */, 'X' /* Cancelled */))
  where (T.BatchNo  = @PickBatchNo) and
        (T.TaskType = 'PB'/* Pick Batch */) and
        (T.Status not in ('C' /* Completed */, 'X' /* Cancelled */));

  /* Get the SKU, Desc to display */
  select @vDisplaySKU     = DisplaySKU,
         @vDisplaySKUDesc = DisplaySKUDesc
  from dbo.fn_SKUs_GetDisplaySKU(@vSKUToPick, 'BatchPicking', @BusinessUnit, @UserId);

  /* Get details from taskdetails here */
  select @vIsLabelGenerated   = IsLabelGenerated,
         @vTempLabelId        = TempLabelId,
         @vTempLabel          = TempLabel,
         @vPickPosition       = PickPosition,
         @vTaskDetailPickType = PickType
  from TaskDetails
  where TaskDetailId = @TaskDetailId;

  /* Get Task Sub Type */
  select @vTaskSubType             = TaskSubType,
         @vDestZone                = DestZone,
         @vPickMultiSKUCategory    = 'PickMultiSKUIntoSameTote_' + coalesce(DestZone, ''),
         @vTaskDetailCount         = DetailCount,
         @vTaskRemainingPicks      = DetailCount - CompletedCount,
         @vTaskNumOrders           = NumOrders,
         @vTaskNumLocations        = NumLocations,
         @vTaskTotalInnerPacks     = TotalInnerPacks,
         @vTaskTotalUnits          = TotalUnits,
         @vTaskRemainingInnerPacks = TotalIPsRemaining,
         @vTaskRemainingUnits      = TotalUnitsRemaining
  from Tasks
  where (TaskId = @TaskId);

  /* Get Num task Lines left to pick for the task.
     Fetch sum(UnitsToPick) other than the current and open picks. */
  -- select @vNumTaskLinesLeftToPick      = count(*),
  --        @vRemainingUnitsToPickForTask = sum(UnitsToPick)
  -- from TaskDetails
  -- where (TaskId = @TaskId) and
  --       (TaskDetailId <> @TaskDetailId) and
  --       (Status not in ('C' /* Completed */, 'X' /* Cancelled */));

  /* Excluding the current task detail, may want to show how many more are remaining
     This is used in V2 only */
  select @vNumTaskLinesLeftToPick      = @vTaskRemainingPicks - 1,
         @vRemainingUnitsToPickForTask = @vTaskRemainingUnits - @vUnitsToPick;

  /* select control option now tp confirm scan from -- location/SKU/UPC/LPN  */
  /* L- LPN, S- SKU, O- Location, U-UPC */
  select @vMaskDisplayLPN    = dbo.fn_Controls_GetAsString('BatchPicking', 'MaskPickFromLPN', 'Y',
                                                            @BusinessUnit, @UserId),
         @vMaskDisplaySKU    = dbo.fn_Controls_GetAsString('BatchPicking', 'MaskPickSKU', 'Y',
                                                            @BusinessUnit, @UserId);

  /* if the tasksub type is case then we need to show the next templabel to pick */
  if (@vTaskDetailPickType = 'CS' /* Cases */)
    select top 1 @ToLPN = LPN
    from vwLPNTasks
    where (TaskDetailId = @TaskDetailId) and
          (Status in ('F', 'U' /* NewTemp, Picking */))
    order by TaskDetailId, LPN;
  else
  /* If Unit pick task and labels were generated, then pick to the Cart Position associated
     with the LPN */
  /* We are not inserting LPNDetailId and TaskDetilId into LPNTasks hence use Task Details */
  if (@vTaskDetailPickType = 'U' /* Units */) and
     (@vIsLabelGenerated = 'Y') and
     (@vTempLabel is not null)
    begin
      select top 1 @ToLPN = coalesce(L.AlternateLPN, L.LPN)
      from LPNTasks LT
        join LPNs L on LT.LPNId = L.LPNId
        join TaskDetails TD on LT.TaskDetailId = TD.TaskDetailId
      where (TD.TaskDetailId = @TaskDetailId);
    end
  else
    begin
      /* Get the control value to pick the multiple SKUs into single tote or not */
      select @vAllowPickMultipleSKUsintoLPN = dbo.fn_Controls_GetAsString('BatchPicking', @vPickMultiSKUCategory, 'Y'/* Default -Y */,
                                                                          @BusinessUnit, @UserId);

      /* Find the LPN (Position) on the Pallet (Cart) where this Order is.
         If there are multiple LPNs(Positions) where the Order is, then we would
         want to find the one that has the least quantity */
      /* if the task destination is PTL then we need to allow them to pick same sku into one temp label */
      if (@LPNToPickFrom is not null)
        select top 1 @ToLPN = LPN
        from LPNs
        where ((PalletId = @PalletId) and
               (OrderId = @OrderId) and
               (PackingGroup = @vPackingGroup) and
               ((@vAllowPickMultipleSKUsintoLPN = 'Y' /* Yes */) or (SKUId = @vSKUIdToPick)) and
               (LPNType = 'A' /* Cart */ or Status = 'U' /* Picking */)
              )
        order by ModifiedDate desc;

      /* If picking to a tote, but that tote is in a Cart, then suggest the Cart position
         If using Cart position, only display the position, i.e. chars past the - */
      if (@vLPNType = 'TO' /* Tote */) and (coalesce(@vAlternateLPN, '') <> '')
        select @ToLPN = substring(@vAlternateLPN, charindex('-', @vAlternateLPN)+1, len(@vAlternateLPN))
      else
      if (@vLPNType = 'A' /* Cart Position */)
        select @ToLPN = substring(@ToLPN, charindex('-', @ToLPN)+1, len(@ToLPN))
    end

  /* Build xml to evaluate Rules */
  select @vxmlRulesData = dbo.fn_XMLNode('RootNode',
                              dbo.fn_XMLNode('FromLocationType',     @vLocationtype  ) +
                              dbo.fn_XMLNode('WaveType',             @vBatchType  ) +
                              dbo.fn_XMLNode('OrderId',              @OrderId) +
                              dbo.fn_XMLNode('TaskType',             @vTaskSubType) +
                              dbo.fn_XMLNode('TaskDetailPickType',   @vTaskDetailPickType) + --Need enhance rules to use TaskDetailPickType
                              dbo.fn_XMLNode('PalletType',           @vPalletType ) +
                              dbo.fn_XMLNode('PickZone',             @vLocPickingZone) +
                              dbo.fn_XMLNode('UserId',               @UserId ) +
                              dbo.fn_XMLNode('UserRole',             @vUserRole));

  exec pr_RuleSets_Evaluate 'PickingConfigurations', @vxmlRulesData, @vControlCategory output;
  exec pr_RuleSets_Evaluate 'PickingScanEntityOption', @vxmlRulesData, @vConfirmScanOption output;
  exec pr_RuleSets_Evaluate 'PickInCasesFromUnitStorage', @vxmlRulesData, @vSuggestInCasesForUnitPicks output;

  /* For CID international orders @vIsCoORequired will be always 'Y' */
  exec pr_RuleSets_Evaluate 'Picking_CoOConfirmations', @vxmlRulesData, @vIsCoORequired output;

  /* We are reading/ovverriding the UnitsToPick value in multiple places above. hence copy the final value here */
  select @vOrgUnitsToPick = @vUnitsToPick;

  /* Adding both Location and Zone to display in RF
     PickFrom can be a Location or Location/LPN */
  select @PickFromDisplay = case
                              when (coalesce(@LPNToPickFrom, '') = '') then
                                @LocToPickFrom
                              when (@PalletToPick is not null) then
                                @LocToPickFrom + coalesce('/' + @PalletToPick, '')
                              else
                                @LocToPickFrom + coalesce('/' + @LPNPallet, '')
                            end,
         @BatchForDisplay = @PickBatchNo + coalesce('/' + @PickPallet, '') + coalesce('/' + @vShipToId, ''),
         @vUnitsToPick    = case
                              when (@vTaskDetailPickType = 'U'/* Units */) and ((@vShipPack > 1) and (@vUnitsToPick / @vShipPack) > 0) then
                                (@vUnitsToPick / @vShipPack)
                              /* If UnitToPick value is greater than the UnitsPerInnerPack then pick in cases */
                              when (@vSuggestInCasesForUnitPicks = 'Y') and (@UnitsPerInnerPack > 0) and (@vUnitsToPick >= @UnitsPerInnerPack) then
                                floor(@vUnitsToPick/@UnitsPerInnerPack)
                              when (@vTaskDetailPickType = 'U') or (@UnitsPerInnerPack = 0) or (@vUnitsToPick < @UnitsPerInnerPack) then
                                @vUnitsToPick
                              else
                                (@vUnitsToPick / @UnitsPerInnerPack)
                            end,
         @QtyForDisplay   = case
                              when (@vTaskDetailPickType = 'P' /* Pallets */) then
                                cast(@vUnitsToPick as varchar(20)) + coalesce('/' + cast(@NumLPNs as varchar(20)), '')
                              when (@vTaskDetailPickType = 'U'/* Units */) and ((@vShipPack > 1) and (@vUnitsToPick / @vShipPack) > 0) then
                                convert(varchar(max), @vUnitsToPick) + ' IP (' + cast(@vShipPack as varchar) + ' EA/IP)' + ', T:' + (cast(@vTotalUnitsToPickForSKU / @vShipPack as varchar)) + ' IP'
                              when (@UnitsPerInnerPack > 1) and (@vSuggestInCasesForUnitPicks = 'Y') and (@vOrgUnitsToPick >= @UnitsPerInnerPack) then
                                convert(varchar(max), @vUnitsToPick) + ' CS '+ '(' + convert(varchar(max), @vUnitsToPick * @UnitsPerInnerPack) + ' EA)'
                              when ((@UnitsPerInnerPack = 1) or (@vTaskDetailPickType = 'U')) then
                                convert(varchar(max), @vUnitsToPick) + ' EA' + coalesce(', (' +  'T/R:' + (cast(@vTotalUnitsToPickForSKU as varchar) + '/' + cast(@vRemainingUnitsToPickForTask as varchar)) + ')', '')
                              when (@UnitsPerInnerPack > 1) then
                                convert(varchar(max), @vUnitsToPick) + ' CS '+ '(' + convert(varchar(max), @vUnitsToPick * @UnitsPerInnerPack) + ' EA)'
                              else
                                cast(@vUnitsToPick as varchar(20)) + coalesce('/' + cast(@NumLPNs as varchar(20)), '')
                            end,
         @vDisplayToPickQty = case when ((@UnitsPerInnerPack = 0) or (@vTaskDetailPickType = 'U')) then
                                     convert(varchar(max), @vUnitsToPick) + ' EA'
                                   when ((@UnitsPerInnerPack > 0) or (@vTaskDetailPickType = 'CS')) then
                                     convert(varchar(max), @vUnitsToPick) + ' CS'
                                   else
                                     convert(varchar(max), @vUnitsToPick) + ' EA'
                              end,
         @PickUoM         = case
                              when (@vTaskDetailPickType = 'U'/* Units */) and ((@vShipPack > 1) and (@UnitsToPick / @vShipPack) > 0)
                                then 'IP'
                              when ((@UnitsPerInnerPack > 1) and (@vTaskDetailPickType <> 'U'))
                                then 'CS'
                              when  ((@vSuggestInCasesForUnitPicks = 'Y') and (@UnitsPerInnerPack > 0) and (@vOrgUnitsToPick >= @UnitsPerInnerPack))
                                then 'CS'
                              else 'EA'
                            end,
         @PickType        = case
                              when (@PalletToPick is not null) then
                                coalesce(@PickType, 'P'/* Pallet Pick */)
                              when (@vTaskDetailPickType  in ('U', 'CS' /* units, Cases */)) then
                                'U' /* Unit Pick */
                              when (@vIsLabelGenerated = 'Y' /* yes */) and (@vTaskDetailPickType = 'L' /* LPN */) then
                                'U'
                              /* We are not sure why the logic earlier was that if UnitsPerInnerPack = 1 then it is a unit Pick.
                                 This causes problems when Picking LPNs as on RF user would be prompted to scan the units and scan a To LPN
                                 both of which are not required for LPN Picks. Not knowing why this was there to begin with, I decided
                                 to leave the condition as is and just exclude it when PickType = LPN */
                              when (@UnitsPerInnerPack = 1) and (@PickType <> 'L' /* LPN */) then
                                'U' /* Unit Pick */
                              else
                                coalesce(@PickType, 'U'/* Unit Pick */)
                            end,
         @DestDropZone    = coalesce(@DestDropZone + '-', ''),
         @PicksLeftForDisplay
                          = case when (@DefaultPicksLeftForDisplay = 'T' /* Tasks */) then
                                   cast(coalesce(@vNumTasksLeftToPick, 0) as varchar(max)) + ' - T'
                                 when (@DefaultPicksLeftForDisplay = 'TD' /* Task Details */) then
                                   cast(coalesce(@vNumTaskLinesLeftToPick, 0)  as varchar(max)) + ' - TD'
                                 when (@DefaultPicksLeftForDisplay = 'U' /* Units */) then
                                   cast(coalesce(@vNumUnitsLeftToPick, 0) as varchar(max)) + ' - U'
                                 when (@DefaultPicksLeftForDisplay = 'TTDU' /* Tasks, TaskDetails and Units */) then
                                   (cast(coalesce(@vNumTasksLeftToPick, 0) as varchar(max)) + ' - T' + '/ ' +
                                    cast(coalesce(@vNumTaskLinesLeftToPick, 0) as varchar(max)) + ' - TD' + '/ ' +
                                    cast(coalesce(@vNumUnitsLeftToPick, 0) as varchar(max)) + ' - U')
                            end,
         @TotalUnitsToPickForDisplay
                          = convert(varchar(max), @vTotalUnitsToPickForToLPN) + ' EA',
         @vForcePalletToDrop = 'Y'; /* By default,force, but could be overwritten by responsed in RFC_Picking_ValidatePallet */

  /* select display SKU and LPN here
  if we need to show mask LPN (vMaskDisplayLPN = 'Y') then we will send *** */
  select @vDisplayLPN        = case
                                 when @vMaskDisplayLPN = 'Y' and (dbo.fn_Permissions_IsAllowed(@UserId, 'RFUnMaskPick') <> '1' /* 1 - True, 0 - False */) then '********'
                                 when @vLocationType <> 'K' /* Picklane */  then @LPNToPickFrom + coalesce(' / ' + @LPNPallet, '')
                                 else @PickFromDisplay
                               end,
         @vDisplaySKU        = case
                                 when @vMaskDisplaySKU = 'Y' and (dbo.fn_Permissions_IsAllowed(@UserId, 'RFUnMaskPick') <> '1' /* 1 - True, 0 - False */) then '********'
                                 else @vDisplaySKU
                               end;

  /* Get the count of LPNs to pick from the Location for the particular SKU */
  /*
  select @vNumLPNsToPick = count(distinct(LPNId))
  from vwPickDetails
  where (PickBatchNo = @PickBatchNo) and
        (Location    = @LocToPickFrom) and
        (SKU         = @vSKUToPick);
  */

 /* Get the count of the particular SKU needed for the Batch */
  select @vNumUnitsToAllocate = sum(UnitsToAllocate),
         @vStdPackQty         = min(OD.UnitsPerCarton)
  from OrderHeaders OH
    join OrderDetails OD on (OH.OrderId = OD.OrderId)
  where (OH.PickBatchNo = @PickBatchNo) and
        (OD.SKUId       = @vSKUIdToPick);

  /* The current Pallet/Location has X units, so the TotalUnitsToPick will be
     the minimum of Units in Location of this SKU or UnitsToAllocate.
     Also, if UoM is EA, we need to divide by StdPackQty */
  select @vNumUnitsInLocation = sum(L.Quantity)
  from LPNs L
    join LPNDetails LD  on (LD.LPNId = L.LPNId) and (LD.SKUId = @vSKUIdToPick) and (LD.OnhandStatus = 'A' /* Available */)
  where (L.LocationId    = @vLocIdtoPickFrom)  and
        (L.OnhandStatus  = 'A' /* Available */);

  select @vTotalUnitsToPick     = case
                                    when (@vNumUnitsInLocation <= @vNumUnitsToAllocate) then
                                      @vNumUnitsInLocation
                                    else
                                      @vNumUnitsToAllocate
                                  end,
         @vNumLPNsToPick        = case
                                    when (@UoM = 'EA') then
                                      @vTotalUnitsToPick /  coalesce(nullif(@vStdPackQty,0),1)
                                    else
                                      @vTotalUnitsToPick
                                  end,
         @vConfirmEmptyLocation = case
                                    when (@vTaskDetailPickType in ('U' /* Units */, 'L' /* LPNs */, 'P' /* Pallets */)) and (@vLocationQuantity = @UnitsToPick) and (@vConfirmEmptyLocation = 'Y' /* Yes */) then
                                      'Y' /* Yes */
                                    when (@vTaskDetailPickType = 'CS'/* Case Pick */) and (@vLocationInnerPacks = @UnitsToPick) and (@vConfirmEmptyLocation = 'Y' /* Yes */) then
                                      'Y'
                                    else
                                      'N'
                                  end;

  /* If location type is Picklane thne we need to show pickzone instead of LPN */
  select @vPickToLPN         = coalesce(@ToLPN, 'New Temp Label'),
         /* We would compare this value in ConfirmBatch Picking controller, so coalesce to empty value
            to avoid application crash */
         @LPNToPickFrom      = case
                                 when @vLocationtype = 'K' /* picklane */ then
                                   coalesce(@vLocPickZoneDesc, '')
                                 else
                                   @LPNToPickFrom
                               end,
         @vPickEntityCaption = case
                                 when @vLocationtype = 'K' /* picklane */ then
                                   'Loc / SKU: '
                                 else
                                   'LPN: '
                               end,
         @vSuggPickToCaption = case
                                 when @vTaskSubType = 'U' then 'Pick To:'
                                 else 'Next Label:'
                               end,
         @vScanPickToCaption = case
                                 when @vTaskSubType = 'U' then 'Tote/LPN:'
                                 else 'Pick Carton:'
                               end,
         @vPickPosition      = case
                                 when (@vPickPosition is not null) then
                                   @vPickPosition
                                 else
                                   @ToLPN
                               end

  select @vPickEntityCaption = dbo.fn_Controls_GetAsString(@vControlCategory, 'PickEntityCaption', @vPickEntityCaption, @BusinessUnit, @UserId),
         @vSuggPickToCaption = dbo.fn_Controls_GetAsString(@vControlCategory, 'SuggPickToCaption', @vSuggPickToCaption, @BusinessUnit, @UserId),
         @vScanPickToCaption = dbo.fn_Controls_GetAsString(@vControlCategory, 'ScanPickToCaption', @vScanPickToCaption, @BusinessUnit, @UserId);

  /* Form the summary info to display underneath the listing */
  select @vPickListSummary   = case when (@vTaskDetailPickType = 'CS') then
                                 dbo.fn_Messages_Build('Picking_PickListSummary_Cases', @vTaskDetailCount,
                                                       @vTaskNumLocations, @vTaskTotalInnerPacks,
                                                       @vTaskTotalUnits, @vTaskNumOrders)
                               else
                                 dbo.fn_Messages_Build('Picking_PickListSummary', count(*),
                                                       @vTaskNumLocations, @vTaskTotalInnerPacks,
                                                       @vTaskTotalUnits, @vTaskNumOrders)
                               end,
         @vPickListRemaining = case when (@vTaskDetailPickType = 'CS') then
                                 dbo.fn_Messages_Build('Picking_PickListRemaining_Cases',
                                                       @vTaskRemainingPicks, @vTaskRemainingInnerPacks, @vTaskRemainingUnits, null, null)
                               else
                                 dbo.fn_Messages_Build('Picking_PickListRemaining',
                                                       @vTaskRemainingPicks, @vTaskRemainingInnerPacks, @vTaskRemainingUnits, null, null)
                               end;

  /* TotalUnitsToPickForToLPN is total quantity against a SKU from same Location into the same ToLPN.
     When the TotalUnitsToPick of ToLPN is more than UnitsToPick of a TaskDetail then suggest to user
     to pick all at once instead of picking each task Detail */
  select @vConsolidatePickMode = iif (@vTotalUnitsToPickForToLPN > @UnitsToPick, 'Consolidated', 'TaskDetail');

  set @xmlBatchPickInfo =  (select @ValidPickTicket    as PickTicket,
                                   @OrderId            as OrderId,
                                   @OrderDetailId      as OrderDetailId,
                                   /* Pick Batch */
                                   @PickBatchNo        as BatchNo,
                                   @PickBatchNo        as WaveNo,
                                   @BatchForDisplay    as DisplayBatchNo,
                                   @vBatchType         as BatchType,
                                   @DestDropZone       as DestDropZone,
                                   @DestDropLoc        as DestDropLocation,
                                   @vForcePalletToDrop as ForcePalletToDrop,
                                   /* Pallet */
                                   @PalletToPick       as Pallet,
                                   @PalletIdToPick     as PalletId,
                                   @NumLPNs            as NumLPNsOnPallet,
                                   /* LPN */
                                   @vDisplayLPN        as DisplayLPN,
                                   @LPNToPickFrom      as LPN,
                                   @LPNIdToPickFrom    as LPNId,
                                   @LPNDetailId        as LPNDetailId,
                                   coalesce(@LPNPallet, @LPNToPickFrom)
                                                       as LPNPallet,
                                   /* Consolidated Pick */
                                   @vTotalUnitsToPickForToLPN as ConsolidatedUnitsToPick,
                                   @TotalUnitsToPickForDisplay as ConsolidatedUnitsToPickDisplay,
                                   @vConsolidatePickMode      as PickMode,
                                   /* Location */
                                   @LocToPickFrom      as Location,
                                   @PickFromDisplay    as PickFromDisplay,
                                   @PickingZone        as PickZone,
                                   @vLocPickZoneDesc   as PickZoneDesc,
                                   @vLocationType      as LocationType,
                                   /* SKU */
                                   @vDisplaySKU        as DisplaySKU,
                                   @vDisplaySKUDesc    as DisplaySKUDesc,
                                   @vSKUDesc1          as DisplaySKUDesc2, -- for HA, temp change
                                   @PickUoM            as PickUoM,
                                   @UoM                as DisplayUoM,
                                   @vSKUToPick         as SKU,
                                   @UPC                as UPC,
                                   @CaseUPC            as CaseUPC,
                                   @SKU1               as SKU1,
                                   @SKU2               as SKU2,
                                   @SKU3               as SKU3,
                                   @SKU4               as SKU4,
                                   @SKU5               as SKU5,
                                   @vSKUDesc1          as SKUDesc1,
                                   @vSKUDesc2          as SKUDesc2,
                                   @vSKUDesc3          as SKUDesc3,
                                   @vSKUDesc4          as SKUDesc4,
                                   @vSKUDesc5          as SKUDesc5,
                                   @AlternateSKU       as AlternateSKU,
                                   @vSKUBarcode        as Barcode,
                                   @vSKUImageURL       as SKUImageURL,
                                   /* Pick info: Qty, Pick Type etc. */
                                   @vUnitsToPick       as TotalUnitsToPick, -- Units to pick for the current task detail
                                   @vNumLPNsToPick     as TotalLPNsToPick,
                                   @PicksLeftForDisplay
                                                       as PicksLeftForDisplay,
                                   @QtyForDisplay      as DisplayQty,
                                   @vDisplayToPickQty  as DisplayToPickQty,
                                   coalesce(@ToLPN, @vPickPosition)
                                                       as PickToLPN,
                                   @PickType           as PickType,
                                   @PickPallet         as PickToPallet,
                                   /* UDFs */
                                   @vBP_UDF1           as BP_UDF1,
                                   @vBP_UDF2           as BP_UDF2,
                                   @vBP_UDF3           as BP_UDF3,
                                   @vBP_UDF4           as BP_UDF4,
                                   @vBP_UDF5           as BP_UDF5,
                                   /* Pick Task Info */
                                   @TaskId             as TaskId,
                                   @TaskDetailId       as TaskDetailId,
                                   @vTaskSubType       as TaskSubType,
                                   @PickGroup          as PickGroup,
                                   @vPickListSummary + ', '+ @vPickListRemaining
                                                       as PickListSummary,
                                   @vTaskNumOrders     as TaskNumOrders,
                                   @vTempLabel         as TempLabel,
                                   /* Display Info */
                                   @vPickEntityCaption as PickEntityCaption,
                                   @vSuggPickToCaption as SuggPickToCaption,
                                   @vScanPickToCaption as ScanPickToCaption,
                                   @vConfirmEmptyLocation
                                                       as LocationEmpty,
                                   @vConfirmScanOption
                                                       as ConfirmScanOption,
                                   @vUserNameDisplay   as UserNameDisplay,
                                   /* Future */
                                   @vDisplayScreen     as DisplayScreen
                            FOR XML raw('BATCHPICKINFO'), elements );

  /* Build Pick List */
  select @xmlPickList = (select top 30
                                case when min(LOC.LocationType) = 'K' then min(L.Location)        -- picking from picklane
                                     --when min(TD.PickType) = 'L' then L.LPN                -- for LPN Pick, just show LPN
                                     else coalesce(min(L.Location) + ' / ', '') + L.LPN    -- for LPN Pick,case/unit picking from Reserve/Bulk, show Location/LPN
                                end                                         Location, /* Need to show the PickList info by LPN */
                                min(LOC.PickingZone)                        PickZone,
                                S.SKU                                       SKU,
                                min(dbo.fn_AppendStrings(S.Description, ' / ', L.InventoryClass1))
                                                                            SKUDesc,
                                count(*)                                    NumPicks,
                                sum(TD.InnerPacks)                          TotaLIPs,
                                sum(TD.Quantity)                            TotalQty,
                                sum(TD.InnerPacksToPick)                    InnerPacksToPick,
                                nullif(sum(TD.UnitsToPick), 0)              UnitsToPick
                         from TaskDetails TD
                           join SKUs S on TD.SKUId = S.SKUId
                           join LPNs L on TD.LPNId = L.LPNId
                           join Locations LOC on TD.locationId = LOC.LocationId
                         where (TD.TaskId = @TaskId) and
                               (TD.Status not in ('C', 'X' /* Cancelled */))
                         group by LOC.PickPath, L.LPN, S.SKUSortOrder, S.SKU
                         order by LOC.PickPath, L.LPN, S.SKUSortOrder, S.SKU
                         for xml raw('PICKLISTDTL'), elements, root('PICKLIST'));

  /* Fetching ControlValues as string and storing it in another xml variable 'xmlOptions'*/
  -- select @vControlCategory = 'BatchPicking_'  + @vBatchType;
  select @vDefaultQty = dbo.fn_Controls_GetAsString(@vControlCategory, 'DefaultQty', '1', @BusinessUnit, @UserId),
         @vQtyEnabled = dbo.fn_Controls_GetAsString(@vControlCategory, 'QtyEnabled', 'N', @BusinessUnit, @UserId),
         /* For ACME, the @vPickMode should be MultiScanPick and for others it should be UnitScanPick
            UnitScanPick : User scans the suggested SKU only once and pick the required qty at a time.
                           It is the process which are following currently
            MultiScanPick : User scans the suggested SKU as many times as the required qty.
                            This is specific to ACME */
         @vPickMode   = dbo.fn_Controls_GetAsString(@vControlCategory, 'PickMode', 'UnitScanPick', @BusinessUnit, @UserId),
         @vEnablePickToLPN = dbo.fn_Controls_GetAsString(@vControlCategory, 'EnablePickToLPN', 'Y', @BusinessUnit, @UserId),
         /* No clue what the below is for - retaining for a future cleanup */
         @vEnableSingleScanSKU = dbo.fn_Controls_GetAsString(@vControlCategory, 'EnableSKUSingleScan', 'N', @BusinessUnit, @UserId),
         @vAutoInitializeToLPN = dbo.fn_Controls_GetAsString(@vControlCategory, 'AutoInitializeToLPN', 'N' /* No */, @BusinessUnit, @UserId);

  /* If configuration says that the default qty should be UnitsToPick, then we should set it accordingly */
  if (@vDefaultQty = 'UnitsToPick' /* Units To Pick */)
    select @vDefaultQty = coalesce(@vUnitsToPick, @UnitsToPick);
  else
  if (@vDefaultQty = 'PickQty')
    select @vDefaultQty = @UnitsToPick;

  /* 4. Get Options from Controls */
  set @xmlOptions = (select @vDefaultQty          as DefaultQuantity,
                            @vQtyEnabled          as QuantityEnabled,
                            @vPickMode            as PickingMode,  -- The RF workflow will change based upon this option, so this is required for UnitPicking
                            @vEnablePickToLPN     as EnablePickToLPN,
                            coalesce(@vIsCoORequired, 'N') as IsCoORequired,
                            @vEnableSingleScanSKU as EnableSingleScanSKU,
                            @vAutoInitializeToLPN as AutoInitializeToLPN
                            for XML raw('BATCHPICKING'), elements, root('OPTIONS'));

  /* 5. Build XML, The return dataset is used for RF to show Locations info, Location Details and Options in seperate nodes */
  set @xmlresult = (select '<BATCHPICKDETAILS>' +
                                 coalesce(@xmlBatchPickInfo, '') +
                                 coalesce(@xmlOptions, '') +
                                 coalesce(@xmlPickList, '') +
                           '</BATCHPICKDETAILS>')
end try
begin catch
  set @xmlResult =  (select ERROR_NUMBER()    as ErrorNumber,
                            ERROR_SEVERITY()  as ErrorSeverity,
                            ERROR_STATE()     as ErrorState,
                            ERROR_PROCEDURE() as ErrorProcedure,
                            ERROR_LINE()      as ErrorLine,
                            ERROR_MESSAGE()   as ErrorMessage
                     FOR XML RAW('ERRORINFO'), TYPE, ELEMENTS XSINIL, ROOT('ERRORDETAILS'));
end catch;
end /* pr_Picking_BatchPickResponse */

Go
