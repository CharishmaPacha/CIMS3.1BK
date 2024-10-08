/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/10/08  VM      Config changes as CIMS SQL is on Git (BK-1113)
  2024/10/01  VM      Config changes due to AAF is on Git (CIMSV3-3707)
  2024/09/27  VM      Config changes due to AMF is on Git (AMF-125)
  2024/09/18  VM      Config changes due to ADP is on Git (ADP-142)
  2024/05/17  VM      DB Build Configurations: CreateDB.bat => CIMSCreate.sql (CIMSV3-3625)
  2024/03/06  VM      Skip processing files which are split and moved to latest folders (CIMSV3-3430/CIMSV3-3451/CIMSV3-3429/CIMSV3-3428)
  2023/05/22  GAG     Changed to build data from Base for def_RBAC, Commented vwUsers, vwRoles,
                      vwRolePermissions, vwUIRolePermissions, vwActiveUIRolePermissions, vwUserUIRolePermissions, trig_Permissions,
                      vwGetUIPages, sp_RBAC, trig_Roles, sp_Access, sp_Users as they are moved to Base (JLCA-683)
  2022/12/28  MS      Added trig_Invsnapshot.sql (BK-981)
  2021/11/26  RV      Added sp_Carrier.sql (CIMSV3-1746)
  2022/04/20  SRP     Added vwSKUVelocity (BK-813)
  2022/02/17  SRS     Added vwLocationReplenishLevels (BK-764)
  2021/09/24  NB      Added vwPasswordRules(CIMSV3-787)
  2021/07/26  SK      Added vwWarehouseKPI.sql (HA-3020)
  2021/07/25  TK/AY   Added sp_KPI.sql (HA-3019)
  2021/05/11  TK      Changed order of sp_Miscellaneous (CIMSV3-1466)
  2021/04/16  VM      Added vwLocationLPNs.sql (HA-GoLive)
  2021/02/05  KBB     Added vwRoles (CIMSV3-1215)
  2020/12/22  AY      Added vwUILookUps (CIMSV3-1222)
  2020/11/23  TK      Added trig_OrderHeaders.sql (CID-1514)
  2020/11/20  MS      Added vwRouterConfirmations (JL-314)
  2020/11/18  RIA     Added sp_RFC_SerialNos, sp_SerialNos (CIMSV3-1211)
  2020/11/03  VM      Re-position of some objects based on dependencies (CIMSV3-1186)
  2020/10/20  VM      Re-position of some objects based on dependencies (HA-1483)
  2020/09/23  RV      Added vwLabelFormats (CIMSV3-1079)
  2020/09/14  AY      Added def_SerialNos, vwSerialNos
  2020/09/09  VM      sp_Custom position moved to last in procedures list to run last (HA-1388)
  2020/08/13  SAK     Added sp_Interface (CIMSV3-1001)
  2020/08/13  SK      Added vwOpenOrdersSummary (HA-1267)
  2020/07/29  MS      Added sp_Reports (HA-1004)
  2020/07/24  PK      Added vwUserRolePermissions (HA-1208)
  2020/07/21  KBB     Added vwCycleCountTaskDetails,vwCycleCountTasks (CIMSV3-1024)
  2020/07/16  MS      domains_UI_DataSources: Moved as last DomainFile to build (CIMSV3-548)
  2020/06/24  KBB     Adedd \Base\domains_Core.sql(CIMS-3043)
  2020/06/08  TK      Added sp_Loading.sql (HA-872)
  2020/06/06  NB      Added sp_UI.sql(CIMSV3-954)
  2020/06/04  SK      Added sp_Reservations.sql file cIMS Reservation (HA-670)
  2020/05/24  NB      Added domains_UI_DataSources.sql, sp_UI_DataSources(HA-101, CIMSV3-817)
  2020/05/21  YJ      Added def_Printing.sql (CIMSV3-915)
  2020/05/19  MS      Added domains_Presentation (HA-202)
  2020/05/18  MS      Added vwNotifications (HA-580)
  2020/05/15  MS      Added vwUIPickTasks, vwUIPickTaskDetails (HA-566)
  2020/04/24  VM      sp_Layouts.sql: Moved from WMS to Base (CIMSV3-855)
  2020/04/19  VM      File rename changes:
                        *_Purchasing => *_Receipts/Receiving, *_Sales => *_Orders, *_PickBatch* => *_Waves* (CIMSV3-824)
                      Added vwWaveDetailsToAllocate.sql (HA-86)
  2020/04/12  MS      Added domains_Access (CIMSV3-813)
  2020/04/11  VM      Added sp_Deploy.sql (CIMS-3069)
  2020/03/31  SK      Added sp_Access.sql (HA-69)
  2020/03/24  VM      Added vwTables.sql, vwWaves.sql (CIMSV3-778)
  2020/03/23  SK      Added sp_Admin.sql (HA-29)
  2020/03/17  YJ      Order changed for domains_Purchasing.sql, domains_Sales.sql since it is dependent on Sales
  2020/03/06  SK      Added def_Productivity.sql (CIMS-2967)
  2020/02/20  MS      Added sp_Custom (JL-123)
  2020/02/20  MS      Added sp_Printing.sql (JL-Support)
  2019/06/20  AY      Added sp_Content.sql (S2G-1276)
  2019/03/06  RIA     Added def_QualityCheck.sql, vwQCResults.sql, sp_RFC_QC.sql (HPI-2282)
  2019/02/11  RV      Included sp_QCInbound.sql (CID-53)
  2018/08/20  OK      Added trig_Pallets (S2G-1083)
  2018/10/18  AY      Moved vwCartonTypes to later as it is now using a function (S2GCA-383)
  2018/09/20  VS      vwTasks dependent on sp_Contacts so changed the order(OB2-638).
  2018/06/14  VM      vwROReceivers => vwReceivedCounts (S2G-947)
  2018/05/02  TK      Added trig_Loads (S2G-747)
  2018/03/27  VM      Adeed vwRoutingRules, vwRoutingRuleZones, vwRoutingZones (S2G-496)
  2018/03/09  VM      Added sp_Alerts.sql (S2G-346)
  2017/12/29  TK      Added sp_Jobs.sql (CIMS-758)
  2017/08/09  LRA     Added sp_DataSetup.sql (cIMS-1346)
  2017/07/04  YJ      Added vwShipLabels.sql (FB-970)
  2017/06/30  AY      Added def_Logging (HPI-1584)
  2017/04/25  TK      Added trig_Receipts.sql (HPI-1517)
  2017/03/28  PSK     domains_Interface dependent on domains_Shipping so changed the order(CIMS-1273).
  2017/01/13  VM      Added vwATEntity (FB:B1-Golive)
  2016/06/30  RV      Added sp_Roles.sql (NBD-588)
  2016/06/10  TK      Added vwTasksToPick.sql (cIMS-895)
  2016/05/28  AY      Added trig_Rules
  2016/04/28  YJ      View vwShipToAddress.sql that is dependent upon functions so changed the Order.
  2015/01/08  TK      Added sp_RFC_Packing.sql (NBD-64)
  2015/12/10  AY      Added def_EDI and sp_EDI (NBD)
  2015/09/29  DK      Added sp_RFC_Returns.sql (FB-389)
  2015/09/25  OK      Added sp_Returns.sql (FB-388).
  2015/07/08  VM      Added trig_Contacts.sql (LL-212)
  2015/07/03  TK      Changed order of sp_Controls.sql as we may use controls in Views.
  2015/06/06  AY      Moved vwLPNPackingListHeaders.sql to end as it depends upon function in sp_contacts.
  2015/05/26  TK      Added domains_Cubing.sql, sp_Cubing.sql.
  2015/05/26  AY      By default, we wouldn't want to include Sorter/Router/Panda and Synnonyms
  2015/03/19  NB      Added def_EventMonitor, sp_EventMonitor
  2015/03/04  NB      Added vwBulkOrderToPackDetails.sql;
  2015/02/25  DK      Added vwBulkOrdersToPack.sql;
  2014/11/27  PKS     Added vwUserLogin.sql
  2014/10/10  AK      Added vwUIReceiptDetails.
  2014/08/29  PKS     Added vwBatchLPNLabels.sql
  2014/08/12  YJ      Added sp_Core.sql.
  2014/06/16  TD      Added vwPutawayZones.sql.
  2014/06/03  TD      Added sp_Allocation.sql..
  2014/05/20  TD      Added sp_RFC_ToteOperations.sql.
  2014/05/26  NB      Added sp_Dashboard.sql.
  2014/05/14  SV      Added sp_Rules.sql.
  2014/04/23  DK      Added sp_Receivers.sql.
              SV      Added vwIntransitReceipts.sql.
  2014/04/17  PKS     Added vwReceivers.sql.
  2014/04/15  PKS     Added sp_Router.sql
              TD      Added vwPickBatchDetailsToAllocate.
  2014/04/12  AY      Added def_Synonyms.sql
  2014/04/09  TD      Added def_Sorter.sql, def_Router.sql.
  2014/04/03  TD      Added vwAllocationRules.
  2014/03/11  DK      Added trig_Notes.sql
  2014/02/05  PK      Added vwShippedLoads, vwOpenOrders, vwOpenReceipts.
  2013/10/11  AY      Added domain_Tasks and domain_TempTables
  2013/09/12  TD      Added vwPickBatchDetails.sql, sp_PreProcess.sql, vwOrderDetailsToBatch.sql,
                            vwBatchOrders, vwBatchOrderDetails.
  2103/08/19  TD      Added vwROLPNDetails.sql.
  2103/08/08  TD      Added vwSKUAttributes.sql.
  2013/07/19  TD      Added vwProductivity.sql, sp_Productivity.sql,vwAuditTrail.sql.
  2103/07/11  TD      Added vwReceiptStats.sql.
  2013/06/13  TD      Added files about replenishments.
  2013/05/17  TD      Added sp_Inventory.sql
  2013/03/26  TD      Added new view vwFieldCaptions.sql.
  2012/12/07  TD      Added new Views vwBoL.sql,vwBoLCarrierDetails.sql,
                          vwBoLOrderDetails.sql.
  2012/11/29  NY      Added sp_Presentation
  2012/11/09  PKS     Added sp_Entities.sql
  2012/11/09  PKS     Added trig_SKUs
  2012/09/25  NY      Added vwBatchPickSummary
  2012/09/24  AA      Added vwActiveSKUs
  2012/09/12  SP      Added vwShipVias
  2012/08/17  PKS     Added vwPackingListSizeScale.sql, vwPackingListMatrix.sql
  2012/08/03  PKS     Added sp_CrossDock.sql.
  2012/08/03  VM      Added vwActiveUIRolePermissions.sql
  2012/06/29  PKS     Added sp_ShipLabel.sql.
  2012/06/18  TD      Added sp_Shipments.sql and sp_Loads.sql, vwOrdersForLoad,
                           vwLoadsToManage,vwLoadOrders.sql, vwOrderShipments.
  2012/06/07  PKS     Added vwPackingListDetails.sql, vwPackingListHeaders.sql.
  2012/05/25  PKS     Added vwOrdersToBatch.
  2012/05/24  PKS     Added vwPickBatchUsers
  2012/05/17  AA      Rename vwDevicePrinterMapping to vwDevicePrinters
  2012/05/04  PKS     Added vwSKUPrePacks.sql;
  2012/05/02  PK      Added def_AuditTrail.sql, sp_AuditTrail.sql;
  2012/04/27  PKS     Added vwPrinters.sql
  2012/04/25  PKS     Added vwDevicePrinterMapping.sql
  2012/04/05  PKS     Added def_Presentation, def_Device, def_PrintService, sp_PrintService
  2012/02/17  PK      Added vwShippedOrderedVariance.
  2012/02/01  PK      Added vwShippedOrders.sql
  2012/01/30  PKS     Added vwLocationsForCycleCount
  2012/01/10  YA      Added sp_CycleCount.sql
  2012/01/02  PK      Added vwCycleCountResults
  2011/12/28  VM      Added vwTasks.sql, vwTaskDetails.sql, sp_Tasks.sql
  2011/12/27  VM      Added vwCurrentOrders, vwCurrentOrderDetails, vwCurrentPickBatches, vwLPNsShipped
  2011/12/01  AA      Added sp_RBAC.sql
  2011/12/14  YA      Added sp_RFC_CycleCount.sql
  2011/12/06  PKS     Added vwOrderAddress.sql
  2011/12/05  AY      Added sp_Layouts.sql
  2011/11/21  YA      Added trig_Roles.sql
  2011/11/17  VM      Added sp_Archive.sql
  2011/10/10  VM      Added vwGetUIPages.sql
  2011/10/06  AY      Added vwShipToAddress, vwSoldToAddress
  2011/09/27  YA      sp_OnhandInventory.sql: Commented as this file contains only one procedure and
                        the procedure in this exists in sp_Exports
  2011/09/09  VM/YA   Corrected as per the files and removed duplicates/commented
              VM      Added vwBatchPickDetails
  2011/09/08  NB      Added add Packing related views
  2011/09/06  VM      Added vwUIRolePermissions, removed duplicate of vwPickingZones
  2011/08/29  NB      Added vwCartonTypes
  2011/08/12  PK      Added vwBatchesToPack, vwBatchTypes, vwExportsOnhandInventory,
                       vwPackingZones, vwPickBatches, vwPickingZones, vwRolePermissions,
                       vwPickDetails, sp_Batching, sp_OnhandInventory, sp_Packing, sp_Pallets.
  2011/07/26  YA      Added def_PickBatch, vwPickBatches & vwBatchingRules
  2011/07/18  AY      Added vwPutawayRules, def_Putaway & vwPutawayLocations
  2011/06/13  VM      Added sp_RFC_Putaway.
                      Added sp_Putaway.
  2011/03/15  VK      Added view vwStatusesBitType.
  2011/03/11  VK      Added sp_Users procedure and vwUsers.
  2011/01/27  VM      Added sp_RFC_Picking.sql
  2011/01/25  VK      Added vwLPNOnhandInventory.sql.
  2011/01/25  VM      Added sp_Devices, vwPickingZones
              VK      Added vwLPNOnhandInventory.sql.
  2011/01/24  VK      Added sp_RFC_Inquiry.sql,vwOrderDetailsToAllocate.sql and
                      sp_Picking.sql.
  2011/01/17  AR      Moved vwOrderDetails.sql, vwReceiptDetails.sql up in the
                      creation order b/c vwLPNDetails.sql relies on them already being
                      created. A better solution would be to NOT base vwLPNDetails on
                      these two views?
  2011/01/10  VM      Added vwExports
  2011/01/02  AR      Added sp_Imports
  2010/12/02  VK      Added pr_RFC_Inventory to Stored Procedures
  2010/10/26  PK      Added trig_Users and sp_Email.
  2010/10/25  AR      We need to be setting READ COMMITTED SNAPSHOT!
  2010/09/23  PK      Initial Revision.
