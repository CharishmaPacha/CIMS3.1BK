/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/25  SK      pr_Loads_Action_ActivateShipCartons, pr_Loads_Action_ActivateShipCartonsValidate: Initial revision (HA-2808)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_Action_ActivateShipCartons') is not null
  drop Procedure pr_Loads_Action_ActivateShipCartons;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_Action_ActivateShipCartons: This procedure is used to activate
    Ship cartons of the selected Load entity

    Note:
      This procedure is initiated from background process
      This is initiated for 1 Load at a time
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_Action_ActivateShipCartons
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
          @vDebug                      TFlags,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          /* Totals */
          @vNumCartonsSelected         TCount,
          @vNumCartonsWithErrors       TCount,
          @vCartonsActivated           TCount,
          /* Process variables */
          @vLoadId                     TRecordId,
          @vActionProcedure            TName,
          @vDataXML                    TXML,
          @vxmlInput                   xml;
          /* temporary tables */
  declare @ttSelectedEntities          TEntityValuesTable,
          @ttLPNDetails                TLPNDetails,
          @ttMarkers                   TMarkers;

  declare @ttOrders table (OrderId    TRecordId,
                           WaveId     TRecordId,

                           RecordId   TRecordId identity(1,1));
begin /* pr_Loads_Action_ActivateShipCartons */
  SET NOCOUNT ON;

  select @vReturnCode           = 0,
         @vMessageName          = null,
         @vRecordId             = 0,
         @vAuditActivity        = 'Load_ActivateShipCartonsDone',
         @vRecordsUpdated       = 0,
         @vNumCartonsSelected   = 0,
         @vNumCartonsWithErrors = 0,
         @vCartonsActivated     = 0;

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Check if in debug mode */
  if (coalesce(@vDebug, '') = '')
    exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Create temp tables */
  select * into #BulkOrders from @ttOrders;
  select * into #ToLPNDetails from @ttLPNDetails;
  select * into #FromLPNDetails from @ttLPNDetails;

  if (object_id('tempdb..#ttSelectedEntities') is null) select * into #ttSelectedEntities from @ttSelectedEntities;
  if (object_id('tempdb..#Markers') is null) select * into #Markers from @ttMarkers;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Load Activation Start', @@ProcId;

  /* Save selected entity into a different temp table as SelectedEntities will be used for LPNs */
  select * into #SelectedLoad from #ttSelectedEntities;

  /* Background process request is sent for one Load at a time */
  select distinct @vLoadId = EntityId from #SelectedLoad;

  /* Clear temp table and Insert LPNs to activate */
  delete from #ttSelectedEntities;
  insert into #ttSelectedEntities(EntityId, EntityKey, EntityType, RecordId)
    select L.LPNId, L.LPN, 'LPN', row_number() over (order by (select 1))
    from LPNs L
    where (L.LoadId = @vLoadId) and
          (L.LPNType = 'S' /* Ship cartons */) and
          (L.Status = 'F' /* New Temp */);

  /* Get total ship cartons and if none found auditlog and exit */
  select @vNumCartonsSelected = count(*) from #ttSelectedEntities;

  if (@vNumCartonsSelected = 0) goto AuditLogging;

  /* Populate LPN info - both from & to LPNs */
  exec pr_LPNs_Activation_PopulateLPNsInfo default /* operation */, @BusinessUnit, @UserId;

  /* Validations */
  exec pr_LPNs_Action_ActivateShipCartons_Validate @BusinessUnit, @UserId;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Get LPNs and Validate end', @@ProcId;

  /* If all LPN records have issues, notify on the load, auditlog and exit */
  if (not exists(select * from #ttSelectedEntities)) or (exists(select * from #ResultMessages))
    begin
      exec pr_Notifications_SaveValidations 'Load', @vLoadId, null /* MasterEntityKey */,
                                            default /* SaveTo as NO */, @vAction /* Operation */, @BusinessUnit, @UserId;

      goto AuditLogging;
    end

  /* Populate XML input for activating LPNs procedure: Driven by ToLPNs */
  select @vxmlInput = dbo.fn_XMLNode('ConfirmLPNReservations',
                        dbo.fn_XMLNode('LPNType',       'S' /* ShipCarton */) +
                        dbo.fn_XMLNode('BusinessUnit',  @BusinessUnit) +
                        dbo.fn_XMLNode('UserId',        @UserId));

  begin try
    /* Activate Ship Carton LPN with audit logs */
    exec pr_Reservation_ActivateLPNs @vxmlInput;

    /* LPN counts */
    select @vNumCartonsWithErrors = count(distinct EntityId) from #ResultMessages where (MessageType = 'E' /* Error */);
    select @vCartonsActivated     = @vNumCartonsSelected - coalesce(@vNumCartonsWithErrors, 0);
    /* Load count */
    select @vRecordsUpdated       = @vTotalRecords; --although we had issues with some LPNs, Load has been processed
  end try
  begin catch
    insert into #ResultMessages (MessageType, EntityId, MessageName)
      select 'E' /* Error */, @vLoadId, ERROR_MESSAGE();
  end catch

  /* Save any errors or clear prior ones */
  exec pr_Notifications_SaveValidations 'Load', @vLoadId, null /* MasterEntityKey */,
                                        default /* SaveTo as NO */, @vAction /* Operation */, @BusinessUnit, @UserId;

AuditLogging:
  /* Audit Trail */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit = @BusinessUnit,
                            @LoadId       = @vLoadId,
                            @Note1        = @vCartonsActivated,
                            @Note2        = @vNumCartonsSelected;

BuildMessage:
  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAuditActivity, @vRecordsUpdated, @vTotalRecords;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Load Activation end', @@ProcId, @vLoadId;
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log default, 'Load', @vLoadId, null, 'Activation', @@ProcId, 'End Activation';

  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_Action_ActivateShipCartons */

Go
