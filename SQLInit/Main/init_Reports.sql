/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/11/07  CHP     Added CC_Rpt_ResultsList (BK-1150)
  2024/11/06  RV      Added OnhandInventory_Rpt_InvSnapshot (BK-1149)
  2021/03/23  MS      Use VICSBoLMaster RDLC for Loads_Rpt_BoL_Account (HA-2386)
  2021/03/10  PHK     Added Loads_Rpt_BoL_Account (HA-2098)
  2021/03/03  SK      Added Loads_Rpt_ShipManifestSummary
                      Modified Loads_Rpt_ShipManifest to Loads_Rpt_ShippingManifest (HA-2103)
  2021/02/15  RBV/KBB Added Locations.Rpt.PalletList Report (HA_1923)
  2020/11/27  MS      Added NumRecordsPerPage, AdditionalReportName, SupplementReport (CIMSV3-1250)
  2020/11/22  RV      Corrected Report template names (CIMSV3-1189)
  2020/11/21  MS      Added PackingLists (CIMSV3-1214)
  2020/10/22  SJ      Added ShipManifest report for Loads (HA-1593)
  2020/09/13  MS      Corrected reportname for palletlisting (JL-247)
  2020/08/04  NB      Initial Revision (CIMSV3-1022)
------------------------------------------------------------------------------*/

Go

declare @EntityType TEntity;

/*------------------------------------------------------------------------------*/
select @EntityType = 'Load';

delete from Reports where EntityType = @EntityType;

insert into Reports
            (EntityType,  ReportName,                      ReportDescription,                ReportTemplateName,                       ReportSchema,       ReportProcedureName,                   ReportFileName,                                                                       ReportDisplayName,                                     FolderName, DocumentType,        DocumentSubType, DocumentSet,           BusinessUnit)
      select @EntityType, 'Loads_Rpt_BoL',                 'Load BoLs',                      'VICSBoLMaster.rdlc',                     'VICSBoL',          'pr_Shipping_GetBoLData_V3',           'VICSBoL_~SELECTEDRECORDVALUE_EntityId~_~SYSTEMVALUE_CURRENTTIMESTAMP~',              '~SELECTEDRECORDVALUE_EntityKey~_VICSBoL',             null,       'Dynamic',           'RDLC',          'LoadReports',         BusinessUnit from vwBusinessUnits
union select @EntityType, 'Loads_Rpt_BoL_Account',         'Load BoLs for Account',          'VICSBoLMaster.rdlc',                     'VICSBoL',          'pr_Shipping_GetBoLData_V3',           'VICSBoL_~SELECTEDRECORDVALUE_EntityId~_~SYSTEMVALUE_CURRENTTIMESTAMP~',              '~SELECTEDRECORDVALUE_EntityKey~_VICSBoL',             null,       'Dynamic',           'RDLC',          'LoadReports',         BusinessUnit from vwBusinessUnits
union select @EntityType, 'Loads_Rpt_ShippingManifest',    'Load Shipping Manifest',         'ShippingManifestMaster.rdlc',            'ShippingManifest', 'pr_Shipping_ShipManifest_GetData',    'ShippingManifest_~SELECTEDRECORDVALUE_EntityKey~_~SYSTEMVALUE_CURRENTTIMESTAMP~',    '~SELECTEDRECORDVALUE_EntityKey~_Manifest',            null,       'SM',                'RDLC',          'LoadReports',         BusinessUnit from vwBusinessUnits
union select @EntityType, 'Loads_Rpt_ShipManifestSummary', 'Load Shipping Manifest Summary', 'ShippingManifestMaster_Summary.rdlc',    'ShippingManifest', 'pr_Shipping_ShipManifest_GetData',    'ShippingManifest_~SELECTEDRECORDVALUE_EntityKey~_~SYSTEMVALUE_CURRENTTIMESTAMP~',    '~SELECTEDRECORDVALUE_EntityKey~_ManifestSummary',     null,       'SM',                'RDLC',          'LoadReports',         BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
select @EntityType = 'Location';

delete from Reports where EntityType = @EntityType;

