/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/24  MS      Setup ShipLabels Tab (HA-2406)
  2020/06/10  MS      Setup Addresses Tab (HA-861)
  2020/05/17  MS      Setup EntityInfo for OrderHeaders (HA-568)
  2018/07/12  NB      Changed Caption for OrderDetails to Order Lines, PickTicketDetails to PickTasks (CIMSV3-298)
  2018/03/20  NB      Changed ContextName to be unique for Listings within EntityInfo(CIMSV3-151)
  2018/01/25  NB      Initial revision(CIMSV3-151)
------------------------------------------------------------------------------*/

Go

declare @EntityType  TName;

select @EntityType = 'OH_EntityInfo'; /* Order Header */

delete from UIEntityInfo where (EntityType = @EntityType);

insert into UIEntityInfo
            (EntityType,   RelationType,  DisplayCaption,     ContextName,                     LayoutDescription,  SelectionName,  ContentType,  DbSourceType,  DbSource,                      FormName,                   BusinessUnit)
      select @EntityType,  'P',           null,               @EntityType + '_Main',           null,               null,           'Html',       null,          null,                          'OH_EntityInfo_Parent',     BusinessUnit from vwBusinessUnits
/* Summary of Entity */
union select @EntityType,  'D',           null,               @EntityType + '_SummaryInfo',    'Standard',         @EntityType,    'Html',       'P',           'pr_Entities_GetSummaryInfo',  'OH_EntityInfo_SummaryForm',BusinessUnit from vwBusinessUnits
/* Header */
union select @EntityType,  'D',           'Order Header',     @EntityType + '_OrderHeader',    'Standard',         @EntityType,    'Html',       'P',           'pr_Entities_GetSummaryInfo',  '~RULEVALUE~',              BusinessUnit from vwBusinessUnits
/* Details/Tabs */
union select @EntityType,  'D',           'Order Lines',      @EntityType + '_OrderDetails',   'Standard',         @EntityType,    'List',       'V',           'vwOrderDetails',              null,                       BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'LPNs',             @EntityType + '_LPNs',           'Standard',         @EntityType,    'List',       'V',           'vwLPNs',                      null,                       BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'LPN Details',      @EntityType + '_LPNDetails',     'Standard',         @EntityType,    'List',       'V',           'vwLPNDetails',                null,                       BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Pick Tasks',       @EntityType + '_PickTasks',      'Standard',         @EntityType,    'List',       'V',           'vwUIPickTasks',               null,                       BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Picks',            @EntityType + '_PickTaskDetails','Standard',         @EntityType,    'List',       'V',           'vwUIPickTaskDetails',         null,                       BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Ship Labels',      @EntityType + '_ShipLabels',     'Standard',         @EntityType,    'List',       'V',           'vwShipLabels',                null,                       BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Addresses',        @EntityType + '_Addresses',      'Standard',         @EntityType,    'List',       'P',           'pr_OrderHeaders_DS_GetAddresses',
                                                                                                                                                                                               null,                       BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Notifications',    @EntityType + '_Notifications',  'Standard',         @EntityType,    'List',       'V',           'vwNotifications',             null,                       BusinessUnit from vwBusinessUnits
--union select @EntityType,  'D',           'Notes',            @EntityType + '_Notes',          'Standard',         @EntityType,    'List',       'V',           'vwNotes',                     null,                       BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Audit Trail',      @EntityType + '_AuditTrail',     'Standard',         @EntityType,    'List',       'V',           'vwATEntity',                  null,                       BusinessUnit from vwBusinessUnits

Go
