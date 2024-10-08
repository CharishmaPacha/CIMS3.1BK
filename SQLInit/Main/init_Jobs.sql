/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/04/27  TK      Added Tasks_RecomputePrintStatus job (CIDV3-676)
  2024/02/12  RV      Added _API_FedExAccessTokenValidateAndCreate to generate the token (CIMSV3-3397)
  2023/09/15  RV      ~DBName~_API_UPSAccessTokenValidateAndCreate: To create the UPS access token (MBW-495)
  2023/09/12  RV      ~DBName~_API_UPSAccessTokenRefresh: To refresh the UPS accounts access tokens (MBW-465)
  2022/08/10  VS      Added Export_DataTransactions_PTError (BK-885)
  2022/07/07  PHK     Added new job for TransactionStatus is Fail/Fatal on APIOutboundTransactions (BK-862)
  2022/07/06  GAG     Added ~DBName~_Order_OrderDeliveryStatus to update Delivery Status for an Order daily at 1AM (BK-865)
  2022/04/22  MS      Added ~DBName~_SKUVelocityStatistics  & ~DBName~_LocationReplenishLevelUpdates (BK-768)
  2021/12/24  TK      Waves_ReturnOrdersToOpenPool: Corrections (BK-720)
  2021/10/11  RKC     Added ~DBName~_Alerts_ListOfOrdersToShip (BK-638)
  2021/08/06  RKC     Added ~DBName~_Alerts_Orders_StuckInDownload (BK-433)
  2021/07/23  SK/TK   Added job to run Warehouse metrics (HA-3019)
  2021/07/10  OK      Added job to finalize API responses (BK-408)
  2021/06/25  SJ      Added job pr_Alerts_LocationsCountsMismatch (HA-2696)
  2021/06/22  VS      Added Adhoc snapshot step to trace the variance (BK-373)
  2021/06/01  RKC     Enabled the ~DBName~_Export_GenerateBatches (HA-2850)
  2021/03/23  OK      Added Alert_LoadsNotShipped (HA-2379)
  2021/03/22  TK      Added Import_InvAdjustments_Transfers (HA-2341)
  2021/03/10  TK/KBB  Added job to process outbound transactions (BK-201)
                      Added job to Export Carrier Tracking Info (BK-203)
  2021/02/01  SK      Setup job for Exporting EDI transactions (HA-1986)
  2021/01/29  VS      Added pr_Alerts_ShipmentNotification Job (BK-117)
  2021/01/29  VS      Migrated pr_Alerts_ShipmentNotification_Summary Job from HPI
  2021/01/26  OK      Added job to process UIActions in background with action procedures (CIMSV3-1267)
  2020/12/04  TK      Added Job to process defered API Inbound Transactions (CID-1542)
  2020/11/18  TK      Added Job to prepare API Outbound Transactions (CID-1498)
  2020/10/14  VS      Schedule Background jobs 1 min difference (S2GCA-1317)
  2020/10/08  VS      Added Background_ExecuteProcesses_CLS,LPL,RFP+CP Jobs (HA-1534)
  2020/09/28  MS      Purging_Execute: Corrections to input params (JL-65)
  2020/09/24  SAK     Added _pr_Alerts_InterfaceErrors job (HA-1075)
  2020/09/18  PHK     Added Archive_Data job (HA-1377)
  2020/09/17  MS      Added Router_DCMS_GetConfirmations & Router_DCMS_ExportInstructions (JL-64, JL-65)
  2020/08/12  SK      New job OpenOrders_ExportSummary to export open order summary to CIMSDE (HA-1267)
  2020/08/04  AY      Inventory_CreateInvSnapshot: pass SnapshotType param (HA-1180)
  2020/07/23  VS      Added Allocation statistics Daily, Monthly (CIMSV3-1037)
  2020/07/22  OK      Added job to create the loads if any load closed manually (HA-1127)
  2020/07/21  RKC     Added LPNTransfers_PrepareForReceipt job (HA-1073)
  2020/07/20  SK      Updated schedule and job InventoryCreateComparison
                      Added new job AlertInventoryDiscrepancyMonthly (HA-1180)
  2020/07/09  OK      Added Loads related jobs (HA-1128)
  2020/06/16  OK      Corrected the Background process job schedule to run every 5 mins (HA-967)
  2020/05/13  KBB     Added Import FailedRecords (HA-148)
  2020/04/22  MS      Migrated Exports Jobs from CID (HA-266)
  2020/03/27  VS      Added Import_RemoveTempTables Job(CID-1399)
  2020/03/25  MS      Added Router_GetConfirmations job (JL-64)
  2020/03/21  MS      Added Router_ExportInstructions job (JL-64)
  2020/02/11  SK      Added job UserProductivity (CIMS-2871)
  2019/12/10  RKC     Added job Alert_MissingExportBatches (CID-1175)
  2019/12/05  SK      Added job to execute auto activation of temporary LPNs for LPN Reservation (FB-1460)
  2019/07/11  SK      Updated Variance CreateInventoryVariance job name, migrated from CIMS Dev (CID-733)
  2019/05/01  VS      Job to Get alerts for Invalid Ownership LPNs (S2GCA-666 & S2GCA-791)
  2019/01/04  VS      Added New Job for ASN and Receipts imports (CID-201)
  2018/12/21  RIA     Added a job to get disk space (OB2-673)
  2018/12/03  AY      Added jobs for Purging (all tables defined in PurgingControl) or specific tables
  2018/11/23  RIA     Added job to auto wave (OB2-745)
  2018/11/22  VS      CreateInventorySnapshots: Added job for creating inventory Snapshot (S2GCA-1169)
  2018/09/03  TK      Added Background process job (S2GCA-215)
  2018/08/23  VS      Added job for Create New ActivityLog table (S2G-1059)
  2018/08/22  AY      Added job for exporting Panda Pallets (S2G-1084)
  2018/08/21  OK      Added job for processing PandA Pallets (S2G-1084)
  2018/08/12  VM      Added Alert_SplitTaskDetails (OB2-Golive)
  2018/07/25  VS      Created new job for Min-Max replen for ASD picklanes (S2GCA-111)
  2018/07/31  VM      Added job for Alert_OpenOrdersSummary (S2G-1066)
  2018/07/24  SPP     Added Productivity_CreateLog(OB2-337)
  2018/07/11  AY      Setup job for completing Replenish Waves (S2G-1015)
  2018/05/08  SV      Export OnHand Inventory: Changes as per the signature change in pr_Exports_CIMSDE_ExportOnhandInventory (S2G-470)
  2018/04/30  VM      Added Router_ProcessConfirmations (S2G-703)
  2018/04/16  SV      Added a job - OrderAutoCancel (HPI-1849)
  2018/04/09  VM      Consolidated alert by EOD for several alerts configured (S2G-489)
  2018/04/04  VM      Alert_LPNCountsMismatch: Additional param ShowModifiedInLastXMinutes (S2G-489)
  2018/04/03  VM      Alert_LogicalLPNCountsMismatch: Additional param ShowModifiedInLastXMinutes passed (S2G-489)
  2018/03/30  SV      pr_Exports_CIMSDE_ExportData, pr_Exports_CIMSDE_ExportOnhandInventory, pr_Exports_CIMSDE_ExportOpenOrders,
                      pr_Exports_CIMSDE_ExportOpenReceipts:
                        Added SourceSystem as parameters for DE ralated jobs (HPI-1845)
  2018/03/24  VM      Added Alert_LPNCountsMismatch (S2G-486)
  2018/03/23  VM      Added Alert_LogicalLPNCountsMismatch (S2G-477)
  2018/03/13  VM      Added Alert_WavesNotAllocated (S2G-391)
  2018/03/10  VM      Added Alert_OrphanDLines (S2G-391)
                      Added Alert_MisMatchOfODUnitsAssigned and Alert_LocationCountDiscrepency (S2G-391)
  2018/03/12  OK      Added jobs for AllocateWave and SetUpWaveToReleaseToWSS (XXXX)
  2018/01/31  OK      Added job for Receipts PreProcess (S2G-176)
  2018/01/05  TD      Jobs for direct database integration (S2G-28)
  2017/12/29  TK      Initial revision (CIMS-758)
------------------------------------------------------------------------------*/

/*******************************************************************************
 *  General Info needed to create jobs:
 ********** Do not add this file to _Init_All.sql file **********
 *** We cannot use user defined datatypes for SQL Server agent procedures hence use only system defined datatypes

 *    OnSuccessAction & OnFailureAction: The action to perform if the step succeeds
                                             1 = Quit with success
                                             2 = Quit with failure
                                             3 = Go to next step
                                             4 = Go to step on_success_step_id

 *    FreqType     : Indicates when the job is to be executed; 4 - daily, 8 - weekly, 16 - monthly, 128 - when idle.

 *    FreqInterval : Interval at which the job runs.
                     if type = 4, this is in days,
                     if type = 8 (weekly) then this is the days of the week, 1 - Sunday, 2 - Mon, 4 - Tue, 8 - Wed, .... 64 - Sat
                     if type = 16, this is day of the month

 *    FreqSubDayType : Specifies the units for frequency_subday_interval and it is defaulted to '4'
                         1 = At Specified Time
                         4 = Minutes
                         8 = Hours

 *    FreqSubDayInterval : Number of FreqSubDayType periods to occur between each execution of the job, with a default of 0.
                          0 = only once a day
                          1 = runs every minute
                          2 = runs every 2 minutes
                          5 = runs every 5 minutes and so on

 *    StartTime    : Time on any day to begin job execution, it is of integer datatype
                       and format should be like HHMMSS on a 24-hour clock
 *    EndTime      : Time on any day to end job execution , it is of integer datatype
                       and format should be like HHMMSS on a 24-hour clock
*******************************************************************************/

