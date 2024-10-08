/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/28  PKK     Added new selection ArchivedLoads (HA-2796)
  2021/03/18  SAK     Ported back the selction LoadsShippedToday (HA-2335)
  2021/02/19  YJ      Ported changes done by Pavan (HA-2014)
  2020/10/12  SJ      Added OpenLoads, RoutingConfirmed, ToRoute selections for Loads (HA-1560)
  2020/06/25  NB      Initial Revision(CIMSV3-990)
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'List.Loads',
        @SelectionName         TName,
        @SelectionDescription  TDescription,
        @ttSelectionFilters    TSelectionFilters;

/******************************************************************************/
/* Default Selection Filters for the Context
   These selection filter records are not bound to any Selection. They are used as a Master set
   of Filters to add to a New Selection. The addition of these new filters is done in the UI
   where the user has a choice to retain/edit/remove these filters, prior to saving the Selections

  Mandatory Selection Filters for the Context
  These selection filter records are not bound to any Selection. These filters always
  get applied, over other filters
*/
delete from @ttSelectionFilters;
select @SelectionName = null;

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,                         Visible)
/* Mandatory Filter */
      select 'M',        'FromWarehouse',    'Equals',           '~SessionKey_UserFilter_Warehouse~', 'N'
union select 'D',        'Archived',         'Equals',           'N',                                 'Y'

/* Add the default and mandatory filters */
exec pr_Setup_Selections @ContextName, null, null, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'ToShipToday',
       @SelectionDescription = 'To Ship Today';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'DesiredShipDate',  'Today',            '',                 'Y'
union select 'L',        'Archived',         'Equals',           'N',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'ToShipTomorrow',
       @SelectionDescription = 'To Ship Tomorrow';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'DesiredShipDate',  'Tomorrow',         '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'ToShipThisWeek',
       @SelectionDescription = 'To Ship this week';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'DesiredShipDate',  'ThisWeek',         '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'ToShipNextWeek',
       @SelectionDescription = 'To Ship next week';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'DesiredShipDate',  'NextWeek',         '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'OpenLoads',
       @SelectionDescription = 'Open Loads';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'LoadStatus',       'NotEquals',        'S',                'Y'
union select 'L',        'LoadStatus',       'NotEquals',        'X',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'RoutingConfirmed',
       @SelectionDescription = 'Routing Confirmed';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'RoutingStatus',       'Equals',        'C',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'ToRoute',
       @SelectionDescription = 'To Route';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'RoutingStatus',       'Equals',        'P',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'LoadsShippedToday',
       @SelectionDescription = 'Loads Shipped Today';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ShippedDate',      'Today',            '',                 'Y'
union select 'L',        'LoadStatus',       'IsAnyof',          'S',                'Y'
union select 'L',        'Archived',         'Equals',           'N',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'ArchivedLoads',
       @SelectionDescription = 'Archived Loads';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'Archived',         'Equals',           'Y',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

Go
