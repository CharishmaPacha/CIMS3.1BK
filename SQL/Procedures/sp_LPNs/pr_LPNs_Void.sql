/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/14  PK      pr_LPNs_Void: Changes to send InvCh transactions when voiding In-transit LPN with Available OnhandStatus (HA-2988)
  2021/03/18  TK      pr_LPNs_Void: Should be able to void new temp cartons as well (HA-GoLive)
  2021/01/31  TK      pr_LPNDetails_UnallocateMultiple & pr_LPNs_Void: Minor fixes noticed during dev testing (HA-1947)
  2020/10/15  VS      pr_LPNs_Void: Made the changes to void the Shiplabels and Cancel the PickTasks (HA-1448)
  2020/07/27  RT      pr_LPNs_Void: Changes to clear OrderId and OrderDetailId on LPNDetails when the LPN is voided (HA-597)
                      pr_LPNs_Void: Clear order info on new ship cartons when voided (HA-722)
  2020/05/15  RT      pr_LPNs_Void: Calling pr_Exports_LPNReceiptConfirmation in the place of pr_Exports_LPNData (HA-111)
  2019/01/18  KSK     pr_LPNs_CreateInvLPNs, pr_LPNs_Void: Added Reference and Generating export while creating Inventory for LPNs (S2GCA-460&461)
  2018/05/31  SV      pr_LPNs_Void: Made a generic change to the signature. Changes to reflect Reference# over Exports which is sent from UI.
                      pr_LPNs_ReverseReceipt: Changes as per the change in signature of pr_LPNs_Void (HPI-1921)
  2018/01/17  OK      pr_LPNs_Void: Passed the UserId param to procedure pr_LPNs_SetPallet to avoid the runtime errors (S2G-97)
  2017/08/01  KL      pr_LPNs_Void: Allow Reverse Receipt exports for only putaway LPNs (SRI-812)
  2017/07/19  PK      pr_LPNs_Void: Excluding cart postions from voiding (HPI-1606)
                      pr_LPNs_Void: Pass in LPN Status to pr_LPNs_UpdateReceiptCounts (HPI-1570)
  2017/06/12  PK      pr_LPNs_Void: Clearing Load and shipment association with the voided LPNs (FB-941)
                      pr_LPNs_Void: Clear destination if LPN is voided before Putaway (HPI-1512)
                      pr_LPNs_Void: Use SetLocation to clear location to avoid repetitive coding (GNC-1512)
  2017/01/18  RV      pr_LPNs_Void: Generate exports for return receipts before clear the ReceiptDetailID on LPNDetails
  2017/01/09  RV      pr_LPNs_Void: Clear the receipt detail on LPN detail while doing reverse receipt to not consider if recount call (HPI-1249)
  2016/11/07  AY      pr_LPNs_Void: Do not allow void if LPN assigned to Replenish Order as this is causing issues (HPI-1002)
  2016/11/01  RV      pr_LPNs_Void: Receipts headers recount when LPN status in Received and InTransit (HPI-970)
  2015/11/03  DK      pr_LPNs_Void: Made changes to clear the Receiver Number (FB-490).
                      pr_LPNs_Void: Modified procedure to handle as flag changes in pr_LPNs_Unallocate (FB-441).
  2015/09/09  SV      pr_LPNs_Void: Bug fix: Update Receipt counts on Void received LPN (SRI-372)
  2015/03/24  DK      pr_LPNs_Void: Updated to export inventory change if its OnhandStatus is Reserved.
  2014/07/19  PKS     pr_LPNs_Void: ReasonCode added in logging AT record
  2014/06/04  AK      pr_LPNs_Void: Prevent Logical LPNs from being voided
  2013/12/16  TD      pr_LPNs_Void: Changes to validate reasoncode.
  2013/11/29  TD      pr_LPNs_Void: Changes to unallocate Inv and cancel Tasks.
  2013/10/09  AY/VM   pr_LPNs_Void: Send specific reason code for client
                      pr_LPNs_Void: Reduce counts on RO when received LPN is voided
  2012/06/30  SP      Placed the transaction controls in 'pr_LPNs_CreateInvLPNs' and 'pr_LPNs_Void'.
  2012/06/11  AY      pr_LPNs_Void: Updated ModifiedBy and ModifiedDate - used in AT.
  2012/05/30  AA      pr_LPNs_Void: Change xml schema to make similar as ModifyLPNs
  2012/05/07  PK      pr_LPNs_Void: Modified to update PalletCounts if LPN is Voided.
  2012/01/11  YA      Added: pr_LPNs_Void.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Void') is not null
  drop Procedure pr_LPNs_Void;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Void:
    update Status in LPNs to Void and OnHandStatus to UnAvailable.
    XML Structure:
    <ModifyLPNs>
      <Data>
        <Operation>VoidLPNs</Operation>
        <ReasonCode>280</ReasonCode>
        <Reference>189716518150</Reference>
        <BusinessUnit>HPI</BusinessUnit>
        <UserId>sandeep</UserId>
      </Data>
      <LPNs>
        <LPNContent>
          <LPNId>753</LPNId>
        </LPNContent>
        <LPNContent>
          <LPNId>754</LPNId>
        </LPNContent>
      </LPNs>
    </ModifyLPNs>
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Void
  (@xmlInput       TXML,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @ReasonCode     TReasonCode,
   @Reference      TReference = null,
   @Operation      TDescription    = 'VoidLPNs',
   @Message        TDescription  output,
   @xmlOutput      TXML = null   output)
