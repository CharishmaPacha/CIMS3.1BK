/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/06/15  VM      File organized to insert all synonyms to create into a temp table and create only when not exists on dest server (CIMSV3-2832)
  2022/05/18  VS      Added CIMSDE_ExportOrderDetails, CIMSDE_pr_PushExportOrderDetails (FBV3-1202)
  2022/05/17  VS      Added CIMSDE_ExportInvSnapshot (FBV3-1203)
  2022/02/18  RV      Added CIMSDE system tables (JLFL-95)
  2022/01/19  MS      Added CIMSDE_pr_PushExportInvSnapShots (HA-3328)
  2021/03/19  TK      Added CIMSDE_pr_GetInvAdjustmentsToImport (HA-2341)
  2021/02/27  TK      Added CIMSDE_ExportCarrierTrackingInfo & CIMSDE_pr_PushExportCarrierTrackingInfoFromCIMS (BK-203)
  2020/09/21  MS      Renamed some of DCMS synonyms (JL-64)
  2020/09/15  AY      Renamed some of DCMS synonyms (JL-65)
  2020/08/12  SK      Added new synonym CIMSDE_ExportOpenOrdersSummary
                      CIMSDE_pr_PushExportOpenOrdersSummary (HA-1267)
  2020/05/23  AY      Added synonyms for other PickBatch* tables (HA-561)
  2020/04/03  MS/TD   Added new synonyms (JL-65)
  2018/11/11  AY      Changed CIMSDE database to CIMSDEDev_Blank as that is corresponding blank DB
  2018/08/18  AY      ActivityLog purging blocks all processes (S2G-1059)
  2018/02/27  SV      Spelling correction from pr_Imports_DE_GetANSLPNDetailsToImport
                        to pr_Imports_DE_GetASNLPNDetailsToImport (S2G-297)
  2018/02/19  TD      Added CIMSDE_ImportResults (CIMS-1865)
  2018/01/22  RV      Added CIMSDE_ImportInvAdjustments (S2G-44)
  2017/11/30  SV      Added CIMSDE_pr_ExportInv, CIMSDE_pr_ExportOpenOrders,
                        CIMSDE_pr_ExportOpenReceipts, CIMSDE_pr_ExportShippedLoads (CIMSDE-35)
  2017/11/27  SV      Added Import ReceiptHeaders - synonym (CIMSDE-17)
                      Added Import ReceiptDetails - synonym (CIMSDE-18)
  2017/11/06  TD      Initial revision.
------------------------------------------------------------------------------*/
Go

/*------------------------------------------------------------------------------
Linked servers should only once for the fresh installation, Please check if there are any
linked servers created already. Below created Linked servers are for local development environment,
Need to change them accordingly while creating for Test or Production servers.
Linked servers has to be defined only where the databased are on different servers.
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Configure CIMS to use CIMSDE Server */
/*----------------------------------------------------------------------------*/

/*  Create link to an instance of SQL Server CIMSDE Development Server
exec sp_addlinkedserver @server     = 'CIMSDE_Server',
                        @srvproduct = '',
                        @provider   = 'SQLNCLI',
                        @datasrc    = '192.168.100.38\SQL2014DEV', -- Remote Server
                        @Catalog    = 'CIMSDE';  --Database of the remote server

-- Configure the linked server to use the domain credentials of the login that is using the linked server
exec sp_addlinkedsrvlogin @rmtsrvname  = N'CIMSDE_Server',
                          @useself     = N'False',
                          @locallogin  = N'cimsdba',
                          @rmtuser     = N'cimsdba',
                          @rmtpassword = 'cimsdba1'

-- We need these options to be true if linked server should accept (rpc) or execute (rpc out) procedures
exec sp_serveroption 'CIMSDE_Server', 'rpc', true;
exec sp_serveroption 'CIMSDE_Server', 'rpc out', true;

*/

/*----------------------------------------------------------------------------*/
/* Configure CIMS to use WCS Server */
/*----------------------------------------------------------------------------*/

