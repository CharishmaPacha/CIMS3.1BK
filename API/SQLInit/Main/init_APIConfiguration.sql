/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/10/30  RV      Added CIMSUPS2-TrackingInfo (BK-1148)
  2024/08/18  RV      Added CIMSFEDEX2-FEDEXTracking (BK-1132)
  2024/04/12  DEM     Added CIMSFEDEX2-AddressValidation (CIMSV3-3531)
  2024/02/12  RV      Added CIMSFEDEX2OAUTH-GenerateToken and CIMSFEDEX2-ShipmentRequest (CIMSV3-3397)
  2023/09/15  RV      Added CIMSUPSOAUTH2-CreateToken (MBW-495)
  2023/09/03  RV      Added CIMSUPSOAUTH2 and CIMSUPS2 (MBW-437)
  2022/01/07  RT      Added AddressValidation for UPS (CID-1904)
  2021/07/22  RV      CIMSUPS -> UPSTracking, ShipmentRequest: Changed Records per batch to 200 (BK-387)
  2021/05/20  RV      CIMSUPS-ShipmentRequest: Added new API configuration (CIMSV3-1453)
  2021/02/26  TK      Updated Stored procedure names for UPS & USPS tracking (BK-201)
  2021/11/15  RV      Added new CIMSUPS - Tracking and CIMSUSPS - Tracking integration (BK-157)
  2021/01/28  TK      Corrected procedure name for ContainerPickComplete (CID-1659)
  2021/01/19  TK      Message URL for MessageAcknowledgement (CID-1630)
  2020/11/24  TK      MessageUrls for ContainerPickComplete, ContainerValidation and ContainerTakenOff (CID-1566)
  2020/11/24  NB      changes to define StoredProcedureName and DataProcedureName for Outbound API Messages(CID-1576)
  2020/11/16  TK      MessageType for pick cancel actions (CID-1513)
  2020/11/19  NB      6RiverCIMS-PrintRequest..changed procedure to pr_API_6River_Inbound_PrintRequest(CID-1543)
  2020/11/16  TK      Different MessageTypes for different GroupUpdate actions (CID-1514)
  2020/11/16  TK      Defined procedures for different MessageTypes (CID-1498)
  2020/10/30  NB      InputDataType changes for Anetara API Caller(CID-1486)
  2020/10/21  NB      Added CIMS API UpdateEventRun, updated 6River API Details(CID-1486, CID-1481)
  2020/09/28  NB      Initial Revision(CID-1481)
------------------------------------------------------------------------------*/

Go

declare @IntegrationName          TName,
        @InputType                TName,
        @InputDataType            TName,
        @ProcessMode              TTypeCode,
        @ResponseType             TTypeCode,
        @BusinessUnit             TBusinessUnit;

/*------------------------------------------------------------------------------*/
select @IntegrationName = '6RiverCIMS',
       @InputType       = 'BODY',
       @InputDataType   = 'JSON1',
       @ProcessMode     = 'DEFER', /* NOW changed to DEFER.. this is temporary, until the implementation is ready */
       @ResponseType    = 'CONFIRM',
       @BusinessUnit    = (select Top 1 BusinessUnit from BusinessUnits where Status = 'A');

delete from APIConfiguration where IntegrationName = @IntegrationName and BusinessUnit = @BusinessUnit;

insert into APIConfiguration
            (MessageType,                  MessageUrl,                   MethodType, StoredProcedureName,                             SuccessResponseCode, FailResponseCode, IntegrationName,  InputType,  InputDataType,   ProcessMode,  ResponseType,   BusinessUnit)
      select 'PrintRequest',               'print-request',              'POST',     'pr_API_6River_Inbound_PrintRequest',            '200',               '400',            @IntegrationName, @InputType, @InputDataType,  @ProcessMode, @ResponseType,  @BusinessUnit
