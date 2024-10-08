/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/21  SRP     Added SKU Velocity (BK-813)
  2022/02/28  MS      Added UserAuditLog (BK-778)
  2022/02/25  SRS     Added ExportInvSnapshot  (BK-767)
  2022/02/17  SRS     Added LocationReplenishLevels (BK-764)
  2021/07/26  SK      Added new Dashboard section (HA-3020)
  2021/07/23  SK      Added WarehouseMetrics (HA-3020)
  2021/07/08  SK      Updated data set for Productivity (HA-2972)
  2021/04/30  NB      Added Packing(CIMSV3-156)
  2021/04/20  NB      Added Manage Permissions(CIMSV3-1341)
  2021/03/16  PK      CycleCountResults: Set visible to 1: Ported changes done by Pavan (HA-2287)
  2021/03/04  KBB     Added CycleCountResults (HA-2003)
  2021/02/05  MS      Added PrintJobDetails (BK-156)
  2021/01/19  SJ      Added APITables (CID-1594)
  2020/12/17  YJ/AY   Changed the Lists page to use vwUILookups (CIMSV3-1222)
  2020/11/24  KBB     Changed the Caption Role Permissions to Permissions(CIMSV3-1215)
  2020/10/08  TK      Renamed 'UnWaved Orders' to 'Orders To Wave' (HA-1531)
  2020/10/01  SK      Added User Productivity (HA-1479)
  2020/09/01  AY      Setup proc for CC Stats (CIMSV3-1026)
  2020/08/14  NB      Added ImportFiles Menu Item (HA-320)
  2020/07/21  KBB     Added Menu for CycleCountTaskDetails (CIMSV3-1024)
  2020/07/14  KBB     Added ShippingLog page (HA-1093)
  2020/07/13  MS      Added CycleCountLocations page (CIMSV3-548)
  2020/06/23  HYP     BaseTables - CartonGroups: Added new listing (HA-796)
  2020/06/10  RV      LoadManagement - LoadOrders: Added new listing (HA-839)
  2020/06/03  NB      ManageReplenishments: changes dbSource from vwLocationsToReplenish to pr_UI_DS_LocationsToReplenish (HA-251)
  2020/06/02  VM      PrintRequests: DBSource changed to vwPrintRequests (HA-251)
  2020/05/30  NB      Changed dbSource from vwPickBatches to vwWaves for WavingWaves(HA-693)
  2020/05/23  NB      Added WaveSummary(HA-101)
  2020/05/22  MS      PrintJobs: Dataset corrected (HA-48)
  2020/05/20  MS      Disabled Replenish Module & Migrated Shipping Module Permissions from Dev (HA-605)
  2020/05/20  KBB     Added List Selections (HA-549)
  2020/05/18  PK      Changed PermissionNames and also re-organized permissions to match with V3 (HA-409)
  2020/05/18  MS      Added Notifications (HA-580)
  2020/05/15  MS      Use vwUIPickTasks, vwUIPickTaskDetails as Dataset (HA-566)
  2020/05/04  VM      Added Maintenance-PrintCenter -> PrintRequests (HA-251)
  2020/04/28  SV      Added Layouts menu details (HA-305)
  2020/04/21  NB      Added List.ATEntity for Entity Audit Trail calls from other listings(HA-231)
  2020/04/20  SAK     Changed the permissions for SystemInfo* menus (HA-244)
  2020/04/20  NB      Layouts list..changed dbSource vwLayouts -> Layouts,
                      clean up..unused DBSourceType variable (CIMSV3-817)
  2020/04/14  MS      Corrections to CartonTypes Permissions (CIMSV3-813)
  2020/03/28  TK      Corrected DBSource for RolePermissions (HA-68)
  2020/03/24  OK      Added Printers listing (HA-46)
  2020/03/24  KBB     Added SKUPriceList (CID-1227)
  2020/03/05  RV      Added ManageLoads UI menu (CIMSV3-154)
  2020/03/03  NB      changes to ShippingDocs menu detail to invoke ShippingDocs url (CIMSV3-221)
  2020/01/23  KBB     Added DCMSTables (JL-62)
  2019/05/23  RKC     Added Imports Tables (CIMSV3-550)
  2019/05/01  SPP     Added RoutingRules, RoutingZones (CIMSV3-485)
  2019/03/30  RC      Changes the dbsource and Permission name for UserInterface module (CIMSV3-227)
  2019/04/04  NB      Added Dashboard Menu and Menu Items (APD-121)
  2019/03/12  MS      Changed the mapping for PicktaskDetails page (CIMSV3-216)
  2019/02/16  AY      Added Replenishments main menu
  2018/07/18  NB      Changes to handle TUIMenuDetails and pr_Setup_UIMenu changes (CIMSV3-299)
  2018/02/02  NB      Modified Pick Batching Menu Details (CIMSV3-153)
  2018/01/02  AY      Changed to use setup procedure (CIMSV3-157)
  2017/12/01  NB      Corrections to handle inserting BusinessUnit (CIMSV3-48)
  2017/11/23  NB      Initial revision.
