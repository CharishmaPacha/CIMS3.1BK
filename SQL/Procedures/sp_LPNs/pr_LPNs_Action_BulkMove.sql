/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/31  TK      pr_LPNs_Action_BulkMove, pr_LPNs_BulkMove & pr_LPNs_ShipMultiple:
  2021/06/02  VS      pr_LPNs_Action_BulkMove: Added validation to Don't move Picklane Logical LPNs (HA-2844)
  2021/04/15  OK      pr_LPNs_Action_BulkMove: Bug fix to get the proper records into the hash table to process (HA-2535)
                      pr_LPNs_Action_BulkMove: Changes to update New Warehouse (HA-1307)
  2020/07/28  PK      pr_LPNs_Action_BulkMove: Removed In-Transit status to allow bulk move of In-transit status LPNs (HA-1246).
  2020/07/26  TK      pr_LPNs_Action_BulkMove, pr_LPNs_BulkMove & pr_LPNs_TransferLPNContentsToPicklane:
  2020/07/21  TK      pr_LPNs_Action_BulkMove & pr_LPNs_Action_PalletizeLPNs: Changes to update ReasonCode & Reference on LPNs
  2020/07/13  TK      pr_LPNs_Action_BulkMove & pr_LPNs_BulkMove: Initial Revision (HA-1115)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Action_BulkMove') is not null
  drop Procedure pr_LPNs_Action_BulkMove;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Action_BulkMove: This proc moves the selected LPNs to the location selected
    but if no location selected then system will try to identify the destination locationusing rules
    and moves LPNs

  LPNs that are palletized are bound together, the user may or may not have selected all the LPNs
  on the Pallet. So, we have several ways to deal with moving of such LPNs. We could move the entire pallet
  or exclude the pallet or move the LPNs off the Pallet into the selected Location etc.
  @PalletizedLPNs determines how we handle them and the options are
  KeepTogether     - Means all the LPNs on a Pallet are to be together, we either
                     move them all or do not move them at all
  MoveSelectedLPNs - if the selected LPNs have to be moved, then they have to be removed off the Pallet
  Skip             - if some LPNs of a Pallet are selected, then skip those LPNs
  We currently always default to KeepTogether
