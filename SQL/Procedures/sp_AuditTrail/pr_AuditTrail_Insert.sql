/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/31  TK      pr_AuditTrail_InsertRecords & pr_AuditTrail_Insert:
                        Changes to log more info needed into AuditDetails (HA-3031)
              AY      pr_AuditTrail_Insert: Code optimizations (HA-3049)
  2020/09/29  SK      pr_AuditTrail_InsertRecords: Added functionality to include logging into Audit details (CIMS-2967)
  2019/09/18  RKC     pr_AuditTrail_Insert: Insert the audit record details to AuditDetails table (CID-1042)
  2017/02/14  KL      pr_AuditTrail_Insert: Combined 'SKU' to UnitsOfSKU to show prefix SKU (HPI-431)
  2016/12/12  AY      pr_AuditTrail_Insert: Added TaskId (HPI-GoLive)
  2016/06/04  TK      pr_AuditTrail_Insert: Enhanced to log AT if Receipt Detail is modified (FB-685)
  2016/06/01  TK      pr_AuditTrail_Insert: Enhanced to handle null values (NBD-571)
  2016/05/24  OK      pr_AuditTrail_Insert: Added the PrevQuantity, PrevInnerPacks parameters(HPI-121)
  2016/04/12  AY      pr_AuditTrail_Insert: Optimized to read UoMs only as needed.
  2016/03/02  OK      pr_AuditTrail_Insert: Removed the @vUsingInnerPacks control variable in where clause as we are not using this any where (NBD-249)
  2016/01/04  SV      pr_AuditTrail_Insert: Enhancement to show AT over Load transactions (CIMS-730)
  2014/11/27  PKS     pr_AuditTrail_Insert: AT record Log for RF logins
  2014/09/01  TK      pr_AuditTrail_Insert: changed @vOnPallet value to be more descriptive.
  2014/07/18  PKS     pr_AuditTrail_Insert: Enhanced to Log ReasonCode information in Audit Comments.
  2014/06/13  PV      pr_AuditTrail_Insert: Corrected to not show cases for Picklane units location.
  2014/05/28  NB      Added pr_AuditTrail_InsertRecords
  2014/05/19  NY      pr_AuditTrail_Insert : Display Description for ReplenishUOM.
  2014/05/14  PV      Enhanced pr_AuditTrail_Insert to return Audit comments.
  2014/05/13  PV      Enhanced pr_AuditTrail_Insert to log audit trail for replenish level adjustments.
  2014/04/19  DK      pr_AuditTrail_Insert: Added ReceiverId.
  2014/04/05  PV      pr_AuditTrail_Insert: Issue fix with InnerPacks when null.
  2014/04/03  NY      pr_AuditTrail_Insert: Added Warehouse in comment.
  2014/04/05  DK      pr_AuditTrail_Insert: Added TrackingNo.
  2014/03/31  AY      pr_AuditTrail_Insert: Added Receiver Number
  2014/03/25  TD      pr_AuditTrail_Insert: Changes to calculate Quantity based on the Innerpacks.
  2014/03/24  AY      pr_AuditTrail_Insert: Enh. to show Innerpacks in audit comments
  2013/12/09  NY      pr_AuditTrail_Insert: Added entity for Receipt
  2013/10/04  PK      pr_AuditTrail_Insert: Building up AuditComment to display LPN/Location if the
                       pick is from Picklane then display Location, else display LPN/Location.
  2013/10/02  PK      pr_AuditTrail_Insert: Fetching BatchNo from PickBatchDetails
  2013/05/09  AY      pr_AuditTrail_Insert: Enhanced to use %DisplaySKU
  2012/12/14  PKS     pr_AuditTrail_Insert: Procedure modified to show Previous value of UnitsOrdered
  2012/11/27  PKS     pr_AuditTrail_Insert: Moved @vNewUnitsToShip in updating the 'comment' part.
  2012/11/14  VM      pr_AuditTrail_Insert: Modified to update message with %OrderLine.
  2012/10/09  PKS     pr_AuditTrail_Insert: Added parameter PrevOrderId to fetch details of Previous Order of LPN.
  2012/09/12  YA      pr_AuditTrail_Insert: Modified to update message with %ToPalletLocation
  2012/09/04  AY      pr_AuditTrail_Insert: NumLPNs, NumPallets incorrectly being reported
                        in AuditTrial - fixed. Location not showing properly in Audit messages - fixed
  2012/08/28  AY      pr_AuditTrail_Insert: Added OnPallet as LPNs may or may not have Pallet
                        and message should be appropriate either way.
  2012/08/17  AY      pr_AuditTrail_Insert: Read comments above procedure for new
                        implementation regarding AuditDateTime, also Added LoadNumber
                        to messages
  2012/08/08  PK      pr_AuditTrail_Insert: Retrieving NumLPNs, NumPallets from Locations.
  2012/07/31  YA      pr_AuditTrail_Insert: Implemented replace function on %NumPallets.
  2012/07/14  AY      pr_AuditTrail_Insert: Build PrevSKU1..5 for message
  2012/05/19  AY      pr_AuditTrail_Insert: Build SKU1..5 for message
                      pr_AuditTrail_InsertEntities: Added
  2012/05/02  AY      pr_AuditTrail_Insert: output AuditRecordId
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AuditTrail_Insert') is not null
  drop Procedure pr_AuditTrail_Insert;