------------------------------------------------------------------------------*/

Go

declare @UIMenu        TUIMenuDetails,
        @UITarget      TDescription,
        @UIList        TDescription  = '/Home/List',
        @UIManageLoads TDescription  = '/Home/ManageLoads',
        @ParentMenuId  TName;

/* Clear Table Entries */
delete from UIMenuDetails;

/*----------------------------------------------------------------------------*/
/* Main Menu Item - This is not displayed anywhere. only acts as the anchor or starting point for building the menu */
                        /* MenuId                   Caption                  PermissionName,                                UITarget,   ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'V3UIMain',              'Main Menu',             'UIMainMenu',                                  null,       null,                              null,                            1,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Main Menu Groups */
delete from @UIMenu;
select @ParentMenuId = 'V3UIMain';

                        /* MenuId                   Caption                  PermissionName,                                UITarget,   ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'Receiving',             'Receiving',             'ReceiveMenu',                                 null,       null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'Inventory',             'Inventory',             'InventoryMenu',                               null,       null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'OrderProcessing',       'Order Fulfillment',     'OrderMenu',                                   null,       null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'Replenishments',        'Replenishments',        'ReplenishmentMenu',                           null,       null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'Shipping',              'Shipping',              'OrderMenu',                                   null,       null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'Maintenance',           'Maintenance',           'MaintenanceMenu',                             null,       null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'Dashboards',            'Dashboards',            'Dashboards',                                  null,       null,                              null,                            1,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Main Menu Group 'Receiving' for Listings */
delete from @UIMenu;
select @ParentMenuId = 'Receiving',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget,   ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'ReceiptHeaders',        'Receipts',              'Receipts',                                    @UIList,    'List.ReceiptHeaders',             'vwReceiptHeaders',              1,      null,   0,                 null
insert into @UIMenu select 'ReceiptDetails',        'Receipt Details',       'ReceiptDetails',                              @UIList,    'List.ReceiptDetails',             'vwReceiptDetails',              1,      null,   0,                 null
insert into @UIMenu select 'Receivers',             'Receivers',             'Receivers',                                   @UIList,    'List.Receivers',                  'vwReceivers',                   1,      null,   0,                 null
insert into @UIMenu select 'Returns',               'Returns',               'Returns',                                     '/Receipts/Returns',  null,                    null,                            1,      'I',    0,                 null
insert into @UIMenu select 'Vendors',               'Vendors',               'Vendors',                                     @UIList,    'List.Vendors',                    'vwVendors',                     1,      null,   0,                 null

/*----------------*/
select @UITarget     = '/LPN/CreateReceiptInventory';

                           /* MenuId                Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'CreateReceiptInventory','Receive Inventory',     'CreateReceiptInventory',                      @UITarget,  null,                              null,                            1,      null,   1,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Main Menu Group 'Inventory' for Listings and Features */
delete from @UIMenu;
select @ParentMenuId = 'Inventory',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'SKUs',                  'SKUs',                  'SKUs',                                        @UITarget,  'List.SKUs',                       'vwSKUs',                        1,      null,   0,                 null
insert into @UIMenu select 'SKUPrePacks',           'SKU PrePacks',          'SKUPrePacks',                                 @UITarget,  'List.SKUPrePacks',                'vwSKUPrePacks',                 1,      null,   0,                 null
-- Changed permission name to have $ to show it as disabled for now.
insert into @UIMenu select 'LPNs',                  'LPNs',                  'LPNs',                                        @UITarget,  'List.LPNs',                       'vwLPNs',                        1,      null,   0,                 null
insert into @UIMenu select 'LPNDetails',            'LPN Details',           'LPNDetails',                                  @UITarget,  'List.LPNDetails',                 'vwLPNDetails',                  1,      null,   0,                 null
insert into @UIMenu select 'Serial Nos',            'Serial Nos',            'SerialNos',                                   @UITarget,  'List.SerialNos',                  'vwSerialNos',                   1,      null,   0,                 null
insert into @UIMenu select 'Pallets',               'Pallets',               'Pallets',                                     @UITarget,  'List.Pallets',                    'vwPallets',                     1,      null,   0,                 null
insert into @UIMenu select 'Locations',             'Locations',             'Locations',                                   @UITarget,  'List.Locations',                  'vwLocations',                   1,      null,   0,                 null
insert into @UIMenu select 'LocationReplenishLevels',
                                                    'Location Replen Levels', 'LocationReplenishLevels',                    @UITarget,  'List.LocationReplenishLevels',    'vwLocationReplenishLevels',     1,      null,   0,                 null

