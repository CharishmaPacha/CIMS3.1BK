/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/16  KBB     pr_Loads_Action_Modify: Initial Revision
  2021/05/27  AY      pr_Loads_Action_ModifyApptDetails: Allow to setup Dock Location (HA-2835)
  2021/05/24  AY      pr_Loads_Action_ModifyApptDetails: Abilty to clear CheckIn/Out times (HA Support)
  2021/03/31  KBB     pr_Loads_Action_ModifyBoLInfo: Added BoLStatus (HA-2467)
  2021/03/05  SJ      pr_Loads_Action_ModifyApptDetails: Giving provision to change CarrierCheckIn, CarrierCheckOut (HA-2137)
  2021/02/22  AY      pr_Loads_Action_ModifyBoLInfo: Save the Consolidator Address on Master BoL (HA-2042)
  2021/01/20  PK      pr_Load_GenerateBoLs, pr_Loads_Action_ModifyBoLInfo, pr_Load_Recount: Ported back changes are done by Pavan (HA-1749) (Ported from Prod)
  2020/09/21  SAK     pr_Loads_Action_ModifyApptDetails: Does not allow to update the App Details on the Shipped and canceled loads (HA-1366)
  2020/07/19  OK      Added pr_Loads_Action_ModifyApptDetails and pr_Loads_Action_ModifyBoLInfo (HA-1146, HA-1147)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_Action_Modify') is not null
  drop Procedure pr_Loads_Action_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_Action_Modify: This procedure used to Modify the selected
    Loads
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_Action_Modify
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vMessage                  TDescription,
          @vRecordId                 TRecordId,
          /* Audit & Response */
          @vAuditActivity            TActivityType,
          @ttAuditTrailInfo          TAuditTrailInfo,
          @ttAuditEntities           TEntityKeysTable,
          @vAuditRecordId            TRecordId,
          @vRecordsUpdated           TCount,
          @vTotalRecords             TCount,
          /* Input variables */
          @vEntity                   TEntity,
          @vAction                   TAction,
          /* Load Info */
          @vLoadId                   TLoadId,
          @vLoadNumber               TLoadNumber,
          @vLoadStatus               TStatus,
          @vStatus                   TStatus,
          @vRoutingStatus            TStatus,
          @vLoadShipVia              TShipVia,
          @vConsolidatorAddressId    TContactRefId,
          @vShipViaCarrier           TCarrier,
          @vLoadType                 TTypeCode,
          @vFromWarehouse            TWarehouse,
          @vShipFrom                 TShipFrom,
          @vShipToId                 TShipToId,
          @vShipVia                  TShipVia,
          @vDesiredShipDate          TDateTime,
          @vShippedDate              TDateTime,
          @vTrailerNumber            TTrailerNumber   = null,
          @vSealNumber               TSealNumber,
          @vProNumber                TProNumber       = null,
          @vDockLocation             TLocation,
          @vStagingLocation          TLocation        = null,
          @vLoadingMethod            TTypeCode        = null,
          @vPalletized               TFlags           = null,
          @vVolume                   TVolume          = null,
          @vWeight                   TWeight          = null,
          @vFreightCharges           TMoney           = null,
          @vClientLoad               TLoadNumber,
          /* BoL Info */
          @vMasterBoL                TBoLNumber,
          @vMasterShipToId           TRecordId,
          @vAssignDockForMultipleLoads
                                     TFlags,
          /* Process variables */
          @vAppointmentConfirmation  TDescription,
          @vFoB                      TFlags,
          @vBoLCID                   TBoLCID,
          @vAppointmentDate          TDateTime,
          @vDeliveryRequestType      TLookupCode,
          @vTransitDays              TCount,
          @vDeliveryDate             TDateTime,
          @vMasterTrackingNo         TTrackingNo,
          @vNote1                    TDescription,
          @vPriority                 TPriority;

