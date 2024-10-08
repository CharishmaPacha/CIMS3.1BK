/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/14  PKK     Added Archived Orders (HA-2796)
  2021/03/19  NB      Insert Default Filters without Selection Name for all the entity info relations (HA-2349)
  2020/11/21  OK      Added selection filters for Load.Notifications (CIMSV3-1232)
  2020/09/29  AY      Added negation global filter for Archived Field (CIMSV3-1088)
  2020/06/09  MS      Added OrderHeaders, LPNs, Pallets Tabs (HA-858)
  2020/06/09  RT      Initial revision.
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName        = null,
        @SelectionName         TName        = 'Load_EntityInfo',
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
select @ContextName = 'Load_EntityInfo';

insert into @ttDefaultFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'LoadId',           'Equals',           '~LoadId~',         'N'
union select '!G',       'Archived',         null,               null,               'N'

/* Add the default filters */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
select @ContextName           = 'Load_EntityInfo_Orders';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

select @SelectionName         = 'Load_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/* Archived Orders */
delete from @ttSelectionFilters;
select @SelectionName        = 'ArchivedOrders',
       @SelectionDescription = 'Archived Orders';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'Archived',         'Equals',           'Y',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Pallets */
select @ContextName = 'Load_EntityInfo_Pallets';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

select @SelectionName         = 'Load_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* LPNs */
select @ContextName = 'Load_EntityInfo_LPNs';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

select @SelectionName         = 'Load_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* BoLs */

select @ContextName = 'Load_EntityInfo_BoLs';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

select @SelectionName         = 'Load_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* BoLOrderDetails */

select @ContextName = 'Load_EntityInfo_BoLOrderDetails';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

select @SelectionName         = 'Load_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* BoLCarrierDetails */

select @ContextName = 'Load_EntityInfo_BoLCarrierDetails';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

select @SelectionName         = 'Load_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* Notifications */
delete from @ttSelectionFilters;
select @ContextName           = 'Load_EntityInfo_Notifications',
       @SelectionName         = 'Load_EntityInfo',
       @SelectionDescription  = 'Default';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'MasterEntityId',   'Equals',           '~LoadId~',        'N'
union select '!G',       'Archived',         null,               null,              'N'

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* AuditTrail */
delete from @ttSelectionFilters;
select @ContextName           = 'Load_EntityInfo_AuditTrail',
       @SelectionName         = 'Load_EntityInfo',
       @SelectionDescription  = 'Default';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~LoadId~',         'N'
union select 'D',        'EntityType',       'Equals',           'Load',             'N'
union select '!G',       'Archived',         null,               null,               'N'

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible */, @ttSelectionFilters;

Go
