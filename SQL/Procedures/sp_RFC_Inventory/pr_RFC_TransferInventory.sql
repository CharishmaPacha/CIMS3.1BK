/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/11  TK      pr_RFC_TransferInventory: Fixes migrated from FB to drop picked pallet into bulk drop picklanes (BK-829)
  2021/07/12  RKC     pr_RFC_TransferInventory: Made changes to get the ToLPNDetailId (HA-2926)
  2021/06/25  RIA     pr_RFC_TransferInventory: Commented not to build the data set (HA-2878)
  2021/04/28  PK/YJ   pr_RFC_TransferInventory: ported changes from prod onsite (HA-2722)
  2021/03/27  VS      pr_RFC_TransferInventory: Get the Ownership mismatch validation (CID-1724, HA-2481)
  2020/07/29  TK      pr_RFC_AddSKUToLocation & pr_RFC_TransferInventory: Changes to consider InventoryClass (HA-1246)
  2020/05/15  RT      pr_RFC_TransferInventory: Calling pr_Exports_LPNReceiptConfirmation in teh place of pr_Exports_LPNData (HA-111)
  2020/04/29  RKC     pr_RFC_TransferInventory : Changes made to generate the export transaction when transfer the inventory from New LPN to PutawayLPN/location (HA-333)
  2020/04/20  TK      pr_RFC_TransferInventory: Do not update receipt details counts as that is being done in LPNs_AdjustQty proc (HA-211)
              TK      pr_RFC_TransferInventory: Changes to populate InventoryClass from source LPN to destination LPN and
  2020/03/19  TK      pr_RFC_TransferInventory: Changes to send source LPN ReceiverId to validate transfer inventory (S2GMI-140)
  2019/03/19  RIA     pr_RFC_TransferInventory: Made changes to validate Inactive SKUs when we transfer the inventory (HPI-2516)
  2018/11/21  TK      pr_RFC_TransferInventory: Bug Fix to transfer inventory in cases to a LPN having units with different SKU (S2GCA-399)
  2018/10/08  TK      pr_RFC_TransferInventory: Use the LPNId and LPNDetailId passed from caller (S2GCA-349)
  2018/10/02  OK      pr_RFC_TransferInventory: bugfix to send the detail information instead of complete LPN info (S2GCA-343)
  2018/09/14  TK      pr_RFC_TransferInventory: Changes to find destination LPN matching source LPN's Ownership & Lot (S2GCA-216)
  2018/09/12  TK      pr_RFC_TransferInventory: Changes to identify Source and Destination to transfer inventory (S2GCA-108)
  2018/09/10  TK      pr_RFC_TransferInventory: Fixed issues with loading default UoM (S2GCA-235)
  2018/08/16  TK/PK   pr_RFC_TransferInventory: Changes to pass ToLPNDetailId while generating WHXfer exports (S2G-1080)
  2018/06/18  TK      pr_RFC_TransferInventory: Changes to carry over Lot from LPNs (S2GCA-71)
  2018/06/08  VM      pr_RFC_TransferInventory: Fix to send right FromLPNId when Received LPN PA to a picklane (S2G-928)
  2018/06/08  AY/VM   pr_RFC_TransferInventory: Log Exports with FromLPNId on WH transfer (S2G-845)
  2018/03/26  RT      pr_RFC_TransferInventory: Made changes to @vFromLPNInnerPacks when the source is Location (S2G-471)
  2018/01/30  OK      pr_RFC_TransferInventory: Bugfix in passing a variable to pr_Exports_WarehouseTransfer (S2G-173)
  2017/11/07  SV      pr_RFC_TransferInventory: TransQty correction for the WHXfer exports (HPI-1675)
  2017/07/28  SV      pr_RFC_TransferInventory: Introduced ParameterSniffing concept to reduce the execution time (OB-537)
  2017/05/03  SV      pr_RFC_TransferInventory: Added the code to generate Warehouse export transaction (HPI-1320)
  2017/04/10  TK      pr_RFC_TransferInventory & pr_RFC_ValidateLPN:
  2017/02/14  SV      pr_RFC_TransferInventory: Added the code to generate Warehouse export transaction (HPI-1327)
  2016/12/23  KL      pr_RFC_TransferInventory:Pass the to LPN quantity value to the validation procedure (HPI-1114)
  2016/12/08  VM      pr_RFC_TransferInventory: Calling procedure switch to handle adding inventory to location in a different way (HPI-1113)
  2016/11/08  KL      pr_RFC_TransferInventory: Enhanced to allow to transfer loaded status LPN (HPI-1011)
  2016/11/02  TK      pr_RFC_TransferInventory: Allow transferring inventory from a LPN with Packing Status (HPI-GoLive)
  2016/09/17  AY      pr_RFC_TransferInventory: Enhanced to allow scanning tracking no for transfers (HPI-GoLive)
  2016/06/30  PK      pr_RFC_Inv_ValidatePallet, pr_RFC_TransferInventory: Bug fix for incorrect Received # over the received PO (NBD-641)
  2016/05/20  NY      pr_RFC_TransferInventory: Allowing staged LPNs to transfer (FB-697)
  2016/05/19  SV      pr_RFC_TransferInventory: Bug fix for transfering inv from a PickLane Loc to empty PickLane Loc (NBD-534)
  2016/04/01  DK      pr_RFC_TransferInventory: Changed procedure to accept XML as input parameter and added ReasonCode (FB-646)
  2016/03/17  SV      pr_RFC_TransferInventory: Bug fix - Updating the ReservedQty over the ToLPN once after confirming to BulkDrop Location (CIMS-715)
  2016/01/30  OK      pr_RFC_TransferInventory: Included the New status LPN to allow transfer inventory (NBD-124)
  2016/01/26  PK      pr_RFC_TransferInventory: Bug fixes (LL-265/266)
  2015/12/03  NY      pr_RFC_TransferInventory : Added Activity Log (LL-254)
  2015/06/30  NY      pr_RFC_TransferInventory: Consider LPNStatus status while Transfering Inventory (SRI-315)
  2015/06/01  TK      pr_RFC_TransferInventory: Use function GetScannedLocation.
                      pr_RFC_Inv_MovePallet, pr_RFC_MoveLPN, pr_RFC_RemoveSKUFromLocation, pr_RFC_TransferInventory,
  2015/03/25  VM      pr_RFC_TransferInventory: Validate To LPN with valid statuses
  2015/03/24  TK      pr_RFC_TransferInventory: If from LPN Status is of New and Destination is Location the generates Exports.
  2015/03/05  VM      pr_RFC_TransferInventory: Update LPN to Picked after Transfer after picking
  2015/02/27  TK      pr_RFC_TransferInventory: Issue fix with InnerPacks
  2015/02/27  TK/VM   pr_RFC_TransferInventory: Enhanced to update OrderId/Pickbatch on Logical LPN.
  2014/07/14  PK      pr_RFC_TransferInventory: Passing in the Location StorageType for validations.
                      pr_RFC_TransferInventory: Returning all the entries of scanned entity.
  2014/05/15  PV      pr_RFC_TransferInventory: Enhanced to return audit comments as success message.
  2014/05/14  PV      pr_RFC_TransferInventory: Computing innerpacks quantity if the quantity entered is equal to multiples of innerpack quantity.
  2014/05/06  PV      pr_RFC_TransferInventory: Issue fix with unitsPerPackage calculation from source instead of considering SKU configured value
  2014/03/18  TD      pr_RFC_TransferInventory:Changes to handle with innerpacks/Quantity.
  2013/12/27  AY      pr_RFC_TransferInventory: Allow transfer of available inventory to a partially allocated LPN
  2013/09/21  VM      pr_RFC_TransferInventory: Bug fix - Bug-fix: ToLPNStatus could be null when Destination is Location, hence corrected the condition.
  2013/09/21  VM      pr_RFC_TransferInventory: Bug fix - Fix to not to generate export when inv transfered from Loc to new LPN
  2013/08/21  AY      pr_RFC_TransferInventory: Do not allow transfers to create MultiSKU LPNs in inventory
                      pr_RFC_TransferInventory: Corrected the status of Lost, Used 'L' instead of 'O'.
  2012/09/20  YA      pr_RFC_TransferInventory: Modified message for Transfer of LPNs to be specific.
  2012/09/18  YA      pr_RFC_TransferInventory: Cannot transfer inv between LPNs of different orders,
                      pr_RFC_TransferInventory: Restricting on some of the  To and From LPNs.
  2012/07/17  AY      pr_RFC_TransferInventory: Generate exports when transfers are
  2011/09/27  PK      pr_RFC_TransferInventory : Set nullif if 'X' or '0' for few fields, and Changed
  2011/08/29  TD      pr_RFC_TransferInventoryL: Bug fix in LocationType validation.
  2011/08/18  TD      pr_RFC_AddSKUToLocation, pr_RFC_TransferInventory: Enhanced to
                      pr_RFC_TransferInventory: Added  @FromLocationType because we are using
  2011/01/04  PK      pr_RFC_TransferInventory: Minor Fixes.
                         and pr_RFC_TransferInventory.
                         except for pr_RFC_TransferInventory
  2010/11/29  PK      (WIP): pr_RFC_TransferInventory
  2010/11/25  VM      (WIP): pr_RFC_TransferInventory
                      pr_RFC_AddSKUToLPN, pr_RFC_AdjustLPN, pr_RFC_TransferInventory.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_TransferInventory') is not null
  drop Procedure pr_RFC_TransferInventory;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_TransferInventory:

  Notes: Earlier, on the RF the user would indicate if they are transferring from
   an LPN or Location and to an LPN or Location. We have now simplified this and
   just request user to scan the entity and we would figure out the intention.
   So, in the new model, we only send FromLocation.

  @XmlInput:
  '<TransferInventory xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
     <FromLocationId />
     <FromLocation>B132A</FromLocation>
     <FromLPNId />
     <FromLPN>X</FromLPN>
     <CurrentSKUId />
     <CurrentSKU>37373</CurrentSKU>
     <NewInnerPacks>1</NewInnerPacks>
     <TransferQuantity>0</TransferQuantity>
     <ReasonCode>290</ReasonCode>
     <ToLocationId />
     <ToLocation>B102A</ToLocation>
     <BusinessUnit>S2G</BusinessUnit>
     <UserId>reshma</UserId>
   </TransferInventory>'
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_TransferInventory
  (@XmlInput   XML,
   @XmlResult  XML output)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,

          @FromLPNId                TRecordId,
          @FromLPN                  TLPN,
          @FromLocationId           TRecordId,
          @FromLocation             TLocation,
          @SelectedLPNId            TRecordId,
          @SelectedLPNDetailId      TRecordId,
          @CurrentSKUId             TRecordId,   /* Selected SKUId */
          @CurrentSKU               TSKU,        /* Selected SKU */
          @NewInnerPacks            TInnerPacks,
          @TransferQuantity         TQuantity,

          @ToLPNId                  TRecordId,
          @ToLPN                    TLPN,
          @ToLocationId             TRecordId,
          @ToLocation               TLocation,
          @DestinationLocOrLPN      TVarchar,
          @ReasonCode               TReasonCode,
          @Operation                TOperation,
          @BusinessUnit             TBusinessUnit,
          @UserId                   TUserId,

          @vNewInnerPacks           TQuantity,
          @vCurrentSKUStatus        TStatus,
          @vFromLocationType        TLocationType,
          @vFromLocationId          TRecordId,
          @vFromLocation            TLocation,
          /* From LPN */
          @vFromLPNId               TRecordId,
          @vFromLPN                 TLPN,
          @vFromLPNType             TTypeCode,
          @vFromWarehouse           TWarehouse,
          @vFromLPNLot              TLot,
          @vFromLPNInventoryClass1  TInventoryClass,
          @vFromLPNInventoryClass2  TInventoryClass,
          @vFromLPNInventoryClass3  TInventoryClass,
          @vFromLPNStatus           TStatus,
          @vFromLPNOnhandStatus     TStatus,
          @vFromLPNInnerPacks       TInnerPacks,
          @vFromLPNQuantity         TQuantity,
          @vFromUnitsPerPackage     TQuantity,
          @vFromLPNOrderId          TRecordId,
          @vFromLPNReceiptId        TRecordId,
          @vFromLPNWaveId           TRecordId,
          @vFromLPNWaveNo           TWaveNo,

          /* To LPN */
          @vToLPNId                 TRecordId,
          @vToLocationType          TLocationType,
          @vToLocStorageType        TStorageType,
          @vToLPNDetailId           TRecordId,
          @Source                   TString,
          @Destination              TString,
          @FromBusinessUnit         TBusinessUnit,
          @ToBusinessUnit           TBusinessUnit,
          @vToWarehouse             TWarehouse,
          @LPNId                    TRecordId,
          @vToOrderId               TRecordId,
          @vToReceiptId             TRecordId,

          @vFromLPNDetailId         TRecordId,
          @vFromLocStorageType      TStorageType,
          @vFromLPNOrderDetailId    TRecordId,
          @vFromLPNReceiptDetailId  TRecordId,
          @vFromLPNOwnership        TOwnership,
          @vFromLPNUDF5             TUDF,
          @vFromLPNTaskId           TRecordId,
          @vFromLPNDtl_InnerPacks   TInnerPacks,
          @vFromLPNDtl_Quantity     TQuantity,

          /* To LPN */
          @vToLPNStatus             TStatus,
          @vToLPNType               TTypeCode,
          @vToLPNOnhandStatus       TStatus,
          @vToLPNQuantity           TQuantity,
          @vToLPNSKUId              TRecordId,
          @vToLocationId            TRecordId,
          @vToLPNOwnership          TOwnership,

          @vActivityType            TActivityType,
          @vExport                  TFlag,
          @vExportTrans             TDescription,
          @vTransType               TTypeCode,
          @vTransQty                TQuantity,
          @xmlTransferInfo          XML,
          @vAuditComment            TVarChar,
          @vXmlResultvar            XML,
          @vXmlLPNDetails           XML,
          @vUOMEADescription        TDescription,
          @vUOMCSDescription        TDescription,
          @vActivityLogId           TRecordId,
          @vDefaultUoM              TUoM,
          @vSKUUoM                  TUoM,
          @vEnableUoM               TControlValue;