/*----------------*/
insert into @UIMenu select 'CycleCount',            'Cycle Count',           'CycleCount',                                  null,       null,                              null,                            1,      null,   1,                 null
/*----------------*/
insert into @UIMenu select 'OnhandInventory',       'Onhand Inventory',      'OnhandInventory',                             @UITarget,  'List.OnhandInventory',            'vwExportsOnhandInventory',      1,      null,   1,                 null
/*----------------*/
insert into @UIMenu select 'GenerateLocations',     'Generate Locations',    'GenLocations',                                @UITarget,  null,                              null,                            0,      null,   1,                 null

/*----------------*/
select @UITarget     = '/LPN/CreateInventory';

                       /* MenuId                    Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'CreateInventoryLPNs',   'Create Inventory',      'CreateInventoryLPNs',                         @UITarget,  null,                              null,                            1,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Main Menu Group 'Inventory' for Listings and Features */
delete from @UIMenu;
select @ParentMenuId = 'CycleCount',
       @UITarget     = '/Home/List';

                        /* MenuId                          Caption                        PermissionName,                           UITarget    ContextName,                       DBSource                                   Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'CycleCountLocations',          'Cycle Count Locations',       'CycleCountLocations',                    @UITarget,  'List.CycleCountLocations',        'pr_CycleCount_DS_GetLocationsToCount',    1,      null,   0,                 null
insert into @UIMenu select 'CycleCountTasks',              'Cycle Count Tasks',           'CycleCountTasks',                        @UITarget,  'List.CycleCountTasks',            'vwCycleCountTasks',                       1,      null,   0,                 null
insert into @UIMenu select 'CycleCountTaskDetails',        'Cycle Count Task Details',    'CycleCountTaskDetails',                  @UITarget,  'List.CycleCountTaskDetails',      'vwCycleCountTaskDetails',                 0,      null,   0,                 null
insert into @UIMenu select 'CycleCountStatistics',         'Cycle Count Statistics',      'CycleCountStatistics',                   @UITarget,  'List.CycleCountStatistics',       'pr_CycleCount_DS_GetResults',             1,      null,   0,                 null
insert into @UIMenu select 'CycleCountResults',            'Cycle Count Results',         'CycleCountStatistics',                   @UITarget,  'List.CycleCountResults',          'vwCycleCountResults',                     1,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Main Menu Group 'OrderProcessing'  */
delete from @UIMenu;
select @ParentMenuId = 'OrderProcessing',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'Orders',                'Orders',                'Orders',                                      @UITarget,  'List.Orders',                     'vwOrderHeaders',                1,      null,   0,                 null
insert into @UIMenu select 'OrderDetails',          'Order Details',         'OrderDetails',                                @UITarget,  'List.OrderDetails',               'vwOrderDetails',                1,      null,   0,                 null
/*----------------*/
/* Waves & Waving */
insert into @UIMenu select 'Waves',                 'Waves',                 'Waves',                                       @UITarget,  'List.Waves',                      'vwWaves',                       1,      null,   1,                 null

select @UITarget     = '/Home/Waving';

insert into @UIMenu select 'Waving',                'Manage Waves',          'ManageWaves',                                 @UITarget,  null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'WaveSummary',           'Wave Summary',          'GenericListing',                              @UITarget,  'List.WaveSummary',                'pr_UI_DS_WaveSummary',          0,      null,   0,                 null

/*----------------*/
/* Tasks */
select @UITarget     = '/Home/List';

insert into @UIMenu select 'Tasks',                 'Pick Tasks',            'PickTasks',                                   @UITarget,  'List.PickTasks',                  'vwUIPickTasks',                 1,      null,   1,                 null
insert into @UIMenu select 'TaskDetails',           'Pick Task Details',     'PickTaskDetails',                             @UITarget,  'List.PickTaskDetails',            'vwUIPickTaskDetails',           1,      null,   0,                 null

/*----------------*/
select @UITarget     = '/Home/Packing';

insert into @UIMenu select 'Packing',               'Packing',               'OrderPacking',                                @UITarget,  null,                              'pr_Packing_GetDetails_V3',      1,      null,   1,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Waving - These items are hidden, and are only used by application for processing */

delete from @UIMenu;
select @ParentMenuId = 'Waving',
       @UITarget     = '/Home/Waving'; /* UITarget has no relevance for the below two items */

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'WavingWaves',           'Open Waves',            'ManageWaves',                                 @UITarget,  'Waving.Waves',                    'vwWaves',                       0,      null,   0,                 null
insert into @UIMenu select 'WavingOrders',          'Orders To Wave',        'ManageWaves',                                 @UITarget,  'Waving.Orders',                   'vwOrdersToBatch',               0,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Replenishments */