union select 'StartedPicking',             'container-inducted',         'POST',     'pr_API_6River_Inbound_ContainerInduction',      '200',               '400',            @IntegrationName, @InputType, @InputDataType,  @ProcessMode, @ResponseType,  @BusinessUnit
union select 'PickCompleted',              'pick-task-picked',           'POST',     'pr_API_6River_Inbound_PickTaskPicked',          '200',               '400',            @IntegrationName, @InputType, @InputDataType,  @ProcessMode, @ResponseType,  @BusinessUnit
union select 'ContainerPickCompleted',     'container-pick-complete',    'POST',     'pr_API_6River_Inbound_ContainerPickComplete',   '200',               '400',            @IntegrationName, @InputType, @InputDataType,  @ProcessMode, @ResponseType,  @BusinessUnit
union select 'ContainerValidation',        'container-validation',       'POST',     'pr_API_6River_Inbound_ContainerValidation',     '200',               '400',            @IntegrationName, @InputType, @InputDataType,  @ProcessMode, @ResponseType,  @BusinessUnit
union select 'ContainerTakenOff',          'container-taken-off',        'POST',     'pr_API_6River_Inbound_ContainerTakenOff',       '200',               '400',            @IntegrationName, @InputType, @InputDataType,  @ProcessMode, @ResponseType,  @BusinessUnit
union select 'MessageAcknowledgement',     'message-acknowledgement',    'POST',     'pr_API_6River_Inbound_MessageAcknowledgement',  '200',               '400',            @IntegrationName, @InputType, @InputDataType,  @ProcessMode, @ResponseType,  @BusinessUnit

/*------------------------------------------------------------------------------*/
select @IntegrationName = 'CIMS6River',
       @InputType       = 'BODY',
       @InputDataType   = 'JSON1';

delete from APIConfiguration where IntegrationName = @IntegrationName and BusinessUnit = @BusinessUnit;

insert into APIConfiguration
            (MessageType,                  MessageUrl,                   MethodType, StoredProcedureName,                             DataProcedureName,                                IntegrationName,  InputType,  InputDataType,   BusinessUnit)
      select 'PickWave',                   'pick-waves',                 'POST',     null,                                            'pr_API_6River_Outbound_PickWave_GetMsgData',     @IntegrationName, @InputType, @InputDataType,  @BusinessUnit
union select 'UpdatePriority',             'group-updates',              'POST',     null,                                            'pr_API_6River_Outbound_GroupUpdate_GetMsgData',  @IntegrationName, @InputType, @InputDataType,  @BusinessUnit
union select 'UpdateShipDate',             'group-updates',              'POST',     null,                                            'pr_API_6River_Outbound_GroupUpdate_GetMsgData',  @IntegrationName, @InputType, @InputDataType,  @BusinessUnit
union select 'UpdateDestination',          'group-updates',              'POST',     null,                                            'pr_API_6River_Outbound_GroupUpdate_GetMsgData',  @IntegrationName, @InputType, @InputDataType,  @BusinessUnit
union select 'PickCanceled',               'group-cancellations',        'POST',     null,                                            'pr_API_6River_Outbound_GroupCancel_GetMsgData',  @IntegrationName, @InputType, @InputDataType,  @BusinessUnit

/*------------------------------------------------------------------------------*/
select @IntegrationName = 'CIMS',
       @InputType       = 'BODY',
       @InputDataType   = 'XML2',
       @ProcessMode     = 'NOW',
       @ResponseType    = 'CONFIRM'

delete from APIConfiguration where IntegrationName = @IntegrationName and BusinessUnit = @BusinessUnit;

insert into APIConfiguration
            (MessageType,                  MessageUrl,                   MethodType, StoredProcedureName,                      IntegrationName,  InputType,  InputDataType,   ProcessMode,  ResponseType,   BusinessUnit)
     select  'UpdateEventRun',             'update-event-run',           'POST',     'pr_API_CIMS_UpdateEventRun',             @IntegrationName, @InputType, @InputDataType,  @ProcessMode, @ResponseType,  BusinessUnit from BusinessUnits

/*------------------------------------------------------------------------------*/
select @IntegrationName = 'CIMSUPS',
       @InputType       = 'URLAPPEND',
       @InputDataType   = 'JSON1',
       @ProcessMode     = 'NOW',
       @ResponseType    = 'CONFIRM'

delete from APIConfiguration where IntegrationName = @IntegrationName and BusinessUnit = @BusinessUnit;

