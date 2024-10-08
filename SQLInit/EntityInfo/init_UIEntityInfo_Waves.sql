/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/24  MS      Setup ShipLabels Tab (HA-2406)
  2021/03/23  TK      Added Wave Summary tab (HA-2381)
  2020/10/08  NB      Removed SelectioName value from List entries as the selection name is no longer valid (CIMSV3-1122)
  2020/05/29  TK      Corrections to LPNs & LPNDetails (HA-691)
  2020/05/18  MS      Initial revision(HA-569)
------------------------------------------------------------------------------*/

Go

declare @EntityType  TName;

select @EntityType = 'Wave_EntityInfo'; /* Wave */

delete from UIEntityInfo where (EntityType = @EntityType);

insert into UIEntityInfo
            (EntityType,   RelationType,  DisplayCaption,     ContextName,                       LayoutDescription,  SelectionName,  ContentType,  DbSourceType,  DbSource,                           FormName,                     BusinessUnit)
      select @EntityType,  'P',           null,               @EntityType + '_Main',             null,               null,           'Html',       null,          null,                               'Wave_EntityInfo_Parent',     BusinessUnit from vwBusinessUnits
/* Summary of Entity */
union select @EntityType,  'D',           null,               @EntityType + '_SummaryInfo',      'Standard',         @EntityType,    'Html',       'P',           'pr_Entities_GetSummaryInfo',       @EntityType + '_SummaryForm', BusinessUnit from vwBusinessUnits
/* Header */
-- None defined at this time
/* Details/Tabs */
union select @EntityType,  'D',           'Summary',          @EntityType + '_WaveSummary',      'Standard',         null,           'List',       'P',           'pr_UI_DS_WaveSummary',             null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Orders',           @EntityType + '_Orders',           'Standard',         null,           'List',       'V',           'vwOrderHeaders',                   null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Order Details',    @EntityType + '_OrderDetails',     'Standard',         null,           'List',       'V',           'vwOrderDetails',                   null,                         BusinessUnit from vwBusinessUnits
--union select @EntityType,  'D',           'Pallets',          @EntityType + '_Pallets',          'Standard',         null,           'List',       'V',           'vwPallets',                        null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Pick Tasks',       @EntityType + '_PickTasks',        'Standard',         null,           'List',       'V',           'vwUIPickTasks',                    null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Picks',            @EntityType + '_PickTaskDetails',  'Standard',         null,           'List',       'V',           'vwUIPickTaskDetails',              null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'LPNs',             @EntityType + '_LPNs',             'Standard',         null,           'List',       'V',           'vwLPNs',                           null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'LPNDetails',       @EntityType + '_LPNDetails',       'Standard',         null,           'List',       'V',           'vwLPNDetails',                     null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Ship Labels',      @EntityType + '_ShipLabels',       'Standard',         @EntityType,    'List',       'V',           'vwShipLabels',                     null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Notifications',    @EntityType + '_Notifications',    'Standard',         null,           'List',       'V',           'vwNotifications',                  null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Audit Trail',      @EntityType + '_AuditTrail',       'Standard',         null,           'List',       'V',           'vwATEntity',                       null,                         BusinessUnit from vwBusinessUnits

Go