delete from @UIMenu;
select @ParentMenuId = 'Replenishments',
       @UITarget     = '/Home/List'; /* UITarget has no relevance for the below two items */

                        /* MenuId                    Caption                    PermissionName,                            UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'ManageReplenishments',  'Manage Replenishments',   'ReplenishLocations',                       @UITarget,  'List.ReplenishmentLocations',     'pr_UI_DS_LocationsToReplenish', 1,      null,   0,                 null
insert into @UIMenu select 'ReplenishOrders',       'Replenish Orders',        'ReplenishOrders',                          @UITarget,  'List.ReplenishOrders',            'vwReplenishOrderHeaders',       1,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Main Menu Group 'Shipping' for Listings */
delete from @UIMenu;
select @ParentMenuId = 'Shipping',
       @UITarget     = '/Home/List';

                        /* MenuId                    Caption                 PermissionName,                                UITarget         ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'Loads',                  'Loads',                'Loads',                                       @UITarget,       'List.Loads',                      'vwLoads',                       1,      null,   0,                 null
insert into @UIMenu select 'ManageLoads',            'Manage Loads',         'ManageLoads',                                 @UIManageLoads,  null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'ShippingLog',            'Shipping Log',         'ShippingLog',                                 @UITarget,       'List.ShippingLog',                'pr_UI_DS_ShippingLog',          1,      null,   0,                 null
/*----------------*/
select @UITarget     = '/Home/ShippingDocs';

insert into @UIMenu select 'ShippingDocs',          'Shipping Documents',    'ShippingDocs',                                @UITarget,  null,                              null,                            1,      null,   1,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Shipping - These items are hidden, and are only used by application for processing */

delete from @UIMenu;
select @ParentMenuId = 'ManageLoads';

                        /* MenuId                   Caption                  PermissionName,                                UITarget         ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'OpenLoads',             'Open Loads',            'ManageLoads',                                 @UIManageLoads,  'ManageLoads.OpenLoads',        'vwLoadsToManage',               0,      null,   0,                 null
insert into @UIMenu select 'OrdersToShip',          'Orders To Ship',        'ManageLoads',                                 @UIManageLoads,  'ManageLoads.OrdersToShip',     'vwOrdersForLoads',              0,      null,   0,                 null
insert into @UIMenu select 'LoadOrders',            'Load Orders',           'ManageLoads',                                 @UIManageLoads,  'ManageLoads.LoadOrders',       'vwLoadOrders',                  0,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Main Menu Group 'Maintenance' for Listings */
delete from @UIMenu;
select @ParentMenuId = 'Maintenance',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'Access',                'Access & Privileges',   'Access&Privileges',                           @UITarget,  null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'SystemConfiguration',   'Lists & Controls',      'List&Controls',                               @UITarget,  null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'Integration',           'Data Exchange',         'DataExchange',                                @UITarget,  'List.Exports',                    'vwExports',                     1,      null,   0,                 null
insert into @UIMenu select 'SystemInfo',            'System Info',           'SystemInfo',                                  @UITarget,  null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'PrintCenter',           'Print Center',          'PrintCenter',                                 @UITarget,  null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'Analytics',             'Analytics',             'Analytics',                                   @UITarget,  null,                              null,                            1,      null,   1,                 null
insert into @UIMenu select 'ATEntity',              'Entity Audit Trail',    'GenericListing',                              @UITarget,  'List.ATEntity',                   'vwATEntity',                    0,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Maintenance Menu Group 'Access & Privileges' for Listings */
delete from @UIMenu;
select @ParentMenuId = 'Access',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'Users',                 'Users',                 'Users',                                       @UITarget,  'List.Users',                      'vwUsers',                       1,      null,   0,                 null
insert into @UIMenu select 'Roles',                 'Roles',                 'Roles',                                       @UITarget,  'List.Roles',                      'vwRoles',                       1,      null,   0,                 null
insert into @UIMenu select 'Permissions',           'Permissions',           'Permissions',                                 @UITarget,  'List.Permissions',                'vwPermissions',                 0,      null,   0,                 null
insert into @UIMenu select 'RolePermissions',       'Permissions',           'RolePermissions',                             @UITarget,  'List.RolePermissions',            'vwActiveUIRolePermissions',     1,      null,   0,                 null

/*----------------*/
select @UITarget = '/Home/ManagePermissions';