as
  /* Declare local variables */
  declare @vMessageName      TMessageName,
          @vEntity           TEntity  = 'LPN',
          @vAction           TAction,
          @vReturnCode       TInteger,
          @vRecordId         TRecordId,

          @vLPN              TLPN,
          @vLPNId            TRecordId,
          @vLPNType          TTypeCode,
          @vLPNStatus        TStatus,
          @vLocation         TLocation,
          @vLocationId       TRecordId,
          @vDestLocation     TLocation,
          @vSKUId            TRecordId,
          @vQuantity         TQuantity,
          @vOnhandStatus     TStatus,
          @vPalletId         TRecordId,
          @vInnerPacks       TInnerPacks,
          @vOrderType        TTypeCode,
          @vPickTicket       TPickTicket,

          @vLPNDetailId      TRecordId,
          @vLPNLine          TDetailLine,
          @vReceiptId        TRecordId,
          @vReceiptNumber    TReceiptNumber,
          @vReceiptDetailId  TRecordId,
          @vLPNQuantity      TQuantity,
          @vQtyReserved      TQuantity,

          @vTransQty         TQuantity,
          @vTotalLPNCount    TCount,
          @vVoidedLPNCount   TCount,
          @vNumLPNs          TCount,
          @vValidStatuses    TStatus,
          @vMessage          TMessage,

          @vReference        TReference,
          @vAuditActivity    TActivityType,

          @xmlLPNs           xml;

  declare @ttTaskDetails     TEntityKeysTable;
  /* Declare temp table to store LPNs data for those LPNs fetched from the variable @XmlInput*/
  declare @ttLPNs            TEntityKeysTable;

  declare @ttUpdatedLocationAndpallets as table
          (LocationId       TRecordId,
           Location         TLocation,
           PalletId         TRecordId,
           Pallet           TPallet,
           RecordId         TRecordId identity(1,1))
