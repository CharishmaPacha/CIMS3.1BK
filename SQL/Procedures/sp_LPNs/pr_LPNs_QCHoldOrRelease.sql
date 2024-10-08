/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/08  AY/VS   Added new procedure pr_LPNs_QCHoldOrRelease and modified in pr_LPNs_Modify for HoldQC and ReleaseQC added Reference field in exports(CID-68)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_QCHoldOrRelease') is not null
  drop Procedure pr_LPNs_QCHoldOrRelease;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_QCHoldOrRelease:
  This proc is used for HoldQC and Release QC Actions,
  When inventory is Quality Check processes we use this actions.

  HoldQC --Inventory was there in 999 Warehouse for QC
  ReleaseQC-- When QC is completed will move the inventory to Original Warehouse i.e 000
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_QCHoldOrRelease
  (@ttLPNsToUpdate   TEntityKeysTable ReadOnly,
   @Action           TAction,
   @ReasonCode       TReasonCode,
   @Reference        TReference,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @Message          TMessage output)
as
  declare @vTotalLPNCount     TCount,
          @vValidLPNStatuses  TControlValue,
          @vLPNStatus         TStatus,
          @vLPNId             TRecordId,
          @vLPN               TLPN,
          @xmlRulesData       TXML,
          @vOldSKUId          TRecordId,
          @vReturnCode        TInteger,
          @vPrevLPNStatus     TStatus,
          @vPrevInvStatus     TInventoryStatus,
          @vPrevWarehouse     TWarehouse,
          @vNewWarehouse      TWarehouse,
          @vAuditActivity     TActivityType,
          @vAuditId           TRecordId,
          @AuditRecordId      TRecordId,
          @vMessageName       TMessageName,
          @vUpdatedLPNsCount  TCount,
          @vRecordId          TRecordId;

  declare @ttLPNsProcessed TRecountKeysTable;

  If object_id('tempdb..#LPNsForQC') is null
  create table #LPNsForQC(RecordId         Int,
                          LPNId            Int,
                          LPN              varchar(50),
                          Status           varchar(10),
                          Warehouse        varchar(10),
                          InventoryStatus  varchar(2),
                          Processed        varchar(2) default 'N',
                          Action           varchar(50),
                          BusinessUnit     varchar(10));

begin
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = 'LPN' + @Action;

  /* Fetch details from tables/views */
  insert into #LPNsForQC (RecordId, LPNId, LPN, Action, BusinessUnit)
    select RecordId, EntityId, EntityKey, @Action, @BusinessUnit
    from @ttLPNsToUpdate;

  select @vTotalLPNCount = @@rowcount; -- Save the total count of LPNs that are being processed

  /* Get LPN Info */
  update LQC
  set Status          = L.Status,
      InventoryStatus = L.InventoryStatus,
      Warehouse       = L.DestWarehouse
  from LPNs L join #LPNsForQC LQC on LQC.LPNId = L.LPNId

  /* Validation for LPN */
  --select @ValidLPNStatuses = dbo.fn_Controls_GetAsString('LPN_'+@Action, 'ValidLPNStatus', 'RTP', @BusinessUnit, @UserId);

  /* Filter out bad data */
  if (@Action = 'QCHold')
    begin
      /* cannot put LPNs on QC Hold unless they are in InTransit, Received or Putaway status */
      delete from #LPNsForQC where Status not in ('T', 'R', 'P');

      /* eliminate LPNs already on QC */
      delete from #LPNsforQC where InventoryStatus = 'QC';
    end
  else
  if (@Action = 'QCRelease')
    begin
      /* eliminate LPNs which are not on QC */
      delete from #LPNsforQC where InventoryStatus <> 'QC';
    end

  /* Validations */
  if (@vTotalLPNCount = 0)
    set @vMessageName = 'InvalidData'

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Setup data for processing rules */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('ReasonCode', @ReasonCode) +
                           dbo.fn_XMLNode('Reference',  @Reference) +
                           dbo.fn_XMLNode('Action',     @Action));

  /* Perform the updates */
  exec pr_RuleSets_ExecuteRules 'QCInbound_LPNHoldorRelease', @xmlRulesData;

  /* Get the processed LPNs and preprocess them now */
  insert into @ttLPNsProcessed (EntityId, EntityKey)
    select LQC.LPNId, LQC.LPN
    from #LPNsForQC LQC join LPNs L on LQC.LPNId = L.LPNId
    where (LQC.InventoryStatus <> L.InventoryStatus);

  /* Get the Count of Updated LPNs */
  select @vUpdatedLPNsCount = @@rowcount;

  /* Preprocess the LPNs */
  exec pr_LPNs_Recalculate @ttLPNsProcessed, 'P' /* preprocess */, @BusinessUnit;

  /* Loop thru the processed LPNs and generate exports for the change */
  while (exists (select * from @ttLPNsProcessed where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId = RecordId,
                   @vLPNId    = EntityId
      from @ttLPNsProcessed
      where RecordId > @vRecordId;

      /* Get the previous values for the LPN */
      select @vPrevLPNStatus = Status,
             @vPrevWarehouse = Warehouse,
             @vPrevInvStatus = InventoryStatus
      from #LPNsForQC
      where (LPNId = @vLPNId);

      /* Get the NewWarehouse to Generate Exports or not */
      select @vNewWarehouse = DestWarehouse
      from LPNs
      where (LPNId = @vLPNId);

      /* Create Audit trail for the LPN */
      exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                @LPNId         = @vLPNId,
                                @Note1         = @vPrevWarehouse,
                                @Note2         = @vNewWarehouse,
                                @BusinessUnit  = @BusinessUnit;

      /* only putaway LPNs would require exports if there is change in Warehouse */
      if (@vPrevLPNStatus <> 'P') or (@vPrevWarehouse = @vNewWarehouse) continue;

      /* Generate exports */
      exec pr_Exports_WarehouseTransfer @LPNId        = @vLPNId,
                                        @TransQty     = null,
                                        @OldWarehouse = @vPrevWarehouse,
                                        @NewWarehouse = @vNewWarehouse,
                                        @ReasonCode   = @ReasonCode,
                                        @Reference    = @Reference;

    end /* End of While loop*/

  /* Based upon the number of LPNs that have been modified, give an appropriate message */
  if (coalesce(@Message, '') = '')
    exec @Message = dbo.fn_Messages_BuildActionResponse 'LPN', @Action, @vUpdatedLPNsCount, @vTotalLPNCount;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_QCHoldOrRelease */

Go