/*  Create link to an instance of SQL Server WCS Development Server
exec sp_addlinkedserver @server     = 'WCSDev_Server',
                        @srvproduct = '',
                        @provider   = 'SQLNCLI',
                        @datasrc    = '192.168.100.99\SQLExpress', -- Remote Server
                        @Catalog    = 'SDIWCS_Dev';  --Database of the remote server

-- Configure the linked server to use the domain credentials of the login that is using the linked server
exec sp_addlinkedsrvlogin @rmtsrvname  = N'WCSDev_Server',
                          @useself     = N'False',
                          @locallogin  = N'cimsdba',
                          @rmtuser     = N'cimsdba',
                          @rmtpassword = 'cimsdba1'

*/

/*----------------------------------------------------------------------------*/
/* Configure CIMS to use Host ERP */
/*----------------------------------------------------------------------------*/

/*  Create link to an instance of SQL Server GNC Server
exec sp_addlinkedserver @server     = 'GNCHostDev_Server',
                        @srvproduct = '',
                        @provider   = 'SQLNCLI',
                        @datasrc    = '192.168.100.99\SqlExpress', -- Remote Server
                        @Catalog    = 'GNCHost_Dev';  -- Database of remote server

Configure the linked server to use the domain credentials of the login that is using the linked server
exec sp_addlinkedsrvlogin @rmtsrvname  = N'GNCHostDev_Server',
                          @useself     = N'False',
                          @locallogin  = N'cimsdba',
                          @rmtuser     = N'cimsdba',
                          @rmtpassword = 'cimsdba1'
*/

Go

declare @ttSynonyms Table(SourceObj TName, DestName TName, DestObj TName, DestServer TName, DestDB TName);
declare @SQL TSQL;

/******************************************************************************/
/* Create Synonyms for the tables of WCS Development server */
/******************************************************************************/
/*
insert into @ttSynonyms
            (SourceObj,                DestObj)
      select 'WCSOrderWaveHeader',     'HI_Xfer_Inb_OrderWaveHeader'     -- Host Order Wave Data update for WCS
union select 'WCSOrderWaveDetail',     'HI_Xfer_Inb_OrderWaveDetail'     -- Host Inbound Carton Data update for WCS
union select 'WCSCartonHeader',        'HI_Xfer_Inb_InboundCartonHeader'
union select 'WCSCartonDetail',        'HI_Xfer_Inb_InboundCartonDetail'
union select 'WCSPackedCartonHeader',  'HI_Xfer_Outb_CartonHeader'       -- WCS update for Host to Retrieve Packed Carton Content for Orders
union select 'WCSPackedCartonDetail',  'HI_Xfer_Outb_CartonDetail'
union select 'WCSConsumedLPN',         'HI_Xfer_Outb_InboundCartonBurn'  -- WCS update to Host for Cartons Consumed at the Sorter Induction Stations
union select 'WCSRouteInstruction',    'HI_Xfer_Inb_RouteInstruction'    -- Routing and PandA Interface: Host Carton/Tote Routing Data update for WCS
union select 'WCSCartonDivert',        'HI_Xfer_OutB_CartonDivert'       -- Routing and PandA Interface: WCS Carton/Tote Divert Data update for Host
union select 'WCSWaveComplete',        'HI_Xfer_OutB_WaveComplete'       -- Routing and PandA Interface: WCS Wave Complete update for Host
union select 'PandALabelData',         'HI_Xfer_Inb_LabelData'           -- PandA Interface:
union select 'PandAVerify',            'HI_Xfer_Outb_PandAVerify'        -- PandA Interface:

update @ttSynonyms set DestServer = 'WCSDev_Server',
                       DestDB     = 'SDIWCS_Dev'
where (SourceObj like 'WCS%') or (SourceObj like 'PandA%');
*/

/******************************************************************************/
/* Internally used synonyms */
/******************************************************************************/
insert into @ttSynonyms
            (SourceObj,                DestObj)
      select 'Waves',                  'PickBatches'
union select 'WaveDetails',            'PickBatchDetails'
union select 'WaveRules',              'PickBatchRules'
union select 'WaveAttributes',         'PickBatchAttributes'
union select 'CurrActivityLog',        'ActivityLog'  -- by default we map to core table but later create a copy and map to it.