Go

declare @vJobId                  uniqueidentifier,
        @vJobName                nvarchar(128),
        @vJobDescription         nvarchar(512),
        @vCommand                nvarchar(max),
        @vBusinessUnit           nvarchar(30),
        @vJobEnabled             tinyint,
        @vFreqType               int,
        @vFreqInterval           int,
        @vFreqSubDayType         int,
        @vFreqSubDayInterval     int,
        @vFreqRelativeInterval   int,
        @vFreqRecurrenceFactor   int,
        @vStartTime              int,
        @vEndTime                int;

declare @ttJobStepsInfo       TJobStepsInfo;

/* Includinig this we can avoid creating jobs on DB's using SCT */
select top 1 @vBusinessUnit = BusinessUnit
from vwBusinessUnits

/*******************************************************************************
  Functional Process Jobs
*******************************************************************************/

/*------------------------------------------------------------------------------
  Process Purge_ActivityLog
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Purge_ActivityLogTables',
       @vJobDescription       = 'Drop ActivityLog_ tables',
      -- All other parameters are default params to run job for every month once at 2:10 am
       @vJobEnabled           = 1,
       @vFreqType             = 16,         @vFreqInterval         = 1, /* Monthly on first day of month */
       @vFreqSubDayType       = 1,          @vFreqSubDayInterval   = 5,
       @vFreqRelativeInterval = 1,          @vFreqRecurrenceFactor = 1,
       @vStartTime            = 021000,     @vEndTime              = null; /* Run at 2:10 am */

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Purge_ActivityLog',      'exec pr_Purging_ActivityLog ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Create New ActivityLog table
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_ActivityLog_Create',
       @vJobDescription     = 'Create New ActivityLog_YYYYMM tables',
      -- All other parameters are default params to run job for every month once at 2.00 am
       @vJobEnabled           = 1,
       @vFreqType             = 16,         @vFreqInterval         = 1, /* Monthly on first day of month */
       @vFreqSubDayType       = 1,          @vFreqSubDayInterval   = 5,
       @vFreqRelativeInterval = 1,          @vFreqRecurrenceFactor = 1,
       @vStartTime            = 020000,     @vEndTime              = null; /* Run at 2:10 am */

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_ActivityLog_Create',     'exec pr_ActivityLog_CreateTable ''Monthly'' ');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Allocate Waves Job
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_AllocateWaves',
       @vJobDescription       = 'Allocate released waves',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = 0,
       @vFreqType             = null,       @vFreqInterval         = null,
       @vFreqSubDayType       = null,       @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,       @vFreqRecurrenceFactor = null,
       @vStartTime            = 000000,     @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_AllocateWaves',          'exec pr_Allocation_AllocateWave null, null, ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 SetUp waves to release to WSS job
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Wave_ComputeWCSReleaseDependency',
       @vJobDescription     = 'Compute WCS Release Dependency',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = 0,
       @vFreqType             = null,       @vFreqInterval         = null,
       @vFreqSubDayType       = null,       @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,       @vFreqRecurrenceFactor = null,
       @vStartTime            = 000000,     @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_SetUpWaveToReleaseToWSS',          'exec pr_Wave_ComputeWCSReleaseDependency ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Job to prepare API outbound transactions
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_API_PrepareOutboundTransactions',
       @vJobDescription       = 'Prepare API outbound transactions',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = 0,
       @vFreqType             = null,       @vFreqInterval         = null,
       @vFreqSubDayType       = null,       @vFreqSubDayInterval   = 5,
       @vFreqRelativeInterval = null,       @vFreqRecurrenceFactor = null,
       @vStartTime            = 000000,     @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                                      Command)
values ('~DBName~_API_PrepareOutboundTransactions',      'exec pr_API_PrepareOutboundTransactions null, ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Job to process deferred API Inbound transactions
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_API_ProcessDeferredInboundTransactions',
       @vJobDescription       = 'Process deferred API inbound transactions',
      -- All other parameters are default params to run job all day long for every 2 minutes
       @vJobEnabled           = 0,
       @vFreqType             = null,       @vFreqInterval         = null,
       @vFreqSubDayType       = null,       @vFreqSubDayInterval   = 2,
       @vFreqRelativeInterval = null,       @vFreqRecurrenceFactor = null,
       @vStartTime            = 000000,     @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                                      Command)
values ('~DBName~_API_ProcessDeferredInboundTransactions',  'exec pr_API_ProcessDeferredInboundTransactions null, ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Job to process API Outbound transactions
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_API_ProcessOutboundTransactions',
       @vJobDescription       = 'Process API Outbound transactions',
      -- All other parameters are default params to run job all day long for every 2 minutes
       @vJobEnabled           = 0,
       @vFreqType             = null,       @vFreqInterval         = 1,
       @vFreqSubDayType       = null,       @vFreqSubDayInterval   = 2,
       @vFreqRelativeInterval = null,       @vFreqRecurrenceFactor = 1,
       @vStartTime            = 000000,     @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                                      Command)
values ('~DBName~_API_ProcessOutboundTransactions',    'exec pr_API_ProcessOutboundTransactions null, ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Job to finalize waves after API Outbound transactions are processed
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_API_FinalizeResponses',
       @vJobDescription       = 'Finalize Responses after outbound transactions are processed',
      -- All other parameters are default params to run job all day long for every 2 minutes
       @vJobEnabled           = 0,
       @vFreqType             = null,       @vFreqInterval         = 1,
       @vFreqSubDayType       = null,       @vFreqSubDayInterval   = 2,
       @vFreqRelativeInterval = null,       @vFreqRecurrenceFactor = 1,
       @vStartTime            = 000000,     @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                                         Command)
values ('~DBName~_API_FinalizeResponses from UPS',        'exec pr_API_FinalizeResponses ''CIMSUPS'', ''APIJOB'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_API_FinalizeResponses from FedEex',     'exec pr_API_FinalizeResponses ''CIMSFEDEX'', ''APIJOB'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_API_FinalizeResponses from USPS',       'exec pr_API_FinalizeResponses ''CIMSENDICIAUSPS'', ''APIJOB'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Job to prepare API Request Tracking Info
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_API_RequestTrackingInfo',
       @vJobDescription       = 'Prepare API Request Tracking Info',
       --This should run once a day and it should be at 09.00 PM
       @vJobEnabled           = 1,
       @vFreqType             = 4,          @vFreqInterval         = 1,
       @vFreqSubDayType       = 4,          @vFreqSubDayInterval   = 30,
       @vFreqRelativeInterval = 0,          @vFreqRecurrenceFactor = 0,
       @vStartTime            = 210000,     @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                                      Command)