Go
/*------------------------------------------------------------------------------
  Proc pr_AuditTrail_Insert:
    This proc will call when user selects Batch Audit tab from UI, by passing the
    selected BatchNo.

    ActivityType - can be ?BatchPick?, ?UnitPick?, ?LPNPick? etc.
    ActivityDateTime - if 0 is passed in, then the modified date from LPN/Pallet would be used
                       if null is passed in, then the current_timestamp woudl be used

  Comments: For each type of activity a comment is built
------------------------------------------------------------------------------*/
Create Procedure pr_AuditTrail_Insert
  (@ActivityType     TActivityType,
   @UserId           TUserId,
   @ActivityDateTime TDateTime,

   @DeviceId         TDeviceId       = null,
   @BusinessUnit     TBusinessUnit   = null,

   @SKUId            TRecordId       = null,
   @LPNId            TRecordId       = null,
   @LPNDetailId      TRecordId       = null,
   @LocationId       TRecordId       = null,
   @PalletId         TRecordId       = null,
   @ReceiverId       TRecordId       = null,
   @Warehouse        TWarehouse      = null,

   @OrderId          TRecordId       = null,
   @OrderDetailId    TRecordId       = null,
   @PickBatchId      TRecordId       = null,
   @WaveId           TRecordId       = null,
   @ShipmentId       TShipmentId     = null,
   @LoadId           TLoadId         = null,
   @PrevOrderId      TRecordId       = null,

   @ToWarehouse      TWarehouse      = null,
   @ToLPNId          TRecordId       = null,
   @ToLPNDetailId    TRecordId       = null,
   @ToLocationId     TRecordId       = null,
   @ToPalletId       TRecordId       = null,
   @PrevSKUId        TRecordId       = null,
   @TaskId           TRecordId       = null,
   @TaskDetailId     TRecordId       = null,

   @NumOrders        TCount          = null,
   @NumPallets       TCount          = null,
   @NumLPNs          TCount          = null,
   @NumSKUs          TCount          = null,
   @InnerPacks       TInnerpacks     = null,
   @Quantity         TQuantity       = null,
   @PrevInnerPacks   TInnerpacks     = null,
   @PrevQuantity     TQuantity       = null,

   @Status           TStatus         = null,

   @ReceiptId        TRecordId       = null,
   @ReceiptDetailId  TRecordId       = null,
   @ReceiverNumber   TReceiverNumber = null,

   @Note1            TDescription    = null,
   @Note2            TDescription    = null,
   @ReasonCodeCategory
                     TCategory       = null,
   @ReasonCode       TLookUpCode     = null,

   @Archived         TFlag           = null,
   @AuditRecordId    TRecordId       = null output,
   @Comment          TVarChar        = null output
   )
as
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName,
          @Message            TDescription,

          @vWaveId            TRecordId,
          @vWaveNo            TWaveNo,
          @vWaveStatus        TStatus,
          @vWaveType          TTypeCode,
          @vWaveTypeDesc      TDescription,

          @vPickTicket        TPickTicket,
          @vOrderStatus       TStatus,
          @vOrderType         TTypeCode,
          @vOrderTypeDesc     TDescription,
          @vOrderLine         TDetailLine,
          @vShortPicked       TFlag,
          @vPrevPickTicket    TPickTicket,

          @vPalletId          TRecordId,
          @vLocationId        TRecordId,

          @vComment           TVarChar,
          @vOwnership         TOwnership,

          @vLPN               TLPN,
          @vReceiverNo        TReceiverNumber,
          @vOnROTypeAndNumber TDescription,
          @vToLPN             TLPN,
          @vToLPNPallet       TPallet,
          @vToLPNLocation     TLocation,
          @vTrackingNo        TDescription,
          @vSorterName        TDescription,
          @vLocation          TLocation,
          @vLocationType      TTypeCode,
          @vToLocation        TLocation,
          @vToLocationType    TTypeCode,
          @vLocationStorageType
                              TStorageType,
          @vToLocationId      TRecordId,

          @vPallet            TPallet,
          @vToPalletId        TRecordId,
          @vToPallet          TPallet,

          @vSKU               TSKU,
          @vSKU1              TSKU,
          @vSKU2              TSKU,
          @vSKU3              TSKU,
          @vSKU4              TSKU,
          @vSKU5              TSKU,
          @vSKU15             TDescription,
          @vDisplaySKU        TDescription,
          @vSKUDesc           TDescription,
          @vUPC               TUPC,
          @vUnitsPerPackage   TQuantity,

          @vPrevSKU           TSKU,
          @vPrevSKU1          TSKU,
          @vPrevSKU2          TSKU,
          @vPrevSKU3          TSKU,
          @vPrevSKU4          TSKU,
          @vPrevSKU5          TSKU,
          @vPrevSKU15         TDescription,
          @vPrevDisplaySKU    TDescription,
          @vPrevSKUDesc       TDescription,
          @vPrevUPC           TUPC,

          @vLoadNumber        TLoadNumber,

          /* Variables to build comments */
          @vActivityMessage       TDescription,
          @vIPUnits               TDescription,
          @vUnitsOnly             TDescription,
          @vLPNUoM                TDescription,
          @vLPNUoM1               TDescription,
          @vLPNUoM2               TDescription,
          @vIPUoM                 TDescription,
          @vIPUoM1                TDescription,
          @vIPUoM2                TDescription,
          @vUnitUoM               TDescription,
          @vUnitUoM1              TDescription,
          @vUnitUoM2              TDescription,
          @vNumLPNs               TDescription,
          @vInnerPacks            TDescription,
          @vPrevUnits             TDescription,
          @vUnits                 TDescription,
          @vUnitsOfSKU            TDescription,
          @vUnitsToShip           TQuantity,
          @vUnitsOrdered          TQuantity,
          @vPTWave                TDescription,
          @vReceiptNumber         TDescription,
          @vROType                TTypeCode,
          @vROTypeDesc            TDescription,
          @vPalletLocation        TDescription,
          @vToPalletLocation      TDescription,
          @vOnPallet              TDescription,
          @vFromLocation          TDescription,
          @vFromLPNLocation       TDescription,
          @vMinQty                TQuantity,
          @vMaxQty                TQuantity,
          @vReplenishUOM          TDescription,
          @vReplenishUOMDesc      TDescription,
          @vReasonCodeDesc        TDescription,
          @vClientReasonCode      TLookUpCode,

          @EntityType             TTypeCode,
          @EntityId               TRecordId,
          @EntityKey              TEntity,
          @EntityDetails          TXML;

  declare @ttAuditEntities Table
          (RecordId       TRecordId identity (1,1),
           EntityId       TRecordId,
           EntityType     TTypeCode,
           EntityKey      TEntity,
           EntityDetails  TXML);