/******************************************************************************/
/* Host ERP Table Synonyms */
/******************************************************************************/
/*
insert into @ttSynonyms
            (SourceObj,                 DestObj)
      select 'HostExportInventory',     'uc_sdi_export_inventory'      -- Inventory exports for Host ERP
union select 'HostExportTransaction',   'uc_sdi_export_transaction'    -- Transaction exports for Host ERP
union select 'HostImportPackedCartons', 'uc_sdi_import_packedcartons'  -- Packed Cartons exported from Host ERP
union select 'HostExportOpenReceipts',  'uc_sdi_export_openreceipts'   -- Open Receipt exports for Host ERP
union select 'HostExportOpenOrders',    'uc_sdi_export_openorders'     -- Open Orders exports for Host ERP
union select 'HostExportShippedLoads',  'uc_sdi_import_shippedorders'  -- Shipped Loads exports for Host ERP
union select 'HostExportInvExpiryData', 'uc_sdi_export_invexpirydata'

update @ttSynonyms set DestServer = 'GNCHostDev_Server',
                       DestDB     = 'GNCHost_Dev'
where SourceObj like 'Host%';
*/

/******************************************************************************/
/* DE Table/Procedure Synonyms */
/******************************************************************************/
insert into @ttSynonyms
            (SourceObj,                                      DestObj)
/* Synonyms for DE Imports tables */
      select 'CIMSDE_ImportASNLPNs',                         'ImportASNLPNs'
union select 'CIMSDE_ImportASNLPNDetails',                   'ImportASNLPNDetails'
union select 'CIMSDE_ImportCartonTypes',                     'ImportCartonTypes'
union select 'CIMSDE_ImportContacts',                        'ImportContacts'
union select 'CIMSDE_ImportInvAdjustments',                  'ImportInvAdjustments'
union select 'CIMSDE_ImportNotes',                           'ImportNotes'
union select 'CIMSDE_ImportOrderDetails',                    'ImportOrderDetails'
union select 'CIMSDE_ImportOrderHeaders',                    'ImportOrderHeaders'
union select 'CIMSDE_ImportReceiptDetails',                  'ImportReceiptDetails'
union select 'CIMSDE_ImportReceiptHeaders',                  'ImportReceiptHeaders'
union select 'CIMSDE_ImportSKUs',                            'ImportSKUs'
union select 'CIMSDE_ImportSKUPrePacks',                     'ImportSKUPrePacks'
union select 'CIMSDE_ImportUPCs',                            'ImportUPCs'
union select 'CIMSDE_ImportResults',                         'ImportResults'

/* Synonyms for DE Import Procedures */
union select 'CIMSDE_pr_GetASNLPNsToImport',                 'pr_Imports_DE_GetASNLPNsToImport'
union select 'CIMSDE_pr_GetASNLPNDetailsToImport',           'pr_Imports_DE_GetASNLPNDetailsToImport'
union select 'CIMSDE_pr_GetCartonTypesToImport',             'pr_Imports_DE_GetCartonTypesToImport'
union select 'CIMSDE_pr_GetContactsToImport',                'pr_Imports_DE_GetContactsToImport'
union select 'CIMSDE_pr_GetNotesToImport',                   'pr_Imports_DE_GetNotesToImport'
union select 'CIMSDE_pr_GetReceiptDetailsToImport',          'pr_Imports_DE_GetReceiptDetailsToImport'
union select 'CIMSDE_pr_GetReceiptHeadersToImport',          'pr_Imports_DE_GetReceiptHeadersToImport'
union select 'CIMSDE_pr_GetOrderDetailsToImport',            'pr_Imports_DE_GetOrderDetailsToImport'
union select 'CIMSDE_pr_GetOrderHeadersToImport',            'pr_Imports_DE_GetOrderHeadersToImport'
union select 'CIMSDE_pr_GetSKUsToImport',                    'pr_Imports_DE_GetSKUsToImport'
union select 'CIMSDE_pr_GetSKUPrePacksToImport',             'pr_Imports_DE_GetSKUPrePacksToImport'
union select 'CIMSDE_pr_GetUPCsToImport',                    'pr_Imports_DE_GetUPCsToImport'
union select 'CIMSDE_pr_GetInvAdjustmentsToImport',          'pr_Imports_DE_GetInvAdjustmentsToImport'