begin
begin try
begin transaction
  SET NOCOUNT ON;

  select @xmlLPNs         = convert(xml, @xmlInput),
         @vVoidedLPNCount = 0,
         @vAuditActivity  = 'LPNVoided',
         @vAction         = 'Void',
         @vRecordId       = 0;

  /* As pr_LPNs_Void will be called from multiple areas, there are chances of passing the values individually rather than in
     the InputXML. Hence we need to verify the values which are sent from InputXML and assign respectively. FYI, in one of
     the case like sending InvCh transactions, we are passing the Reference as VOID statically, which we handled as below */

  select @Operation      = coalesce(nullif(Record.Col.value('Operation[1]',      'TOperation'),      ''),  @Operation),
         @ReasonCode     = coalesce(nullif(Record.Col.value('ReasonCode[1]',     'TReasonCode'),     ''),  @ReasonCode),
         @vReference     = coalesce(nullif(Record.Col.value('Reference[1]',      'TReference'),      ''),  'VOID'),
         @BusinessUnit   = coalesce(nullif(Record.Col.value('BusinessUnit[1]',   'TBusinessUnit'),   ''),  @BusinessUnit),
         @UserId         = coalesce(nullif(Record.Col.value('UserId[1]',         'TUserId'),         ''),  @UserId)
  from @xmlLPNs.nodes('/ModifyLPNs/Data') as Record(Col);

  insert into @ttLPNs (EntityId)
    select Record.Col.value('.', 'TRecordId')
    from @xmlLPNs.nodes('ModifyLPNs/LPNs/LPNContent/LPNId') as Record(Col);

  select @vTotalLPNCount = @@rowcount; --Stores the count of all LPNs.

  /* Update Status of the LPNs (LPNs from the above temp table) to 'V'(Void) and OnhandStatus to 'U'(UnAvailable)
     only on those LPNs which are in particular status. Get the list from Controls(Configurations)
     (for Loehmann's its 'RO' - 'R'(Received) or 'O'(Lost status) */

  set @vValidStatuses = dbo.fn_Controls_GetAsString(@Operation, 'ValidStatuses', 'FROT' /* F:NewTemp,R:Received,O:Lost,T:InTransit */, @BusinessUnit, @UserId);

  /* if the reasoncode is null then get reasoncode from lookups..I think this is not needed */
  if (coalesce(@ReasonCode, '') = '')
    set @vMessageName = 'LPNVoid_ReasonCodeRequired';

  /* if there is any error then navigate to Error Handler */
  if (@vMessageName is not null) exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Create hash table */
  create table #EntitiesToRecalc (RecalcRecId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'RecalcCounts', '#EntitiesToRecalc';

  /* Do not void LPNs except in these list of defined statuses. So, remove all other LPNs in temp table */
  delete @ttLPNs
  from @ttLPNs T
       left outer join LPNs L on (T.EntityId = L.LPNId)
  where (charindex(L.Status, @vValidStatuses) = 0) or
        (L.LPNType in ('L' /* Logical */, 'A' /* Cart Positions */));

  /* If existing OnhandStatus is available then -ve Inventory changes exports to be generated */
  while (exists(select * from @ttLPNs where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId = RecordId,
                   @vLPNId    = EntityId
      from @ttLPNs
      where (RecordId > @vRecordId)
      order by RecordId;

      select @vLPNId         = L.LPNId,
             @vLPN           = L.LPN,
             @vLPNType       = L.LPNType,
             @vLPNStatus     = L.Status,
             @vLocationId    = L.LocationId,
             @vLocation      = L.Location,
             @vSKUId         = L.SKUId,
             @vQuantity      = L.Quantity,
             @vInnerPacks    = L.InnerPacks,
             @vReceiptId     = L.ReceiptId,
             @vOnhandStatus  = L.OnHandStatus,
             @vPalletId      = L.PalletId,
             @vReceiptNumber = coalesce(L.ReceiptNumber, RH.ReceiptNumber),
             @vPickTicket    = L.PickTicket,
             @vOrderType     = L.OrderType,
             @vQtyReserved   = L.ReservedQty,
             @vDestLocation  = L.DestLocation
      from vwLPNs L
        left outer join ReceiptHeaders RH on (L.ReceiptId = RH.ReceiptId)
      where LPNId = @vLPNId;  /* This is a temp fix and will revert back once CIMS-628 is done */

      /* If the LPN is associated with a Replenishment, do not allow to void */
      if (@vOrderType in ('R', 'RP', 'RU'))
        continue;

      /* check here whether the LPN is allocated for any order. If it is, then unallocate the LPN */
      if (@vQtyReserved > 0)
        exec pr_LPNs_Unallocate @vLPNId, default, 'N' /* No - Unallocate Pallet */, @BusinessUnit, @UserId;

      /* Update LPNs status and OnHandStatus */
      update L
      set Status       = case when LPNType = 'A' then 'N' else 'V'  /* Void */ end,
          OnhandStatus = 'U'  /* Unavailable */,
          LocationId   = null,
          Location     = null,
          PalletId     = case when LPNType = 'A' then PalletId else null end,
          Pallet       = case when LPNType = 'A' then Pallet   else null end,
          Reference    = @vReference,
          OrderId      = null,
          PickTicketNo = null,
          SalesOrder   = null,
          ShipmentId   = 0,
          LoadId       = 0,
          LoadNumber   = null,
          PickBatchId  = null,
          PickBatchNo  = null,
          BoL          = null,
          ModifiedDate = current_timestamp,
          ModifiedBy   = coalesce(@UserId, System_User)
      output deleted.LocationId, deleted.Location, deleted.PalletId, deleted.Pallet
      into @ttUpdatedLocationAndpallets (LocationId, Location, PalletId, Pallet)
      from LPNs L
      where (L.LPNId = @vLPNId);

      /* Update LPNDetails OnhandStatus as Unavailable, OrderId and OrderDetailId as null
         as the fields not getting cleared and displaying voided details in the Packing List */
      update LPNDetails
      set OnhandStatus  = 'U'  /* Unavailable */,
          OrderId       = null,
          OrderDetailId = null
      where (LPNId = @vLPNId);

      select @vVoidedLPNCount = @vVoidedLPNCount + 1;

      /* Clear Destination on LPN */
      if (@vDestLocation is not null)
        exec pr_LPNs_SetDestination @vLPNId, 'ClearDestination' /* Operation */;

      /* Update Locations by Clearing Locations or by updating counts on the locations which has that particular LPN. */
      --if (@vLocationId is not null)
        --exec pr_LPNs_SetLocation @vLPNId, null /* Clear Location */

      /* Updating counts on the Pallet which has that particular LPN. */
      --if (@vPalletId is not null) and (@vLPNType <> 'A' /* Cart */)
        --exec pr_LPNs_SetPallet @vLPNId, null /* Clear pallet */, @UserId;

      /* Get All TaskDetails to cancel the TaskDetails */
      insert into @ttTaskDetails(EntityId, EntityKey)
        select distinct TD.TaskDetailId, 'TaskDetail'
        from Tasks T
          join  TaskDetails TD on (T.TaskId   = TD.TaskId)
        where (TD.TempLabelId = @vLPNId) and
              (TD.Status not in ('C', 'X'))

      /* Void the Shiplabels & Cancel the PickTasks */
      if exists(select * from @ttTaskDetails)
        begin
          exec pr_Tasks_Cancel @ttTaskDetails, null/* TaskId */, null /* Batch No */,
                               @BusinessUnit, @UserId, @vMessage output;
        end

      /* If LPN is in Received status, then undo all the receipt qtys on the Receipt Order */
      if (((@vLPNStatus in ('R'/* Received */, 'T' /* InTransit */) and (@vOnhandStatus = 'U'/* Unavailable */)) or
           ((@Operation = 'ReverseReceiving') and (@vLPNStatus = 'P'/* Putaway */))) and
           (@vReceiptNumber is not null))
        begin
          /* Update Receipt and details here */
          exec pr_LPNs_UpdateReceiptCounts @vLPNId, @vLPNStatus;

          /* Generate exports for Reverse receiving only Putaway LPNs.
             Need to send ReceiptDetailId and LPNDetailId without Nulls, before clearing the data on LPNDetail */
          if (@Operation = 'ReverseReceiving') and (@vLPNStatus = 'P' /* Putaway */)
            begin
              /* send -ve quantity to export while reverse receiving */
              select @vAuditActivity = 'ReverseRecvFromLoc',
                     @vAction        = 'Reverse-Receipt';

              exec @vReturnCode = pr_Exports_LPNData 'Recv' /* Receipt */,
                                                     @LPNId        = @vLPNId,
                                                     @TransQty     = @vQuantity,
                                                     @ReasonCode   = @ReasonCode,
                                                     @Reference    = @vReference,
                                                     @QuantitySign = -1,
                                                     @CreatedBy    = @UserId;
            end

          /* Update LPN, LPN Details and counts of ROH/ROD */
          exec pr_LPNs_UndoReceipt @vLPNId;
        end
      else
      /* export -ve inventory change if it's OnhandStatus is Available and Reserved */
      if (@vOnhandStatus in ('A' /* Available */, 'R' /* Reserved */))
        begin
          exec pr_Exports_LPNData 'InvCh' /* Inventory Changes */,
                                  @TransEntity = 'LPNDetails',
                                  @LPNId        = @vLPNId,
                                  @TransQty     = @vTransQty,
                                  @ReasonCode   = @ReasonCode /* Voided onhand Inventory */,
                                  @QuantitySign = -1,
                                  @CreatedBy    = @UserId;
        end
      else
        exec pr_Exports_LPNData 'Void'    /* Void */,
                                @LPNId     = @vLPNId,
                                @TransQty  = @vQuantity,
                                @CreatedBy = @UserId;

      /* Audit Trail - needs to be reflected against LPN, Pallet and Location */
      exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                @LPNId      = @vLPNId,
                                @PalletId   = @vPalletId,
                                @LocationId = @vLocationId,
                                @ReceiptId  = @vReceiptId,
                                @Quantity   = @vQuantity,
                                @ReasonCode = @ReasonCode,
                                @Note1      = @vReference;
    end

  /* Building success message response with counts */
  exec @Message = dbo.fn_Messages_BuildActionResponse @vEntity, @vAction, @vVoidedLPNCount, @vTotalLPNCount;

  /* Insert the Pallets, Locations into #EntitiesToRecalc */
  insert into #EntitiesToRecalc (EntityType, EntityId, RecalcOption, Status, BusinessUnit)
    select distinct 'Pallet', PalletId, 'CS' /* Counts & Status */, 'N', @BusinessUnit from @ttUpdatedLocationAndpallets where PalletId is not null
    union all
    select distinct 'Location', LocationId, 'CS' /* Count & Status */, 'N', @BusinessUnit from @ttUpdatedLocationAndpallets where LocationId is not null

  /* Process all recalcs to avoid at the end once so that we don't process the same Pallet/Location
     again and again */
  exec pr_Entities_RequestRecalcCounts null /* EntityType */, @RecalcOption = 'DeferAll';

  commit transaction;

end try
begin catch
  if (@@trancount > 0) rollback transaction

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Void */

Go
