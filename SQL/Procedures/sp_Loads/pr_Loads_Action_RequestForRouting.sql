/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/06  AY/YJ   pr_Loads_Action_RequestForRouting: Nullify if 0 is sent for some of the fields (HA-2553)
  2021/02/20  PK      pr_Loads_Action_RequestForRouting: Added DesiredShipDate (HA-2029)
  2021/01/11  SK      pr_Loads_Action_RequestForRouting: New procedure for user to request for routing on Load (HA-1896)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_Action_RequestForRouting') is not null
  drop Procedure pr_Loads_Action_RequestForRouting;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_Action_RequestForRouting: This method is used to send new export
       transactions of type EDI753 consolidated by PT/SalesOrder and update the
       Load routing status as "Awaiting Routing Confirmations".
       User would decide on which Load(s) should this action would be performed.
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_Action_RequestForRouting
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vLoadId                     TRecordId,
          /* Process variables */
          @vControlValue               TControlValue,
          @vDesiredShipDate            TDateTime;

  declare @ttEntityValues              TEntityValuesTable;
begin /* pr_Loads_Action_RequestForRouting */
  SET NOCOUNT ON;

  select @vReturnCode      = 0,
         @vMessageName     = null,
         @vRecordId        = 0,
         @vRecordsUpdated  = 0,
         @vAuditActivity   = 'Loads_RequestForRouting';

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  /* Basic validations of input data or entity info */

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get Controls */
  select @vControlValue = dbo.fn_Controls_GetAsString('Load', 'RequestRoutingValidStatus', 'N' /* New */, @BusinessUnit, @UserId);

  /* Get total records selected */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Validations */

  delete from SE
  output 'E', LD.LoadId, LD.LoadNumber, 'Loads_RequestForRouting_NotValidLoadStatus', ST.StatusDescription
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2)
  from #ttSelectedEntities SE
   join Loads    LD on SE.EntityId = LD.LoadId
   join Statuses ST on ST.Entity   = 'Load' and LD.Status = ST.StatusCode and LD.BusinessUnit = ST.BusinessUnit
  where (dbo.fn_IsInList(LD.Status, @vControlValue) = 0);

  /* Validate if at least 1 Order associated on Load */
  delete from SE
  output 'E', LD.LoadId, LD.LoadNumber, 'Loads_RequestForRouting_NoOrders'
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from #ttSelectedEntities SE join Loads LD on SE.EntityId = LD.LoadId
  where (LD.NumOrders = 0);

  /* Update Routing status on Load */
  update LD
  set @vDesiredShipDate = LD.DesiredShipDate, /* ToShipOnDate */
      LD.RoutingStatus  = 'A' /* Awaiting Routing Confirmation */
  from #ttSelectedEntities SE join Loads LD on SE.EntityId = LD.LoadId;

  select @vRecordsUpdated = @@rowcount;

  if (@vRecordsUpdated = 0) return;

  /* Build temp table with the Result set of the procedure */
  create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'Exports', '#ExportRecords';

  /* Export the info for each load summarized by ShipTo, PT and CustPO - TransQty for EDI753
     is number of shipping cartons
     Load can/cannot have LPNs while sending this export */
  insert into #ExportRecords (TransType, Warehouse, Ownership, LoadId, OrderId, SoldToId, ShipToId, ShipVia,
                              TransQty, Weight, Volume,
                              NumPallets, NumLPNs,
                              NumCartons, InnerPacks,
                              Quantity, DesiredShipDate)
    select 'EDI753', OH.Warehouse, OH.Ownership, OS.LoadId, OH.OrderId, OH.SoldToId, OH.ShipToId, OH.ShipVia,
           coalesce(nullif(count(L.LPNId), 0), nullif(sum(OH.LPNsAssigned), 0), sum(OH.EstimatedCartons)), coalesce(sum(L.LPNWeight), sum(OH.TotalWeight)), coalesce((sum(L.LPNVolume)), sum((OH.TotalVolume * 1728)/1)),
           coalesce(count(distinct L.PalletId), 0), coalesce(nullif(count(L.LPNId), 0), nullif(sum(OH.LPNsAssigned), 0), sum(OH.EstimatedCartons)),
           coalesce(nullif(count(L.LPNId), 0), nullif(sum(OH.LPNsAssigned), 0), sum(OH.EstimatedCartons)), coalesce(sum(L.InnerPacks), 0),
           coalesce(sum(L.Quantity), sum(OH.NumUnits)), @vDesiredShipDate
    from #ttSelectedEntities SE
     join vwOrderShipments OS on SE.EntityId = OS.LoadId
     join OrderHeaders OH     on OS.OrderId  = OH.OrderId
     left join LPNs L         on SE.EntityId = L.LoadId and OH.OrderId = L.OrderId and L.LPNType = 'S' /* Shipping Carton */
    group by OH.Warehouse, OH.Ownership, OS.LoadId, OH.OrderId, OH.SoldToId, OH.ShipToId, OH.ShipVia;

  /* Insert export records */
  exec pr_Exports_InsertRecords 'EDI753' /* TransType */, 'Load' /* TransEntity */, @BusinessUnit;

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'Entity', EntityId, EntityKey, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, EntityKey, null, null, null, null) /* Comment */
    from #ttSelectedEntities;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_Action_RequestForRouting */

Go
