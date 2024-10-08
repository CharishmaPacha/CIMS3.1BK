/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/05  SK      Initial revision (HA-3020)
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName,
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

/******************************************************************************/
/* Context - List.WHKPIYesterday */
/******************************************************************************/
select @ContextName = 'List.WHKPIPeriod'

delete from @ttSelectionFilters;
select @SelectionName = null;

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'Archived',         'Equals',           'N',                'Y'

/* Add the default filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'WHKPIPeriod.Yesterday',
       @SelectionDescription = 'Yesterday';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ActivityDate',     'Yesterday',        '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'WHKPIPeriod.ThisWeek',
       @SelectionDescription = 'This Week';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ActivityDate',     'ThisWeek',         '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;


/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'WHKPIPeriod.LastWeek',
       @SelectionDescription = 'Last Week';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ActivityDate',     'LastWeek',         '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'WHKPIPeriod.ThisMonth',
       @SelectionDescription = 'This Month';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ActivityDate',     'ThisMonth',        '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'WHKPIPeriod.ThisQuarter',
       @SelectionDescription = 'This Quarter';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ActivityDate',     'ThisQuarter',      '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'WHKPIPeriod.ThisYear',
       @SelectionDescription = 'This Year';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ActivityDate',     'ThisYear',         '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Context - List.WHKPICust */
/******************************************************************************/
select @ContextName = 'List.WHKPICust'

delete from @ttSelectionFilters;
select @SelectionName = null;

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'Archived',         'Equals',           'N',                'Y'

/* Add the default filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'WHKPICust.Yesterday',
       @SelectionDescription = 'Yesterday';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ActivityDate',     'Yesterday',        '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'WHKPICust.ThisWeek',
       @SelectionDescription = 'This Week';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ActivityDate',     'ThisWeek',         '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;


/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'WHKPICust.LastWeek',
       @SelectionDescription = 'Last Week';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ActivityDate',     'LastWeek',         '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'WHKPICust.ThisMonth',
       @SelectionDescription = 'This Month';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ActivityDate',     'ThisMonth',        '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'WHKPICust.ThisQuarter',
       @SelectionDescription = 'This Quarter';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ActivityDate',     'ThisQuarter',      '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'WHKPICust.ThisYear',
       @SelectionDescription = 'This Year';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ActivityDate',     'ThisYear',         '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;


Go