values ('~DBName~_Shipping_InitiateCarrierTracking',   'exec pr_Shipping_InitiateCarrierTracking null, ''cIMSAgent'', ''~BU~'''),
       ('~DBName~_API_RequestTrackingInfo',            'exec pr_API_RequestTrackingInfo null, ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Archive Entities Job
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_ArchiveEntities',
       @vJobDescription       = 'Archive several Entities',
       -- Every Day, Once a day at  once at 00:05 AM, i.e. 5 mins past midnight
       @vJobEnabled           = 1,
       @vFreqType             = 4,          @vFreqInterval         = 1,
       @vFreqSubDayType       = 1,          @vFreqSubDayInterval   = 0,
       @vFreqRelativeInterval = null,       @vFreqRecurrenceFactor = null,
       @vStartTime            = 000500,     @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Archive_Exports',                  'exec pr_Archive_Exports ''cIMSAgent'', ''~BU~'''),
       ('~DBName~_Archive_Loads',                    'exec pr_Archive_Loads ''cIMSAgent'', ''~BU~'''),
       ('~DBName~_Archive_Orders',                   'exec pr_Archive_Orders ''cIMSAgent'', ''~BU~'''),
       ('~DBName~_Archive_LPNs',                     'exec pr_Archive_LPNs''cIMSAgent'', ''~BU~'''),
       ('~DBName~_Archive_Pallets',                  'exec pr_Archive_Pallets ''cIMSAgent'', ''~BU~'''),
       ('~DBName~_Archive_Waves',                    'exec pr_Archive_Waves ''cIMSAgent'', ''~BU~'''),
       ('~DBName~_Archive_Receivers',                'exec pr_Archive_Receivers ''cIMSAgent'', ''~BU~'''),
       ('~DBName~_Archive_ReceiptOrders',            'exec pr_Archive_ReceiptOrders ''cIMSAgent'', ''~BU~'''),
       ('~DBName~_Archive_ShipLabels',               'exec pr_Archive_ShipLabels ''cIMSAgent'', ''~BU~'''),
       ('~DBName~_Archive_Tasks',                    'exec pr_Archive_Tasks ''cIMSAgent'', ''~BU~''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;
/*------------------------------------------------------------------------------
 Archive Data Job
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_ArchiveData',
       @vJobDescription       = 'Archive Data using Rules',
       -- Every Day, Once a day at  once at 00:10 AM i.e. 10 mins past midnight
       @vJobEnabled           = 1,
       @vFreqType             = 4,          @vFreqInterval         = 1,
       @vFreqSubDayType       = 1,          @vFreqSubDayInterval   = 0,
       @vFreqRelativeInterval = null,       @vFreqRecurrenceFactor = null,
       @vStartTime            = 001000,     @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Archive_AllData',                  'exec pr_Archive_Data ''All'', ''cIMSAgent'', ''~BU~''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Purging Data Job for tables defined in PurgeControl
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_PurgeData_PurgeControl',
       @vJobDescription       = 'Purge old data',
       @vJobEnabled           = 0, -- Disabled by default
       @vFreqType             = 8, -- weekly
       @vFreqInterval         = 1, -- On Sunday
       @vFreqSubDayType       = 1, -- At specified time
       @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,
       @vFreqRecurrenceFactor = 1,
       @vStartTime            = 020000,
       @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Purging_Execute',        'exec pr_Purging_Execute null, null, ''~BU~''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Purging Data Job for specific tables: Two sample steps are setup, need to
   expand and add other steps if needed. This job is usually not run because
   the job PurgeData_PurgeControl will handle all tables. This job is only being
   setup as an example to use if there is a special requirement to purge some
   tables on a different schedule
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_PurgeData_SpecificTables',
       @vJobDescription       = 'Purge old data for specific tables',
       @vJobEnabled           = 0, -- Disabled by default
       @vFreqType             = 8, -- weekly
       @vFreqInterval         = 1, -- On Sunday
       @vFreqSubDayType       = 1, -- At specified time
       @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,
       @vFreqRecurrenceFactor = null,
       @vStartTime            = 020000,
       @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Purging_InterfaceLog_All',         'exec pr_Purging_Execute ''InterfaceLog_All'''),
       ('~DBName~_Purging_Exports_Processed',        'exec pr_Purging_Execute ''Exports_Processed''')

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  RecalCounts
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_RecalcCounts',
       @vJobDescription       = 'Recalc Entity Counts/Statuses',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_RecalcCounts',           'exec pr_Entities_RecalcCounts ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  execute BackGround Process CLS - Confirm Load Shipped
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Background_ExecuteProcesses_CLS',
       @vJobDescription     = 'execute the Confirm Load Shipped from BackgroundProcesses table',
       -- Occurs every day every 5 minute(s) between 05:30:00 and 23:59:59.
       @vJobEnabled           = null,
       @vFreqType             = 4,     @vFreqInterval         = 1,
       @vFreqSubDayType       = 4,     @vFreqSubDayInterval   = 5,
       @vFreqRelativeInterval = 0,     @vFreqRecurrenceFactor = 0,
       @vStartTime            = 163000,@vEndTime              = 10000;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_ExecuteProcess CLS',       'exec pr_Entities_ExecuteProcess ''CLS'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  execute BackGround Process LPL - Load Pallet & LPNs
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Background_ExecuteProcesses_LPL',
       @vJobDescription     = 'execute the Load Pallet & LPNs from BackgroundProcesses table',
       -- Occurs every day every 5 minute(s) between 05:28:00 and 23:59:59.
       @vJobEnabled           = null,
       @vFreqType             = 4,     @vFreqInterval         = 1,
       @vFreqSubDayType       = 4,     @vFreqSubDayInterval   = 5,
       @vFreqRelativeInterval = 0,     @vFreqRecurrenceFactor = 0,
       @vStartTime            = 52800, @vEndTime              = 235959;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_ExecuteProcess LPL',       'exec pr_Entities_ExecuteProcess ''LPL'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  execute BackGround Process RFP+CP - Release for Picking, Confirm Pick Tasks
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Background_ExecuteProcesses_RFP-CP',
       @vJobDescription     = 'execute the Release for Picking and Confirm Picks from BackgroundProcesses table',
       -- Occurs every day every 5 minute(s) between 05:27:00 and 23:59:59.
       @vJobEnabled           = null,
       @vFreqType             = 4,     @vFreqInterval         = 1,
       @vFreqSubDayType       = 4,     @vFreqSubDayInterval   = 5,
       @vFreqRelativeInterval = 0,     @vFreqRecurrenceFactor = 0,
       @vStartTime            = 52700, @vEndTime              = 235959;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_ExecuteProcess RFP',       'exec pr_Entities_ExecuteProcess ''RFP'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_ExecuteProcess CP',        'exec pr_Entities_ExecuteProcess ''CP'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  execute BackGround Process - UI Actions
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Background_ExecuteProcesses_UIAction',
       @vJobDescription     = 'execute the UI Action from BackgroundProcesses table',
       -- Occurs every day every 5 minute(s) between 05:26:00 and 23:59:59.
       @vJobEnabled           = null,
       @vFreqType             = 4,     @vFreqInterval         = 1,
       @vFreqSubDayType       = 4,     @vFreqSubDayInterval   = 5,
       @vFreqRelativeInterval = 0,     @vFreqRecurrenceFactor = 1,
       @vStartTime            = 52600, @vEndTime              = 235959;

insert into @ttJobStepsInfo
       (StepName,                                 Command)
values ('~DBName~_ExecuteProcess UI Actions',     'exec pr_Entities_ExecuteProcess ''UIAction'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  execute BackGround Process - Generic Process
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Background_ExecuteProcesses',
       @vJobDescription     = 'execute the async processes from BackgroundProcesses table',
       -- Occurs every day every 5 minute(s) between 05:26:00 and 23:59:59.
       @vJobEnabled           = null,
       @vFreqType             = 4,     @vFreqInterval         = 1,
       @vFreqSubDayType       = 4,     @vFreqSubDayInterval   = 5,
       @vFreqRelativeInterval = 0,     @vFreqRecurrenceFactor = 0,
       @vStartTime            = 52600, @vEndTime              = 235959;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_ExecuteProcess Generic',   'exec pr_Entities_ExecuteProcess ''Process'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Replenishments - Mark Orders/Waves as completed
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Replenish_MarkAsCompleted',
       @vJobDescription     = 'Recalc the Status of Replenish Orders/Waves',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Replenish_MarkAsCompleted',        'exec pr_Replenish_MarkOrdersCompleted ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Import Jobs - Sales Order Pre-Process
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_OrderPreProcess',
       @vJobDescription     = 'Pre-Process the orders which were recently imported into CIMS',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_PreProcessOrders',       'exec pr_Imports_PreprocessOrders');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Auto Cancel Orders which they do not match host num lines on order and details imported
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_AutoCancel_SalesOrders',
       @vJobDescription     = 'Auto Cancel Orders which they do not match host num lines on order and details imported',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = 1,
       @vFreqType           = 4,          @vFreqInterval       = 1,
       @vFreqSubDayType     = 4,          @vFreqSubDayInterval = 30,
       @vStartTime          = 000000,     @vEndTime            = 235900;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_AutoCancel_SalesOrders',  'exec pr_OrderHeaders_AutoCancel ''~BU~'', ''CancelInvalidOrders'''),
       ('Cancel Order when num lines not matches',  'exec pr_OrderHeaders_AutoCancel ''~BU~'', null');


exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*******************************************************************************
  Alert Jobs
*******************************************************************************/

/*------------------------------------------------------------------------------
  Alert - Allocation statistics Daily
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Alert_AllocationStatisticsDaily',
       @vJobDescription       = 'Wave Allocation Statistics',
       -- Every day once at 11.00PM
       @vJobEnabled           = 0,
       @vFreqType             = 4,         @vFreqInterval         = 1,
       @vFreqSubDayType       = 1,         @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,      @vFreqRecurrenceFactor = 1,
       @vStartTime            = 230000,    @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                                     Command)
values ('~DBName~_Alerts_AllocationStatisticsDaily', 'exec pr_Alerts_AllocationStatistics ''WaveAllocation'', ''0'', ''60'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Alert - Allocation statistics Monthly
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Alert_AllocationStatisticsMonthly',
       @vJobDescription       = 'Wave Allocation Statistics',
       -- Monthly once at 11:00 PM on the last day of the month
       @vJobEnabled           = 0,
       @vFreqType             = 32,         @vFreqInterval         = 8,
       @vFreqSubDayType       = 1,          @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = 16,         @vFreqRecurrenceFactor = 1,
       @vStartTime            = 230000,     @vEndTime              = 235959;

insert into @ttJobStepsInfo
       (StepName,                                       Command)
values ('~DBName~_Alerts_AllocationStatisticsMonthly', 'exec pr_Alerts_AllocationStatistics ''WaveAllocation'', ''30'', ''60'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert for drive space
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alert_DiskSpaceUsage',
       @vJobDescription     = 'Alert to send the disk space',
       --This will run once a day and it should be at 11.30 PM
       @vJobEnabled           = null,
       @vFreqType             = null,   @vFreqInterval         = null,
       @vFreqSubDayType       = 1,      @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,   @vFreqRecurrenceFactor = null,
       @vStartTime            = 233000, @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_DiskSpaceUsage',             'exec pr_Alerts_GetDiskSpace ''~BU~''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Alert - List of orders to ship/close
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Alerts_ListOfOrdersToShip',
       @vJobDescription       = 'Alert if there are any Orders which are yet to be shipped/Closed',
       -- Every day once at 11.00PM
       @vJobEnabled           = 0,
       @vFreqType             = 4,         @vFreqInterval         = 1,
       @vFreqSubDayType       = 1,         @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,      @vFreqRecurrenceFactor = 1,
       @vStartTime            = 230000,    @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                                     Command)
values ('~DBName~_Alerts_ListOfOrdersToShip',  'exec pr_Alerts_ListOfOrdersToShip ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_LocationCountDiscrepency
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alert_LocationCountDiscrepency',
       @vJobDescription     = 'Alert if there are any count discrepancies of Location with its LPNs in it',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_LocationCountDiscrepency',   'exec pr_Alerts_LocationCountDiscrepency ''~BU~'', ''cIMSAgent'', 6');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_LocationCountDiscrepency (Consolidated alert by EOD)
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Alert_LocationCountDiscrepency_EOD',
       @vJobDescription       = 'Alert if there are any count discrepancies of Location with its LPNs in it (EOD)',
       --This should run once a day and it should be at 08.30 PM - Might change, and
       --All other parameters will be default to run
       @vJobEnabled           = null,
       @vFreqType             = null,   @vFreqInterval         = null,
       @vFreqSubDayType       = 1,      @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,   @vFreqRecurrenceFactor = null,
       @vStartTime            = 203000, @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_LocationCountDiscrepency',   'exec pr_Alerts_LocationCountDiscrepency ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_LocationsCountsMismatch (Consolidated alert by EOD)
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Alert_LocationsCountsMismatch_EOD',
       @vJobDescription       = 'Alert if there are any count discrepancies of Location with its LPNs in it (EOD)',
       --This should run once a day and it should be at 11.50 PM - Might change, and
       --All other parameters will be default to run
       @vJobEnabled           = 1,
       @vFreqType             = 4,      @vFreqInterval         = 1,
       @vFreqSubDayType       = 1,      @vFreqSubDayInterval   = 5,
       @vFreqRelativeInterval = 0,      @vFreqRecurrenceFactor = 0,
       @vStartTime            = 235000, @vEndTime              = 235959;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('R-Reserve:Locations Counts Mismatch',      'exec pr_Alerts_LocationsCountsMismatch ''R'', null, ''~BU~'', ''cIMSAgent'''),
       ('B-Bulk:Locations Counts Mismatch',         'exec pr_Alerts_LocationsCountsMismatch ''B'', null, ''~BU~'', ''cIMSAgent'''),
       ('K-PickLane:Locations Counts Mismatch',     'exec pr_Alerts_LocationsCountsMismatch ''K'', null, ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_LogicalLPNCountsMismatch
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alert_LogicalLPNCountsMismatch',
       @vJobDescription     = 'Alert if there are any count discrepancies on Logical LPN',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_LogicalLPNCountsMismatch',   'exec pr_Alerts_LogicalLPNCountsMismatch ''~BU~'', ''cIMSAgent'', 6');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_LogicalLPNCountsMismatch (Consolidated alert by EOD)
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alert_LogicalLPNCountsMismatch_EOD',
       @vJobDescription     = 'Alert if there are any count discrepancies on Logical LPN (EOD)',
       --This should run once a day and it should be at 08.30 PM - Might change, and
       --All other parameters will be default to run
       @vJobEnabled           = null,
       @vFreqType             = null,   @vFreqInterval         = null,
       @vFreqSubDayType       = 1,      @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,   @vFreqRecurrenceFactor = null,
       @vStartTime            = 203000, @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_LogicalLPNCountsMismatch',   'exec pr_Alerts_LogicalLPNCountsMismatch ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_LPNCountsMismatch
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alert_LPNCountsMismatch',
       @vJobDescription     = 'Alert if there are any count discrepancies on LPNs (Other than Logical LPNs)',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_LPNCountsMismatch',          'exec pr_Alerts_LPNCountsMismatch ''~BU~'', ''cIMSAgent'', 6');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_LPNCountsMismatch (Consolidated alert by EOD)
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Alert_LPNCountsMismatch_EOD',
       @vJobDescription       = 'Alert if there are any count discrepancies on LPNs (Other than Logical LPNs)(EOD)',
       --This should run once a day and it should be at 08.30 PM - Might change, and
       --All other parameters will be default to run
       @vJobEnabled           = null,
       @vFreqType             = null,   @vFreqInterval         = null,
       @vFreqSubDayType       = 1,      @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,   @vFreqRecurrenceFactor = null,
       @vStartTime            = 203000, @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_LPNCountsMismatch',          'exec pr_Alerts_LPNCountsMismatch ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_LPNDiscrepancies
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alert_LPNDiscrepancies',
       @vJobDescription     = 'Alert if there are Invalid Ownership LPNs and NumCases',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = null,
       @vFreqType           = 4,     @vFreqInterval       = 1,
       @vFreqSubDayType     = 8,     @vFreqSubDayInterval = 1,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_LPNDiscrepancies',           'exec pr_Alerts_LPNDiscrepancies ''~BU~''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_MisMatchOfODUnitsAssigned
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alert_MisMatchOfODUnitsAssigned',
       @vJobDescription     = 'Alert if there are any mismatches of Order details assigned v Task and LPN details',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_MisMatchOfODUnitsAssigned',  'exec pr_Alerts_MisMatchOfODUnitsAssigned ''~BU~'', ''cIMSAgent'', 6');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_MisMatchOfODUnitsAssigned (Consolidated alert by EOD)
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Alert_MisMatchOfODUnitsAssigned_EOD',
       @vJobDescription       = 'Alert if there are any mismatches of Order details assigned v Task and LPN details (EOD)',
       --This should run once a day and it should be at 08.30 PM - Might change, and
       --All other parameters will be default to run
       @vJobEnabled           = null,
       @vFreqType             = null,   @vFreqInterval         = null,
       @vFreqSubDayType       = 1,      @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,   @vFreqRecurrenceFactor = null,
       @vStartTime            = 203000, @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_MisMatchOfODUnitsAssigned',  'exec pr_Alerts_MisMatchOfODUnitsAssigned ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_MissingExportBatches
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alert_MissingExportBatches',
       @vJobDescription     = 'send Alerts if there are any missing Export Batches',
       @vJobEnabled         = null,
       @vFreqType           = null,   @vFreqInterval       = null,
       @vFreqSubDayType     = null,   @vFreqSubDayInterval = null,
       @vStartTime          = null,   @vEndTime            = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_MissingExportBatches',       'exec pr_Alerts_MissingExportBatches ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_OpenOrdersSummary
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alert_OpenOrdersSummary',
       @vJobDescription     = 'Alert to show the summary of open orders',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_OpenOrdersSummary',          'exec pr_Alerts_OpenOrdersSummary ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - pr_Alerts_Orders_StuckInDownload
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alerts_Orders_StuckInDownload',
       @vJobDescription     = 'Alert if there are any orders not pre-processed',
      -- All other parameters are default params to run job all day long for every 1 hours
       @vJobEnabled           = 1,
       @vFreqType             = 4,       @vFreqInterval         = 1,
       @vFreqSubDayType       = 8,       @vFreqSubDayInterval   = 1,
       @vFreqRelativeInterval = null,    @vFreqRecurrenceFactor = 1,
       @vStartTime            = null,    @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                                 Command)
values ('~DBName~_Alerts_Orders_StuckInDownload', 'exec pr_Alerts_Orders_StuckInDownload ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_OrphanDLines
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alert_OrphanDLines',
       @vJobDescription     = 'Alert if there are any orphan D lines in picklanes',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Alert_OrphanDLines',     'exec pr_Alerts_OrphanDLines ''~BU~'', ''cIMSAgent'', 6');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_OrphanDLines (Consolidated alert by EOD)
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Alert_OrphanDLines_EOD',
       @vJobDescription       = 'Alert if there are any orphan D lines in picklanes (EOD)',
       --This should run once a day and it should be at 08.30 PM - Might change, and
       --All other parameters will be default to run
       @vJobEnabled           = null,
       @vFreqType             = null,   @vFreqInterval         = null,
       @vFreqSubDayType       = 1,      @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,   @vFreqRecurrenceFactor = null,
       @vStartTime            = 203000, @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Alert_OrphanDLines',     'exec pr_Alerts_OrphanDLines ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_SplitTaskDetails
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alert_SplitTaskDetails',
       @vJobDescription     = 'Alert if there are any mismatches while splitting of task details',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = null,
       @vFreqType           = null,  @vFreqInterval       = null,
       @vFreqSubDayType     = null,  @vFreqSubDayInterval = null,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_SplitTaskDetails',           'exec pr_Alerts_SplitTaskDetails ''~BU~'', ''cIMSAgent'', 6');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_WavesNotAllocated
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alert_WavesNotAllocated',
       @vJobDescription     = 'Alert if there are any waves not allocated even there is inventory',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_WavesNotAllocated',          'exec pr_Alerts_WavesNotAllocated ''~BU~'', ''cIMSAgent'', 6');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_WavesNotAllocated (Consolidated alert by EOD)
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Alert_WavesNotAllocated_EOD',
       @vJobDescription       = 'Alert if there are any waves not allocated even there is inventory (EOD)',
       --This should run once a day and it should be at 08.30 PM - Might change, and
       --All other parameters will be default to run
       @vJobEnabled           = null,
       @vFreqType             = null,   @vFreqInterval         = null,
       @vFreqSubDayType       = 1,      @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,   @vFreqRecurrenceFactor = null,
       @vStartTime            = 203000, @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alert_WavesNotAllocated',          'exec pr_Alerts_WavesNotAllocated ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alerts if TransactionStatus is Fail/Fatal on APIOutboundTransactions
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Alerts_APIOutboundTransactions',
       @vJobDescription       = 'Alert if there are any Failed/Fatal transactions in APIOutboundTransactions',
      -- Occurs every day every 1 hour(s) between 00:00:00 and 23:59:59.
       @vJobEnabled           = null,
       @vSchedule             = 'Daily||Every1Hours';

insert into @ttJobStepsInfo
       (StepName,                                             Command)
values ('~DBName~_Alerts_APIOutboundTransactions_Fail',       'exec pr_Alerts_APIOutboundTransactions ''~BU~'', ''cIMSAgent'', null, null, ''Fail'''),
       ('~DBName~_Alerts_APIOutboundTransactions_Fatal',      'exec pr_Alerts_APIOutboundTransactions ''~BU~'', ''cIMSAgent'', null, null, ''Fatal''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit, @vSchedule;

/*------------------------------------------------------------------------------
 * Interface Errors Jobs -
 *----------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Alerts_InterfaceErrors',
       @vJobDescription       = 'Send email when entities which are modified in last 30 days',
      -- All other parameters are default params to run job for every month once at 2:10 am
       @vJobEnabled           = 1,
       @vFreqType             = 16,         @vFreqInterval         = 1, /* Monthly on first day of month */
       @vFreqSubDayType       = 1,          @vFreqSubDayInterval   = 5,
       @vFreqRelativeInterval = 1,          @vFreqRecurrenceFactor = 1,
       @vStartTime            = 021000,     @vEndTime              = null; /* Run at 2:10 am */

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Alerts_InterfaceErrors','exec pr_Alerts_InterfaceErrors ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Alert Jobs  - Alert_LoadsNotShipped
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alert_LoadsNotShipped',
       @vJobDescription     = 'Alert if there are any Loads which are not being shipped from last 30 minutes',
      -- All other parameters are default params to run job all day long for every 7 minutes
       @vJobEnabled           = null,
       @vFreqType             = 4,     @vFreqInterval         = 1,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = 7,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = 1,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Alerts_LoadsNotShipped',          'exec pr_Alerts_LoadsNotShipped ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 * Shipment Notification
 *----------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alerts_ShipmentNotification',
       @vJobDescription     = 'send the shipment notification to customer',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = null,
       @vFreqType           = null,  @vFreqInterval       = null,
       @vFreqSubDayType     = null,  @vFreqSubDayInterval = null,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Alerts_ShipmentNotification',   'exec pr_Alerts_ShipmentNotification ''~BU~'', ''cIMSAgent''')

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 * Shipment Notification Daily summary
 *----------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Alerts_ShipmentNotification_Summary',
       @vJobDescription     = 'send the shipment notification summary to support',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = null,
       @vSchedule             ='Daily||Every5Minutes';

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Alerts_ShipmentNotificationDailySummary',   'exec pr_Alerts_ShipmentNotification_Summary ''~BU~'', ''cIMSAgent''')

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit, @vSchedule;


