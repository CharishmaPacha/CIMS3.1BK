/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/20  TK      pr_LPNs_Action_ActivateShipCartons_Validate: Validate UCCBarcode (HA-2816)
  2021/04/15  AY      pr_LPNs_Action_ActivateShipCartons_Validate: Give better error messages (HA-2636)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Action_ActivateShipCartons_Validate') is not null
  drop Procedure pr_LPNs_Action_ActivateShipCartons_Validate;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Action_ActivateShipCartons_Validate: Validates the LPNs in #ttSelectedLPNs
   and eliminates the ones that cannot be processed.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Action_ActivateShipCartons_Validate
  (@BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vDebug                   TFlags,

          @vTotalLPNs               TCount,
          @vToLPNValidTypes         TControlValue,
          @vToLPNInvalidStatus      TControlValue,
          @vAutoConfirmWavetypes    TControlValue;

  declare @ttLPNDetailSummary table (KeyValue         TEntityKey,
                                     Quantity         TQuantity,
                                     SKUId            TRecordId,
                                     InventoryClass1  TInventoryClass,
                                     InventoryClass2  TInventoryClass,
                                     InventoryClass3  TInventoryClass

                                     Primary Key      (KeyValue));
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Temp tables */
  select * into #ToLPNDetailsSummary from @ttLPNDetailSummary;
  select * into #FromLPNDetailsSummary from @ttLPNDetailSummary;

  /* Get Controls */
  select @vToLPNValidTypes      = dbo.fn_Controls_GetAsString('LPNShipCartonActivate', 'ValidToLPNTypes', 'S' /* default: shipcarton */, @BusinessUnit, @UserId),
         @vToLPNInvalidStatus   = dbo.fn_Controls_GetAsString('LPNShipCartonActivate', 'InvalidToLPNStatuses', 'CVOSELI' /* default: consumed/void/lost/shipped/loaded/inactive */, @BusinessUnit, @UserId),
         @vAutoConfirmWavetypes = dbo.fn_Controls_GetAsString('LPNShipCartonActivate', 'AutoConfirmWaves', 'CP,BCP' /* default: CasePick/BulkCasePick */, @BusinessUnit, @UserId);

  /* No LPNs to activate */
  if (not exists(select * from #ttSelectedEntities))
    begin
      insert into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
        select 'E', null, null, 'LPNActivation_NoLPNsToActivate'

      goto ExitHandler;
    end

  /* delete if other than ship cartons are selected to activate */
  delete from SE
  output 'E', deleted.EntityId, deleted.EntityKey, 'LPNActivation_LPNTypeIsInvalid', deleted.EntityKey
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value1)
  from #ttSelectedEntities SE
    join LPNs L on (L.LPNId = SE.EntityId)
  where (dbo.fn_IsInList(L.LPNType, @vToLPNValidTypes) = 0);

  /* delete if other than ship cartons are selected to activate */
  delete from SE
  output 'E', deleted.EntityId, deleted.EntityKey, 'LPNActivation_InvalidLPNStatus', deleted.EntityKey, S.StatusDescription
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value1, Value2)
  from #ttSelectedEntities SE
    join LPNs     L on (L.LPNId = SE.EntityId)
    join Statuses S on (S.Entity = 'LPN') and (S.StatusCode = L.Status) and (S.BusinessUnit = L.BusinessUnit)
  where (dbo.fn_IsInList(L.Status, @vToLPNInvalidStatus) > 0);

  /* delete if the LPNs are already activated */
  delete from SE
  output 'E', deleted.EntityId, deleted.EntityKey, 'LPNActivation_AlreadyActivated', deleted.EntityKey, S.StatusDescription
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value1, Value2)
  from #ttSelectedEntities SE
    join LPNs     L on (L.LPNId = SE.EntityId)
    join Statuses S on (S.Entity = 'LPN') and (S.StatusCode = L.Status) and (S.BusinessUnit = L.BusinessUnit)
  where (L.OnhandStatus = 'R' /* Reserved */);

  /* delete the LPNs which have no details that can be activated. We only load the LDs which are
     Unavailable into #ToLPNDetails */
  delete from SE
  output 'E', deleted.EntityId, deleted.EntityKey, 'LPNActivation_LPNInvalidOnhandStatus', deleted.EntityKey
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value1)
  from #ttSelectedEntities SE left join #ToLPNDetails TLD on SE.EntityId = TLD.LPNId
  where (TLD.LPNId is null);

  /* delete ship cartons that belong to invalid wave types */
  delete from SE
  output 'E', deleted.EntityId, deleted.EntityKey, 'LPNActivation_WaveTypeIsInvalid', deleted.EntityKey
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value1)
  from #ttSelectedEntities SE
    join LPNs L on (L.LPNId = SE.EntityId)
    join Waves W on (L.PickBatchId = W.WaveId)
  where (dbo.fn_IsInList(WaveType, @vAutoConfirmWavetypes) = 0);

  /*----- Summarize quantites by KeyValue -----*/

  insert into #ToLPNDetailsSummary (KeyValue, SKUId, Quantity, InventoryClass1, InventoryClass2, InventoryClass3)
    select KeyValue, min(SKUId) SKUId, sum(Quantity) Quantity,
           min(InventoryClass1) InventoryClass1, min(InventoryClass2) InventoryClass2, min(InventoryClass3) InventoryClass3
    from #ToLPNDetails
    group by KeyValue;

  insert into #FromLPNDetailsSummary (KeyValue, SKUId, Quantity, InventoryClass1, InventoryClass2, InventoryClass3)
    select KeyValue, min(SKUId) SKUId, sum(AllocableQty),
           min(InventoryClass1) InventoryClass1, min(InventoryClass2) InventoryClass2, min(InventoryClass3) InventoryClass3
    from #FromLPNDetails
    group by KeyValue;

  if (exists(select *
             from #ToLPNDetailsSummary TLD
               left outer join #FromLPNDetailsSummary FLD on (TLD.KeyValue = FLD.KeyValue)
             where (TLD.Quantity > coalesce(FLD.Quantity, 0))))
    begin
      insert into #ResultMessages (MessageType, MessageName, Value1, Value2, Value3, Value4)
        select 'E' /* Error */, 'LPNActivation_InvShortToActivate', S.SKU, S.Description,
                        TLD.Quantity - coalesce(FLD.Quantity, 0), TLD.InventoryClass1
        from #ToLPNDetailsSummary TLD
          left outer join #FromLPNDetailsSummary FLD on TLD.KeyValue = FLD.KeyValue
          join SKUs S on S.SKUId = TLD.SKUId
        where (TLD.Quantity > coalesce(FLD.Quantity, 0));
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Action_ActivateShipCartons_Validate */

Go
