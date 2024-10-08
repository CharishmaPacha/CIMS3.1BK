/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/27  SK      pr_LPNs_Action_ActivateShipCartons: Enhancements to activate from Loads page and move inventory check validation (HA-2808)
  2021/05/20  TK      pr_LPNs_Action_ActivateShipCartons_Validate: Validate UCCBarcode (HA-2816)
  2021/05/06  VS/AY   pr_LPNs_Action_ActivateShipCartons: Show the Short Inventory To Activate the ShipCarton (HA-2732)
  2021/04/15  AY      pr_LPNs_Action_ActivateShipCartons: Performance optimiization (HA-2642)
  2021/04/15  AY      pr_LPNs_Action_ActivateShipCartons_Validate: Give better error messages (HA-2636)
  2021/03/30  SAK     pr_LPNs_Action_ActivateShipCartons: Added validation (HA-2356)
  2021/02/24  OK      pr_LPNs_Action_ActivateShipCartons: Changes to create the hash table with temparary table as creating them in loop
  2021/01/17  TK      pr_LPNs_Action_ActivateShipCartons: Bug fix to validate properly when SKU is picked into multiple cartons (HA-1918)
  2020/07/15  TK      pr_LPNs_Action_ActivateShipCartons & pr_LPNs_Activation_GetInventoryToDeduct:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Action_ActivateShipCartons') is not null
  drop Procedure pr_LPNs_Action_ActivateShipCartons;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Action_ActivateShipCartons: Generates required number of pallets and palletizes
    LPNs by grouping them by grouping criteria specified and prints labels of generated pallets
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Action_ActivateShipCartons
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,
          @vDebug                 TFlags,
          /* Input variables */
          @Entity                 TEntity,
          @Action                 TAction,
          @Operation              TOperation,
          /* LPN input */
          @vLPNId                 TRecordId,
          @vLPN                   TLPN,
          /* Load input */
          @vLoadId                TRecordId,
          /* Totals */
          @vNumCartonsSelected    TCount,
          @vNumCartonsWithErrors  TCount,
          @vCartonsActivated      TCount,
          /* xml variables */
          @xmlInput               xml;

  declare @ttMarkers              TMarkers,
          @ttLPNDetails           TLPNDetails,
          @ttSelectedEntities     TEntityValuesTable;

  declare @ttOrders table (OrderId    TRecordId,
                           WaveId     TRecordId,

                           RecordId   TRecordId identity(1,1));
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode       = 0,
         @vMessageName      = null,
         @vRecordId         = 0,
         @vCartonsActivated = 0;

  /* Create temp tables */
  select * into #ToLPNDetails from @ttLPNDetails;
  select * into #FromLPNDetails from @ttLPNDetails;
  select * into #BulkOrders from @ttOrders;

  if (object_id('tempdb..#Markers') is null) select * into #Markers from @ttMarkers;
  if (object_id('tempdb..#ttSelectedEntities') is null) select * into #ttSelectedEntities from @ttSelectedEntities;

  /* Read input XML */
  select @Entity = Record.Col.value('Entity[1]', 'TEntity'),
         @Action = Record.Col.value('Action[1]', 'TAction'),
         @vDebug = Record.Col.value('Debug[1]',  'TFlags')
  from @xmlData.nodes('/Root') as Record(Col)
  option(optimize for(@xmlData = null));

  /* Check if in debug mode */
  if (coalesce(@vDebug, '') = '')
    exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Activation Start', @@ProcId;

  /* Get the selected LPN Count */
  select @vNumCartonsSelected = count(*) from #ttSelectedEntities;

  /* Populate LPN info - both from & to LPNs */
  exec pr_LPNs_Activation_PopulateLPNsInfo default /* operation */, @BusinessUnit, @UserId;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Get LPN and Quantities', @@ProcId;

  /* Validations */
  exec pr_LPNs_Action_ActivateShipCartons_Validate @BusinessUnit, @UserId;

  /* If all records have errors skip processing */
  if (not exists(select * from #ttSelectedEntities)) goto BuildMessage;
  /* If there is inventory shortage of any SKU skip processing */
  if (exists(select * from #ResultMessages where MessageName = 'LPNActivation_InvShortToActivate')) goto BuildMessage;

  /* Populate XML input for activating LPNs procedure: Driven by ToLPNs */
  select @xmlInput = dbo.fn_XMLNode('ConfirmLPNReservations',
                       dbo.fn_XMLNode('LPNType',       'S'/* ShipCarton */) +
                       dbo.fn_XMLNode('BusinessUnit',  @BusinessUnit) +
                       dbo.fn_XMLNode('UserId',        @UserId));

  if (charindex('D', @vDebug) > 0) select * from #FromLPNDetails
  if (charindex('D', @vDebug) > 0) select * from #ToLPNDetails

  /* Activate Ship Carton LPN */
  exec pr_Reservation_ActivateLPNs @xmlInput;

BuildMessage:
  /* Get number of LPNs that got activated */
  select @vCartonsActivated = count(distinct LPNId) from #ToLPNDetails where (ProcessedFlag = 'A' /* Activated */);

  /* Build response to display to user */
  exec pr_Messages_BuildActionResponse @Entity, @Action, @vCartonsActivated, @vNumCartonsSelected;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Activation end', @@ProcId, @vLPN;
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log default, 'LPN', null, null, 'Activation', @@ProcId, 'End Activation';

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Action_ActivateShipCartons */

Go
