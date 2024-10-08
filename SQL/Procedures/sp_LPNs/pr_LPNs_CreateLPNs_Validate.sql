/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/03  RKC     pr_LPNs_CreateLPNs_Validate, pr_LPNs_CreateLPNs: Made changes to validate if the user selected the Multiple UOM SKU's and tried to generate LPNs (BK-218)
  2020/07/01  TK      pr_LPNs_CreateLPNs: Changes to consume inventory while creating inventory
                      pr_LPNs_CreateLPNs_Validate: Changes to pupulate inventory to be consumed
                      pr_LPNs_CreateLPNs_TransferInventory: Initial Revision
                      pr_LPNs_Ship: Changes to ship LPN without any order info and clear load info
                        when LPNs is marked as in-transit (HA-830)
  2020/06/26  TK      pr_LPNs_CreateLPNs & pr_LPNs_CreateLPNs_Validate: Fixes to invoke these procs from create inventory action (HA-830)
  2020/06/26  NB      pr_LPNs_CreateLPNs_Validate: changes to validate Input Warehouse, Warehouse of Receipt and Receiver(CIMSV3-987)
  2019/12/27  RT      pr_LPNs_CreateLPNs_ActivateKits: Updates on Generated Kits and Picked Kits to process
                      pr_LPNs_CreateLPNs: Create Kits and update the post results on generated Kits
                      pr_LPNs_CreateLPNs_Validate: Evaluating Rules to validate fixture LPNs
                      pr_LPNs_CreateLPNs_MaxKitsToCreate: Validate if SKU does exists in the location, Changes to validate and create Kits to process
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_CreateLPNs_Validate') is not null
  drop Procedure pr_LPNs_CreateLPNs_Validate;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_CreateLPNs_Validate: Validate the inputs for CreateLPNs procedure
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_CreateLPNs_Validate
  (@xmlInput XML)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,
          /* Input params */
          @LPNType                TTypeCode,
          @LPNStatus              TStatus,
          @NumLPNsToCreate        TCount,
          @NumLPNsPerPallet       TCount,
          @Lot                    TLot,
          @Expirydate             TDate,
          @CoO                    TCoO,
          @Ownership              TOwnership,
          @Warehouse              TWarehouse,
          @ReasonCode             TReasonCode,
          @GeneratePallet         TFlags,
          @CreatedDate            TDateTime,
          @ReceiverId             TRecordId,
          @vReceiverWarehouse     TWarehouse,
          @ReceiptId              TRecordId,
          @vReceiptWarehouse      TWarehouse,
          @OrderId                TRecordId,
          @InventoryClass1        TInventoryClass,
          @InventoryClass2        TInventoryClass,
          @InventoryClass3        TInventoryClass,
          @Action                 TAction,
          @Operation              TOperation,
          @BusinessUnit           TBusinessUnit,
          @UserId                 TUserId,

          @Pallet                 TPallet,
          @vPalletId              TRecordId,
          @vPalletStatus          TStatus,

          @vxmlRulesData          TXML,
          @vNote1                 TDescription;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get the XML User inputs in to the local variables */
  select @LPNType          = Record.Col.value('LPNType[1]'            , 'TTypeCode'),
         @NumLPNsToCreate  = Record.Col.value('NumLPNsToCreate[1]'    , 'TInteger'),
         @NumLPNsPerPallet = Record.Col.value('NumLPNsPerPallet[1]'   , 'TInteger'),
         @Lot              = Record.Col.value('Lot[1]'                , 'TLot'),
         @CoO              = Record.Col.value('CoO[1]'                , 'TCoO'),
         @ExpiryDate       = Record.Col.value('ExpiryDate[1]'         , 'TDate'),
         @Ownership        = Record.Col.value('Owner[1]'              , 'TOwnership'),
         @Warehouse        = Record.Col.value('Warehouse[1]'          , 'TWarehouse '),
         @ReasonCode       = Record.Col.value('ReasonCode[1]'         , 'TReasonCode'),
         @GeneratePallet   = Record.Col.value('GeneratePallet[1]'     , 'TFlag'),
         @Pallet           = Record.Col.value('Pallet[1]'             , 'TPallet'),
         @CreatedDate      = Record.Col.value('CreatedDate[1]'        , 'TDate'),
         @Operation        = Record.Col.value('Operation[1]'          , 'TOperation'),
         @ReceiverId       = nullif(Record.Col.value('ReceiverId[1]'  , 'TRecordId'), 0),
         @ReceiptId        = nullif(Record.Col.value('ReceiptId[1]'   , 'TRecordId'), 0),
         @OrderId          = nullif(Record.Col.value('OrderId[1]'     , 'TRecordId'), 0),
         @Operation        = Record.Col.value('Operation[1]'          , 'TOperation'),
         @InventoryClass1  = Record.Col.value('InventoryClass1[1]'    , 'TInventoryClass'),
         @InventoryClass2  = Record.Col.value('InventoryClass2[1]'    , 'TInventoryClass'),
         @InventoryClass3  = Record.Col.value('InventoryClass3[1]'    , 'TInventoryClass')
  from @xmlInput.nodes('Root/Data') as Record(Col);

  select @Action       = Record.Col.value('Action[1]'                           , 'TAction'),
         @BusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]'       , 'TBusinessUnit'),
         @UserId       = Record.Col.value('(SessionInfo/UserId)[1]'             , 'TUserId')
  from @xmlInput.nodes('Root') as Record(Col);

  if (@GeneratePallet = 'N' /* generate - No, User may scan */) and
     (@Pallet is not null) /* Validate, if Pallet is given */
    select @vPalletId     = PalletId,
           @vPalletStatus = Status
    from Pallets
    where (Pallet       = @Pallet) and
          (BusinessUnit = @Businessunit);

  if (@ReceiptId is not null)
    select @vReceiptWarehouse = Warehouse
    from ReceiptHeaders
    where (ReceiptId = @ReceiptId);

  if (@ReceiverId is not null)
    select @vReceiverWarehouse = Warehouse
    from Receivers
    where (ReceiverId = @ReceiverId);

  /* XMLRulesData: Get the InnerXML and replace with root node to evaulate Rules */
  select @vxmlRulesData = replace(cast(@xmlInput.query('Root/Data') as varchar(max)), 'Data', 'RootNode');
  select @vxmlRulesData = dbo.fn_XMLAddNameValue(@vxmlRulesData, 'RootNode', 'Operation', coalesce(@Operation, @Action));
  select @vxmlRulesData = dbo.fn_XMLAddNameValue(@vxmlRulesData, 'RootNode', 'BusinessUnit', @BusinessUnit);
  select @vxmlRulesData = dbo.fn_XMLAddNameValue(@vxmlRulesData, 'RootNode', 'UserId', @UserId);

  /* Validations */
  if (@LPNType = 'L')
    select @vMessageName = 'CreateLPNs_CannotCreateLogicalLPNs';
  else
  if (@Ownership is null)
    select @vMessageName = 'CreateLPNs_OwnershipRequired';
  else
  if (@Warehouse is null)
    select @vMessageName = 'CreateLPNs_WarehouseRequired';
  else
  if (@BusinessUnit is null)
    select @vMessageName = 'CreateLPNs_BusinessUnitRequired';
  else
  if (coalesce(@NumLPNsToCreate, 0) < 1) -- need to be a 1 or more
    select @vMessageName = 'CreateLPNs_InvalidNumLPNs';
  else
  if (@NumLPNsPerPallet < 0) -- cannot be negative
    select @vMessageName = 'CreateLPNs_InvalidNumLPNsPerPallet';
  else
  if ((select count (distinct coalesce(UnitsPerPackage, 0)) from #CreateLPNDetails) <> 1)
    select @vMessageName = 'CreateLPNs_UnitsPerInnerPackNotSame';
  else
  if (@GeneratePallet = 'N') and (@Pallet is not null) and (@vPalletId is null)
    set @vMessageName = 'CreateLPNs_InvalidPallet';
  else
  if (@GeneratePallet = 'N') and (@vPalletStatus not in ('E' /* Empty */, 'B'/* Built */, 'R'/* Received */, 'P' /* Putaway */))
    set @vMessageName = 'CreateLPNs_InvalidPalletStatus';
  else
  if (exists (select * from #CreateLPNDetails where coalesce(ReceiptId, 0) <> coalesce(@ReceiptId, 0)))
    select @vMessageName = 'CreateLPNs_ReceiptIdMismatch';
  else
  if (@ReceiptId is not null) and
     (exists (select * from #CreateLPNDetails where coalesce(ReceiptDetailId, 0) = 0))
    select @vMessageName = 'CreateLPNs_ReceiptDetailIdMissing';
  else
  if (exists (select SKUId from #CreateLPNDetails group by SKUId having count(*) > 1))
    select @vMessageName = 'CreateLPNs_SKUDuplicated';
  else
  if (@ReceiptId is not null) and (@ReceiverId is not null) and
     (@vReceiptWarehouse <> @vReceiverWarehouse)
    select @vMessageName = 'ReceiverReceiptWHMismatch';
  else
  if (@Warehouse is not null) and (@ReceiverId is not null) and
     (@Warehouse <> @vReceiverWarehouse)
    select @vMessageName = 'ReceiverWHMismatch';
  else
  if ((select count(distinct UoM) from #CreateLPNDetails) > 1)
    select @vMessageName = 'CreateLPNs_HasMixedUoMSKUs';
  else
    begin
      /* Evaluate Rules to get all the Inventory Details to create LPNs */
      exec pr_RuleSets_ExecuteRules 'CreateLPNs_GetSourceInventory', @vxmlRulesData;

      exec pr_RuleSets_Evaluate 'CreateLPNs_Validations', @vxmlRulesData, @vMessageName output;
    end

  /* Validate the InnerPacks, UnitsPerInnerPack & UnitsPerLPN */
  select S.SKUId, S.SKU,
         case when (LD.UOM = 'CS') and (LD.InnerPacks = 0)      then 'CreateLPNs_InnerPacksPerLPNRequired'
              when (LD.UOM = 'CS') and (LD.UnitsPerPackage = 0) then 'CreateLPNs_UnitsPerInnerPackRequired'
              when (LD.Quantity = 0)                            then 'CreateLPNs_UnitsPerLPNRequired'
         end ErrorMessage
  into #InvalidLPNDetails
  from #CreateLPNDetails LD join SKUs S on LD.SKUId = S.SKUId;

  /* Add errors to #ResultMessages */
  insert into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
    select 'E', ILD.SKUId, ILD.SKU, ILD.ErrorMessage
    from #InvalidLPNDetails ILD
    where (ILD.ErrorMessage is not null);

  /* If there are any SKU inputs that are invalid, get a MessageName to raise an exception */
  if (@@rowcount > 0)
    select top 1 @vMessageName = MessageName from #ResultMessages where (MessageType = 'E');

  /* Validate over receiving */
  if (@vMessageName is null)
    begin
      select dbo.fn_Receipts_ValidateOverReceiving(ReceiptDetailId, @NumLPNsToCreate * Quantity, @UserId) as MessageName
      into #OverReceipts
      from #CreateLPNDetails
      where (ReceiptId is not null);

      select top 1 @vMessageName = MessageName from #OverReceipts where (MessageName is not null);
    end

ErrorHandler:
  if (@vMessageName is not null)
    begin
      /* Get additional info to build the error */
      if object_id('tempdb..#ErrorInfo') is not null
        select top 1 @vNote1 = Note1 from #ErrorInfo;

      if (object_id('tempdb..#ResultMessages') is not null)
        insert into #ResultMessages (MessageType, MessageName, Value1)
          select 'E' /* Error */, @vMessageName, @vNote1;

      exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vNote1;
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_CreateLPNs_Validate */

Go
