/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/26  TK      Setup visibility Selections (JL-163)
  2017/09/25  AY      Initial revision.
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'List.Locations', --'List.Locations',
        @SelectionName         TName,
        @SelectionDescription  TDescription,
        @ttSelectionFilters    TSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'Default',
       @SelectionDescription = 'All Active Locations';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'LocationStatus',   'NotEquals',        'I',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'ReserveOnly',
       @SelectionDescription = 'Active Reserve';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'LocationStatus',   'NotEquals',        'I',                'Y'
union select 'L',        'LocationType',     'Equals',           'R',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'PicklanesOnly',
       @SelectionDescription = 'Active Picklanes';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'LocationStatus',   'NotEquals',        'I',                'Y'
union select 'L',        'LocationType',     'Equals',           'K',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'EmptyLocations',
       @SelectionDescription = 'Empty Pickable Locations';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'LocationStatus',   'Equals',           'E',                'Y'
union select 'L',        'LocationType',     'AnyOf',            'R,B,K',            'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'UnassignedPicklanes',
       @SelectionDescription = 'Unassigned Picklanes';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'LocationStatus',   'NotEquals',        'I',                'Y'
union select 'L',        'LocationType',     'Equals',           'K',                'Y'
union select 'L',        'NumLPNs',          'Equals',           '0',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

Go
