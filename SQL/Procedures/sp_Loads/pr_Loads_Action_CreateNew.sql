/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/24  SV      pr_Loads_Action_CreateNew: Added the new action procedure (CIMSV3-1517)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_Action_CreateNew') is not null
  drop Procedure pr_Loads_Action_CreateNew;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_Action_CreateNew:
       Procedure creates a New Load Record in Loads Table, with the given Input
         values for LoadType, ShipVia, Desired Ship Date.
  Following is the I/P structure for this proc.

<Root>
  <Entity>Load</Entity>
  <Action>ManageLoads_CreateLoad</Action>
  <SelectionFilters>
    <Filter>
      <FilterOperationEnumCode>12</FilterOperationEnumCode>
      <FilterType>D</FilterType>
      <FieldName>CreatedBy</FieldName>
      <FilterOperation>NotEquals</FilterOperation>
      <FilterValue>cIMSAgent</FilterValue>
      <FilterDescription>Created By does not equal cIMSAgent</FilterDescription>
      <Visible>Y</Visible>
    </Filter>
  </SelectionFilters>
  <GridFilters />
  <MasterSelectionFilters />
  <Data>
    <ShipVia>FDE112</ShipVia>
    <DesiredShipDate>2021-06-20</DesiredShipDate>
    <TrailerNumber>1</TrailerNumber>
    <FromWarehouse>01</FromWarehouse>
    <Palletized>N</Palletized>
    <RoutingStatus>P</RoutingStatus>
    <LoadType>Transfer</LoadType>
    <ShipFrom>01</ShipFrom>
    <StagingLocation>SHIP-04</StagingLocation>
    <DockLocation>Shippingdock1</DockLocation>
    <ShippedDate>2021-06-20</ShippedDate>
    <LoadingMethod>RF</LoadingMethod>
    <Volume>0.0001</Volume>
  </Data>
  <SessionInfo>
    <UserId>cimsadmin</UserId>
    <BusinessUnit>HA</BusinessUnit>
    <DeviceId>PC0000000128</DeviceId>
    <DeviceName>PC0000000128</DeviceName>
    <UserFilter_Warehouse>*</UserFilter_Warehouse>
  </SessionInfo>
</Root>
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_Action_CreateNew
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML  = null output)
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
          @vLoadType                   TTypeCode,
          @vRoutingStatus              TStatus,
          @vShipVia                    TShipvia,
          @vDesiredShipDate            TDateTime,
          @vFromWarehouse              TWarehouse,
          @vShipFrom                   TShipFrom,
          @vShipToId                   TShipToId,
          @vDockLocation               TLocation,
          @vStagingLocation            TLocation,
          @vLoadingMethod              TTypeCode,
          @vPalletized                 TFlags,
          @vDeliveryDate               TDateTime,
          @vWeight                     TWeight,
          @vVolume                     TVolume,
          @vAppointmentConfirmation    TDescription,
          @vAppointmentDate            TDateTime,
          @vDeliveryRequestType        TLookupCode,
          @vFreightCharges             TMoney,
          @vPriority                   TPriority,
          @vTransitDays                TCount,
          @vProNumber                  TProNumber,
          @vSealNumber                 TSealNumber,
          @vTrailerNumber              TTrailerNumber,
          @vMasterTrackingNo           TTrackingNo,
          @vClientLoad                 TLoadNumber,
          @vMasterBoL                  TBoLNumber,
          @vShippedDate                TDateTime,
          @vPickBatchGroup             TWaveGroup,
          @vFoB                        TFlags,
          @vBoLCID                     TBoLCID,
          @vUDF1                       TUDF,
          @vUDF2                       TUDF,
          @vUDF3                       TUDF,
          @vUDF4                       TUDF,
          @vUDF5                       TUDF,
          @vUDF6                       TUDF,
          @vUDF7                       TUDF,
          @vUDF8                       TUDF,
          @vUDF9                       TUDF,
          @vUDF10                      TUDF,
          @vLoadId                     TLoadId,
          @vLoadNumber                 TLoadNumber,
          /* Process variables */
          @vDockLocationId             TRecordId,
          @vDockLocationType           TTypeCode,
          @vStagingLocationId          TRecordId,
          @vStagingLocationType        TTypeCode,
          /* ShipVia Info */
          @vCarrier                    TCarrier,
          @vIsSmallPackageCarrier      TFlag,
          @vCreatedDate                TDateTime,
          @vAssignDockForMultipleLoads TFlags,
          @vLoadAlreadyUsingDock       TLoadNumber,
          @vNote1                      TMessage,
          @vNote2                      TMessage;