insert into Reports
            (EntityType,  ReportName,                      ReportDescription,   ReportTemplateName,            ReportSchema,           ReportProcedureName,           ReportFileName,                                                                     ReportDisplayName,                                   FolderName, DocumentType,       DocumentSubType, DocumentSet,           ReportXMLType, BusinessUnit)
      select @EntityType, 'Locations_Rpt_LPNList',         'Location LPNs',     'Locations_Rpt_LPNList.rdlc',  'LocationsLPNList',     'pr_Locations_Rpt_LPNList',    'LPNList_~SYSTEMVALUE_CURRENTTIMESTAMP~',                                           'LPN List',                                          null,       'Dynamic',          'RDLC',          'LocationsLPNList',    'M',           BusinessUnit from vwBusinessUnits
union select @EntityType, 'Locations_Rpt_PalletList',      'Location Pallets',  'Locations_Rpt_PalletList.rdlc',
                                                                                                               'LocationsLPNList',     'pr_Locations_Rpt_LPNList',    'LPNList_~SYSTEMVALUE_CURRENTTIMESTAMP~',                                           'Pallet List',                                       null,       'Dynamic',          'RDLC',          'LocationsLPNList',    'M',           BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* OnhandInventory */
/*------------------------------------------------------------------------------*/
delete from #Reports;
select @EntityType = 'OnhandInventory';

insert into #Reports
            (ReportName,                              ReportDescription,                        ReportTemplateName,                          AdditionalReportName,                   PageModel,        ReportSchema,       ReportProcedureName,                  ReportFileName,                                ReportDisplayName,                            FolderName, DocumentType,   DocumentSubType, DocumentSet,         ReportXMLType, Status, Visible)
      select 'OnhandInventory_Rpt_InvSnapshot',       'Onhand Inventory Snapshot',              'OnhandInventory_Rpt_InvSnapshot.rdlc',      null,                                   'M',              'OnhandInventory',  'pr_Inventory_Rpt_InvSnapshot',       'InvSnapshot_~SYSTEMVALUE_CURRENTTIMESTAMP~',  'InvSnapshot_~SYSTEMVALUE_CURRENTTIMESTAMP~', null,       'Dynamic',      'RDLC',          'OnhandInvSnapshot', 'M',           'A',    'Y'

/*------------------------------------------------------------------------------*/
select @EntityType = 'Order';

delete from Reports where EntityType = @EntityType;

insert into Reports
            (EntityType,  ReportName,                              ReportDescription,                        ReportTemplateName,                          AdditionalReportName,                   PageModel,        ReportSchema,       ReportProcedureName,           ReportFileName,    ReportDisplayName,  FolderName, DocumentType,   DocumentSubType, DocumentSet,   NumRecordsPerPage, BusinessUnit)
      select @EntityType, 'PackingList_CIMS_Standard',             'CIMS Std Packing List',                  'PackingList_CIMS_Standard.rdlc',            null,                                   null,             'PackingList',      null,                          null,              null,               null,       'PL',           'RDLC',          null,          null,              BusinessUnit from vwBusinessUnits
union select @EntityType, 'PackingList_CIMS_Standard_ComboPL',     'CIMS Std Combo Packing List',            'PackingList_CIMS_Standard_ComboPL.rdlc',    'PackingList_CIMS_Standard_ComboPL_AP', 'M,A',            'PackingList',      null,                          null,              null,               null,       'PL',           'RDLC',          null,          27,                BusinessUnit from vwBusinessUnits
union select @EntityType, 'PackingList_CIMS_Standard_ComboPL_AP',  'CIMS Std Combo Supplement Packing List', 'PackingList_CIMS_Standard_ComboPL_AP.rdlc', 'PackingList_CIMS_Standard_ComboPL',    'S,A',            'PackingList',      null,                          null,              null,               null,       'PL',           'RDLC',          null,          32,                BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
select @EntityType = 'Receipt';

delete from Reports where EntityType = @EntityType;

