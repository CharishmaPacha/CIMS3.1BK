/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/11/02  AY      pr_RFC_Picking_StartBuildCart,pr_RFC_Picking_AddCartonToCart: Disregard voided LPNs, show proper messages on voided
  2016/09/12  TD      pr_RFC_Picking_AddCartonToCart:Changes to get LPN number from scanned tracking number if the length is greater than
  2015/08/30  NY      pr_RFC_Picking_AddCartonToCart: Log cart position as well on AT (HPI-431)
  2015/11/27  TK      pr_RFC_Picking_AddCartonToCart: Update Pallet Id on the Temp Label (ACME-391)
  2015/11/12  TK      pr_RFC_Picking_AddCartonToCart: Clear the alternate LPN on the Cart position, if the scanned LPN is already
              TK      pr_RFC_Picking_AddCartonToCart: When user has built all cartons on the cart, give a message that all cartons
  2015/08/13  TK      pr_RFC_Picking_AddCartonToCart: Changes made to make scan Packing List as optional based upon Batch type (ACME-284)
  2015/08/12  TK      pr_RFC_Picking_AddCartonToCart & pr_RFC_Picking_StartBuildCart:
  2015/06/02  DK/TK   pr_RFC_Picking_StartBuildCart & pr_RFC_Picking_AddCartonToCart: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_AddCartonToCart') is not null
  drop Procedure pr_RFC_Picking_AddCartonToCart;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_AddCartonToCart: This procedure validates the Scanned cart and Batch.

    @xmlInput XML Structure:
    <BuildCart>
      <Cart></Cart>
      <Batch></Batch>
      <ScannedCartPosition></ScannedCartPosition>
      <ScannedLPN></ScannedLPN>
      <PackingList></PackingList>
      <DeviceId></DeviceId>
      <BusinessUnit></BusinessUnit>
      <UserId></UserId>
    </BuildCart>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_AddCartonToCart
  (@xmlInput       xml,
   @xmlResult      xml   output)
As
  declare @vTaskId                     TRecordId,

          @vPickCart                   TPallet,
          @vCartPosition               TLPN,
          @vCartPositionId             TRecordId,
          @vCartPosCartId              TRecordId,
          @vCartPosStatus              TStatus,
          @vLPNInCartPosition          TLPN,
          @vPrevCartPosition           TLPN,
          @vPalletId                   TRecordId,
          @vPallet                     TPallet,
          @vLPNId                      TRecordId,
          @LPN                         TLPN,
          @vLPN                        TLPN,
          @vLPNStatus                  TStatus,
          @vLPNPickTicket              TPickTicket,
          @vPackingList                TLPN,
          @vAlternateLPN               TLPN,
          @vLPNTaskId                  TRecordId,

          @vNumLPNsOnTask              TCount,
          @vNumLPNsOnCart              TCount,

          @vValidTaskId                TRecordId,
          @vTaskPalletId               TRecordId,
          @vNote1                      TDescription,

          @vControlCategory            TCategory,
          @vScanPackingList            TFlag,

          @vDeviceId                   TDeviceId,
          @vUserId                     TUserId,
          @vActivityLogId              TRecordId,
          @vBusinessUnit               TBusinessUnit;

  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription;

  declare @ttLPNsOnTask                TEntityKeysTable;

