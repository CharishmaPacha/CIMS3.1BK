/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/24  MS      Setup ShipLabels Tab (HA-2406)
  2021/03/01  NB      Insert Default Filters without Selection Name for all the entities info relations (HA-2074)
  2020/09/21  NB      Added negation global filter for Archived Field (CIMSV3-1088)
  2020/06/10  MS      Setup Addresses Tab (HA-861)
  2020/05/29  TK      Notification should be filtered with MasterEntityId (HA-646)
  2020/05/17  MS      Added AuditTrail, Notification, Notes selections (HA-568)
  2020/03/26  TK      Setup visibility Selections (JL-163)
  2018/04/02  NB      Added default filters to selections(CIMSV3-151)
  2018/03/20  NB      ContextName changes for selections(CIMSV3-151)
  2018/01/23  NB      Initial revision.
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName        = null,
        @SelectionName         TName        = 'OH_EntityInfo',
        @SelectionDescription  TDescription = 'Default',
        @ttDefaultFilters      TSelectionFilters,
        @ttSelectionFilters    TSelectionFilters;

/******************************************************************************/
/* Default Selection Filters for the Context
   These selection filter records are not bound to any Selection. They are used as a Master set
   of Filters to add to a New Selection. The addition of these new filters is done in the UI
   where the user has a choice to retain/edit/remove these filters, prior to saving the Selections
*/
delete from @ttDefaultFilters;
select @ContextName = 'OH_EntityInfo';

insert into @ttDefaultFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'OrderId',          'Equals',           '~OrderId~',        'N'
union select '!G',       'Archived',         null,               null,               'N'

/* Add the default filters */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* OrderDetails */
select @ContextName = 'OH_EntityInfo_OrderDetails';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

select @SelectionName         = 'OH_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* LPNs */

select @ContextName = 'OH_EntityInfo_LPNs';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

select @SelectionName         = 'OH_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* LPNDetails */

select @ContextName = 'OH_EntityInfo_LPNDetails';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

select @SelectionName         = 'OH_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* PickTasks */

select @ContextName = 'OH_EntityInfo_PickTasks';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

select @SelectionName         = 'OH_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* PickTaskDetails */

select @ContextName = 'OH_EntityInfo_PickTaskDetails';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

select @SelectionName         = 'OH_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* ShipLabels */

select @ContextName          = 'OH_EntityInfo_ShipLabels',
       @SelectionName        = 'OH_EntityInfo',
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
/* Addresses */

select @ContextName = 'OH_EntityInfo_Addresses';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

select @SelectionName         = 'OH_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* Notifications */
delete from @ttSelectionFilters;
select @ContextName           = 'OH_EntityInfo_Notifications',
       @SelectionName         = 'OH_EntityInfo',
       @SelectionDescription  = 'Default';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'MasterEntityId',   'Equals',           '~OrderId~',        'N'
union select '!G',       'Archived',         null,               null,               'N'

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Notes */
delete from @ttSelectionFilters;
select @ContextName           = 'OH_EntityInfo_Notes',
       @SelectionName         = 'OH_EntityInfo',
       @SelectionDescription  = 'Default';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~OrderId~',        'N'
union select '!G',       'Archived',         null,               null,               'N'

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* AuditTrail */
delete from @ttSelectionFilters;
select @ContextName           = 'OH_EntityInfo_AuditTrail',
       @SelectionName         = 'OH_EntityInfo',
       @SelectionDescription  = 'Default';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~OrderId~',        'N'
union select 'D',        'EntityType',       'Equals',           'PickTicket',       'N'
union select '!G',       'Archived',         null,               null,               'N'

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible */, @ttSelectionFilters;

Go