insert into Reports
            (EntityType,  ReportName,                      ReportDescription,   ReportTemplateName,               ReportSchema,      ReportProcedureName,               ReportFileName,                                                                    ReportDisplayName,                                  FolderName, DocumentType,          DocumentSubType, DocumentSet,           BusinessUnit)
      select @EntityType, 'Receipts_Rpt_ReceivingSummary', 'Receiving Summary', 'Receipts_ReceivingSummary.rdlc', 'ReceivingReport', 'pr_Receipts_ReceivingReport_V3',  'ReceivingSummary_~SELECTEDRECORDVALUE_EntityKey~_~SYSTEMVALUE_CURRENTTIMESTAMP~', '~SELECTEDRECORDVALUE_EntityKey~_ReceivingSummary', null,       'Dynamic',             'RDLC',          'ReceivingReports',    BusinessUnit from vwBusinessUnits
union select @EntityType, 'Receipts_Rpt_PalletListing',    'Receiving Pallets', 'Receipts_PalletListing.rdlc',    'ReceivingReport', 'pr_Receipts_ReceivingReport_V3',  'ReceivingPallets_~SELECTEDRECORDVALUE_EntityKey~_~SYSTEMVALUE_CURRENTTIMESTAMP~', '~SELECTEDRECORDVALUE_EntityKey~_ReceivingPallets', null,       'Dynamic',             'RDLC',          'ReceivingReports',    BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
select @EntityType = 'ReplenishmentLocations';

delete from Reports where EntityType = @EntityType;

insert into Reports
            (EntityType,  ReportName,                      ReportDescription,      ReportTemplateName,            ReportSchema,           ReportProcedureName,             ReportFileName,                                                                     ReportDisplayName,                                  FolderName, DocumentType,          DocumentSubType, DocumentSet,                        BusinessUnit)
      select @EntityType, 'ReplenishLocations_Rpt_PrintReplenishReport',
                                                           'Replenish Locations',  'LocationsToReplenish.rdlc',   'LocationsToReplenish', 'pr_Replenish_GetReportData_V3', 'ReplenishLocations_~SELECTEDRECORDVALUE_EntityId~_~SYSTEMVALUE_CURRENTTIMESTAMP~', '~SELECTEDRECORDVALUE_EntityKey~_ReceivingSummary', null,       'Dynamic',             'RDLC',          'ReplenishmentLocationsReports',    BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
select @EntityType = 'Wave';

delete from Reports where EntityType = @EntityType;

insert into Reports
            (EntityType,  ReportName,                      ReportDescription,      ReportTemplateName,            ReportSchema,           ReportProcedureName,              ReportFileName,                                                                     ReportDisplayName,                                  FolderName, DocumentType,   DocumentSubType, DocumentSet,                        BusinessUnit)
      select @EntityType, 'Waves_Rpt_WaveSKUSummary',      'Wave Summary',         'WaveSKUSummary.rdlc',         'WaveSKUSummary',       'pr_Waves_Rpt_GetSKUSummaryData', 'WaveSKUSummary_~SELECTEDRECORDVALUE_EntityKey~_~SYSTEMVALUE_CURRENTTIMESTAMP~',    '~SELECTEDRECORDVALUE_EntityKey~_WaveSKUSummary',   null,       'Dynamic',      'RDLC',          'WaveSummary',                      BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* CycleCountResults */
/*------------------------------------------------------------------------------*/
select @EntityType = 'CycleCountResults';

delete from Reports where EntityType = @EntityType;

insert into Reports
            (EntityType,  ReportName,                      ReportDescription,      ReportTemplateName,            ReportSchema,           ReportProcedureName,              ReportFileName,                                                                     ReportDisplayName,                                  FolderName, DocumentType,   DocumentSubType, DocumentSet,                        ReportXMLType, Status, Visible, BusinessUnit)
      select @EntityType, 'CC_Rpt_ResultsList',            'CC Results',           'CC_Rpt_ResultsList.rdlc',     'CCResultsList',        'pr_CC_Rpt_CCResultsList',        'CCResultsList_~SYSTEMVALUE_CURRENTTIMESTAMP~',                                     null,                                               null,       'Dynamic',      'RDLC',          'CCResultsList',                    'M',           'A',    'Y',     BusinessUnit from vwBusinessUnits

Go