insert into @UIMenu select 'ManagePermissions',     'Manage Permissions',    'RolePermissions',                             @UITarget,  'List.ManagePermissions',          'pr_UI_DS_ManagePermissions',    1,      null,   1,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Maintenance Menu Group 'Configuration' for Listings */
delete from @UIMenu;
select @ParentMenuId = 'SystemConfiguration',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'LookUps',               'Lists',                 'Lookups',                                     @UITarget,  'List.LookUps',                    'vwUILookUps',                   1,      null,   0,                 null
insert into @UIMenu select 'Controls',              'System Controls',       'Controls',                                    @UITarget,  'List.Controls',                   'vwControls',                    1,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Maintenance Menu Group 'Integration' for Listings */
delete from @UIMenu;
select @ParentMenuId = 'Integration',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'Exports',               'Data Exports',          'Exports',                                     @UITarget,  'List.Exports',                    'vwExports',                     1,      null,   0,                 null
insert into @UIMenu select 'InterfaceLog',          'Interface Log',         'InterfaceLog',                                @UITarget,  'List.InterfaceLog',               'vwInterfaceLog',                1,      null,   0,                 null
insert into @UIMenu select 'InterfaceLogDetails',   'Interface Log Details', 'InterfaceLogDetails',                         @UITarget,  'List.InterfaceLogDetails',        'vwInterfaceLogDetails',         0,      null,   0,                 null
insert into @UIMenu select 'Mapping',               'Data Mappings',         'Mapping',                                     @UITarget,  'List.Mapping',                    'vwMapping',                     1,      null,   0,                 null
/*----------------*/
insert into @UIMenu select 'DEImportTables',        'DE Import Tables',      'ImportTables',                                null,       null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'DEExportTables',        'DE Export Tables',      'ExportTables',                                null,       null,                              null,                            1,      null,   0,                 null
/*----------------*/
insert into @UIMenu select 'APIInboundTransactions',     'API Inbound Transactions',   'APIInboundTransactions',                      @UITarget,  'List.APIInboundTransactions',     'APIInboundTransactions',        1,      null,   1,                 null
insert into @UIMenu select 'APIOutboundTransactions',    'API Outbound Transactions',  'APIOutboundTransactions',                     @UITarget,  'List.APIOutboundTransactions',    'APIOutboundTransactions',       1,      null,   0,                 null
/*----------------*/
select @UITarget     = '/Entity/ImportFiles';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'ImportFiles',          'Import Files',           'ImportFiles',                                 @UITarget,  null,                              null,                            1,      null,   1,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Main Menu Group 'Maintenance-SystemInfo' for Listings */
delete from @UIMenu;
select @ParentMenuId = 'SystemInfo',
       @UITarget     = null;

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'SI.UserInterface',      'User Interface',        'UserInterface',                               @UITarget,  null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'SI.SystemRules',        'System Rules',          'SystemRules',                                 @UITarget,  null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'SI.ShippingConfig',     'Shipping Configuration','ShippingConfig',                              @UITarget,  null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'SI.BaseTables',         'Base Tables',           'BaseTables',                                  @UITarget,  null,                              null,                            1,      null,   0,                 null
insert into @UIMenu select 'SI.DCMSTables',         'DCMS Tables',           'DCMSTables',                                  @UITarget,  null,                              null,                            1,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Main Menu Group 'Maintenance-PrintCenter' for Listings */
delete from @UIMenu;
select @ParentMenuId = 'PrintCenter',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'PC.PrintRequests',      'Print Requests',        'PrintRequests',                               @UITarget,  'List.PrintRequests',              'vwPrintRequests',               1,      null,   0,                 null
insert into @UIMenu select 'PC.PrintJobs',          'Print Jobs',            'PrintJobs',                                   @UITarget,  'List.PrintJobs',                  'vwPrintJobs',                   1,      null,   0,                 null
insert into @UIMenu select 'PC.PrintJobDetails',    'Print Job Details',     'PrintJobDetails',                             @UITarget,  'List.PrintJobDetails',            'vwPrintJobDetails',             0,      null,   0,                 null
insert into @UIMenu select 'PC.Printers',           'Printers',              'Printers',                                    @UITarget,  'List.Printers',                   'vwPrinters',                    1,      null,   0,                 null
/*----------------*/
insert into @UIMenu select 'PC.LabelFormats',       'Label Formats',         'LabelFormats',                                @UITarget,  'List.LabelFormats',               'vwLabelFormats',                1,      null,   1,                 null
insert into @UIMenu select 'PC.ReportFormats',      'Report Formats',        'ReportFormats',                               @UITarget,  'List.ReportFormats',              'vwReportFormats',               1,      null,   0,                 null
/*----------------*/
insert into @UIMenu select 'PC.ZPLLabelTemplates',  'ZPL Label Templates',   'ZPLLabelTemplates',                           @UITarget,  'List.ZPLLabelTemplates',          'vwContentTemplates',            1,      'I',    1,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Main Menu Group 'Maintenance-Analytics' for Listings */
delete from @UIMenu;
select @ParentMenuId = 'Analytics',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                                 Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'WarehouseMetrics',      'Warehouse Metrics',     'WarehouseKPI',                                @UITarget,  null,                              null,                                    1,      null,   0,                 null
insert into @UIMenu select 'ProductivitySummary',   'Productivity Summary',  'UserProductivity',                            @UITarget,  'List.SummaryProductivity',        'pr_Prod_DS_GetUserProductivity',        1,      null,   1,                 null
insert into @UIMenu select 'UserProductivity',      'User Productivity',     'UserProductivity',                            @UITarget,  'List.UserProductivity',           'vwProductivity',                        1,      null,   1,                 null
insert into @UIMenu select 'UserAuditLog',          'Audit Log',             'UserAuditLog',                                @UITarget,  'List.UserAuditLog',               'pr_AuditTrail_DS_GetAuditLog',          1,      null,   0,                 null
insert into @UIMenu select 'QCResults',             'QC Results'       ,     'QCResults',                                   @UITarget,  'List.QCResults',                  'vwQCResults',                           1,      null,   2,                 null
insert into @UIMenu select 'SKUVelocity',           'SKU Velocity',          'SKUVelocity',                                 @UITarget,  'List.SKUVelocity',                'vwSKUVelocity',                         1,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Main Menu Group 'Maintenance-Analytics-WarehouseMetrics' for Listings */
delete from @UIMenu;
select @ParentMenuId = 'WarehouseMetrics',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                                 Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'WHKPIPeriod',           'Summary By Period',     'WHKPIPeriod',                                 @UITarget,  'List.WHKPIPeriod',                'vwWarehouseKPI',                        1,      null,   0,                 null
insert into @UIMenu select 'WHKPICust',             'Summary By Customer',   'WHKPICust',                                   @UITarget,  'List.WHKPICust',                  'vwWarehouseKPI',                        1,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
delete from @UIMenu;
select @ParentMenuId = 'SI.DCMSTables',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'RouterInstructions',    'Router Instructions',   'RouterInstructions',                          @UITarget,  'List.RouterInstructions',         'vwRouterInstructions',          1,      null,   0,                 null
insert into @UIMenu select 'RouterConfirmations',   'Router Confirmations',  'RouterConfirmations',                         @UITarget,  'List.RouterConfirmations',        'vwRouterConfirmations',         1,      null,   0,                 null
insert into @UIMenu select 'PandALabels',           'Panda Labels',          'PandALabels',                                 @UITarget,  'List.PandALabels',                'vwPandALabels',                 1,      null,   1,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
delete from @UIMenu;
select @ParentMenuId = 'SI.UserInterface',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'Fields',                'Fields',                'Fields',                                      @UITarget,  'List.Fields',                     'vwFields',                      1,      null,   0,                 null
insert into @UIMenu select 'LayoutFields',          'Layout Fields',         'LayoutFields',                                @UITarget,  'List.LayoutFields',               'vwLayoutFields',                1,      null,   0,                 null
insert into @UIMenu select 'Layouts',               'Layouts',               'Layouts',                                     @UITarget,  'List.Layouts',                    'vwLayouts',                     1,      null,   0,                 null
insert into @UIMenu select 'Messages',              'Messages',              'Messages',                                    @UITarget,  'List.Messages',                   'vwMessages',                    1,      null,   0,                 null
insert into @UIMenu select 'Notifications',         'Notifications',         'Notifications',                               @UITarget,  'List.Notifications',              'vwNotifications',               0,      null,   0,                 null
insert into @UIMenu select 'Selections',            'Selections',            'Selections',                                  @UITarget,  'List.Selections',                 'Selections',                    1,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
delete from @UIMenu;
select @ParentMenuId = 'SI.ShippingConfig',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'ShipVias',              'Ship Vias',             'ShipVias',                                    @UITarget,  'List.ShipVias',                   'vwShipVias',                    1,      null,   0,                 null
insert into @UIMenu select 'ShippingAccounts',      'Shipping Accounts',     'ShippingAccounts',                            @UITarget,  'List.ShippingAccounts',           'vwShippingAccounts',            1,      null,   0,                 null
insert into @UIMenu select 'RoutingRules',          'Routing Rules',         'RoutingRules',                                @UITarget,  'List.RoutingRules',               'vwRoutingRules',                1,      null,   0,                 null
insert into @UIMenu select 'RoutingZones',          'Routing Zones',         'RoutingZones',                                @UITarget,  'List.RoutingZones',               'vwRoutingZones',                1,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
delete from @UIMenu;
select @ParentMenuId = 'SI.SystemRules',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
insert into @UIMenu select 'SI.RuleSets',           'Rule Sets',             'RuleSets',                                    @UITarget,  'List.RuleSets',                   'vwRuleSets',                    1,      null,   0,                 null
insert into @UIMenu select 'SI.Rules',              'Rules',                 'Rules',                                       @UITarget,  'List.Rules',                      'vwRules',                       1,      null,   0,                 null
insert into @UIMenu select 'SI.PutawayRules',       'Putaway Rules',         'PutawayRules',                                @UITarget,  'List.PutawayRules',               'vwPutawayRules',                1,      null,   0,                 null
insert into @UIMenu select 'SI.AllocationRules',    'Allocation Rules',      'AllocationRules',                             @UITarget,  'List.AllocationRules',            'vwAllocationRules',             1,      null,   0,                 null
insert into @UIMenu select 'SI.PickBatchRules',     'Waving Rules',          'PickBatchRules',                              @UITarget,  'List.PickBatchRules',             'vwBatchingRules',               1,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under System Info Sub Menu in Maintenance */
delete from @UIMenu;
select @ParentMenuId = 'SI.BaseTables',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                  PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName  */
insert into @UIMenu select 'Contacts',              'Contacts',              'Contacts',                                    @UITarget,  'List.Contacts',                   'vwContacts',                    1,      null,   0,                 null
insert into @UIMenu select 'Devices',               'Devices',               'Devices',                                     @UITarget,  'List.Devices',                    'vwDevices',                     1,      null,   0,                 null
insert into @UIMenu select 'Notes',                 'Notes',                 'Notes',                                       @UITarget,  'List.Notes',                      'vwNotes',                       1,      null,   0,                 null
insert into @UIMenu select 'SKUattributes',         'SKU Attributes',        'SKUAttributes',                               @UITarget,  'List.SKUattributes',              'vwSKUattributes',               0,      null,   0,                 null
insert into @UIMenu select 'CartonTypes',           'Carton Types',          'CartonTypes',                                 @UITarget,  'List.CartonTypes',                'vwCartonTypes',                 1,      null,   0,                 null
insert into @UIMenu select 'CartonGroups',          'Carton Groups',         'CartonGroups',                                @UITarget,  'List.CartonGroups',               'vwCartonGroupsAndTypes',        1,      null,   0,                 null
insert into @UIMenu select 'ShipLabels',            'Ship Labels',           'ShipLabels',                                  @UITarget,  'List.ShipLabels',                 'vwShipLabels',                  1,      null,   0,                 null
insert into @UIMenu select 'SKUPriceLists',         'SKU Price List',        'SKUPriceLists',                               @UITarget,  'List.SKUPriceLists',              'vwSKUPriceList',                1,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
delete from @UIMenu;
select @ParentMenuId = 'DEImportTables',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                       PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
/* Imports  DETables */
insert into @UIMenu select 'ImportSKUs',            'Import SKUs',                'ImportSKUs',                                  @UITarget,  'List.CIMSDE_ImportSKUs',          'vwCIMSDE_ImportSKUs',           1,      null,   0,                 null
insert into @UIMenu select 'ImportUPCs',            'Import UPCs',                'ImportUPCs',                                  @UITarget,  'List.CIMSDE_ImportUPCs',          'vwCIMSDE_ImportUPCs',           1,      null,   0,                 null
insert into @UIMenu select 'ImportSKUPrePacks',     'Import SKU PrePacks',        'ImportSKUPrePacks',                           @UITarget,  'List.CIMSDE_ImportSKUPrePacks',   'vwCIMSDE_ImportSKUPrePacks',    1,      null,   0,                 null
/*----------------*/
insert into @UIMenu select 'ImportReceiptHeaders',  'Import Receipt Headers',     'ImportReceiptHeaders',                        @UITarget,  'List.CIMSDE_ImportReceiptHeaders','vwCIMSDE_ImportReceiptHeaders', 1,      null,   1,                 null
insert into @UIMenu select 'ImportReceiptDetails',  'Import Receipt Details',     'ImportReceiptDetails',                        @UITarget,  'List.CIMSDE_ImportReceiptDetails','vwCIMSDE_ImportReceiptDetails', 1,      null,   0,                 null
insert into @UIMenu select 'ImportASNLPNs',         'Import ASN LPNs',            'ImportASNLPNs',                               @UITarget,  'List.CIMSDE_ImportASNLPNs',       'vwCIMSDE_ImportASNLPNs',        1,      null,   0,                 null
insert into @UIMenu select 'ImportASNLPNDetails',   'Import ASN LPN Details',     'ImportASNLPNDetails',                         @UITarget,  'List.CIMSDE_ImportASNLPNDetails', 'vwCIMSDE_ImportASNLPNDetails',  1,      null,   0,                 null
/*----------------*/
insert into @UIMenu select 'ImportContacts',        'Import Contacts',            'ImportContacts',                              @UITarget,  'List.CIMSDE_ImportContacts',      'vwCIMSDE_ImportContacts',       1,      null,   1,                 null
insert into @UIMenu select 'ImportOrderHeaders',    'Import Order Headers',       'ImportOrderHeaders',                          @UITarget,  'List.CIMSDE_ImportOrderHeaders',  'vwCIMSDE_ImportOrderHeaders',   1,      null,   0,                 null
insert into @UIMenu select 'ImportOrderDetails',    'Import Order Details',       'ImportOrderDetails',                          @UITarget,  'List.CIMSDE_ImportOrderDetails',  'vwCIMSDE_ImportOrderDetails',   1,      null,   0,                 null
/*----------------*/
insert into @UIMenu select 'ImportCartonTypes',     'Import Carton Types',        'ImportCartonTypes',                           @UITarget,  'List.CIMSDE_ImportCartonTypes',   'vwCIMSDE_ImportCartonTypes',    1,      null,   1,                 null
insert into @UIMenu select 'ImportNotes',           'Import Notes',               'ImportNotes',                                 @UITarget,  'List.CIMSDE_ImportNotes',         'vwCIMSDE_ImportNotes',          1,      null,   0,                 null
insert into @UIMenu select 'ImportResults',         'Import Results',             'ImportResults',                               @UITarget,  'List.CIMSDE_ImportResults',       'vwCIMSDE_ImportResults',        1,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
delete from @UIMenu;
select @ParentMenuId = 'DEExportTables',
       @UITarget     = '/Home/List';

                        /* MenuId                   Caption                       PermissionName,                                UITarget    ContextName,                       DBSource                         Visible Status  StartNewMenuGroup  HandlerTagName */