/*------------------------------------------------------------------------------
 Job to update Order Delivery Status for an Order
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Order_OrderDeliveryStatus',
       @vJobDescription     = 'Update Order Delivery Status for an Order whether it is Delivered or Not Delivered',
      -- All other parameters are default params to run job once in a day at 1AM
       @vJobEnabled         = null,
       @vSchedule             ='Daily||SpecificTime|010000';

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_OrderDeliveryStatus',      'exec pr_OrderHeaders_OrderDeliveryStatus ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit, @vSchedule;

/*******************************************************************************
  Data Validation/Verification Jobs
*******************************************************************************/

/*******************************************************************************
  DB 2 DB Integration Jobs
*******************************************************************************/
/*------------------------------------------------------------------------------
 Import Jobs  -SKUs
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Import_SKUs',
       @vJobDescription     = 'Import unprocessed SKUs/UPCs From CIMSDE to CIMS',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Import_SKUs',            'exec pr_Imports_CIMSDE_ImportData ''SKU'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_UPCs',            'exec pr_Imports_CIMSDE_ImportData ''UPC'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Import Jobs - Contacts
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Import_Contacts',
       @vJobDescription     = 'Import unprocessed contacts From CIMSDE to CIMS',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Import_Contacts',        'exec pr_Imports_CIMSDE_ImportData ''CNT'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Consolidate Orders Job
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Import_ConsolidateOrders',
       @vJobDescription     = 'Consolidates the Orders',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = 0,
       @vFreqType           = null,       @vFreqInterval       = null,
       @vFreqSubDayType     = null,       @vFreqSubDayInterval = null,
       @vStartTime          = 000000,     @vEndTime            = 235900;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Import_ConsolidateOrders', 'exec pr_Imports_OrdersConsolidation ''~BU~''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Import Jobs - Sales Orders
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Import_SalesOrders',
       @vJobDescription       = 'Import unprocessed Orders, Details & Notes From CIMSDE to CIMS',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Import_SKUs',            'exec pr_Imports_CIMSDE_ImportData ''SKU'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_OrderHeaders',    'exec pr_Imports_CIMSDE_ImportData ''OH'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_OrderDetails',    'exec pr_Imports_CIMSDE_ImportData ''OD'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_Notes',           'exec pr_Imports_CIMSDE_ImportData ''NOTE'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 * Import Jobs - Import Receipts
 *----------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Import_Receipts',
       @vJobDescription       = 'Import unprocessed Receipts and Details from CIMSDE to CIMS',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = 0,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Import_SKUs',            'exec pr_Imports_CIMSDE_ImportData ''SKU'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_ReceiptHeaders',  'exec pr_Imports_CIMSDE_ImportData ''RH'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_ReceiptDetails',  'exec pr_Imports_CIMSDE_ImportData ''RD'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Import Jobs - Import Receipts and ASNs
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Import_ReceiptsandASNs',
       @vJobDescription     = 'Import unprocessed Receipts and Details from CIMSDE to CIMS',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = null,
       @vFreqType           = null,  @vFreqInterval       = null,
       @vFreqSubDayType     = null,  @vFreqSubDayInterval = null,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Import_SKUs',              'exec pr_Imports_CIMSDE_ImportData ''SKU'',   ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_ReceiptHeaders',    'exec pr_Imports_CIMSDE_ImportData ''RH'',    ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_ReceiptDetails',    'exec pr_Imports_CIMSDE_ImportData ''RD'',    ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_ASNLPNHeaders',     'exec pr_Imports_CIMSDE_ImportData ''ASNLH'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_ASNLPNDetails',     'exec pr_Imports_CIMSDE_ImportData ''ASNLD'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Import Jobs - Import Inventory Adjustments Transfers
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Import_InvAdjustments_Transfers',
       @vJobDescription     = 'Process all unprocessed Inventory Adjustments from CIMSDE in CIMS',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = 0,
       @vFreqType             = null,    @vFreqInterval         = null,
       @vFreqSubDayType       = null,    @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,    @vFreqRecurrenceFactor = 1,
       @vStartTime            = 000400,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Import_SKUs',                      'exec pr_Imports_CIMSDE_ImportData ''SKU'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_InvAdjustments_Transfers',  'exec pr_Imports_InvAdjustments_Transfers ''TRFINV'', null, ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Import Jobs - Import Inventory Adjustments
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Import_InvAdjustments',
       @vJobDescription     = 'Process all unprocessed Inventory Adjustments from CIMSDE in CIMS',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = 0,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Import_InvAdjustments',  'exec pr_Imports_InventoryAdjustments ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Import Jobs - Receipts Pre-Process
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_ReceiptsPreProcess',
       @vJobDescription     = 'Pre-Process the Receipts which were recently imported into CIMS',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_PreProcessReceipts',     'exec pr_Imports_PreprocessReceipts');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Job for UPS Accounts Acess Token Create
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_API_UPSAccessTokenValidateAndCreate',
       @vJobDescription     = 'Create the UPS API Acess Token',
       -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = 1,
       @vFreqType             = 4,  @vFreqInterval         = 1,
       @vFreqSubDayType       = 4,  @vFreqSubDayInterval   = 5,
       @vFreqRelativeInterval = 0,  @vFreqRecurrenceFactor = 0,
       @vStartTime            = null,  @vEndTime              = null;
insert into @ttJobStepsInfo
       (StepName,                             Command)
values ('~DBName~_API_UPSAccessTokenCreate',  'exec pr_API_UPS2_AccessToken_ValidateAndCreate 1800 /* BufferSecondsToRefresh */, ''CLR'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;
/*------------------------------------------------------------------------------
  Job for FedEx Accounts Acess Token Create
  Note: FedEx API OAUTH Token expires in 3599 seconds (60 mins)
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_API_FedExAccessTokenValidateAndCreate',
       @vJobDescription     = 'Generate the FedEx API Acess Token',
       -- All other parameters are default params to run job all day long for every 15 minutes
       @vJobEnabled           = 1,
       @vFreqType             = 4,  @vFreqInterval         = 1,
       @vFreqSubDayType       = 4,  @vFreqSubDayInterval   = 15,
       @vFreqRelativeInterval = 0,  @vFreqRecurrenceFactor = 0,
       @vStartTime            = null,  @vEndTime              = null;
insert into @ttJobStepsInfo
       (StepName,                                 Command)
values ('~DBName~_API_FedEx_AccessTokenGenerate', 'exec pr_API_FedEx2_AccessToken_ValidateAndGenerate 1800 /* BufferSecondsToRefresh */, ''CLR'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;
/*------------------------------------------------------------------------------
  Job for UPS Accounts Acess Token Refresh
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_API_UPSAccessTokenRefresh',
       @vJobDescription     = 'Refresh the UPS API Acess Token',
       -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = 0,
       @vFreqType             = 4,     @vFreqInterval         = 1,
       @vFreqSubDayType       = 4,     @vFreqSubDayInterval   = 5,
       @vFreqRelativeInterval = 0,     @vFreqRecurrenceFactor = 0,
       @vStartTime            = null,  @vEndTime              = null;
insert into @ttJobStepsInfo
       (StepName,                             Command)
values ('~DBName~_API_UPSAccessTokenRefresh', 'exec pr_API_UPS2_AcessToken_ValidateAndRefresh 300 /* BufferSecondsToRefresh */, ''CLR'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Import Jobs - Import Carton Types
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Import_CartonTypes',
       @vJobDescription     = 'Import unprocessed Carton types from CIMSDE to CIMS',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Import_CartonTypes',     'exec pr_Imports_CIMSDE_ImportData ''CT'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Import Jobs - Import ASNs
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Import_ASNs',
       @vJobDescription     = 'Import unprocessed ASNs from CIMSDE to CIMS',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = 0,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Import_SKUs',            'exec pr_Imports_CIMSDE_ImportData ''SKU'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_ASNs',            'exec pr_Imports_CIMSDE_ImportData ''ASNLH'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_ASNLPNDetails',   'exec pr_Imports_CIMSDE_ImportData ''ASNLD'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Import Jobs - Import SKUPrePacks
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Import_SKUPrePacks',
       @vJobDescription     = 'Import unprocessed SKU PrePacks from CIMSDE to CIMS',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Import_SKUPrePacks',     'exec pr_Imports_CIMSDE_ImportData ''SMP'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
   Import_RemoveTempTables : Remove Temparory tables which is created in import process
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_File_Import_RemoveTempTables',
       @vJobDescription       = 'Job to remove Temparory tables which is created during import process',
       --This should run once a day and it should be at 23:30:00.
       @vJobEnabled           = 1,
       @vFreqType             = 4,       @vFreqInterval         = 1,
       @vFreqSubDayType       = 1,       @vFreqSubDayInterval   = 1,
       @vFreqRelativeInterval = 0,       @vFreqRecurrenceFactor = 0,
       @vStartTime            = 233000,  @vEndTime              = 235959;