begin /* pr_RFC_Picking_AddCartonToCart */
begin try
  SET NOCOUNT ON;

  /* Get the XML User inputs in to the local variables */
  select @vTaskId       = Record.Col.value('Batch[1]'              , 'TRecordId'),
         @vPickCart     = Record.Col.value('Cart[1]'               , 'TPallet'),
         @vCartPosition = Record.Col.value('ScannedCartPosition[1]', 'TLPN'),
         @LPN           = Record.Col.value('ScannedLPN[1]'         , 'TLPN'),
         @vPackingList  = Record.Col.value('PackingList[1]'        , 'TLPN'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]'       , 'TBusinessUnit'),
         @vUserId       = Record.Col.value('UserId[1]'             , 'TUserId'),
         @vDeviceId     = Record.Col.value('DeviceId[1]'           , 'TDeviceId')
  from @xmlInput.nodes('BuildCart') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      @vTaskId, @LPN, 'TaskId-LPN', @Value1 = @vPickCart,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* get the scanned LPN details */
  select @vLPNId            = LPNId,
         @vLPN              = LPN,
         @vAlternateLPN     = AlternateLPN,
         @vLPNStatus        = Status,
         @vLPNPickTicket    = PickTicket,
         @vPrevCartPosition = nullif(AlternateLPN, '')
  from vwLPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@LPN, @vBusinessUnit, 'LTU' /* Options */));

  /* check the status of the Scanned LPN */
  select @vCartPositionId    = LPNId,
         @vCartPosStatus     = Status,
         @vCartPosCartId     = PalletId,
         @vLPNInCartPosition = nullif(AlternateLPN, '')
  from LPNs
  where (LPN          = @vCartPosition) and
        (BusinessUnit = @vBusinessUnit);

  select @vPalletId = PalletId,
         @vPallet   = Pallet
  from vwPallets
  where (Pallet       = @vPickCart) and
        (BusinessUnit = @vBusinessUnit);

  /* Get Task info */
  select @vValidTaskId     = T.TaskId,
         @vTaskPalletId    = T.PalletId,
         @vControlCategory = 'PickBatch_' + PB.BatchType
  from Tasks T
    join PickBatches PB on (T.BatchNo = PB.BatchNo)
  where (T.TaskId = @vTaskId);

  /* Check if the LPN is associated with the given task */
  select @vLPNTaskId = RecordId
  from LPNTasks
  where (TaskId = @vTaskId) and
        (LPNId  = @vLPNId);

  /* for some Batch types scanning Packing List is mandatory and some not */
  select @vScanPackingList = dbo.fn_Controls_GetAsBoolean(@vControlCategory, 'ScanPackingList', 'Y' /* Yes */, @vBusinessUnit, null /* UserId */);

  /* Validations */
  if (@vLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (@vLPNStatus = 'V' /* Voided */)
    set @vMessageName = 'BuildCart_LPNVoided';
  else
  if (@vLPNStatus not in ('N' /* New */, 'F' /* New Temp */))
    set @vMessageName = 'InvalidLPNStatus';
  else
  if (@vCartPositionId is null)
    select @vMessageName = 'InvalidCartPosition';
  else
  if (@vLPNInCartPosition is not null)
    select @vMessageName = 'BuildCart_CartPositionInUse', @vNote1 = @vLPNInCartPosition;
  else
  if (@vCartPosStatus <> 'N' /* New */)
    set @vMessageName = 'InvalidCartPosStatus';
  else
  if (@vValidTaskId is null)
    select @vMessageName = 'BuildCart_InvalidTaskId';
  else
  if (@vPalletId is null)
    select @vMessageName = 'BuildCart_InvalidCart';
  else
  if (@vCartPosCartId <> @vPalletId)
    select @vMessageName = 'BuildCart_ScannedPositionNotOnCart';
  else
  if (@vTaskPalletId is not null) and (@vTaskPalletId <> @vPalletId)
    begin
      select @vMessageName = 'TaskAssociatedWithAnotherCart';
      select @vNote1       = Pallet from Pallets where PalletId = @vTaskPalletId;
    end
  else
  if (@vLPNTaskId is null)
    select @vMessageName = 'ScannedLPNNotAssociatedWithThisBatch';
  else
  if (@vScanPackingList = 'Y' /* Yes */) and
     (@vPackingList is null)
    set @vMessageName = 'BuildCart_PackingListIsRequired';
  else
  if ((@vScanPackingList = 'Y' /* Yes */) and
      ((@vPackingList <> @vLPN) and
       (@vPackingList <> @vLPNPickTicket)))
    set @vMessageName = 'BuildCart_WrongPackingList';
  else
  if (@vCartPosition = @vAlternateLPN)
    set @vMessageName = 'BuildCart_LPNAlreadyAtPosition';
  else
  if exists (select * from LPNTasks LT join LPNs L on LT.LPNId = L.LPNId
             where LT.TaskId = @vTaskId and
                   L.AlternateLPN = @vCartPosition)
    set @vMessageName = 'ScannedPositionAssociatedWithOtherLPN';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Update scanned cart position on the LPN */
  update LPNs
  set AlternateLPN = @vCartPosition,
      PalletId     = @vPalletId,
      Pallet       = @vPallet
  where (LPNId = @vLPNId);

  /* Update the cart position with the LPN that is in the position */
  update LPNs
  set AlternateLPN = @vLPN
  where (LPNId = @vCartPositionId);

  /* If scanned LPN was already assigned to some position and user wants to
     move that LPN to another position then make the current cart position available for re-use */
  if (@vPrevCartPosition is not null)
    update LPNs
    set AlternateLPN = null
    where (LPN = @vPrevCartPosition) and (BusinessUnit = @vBusinessUnit);

  /* If Task is not associated with Pallet, then update it */
  if (@vTaskPalletId is null)
    update Tasks
    set PalletId = @vPalletId,
        Pallet   = @vPallet
    where (TaskId = @vTaskId);

  /* Update counts on the Pallet */
  exec pr_Pallets_UpdateCount @vPalletId, @UpdateOption = '*';

  insert into @ttLPNsOnTask (EntityId, EntityKey)
    select distinct L.LPNId, L.AlternateLPN
    from LPNTasks LT join LPNs L on LT.LPNId = L.LPNId
    where (LT.TaskId = @vTaskId) and (L.Status not in ('V' /* Voided */, 'C' /* Consumed */));

  select @vNumLPNsOnTask = count(EntityId),
         @vNumLPNsonCart = sum(case when nullif(EntityKey, '') is not null then 1 else 0 end)
  from @ttLPNsOnTask;

  /* If all the LPNs on the Task are built then  */
  if (@vNumLPNsOnTask = @vNumLPNsonCart)
    select @vMessage = dbo.fn_Messages_GetDescription('BuildCart_AllLPNsBuilt');
  else
    select @vMessage = dbo.fn_Messages_GetDescription('BuildCart_LPNAddedSuccessfully');

  exec pr_AuditTrail_Insert 'LPNAddedToCart', @vUserId, null /* ActivityTimestamp */,
                            @LPNId        = @vLPNId,
                            @ToLPNId      = @vCartPositionId,
                            @ToPalletId   = @vPalletId;

  set @xmlResult = (select @vPickCart        as Cart,
                           @vTaskId          as Batch,
                           @vNumLPNsonCart   as NumLPNsOnCart,
                           @vNumLPNsOnTask   as NumLPNsonTask,
                           @vMessage         as Message
                           for XML raw('BuildCart'), elements);

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vNote1;

  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_AddCartonToCart */

Go
