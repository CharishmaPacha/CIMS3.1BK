/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/07/11  PKK     pr_Shipping_VoidShipLabels, pr_Shipping_ShipLabelsInsert_New: Made changes to void the shiplabels and generate the new one (BK-867)
  2021/01/26  VS      pr_Shipping_VoidShipLabels: Pass the table value parameter to void the Shiplabels (BK-126)
  2021/01/04  RV      pr_Shipping_VoidShipLabels: Made changes to update the TaskId on ship labels table
  2020/06/04  RV      pr_Shipping_VoidShipLabels: Made changes to show messages in V3 (HA-745)
  2020/02/24  YJ      pr_Shipping_VoidShipLabels: Changes to update PickTicket, WaveNo, WaveId on ShipLabels (CID-1335)
  2019/10/03  AY      pr_Shipping_VoidShipLabels: Do not want to clear Tracking no even when labels are voided
  2018/08/29  RV      pr_Shipping_VoidShipLabels: Made changes to decide whether the shipment is small package carrier or not from
                        IsSmallPackageCarrier flag from ShipVias table (S2GCA-131)
  2018/05/31  MJ      pr_Shipping_VoidShipLabels: Added parameter and rules to regenerating shipLabels while voiding the LPNs based on the small package carrier (S2G-443)
  2018/05/23  MJ      pr_Shipping_VoidShipLabels: Added parameter and rules to regenerating shiplabels while voiding the LPNs (S2G-443)
  2017/04/25  SV      pr_Shipping_VoidShipLabels: Updates over the ShipLabels and LPNs upon voiding the LPN (HPI-846)
  2016/12/02  SV      pr_Shipping_VoidShipLabels : Considering LPN while voiding the ShipLabel (HPI-846)
  2016/05/11  RV      pr_Shipping_SaveLPNData: Update the OrderId in Ship Labels table
                      pr_Shipping_VoidShipLabels: Not allowed to void shipped labels (NBD-506)
  2012/01/30  YA      Added pr_Shipping_VoidShipLabels.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_VoidShipLabels') is not null
  drop Procedure pr_Shipping_VoidShipLabels;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_VoidShipLabels: Void the ship labels for all LPNs of an Order
    or for the given LPN or the list of LPNs given.
    Mark the ShipLabel as voided and change the EntityKey
    as there may be a new one generated again in future for same LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_VoidShipLabels
  (@OrderId         TRecordId,
   @LPNId           TRecordId,
   @ttLPNsToVoid    TEntityKeysTable Readonly,
   @BusinessUnit    TBusinessUnit,
   @RegenerateLabel TFlags        = 'N',
   @Message         TMessageName  = null output,
   @Operation       TOperation    = 'VoidShipLabels')
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vRecordsUpdated          TCount,

          @vLPN                     TLPN,
          @vLPNStatus               TStatus,
          @vLPNOrderId              TRecordId,
          @vInvalidLPNStatusToVoid  TStatus,
          @vOrderId                 TRecordId,
          @vPickTicket              TPickTicket,
          @vTaskId                  TRecordId,
          @vOrderStatus             TStatus,
          @vShipVia                 TShipVia,
          @vIsSmallPackageCarrier   TFlag,
          @vEntityType              TEntity,
          @vVoidedLPNCount          TCount,
          @vCarrier                 TCarrier;

  declare @ttShipLabelsToInsert     TShipLabels;

  declare @ttLPNsToUpdate table (RecordId  TRecordId identity (1,1) not null,
                                 LPNId     TRecordId,
                                 OrderId   TRecordId,
                                 TaskId    TRecordId,
                                 LPN       TLPN,
                                 LabelType TTypeCode,
                                 IsSmallPackageCarrier TFlag);
