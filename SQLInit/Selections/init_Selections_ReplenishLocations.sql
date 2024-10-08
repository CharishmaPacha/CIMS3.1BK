/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  MS      Removed Unnecessary Filters (BK-302)
  2020/05/05  VS      Initial revision.(HA-368)
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'List.ReplenishmentLocations',
        @SelectionName         TName,
        @SelectionDescription  TDescription,
        @ttSelectionFilters    TSelectionFilters;

/******************************************************************************/
/* Default Selection Filters for the Context
   These selection filter records are not bound to any Selection. They are used as a Master set
   of Filters to add to a New Selection. The addition of these new filters is done in the UI
   where the user has a choice to retain/edit/remove these filters, prior to saving the Selections
*/
/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName = null;

delete from @ttSelectionFilters;
select @SelectionName        = 'UI-ReplenishLocations',
       @SelectionDescription = 'Selected Locations';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'PickZone',         'StartsWith',       '',                 'Y'
union select 'D',        'PutawayZone',      'StartsWith',       '',                 'Y'
union select 'D',        'StorageType',      'IsAnyOf',          'U',                'Y'
union select 'D',        'ReplenishType',    'IsAnyOf',          'R,H,F',            'Y'
union select 'D',        'SKU',              'StartsWith',       '',                 'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

Go
