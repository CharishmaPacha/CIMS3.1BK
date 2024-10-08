/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/30  RV      Initial revision (HA-3007)
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName,
        @SelectionName         TName,
        @SelectionDescription  TDescription,
        @ttSelectionFilters    TSelectionFilters;

/******************************************************************************/
/* Context - List.CIMSDE_ExportTransactions */
/******************************************************************************/
select @ContextName = 'List.CIMSDE_ExportTransactions'

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'CIMSDE_ExportTransactions.Yesterday',
       @SelectionDescription = 'Yesterday';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'TransDate',        'Yesterday',        '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'CIMSDE_ExportTransactions.Today',
       @SelectionDescription = 'Today';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'TransDate',        'Today',            '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'CIMSDE_ExportTransactions.LastWeek',
       @SelectionDescription = 'Last Week';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'TransDate',        'LastWeek',         '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'CIMSDE_ExportTransactions.ThisWeek',
       @SelectionDescription = 'This Week';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'TransDate',        'ThisWeek',         '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'CIMSDE_ExportTransactions.LastMonth',
       @SelectionDescription = 'Last Month';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'TransDate',        'LastMonth',        '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'CIMSDE_ExportTransactions.ThisMonth',
       @SelectionDescription = 'This Month';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'TransDate',        'ThisMonth',        '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'CIMSDE_ExportTransactions.LastQuarter',
       @SelectionDescription = 'Last Quarter';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'TransDate',        'LastQuarter',      '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'CIMSDE_ExportTransactions.ThisQuarter',
       @SelectionDescription = 'This Quarter';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'TransDate',        'ThisQuarter',      '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'CIMSDE_ExportTransactions.LastYear',
       @SelectionDescription = 'Last Year';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'TransDate',        'LastYear',         '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'CIMSDE_ExportTransactions.ThisYear',
       @SelectionDescription = 'This Year';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'TransDate',        'ThisYear',         '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default /* Visible */, @ttSelectionFilters;

Go
