/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/14  PKK     Added Archived Orders (HA-2796)
  2021/03/24  MS      Setup ShipLabels Tab (HA-2406)
  2020/10/07  NB      Added mandatory filter for WaveId to all contexts of Wave Entity Info (CIMSV3-1122)
  2020/09/29  AY      Added negation global filter for Archived Field (CIMSV3-1088)
  2020/06/03  MS      Corrections to LPNs, LPNDetails, PickTasks, PickTaskDetails (HA-788)
  2020/05/29  TK      Notification should be filtered with MasterEntityId (HA-646)
                      Corrections to LPNs & LPNDetails (HA-691)
  2020/05/18  MS      Initial revision(HA-569)
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName        = null,
        @SelectionName         TName        = 'Wave_EntityInfo',
        @SelectionDescription  TDescription = 'Default',
        @ttMandatoryFilters    TSelectionFilters,
        @ttDefaultFilters      TSelectionFilters,
        @ttSelectionFilters    TSelectionFilters;

/******************************************************************************/
/* Mandatory Selection Filters for the Context
*/
delete from @ttMandatoryFilters;

insert into @ttMandatoryFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'M',        'WaveId',           'Equals',           '~WaveId~',         'N'

/******************************************************************************/
/* Default Selection Filters for the Context
   These selection filter records are not bound to any Selection. They are used as a Master set
   of Filters to add to a New Selection. The addition of these new filters is done in the UI
   where the user has a choice to retain/edit/remove these filters, prior to saving the Selections
*/
delete from @ttDefaultFilters;
select @ContextName = 'Wave_EntityInfo';

insert into @ttDefaultFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'M',        'WaveId',           'Equals',           '~WaveId~',         'N'
union select '!G',       'Archived',         null,               null,               'N'

/* Add the default filters */
exec pr_Setup_Selections @ContextName, null, null, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
select @ContextName           = 'Wave_EntityInfo_Orders',
       @SelectionName         = 'Wave_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default filters */
exec pr_Setup_Selections @ContextName, null, null, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/* Archived Orders */
delete from @ttSelectionFilters;
select @SelectionName        = 'ArchivedOrders',
       @SelectionDescription = 'Archived Orders';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'Archived',         'Equals',           'Y',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* OrderDetails */
select @ContextName           = 'Wave_EntityInfo_OrderDetails',
       @SelectionName         = 'Wave_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default filters */
exec pr_Setup_Selections @ContextName, null, null, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* Pallets */
select @ContextName           = 'Wave_EntityInfo_Pallets',
       @SelectionName         = 'Wave_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default filters */
exec pr_Setup_Selections @ContextName, null, null, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* LPNs */
delete from @ttSelectionFilters;
select @ContextName           = 'Wave_EntityInfo_LPNs',
       @SelectionName         = 'Wave_EntityInfo',
       @SelectionDescription  = 'Default';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'LPNType',          'Equals',           'S',                'N'
union select 'M',        'WaveId',           'Equals',           '~WaveId~',         'N'
union select '!G',       'Archived',         null,               null,               'N'

/* Add the default filters */
exec pr_Setup_Selections @ContextName, null, null, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttSelectionFilters;

/******************************************************************************/
/* LPNDetails */

select @ContextName           = 'Wave_EntityInfo_LPNDetails',
       @SelectionName         = 'Wave_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default filters */
exec pr_Setup_Selections @ContextName, null, null, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttSelectionFilters;

/******************************************************************************/
/* PickTasks */

select @ContextName           = 'Wave_EntityInfo_PickTasks',
       @SelectionName         = 'Wave_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default filters */
exec pr_Setup_Selections @ContextName, null, null, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* PickTaskDetails */

select @ContextName           = 'Wave_EntityInfo_PickTaskDetails',
       @SelectionName         = 'Wave_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default filters */
exec pr_Setup_Selections @ContextName, null, null, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* ShipLabels */
delete from @ttSelectionFilters;

select @ContextName          = 'Wave_EntityInfo_ShipLabels',
       @SelectionName        = 'Wave_EntityInfo',
       @SelectionDescription = 'Label Errors';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ProcessStatus',    'Equals',           'LGE',              'Y'
union select 'D',        'Status',           'NotEquals',        'V',                'Y'

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Notifications */
delete from @ttSelectionFilters;
select @ContextName           = 'Wave_EntityInfo_Notifications',
       @SelectionName         = 'Wave_EntityInfo',
       @SelectionDescription  = 'Default';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'M',        'MasterEntityId',   'Equals',           '~WaveId~',         'N'
union select '!G',       'Archived',         null,               null,               'N'

/* Add the default filters */
exec pr_Setup_Selections @ContextName, null, null, 'D' /* Selection Type- Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* AuditTrail */
delete from @ttSelectionFilters;
select @ContextName           = 'Wave_EntityInfo_AuditTrail',
       @SelectionName         = 'Wave_EntityInfo',
       @SelectionDescription  = 'Default';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'M',        'EntityId',         'Equals',           '~WaveId~',         'N'
union select 'M',        'EntityType',       'Equals',           'Wave',             'N'
union select '!G',       'Archived',         null,               null,               'N'

/* Add the default filters */
exec pr_Setup_Selections @ContextName, null, null, 'D' /* Selection Type- Default */, 'N' /* Visible */, @ttSelectionFilters;

Go