/* Export  DETables */
insert into @UIMenu select 'ExportTransactions',    'Export Transactions',        'ExportTransactions',                          @UITarget,  'List.CIMSDE_ExportTransactions',  'vwCIMSDE_ExportTransactions',   1,      null,   0,                 null
insert into @UIMenu select 'ExportOnhandInventory', 'Export Onhand Inventory',    'ExportOnhandInventory',                       @UITarget,  'List.CIMSDE_OnhandInventory',     'vwCIMSDE_ExportOnhandInventory',1,      null,   1,                 null
insert into @UIMenu select 'ExportOpenOrders',      'Export Open Orders',         'ExportOpenOrders',                            @UITarget,  'List.CIMSDE_OpenOrders',          'vwCIMSDE_ExportOpenOrders',     1,      null,   0,                 null
insert into @UIMenu select 'ExportOpenReceipts',    'Export Open Receipts',       'ExportOpenReceipts',                          @UITarget,  'List.CIMSDE_OpenReceipts',        'vwCIMSDE_ExportOpenReceipts',   1,      null,   0,                 null
insert into @UIMenu select 'ExportInvSnapshot',     'Export Inv Snapshot',        'ExportInvSnapshot',                           @UITarget,  'List.CIMSDE_ExportInvSnapshot',   'vwCIMSDE_ExportInvSnapshot',    1,      null,   0,                 null
insert into @UIMenu select 'ExportShippedLoads',    'Export Shipped Loads',       'ExportShippedLoads',                          @UITarget,  'List.CIMSDE_ShippedLoads',        'vwCIMSDE_ExportShippedLoads',   0,      null,   0,                 null

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

