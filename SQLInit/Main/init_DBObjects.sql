/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/21  VM      Added ContentTemplatesDataSetup (CIMSV3-1109)
  2021/07/30  KBB     Added LocationLPNLabel (BK-446)
  2021/07/13  SK      Added pr_Prod_DS_GetUserProductivity (HA-2972)
  2021/07/08  NB      Added pr_UI_DS_ManagePermissions(CIMSV3-1341)
  2021/03/21  KBB     Added pr_Waves_GetLabelDataByStyle (HA-2365)
  2020/09/30  KBB     Added pr_UI_DS_ShippingLog (HA-1093)
  2020/09/01  AY      pr_CycleCount_DS_GetResults: Setup (CIMSV3-1026)
  2020/09/01  RKC     Changed the ResultSetDef for pr_UI_DS_WaveSummary (HA-1353)
  2020/08/18  KBB     Changed ObjectName for ReceiptLabel (HA-1326)
  2020/08/12  KBB     Added pr_Waves_GetLabelData (HA-1107)
  2020/07/13  MS      Added pr_CycleCount_DS_GetLocationsToCount (CIMSV3-548)
  2020/06/25  AY      Setup ResultSetDef for pr_ShipLabel_GetLPNDataAndContents (HA-1013)
  2020/06/19  NB      Added pr_UI_DS_LocationsToReplenish, pr_UI_DS_WaveSummary (CIMSV3-817)
  2020/05/13  MS      Added Exports (HA-350)
  2020/04/17  PHK     Added PrinterLabel (HA-98)
  2020/04/10  KBB     Changed the dbobjects name ReceiptOrderLabel(HA-50)
  2020/04/07  KBB     Changed the dbobjects name (HA-50)
  2020/03/27  PHK     Added ReceiptHeaders & Receivers (HA-50 & HA-51)
  2020/02/11  AY      Setup ResultSets for ZPL labels for entities (JL-39)
  2020/01/29  SPP     Updating DBObjects for pr_ShipLabel_GetLPNData (CID-1289)
  2019/12/27  RBV     Initial revision (CID-909)
------------------------------------------------------------------------------*/

Go

delete from DBObjects;

/*

This system function is supposed to return the data set for the DBObject. However, it doesn't always and
so we have to give definiton of the return data set i.e. a DataType or give the query etc. so system can
build the temp table to hold the result set when the procedure is run

select * from sys.dm_exec_describe_first_result_set_for_object(object_id('pr_Tasks_GetHeaderLabelData'), 0);

declare @SQL TSQL;
exec pr_PrepareDataSetDefinition 'pr_Tasks_EmployeeLabelData', @SQL out;
select @SQL;
*/

/******************************************************************************/
/* Insert the respective Result set Def for the DbObjects which is used to build
   the column of the temp table. This is particularly needed for datasets used
   for ZPL label printing */
/******************************************************************************/
declare @vSQL_GetLPNDataAndContents TSQL;

/* stored procedure pr_ShipLabel_GetLPNDataAndContents returns a combination of ShipLabel data and Contents data */
select @vSQL_GetLPNDataAndContents = 'declare @ttLPNData      TLPNShipLabelData;
                                      declare @ttLPNContents  TLPNContents;

                                      select * from @ttLPNData LD join @ttLPNContents LC on LD.LPN = LC_LPN'

insert into DBObjects
            (ObjectName,                              ResultSetDef,                           BusinessUnit)
      select 'pr_Shipping_GetLPNContentLabelData',    'TLPNContentsLabelData',                BU.BusinessUnit from vwBusinessUnits BU
union select 'pr_Tasks_GetHeaderLabelData',           null,                                   BU.BusinessUnit from vwBusinessUnits BU
union select 'pr_ShipLabel_GetLPNData',               'TLPNShipLabelData',                    BU.BusinessUnit from vwBusinessUnits BU
union select 'pr_ShipLabel_PriceStickers_GetData',    'TShipLabel_PriceStickers_GetData',     BU.BusinessUnit from vwBusinessUnits BU
union select 'pr_Tasks_GetEmployeeLabelData',         null,                                   BU.BusinessUnit from vwBusinessUnits BU
union select 'pr_ShipLabel_GetLPNDataAndContents',    @vSQL_GetLPNDataAndContents,            BU.BusinessUnit from vwBusinessUnits BU
/* UI Datasource procedures */
union select 'pr_CycleCount_DS_GetLocationsToCount',  'TLocationsToCycleCountData',           BU.BusinessUnit from vwBusinessUnits BU
union select 'pr_CycleCount_DS_GetResults',           'TCycleCountVariance',                  BU.BusinessUnit from vwBusinessUnits BU
union select 'pr_OrderHeaders_DS_GetAddresses',       'TOrderAddressesData',                  BU.BusinessUnit from vwBusinessUnits BU
union select 'pr_UI_DS_LocationsToReplenish',         'TLocationsToReplenishData',            BU.BusinessUnit from vwBusinessUnits BU
union select 'pr_UI_DS_ManagePermissions',            'vwActiveUIRolePermissions',            BU.BusinessUnit from vwBusinessUnits BU
union select 'pr_UI_DS_WaveSummary',                  'TWaveSummary',                         BU.BusinessUnit from vwBusinessUnits BU
union select 'pr_UI_DS_ShippingLog',                  'TShippingLogData',                     BU.BusinessUnit from vwBusinessUnits BU
union select 'pr_Waves_GetLabelData',                 null,                                   BU.BusinessUnit from vwBusinessUnits BU
union select 'pr_Waves_GetLabelDataByStyle',          null,                                   BU.BusinessUnit from vwBusinessUnits BU
union select 'pr_Prod_DS_GetUserProductivity',        'TUserProductivity',                    BU.BusinessUnit from vwBusinessUnits BU