/* Synonym for Ack of imported records */
union select 'CIMSDE_pr_AckImportedRecords',                 'pr_Imports_DE_ACKImportedRecords'

/* Synonyms for DE Exports table */
union select 'CIMSDE_ExportOnhandInventory',                 'ExportOnhandInventory'
union select 'CIMSDE_ExportOpenOrders',                      'ExportOpenOrders'
union select 'CIMSDE_ExportOpenReceipts',                    'ExportOpenReceipts'
union select 'CIMSDE_ExportShippedLoads',                    'ExportShippedLoads'
union select 'CIMSDE_ExportTransactions',                    'ExportTransactions'
union select 'CIMSDE_ExportOpenOrdersSummary',               'ExportOpenOrdersSummary'
union select 'CIMSDE_ExportCarrierTrackingInfo',             'ExportCarrierTrackingInfo'
union select 'CIMSDE_ExportInvSnapshot',                     'ExportInvSnapshot'
--union select 'CIMSDE_ExportOrderDetails',                    'ExportOrderDetails'

--/* FlatFile Import related */
--union select 'CIMSDE_FF_ImportASNs',                         'FF_ImportASNs'
--union select 'CIMSDE_FF_ImportOrders',                       'FF_ImportOrders'
--union select 'CIMSDE_FF_ImportReceipts',                     'FF_ImportReceipts'
--union select 'CIMSDE_FF_ImportRMAs',                         'FF_ImportRMAs'
--union select 'CIMSDE_FF_ImportSKUs',                         'FF_ImportSKUs'

--/* FlatFile Export related */
--union select 'CIMSDE_FF_ExportInventoryAdjustments',         'FF_ExportInventoryAdjustments'
--union select 'CIMSDE_FF_ExportRMATransactions',              'FF_ExportRMATransactions'
--union select 'CIMSDE_FF_ExportReceiptConfirmations',         'FF_ExportReceiptConfirmations'
--union select 'CIMSDE_FF_ExportShipConfirmations',            'FF_ExportShipConfirmations'

/* Synonyms for DE Export Procedures */
union select 'CIMSDE_pr_PushExportDataFromCIMS',             'pr_Exports_DE_GetExportDataFromCIMS'
union select 'CIMSDE_pr_PushExportInvFromCIMS',              'pr_Exports_DE_GetOnhandInventoryFromCIMS'
--union select 'CIMSDE_pr_PushExportTransferOrderData',        'pr_Exports_DE_GetTransferOrderDataFromCIMS'
union select 'CIMSDE_pr_PushExportOpenOrdersFromCIMS',       'pr_Exports_DE_GetOpenOrdersFromCIMS'
union select 'CIMSDE_pr_PushExportOpenReceiptsFromCIMS',     'pr_Exports_DE_GetOpenReceiptsFromCIMS'
union select 'CIMSDE_pr_PushExportShippedLoadsFromCIMS',     'pr_Exports_DE_GetShippedLoadsFromCIMS'
union select 'CIMSDE_pr_PushExportOpenOrdersSummary',        'pr_Exports_DE_InsertOpenOrdersSummary'
union select 'CIMSDE_pr_PushExportCarrierTrackingInfoFromCIMS',
                                                             'pr_Exports_DE_GetCarrierTrackingInfoFromCIMS'
--union select 'CIMSDE_pr_PushExportInvSnapShots',             'pr_Exports_DE_InsertInvSnapShot'
union select 'CIMSDE_pr_PushExportOrderDetails',             'pr_Exports_DE_InsertOrderDetails'

/*----------------------------------------------------------------------------*/
update @ttSynonyms set --DestServer = 'CIMSDE_Server',
                       DestDB     = replace(DB_NAME(), 'CIMS', 'CIMSDE')
where SourceObj like 'CIMSDE%';

