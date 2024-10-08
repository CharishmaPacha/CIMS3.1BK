/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/21  OK      Added Notifications (CIMSV3-1232)
  2020/07/17  MRK     Added Summary By Status as default layout (HA-982)
  2020/06/09  MS      Added OrderHeaders, LPNs, Pallets Tabs (HA-858)
  2020/06/08  RT      Intial Revision
------------------------------------------------------------------------------*/

Go

declare @EntityType  TName;

select @EntityType = 'Load_EntityInfo'; /* Load */

delete from UIEntityInfo where (EntityType = @EntityType);

insert into UIEntityInfo
            (EntityType,   RelationType,  DisplayCaption,           ContextName,                        LayoutDescription,  SelectionName,  ContentType,  DbSourceType,  DbSource,               FormName,                     BusinessUnit)
      select @EntityType,  'P',           null,                     @EntityType + '_Main',              null,               null,           'Html',       null,          null,                   'Load_EntityInfo_Parent',     BusinessUnit from vwBusinessUnits
/* Summary of Entity */
union select @EntityType,  'D',           null,                     @EntityType + '_SummaryInfo',       'Standard',         @EntityType,    'Html',       'P',           'pr_Entities_GetSummaryInfo',
                                                                                                                                                                                                 'Load_EntityInfo_SummaryForm',BusinessUnit from vwBusinessUnits
/* Header */
-- None defined at this time
/* Details/Tabs */
union select @EntityType,  'D',           'Orders',                 @EntityType + '_Orders',            'Standard',                  @EntityType,    'List',       'V',           'vwLoadOrders',         null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'LPNs',                   @EntityType + '_LPNs',              'By Pallet & Status',        @EntityType,    'List',       'V',           'vwLPNs',               null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Pallets',                @EntityType + '_Pallets',           'Standard',                  @EntityType,    'List',       'V',           'vwPallets',            null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'BoLs',                   @EntityType + '_BoLs',              'Standard',                  @EntityType,    'List',       'V',           'vwBoLs',               null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'BoL Order Details',      @EntityType + '_BoLOrderDetails',   'Standard',                  @EntityType,    'List',       'V',           'vwBoLOrderDetails',    null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'BoL Carrier Details',    @EntityType + '_BoLCarrierDetails', 'Standard',                  @EntityType,    'List',       'V',           'vwBoLCarrierDetails',  null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Notifications',          @EntityType + '_Notifications',     'Standard',                  @EntityType,    'List',       'V',           'vwNotifications',      null,                         BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Audit Trail',            @EntityType + '_AuditTrail',        'Standard',                  @EntityType,    'List',       'V',           'vwATEntity',           null,                         BusinessUnit from vwBusinessUnits

Go