begin /* pr_Loads_Action_CreateNew */

  select @vReturnCode  = 0,
         @vMessagename = null,
         @vCreatedDate = current_timestamp;

  /* Read inputs from XML */
  select @vLoadType                 = Record.Col.value('LoadType[1]',                 'TTypeCode'),
         @vShipVia                  = Record.Col.value('ShipVia[1]',                  'TShipVia'),
         @vDesiredShipDate          = Record.Col.value('DesiredShipDate[1]',          'TDateTime'),
         @vFromWarehouse            = Record.Col.value('FromWarehouse[1]',            'TWarehouse'),
         @vShipFrom                 = Record.Col.value('ShipFrom[1]',                 'TShipFrom'),
         @vShipToId                 = Record.Col.value('ShipToId[1]',                 'TShipToId'),
         @vDockLocation             = Record.Col.value('DockLocation[1]',             'TLocation'),
         @vStagingLocation          = Record.Col.value('StagingLocation[1]',          'TLocation'),
         @vLoadingMethod            = Record.Col.value('LoadingMethod[1]',            'TTypeCode'),
         @vPalletized               = Record.Col.value('Palletized[1]',               'TFlags'),
         @vWeight                   = Record.Col.value('Weight[1]',                   'TWeight'),
         @vVolume                   = Record.Col.value('Volume[1]',                   'TVolume'),
         @vRoutingStatus            = Record.Col.value('RoutingStatus[1]',            'TStatus'),
         @vAppointmentConfirmation  = Record.Col.value('AppointmentConfirmation[1]',  'TDescription'),
         @vAppointmentDate          = Record.Col.value('AppointmentDate[1]',          'TDateTime'),
         @vDeliveryDate             = Record.Col.value('DeliveryDate[1]',             'TDateTime'),
         @vDeliveryRequestType      = Record.Col.value('DeliveryRequestType[1]',      'TLookupCode'),
         @vTransitDays              = Record.Col.value('TransitDays[1]',              'TCount'),
         @vFreightCharges           = Record.Col.value('FreightCharges[1]',           'TMoney'),
         @vPriority                 = Record.Col.value('Priority[1]',                 'TPriority'),
         @vProNumber                = Record.Col.value('ProNumber[1]',                'TProNumber'),
         @vSealNumber               = Record.Col.value('SealNumber[1]',               'TSealNumber'),
         @vTrailerNumber            = Record.Col.value('TrailerNumber[1]',            'TTrailerNumber'),
         @vMasterTrackingNo         = Record.Col.value('MasterTrackingNo[1]',         'TTrackingNo'),
         @vClientLoad               = Record.Col.value('ClientLoad[1]',               'TLoadNumber'),
         @vMasterBoL                = Record.Col.value('MasterBoL[1]',                'TBoLNumber'),
         @vShippedDate              = Record.Col.value('ShippedDate[1]',              'TDateTime'),
         @vPickBatchGroup           = Record.Col.value('PickBatchGroup[1]',           'TWaveGroup'),
         @vFoB                      = Record.Col.value('FoB[1]',                      'TFlags'),
         @vBoLCID                   = Record.Col.value('BoLCID[1]',                   'TBoLCID'),
         @vUDF1                     = Record.Col.value('UDF1[1]',                     'TUDF'),
         @vUDF2                     = Record.Col.value('UDF2[1]',                     'TUDF'),
         @vUDF3                     = Record.Col.value('UDF3[1]',                     'TUDF'),
         @vUDF4                     = Record.Col.value('UDF4[1]',                     'TUDF'),
         @vUDF5                     = Record.Col.value('UDF5[1]',                     'TUDF'),
         @vUDF6                     = Record.Col.value('UDF6[1]',                     'TUDF'),
         @vUDF7                     = Record.Col.value('UDF7[1]',                     'TUDF'),
         @vUDF8                     = Record.Col.value('UDF8[1]',                     'TUDF'),
         @vUDF9                     = Record.Col.value('UDF9[1]',                     'TUDF'),
         @vUDF10                    = Record.Col.value('UDF10[1]',                    'TUDF'),
         @vLoadId                   = Record.Col.value('LoadId[1]',                   'TLoadId'),
         @vLoadNumber               = Record.Col.value('LoadNumber[1]',               'TLoadNumber')
  from @xmlData.nodes('/Root/Data') as Record(Col);

  select @vEntity       = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction       = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vLoadType        = coalesce(@vLoadType, 'MULTIDROP'), /* Load Type will mostly be given as Input */
         @vDockLocation    = nullif(@vDockLocation, ''),
         @vStagingLocation = nullif(@vStagingLocation, '');

  select @vAssignDockForMultipleLoads = dbo.fn_Controls_GetAsString('Load', 'AssignDockForMultipleLoads',  'Y' /* Yes */, @BusinessUnit, @UserId);

  /* Needed for selected DOCK location validation. */
  if (@vDockLocation is not null)
    select @vDockLocationId   = LocationId,
           @vDockLocationType = LocationType
    from Locations
    where (Location     = @vDockLocation) and
          (BusinessUnit = @BusinessUnit);

  /* Needed for Staging location validation. */
  if (@vStagingLocation is not null)
    select @vStagingLocationId   = LocationId,
           @vStagingLocationType = LocationType
    from Locations
    where (Location     = @vStagingLocation) and
          (BusinessUnit = @BusinessUnit);

  /* Get the Palletized based on Carrier */
  select @vCarrier               = Carrier,
         @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from ShipVias
  where (ShipVia      = @vShipVia) and
        (BusinessUnit = @BusinessUnit);

  /* If not specified, default based upon Carrier */
  set @vPalletized = coalesce(@vPalletized, case when @vIsSmallPackageCarrier = 'Y' then 'N' else 'Y' end);

  /* Check if there is already another Load using given Dock Location */
  if  (@vAssignDockForMultipleLoads = 'N'/* No */) and
      (@vDockLocation is not null)
    select @vLoadAlreadyUsingDock = LoadNumber
    from Loads
    where (Status not in ('S', 'X' /* Shipped,Canceled */)) and
          (DockLocation = @vDockLocation) and
          (BusinessUnit = @BusinessUnit);

  /* Validations */
  if (@vAssignDockForMultipleLoads = 'N'/* No */) and
     (@vLoadAlreadyUsingDock is not null)
    select @vMessageName = 'CannotAssignMultipleLoadsForDock', @vNote1 = @vLoadAlreadyUsingDock, @vNote2 = @vDockLocation;
  else
  if (@vDockLocationId is null)
    select @vMessageName = 'LoadCreate_DockLocationInvalid';
  else
  if (@vDockLocationType <> 'D')
    select @vMessageName = 'LoadCreate_DockLocationInvalidType';
  else
  if (@vStagingLocationId is null)
    select @vMessageName = 'LoadCreate_StagingLocationInvalid';
  else
  if (@vStagingLocationType <> 'S')
    select @vMessageName = 'LoadCreate_StagingLocationInvalidType'

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vNote1, @vNote2;

  /* Create new Load record */
  exec pr_Load_GetNextSeqNo @BusinessUnit, @vShipToId, @vLoadNumber output;

  insert into Loads(LoadNumber,
                    LoadType,
                    ShipVia,
                    RoutingStatus,
                    DesiredShipDate,
                    FromWarehouse,
                    ShipFrom,
                    ShipToId,
                    DockLocation,
                    StagingLocation,
                    LoadingMethod,
                    Palletized,
                    DeliveryDate,
                    Weight,
                    Volume,
                    AppointmentConfirmation,
                    AppointmentDateTime,
                    DeliveryRequestType,
                    FreightCharges,
                    Priority,
                    TransitDays,
                    ProNumber,
                    SealNumber,
                    TrailerNumber,
                    MasterTrackingNo,
                    ClientLoad,
                    MasterBoL,
                    ShippedDate,
                    LoadGroup,
                    FoB,
                    BoLCID,
                    BusinessUnit,
                    CreatedDate,
                    CreatedBy)
             select @vLoadNumber,
                    @vLoadType,
                    @vShipVia,
                    coalesce(@vRoutingStatus, 'N' /* Not Required (Default) */),
                    @vDesiredShipDate,
                    @vFromWarehouse,
                    @vShipFrom,
                    @vShipToId,
                    @vDockLocation,
                    @vStagingLocation,
                    @vLoadingMethod,
                    @vPalletized,
                    @vDeliveryDate,
                    @vWeight,
                    @vVolume,
                    @vAppointmentConfirmation,
                    @vAppointmentDate,
                    @vDeliveryRequestType,
                    @vFreightCharges,
                    @vPriority,
                    @vTransitDays,
                    @vProNumber,
                    @vSealNumber,
                    @vTrailerNumber,
                    @vMasterTrackingNo,
                    @vClientLoad,
                    @vMasterBoL,
                    @vShippedDate,
                    @vPickBatchGroup,
                    @vFoB,
                    coalesce(@vBoLCID, @vClientLoad),
                    @BusinessUnit,
                    @vCreatedDate,
                    coalesce(@UserId, system_user);

  /* Save id of the record just created */
  set @vLoadId = Scope_Identity();

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'LoadCreated', @UserId, @vCreatedDate, @LoadId = @vLoadId;

  /* Inserted the details so that the application can show the created Load */
  if (object_id('tempdb..#ResultData') is not null)
    insert into #ResultData (FieldName, FieldValue)
            select 'LoadId',     cast(@vLoadId as varchar(100))
      union select 'LoadNumber', @vLoadNumber

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, 1 /* RecordsUpdated */, 1 /* TotalRecords */, @vLoadNumber /* Value1 */;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_Action_CreateNew */

Go
