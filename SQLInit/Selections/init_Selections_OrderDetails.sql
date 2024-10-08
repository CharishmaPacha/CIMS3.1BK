/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/25  NB      Replaced NotEquals filters on OrderType and OrderStatus with NotAnyOf filters(HA-2053)
  2020/12/07  RKC     Added new selection Partially Allocate (HA-793)
  2020/10/08  TK      Renamed 'UnWaved Orders' to 'Orders To Wave' (HA-1531)
  2020/05/02  MS      Use OrderStatus in filters (HA-293)
  2020/03/26  TK      Setup visibility Selections (JL-163)
  2019/03/23  AY      Initial revision.
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'List.OrderDetails',
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
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'OrderStatus',      'NotAnyOf',         'O',                'Y'
union select 'D',        'Archived',         'Equals',           'N',                'Y'
union select 'D',        'OrderType',        'NotAnyOf',         'R,RU,B',           'Y'

/* Add the default filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'CustomerOrders',
       @SelectionDescription = 'Customer Orders';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'OrderStatus',      'NotAnyOf',         'O',                'Y'
union select 'L',        'Archived',         'Equals',           'N',                'Y'
union select 'L',        'OrderType',        'NotAnyOf',         'R,RU,B',           'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'Open Customer Orders',
       @SelectionDescription = 'Open Customer Orders';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'OrderStatus',      'NotAnyOf',         'O,N,S,X',          'Y'
union select 'L',        'Archived',         'Equals',           'N',                'Y'
union select 'L',        'OrderType',        'NotAnyOf',         'R,RU,B',           'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'OrdersToWave',
       @SelectionDescription = 'Orders To Wave';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'OrderStatus',      'AnyOf',            'N',                'Y'
union select 'L',        'Archived',         'Equals',           'N',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'AllOrders',
       @SelectionDescription = 'All Orders';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'Archived',         'Equals',           'N',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'ToAllocate',
       @SelectionDescription = 'Details Not Allocated';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'Archived',         'Equals',           'N',                'Y'
union select 'L',        'UnitsToAllocate',  'GreaterThan',      '0',                'Y'
union select 'L',        'OrderStatus',      'NotAnyOf',         'O,N,S,X',          'Y'
union select 'L',        'Archived',         'Equals',           'N',                'Y'
union select 'L',        'OrderType',        'NotAnyOf',         'R,RU,B',           'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'PartiallyAllocated',
       @SelectionDescription = 'Partially Allocated';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,       FilterValue,                               Visible)
      select 'L',        '_CUSTOMFILTER_',   '_CUSTOMFILTER_',      'UnitsAssigned < UnitsAuthorizedToShip',   'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

Go