begin
  SET NOCOUNT ON;

  /* DO not overwrite input params of PalletId/LocationId as we would need to know
     what the caller passed in. Use Local variables instead */
  select @ReturnCode       = 0,
         @MessageName      = null,
         @ActivityType     = replace(@ActivityType, ' ', ''),
         @ActivityDateTime = case when @ActivityDateTime = 0 then null
                                  else coalesce(@ActivityDateTime, current_timestamp) end,
         @vPalletId        = @PalletId,
         @vLocationId      = @LocationId,
         @vWaveId          = coalesce(@WaveId, @PickBatchId);

  /* Get Key info of all relevant entities */

  if (@OrderDetailId is not null)
    select @OrderId       = coalesce(@OrderId, OrderId),
           @vOrderLine    = coalesce(@vOrderLine, OrderLine),
           @SKUId         = coalesce(@SKUId,   SKUId),
           @vUnitsToShip  = UnitsAuthorizedToShip,
           @vUnitsOrdered = UnitsOrdered,
           @BusinessUnit  = coalesce(@BusinessUnit, BusinessUnit)
    from OrderDetails
    where (OrderDetailId = @OrderDetailId);

  if (@OrderId is not null)
    select @vPickTicket    = PickTicket,
           @vOrderStatus   = Status,
           @vShortPicked   = ShortPick,
           @vWaveNo        = PickBatchNo,
           @vOrderType     = OrderType,
           @vWaveId        = coalesce(@vWaveId, PickBatchId),
           @BusinessUnit   = coalesce(@BusinessUnit, BusinessUnit),
           @Warehouse      = coalesce(@Warehouse, Warehouse),
           @vOwnership     = coalesce(@vOwnership, Ownership)
    from OrderHeaders
    where (OrderId = @OrderId);

  /* Get WaveNo from PickBatchDetails */
  if (@vWaveNo is null)
    select @vWaveNo = PickBatchNo,
           @vWaveId = coalesce(@vWaveId, PickBatchId)
    from PickBatchDetails
    where (OrderDetailId = @OrderDetailId);

  if (@PrevOrderId is not null)
    select @vPrevPickTicket = PickTicket
    from OrderHeaders
    where (OrderId = @PrevOrderId)

  if (@vWaveId is not null)
    select @vWaveNo       = BatchNo,
           @vWaveStatus   = Status,
           @vWaveType     = WaveType,
           @BusinessUnit  = coalesce(@BusinessUnit, BusinessUnit),
           @NumOrders     = coalesce(@NumOrders, NumOrders),
           @Warehouse     = coalesce(@Warehouse, Warehouse),
           @vOwnership    = coalesce(@vOwnership, Ownership)
    from Waves
    where (WaveId = @vWaveId);

  /* If ReceiverId is available, get ReceiverInfo */
  if (@ReceiverId is not null)
    select @vReceiverNo = ReceiverNumber
    from Receivers
    where (ReceiverId = @ReceiverId)

  if (@ReceiptDetailId is not null)
    select @ReceiptId     = coalesce(@ReceiptId, ReceiptId),
           @SKUId         = coalesce(@SKUId,   SKUId),
           @vUnitsOrdered = QtyOrdered,
           @BusinessUnit  = coalesce(@BusinessUnit, BusinessUnit)
    from ReceiptDetails
    where (ReceiptDetailId = @ReceiptDetailId);

  /* Get Receipt details */
  if (@ReceiptId is not null)
    select @vReceiptNumber = ReceiptNumber,
           @vROType        = ReceiptType,
           @Warehouse      = coalesce(@Warehouse, Warehouse),
           @vOwnership     = coalesce(@vOwnership, Ownership)
    from ReceiptHeaders
    where (ReceiptId = @ReceiptId);

  /* If LPNDetail is available, get LPNId and SKUId */
  if (@LPNDetailId is not null)
    select @LPNId            = coalesce(@LPNId, LPNId),
           @SKUId            = coalesce(@SKUId, SKUId),
           @vUnitsPerPackage = nullif(UnitsPerPackage, 0),
           @BusinessUnit     = coalesce(@BusinessUnit, BusinessUnit)
    from LPNDetails
    where (LPNDetailId = @LPNDetailId)
  else
  /* If we have LPNId and SKUId, then at least get the UnitsPerPackage from the LPN */
  if (@LPNId is not null) and (@SKUId is not null)
    select @vUnitsPerPackage = nullif(UnitsPerPackage, 0)
    from LPNDetails
    where (LPNId = @LPNId) and (SKUId = @SKUId);

  /* If LPNId is available, get LPNInfo as well as PalletId and LocationId  */
  if (@LPNId is not null)
    select @vLPN             = LPN,
           @NumLPNs          = 1,
           @SKUId            = coalesce(@SKUId,   SKUId),
           @vPalletId        = coalesce(@vPalletId, PalletId),
           @vLocationId      = coalesce(@vLocationId, LocationId),
           @vTrackingNo      = TrackingNo,
           @vSorterName      = SorterName,
           @OrderId          = coalesce(@OrderId, OrderId),
           @BusinessUnit     = coalesce(@BusinessUnit, BusinessUnit),
           @ActivityDateTime = coalesce(@ActivityDateTime, ModifiedDate),
           @Warehouse        = coalesce(@Warehouse, DestWarehouse),
           @vOwnership       = coalesce(@vOwnership, Ownership)
    from LPNs
    where (LPNId = @LPNId);

  /* Get Pallet Info, retrieve NumLPNs only if PalletId was passed in */
  if (@vPalletId is not null)
    select @vPallet          = Pallet,
           @NumLPNs          = case when @PalletId is not null then coalesce(@NumLPNs, NumLPNs) else @NumLPNs end,
           @vOwnership       = coalesce(@vOwnership, Ownership),
           @BusinessUnit     = coalesce(@BusinessUnit, BusinessUnit),
           @ActivityDateTime = coalesce(@ActivityDateTime, ModifiedDate)
    from Pallets
    where (PalletId = @vPalletId);

  /* Get Location info - do not create AT for locations other than RBK Locations
     Also, do not overwirte NumLPNs, NumPallets from LocationId was given explicitly */
  if (@vLocationId is not null)
    select @vLocation            = Location,
           @vLocationType        = LocationType,
           @vLocationStorageType = StorageType,
           @NumLPNs              = case when @LocationId is not null then coalesce(@NumLPNs, NumLPNs) else @NumLPNs end,
           @NumPallets           = case when @LocationId is not null then coalesce(@NumPallets, NumPallets) else @NumPallets end,
           @BusinessUnit         = coalesce(@BusinessUnit, BusinessUnit),
           @vMinQty              = MinReplenishLevel,
           @vMaxQty              = MaxReplenishLevel,
           @vReplenishUOM        = ReplenishUoM,
           @Warehouse            = coalesce(@Warehouse, Warehouse)
    from Locations
    where (LocationId = @vLocationId);

  /* Get the Description of ReplenishUoM */
  if (@vReplenishUOM is not null)
    select @vReplenishUOMDesc = LookUpDescription
    from LookUps
    where LookUpCode = @vReplenishUOM

   /* Get LPNDetails info */
  if (@ToLPNDetailId is not null)
    select @ToLPNId = coalesce(@ToLPNId, LPNId)
    from LPNDetails
    where (LPNDetailId = @ToLPNDetailId);

  /* Get LPN info */
  if (@ToLPNId is not null)
    select @vToLPN       = LPN,
           @ToPalletId   = coalesce(@ToPalletId, PalletId),
           @ToLocationId = coalesce(@ToLocationId, LocationId),
           @vToLocation  = Location,
           @vOwnership   = coalesce(@vOwnership, Ownership)
    from LPNs
    where (LPNId = @ToLPNId);

  /* Get To Pallet info */
  if (@ToPalletId is not null)
    select @vToPallet = Pallet
    from Pallets
    where (PalletId = @ToPalletId);

  /* Get To Location info */
  if (@ToLocationId is not null)
    select @vToLocationId   = LocationId,
           @vToLocation     = Location,
           @vToLocationType = LocationType,
           @ToWarehouse     = coalesce(@ToWarehouse, Warehouse)
    from Locations
    where (LocationId = @ToLocationId);

  /* Get SKU info */
  if (@SKUId is not null)
    select @vSKU             = SKU,
           @vSKU1            = SKU1,
           @vSKU2            = SKU2,
           @vSKU3            = SKU3,
           @vSKU4            = SKU4,
           @vSKU5            = SKU5,
           @vUPC             = UPC,
           @vSKUDesc         = Description,
           @vUnitsPerPackage = coalesce(@vUnitsPerPackage, UnitsPerInnerPack)
    from SKUs
    where (SKUId = @SKUId);

  /* Get Prev SKU info */
  if (@PrevSKUId is not null)
    select @vPrevSKU     = SKU,
           @vPrevSKU1    = SKU1,
           @vPrevSKU2    = SKU2,
           @vPrevSKU3    = SKU3,
           @vPrevSKU4    = SKU4,
           @vPrevSKU5    = SKU5,
           @vPrevUPC     = UPC,
           @vPrevSKUDesc = Description
    from SKUs
    where (SKUId = @PrevSKUId);

  if (@LoadId is not null)
    select @vLoadNumber  = LoadNumber,
           @BusinessUnit = BusinessUnit,
           @Warehouse    = FromWarehouse
    from Loads
    where (LoadId = @LoadId);

  /* Reason codes are unique i.e we will not use one reason code to mean different things
     in different contexts. i.e if we have 201 mean 'Damage' it means the same whether that
     code is used in LPNAdjust or CreateInv or something else */
  if (@ReasonCode is not null)
    select @vReasonCodeDesc = L.LookUpDescription
    from LookUps L
    where (L.LookUpCategory = coalesce(@ReasonCodeCategory, L.LookUpCategory)) and
          (L.LookUpCode     = @ReasonCode) and
          (L.BusinessUnit = @BusinessUnit);

  if (@vOrderType is not null)
    select @vOrderTypeDesc = dbo.fn_EntityType_GetDescription('Order', @vOrderType, @BusinessUnit);

  if (@vROType is not null)
    select @vROTypeDesc = dbo.fn_EntityType_GetDescription('Receipt', @vROType, @BusinessUnit);

  if (@vWaveType is not null)
    select @vWaveTypeDesc = dbo.fn_EntityType_GetDescription('Wave', @vWaveType, @BusinessUnit);

  /* Calculate InnerPacks OR Quantity based on the input */
   if ((coalesce(@vUnitsPerPackage, 0) > 0) and (coalesce(@Quantity, 0) = 0) and
       (coalesce(@InnerPacks, 0) > 0))
     set @Quantity = @vUnitsPerPackage * @InnerPacks;
   else
   if ((coalesce(@vUnitsPerPackage, 0) > 0) and
       (coalesce(@Quantity, 0) > 0) and
       (coalesce(@InnerPacks, 0) = 0))
     set @InnerPacks = @Quantity / @vUnitsPerPackage;

   if ((coalesce(@vUnitsPerPackage, 0) > 0) and (coalesce(@PrevQuantity, 0) = 0) and
       (coalesce(@PrevInnerPacks, 0) > 0))
     set @PrevQuantity = @vUnitsPerPackage * @PrevInnerPacks;
   else
   if ((coalesce(@vUnitsPerPackage, 0) > 0) and
       (coalesce(@PrevQuantity, 0) > 0) and
       (coalesce(@PrevInnerPacks, 0) = 0))
     set @PrevInnerPacks = @PrevQuantity / @vUnitsPerPackage;

  /* The units in the Audit trail can include Inner packs and Units with singular and
     plural units of measures. The below section allows for the various possibilities
     We can units shown with InnerPacks and units or just units only. That is decided
     based upon the count of InnerPacks i.e. if InnerPacks >= 1, intention is to show
     Innerpacks and units, else show units only
     Beyond that, inner packs and units would have UoM as caption and we define singular
     and plural versions of it */

  /* Get only the UoMs that are needed for performances reasons */
  if (@InnerPacks is not null) or (@Quantity is not null)
    select @vIPUnits   = dbo.fn_Messages_GetDescription('AT_IPUnits'),
           @vUnitsOnly = dbo.fn_Messages_GetDescription('AT_UnitsOnly');

  if (@InnerPacks is not null)
    select @vIPUoM1    = dbo.fn_Messages_GetDescription('AT_IPUoM1'),
           @vIPUoM2    = dbo.fn_Messages_GetDescription('AT_IPUoM2');

  if (@Quantity is not null)
    select @vUnitUoM1  = dbo.fn_Messages_GetDescription('AT_UnitUoM1'),
           @vUnitUoM2  = dbo.fn_Messages_GetDescription('AT_UnitUoM2');

  if (@NumLPNs is not null)
    select @vLPNUoM1   = dbo.fn_Messages_GetDescription('AT_LPNUoM1'),
           @vLPNUoM2   = dbo.fn_Messages_GetDescription('AT_LPNUoM2');

  select @InnerPacks     = coalesce(@InnerPacks, 0),
         @PrevInnerPacks = coalesce(@PrevInnerPacks, 0),
         @vIPUoM1        = coalesce(@vIPUoM1,   ''),
         @vIPUoM2        = coalesce(@vIPUoM2,   ''),
         @vUnitUoM1      = coalesce(@vUnitUoM1, ''),
         @vUnitUoM2      = coalesce(@vUnitUoM2, ''),
         @vLPNUoM1       = coalesce(@vLPNUoM1,  ''),
         @vLPNUoM2       = coalesce(@vLPNUoM2,  '');

  /* Reset InnerPacks to Zero if Location is PickLane Unit storage */
  if (@vLocationType = 'K' /* Picklane*/ and @vLocationStorageType = 'U' /* Units */)
    select @InnerPacks = 0;

  select @vLPNUoM    = case when @NumLPNs     = 1 then @vLPNUoM1  else @vLPNUoM2    end,
         @vIPUoM     = case when @InnerPacks  = 1 then @vIPUoM1   else @vIPUoM2    end,
         @vUnitUoM   = case when @Quantity    = 1 then @vUnitUoM1 else @vUnitUoM2  end,
         @vUnits     = case when (@InnerPacks >= 1) then @vIPUnits else @vUnitsOnly end,
         @vPrevUnits = case when (@PrevInnerPacks >= 1) then @vIPUnits else @vUnitsOnly end;

  select @vUnits     = replace(@vUnits,     '%InnerPacks', convert(varchar, @InnerPacks)),
         @vUnits     = replace(@vUnits,     '%Quantity',   convert(varchar, @Quantity)),
         @vUnits     = replace(@vUnits,     '%IPUoM',      @vIPUoM),
         @vUnits     = replace(@vUnits,     '%UnitUoM',    @vUnitUoM);

  select @vPrevUnits = replace(@vPrevUnits, '%InnerPacks', convert(varchar, @PrevInnerPacks)),
         @vPrevUnits = replace(@vPrevUnits, '%Quantity',   convert(varchar, @PrevQuantity)),
         @vPrevUnits = replace(@vPrevUnits, '%IPUoM',      @vIPUoM),
         @vPrevUnits = replace(@vPrevUnits, '%UnitUoM',    @vUnitUoM);

  select @vNumLPNs = coalesce(convert(varchar, @NumLPNs) + ' ' + @vLPNUoM, '');

  if (coalesce(@vPickTicket, '') = '')
    select @vPTWave = coalesce(@vWaveNo, '');
  else
    select @vPTWave = coalesce(@vPickTicket, '') + coalesce('/' + @vWaveNo, '');

  select @vUnitsOfSKU        = @vUnits + coalesce(' of SKU ' + @vSKU, ''),  -- handles when SKU could be null as there are multiple
         @vPalletLocation    = @vPallet + coalesce(' (Location ' + @vLocation + ')', ''),
         @vToPalletLocation  = @vToPallet + coalesce(' (Location ' + @vToLocation + ')', ''),
         @vOnPallet          = 'on Pallet ' + @vPallet,
         @vFromLocation      = 'from ' + @vLocation,
         @vFromLPNLocation   = case when (@vLocationType = 'K' /* PickLane */) then @vLocation else (@vLPN + '/' + @vLocation) end,
         @vOnROTypeAndNumber = 'on ' + @vROTypeDesc + ' ' + @vReceiptNumber;

  select @vLocation        = coalesce(@vLocation, ''),
         @vActivityMessage = 'AT_' + @ActivityType;

  /* Do not generate AT for Locations other than RBK - Reserve, Bulk, Picklane */
  if (@vLocationType not in ('R', 'B', 'K')) select @vLocationId = null;
  if (@vToLocationType not in ('R', 'B', 'K')) select @ToLocationId = null;

  if (@ActivityType is null)
    goto Exithandler;

  /* Get the appropriate message for the given activity */
  select @vComment = dbo.fn_Messages_GetDescription(@vActivityMessage);

  /* Build SKU1..SKU5 */
  if (charindex('%SKU15', @vComment) > 0)
    begin
      select @vSKU15 = dbo.fn_Messages_GetDescription('AT_SKU15');
      select @vSKU15 = replace(@vSKU15, '%SKU1', coalesce(@vSKU1, '-'));
      select @vSKU15 = replace(@vSKU15, '%SKU2', coalesce(@vSKU2, '-'));
      select @vSKU15 = replace(@vSKU15, '%SKU3', coalesce(@vSKU3, '-'));
      select @vSKU15 = replace(@vSKU15, '%SKU4', coalesce(@vSKU4, '-'));
      select @vSKU15 = replace(@vSKU15, '%SKU5', coalesce(@vSKU5, '-'));
    end

  /* Build Prev SKU1..SKU5 */
  if (charindex('%PrevSKU15', @vComment) > 0)
    begin
      select @vPrevSKU15 = dbo.fn_Messages_GetDescription('AT_PrevSKU15');
      select @vPrevSKU15 = replace(@vSKU15, '%PrevSKU1', coalesce(@vPrevSKU1, '-'));
      select @vPrevSKU15 = replace(@vSKU15, '%PrevSKU2', coalesce(@vPrevSKU2, '-'));
      select @vPrevSKU15 = replace(@vSKU15, '%PrevSKU3', coalesce(@vPrevSKU3, '-'));
      select @vPrevSKU15 = replace(@vSKU15, '%PrevSKU4', coalesce(@vPrevSKU4, '-'));
      select @vPrevSKU15 = replace(@vSKU15, '%PrevSKU5', coalesce(@vPrevSKU5, '-'));
    end

  /* Build DisplaySKU with SKU1..SKU5, UPC, Desc - what the client wants */
  if (charindex('%DisplaySKU', @vComment) > 0)
    begin
      select @vDisplaySKU = dbo.fn_Messages_GetDescription('AT_DisplaySKU');
      select @vDisplaySKU = replace(@vDisplaySKU, '%SKU1',     coalesce(@vSKU1,     '-'));
      select @vDisplaySKU = replace(@vDisplaySKU, '%SKU2',     coalesce(@vSKU2,     '-'));
      select @vDisplaySKU = replace(@vDisplaySKU, '%SKU3',     coalesce(@vSKU3,     '-'));
      select @vDisplaySKU = replace(@vDisplaySKU, '%SKU4',     coalesce(@vSKU4,     '-'));
      select @vDisplaySKU = replace(@vDisplaySKU, '%SKU5',     coalesce(@vSKU5,     '-'));
      select @vDisplaySKU = replace(@vDisplaySKU, '%SKUDesc',  coalesce(@vSKUDesc,  '-'));
      select @vDisplaySKU = replace(@vDisplaySKU, '%SKU',      coalesce(@vSKU,      '-'));
      select @vDisplaySKU = replace(@vDisplaySKU, '%UPC',      coalesce(@vUPC,      '-'));
    end

  /* Build PrevDisplaySKU with SKU1..SKU5, UPC, Desc - what the client wants */
  if (charindex('%PrevDisplaySKU', @vComment) > 0)
    begin
      select @vPrevDisplaySKU = dbo.fn_Messages_GetDescription('AT_PrevDisplaySKU');
      select @vPrevDisplaySKU = replace(@vPrevDisplaySKU, '%PrevSKU1',     coalesce(@vPrevSKU1,    '-'));
      select @vPrevDisplaySKU = replace(@vPrevDisplaySKU, '%PrevSKU2',     coalesce(@vPrevSKU2,    '-'));
      select @vPrevDisplaySKU = replace(@vPrevDisplaySKU, '%PrevSKU3',     coalesce(@vPrevSKU3,    '-'));
      select @vPrevDisplaySKU = replace(@vPrevDisplaySKU, '%PrevSKU4',     coalesce(@vPrevSKU4,    '-'));
      select @vPrevDisplaySKU = replace(@vPrevDisplaySKU, '%PrevSKU5',     coalesce(@vPrevSKU5,    '-'));
      select @vPrevDisplaySKU = replace(@vPrevDisplaySKU, '%PrevSKUDesc',  coalesce(@vPrevSKUDesc, '-'));
      select @vPrevDisplaySKU = replace(@vPrevDisplaySKU, '%PrevSKU',      coalesce(@vPrevSKU,     '-'));
      select @vPrevDisplaySKU = replace(@vPrevDisplaySKU, '%PrevUPC',      coalesce(@vPrevUPC,     '-'));
    end

  /* Replace variables in the Comment - order of these is important!
     VM - Can we change the order to be alphabetical for quicker readability? */
  select @vComment = replace(@vComment, '%UnitsOfSKU',        coalesce(@vUnitsOfSKU, ''));
  select @vComment = replace(@vComment, '%PrevUnits',         coalesce(@vPrevUnits, ''));
  select @vComment = replace(@vComment, '%Units',             coalesce(@vUnits, ''));
  select @vComment = replace(@vComment, '%Quantity',          coalesce(@Quantity, ''));
  select @vComment = replace(@vComment, '%PickBatchType',     coalesce(@vWaveTypeDesc, ''));
  select @vComment = replace(@vComment, '%PickBatch',         coalesce(@vWaveNo, ''));
  select @vComment = replace(@vComment, '%WaveType',          coalesce(@vWaveTypeDesc, ''));
  select @vComment = replace(@vComment, '%WaveNo',            coalesce(@vWaveNo, ''));
  select @vComment = replace(@vComment, '%Wave',              coalesce(@vWaveNo, ''));
  select @vComment = replace(@vComment, '%PickTicket',        coalesce(@vPickTicket, ''));
  select @vComment = replace(@vComment, '%OrderType',         coalesce(@vOrderTypeDesc, ''));
  select @vComment = replace(@vComment, '%PalletLocation',    coalesce(@vPalletLocation, ''));
  select @vComment = replace(@vComment, '%ToPalletLocation',  coalesce(@vToPalletLocation, ''));
  select @vComment = replace(@vComment, '%FromLocation',      coalesce(@vFromLocation, ''));
  select @vComment = replace(@vComment, '%ToLocation',        coalesce(@vToLocation, ''));
  select @vComment = replace(@vComment, '%Location',          coalesce(@vLocation, ''));
  select @vComment = replace(@vComment, '%ToPallet',          coalesce(@vToPallet, ''));
  select @vComment = replace(@vComment, '%Pallet',            coalesce(@vPallet, ''));
  select @vComment = replace(@vComment, '%OnPallet',          coalesce(@vOnPallet, ''));
  select @vComment = replace(@vComment, '%NumPallets',        coalesce(@NumPallets, ''));
  select @vComment = replace(@vComment, '%LPNLocation',       coalesce(@vFromLPNLocation, ''));
  select @vComment = replace(@vComment, '%ToLPN',             coalesce(@vToLPN, ''));
  select @vComment = replace(@vComment, '%LPN',               coalesce(@vLPN, ''));
  select @vComment = replace(@vComment, '%TrackingNo',        coalesce(@vTrackingNo, ''));
  select @vComment = replace(@vComment, '%NumLPNs',           coalesce(@vNumLPNs, ''));
  select @vComment = replace(@vComment, '%SKU15',             coalesce(@vSKU15, ''));
  select @vComment = replace(@vComment, '%DisplaySKU',        coalesce(@vDisplaySKU, ''));
  select @vComment = replace(@vComment, '%SKU',               coalesce(@vSKU, ''));
  select @vComment = replace(@vComment, '%PrevSKU15',         coalesce(@vPrevSKU15, ''));
  select @vComment = replace(@vComment, '%PrevDisplaySKU',    coalesce(@vPrevDisplaySKU, ''));
  select @vComment = replace(@vComment, '%PrevSKU',           coalesce(@vPrevSKU, ''));
  select @vComment = replace(@vComment, '%PTBatch',           coalesce(@vPTWave, ''));
  select @vComment = replace(@vComment, '%PTWave',            coalesce(@vPTWave, ''));
  select @vComment = replace(@vComment, '%NumOrders',         coalesce(@NumOrders, ''));
  select @vComment = replace(@vComment, '%ROType',            coalesce(@vROTypeDesc, ''));
  select @vComment = replace(@vComment, '%ReceiptNumber',     coalesce(@vReceiptNumber, ''));
  select @vComment = replace(@vComment, '%ReceiverNumber',    coalesce(@ReceiverNumber, @vReceiverNo, ''));
  select @vComment = replace(@vComment, '%OnROTypeAndNumber', coalesce(@vOnROTypeAndNumber, ''));
  select @vComment = replace(@vComment, '%Note1',             coalesce(@Note1, ''));
  select @vComment = replace(@vComment, '%Note2',             coalesce(@Note2, ''));
  select @vComment = replace(@vComment, '%LoadNumber',        coalesce(@vLoadNumber, ''));
  select @vComment = replace(@vComment, '%PrevPickTicket',    coalesce(@vPrevPickTicket, ''));
  select @vComment = replace(@vComment, '%OrderLine',         coalesce(@vOrderLine, ''));
  select @vComment = replace(@vComment, '%PrevUnitsToShip',   coalesce(@Note1, ''));
  select @vComment = replace(@vComment, '%PrevUnitsOrdered',  coalesce(@Note2, ''));
  select @vComment = replace(@vComment, '%NewUnitsToShip',    coalesce(@vUnitsToShip, ''));
  select @vComment = replace(@vComment, '%NewUnitsOrdered',   coalesce(@vUnitsOrdered, ''));
  select @vComment = replace(@vComment, '%Warehouse',         coalesce(@Warehouse, ''));
  select @vComment = replace(@vComment, '%MinQty',            coalesce(@vMinQty, ''));
  select @vComment = replace(@vComment, '%MaxQty',            coalesce(@vMaxQty, ''));
  select @vComment = replace(@vComment, '%ReplenishUoM',      coalesce(@vReplenishUOMDesc, ''));
  select @vComment = replace(@vComment, '%ReasonCodeDesc',    coalesce(@vReasonCodeDesc,''));
  select @vComment = replace(@vComment, '%TaskId',            coalesce(@TaskId,''));
  select @vComment = replace(@vComment, '%UserId',            coalesce(@UserId,''));
  select @vComment = replace(@vComment, '%DeviceId',          coalesce(@DeviceId,''));
  select @vComment = replace(@vComment, '%SorterName',        coalesce(@vSorterName,''));

  /* This is to send output */
  select @Comment = @vComment;

  /* Save the audit trail with the comment */
  insert into AuditTrail(ActivityType,
                         ActivityDateTime,
                         NumPallets, NumLPNs, NumSKUs,
                         InnerPacks, Quantity,
                         Comment,
                         DeviceId, BusinessUnit, UserId)
                  select @ActivityType,
                         coalesce(@ActivityDateTime, current_timestamp),
                         @NumPallets, @NumLPNs, @NumSKUs,
                         @InnerPacks, @Quantity,
                         @vComment,
                         @DeviceId, @BusinessUnit, @UserId;

  /* Save id of the audit trail record just created */
  set @AuditRecordId = Scope_Identity();

  /* Build list of Audit Entities */
  insert into @ttAuditEntities (EntityType, EntityId, EntityKey)
          select 'LPN',         @LPNId,        @vLPN
    union select 'Location',    @vLocationId,  @vLocation
    union select 'Receiver',    @ReceiverId,   @vReceiverNo
    union select 'Receipt',     @ReceiptId,    @vReceiptNumber
    union select 'Wave',        @vWaveId,      @vWaveNo
