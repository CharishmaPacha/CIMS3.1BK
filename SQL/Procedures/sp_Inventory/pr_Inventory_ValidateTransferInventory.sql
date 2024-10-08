/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/11  TK/VS   pr_Inventory_ValidateTransferInventory: Fixes migrated from FB to drop picked pallet into bulk drop picklanes (BK-829)
  2021/04/27  RKC     pr_Inventory_ValidateTransferInventory: Made changes to does not allow to transfer the inventory from putaway LPN to pick lane locations (HA-2702)
  2021/04/13  AY      pr_Inventory_ValidateTransferInventory: Do not restrict transferring from reserved LPNs (HA GoLive)
  2021/02/16  TK      pr_Inventory_ValidateTransferInventory: Validation to restrict user transfer inventory below reserved quantity (CID-1724)
  2020/11/18  RKC     pr_Inventory_ValidateTransferInventory: Do not allow to transfer of the inventory until the receiver is closed (HA-1369)
  2020/06/06  MS/TK   pr_Inventory_ValidateTransferInventory: Changes to return validate messages if Location is not setup for SKU (HA-435 & 803)
  2020/05/05  RKC     pr_Inventory_ValidateTransferInventory: Made changes to validate if source and destination values is not valid (HA-380)
  2020/05/05  RKC     pr_Inventory_ValidateTransferInventory: Removed the Received LPN status in TransferInv_ToLPNUnavailable validation (HA-340)
  2020/04/30  MS      pr_Inventory_ValidateTransferInventory: Get the locationId from input (HA-294)
  2020/04/22  TK      pr_Inventory_ValidateTransferInventory: Moved Validations from rules to procedure (HA-222)
  2020/04/16  RKC     pr_Inventory_ValidateTransferInventory: Made changes to transfer the Received LPN to New LPN
  2020/04/15  TK      pr_Inventory_ValidateTransferInventory: Code revamp (HA-84)
  2020/04/14  VM      pr_Inventory_ValidateTransferInventory:
                      pr_Inventory_ValidateTransferInventory: Validation to restrict transfer inventory between LPNs if Inventory mismatch (HA-84)
  2019/03/19  RIA     pr_Inventory_ValidateTransferInventory: Made changes to validate Inactive SKUs when we transfer the inventory (HPI-2516)
  2019/02/28  VS      pr_Inventory_ValidateTransferInventory: Added Validation for Open Receiver against LPN to Location Transfer (CID-135)
  2018/12/13  RT      pr_Inventory_ValidateTransferInventory: Made changes to validate the OrderId when null passed and
  2018/09/26  DK      pr_Inventory_ValidateTransferInventory: Enhanced to use rules for additional validation (OB2-646)
                      pr_Inventory_ValidateTransferInventory: Validate SKU attributes while transferring inventory from LPN (S2GCA-26)
  2018/03/21  OK      pr_Inventory_ValidateTransferInventory: Changes to bypass the validations for replenishments to allow transfer reserved lines (S2G-469)
  2016/12/23  KL      pr_Inventory_ValidateTransferInventory: Added validation to restrict transfer inventory to Non-Empty LPN or LPN's which are not
  2016/11/14  KL      pr_Inventory_ValidateTransferInventory: Made minor changes to from LPNOrderId and ToLPN OrderId (HPI-1011)
  2016/06/14  TK      pr_Inventory_ValidateTransferInventory: Allow transfer Inventory even if the SKU is not configured for a dynamic Location (NBD-597)
  2016/04/10  AY      pr_Inventory_ValidateTransferInventory: Migrated enhancement to allow transfers into inactive locations
  2016/04/05  RV      pr_Inventory_ValidateTransferInventory: Validate Cross Ownership inventory transfer (NBD-305)
  2016/03/20  RV      pr_Inventory_ValidateTransferInventory: Validation changed with LocationId instead of LPNId to properly validate (NBD-304)
  2015/02/04  TK      pr_Inventory_ValidateTransferInventory: If ToLPN status is not new and ToLPN and FromLPN OrderId's
  2014/07/14  PK      pr_Inventory_ValidateTransferInventory: Bug fix to validate quantity.
  2014/05/14  PV      pr_Inventory_ValidateTransferInventory: Added validation to restrict the quantity to transfer in units equal to
  2014/05/01  PV      pr_Inventory_ValidateTransferInventory: Added validation to restrict the transfer of inner packs
  2014/04/28  PV      pr_Inventory_ValidateTransferInventory: Added validation to restrict the transfer of inventory
  2014/03/18  TD      pr_Inventory_TransferUnits, pr_Inventory_ValidateTransferInventory:Changes to
  2014/03/03  PK      pr_Inventory_ValidateTransferInventory: Allowing to transfer the inventory from
  2013/12/19  PK      pr_Inventory_ValidateTransferInventory: Included a validation for not allowing to transfer
  2013/11/25  TD      pr_Inventory_ValidateTransferInventory: Added few more validations.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Inventory_ValidateTransferInventory') is not null
  drop Procedure pr_Inventory_ValidateTransferInventory;