begin /* pr_RFC_TransferInventory */
begin try
  begin transaction;
  SET NOCOUNT ON;

  /* Read values from input xml */
  select @FromLPNId           = Record.Col.value('FromLPNId[1]',                  'TRecordId'),
         @FromLPN             = Record.Col.value('FromLPN[1]',                    'TLPN'),
         @FromLocationId      = Record.Col.value('FromLocationId[1]',             'TRecordId'),
         @FromLocation        = Record.Col.value('FromLocation[1]',               'TLocation'),
         @SelectedLPNId       = Record.Col.value('CurrentLPNId[1]',               'TRecordId'),
         @SelectedLPNDetailId = Record.Col.value('CurrentLPNDetailId[1]',         'TRecordId'),
         @CurrentSKUId        = Record.Col.value('CurrentSKUId[1]',               'TRecordId'),
         @CurrentSKU          = Record.Col.value('CurrentSKU[1]',                 'TSKU'),
         @NewInnerPacks       = Record.Col.value('NewInnerPacks[1]',              'TInnerPacks'),
         @TransferQuantity    = Record.Col.value('TransferQuantity[1]',           'TQuantity'),
         @ToLPNId             = Record.Col.value('ToLPNId[1]',                    'TRecordId'),
         @ToLPN               = Record.Col.value('ToLPN[1]',                      'TLPN'),
         @ToLocationId        = Record.Col.value('ToLocationId[1]',               'TRecordId'),
         @ToLocation          = Record.Col.value('ToLocation[1]',                 'TLocation'),
         @DestinationLocOrLPN = Record.Col.value('DestinationLocationOrLPN[1]',   'TVarchar'),
         @ReasonCode          = Record.Col.value('ReasonCode[1]',                 'TReasonCode'),
         @Operation           = Record.Col.value('Operation[1]',                  'TOperation'),
         @BusinessUnit        = Record.Col.value('BusinessUnit[1]',               'TBusinessUnit'),
         @UserId              = Record.Col.value('UserId[1]',                     'TUserId')
  from @XmlInput.nodes('TransferInventory') as Record(Col);

  select @FromLPNId           = nullif(@FromLPNId, 0),
         @FromLPN             = nullif(@FromLPN, 'X'),
         @FromLocationId      = nullif(@FromLocationId, 0),
         @FromLocation        = nullif(@FromLocation, 'X'),
         @ToLPNId             = nullif(@ToLPNId, 0),
         @ToLPN               = nullif(@ToLPN, 'X'),
         @ToLocationId        = nullif(@ToLocationId, 0),
         @ToLocation          = nullif(@ToLocation, 'X'),
         @DestinationLocOrLPN = nullif(@DestinationLocOrLPN, ''),
         @TransferQuantity    = coalesce(@TransferQuantity, 0),
         @NewInnerPacks       = coalesce(@NewInnerPacks, 0),
         @vFromLPNQuantity    = 0,
         @ReasonCode          =  nullif(@ReasonCode, '132'); /*  As per Previous code we are sending the '219' as default ReasonCode in case 'ReasonCode field is disabled from controls */

  select @vEnableUoM = dbo.fn_Controls_GetAsString('Inv_' + @Operation, 'EnableUoM', 'N' /* No */, @BusinessUnit, @UserId);

  /*----------------- Identify Inputs From/To & SKU ------------------*/

  /* Find out whether user scanned destination as LPN or Location */
  if (@DestinationLocOrLPN is not null)
    exec pr_LPNs_IdentifyLPNOrLocation @DestinationLocOrLPN, @BusinessUnit, @UserId,
                                       @Destination out, @ToLPNId out, @ToLPN out,
                                       @ToLocationId out, @ToLocation out;

  /* User may be transferring inventory from Location or LPN, identify source based on the
     scanned entity */
  if (@FromLocation is not null)
    exec pr_LPNs_IdentifyLPNOrLocation @FromLocation, @BusinessUnit, @UserId,
                                       @Source out, @FromLPNId out, @FromLPN out,
                                       @FromLocationId out, @FromLocation out;
  else
  if (@FromLPN is not null)
    exec pr_LPNs_IdentifyLPNOrLocation @FromLPN, @BusinessUnit, @UserId,
                                       @Source out, @FromLPNId out, @FromLPN out,
                                       @FromLocationId out, @FromLocation out;

  select @CurrentSKUId      = SKUId,
         @CurrentSKU        = SKU,
         @vSKUUoM           = UoM,
         @vCurrentSKUStatus = Status
  from fn_SKUs_GetScannedSKUs(@CurrentSKU, @BusinessUnit); -- User can scan UPC as well

  /* ----------------- Source ------------------  */

  if (@Source = 'LOC')
    begin
      /* Get FromLocation Details and its Location */
      select @vFromLocationId     = LocationId,
             @vFromLocation       = Location,
             @vFromLocationType   = LocationType,
             @vFromLocStorageType = StorageType,
             @vFromWarehouse      = Warehouse
      from Locations
      where (LocationId = dbo.fn_Locations_GetScannedLocation (@FromLocationId, @FromLocation,  null /* DeviceId */, @UserId, @BusinessUnit));

      /* If caller has passed in LPNId & LPNDetailId get information from it */
      select @vFromLPNId = @SelectedLPNId;

      /* If caller didn't pass LPNId, there could be multiple LPNs in the Loc (like in a multi SKU picklane)
         so find the one by SKU */
      if (@vFromLPNId is null)
        select @vFromLPNId = LPNId
        from LPNs
        where (LocationId = @vFromLocationId) and (SKUId = @CurrentSKUId);
    end
  else
    begin /* @Source = 'LPN' */
      /* Get FromLPNId */
      select @vFromLPNId = dbo.fn_LPNs_GetScannedLPN(@FromLPN, @BusinessUnit, default /* Options */);
    end

  /* get all the LPN Details. Whether user scanned LPN or Location, we should have
     a FromLPNId and we use that to get the LPN Details */
  select @vFromLPNId              = LPNId,
         @vFromLPN                = LPN,
         @vFromLPNType            = LPNType,
         @vFromLPNStatus          = Status,
         @vFromLPNInnerPacks      = InnerPacks,
         @vFromLPNQuantity        = Quantity,
         @vFromWarehouse          = DestWarehouse,
         @vFromLPNOrderId         = OrderId,
         @vFromLPNWaveId          = PickBatchId,
         @vFromLPNWaveNo          = PickBatchNo,
         @vFromLPNReceiptId       = ReceiptId,
         @vFromLPNStatus          = Status,
         @vFromLPNOnhandStatus    = OnhandStatus,
         @vFromLPNLot             = Lot,
         @vFromLPNOwnership       = Ownership,
         @vFromLPNInventoryClass1 = InventoryClass1,
         @vFromLPNInventoryClass2 = InventoryClass2,
         @vFromLPNInventoryClass3 = InventoryClass3
  from LPNs
  where (LPNId = @vFromLPNId);

  /* If caller has passed LPNDetailId then just use it */
  if (@SelectedLPNDetailId is not null)
    select @vFromLPNDetailId        = LPNDetailId,
           @vFromLPNOnhandStatus    = OnhandStatus,
           @vFromLPNDtl_Quantity    = Quantity,
           @vFromLPNDtl_InnerPacks  = InnerPacks,
           @vFromUnitsPerPackage    = UnitsPerInnerPack,
           @vFromLPNOrderDetailId   = OrderDetailId,
           @vFromLPNReceiptDetailId = ReceiptDetailId
    from vwLPNDetails
    where (LPNDetailId = @SelectedLPNDetailId);
  else
    /* We should be able to transfer from an Allocated LPN if there is no pick task */
    select @vFromLPNDetailId        = LPNDetailId,
           @vFromLPNOnhandStatus    = OnhandStatus,
           @vFromLPNDtl_Quantity    = Quantity,
           @vFromLPNDtl_InnerPacks  = InnerPacks,
           @vFromUnitsPerPackage    = UnitsPerInnerPack,
           @vFromLPNOrderDetailId   = OrderDetailId,
           @vFromLPNReceiptDetailId = ReceiptDetailId
    from vwLPNDetails
    where (LPNId = @vFromLPNId) and
          ((LPNStatus in ('K','D','G','L','E' /* Picked, Packed, Packing, Loaded, Staged */) and OnhandStatus = 'R' /* Reserved */) or
           ((LPNStatus = 'A' /* Allocated */) and (@vFromLPNTaskId = 0) and (OnhandStatus = 'R' /* Reserved */)) or
           (LPNStatus in ('R','N' /* Received, New */) and OnhandStatus = 'U' /* Unavailable */) or
           (LPNStatus = 'P' /* Putaway */  and OnhandStatus = 'A' /* Available */)) and
          (SKU   = @CurrentSKU) and
          (Quantity > 0)
    order by LPNDetailId desc;

  if (@Destination = 'LOC')
    begin
      /* Get ToLocation Details and its Location */
      select @ToLocationId      = LocationId,
             @vToLocationId     = LocationId,
             @ToLocation        = Location,
             @vToLocationType   = LocationType,
             @vToLocStorageType = StorageType,
             @vToWarehouse      = Warehouse
      from Locations
      where (LocationId  = dbo.fn_Locations_GetScannedLocation (@ToLocationId, @ToLocation, null /* DeviceId */, @UserId, @BusinessUnit));

      /* There could be multiple LPNs in the Loc (like in a multi SKU picklane)
         so find the one by SKU
         There might not be any LPNs (logical) for this SKU in this location as well!! */
      /* Find the LPN which is matching the source LPN Lot and Ownership */
      select @vToLPNId        = LPNId,
             @vToLPNStatus    = Status,
             @vToLPNOwnership = Ownership
      from LPNs
      where (LocationId        = @ToLocationId) and
            (SKUId             = @CurrentSKUId) and
            (Ownership         = @vFromLPNOwnership) and
            (InventoryClass1   = @vFromLPNInventoryClass1) and
            (coalesce(Lot, '') = coalesce(@vFromLPNLot, ''));

      /* if SKU does not exists in location, we need to add. So, set Owner to be FromOwner to pass the validation */
      select @vToLPNOwnership = coalesce(@vToLPNOwnership, @vFromLPNOwnership);
    end
  else
    begin /* @Destination = 'LPN' */
      /* Get ToLPN Details */
      select @vToLPNId           = LPNId,
             @ToLPN              = LPN,
             @vToLPNType         = LPNType,
             @vToLPNStatus       = Status,
             @vToLPNOnhandStatus = OnhandStatus,
             @vToLPNQuantity     = Quantity,
             @vToWarehouse       = DestWarehouse,
             @vToOrderId         = OrderId,
             @vToLPNSKUId        = SKUId,
             @vToReceiptId       = ReceiptId,
             @vToLPNOwnership    = Ownership
      from LPNs
      where (LPNId = dbo.fn_LPNs_GetScannedLPN(@ToLPN, @BusinessUnit, default /* Options */));
    end

  /* select ToLine to transfer to - if transferring available/reserved inventory, then transfer
     to the corresponding line only */
  /* If user is trying to transfer innerpacks then find out the line which has innerpacks and with
     units per package is same as from LPN detail units per package else create a new line */
  if (@NewInnerpacks > 0)
    select @vToLPNDetailId = LPNDetailId
    from LPNDetails
    where (LPNId           = @vToLPNId) and
          (SKUId           = @CurrentSKUId) and
          (InnerPacks      > 0) and
          (UnitsPerPackage = @vFromUnitsPerPackage) and
          (OnhandStatus    = @vFromLPNOnhandStatus);
  else
    select @vToLPNDetailId = LPNDetailId
    from LPNDetails
    where (LPNId        = @vToLPNId) and
          (SKUId        = @CurrentSKUId) and
          (OnhandStatus = @vFromLPNOnhandStatus) and
          (InnerPacks   = 0);

  /* if User gives InnerPacks only, then we need to calculate Quantity and vice versa */
  if ((@NewInnerPacks > 0) and (@TransferQuantity = 0))
    select @TransferQuantity = (@vFromUnitsPerPackage * @NewInnerPacks);
  else
  /* Calculate InnerPacks only if the quantity is greater than zero and is in multiples of InnerPack quantity
     If Quantity is not multiple of InnerPacks do not change it, let Validate proc error out */
  if ((@TransferQuantity > 0) and (@NewInnerPacks = 0) and (coalesce(@vFromUnitsPerPackage, 0) > 0) and ((@TransferQuantity % @vFromUnitsPerPackage) = 0))
    select @NewInnerPacks  = (@TransferQuantity / @vFromUnitsPerPackage);

  /* Build an xml with the values to validate */
  select @xmlTransferInfo = (select @Source                      as Source,
                                    @Destination                 as Destination,

                                    @CurrentSKUId                as TransferSKUId,
                                    @NewInnerPacks               as TransferInnerPacks,
                                    @TransferQuantity            as TransferQuantity,

                                    /* From Info */
                                    @vFromLPNId                  as FromLPNId,
                                    @vFromLPNDetailId            as FromLPNDetailId,
                                    @vFromLocationId             as FromLocationId,

                                    /* To Info */
                                    @vToLPNId                    as ToLPNId,
                                    @vToLocationId               as ToLocationId
                             for xml raw('TRANSFERINVENTORYVALIDATIONINFO'), elements);

  /* Add to RF Log */
  exec pr_RFLog_Begin @XmlInput, @@ProcId, @BusinessUnit, @UserId, null /* @DeviceId */,
                      @vFromLPNId, @vFromLPN, 'FromLPN', @Operation,
                      @Value1 = @vToLPNId, @Value2 = @ToLPN,
                      @ActivityLogId = @vActivityLogId output;

  /* Transfer Validations */
  exec @vReturnCode = pr_Inventory_ValidateTransferInventory @xmlTransferInfo, @Operation,
                                                             @BusinessUnit, @UserId;

  if (@vReturnCode > 0)
    goto ErrorHandler;

  select @vActivityType = 'InvTransfer' + rtrim(@Source) + 'To' + rtrim(@Destination);
  -- deprecated, see @vExportTrans below
         -- @vExportWHXfer = case when ((coalesce(@vToLPNStatus,   '') <> 'N' /* New */) and
         --                             (coalesce(@vFromWarehouse, '') <> coalesce(@vToWarehouse, ''))) then
         --                             'Y'
         --                       else 'N'
         --                  end;

  /* Determine the type of exports to be generated due to the transfer.
     a. If transferring into a new LPN, then there is no export to be generated as the New LPN
        would get the Status, OnhandStatus, WH, Ownership etc. of the From LPN
     b. If transferring from a new LPN to a Location or another LPN, then it is an inventory change
        Note that transferring form New to New LPN is already handled above and there are no exports
     c. If transferring the inventory from Warehouse A to Warehouse B then need to send the WHXfer changes
   */
  select @vExportTrans = case when (coalesce(@vToLPNStatus,   '') = 'N' /* New */) then 'None'
                              when (coalesce(@vFromLPNStatus, '') = 'N' /* New */) then 'InvCh'
                              when (@vFromLPNStatus = 'R' /* Received */) and
                                   (((@Destination = 'LOC') and (@vToLocationType = 'K' /* Picklane */)) or
                                    ((@Destination = 'LPN') and (@vToLPNOnhandStatus = 'A' /* Available */))) then 'Recv'
                              when (coalesce(@vFromWarehouse, '') <> coalesce(@vToWarehouse, '')) then 'WHXfer'
                              else 'None'
                         end;

  /* Earlier we have individual procedures generating exports on WHXFer, now we have consolidated that
     into one procedure Exports_WarehouseXFer which is called below, so turn off the previous way of
     exports. */
  select @vExport = 'N';

  /* If the Source and Destination is LPNs, then Transfer the units using the below procedure */
  if ((@Source = 'LPN') and (@Destination = 'LPN'))
    begin
      /* User will pass innerpacks or Quantity. So we need to calculate the values
         based on the input. that will taken care by the below procedure and will
         return the transfered Innerpacks and Quantity for the other usage (We are using
         those in while exporting data). Because we do not need to calculate again the same thing
         in this procedure. */
      exec @vReturncode = pr_Inventory_TransferUnits @vFromLPNId,
                                                     @vFromLPNDetailId,
                                                     @CurrentSKUId,
                                                     @NewInnerPacks output,
                                                     @TransferQuantity output,
                                                     @vToLPNId,
                                                     @vExport,
                                                     @ReasonCode,  /* Reason Code */
                                                     default,       /* Operation */
                                                     @BusinessUnit,
                                                     @UserId,
                                                     @vToLPNDetailId output;

      /* if there are any errors then goto Error handler or else go to EandA
         to generate Exports and Audit trail info for the transaction */
      if (@vReturnCode <> 0) goto ErrorHandler;
    end
  else
    /* LPN -> LOC or LOC -> LOC or LOC -> LPN */
    begin
      /* If the Destination is LPN, then adjust the quantity in the LPN
      If the Destination is a Location, then call AddSKUToPicklane
       - which might have to create an LPN and add SKU to it or
         will adjust the LPN which has the SKU if one already exists */
      if (@Destination = 'LPN')
        begin
          exec @vReturnCode = pr_LPNs_AdjustQty @vToLPNId,
                                                @vToLPNDetailId,
                                                @CurrentSKUId,
                                                @CurrentSKU,
                                                @NewInnerPacks,
                                                @TransferQuantity,
                                                '+' /* Update Option - Add Qty */,
                                                @vExport,
                                                @ReasonCode,  /* Reason Code */
                                                null, /* Reference */
                                                @BusinessUnit,
                                                @UserId;

          /* Update Destination LPN with the Source LPN (Owner and Warehouse) if the
             Destination LPN status is New */
          if (@vToLPNStatus = 'N'/* New */)
            begin
              update L1
              set Ownership       = L2.Ownership,
                  DestWarehouse   = L2.DestWarehouse,
                  Status          = L2.Status,
                  OnhandStatus    = L2.OnhandStatus,
                  Lot             = L2.Lot,
                  InventoryClass1 = L2.InventoryClass1,
                  InventoryClass2 = L2.InventoryClass2,
                  InventoryClass3 = L2.InventoryClass3
              from LPNs L1, LPNs L2
              where (L1.LPNId = @vToLPNId) and (L2.LPNId = @vFromLPNId);

              update LPNDetails
              set OnhandStatus = @vFromLPNOnhandStatus,
                  Lot          = @vFromLPNLot
              where (LPNId = @vToLPNId);
            end
        end
      else /* @Destination = 'Location' */
        begin
          /* If destination is picklane unit storage then dont send innerpack quantity */
          if ( (@vToLocationType = 'K'/* Picklane */) and (@vToLocStorageType = 'U'/* Units */))
            select @vNewInnerPacks = 0
          else
            select @vNewInnerPacks = @NewInnerPacks;

          /* Call pr_Locations_AddSKUQuantity to verify and relieve replenish lines first or
             just add inventory/SKU later */
          exec pr_Locations_AdjustSKUQuantity 'TransferInventory' /* Operation */,
                                              @vToLocationId,
                                              @CurrentSKUId,
                                              @vNewInnerPacks,
                                              @TransferQuantity,
                                              @vFromLPNLot,
                                              @vFromLPNOwnership,
                                              @vFromLPNInventoryClass1,
                                              @vFromLPNInventoryClass2,
                                              @vFromLPNInventoryClass3,
                                              @vFromLPNOrderId,
                                              @ReasonCode,
                                              @vExport,
                                              @vToLPNId output,
                                              @vToLPNDetailId output,
                                              @BusinessUnit, @UserId;

          /* If the LPN being transferred is assigned to a Lot than LPN received or created could be
            designated to some order to carry Lot info to destination LPN */
          /* Update InventoryClass on picklane LPN */
          /* Special case - if Transfer to Picklane is happening after Picking,
             need to transfer FromLPN OrderId/OrderDetailId to ToLPN/LPNDetails */
          update LPNs
          set Status          = case when @Operation = 'TransferAfterPicking' then 'K' /* Picked */   else Status       end,
              OnhandStatus    = case when @Operation = 'TransferAfterPicking' then 'R' /* Reserved */ else OnhandStatus end,
              OrderId         = case when @Operation = 'TransferAfterPicking' then @vFromLPNOrderId   else OrderId      end,
              PickBatchId     = case when @Operation = 'TransferAfterPicking' then @vFromLPNWaveId    else PickBatchId  end,
              PickBatchNo     = case when @Operation = 'TransferAfterPicking' then @vFromLPNWaveNo    else PickBatchNo  end,
              Lot             = coalesce(@vFromLPNLot, ''),
              InventoryClass1 = @vFromLPNInventoryClass1,
              InventoryClass2 = @vFromLPNInventoryClass2,
              InventoryClass3 = @vFromLPNInventoryClass3
          where (LPNId = @vToLPNId);

          /* Update lot on LPN Detail */
          update LPNDetails
          set OnhandStatus    = case when @Operation = 'TransferAfterPicking' then 'R' /* Reserved */     else OnhandStatus  end,
              OrderId         = case when @Operation = 'TransferAfterPicking' then @vFromLPNOrderId       else OrderId       end,
              OrderDetailId   = case when @Operation = 'TransferAfterPicking' then @vFromLPNOrderDetailId else OrderDetailId end,
              Lot             = coalesce(@vFromLPNLot, ''),
              InventoryClass1 = @vFromLPNInventoryClass1,
              InventoryClass2 = @vFromLPNInventoryClass2,
              InventoryClass3 = @vFromLPNInventoryClass3
          where (LPNId = @vToLPNId) and
                (SKUId = @CurrentSKUId);
        end

      if (@vReturnCode <> 0)
        goto ErrorHandler;

     /* From Location or LPN Add the Quantity  */
     if (@Source = 'LPN')
       exec @vReturnCode = pr_LPNs_AdjustQty @vFromLPNId,
                                             @vFromLPNDetailId,
                                             @CurrentSKUId,
                                             @CurrentSKU,
                                             @NewInnerPacks,
                                             @TransferQuantity,
                                             '-' /* Update Option - Subtract Qty */,
                                             @vExport,
                                             @ReasonCode,  /* Reason Code  */
                                             null, /* Reference */
                                             @BusinessUnit,
                                             @UserId;
     else
       begin
         exec @vReturncode = pr_Locations_AddSKUToPicklane @CurrentSKUId,
                                                           @vFromLocationId,
                                                           @NewInnerPacks,
                                                           @TransferQuantity,
                                                           @vFromLPNLot,
                                                           @vFromLPNOwnership,
                                                           @vFromLPNInventoryClass1,
                                                           @vFromLPNInventoryClass2,
                                                           @vFromLPNInventoryClass3,
                                                           '-', /* Update Option - Subtract */
                                                           @vExport,
                                                           @UserId,
                                                           @ReasonCode;
       end
    end

  /* Generate Exports 'Recv' when inventory has been transfered from a Received LPN into a Picklane
     or to another LPN (which has already been putaway) */
  if (@vFromLPNStatus = 'R' /* Received */) and
     (((@Destination = 'LOC') and (@vToLocationType = 'K' /* Picklane */)) or
      ((@Destination = 'LPN') and (@vToLPNOnhandStatus = 'A' /* Available */)))
    exec @vReturnCode = pr_Exports_LPNReceiptConfirmation @LPNId         = @vFromLPNId,
                                                          @LPNDetailId   = @vFromLPNDetailId,
                                                          @PAQuantity    = @TransferQuantity,
                                                          @ToLocationId  = @vToLocationId,
                                                          @FromWarehouse = @vFromWarehouse,
                                                          @CreatedBy     = @UserId;
  else
  if (@vExportTrans = 'InvCh')
    exec @vReturnCode = pr_Exports_LPNData 'InvCh' /* Inventory Changes */,
                                           @LPNId        = @vToLPNId,
                                           @LPNDetailId  = @vToLPNDetailId,
                                           @LocationId   = @vToLocationId,
                                           @SKUId        = @CurrentSKUId,
                                           @TransQty     = @TransferQuantity,
                                           @ReasonCode   = @ReasonCode,
                                           @BusinessUnit = @BusinessUnit,
                                           @CreatedBy    = @UserId;
  else
  if (@vExportTrans = 'WhXfer')
    begin
      /* if user transfers the inventory from Putaway LPN to other Putaway LPN, with different SKU & Warehouse
         then the entire line is transferred from FromLPN to ToLPN. So FromLPN would not have that line anymore.
         here we are unable to export SKUId on -/+ TransQty exports transactions. So we need to pass FromLPNdetaild
         as well to handle this scenario

         If @FromLPNDetailId = @vToLPNDetailId  --> Entire line transfered so we need to intilize the @FromLPNDetailId equal to @vToLPNDetailId
         If No details exists with FromLPNDetailId then LPN does not have that LPN or its consumed so we need to consider the ToLPNDetailId as FromLPNDetailId
         If @FromLPNDetailId <> @vToLPNDetailId --> Partial line transfered so we need to intilize the @vFromLPNDetailId = @FromLPNDetailId */
      select @vFromLPNDetailId = case when (@vFromLPNDetailId = @vToLPNDetailId) or
                                           (not exists (select * from LPNDetails where LPNDetailId = @vFromLPNDetailId)) then @vToLPNDetailId
                                      else @vFromLPNDetailId
                                 end

      exec @vReturnCode = pr_Exports_WarehouseTransfer @TransType       = @vTransType,
                                                       @LPNId           = @vToLPNId, -- Use local variable instead of i/p param as caller may pass LPN or LPNId
                                                       @LPNDetailId     = @vToLPNDetailId,
                                                       @FromLPNId       = @vFromLPNId,
                                                       @FromLPNDetailId = @vFromLPNDetailId,
                                                       @LocationId      = @vToLocationId,
                                                       @SKUId           = @CurrentSKUId,
                                                       @TransQty        = @TransferQuantity,
                                                       @OldWarehouse    = @vFromWarehouse,
                                                       @NewWarehouse    = @vToWarehouse,
                                                       @ReasonCode      = @ReasonCode,
                                                       @BusinessUnit    = @BusinessUnit,
                                                       @CreatedBy       = @UserId;
    end
  else

  if (@vReturnCode <> 0) goto ErrorHandler;

  /* Fetch the UOM description */
  select @vUOMEADescription = case when LookUpCode = 'EA' then LookUpDescription end,
         @vUOMCSDescription = case when LookUpCode = 'CS' then LookUpDescription end
  from LookUps
  where (LookUpCategory = 'UOM');

  /* Default UoM is the UoM that will be shown to the RF user by default */
  select @vDefaultUoM = case
                          when (@vFromLPNInnerPacks > 0) then 'CS'
                          else coalesce(@vSKUUoM, 'EA')
                        end;

  /* Send the details back to device of the FromLPN for further transfers. We have to use
     FromLPN instead of FromLPNId to handle multi-SKU picklanes. If we used FromLPNId we would
     return details of only one SKU */
  /* TD- 07/20- Tep fix for performance */
  /* if (@Source = 'LPN')
    set @vXmlLPNDetails =  (select LPNId, LPN, LPNDetailId, LPNLine, LPNType, CoO, SKUId, SKU,
                               coalesce(SKU1,'') SKU1, coalesce(SKU2, '') SKU2, coalesce(SKU3,'') SKU3, coalesce(SKU4,'') SKU4, coalesce(SKU5, '')SKU5,
                               coalesce(SKUDescription, SKU) SKUDescription,  UOM, OnhandStatus, OnhandStatusDescription,
                               InnerPacks, Quantity, UnitsPerPackage, ReceivedUnits, ShipmentId,
                               LoadId, ASNCase, LocationId, Location, Barcode, OrderId, PickTicket,
                               SalesOrder, OrderDetailId, OrderLine, ReceiptId, ReceiptNumber,
                               ReceiptDetailId, ReceiptLine, Weight, Volume, Lot, LastPutawayDate,
                               UDF1, UDF2, UDF3, UDF4, UDF5, BusinessUnit, coalesce(@vDefaultUoM, DefaultUoM) as DefaultUoM, @vEnableUoM as EnableUoM,
                               case when InnerPacks > 0 then convert(varchar(5),InnerPacks) + ' ' + @vUOMCSDescription + '/'+ convert(varchar(5),Quantity) + ' ' + @vUOMEADescription
                                    else convert(varchar(5),Quantity)    + ' ' + @vUOMEADescription
                               end DisplayQuantity
                            from vwLPNDetails
                            where ((LPNId      = @vFromLPNId) and (Quantity > 0))
                            order by SKU
                            FOR XML AUTO, ELEMENTS XSINIL, ROOT('vwLPNDetailDto'));
   else
   if (@Source = 'LOC')
     set @vXmlLPNDetails =  (select LPNId, LPN, LPNDetailId, LPNLine, LPNType, CoO, SKUId, SKU,
                               coalesce(SKU1,'') SKU1, coalesce(SKU2, '') SKU2, coalesce(SKU3,'') SKU3, coalesce(SKU4,'') SKU4, coalesce(SKU5, '')SKU5,
                               coalesce(SKUDescription, SKU) SKUDescription,  UOM, OnhandStatus, OnhandStatusDescription,
                               InnerPacks, Quantity, UnitsPerPackage, ReceivedUnits, ShipmentId,
                               LoadId, ASNCase, LocationId, Location, Barcode, OrderId, PickTicket,
                               SalesOrder, OrderDetailId, OrderLine, ReceiptId, ReceiptNumber,
                               ReceiptDetailId, ReceiptLine, Weight, Volume, Lot, LastPutawayDate,
                               UDF1, UDF2, UDF3, UDF4, UDF5, BusinessUnit, coalesce(@vDefaultUoM, DefaultUoM) as DefaultUoM, @vEnableUoM as EnableUoM,
                               case when InnerPacks > 0 then convert(varchar(5),InnerPacks) + ' ' + @vUOMCSDescription + '/'+ convert(varchar(5),Quantity) + ' ' + @vUOMEADescription
                                    else convert(varchar(5),Quantity)    + ' ' + @vUOMEADescription
                               end DisplayQuantity
                            from vwLPNDetails
                            where (LocationId = @vFromLocationId)
                            order by SKU
                            FOR XML AUTO, ELEMENTS XSINIL, ROOT('vwLPNDetailDto')); */

  /* Audit Trail */
  exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */,
                            @LPNId        = @vFromLPNId,
                            @LocationId   = @vFromLocationId,
                            @ToLPNId      = @vToLPNId,
                            @ToLocationId = @vToLocationId,
                            @SKUId        = @CurrentSKUId,
                            @InnerPacks   = @NewInnerPacks,
                            @Quantity     = @TransferQuantity,
                            @ReasonCode   = @ReasonCode,
                            @Comment      = @vAuditComment output;

  /* Build Success Message */
  exec pr_BuildRFSuccessXML @vAuditComment, @vXmlResultvar output;

  select @XmlResult = dbo.fn_XMLNode('TransferInventoryInfo',
                        cast(coalesce(@vXmlResultvar, '') as varchar(max)) +
                        cast(coalesce(@vXmlLPNDetails, '') as varchar(max)));

  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

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
end /* pr_RFC_TransferInventory */

Go
