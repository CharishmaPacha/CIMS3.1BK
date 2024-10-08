/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/23  SPP      Initial revision (HA-1707)
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'List.WaveSummary',
        @SelectionName         TName,
        @SelectionDescription  TDescription,
        @ttSelectionFilters    TSelectionFilters;

/******************************************************************************/
/* Default Selection Filters for the Context
   These selection filter records are not bound to any Selection. They are used as a Master set
   of Filters to add to a New Selection. The addition of these new filters is done in the UI
   where the user has a choice to retain/edit/remove these filters, prior to saving the Selections
*/
delete from @ttSelectionFilters;
select @SelectionName = null;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'AllSKUsonWave',
       @SelectionDescription = 'All SKUs on Wave';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'SKU',              'IsNotNull',        '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'Shortages',
       @SelectionDescription = 'Shortages';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'UnitsShort',       'GreaterThan',      '0',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'L' /* Selection Type: Listing */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'Notcompletelyallocated',
       @SelectionDescription = 'Not completely allocated';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,         FilterValue,        Visible)
      select 'L',        'UnitsNeeded',      'GreaterThanOrEqual',    '1',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'L' /* Selection Type: Listing */, default /* Visible */, @ttSelectionFilters;

Go