/* Entity Labels */
union select 'LocationLabel',                         'vwLocations',                          BU.BusinessUnit from vwBusinessUnits BU
union select 'LocationLPNLabel',                      'vwLocationLPNs',                       BU.BusinessUnit from vwBusinessUnits BU
union select 'LoadLabel',                             'vwLoads',                              BU.BusinessUnit from vwBusinessUnits BU
union select 'LPNLabel',                              'vwLPNs',                               BU.BusinessUnit from vwBusinessUnits BU
union select 'PalletLabel',                           'vwPallets',                            BU.BusinessUnit from vwBusinessUnits BU
union select 'ReceiptLabel',                          'vwReceiptHeaders',                     BU.BusinessUnit from vwBusinessUnits BU
union select 'ReceiverLabel',                         'vwReceivers',                          BU.BusinessUnit from vwBusinessUnits BU
union select 'SKULabel',                              'vwSKUs',                               BU.BusinessUnit from vwBusinessUnits BU
union select 'UserLabel',                             'vwUsers',                              BU.BusinessUnit from vwBusinessUnits BU
union select 'WaveLabel',                             'vwWaves',                              BU.BusinessUnit from vwBusinessUnits BU
union select 'PrinterLabel',                          'vwPrinters',                           BU.BusinessUnit from vwBusinessUnits BU
/* Exports */
union select 'Exports',                               'Exports',                              BU.BusinessUnit from vwBusinessUnits BU

/* DataSetup */
union select 'ContentTemplatesDataSetup',             'TContentTemplates',                    BU.BusinessUnit from vwBusinessUnits BU

/*******************************************************************************
  Let system prepare the Temp table SQL
*******************************************************************************/
exec pr_PrepareHashTable 'pr_ShipLabel_GetLPNData',            null /* Temp Table Name */;
exec pr_PrepareHashTable 'pr_ShipLabel_GetLPNDataAndContents', null /* Temp Table Name */;
exec pr_PrepareHashTable 'pr_ShipLabel_PriceStickers_GetData', null /* Temp Table Name */;
exec pr_PrepareHashTable 'pr_Shipping_GetLPNContentLabelData', null /* Temp Table Name */;
exec pr_PrepareHashTable 'pr_Tasks_GetHeaderLabelData',        null /* Temp Table Name */;
exec pr_PrepareHashTable 'pr_Tasks_GetEmployeeLabelData',      null /* Temp Table Name */;

/* UI Datasource procedures */
exec pr_PrepareHashTable 'pr_CycleCount_DS_GetLocationsToCount',null /* Temp Table Name */;
exec pr_PrepareHashTable 'pr_CycleCount_DS_GetResults',         null /* Temp Table Name */;
exec pr_PrepareHashTable 'pr_OrderHeaders_DS_GetAddresses',     null /* Temp Table Name */;
exec pr_PrepareHashTable 'pr_UI_DS_LocationsToReplenish',       null /* Temp Table Name */;
exec pr_PrepareHashTable 'pr_UI_DS_WaveSummary',                null /* Temp Table Name */;
exec pr_PrepareHashTable 'pr_UI_DS_ShippingLog',                null /* Temp Table Name */;
exec pr_PrepareHashTable 'pr_Waves_GetLabelDataByStyle',        null /* Temp Table Name */;
exec pr_PrepareHashTable 'pr_Prod_DS_GetUserProductivity',      null /* Temp Table Name */;

/* Entity Labels */
exec pr_PrepareHashTable 'LocationLabel',      null /* Temp Table Name */;
exec pr_PrepareHashTable 'LoadLabel',          null /* Temp Table Name */;
exec pr_PrepareHashTable 'LPNLabel',           null /* Temp Table Name */;
exec pr_PrepareHashTable 'PalletLabel',        null /* Temp Table Name */;
exec pr_PrepareHashTable 'ReceiptLabel',       null /* Temp Table Name */;
exec pr_PrepareHashTable 'ReceiverLabel',      null /* Temp Table Name */;
exec pr_PrepareHashTable 'SKULabel',           null /* Temp Table Name */;
exec pr_PrepareHashTable 'UserLabel',          null /* Temp Table Name */;
exec pr_PrepareHashTable 'WaveLabel',          null /* Temp Table Name */;
exec pr_PrepareHashTable 'PrinterLabel',       null /* Temp Table Name */;
/* Exports */
exec pr_PrepareHashTable 'Exports',            null /* Temp Table Name */;
/* DataSetup */
exec pr_PrepareHashTable 'ContentTemplatesDataSetup',
                                               null /* Temp Table Name */;

Go