insert into APIConfiguration
             (MessageType,                  MessageUrl,                   MethodType, StoredProcedureName,                      DataProcedureName,                        IntegrationName,  InputType,  InputDataType,   ProcessMode,  ResponseType,  RecordsPerBatch,   BusinessUnit)
      select  'UPSTracking',                'track/v1/details',           'GET',      'pr_API_UPS_ProcessTrackingInfo',         'pr_API_UPS_TrackingInfo_GetMsgData',     @IntegrationName, @InputType, @InputDataType,  @ProcessMode, @ResponseType, 200,               BusinessUnit from BusinessUnits
union select  'ShipmentRequest',            'ship/v2/shipments',          'POST',     'pr_API_UPS_ProcessShipmentResponse',     'pr_API_UPS_ShipmentRequest_GetMsgData',  @IntegrationName, 'BODY',     @InputDataType,  @ProcessMode, @ResponseType, 200,               BusinessUnit from BusinessUnits
union select  'AddressValidation',          'addressvalidation/v1/3',     'POST',     'pr_API_UPS_AddressValidation_ProcessResponse', 'pr_API_UPS_AddressValidation_GetMsgData',        @IntegrationName, 'BODY',     @InputDataType,  @ProcessMode, @ResponseType, 200,               BusinessUnit from BusinessUnits

/*------------------------------------------------------------------------------*/
select @IntegrationName = 'CIMSUPSOAUTH2',
       @InputType       = 'BODY',
       @InputDataType   = 'JSON1',
       @ProcessMode     = 'NOW',
       @ResponseType    = 'CONFIRM'

delete from APIConfiguration where IntegrationName = @IntegrationName and BusinessUnit = @BusinessUnit;
/* Note:
    GenerateToken: Requires authorization code to generate token and allow only one time to generate token for the authorization code
    Create Token: Requires client id and client secret to create token and we can generate whenever required */
insert into APIConfiguration
             (MessageType,                  MessageUrl,                     MethodType, StoredProcedureName,                            DataProcedureName,                              IntegrationName,  InputType,        InputDataType,   ProcessMode,  ResponseType,  RecordsPerBatch,   BusinessUnit)
      select  'GenerateToken',              'security/v1/oauth/token',      'POST',     'pr_API_UPS2_GenerateToken_ProcessResponse',    'pr_API_UPS2_GenerateToken_GetMsgData',         @IntegrationName, 'FormURLEncoded', @InputDataType,  @ProcessMode, @ResponseType, 200,               BusinessUnit from BusinessUnits
union select  'RefreshToken',               'security/v1/oauth/refresh',    'POST',     'pr_API_UPS2_RefreshToken_ProcessResponse',     'pr_API_UPS2_RefreshToken_GetMsgData',          @IntegrationName, 'FormURLEncoded', @InputDataType,  @ProcessMode, @ResponseType, 200,               BusinessUnit from BusinessUnits
union select  'CreateToken',                'security/v1/oauth/token',      'POST',     'pr_API_UPS2_CreateToken_ProcessResponse',      'pr_API_UPS2_CreateToken_GetMsgData',           @IntegrationName, 'FormURLEncoded', @InputDataType,  @ProcessMode, @ResponseType, 200,               BusinessUnit from BusinessUnits

/*------------------------------------------------------------------------------*/
select @IntegrationName = 'CIMSUPS2',
       @InputType       = 'BODY',
       @InputDataType   = 'JSON1',
       @ProcessMode     = 'NOW',
       @ResponseType    = 'CONFIRM'

delete from APIConfiguration where IntegrationName = @IntegrationName and BusinessUnit = @BusinessUnit;

insert into APIConfiguration
             (MessageType,                  MessageUrl,                     MethodType, StoredProcedureName,                            DataProcedureName,                              IntegrationName,  InputType,        InputDataType,   ProcessMode,  ResponseType,  RecordsPerBatch,   BusinessUnit)
      select  'ShipmentRequest',            'shipments/v2205/ship',         'POST',     'pr_API_UPS_ProcessShipmentResponse',           'pr_API_UPS_ShipmentRequest_GetMsgData',        @IntegrationName, @InputType,       @InputDataType,  @ProcessMode, @ResponseType, 200,               BusinessUnit from BusinessUnits