--    union select 'SKU',         @SKUId,        @vSKU
    union select 'Pallet',      @vPalletId,    @vPallet
    union select 'PickTicket',  @OrderId,      @vPickTicket
    union select 'Load',        @LoadId,       @vLoadNumber
    union select 'Location',    @ToLocationId, @vToLocation
    union select 'LPN',         @ToLPNId,      @vToLPN
    union select 'Pallet',      @ToPalletId,   @vToPallet

  /* Insert all valid entities into AuditEntities table */
  insert into AuditEntities(AuditId, BusinessUnit,
                            EntityType, EntityId, EntityKey, EntityDetails)
    select @AuditRecordId, @BusinessUnit,
           EntityType, EntityId, EntityKey, EntityDetails
    from @ttAuditEntities
    where (EntityId is not null) and (EntityKey is not null);

  /* Insert all valid entities details into AuditDetails table - ignore AT for which there
     is no relationship to SKU/LPN/Pallet/Location/Order/Task?Receipt */
  if (@SKUId is not null) or (@LPNId is not null) or (@ToLPNId is not null) or
     (@vPalletId is not null) or (@vLocationId is not null) or (@vToLocationId is not null) or
     (@OrderId is not null) or (@TaskId is not null) or (@ReceiptId is not null)
    insert into AuditDetails(AuditId, SKUId, SKU, LPNId, LPN, ToLPNId, ToLPN,
                             Ownership, Warehouse, ToWarehouse, PalletId, Pallet,
                             LocationId, Location, ToLocationId, ToLocation,
                             PrevInnerPacks, InnerPacks, PrevQuantity, Quantity,
                             WaveId, OrderId, TaskId, TaskDetailId,
                             ReceiverId, ReceiptId)
      select @AuditRecordId, @SKUId, @vSKU, @LPNId, @vLPN, @ToLPNId, @vToLPN,
             @vOwnership, @Warehouse, @ToWarehouse, @vPalletId, @vPallet,
             coalesce(@vLocationId, @LocationId), @vLocation, @vToLocationId, @vToLocation,
             @PrevInnerPacks, @InnerPacks, @PrevQuantity, @Quantity,
             @vWaveId, @OrderId, @TaskId, @TaskDetailId,
             @ReceiverId, @ReceiptId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_AuditTrail_Insert */

Go
