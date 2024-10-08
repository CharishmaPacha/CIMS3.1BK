/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

                      pr_LPNs_Modify: Update Volume when carton type is updated (BK-192)
  2020/07/22  AY      pr_LPNs_Modify: Do not allow change WH on Reserved LPNs (HA-1194)
  2020/05/09  TK      pr_LPNs_Modify: Invoke new Proc for ChangeSKU
  2020/05/07  TK      pr_LPNs_Modify: Invoke new Proc for ModifyLPNs
              SV      pr_LPNs_Modify: Changes to update Reference field over LPNs (HA-421)
  2019/05/02  RIA     pr_LPNs_Modify: Changes to update CartonType and Weight (S2GCA-669)
  2019/02/08  AY/VS   Added new procedure pr_LPNs_QCHoldOrRelease and modified in pr_LPNs_Modify for HoldQC and ReleaseQC added Reference field in exports(CID-68)
  2018/12/18  AY      pr_LPNs_Modify: Allow SKU Modify on picklanes (S2GCA-Support)
  2018/04/19  AJ      pr_LPNs_Modify: Added Action: -> RegenerateTrackingNumber (S2G-549)
  2017/09/11  VM      pr_LPNs_Modify - ModifyOwnership: Exclude non Putaway LPNs to process (FB-1015)
  2017/02/08  NB      pr_LPNs_Modify: Migrated fix from HPI Test SQL to handle unique Key violation on @ttPalletsToRecount in Change SKU (HPI-962)
  2016/11/11  RA      pr_LPNs_Modify: Removed the condition for checking the vReceiverNumber  (HPI-977)
  2016/08/24  TD      pr_LPNs_Modify:Bugfix-Fetching status from LPN while updating to generate exports.
  2016/06/23  NY      pr_LPNs_Modify: Insert distinct pallets to avoid unique key exception (NBD-618)
  2016/02/04  KL      pr_LPNs_Modify: Modify Ownership and Warehouse on newly created LPNs (NBD-125)
                      pr_LPNs_Modify: Modified procedure to handle as flag changes in pr_LPNs_Unallocate.
  2014/08/06  TK      pr_LPNs_Modify: Updated not to allow user to modify Warehouse of a Logical LPN.
  2014/07/29  TK      pr_LPNs_Modify: Updated not to allow user to update ExpiryDate
  2014/07/24  TK      pr_LPNs_Modify: Updated to Log Audit Trail.
  2014/07/23  AY      pr_LPNs_Modify: Do not send WHXfer if LPNQty = 0
  2014/07/21  NY      pr_LPNs_Modify: Log AT for Wh Change for Received Inventory as well.
  2014/03/05  TD      pr_LPNs_Modify:Changes to modify LPNs.
  2014/01/27  TD      pr_LPNs_Modify: Changes about reverse receiving.
                      pr_LPNs_Modify: Change Exports on Change Warehouse
  2013/08/05  AY      pr_LPNs_Modify: New feature - change Warehouse
  2103/05/27  TD      pr_LPNs_Modify:Added New Action 'UpdateInvExpDate'
                      pr_LPNs_Modify: Implemented functionality for UnallocateLPN
  2012/10/01  PKS     pr_LPNs_Modify: Pallet update count procedure was called to update LPNs' pallets.
  2012/09/29  PKS     pr_LPNs_Modify: Updating SKU on Pallet by calling pr_Pallets_UpdateCount.
  2012/07/13  PKS/VM  pr_LPNs_Modify: XML Structure change, ChangeSKU: Allow based upon Statuses in Control var,
  2012/07/12  PKS     pr_LPNs_Modify: XML structure was changed.
  2012/03/31  NY      pr_LPNs_Modify: ChangeSKU was included.
  2012/03/14  PKS     pr_LPNs_Modify: ModifyOwnership was included.
  2011/11/21  SHR     Added pr_LPNs_Modify.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Modify') is not null
  drop Procedure pr_LPNs_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Modify:
    update LPNType in LPNs as Flat or Hanging (only for Flat and Hanging LPNType).
    XML Structure:
<ModifyLPNs>
  <Action>Action1</Action>
  <Data>
    <LPNOwner>LPNOwner1</LPNOwner>
    <LPNType>LPNType1</LPNType>
    <SKU>SKU1</SKU>
    <Warehouse></Warehouse>
  </Data>
  <LPNs>
    <LPNContent>
      <LPN>LPN1</LPN>
      <LPNId>LPNId1</LPNId>
    </LPNContent>
    <LPNContent>
      <LPN>LPN2</LPN>
      <LPNId>LPNId2</LPNId>
    </LPNContent>
    <LPNContent>
      <LPN>LPN3</LPN>
      <LPNId>LPNId3</LPNId>
    </LPNContent>
  </LPNs>
</ModifyLPNs>
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Modify
  (@UserId       TUserId,
   @LPNContents  varchar(max),
   @BusinessUnit TBusinessUnit,
   @Message      TMessage output)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @vEntity           TEntity  = 'LPN',

          @vAction           varchar(100),
          @vData             varchar(100),
          @vLPNs             TNVarChar,
          @xmlData           xml,
          @vRecordId         TRecordId,
          /* Counts */
          @vLPNsCount        TCount,
          @vLPNsUpdated      TCount,
          @vCount            TCount,
          @vLPNDetails       TCount,
          @vLPNsUnallocated  TCount,
          /* LPN Type change */
          @vLPNType          TTypeCode,
          @vLPNTypeDesc      TDescription,
          /* Carton Type change */
          @vCartonType       TCartonType,
          @vLPNWeight        TWeight,
          @vCartonVolume     TVolume,
          @vEmptyCartonWeight TWeight,
          /* Owner change */
          @vNewOwner         TOwnership,
          @vOldOwner         TOwnership,
          @vQuantity         TQuantity,
          @vLPN              TLPN,
          @vLPNId            TRecordId,
          @vUpdatedLPNId     TRecordId,
          @vValidStatuses    TStatus,
          /* SKU Change */
          @vNewSKUId         TRecordId,
          @vNewSKU           TSKU,
          @vOldSKUId         TRecordId,
          @vOldSKU           TSKU,
          @vDirectedQty      TQuantity,
          /* Warehouse Change */
          @vOldWarehouse     TWarehouse,
          @vNewWarehouse     TWarehouse,
          /* LPN Info */
          @vLPNStatus        TStatus,
          @vOnhandStatus     TStatus,
          @vOrderId          TRecordId,

          /* Pallet Info */
          @vPalletId         TRecordId,

          /* Reverse Receiving */
          @vReasonCode       TReasonCode,
          @vReference        TReference,
          @vReceiverNumber   TReceiptNumber,
          @vReservedQty      TQuantity,
          @vLPNsToVoid       TXML,
          @vReceiptId        TRecordId,
          @vLocationId       TRecordId,

          /* Audit */
          @vAuditActivity    TActivityType,
          @vAuditRecordId    TRecordId,
          @vInvExpDate       TDate,
          @vExpDate          TVarchar;

  declare @ttLPNsToUpdate     TEntityKeysTable,
          @ttLPNsUpdated      TEntityKeysTable,
          @ttPalletsToRecount TRecountKeysTable;