begin /* pr_Loads_Action_Modify */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = 'AT_LoadModified';

  select @vEntity            = Record.Col.value('Entity[1]',                     'TEntity'),
         @vAction            = Record.Col.value('Action[1]',                     'TAction'),
         @vLoadId            = Record.Col.value('(Data/LoadId)[1]',              'TRecordId'),
         @vLoadType          = Record.Col.value('(Data/LoadType)[1]',            'TTypeCode'),
         @vFromWarehouse     = Record.Col.value('(Data/FromWarehouse)[1]',       'TWarehouse'),
         @vShipFrom          = Record.Col.value('(Data/ShipFrom)[1]',            'TShipFrom'),
         @vShipVia           = Record.Col.value('(Data/ShipVia)[1]',             'TShipVia'),
         @vRoutingStatus     = Record.Col.value('(Data/RoutingStatus)[1]',       'TStatus'),
         @vDesiredShipDate   = Record.Col.value('(Data/DesiredShipDate)[1]',     'TDateTime'),
         @vShippedDate       = Record.Col.value('(Data/ShippedDate)[1]',         'TDateTime'),
         @vPRONumber         = Record.Col.value('(Data/PRONumber)[1]',           'TProNumber'),
         @vTrailerNumber     = Record.Col.value('(Data/TrailerNumber)[1]',       'TTrailerNumber'),
         @vSealNumber        = Record.Col.value('(Data/SealNumber)[1]',          'TSealNumber'),
         @vDockLocation      = Record.Col.value('(Data/DockLocation)[1]',        'TLocation'),
         @vStagingLocation   = Record.Col.value('(Data/StagingLocation)[1]',     'TLocation'),
         @vLoadingMethod     = Record.Col.value('(Data/LoadingMethod)[1]',       'TTypeCode'),
         @vPalletized        = Record.Col.value('(Data/Palletized)[1]',          'TFlags'),
         @vWeight            = Record.Col.value('(Data/Weight)[1]',              'TWeight'),
         @vVolume            = Record.Col.value('(Data/Volume)[1]',              'TVolume'),
         @vClientLoad        = Record.Col.value('(Data/ClientLoad)[1]',          'TLoadNumber'),
         @vFreightCharges    = Record.Col.value('(Data/FreightCharges)[1]',      'TMoney')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vAssignDockForMultipleLoads = dbo.fn_Controls_GetAsString('Load', 'AssignDockForMultipleLoads', 'Y' /* Yes */, @BusinessUnit, @UserId);

  /* Get the total count of Loads from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Basic Validations */
  if (@BusinessUnit is null)
    select @vMessageName = 'BusinessUnitIsInvalid';
  else
  /* Check if MasterBoL is used by any other Load */
  if (exists (select * from Loads
              where (MasterBoL = @vMasterBoL) and (LoadId <> @vLoadId)))
    select @vMessageName = 'Load_BoLNumberAlreadyExists';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get more info of the selected Loads and validate as much as we can */
  select L.LoadId, L.LoadNumber, L.LoadStatusDesc, L.DockLocation,
  case when (dbo.fn_IsInList(L.LoadStatus, 'SX,SI') > 0)  then 'Load_Modify_InvalidStatus'
       when (LoadStatus = 'N') and (@vRoutingStatus = 'C') then 'Load_Modify_CannotConfirmRouting'
  end ErrorMessage
  into #SelectedLoads
  from #ttSelectedEntities ttSE
    join vwLoads L on (ttSE.EntityId = L.LoadId);

  /* Delete the Loads that have errors */
  delete SE
  output 'E', SL.ErrorMessage, SL.LoadId, SL.LoadNumber, SL.LoadStatusDesc
  into #ResultMessages (MessageType, MessageName, EntityId, EntityKey, Value2)
  from #ttSelectedEntities SE
    join #SelectedLoads SL on (SE.EntityId = SL.LoadId)
  where (SL.ErrorMessage is not null);

  /* Check if there are any other active Loads using same Dock */
  delete ttSE
  output 'E', 'CannotAssignMultipleLoadsForDock', L.LoadNumber
  into #ResultMessages (MessageType, MessageName, Value1)
  from #ttSelectedEntities ttSE
    join Loads L on (ttSE.EntityId = L.LoadId)
  where (Status not in ('S', 'X' /* Shipped,Canceled */)) and
        (DockLocation = coalesce(@vDockLocation, '')) and
        (L.LoadId <> ttSE.EntityId)

  /* check if shipping to consolidator, if so, set the ConsolidatorAddress */
  if (@vShipVia is not null)
    begin
      select @vConsolidatorAddressId = case when (ServiceClass = 'CON' /* Consolidator */) then 'FC-' + ShipVia else null end,
             @vShipViaCarrier        = Carrier
      from ShipVias
      where (Shipvia      = @vShipVia) and
            (BusinessUnit = @BusinessUnit);

      /* If ShipVia is 'LTL' then update new ship via on corresponding shipments */
      if (@vShipViaCarrier = 'LTL')
        update S
        set ShipVia = @vShipVia
        from Shipments S
        where (LoadId = @vLoadId) and
              (ShipVia <> @vShipVia);

      /* If Load is being shipped to a consolidator and there is a Master BoL, then update Master BoL */
      if (@vConsolidatorAddressId is not null)
        begin
          select @vMasterShipToId = ContactId
          from Contacts
          where (ContactType = 'FC') and (ContactRefId = @vConsolidatorAddressId) and (BusinessUnit = @BusinessUnit);

          update BoLs
          set ShipToAddressid = @vMasterShipToId
          where (LoadId = @vLoadId) and (BoLType = 'M' /* Master */);
        end
    end

  /* Perform the actual updates */
  update L
  set LoadType                = coalesce(@vLoadType,                LoadType),
      Status                  = coalesce(@vStatus,                  Status),
      RoutingStatus           = coalesce(@vRoutingStatus,           RoutingStatus),
      FromWarehouse           = coalesce(@vFromWarehouse,           FromWarehouse),
      ShipFrom                = coalesce(@vShipFrom,                ShipFrom),
      ShipToId                = coalesce(@vShipToId,                ShipToId),
      DockLocation            = @vDockLocation,
      StagingLocation         = coalesce(@vStagingLocation,         StagingLocation),
      LoadingMethod           = coalesce(@vLoadingMethod,           LoadingMethod),
      Palletized              = coalesce(@vPalletized,              Palletized),
      ShipVia                 = coalesce(@vShipVia,                 ShipVia),
      DesiredShipDate         = coalesce(@vDesiredShipDate,         DesiredShipDate),
      ShippedDate             = coalesce(@vShippedDate,             ShippedDate),
      Priority                = coalesce(@vPriority,                Priority),
      TrailerNumber           = coalesce(@vTrailerNumber,           TrailerNumber),
      SealNumber              = coalesce(@vSealNumber,              SealNumber),
      PRONumber               = coalesce(@vPRONumber,               PRONumber),
      MasterTrackingNo        = trim(coalesce(@vMasterTrackingNo,   MasterTrackingNo)),
      DeliveryDate            = coalesce(@vDeliveryDate,            DeliveryDate),
      TransitDays             = coalesce(@vTransitDays,             TransitDays),
      Volume                  = coalesce(@vVolume,                  Volume),
      Weight                  = coalesce(@vWeight,                  Weight),
      AppointmentConfirmation = coalesce(@vAppointmentConfirmation, AppointmentConfirmation),
      AppointmentDateTime     = coalesce(@vAppointmentDate,         AppointmentDateTime),
      DeliveryRequestType     = coalesce(@vDeliveryRequestType,     DeliveryRequestType),
      FreightCharges          = coalesce(@vFreightCharges,          FreightCharges),
      ClientLoad              = coalesce(@vClientLoad,              ClientLoad),
      MasterBoL               = coalesce(@vMasterBoL,               MasterBoL),
      FoB                     = coalesce(@vFoB,                     FoB),
      BoLCID                  = coalesce(@vBoLCID,                  BoLCID, @vClientLoad),
      ConsolidatorAddressId   = coalesce(@vConsolidatorAddressId,   ConsolidatorAddressId),
      ModifiedDate            = current_timestamp,
      ModifiedBy              = coalesce(@UserId,                   System_user)
  from Loads L
    join #ttSelectedEntities ttSE on L.LoadId = ttSE.EntityId

  select @vRecordsUpdated = @@rowcount;

  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'FromWarehouse',   @vFromWarehouse);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'ShipVia',         @vShipVia);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'PRONumber',       @vPRONumber);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'TrailerNumber',   @vTrailerNumber);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'SealNumber',      @vSealNumber);
  select @vNote1 = '(' + @vNote1 + ')';

   /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select distinct 'Load', EntityId, EntityKey, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, EntityKey, @vNote1, null, null, null) /* Comment */
    from #ttSelectedEntities;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_Action_Modify */

Go