Go
/*------------------------------------------------------------------------------
  Proc pr_Inventory_ValidateTransferInventory:
  Params:
  @Operation: Would be used if there should be any operation specific validations

  Sample Input:
   @xmlTransferInfo :
      '<TRANSFERINVENTORYVALIDATIONINFO>
         <Source>LOC</Source>
         <FromLPNId>1531</FromLPNId>
         <FromLPNDetailId>1248</FromLPNDetailId>
         <FromLocationId>12069</FromLocationId>
         <Destination>LOC</Destination>
         <ToLPNId>12039</ToLPNId>
         <ToLocationId>12039</ToLocationId>
         <SKUId>7407</SKUId>
         <TransferInnerPacks>1</TransferInnerPacks>
         <TransferQuantity>5</TransferQuantity>
       </TRANSFERINVENTORYVALIDATIONINFO>'
------------------------------------------------------------------------------*/
Create Procedure pr_Inventory_ValidateTransferInventory
  (@xmlTransferInfo      XML,
   @Operation            TOperation = 'Xfer',
   @BusinessUnit         TBusinessUnit,
   @UserId               TUserId)
as
  declare @vReturnCode                    TInteger,
          @vMessageName                   TMessageName,
          @vNote1                         TDescription,

          /* Input Params */
          @SKUId                          TRecordId,
          @TransferInnerPacks             TInnerPacks,
          @TransferQuantity               TQuantity,
          @FromLPNId                      TRecordId,
          @FromLPNDetailId                TRecordId,
          @FromLocationId                 TRecordId,
          @ToLPNId                        TRecordId,
          @ToLocationId                   TRecordId,

          /* From */
          @vSource                        TString,
          @vFromLPNId                     TRecordId,
          @vFromLPNStatus                 TStatus,
          @vFromLPNOnhandStatus           TStatus,
          @vFromLPNReceiverStatus         TStatus,
          @vFromLPNInnerPacks             TQuantity,
          @vFromLPNQuantity               TQuantity,
          @vFromLPNAllocableQty           TQuantity,
          @vFromLPNDetailId               TRecordId,
          @vFromLPNOrderId                TRecordId,
          @vFromLPNOrderType              TTypeCode,
          @vFromLPNReceiptId              TRecordId,
          @vFromLPNReceiverId             TRecordId,
          @vFromLPNWarehouse              TWarehouse,
          @vFromLPNOwner                  TOwnership,
          @vFromLPNInventoryClass1        TInventoryClass,
          @vFromLPNInventoryClass2        TInventoryClass,
          @vFromLPNInventoryClass3        TInventoryClass,

          @vFromLPNDetailOnhandStatus     TStatus,
          @vFromLPNDetailAvailableQty     TInteger,

          @vFromLocationId                TRecordId,
          @vFromLocationType              TLocationType,
          @vFromLocStorageType            TStorageType,

          /* To */
          @vDestination                   TString,
          @vToLPNId                       TRecordId,
          @vToLPNType                     TTypeCode,
          @vToLPNStatus                   TStatus,
          @vToLPNOnhandStatus             TStatus,
          @vToLPNLineCount                TCount,
          @vToLPNQuantity                 TQuantity,
          @vToLPNDetailId                 TRecordId,
          @vToLPNOrderId                  TRecordId,
          @vToLPNReceiptId                TRecordId,
          @vToLPNWarehouse                TWarehouse,
          @vToLPNOwner                    TOwnership,
          @vToLPNInventoryClass1          TInventoryClass,
          @vToLPNInventoryClass2          TInventoryClass,
          @vToLPNInventoryClass3          TInventoryClass,

          @vToLocationId                  TRecordId,
          @vToLocationType                TLocationType,
          @vToLocStorageType              TStorageType,
          @vToLocationSubType             TTypeCode,
          @vToLocationStatus              TStatus,

          @vTransferSKUId                 TRecordId,
          @vTransferSKUStatus             TStatus,

          @vTransferInnerPacks            TInnerpacks,
          @vTransferQuantity              TQuantity,

          @vXmlRulesData                  TXML,

          @vAllowTransferToUnassignedLoc  TControlvalue,
          @vAllowTransferToInactiveLoc    TControlValue,
          @vAllowMoveBetweenWarehouses    TControlValue,
          @vInvalidFromLPNStatuses        TControlValue,
          @vInvalidToLPNStatuses          TControlValue,
          @vAllowNewInvBeforeReceiverClose
                                          TControlValue;