begin
  select @vReturnCode     = 0,
         @vRecordsUpdated = 0,
         @vOrderId        = @OrderId;

  /* Caller could pass in LPNs via #ShipLabelsToInsert, if not, then create one */
  if (object_id('tempdb..#ShipLabelsToInsert') is null)
    select * into #ShipLabelsToInsert from @ttShipLabelsToInsert;

  select @vInvalidLPNStatusToVoid = dbo.fn_Controls_GetAsString('VoidShipLabels', 'InvalidStatuses', 'S'/* Shipped */, @BusinessUnit, 'cIMSUser');

  /* If LPN is given then get the info to validate */
  if (coalesce(@LPNId, 0) <> 0)
    select @vLPN        = LPN,
           @vLPNOrderId = OrderId,
           @vOrderId    = OrderId,
           @vTaskId     = TaskId,
           @vLPNStatus  = Status,
           @vEntityType = 'LPN'
    from LPNs
    where (LPNId = @LPNId);

  /* Validate to allow update only on those orders which are NOT shipped */
  select @vPickTicket  = PickTicket,
         @vOrderStatus = Status,
         @vShipVia     = ShipVia,
         @vEntityType  = coalesce(@vEntityType, 'PickTicket')
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* Get the carrier info from ShipVias */
  select @vCarrier               = Carrier,
         @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from ShipVias
  where (ShipVia = @vShipVia) and (BusinessUnit = @BusinessUnit);

  if ((coalesce(@OrderId, 0) = 0) and (coalesce(@LPNId, 0) = 0)) and
     (not exists (select * from @ttLPNsToVoid))
    set @vMessageName = 'VoidShipLabels_InvalidInputs';
  else
  if (@vLPN is not null) and (@vLPNOrderId <> @vOrderId)
    set @vMessageName = 'VoidShipLabels_LPNOrderMismatch'
  else
  /* We will not allow to void ship label after shipped */
  if (@vLPN is not null) and (charindex(@vLPNStatus, @vInvalidLPNStatusToVoid) <> 0)
    set @vMessageName = 'VoidShipLabels_InvalidLPNStatus';
  else
  /* We will not allow to void ship label after shipped */
  if (@vOrderStatus in ('S' /* Shipped */))
    set @vMessageName = 'VoidShipLabels_InvalidOrderStatus';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If list of LPNs is given, void those labels only */
  if exists(select * from @ttLPNsToVoid)
    begin
      insert into @ttLPNsToUpdate(LPNId, LPN, OrderId, LabelType, TaskId, IsSmallPackageCarrier)
        select L.LPNId, L.LPN, L.OrderId, SL.LabelType, L.TaskId, S.IsSmallPackageCarrier
        from @ttLPNsToVoid LTV
          join LPNs L on (L.LPNId = LTV.EntityId)
          join ShipLabels SL on (SL.EntityKey = L.LPN) and (SL.BusinessUnit = L.BusinessUnit)
          join Shipvias S on (S.ShipVia = SL.RequestedShipVia)
        where (charindex(L.Status, @vInvalidLPNStatusToVoid) = 0) and
              (SL.OrderId = coalesce(@OrderId, SL.OrderId)) and
              (SL.Status  = 'A');

      /* Need to show in UI how many LPNs are voided */
      select @vVoidedLPNCount = count(*) from @ttLPNsToUpdate
    end
  else
  /* In case if LPN is provided, void that LPN only */
  if (coalesce(@LPNId, 0) <> 0)
    insert into @ttLPNsToUpdate(LPNId, LPN, OrderId, TaskId)
      select @LPNId, @vLPN, @vOrderId, @vTaskId;
  else
    /* Get all LPNs of the Order that have a small package label and are of valid status to void */
    insert into @ttLPNsToUpdate(LPNId, LPN, OrderId, LabelType, TaskId)
      select L.LPNId, L.LPN, @OrderId, SL.LabelType, L.TaskId
      from ShipLabels SL join LPNs L on (SL.EntityKey = L.LPN) and (L.BusinessUnit = @BusinessUnit)
      where (L.OrderId = @OrderId) and
            (charindex(L.Status, @vInvalidLPNStatusToVoid) = 0) and
            (SL.OrderId = @OrderId) and
            (SL.Status  = 'A');

  /* Void ShipLabels and clear Tracking# over the LPNs */
  update ShipLabels
  set EntityKey    = rtrim(EntityKey) + '_' + cast(SL.RecordId as varchar) + '_Void',
      --TrackingNo   = TrackingNo + '*' /* Can't update TrackingNo to null as per the definition */,
      Status       = 'V' /* Void */,
      ModifiedDate = current_timestamp
  from ShipLabels SL join @ttLPNsToUpdate TTL on (TTL.LPN = SL.EntityKey) and (SL.BusinessUnit = @BusinessUnit)

  select @vRecordsUpdated = @@rowcount

  /* Clear tracking no on the LPNs as that tracking no is not valid anymore */
  update LPNs
  set TrackingNo = null
  from LPNs L join @ttLPNsToUpdate TTL on (L.LPNId = TTL.LPNId);

  /* if any records are updated then give a confirmation message to users */
  if (@vRecordsUpdated > 0)
    begin
      select @Message = 'ShipLabel_Voided' + coalesce(@vEntityType, 'LPNs');

      /* Inserted the messages information to display in V3 application */
      if (object_id('tempdb..#ResultMessages') is not null)
        insert into #ResultMessages (MessageType, MessageName, Value1, Value2, Value3)
          select 'I' /* Info */, @Message, @vLPN, @vPickTicket, @vVoidedLPNCount;
    end

  /* After voiding the ShipLabels then Reinsert based on the parameter passed and new ShipVia */
  if (@RegenerateLabel = 'Y'/* Yes */)
    begin
      if (exists (select * from @ttLPNsToUpdate where IsSmallPackageCarrier = 'Y'))
        begin
          insert into #ShipLabelsToInsert(EntityId, EntityType, EntityKey, CartonType, OrderId, TaskId, WaveId, WaveNo, LabelType)
            select L.LPNId, 'L', L.LPN, L.CartonType, L.OrderId, L.TaskId, L.PickBatchId, L.PickBatchNo, ''
            from LPNs L
              join @ttLPNsToUpdate ttV on (L.LPNId = ttV.LPNId) and (ttV.IsSmallPackageCarrier = 'Y')
            where (L.LPNType = 'S') ;

            exec pr_Shipping_ShipLabelsInsert 'Shipping' /* Module */, @Operation, null, null, @BusinessUnit, 'CIMSAgent2'/* UserId */;

            /* Confirmation message */
            select @Message = 'ShipLabel_Inserted' + coalesce(@vEntityType, 'LPNs');

            /* Inserted the messages information to display in V3 application */
            if (object_id('tempdb..#ResultMessages') is not null)
              insert into #ResultMessages (MessageType, MessageName, Value1)
                select 'I' /* Info */, @Message, EntityKey from #ShipLabelsToInsert;
        end
      else
      if (@vIsSmallPackageCarrier = 'Y' /* Yes */)
        begin
          exec pr_Shipping_ShipLabelsInsert 'Shipping' /* Module */, @Operation, @vOrderId, @LPNId, @BusinessUnit, 'CIMSAgent2'/* UserId */;

          /* Confirmation message */
          select @Message = 'ShipLabel_Inserted' + coalesce(@vEntityType, 'LPNs');

          /* Inserted the messages information to display in V3 application */
          if (object_id('tempdb..#ResultMessages') is not null)
            insert into #ResultMessages (MessageType, MessageName, Value1, Value2, Value3)
              select 'I' /* Info */, @Message, @vLPN, @vPickTicket, @vVoidedLPNCount;
        end
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_VoidShipLabels */

Go
