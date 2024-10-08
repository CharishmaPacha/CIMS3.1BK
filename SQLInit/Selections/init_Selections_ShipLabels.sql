/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/13  AY      Setup default filter and changed Active labels to be the default (OBV3-1177)
  2022/07/22  SAK     Added Selections LabelErrors and Archived Labels (BK-753)
  2021/03/25  MS      Initial revision.
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'List.ShipLabels',
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

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'Archived',         'Equals',           'N',                'Y'

/* Add the default and mandatory filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Label Errors */
delete from @ttSelectionFilters;
select @SelectionName        = 'LabelErrors',
       @SelectionDescription = 'Label Errors';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ProcessStatus',    'Equals',           'LGE',              'Y'
union select 'D',        'Status',           'NotEquals',        'V',                'Y'

/* Add the default selection */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- User */, default, @ttSelectionFilters;

/******************************************************************************/
/* Active Labels */
delete from @ttSelectionFilters;
select @SelectionName        = 'ActiveShipLabels',
       @SelectionDescription = 'Active Labels';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'Archived',         'Equals',           'N',                'Y'
union select 'D',        'Status',           'Equals',           'A',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, 'Y' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Archived Labels */
delete from @ttSelectionFilters;
select @SelectionName        = 'ArchivedShipLabels',
       @SelectionDescription = 'Archived Labels';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'M',        'Archived',         'Equals',           'Y',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, 'Y' /* Visible */, @ttSelectionFilters;

Go