insert into @ttJobStepsInfo
       (StepName,                               Command)
values ('~DBName~_Import_RemoveTempTables',    'exec pr_File_Import_RemoveTempTables ''SPL_SKUPriceList'', ''~BU~''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vFreqRelativeInterval, @vFreqRecurrenceFactor, @vStartTime, @vEndTime;

/*******************************************************************************
 Export Jobs
********************************************************************************/

/*------------------------------------------------------------------------------
 Export Jobs - Export Generate batches
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Export_GenerateBatches',
       @vJobDescription     = 'Generate Batches for unprocessed Data Transactions from CIMS to CIMSDE',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = 1,
       @vFreqType           = null,  @vFreqInterval       = null,
       @vFreqSubDayType     = null,  @vFreqSubDayInterval = null,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Export_GenerateBatches',   'exec pr_Exports_GenerateBatches null, null, null, null, ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Export Jobs - Export Carrier Tracking Info
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Export_CarrierTrackingInfo',
       @vJobDescription     = 'Export Carrier Tracking Info from CIMS to CIMSDE',
      -- All other parameters are default params to run job all day long for every 30 minutes
       @vJobEnabled           = null,
       @vFreqType             = 4,       @vFreqInterval         = 1,
       @vFreqSubDayType       = 4,       @vFreqSubDayInterval   = 30,
       @vFreqRelativeInterval = 0,       @vFreqRecurrenceFactor = 0,
       @vStartTime            = 220000,  @vEndTime              = 235959;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Export_CarrierTrackingInfo',            'exec pr_Exports_CIMSDE_ExportCarrierTrackingInfo ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Export Jobs - Export Data Transactions
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Export_DataTransactions',
       @vJobDescription     = 'Export unprocessed Data Transactions from CIMS to CIMSDE',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Export_Data',            'exec pr_Exports_CIMSDE_ExportData null, null, null, ''HOST'' /* SourceSystem */, ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Export Jobs - Export InvCh Transactions from CIMS to CIMSDE
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Export_DataTransactions_InvCh',
       @vJobDescription     = 'Export unprocessed InvCh transactions from CIMS to CIMSDE',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,   @vFreqInterval         = null,
       @vFreqSubDayType       = null,   @vFreqSubDayInterval   = null,
       @vStartTime            = 000030, @vEndTime              = 235959;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Export_Data',              'exec pr_Exports_CIMSDE_ExportData ''InvCh'' /* Transtype */, null, null, ''HOST'' /* SourceSystem */, ''~BU~'', ''cIMSAgent2''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Export Jobs - Export PTCancel Transactions from CIMS to CIMSDE
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Export_DataTransactions_PTCancel',
       @vJobDescription     = 'Export unprocessed PTCancel transactions from CIMS to CIMSDE',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = null,
       @vFreqType           = null,  @vFreqInterval       = null,
       @vFreqSubDayType     = null,  @vFreqSubDayInterval = null,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Export_Data',              'exec pr_Exports_CIMSDE_ExportData ''PTCancel'' /* TransType */, null, null, ''HOST'' /* SourceSystem */, ''~BU~'', ''cIMSAgent2''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Export Jobs - Export PTStatus Transactions from CIMS to CIMSDE
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Export_DataTransactions_PTStatus',
       @vJobDescription     = 'Export unprocessed PTStatus transactions from CIMS to CIMSDE',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = null,
       @vFreqType           = null,  @vFreqInterval       = null,
       @vFreqSubDayType     = null,  @vFreqSubDayInterval = 1,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Export_Data',              'exec pr_Exports_CIMSDE_ExportData ''PTStatus'' /* TransType */, null, null, ''HOST'' /* SourceSystem */, ''~BU~'', ''cIMSAgent2''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Export Jobs - Export PTException Transactions from CIMS to CIMSDE
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Export_DataTransactions_PTError',
       @vJobDescription     = 'Export unprocessed PTError transactions from CIMS to CIMSDE',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = null,
       @vSchedule           ='Daily||Every5Minutes';

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Export_Data',              'exec pr_Exports_CIMSDE_ExportData ''PTError'' /* TransType */, null, null, ''HOST'' /* SourceSystem */, ''~BU~'', ''cIMSAgent2''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,  @vSchedule;

/*------------------------------------------------------------------------------
 Export Jobs - Export Recv Transactions from CIMS to CIMSDE
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Export_DataTransactions_Recv',
       @vJobDescription       = 'Export unprocessed Recv transactions from CIMS to CIMSDE',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,   @vFreqInterval         = null,
       @vFreqSubDayType       = null,   @vFreqSubDayInterval   = null,
       @vStartTime            = 000015, @vEndTime              = 235959;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Export_Data',              'exec pr_Exports_CIMSDE_ExportData ''Recv'' /* TransType */, null, null, ''HOST'' /* SourceSystem */, ''~BU~'', ''cIMSAgent2''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,@vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Export Jobs - Export Ship Transactions from CIMS to CIMSDE
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Export_DataTransactions_Ship',
       @vJobDescription       = 'Export unprocessed Ship transactions from CIMS to CIMSDE',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = 1,
       @vStartTime            = 000000,@vEndTime              = 235959;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Export_Data',              'exec pr_Exports_CIMSDE_ExportData ''Ship'' /* TransType */, null, null, ''HOST'' /* SourceSystem */, ''~BU~'', ''cIMSAgent2''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Export Jobs - Export WhXfer Transactions from CIMS to CIMSDE
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Export_DataTransactions_WhXFer',
       @vJobDescription     = 'Export unprocessed WhXFer transactions from CIMS to CIMSDE',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = null,
       @vFreqType           = null,  @vFreqInterval       = null,
       @vFreqSubDayType     = null,  @vFreqSubDayInterval = null,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Export_Data',              'exec pr_Exports_CIMSDE_ExportData ''WhXFer'' /* TransType */, null, null, ''HOST'' /* SourceSystem */, ''~BU~'', ''cIMSAgent2''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Export Jobs - Export EDI753 Transactions from CIMS to CIMSDE
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;
select @vJobId = null;

select @vJobName            = '~DBName~_Export_DataTransactions_EDI753',
       @vJobDescription     = 'Export unprocessed EDI753 transactions from CIMS to CIMSDE',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = 0,
       @vFreqType           = null,  @vFreqInterval       = 1,
       @vFreqSubDayType     = null,  @vFreqSubDayInterval = null,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Export_Data',              'exec pr_Exports_CIMSDE_ExportData ''EDI753'' /* TransType */, null, null, ''HOST'' /* SourceSystem */, ''~BU~'', ''cIMSAgent2''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Export Jobs - Export OnHand Inventory
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Export_OnHandInventory',
       @vJobDescription       = 'Export OnHandInventory Data from CIMS to CIMSDE on daily base',
       --This should run once a day and it should be at 10.30 PM - Might change, and
       --All other parameters will be default to run
       @vJobEnabled           = null,
       @vFreqType             = 4,                 @vFreqInterval         = 1,
       @vFreqSubDayType       = 1,                 @vFreqSubDayInterval   = 5,  /* once a day at 22:30 */
       @vFreqRelativeInterval = 223000,            @vFreqRecurrenceFactor = 0,
       @vStartTime            = 0,                 @vEndTime              = 235959;

insert into @ttJobStepsInfo
       (StepName,                            Command)
values ('~DBName~_Update_ProcessedData',     'Update CIMSDE_ExportOnhandInventory set ExchangeStatus = ''P'' where ExchangeStatus = ''N'''),
       ('~DBName~_Export_OnHandInventory',   'exec pr_Exports_CIMSDE_ExportOnhandInventory null /* Warehouse */, null /* Ownership */, ''HOST'' /* SourceSystem */, ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Export Jobs - Export OpenOrders
                This should run once a day and it should be at 10.30 PM - Might change
 *----------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Export_OpenOrders',
       @vJobDescription       = 'Export Open Orders from CIMS to CIMSDE on daily base',
       --This should run once a day and it should be at 10.30 PM - Might change, and
       --All other parameters will be default to run
       @vJobEnabled           = null,
       @vFreqType             = null,   @vFreqInterval         = null,
       @vFreqSubDayType       =    1,   @vFreqSubDayInterval   = null,  /* once a day at 22:30 */
       @vFreqRelativeInterval = null,   @vFreqRecurrenceFactor = null,
       @vStartTime            = 223000, @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Export_OpenOrders',      'exec pr_Exports_CIMSDE_ExportOpenOrders ''HOST'' /* SourceSystem */, ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Export Jobs - Export OpenReceipts
                This should run once a day and it should be at 10.30 PM - Might change
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Export_OpenReceipts',
       @vJobDescription       = 'Export Open Receipts from CIMS to CIMSDE on daily base',
       --This should run once a day and it should be at 10.30 PM - Might change, and
       --All other parameters will be default to run
       @vJobEnabled           = null,
       @vFreqType             = null,   @vFreqInterval         = null,
       @vFreqSubDayType       =    1,   @vFreqSubDayInterval   = null,  /* once a day at 22:30 */
       @vFreqRelativeInterval = null,   @vFreqRecurrenceFactor = null,
       @vStartTime            = 223000, @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Export_OpenReceipts',    'exec pr_Exports_CIMSDE_ExportOpenReceipts ''HOST'' /* SourceSystem */, ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Export Jobs - Export ShippedLoads
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Export_ShippedLoads',
       @vJobDescription       = 'Export Shipped Loads from CIMS to CIMSDE on daily base',
       --This should run once a day and it should be at 10.30 PM - Might change, and
       --All other parameters will be default to run
       @vJobEnabled           = null,
       @vFreqType             = null,   @vFreqInterval         = null,
       @vFreqSubDayType       =    1,   @vFreqSubDayInterval   = null,   /* once a day at 22:30 */
       @vFreqRelativeInterval = null,   @vFreqRecurrenceFactor = null,
       @vStartTime            = 223000, @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_Export_ShippedLoads',    'exec pr_Exports_CIMSDE_ExportShippedLoads ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*******************************************************************************
 Inventory Snapshot, Compare & Alert jobs
********************************************************************************/
/*------------------------------------------------------------------------------
 Create Inventory Snapshot
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Inventory_CreateInvSnapshot',
       @vJobDescription       = 'To Show InventorySnapshots',
      -- All other parameters are default params to run job evrey day at 11.00PM
       @vJobEnabled           = 0,
       @vFreqType             = 4,         @vFreqInterval         = 1,
       @vFreqSubDayType       = 1,         @vFreqSubDayInterval   = 5,
       @vFreqRelativeInterval = 110000,    @vFreqRecurrenceFactor = 0,
       @vStartTime            = 230000,    @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Inventory_CreateInvSnapshot',          'exec pr_Inventory_CreateInvSnapshot ''~BU~'', ''cIMSAgent'', ''EndOfDay'''),
       ('Create detailed snapshot by LPN for debugging', 'exec pr_Inventory_CreateInvSnapshot ''~BU~'',, ''cIMSAgent'', ''Adhoc'', @Mode = ''LPN''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Create Inventory Comparison
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Inventory_CreateInvComparison',
       @vJobDescription       = null,
      -- Occurs every day at 11:10:00PM.
       @vJobEnabled           = 0,
       @vFreqType             = 4,         @vFreqInterval         = 1,
       @vFreqSubDayType       = 1,         @vFreqSubDayInterval   = 0,
       @vFreqRelativeInterval = 0,         @vFreqRecurrenceFactor = 1,
       @vStartTime            = 231000,    @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                             Command)
values ('~DBName~_InventoryCreateComparison', 'exec pr_Inventory_CreateComparison ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_AlertInventoryVariance',    'exec pr_Alerts_InventoryVariance ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Inventory Variance - Alerrt monthly
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Alert_InventoryDiscrepancyMonthly',
       @vJobDescription       = null,
      -- Occurs every month on 25th at 11:30:00PM to send out an alert even if there is no data
       @vJobEnabled           = 0,
       @vFreqType             = 16,        @vFreqInterval         = 25,
       @vFreqSubDayType       = 1,         @vFreqSubDayInterval   = 0,
       @vFreqRelativeInterval = 0,         @vFreqRecurrenceFactor = 1,
       @vStartTime            = 233000,    @vEndTime              = 235900;

insert into @ttJobStepsInfo
       (StepName,                             Command)
values ('~DBName~_AlertInventoryDiscrepancy', 'exec pr_Alerts_InventoryDiscrepancy ''~BU~'', ''cIMSAgent'', null, ''N'', ''Y''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*******************************************************************************
 Loads Jobs
********************************************************************************/

/*------------------------------------------------------------------------------
   Loads Jobs : Auto Create Express Loads
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;
select @vJobId = null;

select @vJobName            = '~DBName~_Loads_AutoCreate_Express',
       @vJobDescription     = 'Loads: Auto create for UPS Express and FedEx Express',
       @vJobEnabled         = 1, /* Enable the job */
       @vFreqType           = 0 /* Schedule added later */,
       -- All other parameters are default params to run job every day on schedule timings.
       @vFreqInterval       = null,
       @vFreqSubDayType     = null,  @vFreqSubDayInterval = null,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
             (StepName,                           Command)
      values ('Cancel unused Auto created Loads', 'exec pr_Loads_AutoCancel ''UPSE,FDEN'', ''~BU~'', ''cIMSAgent'''),
             ('Load for UPS Express',             'declare @today tdatetime = getdate(); exec pr_Load_CreateNew ''cIMSAgent'', ''~BU~'', ''UPSE'', @DesiredShipDate = @Today, @FromWarehouse = ''04'''),
             ('Load for FedEx Express',           'declare @today tdatetime = getdate(); exec pr_Load_CreateNew ''cIMSAgent'', ''~BU~'', ''FDEN'', @DesiredShipDate = @Today, @FromWarehouse = ''04''');

/* Create Job without the schedule */
exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime, @JobId = @vJobId output;

/* Schedule the job at 6AM once a day */
exec pr_Jobs_AddJobSchedule @vJobId, 'Express Loads at 6:00AM', 4, 1, 1, 0,  null, null, 060000, 235959  /* 6:00AM */

/*------------------------------------------------------------------------------
   Loads Jobs : Auto Create Ground Loads
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;
select @vJobId = null;

select @vJobName            = '~DBName~_Loads_AutoCreateLoads_Ground',
       @vJobDescription     = 'Loads: Auto create for UPS Ground and FedEx Ground',
       -- All other parameters are default params to run job every day on schedule timings.
       @vJobEnabled         = 1, /* Enable the job */
       @vFreqType           = 0 /* Schedule added later */,
       -- All other parameters are default params to run job every day on schedule timings.
       @vFreqInterval       = null,
       @vFreqSubDayType     = null,  @vFreqSubDayInterval = null,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
             (StepName,                           Command)
      values ('Cancel unused Auto created Loads', 'exec pr_Loads_AutoCancel ''UPSN,FDEG'', ''~BU~'', ''cIMSAgent'''),
             ('Load for UPS Groud',               'declare @today tdatetime = getdate(); exec pr_Load_CreateNew ''cIMSAgent'', ''~BU~'', ''UPSN'', @DesiredShipDate = @Today, @FromWarehouse = ''04'''),
             ('Load for FedEx Ground',            'declare @today tdatetime = getdate(); exec pr_Load_CreateNew ''cIMSAgent'', ''~BU~'', ''FDEG'', @DesiredShipDate = @Today, @FromWarehouse = ''04''');

/* Create Job without the schedule */
exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime, @JobId = @vJobId output;

/* Schedule the job at 6 am once a day */
exec pr_Jobs_AddJobSchedule @vJobId, 'Ground Loads at 6:00AM', 4, 1, 1, 0,  null, null, 060000, 235959  /* 06:00 AM */

/*------------------------------------------------------------------------------
   Loads Jobs : Automatically Add Orders to Load based on ShipVia
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;
select @vJobId = null;

select @vJobName            = '~DBName~_Loads_AutoBuild',
       @vJobDescription     = 'Loads: Automatically add Orders to the Load based on ShipVia',
       @vJobEnabled         = null,
       @vFreqType           = null,  @vFreqInterval       = null,
       @vFreqSubDayType     = null,  @vFreqSubDayInterval = null,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
       (StepName,                               Command)
values ('~DBName~_Loads_AutoAddOrderstoLoad',   'exec pr_Loads_AutoBuild default /* Operation */, null /* Load Number */, ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
   Loads Jobs : Auto Ship Loads
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;
select @vJobId = null;

select @vJobName            = '~DBName~_Loads_Auto_Ship',
       @vJobDescription     = 'Automatically Ship the Loads',
      -- All other parameters are default params to run job every day on schedule timings.
       @vJobEnabled         = 0,
       @vFreqType           = 0,     @vFreqInterval       = null,
       @vFreqSubDayType     = null,  @vFreqSubDayInterval = null,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
             (StepName,                          Command)
      values ('~DBName~_Loads_Auto_Ship',        'exec pr_Loads_AutoShip ''~BU~'', ''CIMSAgent'''),
             ('~DBName~_Entities_RecalcCounts',  'exec pr_Entities_RecalcCounts ''~BU~'', ''cIMSAgent''');

/* Create Job without the schedule */
exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime, @JobId =  @vJobId output;

/* Schedule the job at 5PM */
exec pr_Jobs_AddJobSchedule @vJobId, 'Auto ship Loads at 5PM', 4, 1, 1, 0,  null, null, 170000, 235959  /* 05:00PM */

/*******************************************************************************
 DCMS Jobs
********************************************************************************/

/*------------------------------------------------------------------------------
  Router Jobs - Process Router Confirmations
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Router_ProcessConfirmations',
       @vJobDescription       = 'Process Router Confirmations',
      -- All other parameters are default params to run job all day long for every 1 minute
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = 1,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Router_ProcessConfirmations',      'exec pr_Router_ProcessConfirmations ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Router Jobs - Router Get Confirmations
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Router_DCMS_GetConfirmations',
       @vJobDescription       = 'Process Router Confirmations',
      -- All other parameters are default params to run job all day long for every 1 minute
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = 1,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Router_DCMS_GetConfirmations',     'exec pr_Router_DCMS_GetConfirmations ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Router Jobs - Export Router Instructions
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Router_DCMS_ExportInstructions',
       @vJobDescription       = 'Process Router Instructions',
      -- All other parameters are default params to run job all day long for every minute
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = null,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = 1,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Router_DCMS_ExportInstructions',   'exec pr_Router_DCMS_ExportInstructions');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  PandA Jobs - Process Panda Pallets for Amazon
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_PandA_ProcessPandAPallets',
       @vJobDescription     = 'Process PandA Pallets',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = 1,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_PandA_ProcessPandAPallets',        'exec pr_PandA_ProcessPandaPallets null, default, ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  PandA Jobs - Export Panda Pallets to DCMS
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_PandA_ExportPallets',
       @vJobDescription       = 'Export Pallets to Panda',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled           = null,
       @vFreqType             = null,  @vFreqInterval         = 1,
       @vFreqSubDayType       = null,  @vFreqSubDayInterval   = null,
       @vFreqRelativeInterval = null,  @vFreqRecurrenceFactor = null,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                          Command)
values ('~DBName~_PandA_ExportPallets',    'exec pr_PandA_ExportPallets ''Amazon'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Replenishments - Min-Max Replenishment for the Picklanes
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Replenish_MinMax_Picklanes',
       @vJobDescription     = 'Min-Max Replenishment for the Picklanes',
      -- This Job will run daily morning at 6.00 AM
       @vJobEnabled         = 0,
       @vFreqType           = null,    @vFreqInterval       = null,
       @vFreqSubDayType     = 1,       @vFreqSubDayInterval = null,
       @vStartTime          = 060000,  @vEndTime            = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Replenish_MinMax_Picklanes',       'exec pr_Replenish_AutoReplenish ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*******************************************************************************
  Job for Auto waving
********************************************************************************/
/*------------------------------------------------------------------------------
  Auto waving for Single Line Orders
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Wave_AutoGenerate_SLB',
       @vJobDescription     = 'Auto waving for Single Line Orders',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = null,
       @vFreqType           = null,  @vFreqInterval       = null,
       @vFreqSubDayType     = null,  @vFreqSubDayInterval = null,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Wave_AutoGenerate_SLB',            'exec pr_Wave_AutoGenerateWaves ''Wave_AutoGeneration'', ''~BU~''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Waves_ReturnOrdersToOpenPool
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Waves_ReturnOrdersToOpenPool',
       @vJobDescription     = 'Remove all Orders from Wave, which do not have any picks on the Wave',
      -- Occurs every day every 1 hour(s) between 00:00:00 and 23:59:59.
       @vJobEnabled           = null,
       @vFreqType             = 4,     @vFreqInterval         = 1,
       @vFreqSubDayType       = 8,     @vFreqSubDayInterval   = 1,
       @vFreqRelativeInterval = 0,     @vFreqRecurrenceFactor = 1,
       @vStartTime            = null,  @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                 Command)
values ('~DBName~_Waves_ReturnOrdersToOpenPool',  'exec pr_Waves_ReturnOrdersToOpenPool ''Wave_ReturnOrdersToOpenPool'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval, @vFreqRelativeInterval, @vFreqRecurrenceFactor,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
 Tasks - Update Print Status
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName              = '~DBName~_Tasks_RecomputePrintStatus',
       @vJobDescription       = 'Tasks: Recompute Print Status',
      -- All other parameters are default params to run job all day long for every 5 minutes starting at 12:03:05 am
       @vJobEnabled           = 0,
       @vSchedule             = 'Daily||Every5Minutes|000305'

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_Tasks_RecomputePrintStatus',       'exec pr_Tasks_RecomputePrintStatus ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit, @vSchedule;

/*------------------------------------------------------------------------------
  Activation - Auto activation of FromLPNs matching ToLPNs

  Every day, every 10 mins between 7 AM & 7 PM Server time
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_Reservation_AutoActivation',
       @vJobDescription     = 'execute Auto activation',
      -- All other parameters are default params to run job all day long for every 2 hours
       @vJobEnabled         = 1,
       @vFreqType           = 4,      @vFreqInterval       = 1,
       @vFreqSubDayType     = 4,      @vFreqSubDayInterval = 5,
       @vStartTime          = 070000, @vEndTime            = 190000;

insert into @ttJobStepsInfo
       (StepName,                                              Command)
values ('~DBName~_Reservation_AutoActivation',                 'exec pr_Reservation_AutoActivation ''04,08'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   null /* FreqRelativeInterval */, null /* FreqRecurrenceFactor */,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  LPNTransfers_PrepareforReceipt : Clear the Load information on the Intransit LPN's
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_LPNTransfers_PrepareForReceipt',
       @vJobDescription     = 'Prepare the shipped transfer LPNs for Receivings',
       --This should run once a day and it should be at 10.30 PM - Might change, and
       --All other parameters will be default to run
       @vJobEnabled           = null,
       @vFreqType             = null,   @vFreqInterval         = null,
       @vFreqSubDayType       =    1,   @vFreqSubDayInterval   = null,  /* once a day at 22:30 */
       @vFreqRelativeInterval = null,   @vFreqRecurrenceFactor = null,
       @vStartTime            = 223000, @vEndTime              = null;

insert into @ttJobStepsInfo
       (StepName,                                              Command)
values ('~DBName~_LPNTransfers_PrepareForReceipt',             'exec pr_LPNs_TransferLPNs_PrepareforReceipt ''cIMSAgent'', ''~BU~''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   null /* FreqRelativeInterval */, null /* FreqRecurrenceFactor */,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Export Open Orders Summary - For client order forecasting
  Daily job run once
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_OpenOrders_ExportSummary_Daily',
       @vJobDescription     = 'execute Open Orders Summary Export Daily',
      -- Run once every day at 4 AM
       @vJobEnabled         = null,
       @vFreqType           = 4,      @vFreqInterval       = 0,
       @vFreqSubDayType     = 1,      @vFreqSubDayInterval = null,
       @vStartTime          = 040000, @vEndTime            = 075959;

insert into @ttJobStepsInfo
       (StepName,                                              Command)
values ('~DBName~_OpenOrders_ExportSummary',                   'exec pr_Exports_OpenOrdersSummary ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   null /* FreqRelativeInterval */, null /* FreqRecurrenceFactor */,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Export Open Orders Summary - For client order forecasting
  Daily job runs for every 4 hours
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_OpenOrders_ExportSummary_Hourly',
       @vJobDescription     = 'execute Open Orders Summary Export Hourly',
      -- Run once every day every 4 hours starting at 8 AM
       @vJobEnabled         = null,
       @vFreqType           = 4,      @vFreqInterval       = 1,
       @vFreqSubDayType     = 8,      @vFreqSubDayInterval = 4,
       @vStartTime          = 080000, @vEndTime            = 210000;

insert into @ttJobStepsInfo
       (StepName,                                              Command)
values ('~DBName~_OpenOrders_ExportSummary',                   'exec pr_Exports_OpenOrdersSummary ''~BU~'', ''cIMSAgent'', ''U''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   null /* FreqRelativeInterval */, null /* FreqRecurrenceFactor */,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
   User Productivity : Job to process productivity per user per date
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_UserProductivity',
       @vJobDescription     = 'Job to capture user productivity for a day',
      -- Run once every day at 23hours 27minute 15second
       @vJobEnabled           = null,
       @vFreqType             = 4,      @vFreqInterval       = 1,
       @vFreqSubDayType       = 1,      @vFreqSubDayInterval = 1,
       @vStartTime            = 232715, @vEndTime            = 234500;

insert into @ttJobStepsInfo
       (StepName,                               Command)
values ('~DBName~_UserProductivity',    'exec pr_Prod_MainProcess null, ''~BU~'', ''cIMSAgent'', ''N''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vFreqRelativeInterval, @vFreqRecurrenceFactor, @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
   Warehouse metrics : Job to process Warehouse metrics per date
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_RunWarehouseMetrics',
       @vJobDescription     = 'Job to capture Warehouse metrics for that day',
      -- Run once every day at 3 AM server time
       @vJobEnabled           = null,
       @vFreqType             = 4,      @vFreqInterval       = 1,
       @vFreqSubDayType       = 1,      @vFreqSubDayInterval = 1,
       @vStartTime            = 030000, @vEndTime            = 060000;

insert into @ttJobStepsInfo
       (StepName,                               Command)
values ('~DBName~_RunWarehouseMetrics',  'declare @vDate TDate;
                                         select @vDate = dateadd(dd, -1, getdate());
                                         exec pr_KPI_Execute @vDate, ''~BU~'', ''cIMSAgent'';');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vFreqRelativeInterval, @vFreqRecurrenceFactor, @vStartTime, @vEndTime;
/*------------------------------------------------------------------------------
  SKU Velocity Statistics
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_SKUVelocityStatistics',
       @vJobDescription     = 'SKU Velocity Statistics',
      -- Occurs every day at 11.05PM
       @vJobEnabled         = null,
       @vFreqType           = 4,     @vFreqInterval       = 1,
       @vFreqSubDayType     = 1,     @vFreqSubDayInterval = 5,
       @vStartTime          = 230500,@vEndTime            = 235959;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_SKUVelocityStatistics',            'declare @TDate datetime; set @TDate = getdate(); exec pr_SKUs_BuildSKUVelocity ''SHIP'', @TDate, ''~BU~'', ''CIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

/*------------------------------------------------------------------------------
  Location ReplenishLevelUpdates
------------------------------------------------------------------------------*/
delete from @ttJobStepsInfo;

select @vJobName            = '~DBName~_LocationReplenishLevelUpdates',
       @vJobDescription     = 'Location ReplenishLevelUpdates',
      -- Occurs every day at 11.30PM
       @vJobEnabled         = null,
       @vFreqType           = 4,     @vFreqInterval       = 1,
       @vFreqSubDayType     = 1,     @vFreqSubDayInterval = 5,
       @vStartTime          = 233000,@vEndTime            = 235959;

insert into @ttJobStepsInfo
       (StepName,                                    Command)
values ('~DBName~_LocationReplenishLevelUpdates',    'exec pr_Locations_UpdateLocationReplenishLevels ''~BU~'', ''CIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;

Go