union select  'UPSTracking',                'track/v1/details',             'GET',      'pr_API_UPS2_TrackingInfo_ProcessResponse',     'pr_API_UPS2_TrackingInfo_GetMsgData',          @IntegrationName, 'URLAPPEND',      @InputDataType,  @ProcessMode, @ResponseType, 200,               BusinessUnit from BusinessUnits


/*------------------------------------------------------------------------------*/
select @IntegrationName = 'CIMSUSPS',
       @InputType       = 'URLCONCAT',
       @InputDataType   = 'XML1',
       @ProcessMode     = 'NOW',
       @ResponseType    = 'CONFIRM'

delete from APIConfiguration where IntegrationName = @IntegrationName and BusinessUnit = @BusinessUnit;

insert into APIConfiguration
            (MessageType,                  MessageUrl,                     MethodType, StoredProcedureName,                    DataProcedureName,                        IntegrationName,  InputType,  InputDataType,   ProcessMode,  ResponseType,   BusinessUnit)
     select  'USPSTracking',               'ShippingAPI.dll?API=TrackV2&', 'GET',      'pr_API_USPS_ProcessTrackingInfo',      'pr_API_USPS_TrackingInfo_GetMsgData',    @IntegrationName, @InputType, @InputDataType,  @ProcessMode, @ResponseType,  BusinessUnit from BusinessUnits
/*------------------------------------------------------------------------------*/
/* CIMS FedEx 2 integration is newer FedEx Restful API integration using OAuth */
select @IntegrationName = 'CIMSFEDEX2OAUTH',
       @InputType       = 'BODY',
       @InputDataType   = 'JSON1',
       @ProcessMode     = 'NOW',
       @ResponseType    = 'CONFIRM'

delete from APIConfiguration where IntegrationName = @IntegrationName and BusinessUnit = @BusinessUnit;

insert into APIConfiguration
             (MessageType,                  MessageUrl,                     MethodType, StoredProcedureName,                            DataProcedureName,                              IntegrationName,  InputType,        InputDataType,   ProcessMode,  ResponseType,  RecordsPerBatch,   BusinessUnit)
      select  'GenerateToken',              'oauth/token',                  'POST',     'pr_API_FedEx2_GenerateToken_ProcessResponse',  'pr_API_FedEx2_GenerateToken_GetMsgData',       @IntegrationName, 'FormURLEncoded', @InputDataType,  @ProcessMode, @ResponseType, 200,               BusinessUnit from BusinessUnits

/*------------------------------------------------------------------------------*/
select @IntegrationName = 'CIMSFEDEX2',
       @InputType       = 'BODY',
       @InputDataType   = 'JSON1',
       @ProcessMode     = 'NOW',
       @ResponseType    = 'CONFIRM'

delete from APIConfiguration where IntegrationName = @IntegrationName and BusinessUnit = @BusinessUnit;

insert into APIConfiguration
            (MessageType,                  MessageUrl,                     MethodType,     StoredProcedureName,                                    DataProcedureName,                                 IntegrationName,  InputType,  InputDataType,   ProcessMode,  ResponseType,   BusinessUnit)
      select 'AddressValidation',          'address/v1/addresses/resolve', 'POST',         'pr_API_FEDEX2_AddressValidation_ProcessResponse',      'pr_API_FEDEX2_AddressValidation_GetMsgData',      @IntegrationName, 'BODY',     @InputDataType,  @ProcessMode, @ResponseType,  BusinessUnit from BusinessUnits
union select 'ShipmentRequest',            'ship/v1/shipments',            'POST',         'pr_API_FedEx2_ShipmentRequest_ProcessResponse',        'pr_API_FedEx2_ShipmentRequest_GetMsgData',        @IntegrationName, 'BODY',     @InputDataType,  @ProcessMode, @ResponseType,  BusinessUnit from BusinessUnits
union select 'FEDEXTracking',              'track/v1/trackingnumbers',     'POST',         'pr_API_FedEx2_TrackingInfo_ProcessResponse',           'pr_API_FedEx2_TrackingInfo_GetMsgData',           @IntegrationName, 'BODY',     @InputDataType,  @ProcessMode, @ResponseType,  BusinessUnit from BusinessUnits


Go