begin
begin try

  /* Get the input values */
  /* Get the values from the xml paramter */
  select @vSource                      = Record.Col.value('Source[1]',                     'TString'),
         @vDestination                 = Record.Col.value('Destination[1]',                'TString'),
         @SKUId                        = Record.Col.value('TransferSKUId[1]',              'TRecordId'),
         @vTransferInnerPacks          = Record.Col.value('TransferInnerPacks[1]',         'TQuantity'),
         @vTransferQuantity            = Record.Col.value('TransferQuantity[1]',           'TQuantity'),

         /* From Info */
         @FromLPNId                    = Record.Col.value('FromLPNId[1]',                  'TRecordId'),
         @FromLPNDetailId              = Record.Col.value('FromLPNDetailId[1]',            'TRecordId'),

         /* To Info */
         @ToLPNId                      = Record.Col.value('ToLPNId[1]',                    'TRecordId'),
         @vToLocationId                = Record.Col.value('ToLocationId[1]',               'TRecordId')

  from @xmlTransferInfo.nodes('TRANSFERINVENTORYVALIDATIONINFO') as Record(Col);

  /* Get the SKU info */
  select @vTransferSKUId     = SKUId,
         @vTransferSKUStatus = Status
  from SKUs
  where (SKUId = @SKUId);

  /* From LPN info */
  select @vFromLPNId              = LPNId,
         @vFromLPNStatus          = Status,
         @vFromLPNOnhandStatus    = OnhandStatus,
         @vFromLPNQuantity        = Quantity,
         @vFromLPNAllocableQty    = Quantity - ReservedQty,
         @vFromLPNInnerPacks      = InnerPacks,
         @vFromLocationId         = LocationId,
         @vFromLPNOrderId         = OrderId,
         @vFromLPNReceiptId       = ReceiptId,
         @vFromLPNReceiverId      = ReceiverId,
         @vFromLPNWarehouse       = DestWarehouse,
         @vFromLPNOwner           = Ownership,
         @vFromLPNInventoryClass1 = InventoryClass1,
         @vFromLPNInventoryClass2 = InventoryClass2,
         @vFromLPNInventoryClass3 = InventoryClass3
  from LPNs
  where (LPNId = @FromLPNId);

  /* From LPNDetail Info */
  select @vFromLPNDetailOnhandStatus = OnhandStatus,
         @vFromLPNDetailAvailableQty = AllocableQty
  from LPNDetails
  where (LPNDetailId = @FromLPNDetailId);

  /* From Location info */
  select @vFromLocationId     = LocationId,
         @vFromLocationType   = LocationType,
         @vFromLocStorageType = StorageType
  from Locations
  where (LocationId = @vFromLocationId);

  /* From LPN Order info */
  select @vFromLPNOrderType = OrderType
  from OrderHeaders
  where (OrderId = @vFromLPNOrderId);

  /* To LPN Info */
  select @vToLPNId              = LPNId,
         @vToLPNType            = LPNType,
         @vToLPNStatus          = Status,
         @vToLPNOnhandStatus    = OnhandStatus,
         @vToLPNQuantity        = Quantity,
         @vToLocationId         = LocationId,
         @vToLPNOrderId         = OrderId,
         @vToLPNReceiptId       = ReceiptId,
         @vToLPNWarehouse       = DestWarehouse,
         @vToLPNOwner           = Ownership,
         @vToLPNInventoryClass1 = InventoryClass1,
         @vToLPNInventoryClass2 = InventoryClass2,
         @vToLPNInventoryClass3 = InventoryClass3
  from LPNs
  where (LPNId = @ToLPNId);

  /* To Location info */
  select @vToLocationType    = LocationType,
         @vToLocStorageType  = StorageType,
         @vToLocationSubType = LocationSubType,
         @vToLocationStatus  = Status,
         /* When ToLPN info is not available - happens only when transferring to a Picklane
            which does not yet have the SKU being transferred, use Location info */
         @vToLPNWarehouse    = coalesce(@vToLPNWarehouse, Warehouse),
         @vToLPNOwner        = coalesce(@vToLPNOwner,     Ownership)
  from Locations
  where (LocationId = @vToLocationId);

  /* Get the From LPN receivers status */
  select @vFromLPNReceiverStatus = Status
  from Receivers
  where (ReceiverId = @vFromLPNReceiverId);

  /* Get the control variables */
  select @vAllowMoveBetweenWarehouses       = dbo.fn_Controls_GetAsString('Inventory', 'MoveBetweenWarehouses', 'N' /* No */, @BusinessUnit, @UserId),
         @vAllowTransferToUnassignedLoc     = dbo.fn_Controls_GetAsString('Inventory', 'TransferToUnassignedLoc', 'N'/* No */, @BusinessUnit, @UserId),
         @vAllowTransferToInactiveLoc       = dbo.fn_Controls_GetAsString('Inventory', 'TransferToInactiveLoc', 'N'/* No */, @BusinessUnit, @UserId),
         @vInvalidFromLPNStatuses           = dbo.fn_Controls_GetAsString('TransferInventory', 'InvalidFromLPNStatuses', 'CFISTOV' /* Consumed, New Temp, Inactive, Shipped, In Transit, Lost, Voided */, @BusinessUnit, @UserId),
         @vInvalidToLPNStatuses             = dbo.fn_Controls_GetAsString('TransferInventory', 'InvalidToLPNStatuses', 'CISTOV' /* Consumed, Inactive, Shipped, In Transit, Lost, Voided */, @BusinessUnit, @UserId),
         @vAllowNewInvBeforeReceiverClose   = dbo.fn_Controls_GetAsString('Inventory', 'AllowNewInvBeforeReceiverClose', 'N' /* No */, @BusinessUnit, @UserId);

  /* Prepare XML for rules */
  select @vXmlRulesData = dbo.fn_XMLNode('Root',
                            dbo.fn_XMLNode('Source',                   @vSource) +
                            dbo.fn_XMLNode('Destination',              @vDestination) +
                            dbo.fn_XMLNode('FromLPNId',                @vFromLPNId) +
                            dbo.fn_XMLNode('FromLPNStatus',            @vFromLPNStatus) +
                            dbo.fn_XMLNode('FromLPNInventoryClass1',   @vFromLPNInventoryClass1) +
                            dbo.fn_XMLNode('FromLPNInventoryClass2',   @vFromLPNInventoryClass2) +
                            dbo.fn_XMLNode('FromLPNInventoryClass3',   @vFromLPNInventoryClass3) +
                            dbo.fn_XMLNode('FromLocationId',           @vFromLocationId) +
                            dbo.fn_XMLNode('FromLocationType',         @vFromLocationType) +
                            dbo.fn_XMLNode('ToLPNId',                  @vToLPNId) +
                            dbo.fn_XMLNode('ToLPNStatus',              @vToLPNStatus) +
                            dbo.fn_XMLNode('ToLPNInventoryClass1',     @vToLPNInventoryClass1) +
                            dbo.fn_XMLNode('ToLPNInventoryClass2',     @vToLPNInventoryClass2) +
                            dbo.fn_XMLNode('ToLPNInventoryClass3',     @vToLPNInventoryClass3) +
                            dbo.fn_XMLNode('ToLocationId',             @vToLocationId) +
                            dbo.fn_XMLNode('ToLocationType',           @vToLocationType));

  /* Get the LPNLine Count to check whether the ToLPN has the inventory in it or not */
  select @vToLPNLineCount = count(*)
  from LPNDetails
  where (LPNId    = @vToLPNId) and ((OnhandStatus = 'A') or (@vToLPNStatus = 'N')) and
        (Quantity > 0);

  /* Validations */
  if (@vSource is null)
    set @vMessageName = 'TransferInv_SourceNotIdentified';
  else
  if (@vDestination is null)
    set @vMessageName = 'TransferInv_DestinationNotIdentified'
  else
  if (@vTransferSKUStatus = 'I' /* Inactive */)
    set @vMessageName = 'SKUIsInactive';
  else
  /* If the FromLPN is not null then it validates FromLPN and TransferSKU */
  if (@vSource = 'LPN')
    begin
      if (@vFromLPNId is null)
        set @vMessageName = 'FromLPNDoesNotExist';
      else
      if (charindex(@vFromLPNStatus, @vInvalidFromLPNStatuses) > 0)
        set @vMessageName = 'TransferInv_LPNFromStatusIsInvalid';
      else
      if (@vFromLPNOnhandStatus = 'U' /* Unavailable */) and
         (@vFromLPNStatus not in ('N', 'R' /* New, Received */))
        set @vMessageName = 'TransferInv_FromLPNUnavailable';
      else
      if (@vFromLPNQuantity <= 0)
        set @vMessageName = 'NoInventoryToTransferFromLPN'
      else
      if ((@vFromLPNInnerPacks > 0) and (@vTransferInnerPacks = 0))
        set @vMessageName = 'TransferInv_TransferCasesOnly'
      else
      if (not exists(select *
                     from LPNDetails
                     where (SKUId = @vTransferSKUId) and
                           (LPNId = @vFromLPNId)))
         set @vMessageName = 'SKUDoesNotExistInLPN';
      else
      /* Reserved line can only be transferred to another LPN that is also reserved for the same order or a new LPN */
      if ((@vFromLPNOrderType not in ('RU', 'RP' /* ReplenishUnits, ReplenishCases */)) and
          (@vFromLPNOnhandStatus = 'R'/* Reserved */) and
          (@vToLPNStatus <> 'N' /* New */) and (@vFromLPNOrderId <> @vToLPNOrderId))
        set @vMessageName = 'TransferInv_DifferentOrder';
      else
      if ((@vFromLPNOrderType not in ('RU', 'RP' /* ReplenishUnits, ReplenishCases */)) and
          (@vFromLPNOnhandStatus = 'R'/* Reserved */) and
          (@vToLPNStatus <> 'N' /* New */) and (coalesce(@vToLPNOrderId, 0) = 0))
        set @vMessageName = 'TransferInv_CannotTransferReservedLine';
      else
      if (@vAllowNewInvBeforeReceiverClose = 'N') and (@vFromLPNReceiverStatus <> 'C' /* Closed */) and
         (@vFromLPNStatus in ('T', 'R' /* InTransit, Received */)) and (@vToLPNStatus <> 'N')
        set @vMessageName = 'TransferInv_ReceiverNotYetClosed';
      else
      if ((@vToLPNQuantity <> 0) and (coalesce(@vFromLPNOrderId, 0) <> coalesce(@vToLPNOrderId, 0)))
        set @vMessageName = 'TransferInv_NotSameOrder';
      else
      /* Check SKU operations if user is trying to transfer inventory from LPN
         to the LPN with statues other than New, In-Transit, Received */
      if (@vToLPNStatus not in ('N', 'T', 'R' /* New, In-Transit, Received */)) and
         (@vFromLPNStatus in ('N', 'T', 'R' /* New, In-Transit, Received */))
        set @vMessageName = dbo.fn_SKUs_IsOperationAllowed(@vTransferSKUId, 'TransferInventory');

      /* More validations - if there are any exceptions, catch block catches to raise the error */
      exec @vReturnCode = pr_LPNs_ValidateInventoryMovement @vFromLPNId, null /* PalletId */, @vToLocationId, 'Transfer', @BusinessUnit, @UserId;
    end
  else /* @Source = 'Location' */
    begin
      if (@vFromLocationId is null)
        set @vMessageName = 'FromLocationDoesNotExist';
      else
      if (@vFromLocationType <> 'K' /* Picklane */)
        set @vMessageName = 'CannotTransferFromNonPicklaneLoc';
      else
      if (@vFromLPNQuantity <= 0)
        set @vMessageName = 'NoInventoryToTransferFromLoc'
      else
      if ((@vFromLPNInnerPacks > 0) and (@vTransferInnerPacks = 0))
        set @vMessageName = 'TransferInv_TransferCasesOnly'
      else
      if (not exists(select *
                     from LPNs
                     where (SKUId        = @vTransferSKUId) and
                           (LocationId   = @vFromLocationId)))
        set @vMessageName = 'SKUDoesNotExistInLocation';
      else
      if (@vFromLPNDetailOnhandStatus = 'R'/* Reserved */)
        set @vMessageName = 'TransferInv_CannotTransferReservedLine';
    end

  /* Apply Rules to verify */
  if (@vMessageName is null)
    exec pr_RuleSets_Evaluate 'Inv_ValidateTransferInv', @vXmlRulesData, @vMessageName output;

  if (@vMessageName is not null)
    goto ErrorHandler;

  if (@vDestination = 'LPN')
    begin
      if (@vToLPNId is null)
        set @vMessageName = 'ToLPNDoesNotExist';
      else
      if (@vToLPNType = 'L'/* Logical */)
        set @vMessageName = 'TransferInv_ToLPNIsLogicalLPN';
      else
      if (@vFromLPNId = @vToLPNId)
        set @vMessageName  = 'TransferInv_SameLPN';
      else
      if (charindex(@vToLPNStatus, @vInvalidToLPNStatuses) > 0)
        set @vMessageName = 'TransferInv_LPNToStatusIsInvalid';
      else
      /* Cannot transfer From LPN into LPN having different orders, but if transferring to blank LPN then allow */
      if (@vSource = 'LPN') and
         (@vToLPNLineCount > 0) and
         (coalesce(@vFromLPNOrderId, 0) <> coalesce(@vToLPNOrderId, 0))
        set @vMessageName = 'TransferInv_DifferentOrders';
      else
      if (@vSource = 'LPN') and
         (@vFromLPNStatus = 'R' /* Received */) and (@vToLPNStatus <> 'N') and
         (coalesce(@vFromLPNReceiptId, 0) <> coalesce(@vToLPNReceiptId, 0))
        set @vMessageName = 'TransferInv_DifferentReceipts';
      else
      if (@vToLPNOnhandStatus = 'U' /* Unavailable */) and (@vToLPNStatus not in ( 'N','R' /* New, Received */))
        set @vMessageName = 'TransferInv_ToLPNUnavailable';
      else
      if (@vToLPNStatus <> 'N'/* New */) and
         ((@vToLPNInventoryClass1 <> @vFromLPNInventoryClass1) or
          (@vToLPNInventoryClass2 <> @vFromLPNInventoryClass2) or
          (@vToLPNInventoryClass3 <> @vFromLPNInventoryClass3))
        set @vMessageName = 'TransferInv_InventoryClassMismatch';
    end
  else /* @Destination = 'Location' */
    begin
      if (@vToLocationId is null)
        set @vMessageName = 'ToLocationDoesNotExist';
      else
      if (@vToLocationType <> 'K'/* PickLane */)
        set @vMessageName = 'SKUCanTransferIfLocTypeIsPickLane';
      else
      if (@vFromLocationId = @vToLocationId) and (@vSource = 'LOC')
        set @vMessageName = 'TransferInv_SameLocation';
      else
      if ((@vFromLPNOrderId is not null) and (@vFromLPNOrderType not in ('B' /* Bulk */, 'R', 'RU', 'RP' /* Replenishment */)))
        set @vMessageName = 'TransferInv_FromLPNAllocated';
      else
      if (@vToLPNId is not null) and
         ((@vToLPNInventoryClass1 <> @vFromLPNInventoryClass1) or
          (@vToLPNInventoryClass2 <> @vFromLPNInventoryClass2) or
          (@vToLPNInventoryClass3 <> @vFromLPNInventoryClass3))
        set @vMessageName = 'TransferInv_InventoryClassMismatch';
      else
      if (@vToLPNId is null) and
         (@vAllowTransferToUnassignedLoc = 'N' /* No */) and
         (@vToLocationSubType = 'S' /* Static */)
        set @vMessageName = 'TransferInv_LocationIsNotSetupForSKU';
      else
      if (@vToLPNId is null) and (@vAllowTransferToUnassignedLoc = 'Y' /* Yes */) and
         (dbo.fn_Permissions_IsAllowed(@UserId, 'RFTransferInventoryToUnassignedLoc') <> '1')
        set @vMessageName = 'TransferInv_NoPermissionToTransferToUnassignedLoc';
      else
      if (@vToLocationStatus = 'I'/* InActice */) and (@vAllowTransferToInactiveLoc = 'N' /* No */)
        set @vMessageName = 'TransferInv_LocationIsNotActive';
      else
      /* If the Location has another SKU and this SKU is not already assigned, do not allow */
      if (@vToLocationSubType <> 'D'/* Dynamic */) and
         (exists (select *
                  from vwLPNDetails
                  where (LocationId = @vToLocationId) and
                        (SKUId <> @vTransferSKUId))) and
         (not exists (select *
                      from vwLPNDetails
                      where (LocationId = @vToLocationId) and
                            (SKUId = @vTransferSKUId)))
        set @vMessageName = 'TransferInv_LocationIsSetupForDifferentSKU';
    end

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* 4. Validate Transfer Quantity (<0) */
  if ((@vTransferQuantity <= 0) and (@vTransferInnerPacks <= 0))
     set @vMessageName = 'InvalidQuantity';
  else
  if (((@vFromLocStorageType = 'U'/* Units */) and (@vTransferQuantity > @vFromLPNQuantity)) or
      ((@vFromLocStorageType = 'P'/* Cases */) and (@vTransferInnerPacks > @vFromLPNInnerPacks)))
     set @vMessageName = 'TransferInv_NoSufficientQty';
  else
  if ((@vTransferInnerPacks > 0) and (@vTransferQuantity % @vTransferInnerPacks > 0))
    set @vMessageName = 'LPNInnerPacksAndQtyMismatch';
  else
  if (@vAllowMoveBetweenWarehouses = 'N') and
     (coalesce(@vToLPNStatus, '') <> 'N' /* New */) and
     (coalesce(@vFromLPNWarehouse, '') <> coalesce(@vToLPNWarehouse, ''))
    set @vMessageName = 'TransferInv_LPNsWarehouseMismatch';
  else
  if (@vToLPNId is not null) and (coalesce(@vToLPNStatus, '') <> 'N' /* New */) and
     (coalesce(@vFromLPNOwner, '') <> coalesce(@vToLPNOwner, ''))
    set @vMessageName = 'TransferInv_LPNsOwnerMismatch';
  else
  /* Should not allow to move inventory across Warehouses in any one of cases
     - If From or/and To LPN is/are reserved
     - If From or/and To LPN is/are in Received status */
  if (coalesce(@vFromLPNWarehouse, '') <> coalesce(@vToLPNWarehouse, '')) and
     ((@vFromLPNOnhandStatus = 'R' /* Reserved */) or (@vToLPNOnhandStatus = 'R' /* Reserved */))
    select @vMessageName = 'TransferInv_CannotMoveReservedInvBetweenWH';
  else
  if (coalesce(@vFromLPNWarehouse, '') <> coalesce(@vToLPNWarehouse, '')) and
     ((@vFromLPNStatus = 'R' /* Received */) or (@vToLPNStatus = 'R' /* Received */))
    select @vMessageName = 'TransferInv_CannotMoveReceivedInvBetweenWH';
  else
  /* This is an invalid condition. Don't know what we were trying to address at the time and
     without comments we cannot revise it either. so commenting it */
  -- if (@vTransferQuantity > @vFromLPNAllocableQty)
  --   select @vMessageName = 'TransferInv_CannotTransferReservedQty', @vNote1 = @vFromLPNAllocableQty;
  -- else
  /* Should not allow to transfer from Available/ReservedLPN to an unavailable LPN
     unless it is a new LPN with zero quantity */
  if (@vFromLPNOnhandStatus in ('A', 'R')) and
     ((@vToLPNOnhandStatus in ('U')) and (@vToLPNStatus <> 'N') and (@vToLPNQuantity > 0))
    select @vMessageName = 'TransferInv_TransferToUnavailableLPN';
  else
  /* Do not allow to transfer or putaway of LPNs(Reserve Qty) to Picklanes, except inventory picked for Bulk Orders */
  if (@vTransferQuantity > @vFromLPNDetailAvailableQty) and
     (@vToLocationType = 'K'/* PickLane */) and
     (@vFromLPNOrderType <> 'B'/* Bulk Order */)
    select @vMessageName = 'TransferInv_CannotTransferReservedQty', @vNote1 = @vFromLPNDetailAvailableQty;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vNote1;

end try
begin catch
  exec @vReturnCode = pr_ReRaiseError;
end catch;

  return(coalesce(@vReturnCode, 0));
end /* pr_Inventory_ValidateTransferInventory */

Go