/------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Action_BulkMove
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,

          @vEntity                  TEntity,
          @vAction                  TAction,
          @NewLocation              TLocation,
          @ReasonCode               TReasonCode,
          @Reference                TReference,

          @vNewLocationId           TRecordId,
          @vNewLocation             TLocation,
          @vNewLocationType         TTypeCode,
          @vNewStorageType          TTypeCode,
          @vNewLocWarehouse         TWarehouse,

          @vSelectedLPNsCount       TCount,
          @vLPNsMoved               TCount,
          @vPalletizedLPNs          TControlValue,

          @XMLRulesData             TXML;
  declare @ttLPNsToMove             TInventoryTransfer;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vPalletizedLPNs = 'KeepTogether';

  /* Create temp tables */
  select * into #LPNsToMove from @ttLPNsToMove;

  /* Read input XML */
  select @vEntity     = Record.Col.value('Entity[1]',             'TEntity'),
         @vAction     = Record.Col.value('Action[1]',             'TAction'),
         @NewLocation = Record.Col.value('(Data/Location)[1]',    'TLocation'),
         @ReasonCode  = Record.Col.value('(Data/ReasonCode)[1]',  'TReasonCode'),
         @Reference   = Record.Col.value('(Data/Reference)[1]',   'TReference')
  from @xmlData.nodes('/Root') as Record(Col)
  option(optimize for(@xmlData = null));

  /* Get all the selected LPNs */
  insert into #LPNsToMove (LPNId, LPN, PalletId, Pallet, ProcessFlag)
    select EntityId, EntityKey, L.PalletId, L.Pallet, 'N' /* No */
    from #ttSelectedEntities SE
      join LPNs L on (SE.EntityId = L.LPNId);

  /* If user selected LPNs which are on pallet, then load all LPNs that are on pallet
     even if user didn't select all LPNs on pallet. We can only move all LPNs on pallet */
  if (@vPalletizedLPNs = 'KeepTogether')
    insert into #LPNsToMove (LPNId, LPN, PalletId, Pallet, ProcessFlag)
      select distinct L.LPNId, L.LPN, L.PalletId, L.Pallet, 'N' /* No */
      from #LPNsToMove LTM
        join LPNs L on (LTM.PalletId = L.PalletId)
      where L.LPNId not in (select LPNId from #LPNsToMove);
      /* in case any performance issue reported while Bulk moving the LPNs, then comment above where clause
         and uncomment below except statement which filters the required data */
  --except
  --select LPNId, LPN, PalletId, Pallet, 'N' from #LPNsToMove

  /* Get the Location info */
  if (@NewLocation is not null)
    select @vNewLocationId   = LocationId,
           @vNewLocation     = Location,
           @vNewLocationType = LocationType,
           @vNewStorageType  = StorageType,
           @vNewLocWarehouse = Warehouse
    from Locations
    where (Location = @NewLocation) and (BusinessUnit = @BusinessUnit);

  /* Build XML rules data */
  select @XMLRulesData =  dbo.fn_XMLNode('Root',
                            dbo.fn_XMLNode('NewLocationId', @vNewLocationId) +
                            dbo.fn_XMLNode('NewLocation',   @vNewLocation) +
                            dbo.fn_XMLNode('BusinessUnit',  @BusinessUnit));

  /* if user selected a location then move all the LPNs to that location */
  if (@vNewLocationId is not null)
    begin
      update LTM
      set LPNType         = L.LPNType,
          LPNStatus       = L.Status,
          LPNOnhandStatus = L.OnhandStatus,
          LocationId      = L.LocationId,
          Location        = L.Location,
          Warehouse       = L.DestWarehouse,
          NewLocationId   = @vNewLocationId,
          NewLocation     = @vNewLocation,
          NewLocationType = @vNewLocationType,
          NewStorageType  = @vNewStorageType,
          NewWarehouse    = @vNewLocWarehouse
      from #LPNsToMove LTM
        join LPNs L on (LTM.LPNId = L.LPNId);
    end
  else
    /* If no location selected then evaluate rules to identify the location to move LPNs */
    exec pr_RuleSets_ExecuteRules 'LPNsBulkMove_UpdateDestLocation', @XMLRulesData;

  /* Validations */
  /* Check in there is a location defined to move LPN */
  update LTM
  set ProcessFlag = 'I' /* Ignore */
  output 'E', inserted.LPNId, inserted.LPN, 'MoveLPNs_LocationUndefined'
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from #LPNsToMove LTM
  where (NewLocationId is null);

  /* NewCarton, Voided, Consumed, Lost, Picking, Packing & Loaded LPNs cannot be moved */
  update LTM
  set ProcessFlag = 'I' /* Ignore */
  output 'E', inserted.LPNId, inserted.LPN, 'MoveLPNs_LPNStatusInvalid'
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from #LPNsToMove LTM
  where (dbo.fn_IsInList(LPNStatus, 'FVCOUGL') > 0)

  /* Received LPNs can only be moved to Reserve, Bulk, Staging, Dock & Conveyer locations */
  update LTM
  set ProcessFlag = 'I' /* Ignore */
  output 'E', inserted.LPNId, inserted.LPN, 'MoveLPNs_ReceivedLPNsCanBeMovedToRBSDCLocsOnly'
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from #LPNsToMove LTM
  where (LPNStatus = 'R' /* Received */) and
        (dbo.fn_IsInList(NewLocationType, 'RBSDC') = 0);

  /* Picked, Packed & Staged LPNs can only be moved to Staging, Dock & Conveyer locations */
  update LTM
  set ProcessFlag = 'I' /* Ignore */
  output 'E', inserted.LPNId, inserted.LPN, 'MoveLPNs_PickedLPNsCanBeMovedToSDCLocsOnly'
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from #LPNsToMove LTM
  where (dbo.fn_IsInList(LPNStatus, 'KDE') > 0) and
        (dbo.fn_IsInList(NewLocationType, 'SDC') = 0);

  /* Allocated LPNs cannot be moved as there may be pick tasks assigned to them */
  update LTM
  set ProcessFlag = 'I' /* Ignore */
  output 'E', inserted.LPNId, inserted.LPN, 'MoveLPNs_AllocatedLPNsCannotBeMoved'
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from #LPNsToMove LTM
  where (LPNStatus = 'A');

  /* Picklane Logical LPNs cannot be moved as there may be pick tasks assigned to them */
  update LTM
  set ProcessFlag = 'I' /* Ignore */
  output 'E', inserted.LPNId, inserted.LPN, 'MoveLPNs_LogicalLPNsCannotBeMoved'
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from #LPNsToMove LTM
  where (LPNType = 'L' /* Logical */);

  /* Check if there are any custom validations */
  exec pr_RuleSets_ExecuteRules 'LPNsBulkMove_Validations', @XMLRulesData;

  /* Check if any of the LPN on pallet is ignored above, if ignored then ignore all other LPNs on pallet */
  if (@vPalletizedLPNs = 'KeepTogether')
    update LTM
    set ProcessFlag = 'I' /* Ignore */
    output 'E', inserted.LPNId, inserted.LPN, 'MoveLPNs_OneOrMoreLPNsOnPalletDoesNotConform', inserted.Pallet
      into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2)
    from #LPNsToMove LTM
    where (PalletId in (select distinct PalletId from #LPNsToMove where ProcessFlag = 'I' /* Ignore */)) and
          (ProcessFlag <> 'I' /* Ignore */);

  /* Invoke procedure that move all the selected LPNs to New location */
  exec pr_LPNs_BulkMove default /* Operation */, @BusinessUnit, @UserId, @ReasonCode, @Reference;

  /* Update ReasonCode & Reference on the LPNs that are successfully moved */
  update L
  set ReasonCode = @ReasonCode,
      Reference  = @Reference
  from LPNs L
    join #LPNsToMove LTM on (L.LPNId = LTM.LPNId)
  where (LTM.ProcessFlag = 'Y' /* Yes */);

  /* Get the LPNs count that are successfully moved */
  select @vSelectedLPNsCount = count(*),
         @vLPNsMoved         = sum(case when ProcessFlag = 'Y' /* Yes */ then 1 else 0 end)
  from #LPNsToMove;

  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vLPNsMoved, @vSelectedLPNsCount;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Action_BulkMove */

Go