/******************************************************************************/
/* DCMS Integration Table/Procedure Synonyms */
/******************************************************************************/
/*
insert into @ttSynonyms
            (SourceObj,                          DestObj)
      select 'DCMS_OrderWaveHeader',             'HI_Xfer_Inb_OrderWaveHeader'              -- CIMS -> DCMS: Order Wave Data update
union select 'DCMS_OrderWaveDetail',             'HI_Xfer_Inb_OrderWaveDetail'              -- CIMS -> DCMS: Order Wave Data update
union select 'DCMS_CartonHeader',                'HI_Xfer_Inb_InboundCartonHeader'          -- CIMS -> DCMS: Inbound Carton Data: Cartons routed to sorted for consumption
union select 'DCMS_CartonDetail',                'HI_Xfer_Inb_InboundCartonDetail'          -- CIMS -> DCMS: Inbound Carton Data: Cartons routed to sorted for consumption
union select 'DCMS_PackedCartonHeader',          'HI_Xfer_Outb_CartonHeader'                -- DCMS -> CIMS: Cartons Packed at Sorter/PTL for Orders
union select 'DCMS_PackedCartonDetail',          'HI_Xfer_Outb_CartonDetail'                -- DCMS -> CIMS: Cartons Packed at Sorter/PTL for Orders
union select 'DCMS_ConsumedLPN',                 'HI_Xfer_Outb_InboundCartonBurn'           -- DCMS -> CIMS: Consumed at the Sorter/PTL Induction Stations
union select 'DCMS_WaveStatus',                  'HI_Xfer_OutB_WaveComplete'                -- DCMS -> CIMS: Wave Completion Status update
union select 'vw_DCMSPackedCartons',             'Sdivw_HI_GetReadyCartonContentRecords'    -- Views to get the data
union select 'pr_DCMSPackedCarton_ACK',          'Sdisp_HI_ACK_CartonContent'               -- Procedures to ACK the data retrieved
union select 'pr_DCMSConsumedLPN_ACK',           'Sdisp_HI_ACK_CartonBurn'                  -- Procedures to ACK the data retrieved
union select 'DCMS_RouteInstruction',            'HI_Xfer_Inb_RouteInstructions'            -- DCMS Carton/Tote Routing
union select 'DCMS_CartonDivert',                'HI_Xfer_OutB_CartonDivert'                -- DCMS Carton/Tote Routing
union select 'vw_DCMSCartonDivert',              'Sdivw_HI_GetReadyCartonDivertRecords'     -- View to fetch data from DCMS
union select 'pr_DCMSCartonDivert_ACK',          'Sdisp_HI_ACK_CartonDivert'                -- Procedure to ACK the retrieved data
union select 'DCMS_vwCartonDivert',              'sdivw_HI_CIMS_Get_Outb_ReadyCartonDivert'
union select 'DCMS_pr_CartonDivertACK',          'sdisp_HI_ACK_Outb_CartonDivert'

update @ttSynonyms set DestServer = 'DCMSDev_Server',
                       DestDB     = 'SDI_DCMSCore'
where (SourceObj like 'DCMS%') or (ourceObj like 'vw_DCMS%') or (ourceObj like 'pr_DCMS%');
*/

/******************************************************************************/
/* Process the data */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Delete if the synonyms already exist */
delete Syn
from @ttSynonyms Syn join sys.synonyms S on (Syn.SourceObj = S.Name);

/*----------------------------------------------------------------------------*/
/* Build the DestDB as current DB to all for which DestServer is not defined. */
update @ttSynonyms set DestDB = DB_NAME() where DestDB is null;

/*----------------------------------------------------------------------------*/
/* Build the DestName */
update @ttSynonyms set DestName = concat_ws('.', DestServer, DestDB, 'dbo', DestObj);

--select * from @ttSynonyms;

/*----------------------------------------------------------------------------*/
/* Prepare SQL to create all synonyms */
select @SQL = string_agg(concat('Create Synonym ', SourceObj, ' for ', DestName), '; ')
from @ttSynonyms;

/*----------------------------------------------------------------------------*/
/* Execute SQL to create synonyms */
select @SQL;
if coalesce(@SQL, '') <> ''
  exec (@SQL);

Go