/*----------------------------------------------------------------------------*/
/* Items Under Dashboards Menu */
delete from @UIMenu;
select @ParentMenuId = 'Dashboards',
       @UITarget     = 'APPSETTINGS_DASHBOARDSAPPURL'; /* This will be replaced with the Dashboard Board application external url by UI application.The constant DASHBOARDSAPPURL is the name of App Setting in Web.Config with the value of the URL */
with DashboardsCategoryList(CategoryName,           CategoryCaption,         SortSeq) as
                   (select 'Receiving',             null,                    1
              union select 'Inventory',             null,                    2
              union select 'CycleCount',            'Cycle Count',           3
              union select 'Orders',                null,                    4
              union select 'Waves',                 null,                    5
              union select 'Replenishments',        null,                    6
              union select 'Picking',               null,                    7
              union select 'Packing',               null,                    8
              union select 'Shipping',              null,                    9
              union select 'Productivity',          null,                    10
              union select 'WarehouseMetrics',      'Warehouse Metrics',     11
                   )
                   /*       MenuId,               Caption                                  PermissionName,                 UITarget    ContextName,          DBSource            Visible  Status  StartNewMenuGroup  HandlerTagName  */
insert into @UIMenu select  CategoryName + 'DaB', coalesce(CategoryCaption, CategoryName), CategoryName + '.Dab',          @UITarget,  CategoryName,         null,               1,       null,   0,                 'ShowDashboard'
from DashboardsCategoryList
order by SortSeq;

exec pr_Setup_UIMenu @ParentMenuId, @UIMenu;

Go
