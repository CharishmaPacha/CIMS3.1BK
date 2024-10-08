/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/20  AY      pr_Load_CreateNew: Validate Dock & Staging Locations (HA-1361)
  2020/07/10  RKC     pr_Load_CreateNew, pr_Load_Update : Added StagingLocation, LoadingMethod, Palletized parameters
                      pr_Load_CreateNew, pr_Load_Update, pr_Load_Recount: changes for ShipFrom(CIMSV3-996)
  2020/06/15  RKC     pr_Load_Generate: Pass the missed parameter to pr_Load_CreateNew (HA-942)
  2020/06/11  RV      pr_Load_CreateNew: Changes to insert messages and result data into #tables to show in V3 (HA-840)
  2019/10/31  MJ      pr_Load_CreateNew,pr_Load_Update :Made changes to update AppointmentConfirmation, AppointmentDate, DeliveryRequestType (S2GCA-1018)
  2019/07/23  AJ      pr_Load_CreateNew, pr_Load_Update: Changes to Add/Edit MasterTrackingNo (CID-843)
  2019/07/10  YJ      pr_Load_CreateNew, pr_Load_Update: Changes to Add/Edit FreightCharges (CID-749)
  2018/05/21  TK      pr_Load_CreateNew & pr_Load_Update:
  2016/07/26  AY      pr_Load_CreateNew: Make all input params optional (HPI-353)
  2016/01/05  SV      pr_Load_CreateNew, pr_Load_AddOrder, pr_Load_RemoveOrders,
                      pr_Load_CreateNew: Added PickBatchGroup field (FB-350)
  2012/10/29  PKS     pr_Load_CreateNew: Routing status set to 'Not Required' as default value.
  2012/10/23  PKS     pr_Load_CreateNew: BolNumber was updated with default value if it is null.
  2012/09/13  VM      pr_Load_CreateNew: send LoadNumber as second param to build message properly for Load_Generation_Successful
              VM      pr_Load_CreateNew: Update UDF1 as well (Order PickBatchGroup -> OrderGroup)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_CreateNew') is not null
  drop Procedure pr_Load_CreateNew;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_CreateNew:
       Procedure creates a New Load Record in Loads Table, with the given Input
         values for LoadType, ShipVia, Desired Ship Date
------------------------------------------------------------------------------*/
Create Procedure pr_Load_CreateNew
  (@UserId                  TUserId         = null,
   @BusinessUnit            TBusinessUnit   = null,
   @LoadType                TTypeCode       = 'MULTIDROP',
   @RoutingStatus           TStatus         = null,
   @ShipVia                 TShipvia        = null,
   @DesiredShipDate         TDateTime       = null,
   @FromWarehouse           TWarehouse      = null,
   @ShipFrom                TShipFrom       = null,
   @ShipToId                TShipToId       = null,
   @DockLocation            TLocation       = null,
   @StagingLocation         TLocation       = null,
   @LoadingMethod           TTypeCode       = null,
   @Palletized              TFlags          = null,
   @DeliveryDate            TDateTime       = null,
   @Weight                  TWeight         = null,
   @Volume                  TVolume         = null,
   @AppointmentConfirmation TDescription    = null,
   @AppointmentDate         TDateTime       = null,
   @DeliveryRequestType     TLookupCode     = null,
   @FreightCharges          TMoney          = null,
   @Priority                TPriority       = null,
   @TransitDays             TCount          = null,
   @ProNumber               TProNumber      = null,
   @SealNumber              TSealNumber     = null,
   @TrailerNumber           TTrailerNumber  = null,
   @MasterTrackingNo        TTrackingNo     = null,
   @ClientLoad              TLoadNumber     = null,
   @MasterBoL               TBoLNumber      = null,
   @ShippedDate             TDateTime       = null,
   @PickBatchGroup          TWaveGroup      = null,
   @FoB                     TFlags          = null,
   @BoLCID                  TBoLCID         = null,
   @UDF1                    TUDF            = null,
   @UDF2                    TUDF            = null,
   @UDF3                    TUDF            = null,
   @UDF4                    TUDF            = null,
   @UDF5                    TUDF            = null,
   @UDF6                    TUDF            = null,
   @UDF7                    TUDF            = null,
   @UDF8                    TUDF            = null,
   @UDF9                    TUDF            = null,
   @UDF10                   TUDF            = null,
   -------------------------------------------------------
   @LoadId                  TLoadId         = null output,
   @LoadNumber              TLoadNumber     = null output,
   @Message                 TDescription    = null output)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,

          /* ShipVia Info */
          @vShipVia                     TShipVia,
          @vCarrier                     TCarrier,
          @vIsSmallPackageCarrier       TFlag,
          /* Shipment Info */
          @vShipmentId                  TShipmentId,
          @vLoadId                      TLoadId,
          @vLoadNumber                  TLoadNumber,
          @vUDF2                        TUDF,
          @vCreatedDate                 TDateTime,
          @vPalletized                  TFlags,
          @vAssignDockForMultipleLoads  TFlags,
          @vLoadAlreadyUsingDock        TLoadNumber,
          @vNote1                       TMessage,
          @vNote2                       TMessage;

