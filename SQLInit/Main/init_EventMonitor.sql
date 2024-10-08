/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/08/29  RV      Added and removed EventNames (S2G-1096)
  2018/07/03  RV      Added ShippingDocsExport_1 and GenerateLabels_1 to send email alert while not running the tools (S2G-351)
  2016/09/08  AY/NY   Clean up and standardize the EventNames (HPI-502)
  2016/04/04  NY      Added temp table to insert the data into EventMonitor (NBD-299)
  2016/03/31  NY      Added the possible Events for DE
  2015/03/26  NB      Added additional fields in init for tracking and email updates
  2015/03/23  NB      Initial Revision
------------------------------------------------------------------------------*/

delete from EventMonitor;

Go

declare @vEventType    TEntity,
        @vSupportEmail TVarChar,
        @vClientEmail  TVarChar;

/* Create a temp table to hold the values to insert */
declare @ttEventMonitor table (RecordId       TRecordId    identity (1,1) not null,
                               EventName      TName,
                               AlertInterval  TInteger,
                               AlertType      TFlags,
                               TrackEvent     TFlags,
                               EventDetails   TVarchar,
                               AlertMessage   TVarChar);

select @vEventType    = 'JOB',
       @vSupportEmail = 'support@cloudimsystems.com',
       @vClientEmail  = null;

delete from @ttEventMonitor;

insert into @ttEventMonitor
            (EventName,                    AlertInterval,   AlertType,        TrackEvent,    EventDetails,   AlertMessage)
      select 'DE-Import_PDV',              5,               'E'/* E-Mail */,  'S',           null,           null
union select 'DE-Import_CSV',              5,               'E'/* E-Mail */,  'S',           null,           null
union select 'DE-Import_EDI',              5,               'E'/* E-Mail */,  'S',           null,           null
union select 'DE-Import_XML',              5,               'E'/* E-Mail */,  'S',           null,           null
union select 'DE-Import_FWF',              5,               'E'/* E-Mail */,  'S',           null,           null

/* Inventory Onhand Export */
union select 'DE-ExportInvOH_CSV',         60,              'E'/* E-Mail */,  'S',           null,           null
union select 'DE-ExportInvOH_XML',         60,              'E'/* E-Mail */,  'S',           null,           null

/* All transactions in one file */
union select 'DE-ExportTrans_CSV',         10,              'E'/* E-Mail */,  'S',           null,           null
union select 'DE-ExportTrans_EDI',         10,              'E'/* E-Mail */,  'S',           null,           null
union select 'DE-ExportTrans_FWF',         10,              'E'/* E-Mail */,  'S',           null,           null
union select 'DE-ExportTrans_XML',         10,              'E'/* E-Mail */,  'S',           null,           null

/* Transactions separated into diff. files - CSV */
union select 'DE-ExportInvCh_CSV',         10,              'E'/* E-Mail */,  'S',           null,           null
union select 'DE-ExportRecv_CSV',          10,              'E'/* E-Mail */,  'S',           null,           null
union select 'DE-ExportShip_CSV',          10,              'E'/* E-Mail */,  'S',           null,           null
union select 'DE-ExportWhXFer_CSV',        10,              'E'/* E-Mail */,  'S',           null,           null

/* Transactions separated into diff. files - XML */
union select 'DE-ExportInvCh_XML',         10,              'E'/* E-Mail */,  'S',           null,           null
union select 'DE-ExportRecv_XML',          10,              'E'/* E-Mail */,  'S',           null,           null
union select 'DE-ExportShip_XML',          10,              'E'/* E-Mail */,  'S',           null,           null
union select 'DE-ExportWhXFer_XML',        10,              'E'/* E-Mail */,  'S',           null,           null

union select 'DE-ExportOpenOrders_CSV',    10,              'E'/* E-Mail */,  'S',           null,           null
union select 'DE-ExportOpenReceipts_CSV',  10,              'E'/* E-Mail */,  'S',           null,           null

union select 'DE-ExportLMSData_FWF',       60,              'E'/* E-Mail */,  'S',           null,           null

union select 'ShippingDocsExport_1',       5,               'E'/* E-Mail */,  'S',           null,           null
union select 'ShippingDocsExport_2',       5,               'E'/* E-Mail */,  'S',           null,           null
union select 'ShippingDocsExport_3',       5,               'E'/* E-Mail */,  'S',           null,           null

union select 'GenearateLabels_1',          5,               'E'/* E-Mail */,  'S',           null,           null

insert into EventMonitor (EventType, EventName, AlertInterval, AlertType, SupportEmail, ClientEmail, TrackEvent, EventDetails, AlertMessage, BusinessUnit)
  select @vEventType, TE.EventName, TE.AlertInterval, TE.AlertType, @vSupportEmail, @vClientEmail, TE.TrackEvent, TE.EventDetails, TE.AlertMessage, BusinessUnit
  from vwBusinessUnits join @ttEventMonitor TE on (TE.RecordId <> 0)
  where TE.TrackEvent = 'S';

Go
