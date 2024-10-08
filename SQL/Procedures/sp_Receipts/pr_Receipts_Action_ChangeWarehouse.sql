/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/19  AJM     pr_Receipts_Action_ChangeWarehouse : New procedure (HA-926)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_Action_ChangeWarehouse') is not null
  drop Procedure pr_Receipts_Action_ChangeWarehouse;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_Action_ChangeWarehouse: This procedure used to change the
      Warehouse on selected receipts
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_Action_ChangeWarehouse
  (@xmlData          xml,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @ResultXML        TXML    = null output)
as
  /* Declare local variables */
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vRecordId             TRecordId,
          @ttAuditTrailInfo      TAuditTrailInfo,
          @vReceiptid            TRecordId,
          @vEntity               TEntity,
          @vAction               TAction,
          @vReceiptsCount        TCount,
          @vRecordsUpdated       TCount,
          @vTotalRecords         TCount,

          /* Warehouse Change */
          @vOldWarehouse         TWarehouse,
          @vNewWarehouse         TWarehouse,

          @vValidReceiptStatuses TControlValue,
          @vMessage              TDescription,
          @vAuditActivity        TActivityType;

  declare @ttUpdatedReceipts table
          (ReceiptId            TRecordId,
           ReceiptNumber        TReceiptNumber,
           OldWarehouse         TWarehouse,
           NewWarehouse         TWarehouse,
           RecordId             TRecordId identity(1,1));

begin /* pr_Receipts_Action_ChangeWarehouse */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vRecordsUpdated = 0,
         @vRecordId       = 0,
         @vAuditActivity  = 'AT_Receipt_WarehouseChanged'

  /* Get the total count of receipts from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  select * into #UpdatedReceipts from @ttUpdatedReceipts

  select @vEntity       = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction       = Record.Col.value('Action[1]', 'TAction'),
         @vNewWarehouse = Record.Col.value('(Data/NewWarehouse) [1]', 'TWarehouse')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  select @vValidReceiptStatuses = dbo.fn_Controls_GetAsString('Receipts', 'ChangeWarehouse_ValidStatuses', 'I' /* Initial */, @BusinessUnit, @UserId);

  /* Validations */
  select @vMessageName = dbo.fn_IsValidLookUp('Warehouse', @vNewWarehouse, @BusinessUnit, @UserId);

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If new WH and existing receipts WH are same delete them from #table */
  delete ttSE
  output 'E', 'Receipts_ChangeWH_SameWarehouse', RH.ReceiptNumber, RH.Warehouse
  into #ResultMessages (MessageType, MessageName, Value1, Value2)
  from ReceiptHeaders RH join #ttSelectedEntities ttSE on (RH.ReceiptId = ttSE.EntityId)
  where (RH.Warehouse  = @vNewWarehouse); /* Should not update if Prev and selected Warehouse is same */

  /* If any receipts has invalid status to change WH delete them here */
  delete ttSE
  output 'E', 'Receipts_ChangeWH_InvalidStatus', RH.ReceiptNumber, RH.ReceiptStatusDesc
  into #ResultMessages (MessageType, MessageName, Value1, Value2)
  from vwReceiptHeaders RH join #ttSelectedEntities ttSE on (RH.ReceiptId = ttSE.EntityId)
  where (charindex (RH.Status, @vValidReceiptStatuses) = 0);

  /* Update with WH of remaining Receipts */
  update RH
  set Warehouse    = @vNewWarehouse,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output inserted.ReceiptId, inserted.ReceiptNumber, deleted.Warehouse, inserted.Warehouse
  into #UpdatedReceipts (ReceiptId, ReceiptNumber, OldWarehouse, NewWarehouse)
  from ReceiptHeaders RH join #ttSelectedEntities ttSE on RH.ReceiptId = ttSE.EntityId;

  set @vRecordsUpdated = @@rowcount;

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'Receipt', ReceiptId, ReceiptNumber, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, ReceiptNumber, OldWarehouse, NewWarehouse, null, null) /* Comment */
    from #UpdatedReceipts

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords, @vNewWarehouse;

  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_Action_ChangeWarehouse */

Go