begin /* pr_Load_CreateNew */
  select @vReturnCode     = 0,
         @vMessagename    = null,
         @LoadType        = coalesce(@LoadType, 'MULTIDROP'), /* Load Type will mostly be given as Input */
         @vCreatedDate    = current_timestamp,
         @DockLocation    = nullif(@DockLocation, ''),
         @StagingLocation = nullif(@StagingLocation, '');

  select @vAssignDockForMultipleLoads = dbo.fn_Controls_GetAsString('Load', 'AssignDockForMultipleLoads',  'Y' /* Yes */, @BusinessUnit, @UserId);

  select @vLoadNumber = LoadNumber,
         @vLoadId     = LoadId
  from Loads
  where (LoadId       = @LoadId) and
        (BusinessUnit = @BusinessUnit);

  /* A Load already exists with the LoadId value */
  if (@vLoadId is not null)
    goto ExitHandler;

  /* Get the Palletized based on Carrier */
  select @vCarrier               = Carrier,
         @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from ShipVias
  where (ShipVia      = @ShipVia) and
        (BusinessUnit = @BusinessUnit);

  /* If not specified, default based upon Carrier */
  set @vPalletized = coalesce(@Palletized, case when @vIsSmallPackageCarrier = 'Y' then 'N' else 'Y' end);

  /* Check if there is already another Load using given Dock Location */
  if (@DockLocation is not null)
    select @vLoadAlreadyUsingDock = LoadNumber
    from Loads
    where (Status not in ('S', 'X' /* Shipped,Canceled */)) and
          (DockLocation = @DockLocation) and
          (BusinessUnit = @BusinessUnit);

  /* Validations */
  if (@vAssignDockForMultipleLoads = 'N'/* No */) and
     (@vLoadAlreadyUsingDock is not null)
    select @vMessageName = 'CannotAssignMultipleLoadsForDock', @vNote1 = @vLoadAlreadyUsingDock, @vNote2 = @DockLocation;
  else
  if (@DockLocation is not null) and
     (not exists (select * from Locations where Location = @DockLocation and BusinessUnit = @BusinessUnit))
    select @vMessageName = 'LoadCreate_DockLocationInvalid';
  else
  if (@DockLocation is not null) and
     ((select LocationType from Locations where Location = @DockLocation and BusinessUnit = @BusinessUnit) <> 'D')
    select @vMessageName = 'LoadCreate_DockLocationInvalidType';
  else
  if (@StagingLocation is not null) and
     (not exists (select * from Locations where Location = @StagingLocation and BusinessUnit = @BusinessUnit))
    select @vMessageName = 'LoadCreate_StagingLocationInvalid';
  else
  if (@StagingLocation is not null) and
     ((select LocationType from Locations where Location = @StagingLocation and BusinessUnit = @BusinessUnit) <> 'S')
    select @vMessageName = 'LoadCreate_StagingLocationInvalidType'

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vNote1, @vNote2;

  /* Create new Load record */
  exec pr_Load_GetNextSeqNo @BusinessUnit, @ShipToId, @LoadNumber output;

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
            select @LoadNumber,
                   @LoadType,
                   @ShipVia,
                   'N', /* Not Required (Default) */
                   @DesiredShipDate,
                   @FromWarehouse,
                   @ShipFrom,
                   @ShipToId,
                   @DockLocation,
                   @StagingLocation,
                   @LoadingMethod,
                   @vPalletized,
                   @DeliveryDate,
                   @Weight,
                   @Volume,
                   @AppointmentConfirmation,
                   @AppointmentDate,
                   @DeliveryRequestType,
                   @FreightCharges,
                   @Priority,
                   @TransitDays,
                   @ProNumber,
                   @SealNumber,
                   @TrailerNumber,
                   @MasterTrackingNo,
                   @ClientLoad,
                   @MasterBoL,
                   @ShippedDate,
                   @PickBatchGroup,
                   @FoB,
                   coalesce(@BoLCID, @ClientLoad),
                   @BusinessUnit,
                   @vCreatedDate,
                   coalesce(@UserId, system_user);

  /* Save id of the record just created */
  set @LoadId = Scope_Identity();

   /* Build the message here..*/
  exec @Message = dbo.fn_Messages_Build 'Load_Generation_Successful', default, @LoadNumber;

  /* Inserted the messages information to display in V3 application */
  if (object_id('tempdb..#ResultMessages') is not null)
    insert into #ResultMessages (MessageType, MessageText) select 'I' /* Info */, @Message;

    /* Inserted the messages information to display in V3 application */
  if (object_id('tempdb..#ResultData') is not null)
    insert into #ResultData (FieldName, FieldValue)
            select 'LoadId',     cast(@LoadId as varchar(100))
      union select 'LoadNumber', @LoadNumber

  /* Auditing */
  exec pr_AuditTrail_Insert 'LoadCreated', @UserId, @vCreatedDate,
                            @LoadId       = @LoadId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Load_CreateNew */

Go