begin
begin try
  begin transaction
  SET NOCOUNT ON;

  select @vLPNsUpdated   = 0,
         @vAuditActivity = 'LPNModified',
         @vAuditRecordId = null,
         @vRecordId      = 0;

  /* Validate Business Unit */
  select @MessageName = dbo.fn_IsValidBusinessUnit(@BusinessUnit, @UserId);

  set @xmlData = convert(xml, @LPNContents);

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    set @MessageName = 'InvalidData'

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get the Action from the xml */
  select @vAction = Record.Col.value('Action[1]', 'varchar(100)')
  from @xmlData.nodes('/ModifyLPNs') as Record(Col);

  /* Load all the LPNs into the temp table which are to be updated in LPNs table */
  insert into @ttLPNsToUpdate (EntityId, EntityKey)
    select Record.Col.value('LPNId[1]', 'TRecordId') LPNId,
           Record.Col.value('LPN[1]', 'TLPN')      LPN
    from @xmlData.nodes('/ModifyLPNs/LPNs/LPNContent') as Record(Col);

  /* Get number of rows inserted */
  select @vLPNsCount = @@rowcount,
         @vCount     = @@rowcount;

  /* Create required hash tables */
  select * into #LPNsToUpdate from @ttLPNsToUpdate;

  if (@vAction = 'ModifyLPNType')
    begin
      select @vAuditActivity = 'LPNTypeModified';

      select @vLPNType = Record.Col.value('LPNType[1]', 'TTypeCode')
      from @xmlData.nodes('/ModifyLPNs/Data') as Record(Col);

      /* Check if the LPNType is passed or not */
      if (@vLPNType is null)
        set @MessageName = 'LPNTypeIsRequired';
      else
      /* Check if the LPNType is Active or not */
      if (not exists(select *
                     from vwEntityTypes
                     where (Entity       = 'LPN') and
                           (TypeCode     = @vLPNType) and
                           (BusinessUnit = @BusinessUnit)))
        set @MessageName = 'LPNTypeIsInvalid';

      if (@MessageName is not null)
         goto ErrorHandler;

      /* Update only if there is a change in LPNType.
         We only change the LPNs with LPN Type as Flat or Hanging. */
      update L
      set LPNType      = @vLPNType,
          ModifiedDate = current_timestamp,
          ModifiedBy   = @UserId
      output Deleted.lpnId, Deleted.LPN into @ttLPNsUpdated
      from LPNs L join @ttLPNsToUpdate LP on (LP.EntityId = L.LPNId)
      where ((L.LPNType in ('F' /* Flat */, 'H' /* Hanging */)) and
             (L.LPNType <> @vLPNType) and
             (BusinessUnit = @BusinessUnit));

      set @vLPNsUpdated = @@rowcount;

      /* Audit Trail */
      exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                @BusinessUnit  = @BusinessUnit,
                                @Note1         = @vLPNTypeDesc,
                                @AuditRecordId = @vAuditRecordId output;
    end
  else
  if (@vAction = 'ModifyCartonDetails')
    begin
      select @vAuditActivity = 'CartonTypeModified';

      select @vCartonType = Record.Col.value('CartonType[1]', 'TCartonType'),
             @vLPNWeight  = Record.Col.value('Weight[1]', 'TWeight')
      from @xmlData.nodes('/ModifyLPNs/Data') as Record(Col);

      /* Check if the CartonType is passed or not */
      if (@vCartonType is null)
        set @MessageName = 'CartonTypeIsRequired';
      else
      /* Check if the CartonType is Active or not */
      if (not exists(select *
                     from CartonTypes
                     where (Status       = 'A') and
                           (CartonType   = @vCartonType) and
                           (BusinessUnit = @BusinessUnit)))
        set @MessageName = 'CartonTypeIsInvalid';

      if (@MessageName is not null)
         goto ErrorHandler;

      /* Get the carton type weight and volume */
      select @vCartonVolume      = OuterVolume,
             @vEmptyCartonWeight = EmptyWeight
      from CartonTypes
      where (CartonType = @vCartonType) and
            (BusinessUnit = @BusinessUnit);

      /* Update CartonType and Weight */
      update L
      set CartonType   = @vCartonType,
          ActualWeight = coalesce(nullif(@vLPNWeight, 0), ActualWeight ),
          ActualVolume = case when @vCartonType is not null then @vCartonVolume else ActualVolume end, -- no matter how much the volume of the contents, the carton volume is applicable
          ModifiedDate = current_timestamp,
          ModifiedBy   = @UserId
      output Deleted.LPNId, Deleted.LPN into @ttLPNsUpdated
      from LPNs L join @ttLPNsToUpdate LP on (LP.EntityId = L.LPNId);

      set @vLPNsUpdated = @@rowcount;

      /* Audit Trail */
      exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                @BusinessUnit = @BusinessUnit,
                                @AuditRecordId = @vAuditRecordId output;
    end
  else
  if (@vAction = 'ModifyOwnership')
    begin
      select @vAuditActivity = 'LPNOwnerModified';

      /* Fetching of LPNOwnership from XML */
      select @vNewOwner = Record.Col.value('LPNOwner[1]', 'TTypeCode')
      from @xmlData.nodes('/ModifyLPNs/Data') as Record(Col);

      /* Validations */
      select @MessageName = dbo.fn_IsValidLookUp('Owner', @vNewOwner, @BusinessUnit, @UserId);

      if (@MessageName is not null)
        goto ErrorHandler;

      while (@vCount > 0)
        begin
          select @vLPNId = null, @vUpdatedLPNId = null;

          /* select next LPN to process */
          select top 1 @vLPNId = EntityId from @ttLPNsToUpdate;

          /* Updating the LPNs of XML with given Ownership when LPN Ownership and
             Ownership in XML are different. Cannot change Ownership of Reserved LPNs */
          update L
          set @vUpdatedLPNId = LPNId,
              @vQuantity     = Quantity,
              @vOldOwner     = Ownership,
              Ownership      = @vNewOwner,
              ModifiedDate   = current_timestamp,
              ModifiedBy     = @UserId
          from LPNs L
          where (L.Ownership  <> @vNewOwner       ) and
                (Status       =  'P' /* Putaway */) and
                (L.LPNId      =  @vLPNId          ) and
                (BusinessUnit =  @BusinessUnit    );

          set @vLPNsUpdated += @@rowcount;

          /* If the LPN was updated, then generate a transaction */
          if (@vUpdatedLPNId is not null)
            begin
              exec @ReturnCode = pr_Exports_LPNData 'InvCh' /* Inventory Changes */,
                                                    @LPNId      = @vLPNId,
                                                    @TransQty   = @vQuantity,
                                                    @Ownership  = @vNewOwner,
                                                    @ReasonCode = @vReasonCode,
                                                    @CreatedBy  = @UserId;

              set @vQuantity = -@vQuantity;

              /* Exporting Ownership info */
              exec @ReturnCode = pr_Exports_LPNData 'InvCh' /* Inventory Changes */,
                                                    @LPNId      = @vLPNId,
                                                    @TransQty   = @vQuantity,
                                                    @Ownership  = @vOldOwner,
                                                    @ReasonCode = @vReasonCode,
                                                    @CreatedBy  = @UserId;

              /* Audit Trail */
              exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                        @LPNId         = @vLPNId,
                                        @Note1         = @vOldOwner,
                                        @Note2         = @vNewOwner;
            end

          /* Delete the processed LPN */
          delete from @ttLPNsToUpdate
          where (EntityId = @vLPNId);

          set @vCount = @vCount - 1;
        end
    end /* Modify Ownership */
  else
  if (@vAction = 'ModifyWarehouse')
    begin
      select @vAuditActivity = 'LPNWarehouseModified';

      /* Fetching of New Warehouse from XML */
      select @vNewWarehouse = Record.Col.value('NewWarehouse[1]', 'TWarehouse')
      from @xmlData.nodes('/ModifyLPNs/Data') as Record(Col);

      /* Validations */
      select @MessageName = dbo.fn_IsValidLookUp('Warehouse', @vNewWarehouse, @BusinessUnit, @UserId);

      if (@MessageName is not null)
        goto ErrorHandler;

      while (@vCount > 0)
        begin
          select @vLPNId = null, @vUpdatedLPNId = null;

          /* select next LPN to process */
          select top 1 @vLPNId = EntityId from @ttLPNsToUpdate;

          /* Updating the LPNs of XML with given Warehouse when LPN Warehouse and
             Warehouse in XML are different. Cannot change Warehouse of Reserved LPNs */
          update L
          set @vUpdatedLPNId = LPNId,
              @vQuantity     = Quantity,
              @vOldWarehouse = DestWarehouse,
              @vOnhandStatus = OnhandStatus,
              @vLPNStatus    = Status,
              DestWarehouse  = @vNewWarehouse,
              ModifiedDate   = current_timestamp,
              ModifiedBy     = @UserId
          from LPNs L
          where (L.DestWarehouse <> @vNewWarehouse) and
                ((L.Status in  ( 'N', 'R' /* New , Received */)) or
                 (L.OnhandStatus =  'A' /* Available */)) and
                (L.LPNType     <> 'L' /* Logical */) and
                (L.LPNId       =  @vLPNId          ) and
                (L.ReservedQty = 0                 ) and
                (BusinessUnit  =  @BusinessUnit    );

          set @vLPNsUpdated += @@rowcount;

          /* If the LPN was updated, then generate a transaction */
          if (@vUpdatedLPNId is not null) and
             (@vLPNStatus <> 'N' /* New */ ) and
             (@vOnhandStatus = 'A' /* Available */) and
             (@vQuantity > 0)
            begin
              exec pr_Exports_WarehouseTransfer @LPNId        = @vUpdatedLPNId,
                                                @TransQty     = null,
                                                @OldWarehouse = @vOldWarehouse,
                                                @NewWarehouse = @vNewWarehouse,
                                                @CreatedBy    = @UserId;
            end

          /* Audit Trail */
          if (@vUpdatedLPNId is not null)
            exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                      @LPNId         = @vUpdatedLPNId,
                                      @Note1         = @vOldWarehouse,
                                      @Note2         = @vNewWarehouse;

          /* Delete the processed LPN */
          delete from @ttLPNsToUpdate
          where (EntityId = @vLPNId);

          set @vCount = @vCount - 1;
        end
    end /* Modify Warehouse */
  else
  if (@vAction = 'ChangeSKU')
    exec pr_LPNs_Action_ChangeSKU @xmlData, @BusinessUnit, @UserId;
  else
  if (@vAction = 'UnallocateLPNs')
    begin
      /* Delete LPNs from temp table, which are not allocated */
      delete from tt
      from @ttLPNsToUpdate tt
        join LPNs L on (tt.EntityId = L.LPNId) and (L.OnhandStatus <> 'R' /* Reserved */);

      /* Recalculate the valid LPNs to allocate */
      select @vCount = @vCount - @@rowcount;

      /* UnAllocate selected LPN(s) */
      exec pr_LPNs_Unallocate @LPNId         = null,
                              @LPNsToUpdate  = @ttLPNsToUpdate,
                              @UnallocPallet = 'P'/* PalletPick */,
                              @BusinessUnit  = @BusinessUnit,
                              @UserId        = @UserId;

      /* Get the LPNs which are not unallocated - still in Allocate */
      select @vLPNsUnallocated = count(*)
      from @ttLPNsToUpdate LU
        left join LPNs L on (L.LPNId = LU.EntityId)
      where L.OnHandStatus = 'R' /* Reserved */

      select @vLPNsUpdated = @vCount - @vLPNsUnallocated;
    end
  else
  if (@vAction = 'UpdateInvExpDate')
    begin
      select @vAuditActivity = 'UpdateLPNInvExpDate';

      /* Fetching of LPNOwnership from XML */
      select @vInvExpDate = Record.Col.value('InvExpDate[1]', 'TTypeCode')
      from @xmlData.nodes('/ModifyLPNs/Data') as Record(Col);

      /* Converting Date Format to dd/mm/yyyy for logging Audit Trail */
      select @vExpDate = convert(varchar, @vInvExpDate, 101);

      update L
      set ExpiryDate = @vInvExpDate
      output Deleted.LPNId, Deleted.LPN into @ttLPNsUpdated
      from LPNs L join @ttLPNsToUpdate LP on (LP.EntityId = L.LPNId)
      where L.Status not in ('C' /* Consumed */, 'V' /* Voided */, 'O' /* Lost */ , 'A' /* Allocated */, 'U' /* Picking */, 'K' /* Picked */, 'L' /* Loaded */, 'S' /* Shipped */  );

      set @vLPNsUpdated = @@rowcount;

      /* Audit Trail */
      exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                @BusinessUnit  = @BusinessUnit,
                                @Note1         = @vExpDate,
                                @AuditRecordId = @vAuditRecordId output;
    end
  else
  if (@vAction = 'Reverse-Receipt')
    begin
      /* Fetching of SKU from XML. */
      select @vReasonCode     = Record.col.value('ReasonCode[1]','TReasonCode'),
             @vReceiverNumber = Record.col.value('ReceiverNumber[1]','TReceiverNumber')
      from @xmldata.nodes('/ModifyLPNs/Data') as Record(col);

      if (coalesce(@vReasonCode, '') = '')
        set @Messagename = 'ReasonCodeIsRequired';
      else
      if (coalesce(@vReceiverNumber, '') = '')
        set @MessageName = 'ReceiverNumberIsRequired';

      if (@MessageName is not null)
        goto ErrorHandler;

      /* call procedure here to reverse receiving */
      exec pr_LPNs_ReverseReceipt null /* LPNId */, @ttLPNsToUpdate, @vReasonCode,
                                  @vReceiverNumber, @BusinessUnit, @UserId, @Message output;

    end
  else
  if (@vAction = 'ModifyLPNs')
    exec pr_LPNs_Action_ModifyLPNs @xmlData, @BusinessUnit, @UserId;
  else
  if (@vAction = 'ReGenerateTrackingNumber')
    begin
      /* ReGenerate Tracking Number */
      exec pr_Shipping_RegenerateTrackingNumbers null/* OrderId */, null/* LPNId */, @ttLPNsToUpdate, @BusinessUnit, @UserId, @Message output;
    end
  else
  if (@vAction = 'QCHold') or (@vAction = 'QCRelease')
    begin
      select @vReasonCode = Record.Col.value('ReasonCode[1]', 'TReasonCode'),
             @vReference  = Record.Col.value('Reference[1]',  'TReference')
      from @xmlData.nodes('/ModifyLPNs/Data') as Record(Col);

      exec pr_LPNs_QCHoldOrRelease @ttLPNsToUpdate, @vAction, @vReasonCode, @vReference, @BusinessUnit, @UserId, @Message output;
    end
  else
    begin
      /* If the action is not one of the above, send a message to UI saying Unsupported Action*/
      set @MessageName = 'UnsupportedAction';
      goto ErrorHandler;
    end

  /* Recount the pallets */
  if (@vLPNsUpdated > 0)
    exec pr_Pallets_Recalculate @ttPalletsToRecount, 'C' /* Recalculate counts */, @BusinessUnit, @UserId;

  /* If multiple LPNs are updated and only one audit record is created for all of
     them, then associate the Updated LPNs with the Audit record */
  if (@vAuditRecordId is not null)
    exec pr_AuditTrail_InsertEntities @vAuditRecordId, @vEntity, @ttLPNsUpdated, @BusinessUnit;

  /* Based upon the number of LPNs that have been modified, give an appropriate message */
  if (coalesce(@Message, '') = '') or (not exists(select * from #ResultMessages))
    exec @Message = dbo.fn_Messages_BuildActionResponse @vEntity, @vAction, @vLPNsUpdated, @vLPNsCount;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;
  exec @ReturnCode = pr_ReRaiseError;
end catch

  return(coalesce(@ReturnCode, 0));
end /* pr_LPNs_Modify */

Go