------------------------------------------------------------------------------*/

/* Row Versioning */
declare @sSql nvarchar(80);
set @sSql = 'Alter Database ' + DB_Name() + ' set Read_Committed_Snapshot On;';
exec(@sSql);
Go

/* WMS DataTypes, TableTypes, Tables, Views, Functions, Procedures, Triggers and Finalize objects */
Input ..\SQL\DataTypes;
Input ..\SQL\TableTypes;
Input ..\SQL\Tables;
Input ..\SQL\Functions|fn_*;
Input ..\SQL\Views;
Input ..\SQL\Procedures|sp_*;
Input ..\SQL\Triggers;
Input ..\SQL\Finalize;

/* RF & AMF Framework DataTypes, TableTypes, Tables, Views, Functions, Procedures and Triggers */
Input ..\..\SQL_RF_AMF\SQL\DataTypes;
Input ..\..\SQL_RF_AMF\SQL\TableTypes;
Input ..\..\SQL_RF_AMF\SQL\Tables;
Input ..\..\SQL_RF_AMF\SQL\Functions|fn_*;
Input ..\..\SQL_RF_AMF\SQL\Views;
Input ..\..\SQL_RF_AMF\SQL\Procedures|sp_*;
Input ..\..\SQL_RF_AMF\SQL\Triggers;

/* API & AAF Framework DataTypes, TableTypes, Tables, Views, Functions, Procedures and Triggers */
Input ..\..\SQL_API_AAF\SQL\DataTypes;
Input ..\..\SQL_API_AAF\SQL\TableTypes;
Input ..\..\SQL_API_AAF\SQL\Tables;
Input ..\..\SQL_API_AAF\SQL\Functions|fn_*;
Input ..\..\SQL_API_AAF\SQL\Views;
Input ..\..\SQL_API_AAF\SQL\Procedures|sp_*;
Input ..\..\SQL_API_AAF\SQL\Triggers;

/* ADP & DaB Framework DataTypes, TableTypes, Tables, Views, Functions, Procedures and Triggers */
Input ..\..\SQL_DaB_ADP\SQL\DataTypes;
Input ..\..\SQL_DaB_ADP\SQL\TableTypes;
Input ..\..\SQL_DaB_ADP\SQL\Tables;
Input ..\..\SQL_DaB_ADP\SQL\Functions|fn_*;
Input ..\..\SQL_DaB_ADP\SQL\Views;
Input ..\..\SQL_DaB_ADP\SQL\Procedures|sp_*;
Input ..\..\SQL_DaB_ADP\SQL\Triggers;

Go
