/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/25  SK      pr_Loads_Action_ActivateShipCartons, pr_Loads_Action_ActivateShipCartonsValidate: Initial revision (HA-2808)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_Action_ActivateShipCartonsValidate') is not null
  drop Procedure pr_Loads_Action_ActivateShipCartonsValidate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_Action_ActivateShipCartonsValidate: This procedure is used
      a. Validate the inventory check for ship cartons to get activated
      b. Run activation of ship cartons in the background
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_Action_ActivateShipCartonsValidate
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
          /* Process variables */
          @vLoadId                     TRecordId,
          @vActionProcedure            TName,
          @vDataXML                    TXML;
          /* temporary tables */
  declare @ttSelectedEntities          TEntityValuesTable,
          @ttLPNDetails                TLPNDetails;

  declare @ttOrders table (OrderId    TRecordId,
                           WaveId     TRecordId,

                           RecordId   TRecordId identity(1,1));
begin /* pr_Loads_Action_ActivateShipCartonsValidate */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vRecordId       = 0,
         @vAuditActivity  = 'Load_ActivateShipCartonsRequest',
         @vRecordsUpdated = 0;

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Create temp tables */
  select * into #BulkOrders from @ttOrders;
  select * into #ToLPNDetails from @ttLPNDetails;
  select * into #FromLPNDetails from @ttLPNDetails;

  /* Basic validations */
  delete from SE
  output 'E', Deleted.EntityId, 'Loads_ActivateShipCartons_InvalidStatus', ST.StatusDescription
  into #ResultMessages (MessageType, EntityId, MessageName, Value1)
  from #ttSelectedEntities SE
    join Loads LD on SE.EntityId = LD.LoadId
    join Statuses ST on LD.Status = ST.StatusCode and ST.Entity = 'Load'
  where LD.Status in ('S', 'X' /* Shipped, Cancelled */);

  /* Exit if there are no records to process */
  if (not exists(select * from #ttSelectedEntities)) goto BuildMessage;

  /* Save selected entity into a different temp table */
  select * into #SelectedLoads from #ttSelectedEntities;

  /* Loop through all selected loads */
  while (exists(select * from #SelectedLoads where RecordId > @vRecordId))
    begin
      select top 1 @vLoadId   = EntityId,
                   @vRecordId = RecordId
      from #SelectedLoads
      where (RecordId > @vRecordId)
      order by RecordId;

      /* clear old entries */
      delete from #ttSelectedEntities;
      delete from #ToLPNDetails;
      delete from #FromLPNDetails;
      delete from #BulkOrders;
      delete from #ResultMessages;

      /* Populate ship cartons for validations */
      insert into #ttSelectedEntities (EntityId, EntityKey, EntityType, RecordId)
        select L.LPNId, L.LPN, 'LPN', row_number() over (order by (select 1))
        from LPNs L
        where (L.LoadId = @vLoadId) and
              (L.LPNType = 'S' /* Ship cartons */) and
              (L.Status = 'F' /* New Temp */);

      /* Populate LPN info - both from and to LPNs */
      exec pr_LPNs_Activation_PopulateLPNsInfo default /* Operation */, @BusinessUnit, @UserId;

      /* Validate for activation */
      exec pr_LPNs_Action_ActivateShipCartons_Validate @BusinessUnit, @UserId;

      /* If errors exist skip processing activation in the background */
      if (exists(select * from #ResultMessages))
        begin
          exec pr_Notifications_SaveValidations 'Load', @vLoadId, null /* MasterEntityKey */,
                                                default /* SaveTo as NO */, @vAction /* Operation */, @BusinessUnit, @UserId;

          /* Continue processing next load */
          continue;
        end

      select @vDataXML = cast(@xmlData as varchar(max));

      exec pr_Entities_ExecuteInBackground @Entity            = 'Load',
                                           @EntityId          = @vLoadId /* EntityId */,
                                           @ProcessClass      = 'UIAction',
                                           @ProcId            = @@ProcId,
                                           @Operation         = 'ActivateLPNs',
                                           @BusinessUnit      = @BusinessUnit,
                                           @ExecProcedureName = 'pr_Loads_Action_ActivateShipCartons',
                                           @InputParams       = @vDataXML;

      /* Update the count */
      select @vRecordsUpdated += 1;

      /* Clear all previous notifications of the Load */
      exec pr_Notifications_Clear 'Load', @vLoadId, null /* MasterEntityKey */,
                                  default /* SaveTo as NO */, @vAction /* Operation */, @BusinessUnit, @UserId;

      /* Audit Trail */
      exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                @BusinessUnit  = @BusinessUnit,
                                @LoadId        = @vLoadId;

    end /* End of looping through Loads */

BuildMessage:
  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAuditActivity, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_Action_ActivateShipCartonsValidate */

Go
