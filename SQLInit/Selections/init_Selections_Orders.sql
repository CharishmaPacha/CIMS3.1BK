/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/28  PKK     Added new selection ArchivedOrders (HA-2796)
  2020/10/08  TK      Renamed 'UnWaved Orders' to 'Orders To Wave' (HA-1531)
  2020/07/28  NB      Mandatory Selection Filters changes to set Visible to N (CIMSV3-1042)
  2020/05/02  MS      Use OrderStatus in filters (HA-293)
  2020/03/26  TK      Setup visibility Selections (JL-163)
  2019/06/03  NB      Added Mandatory Selection Filters(CIMSV3-509)
  2017/09/27  AY      Initial revision.
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'List.Orders',
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
      select 'D',        'OrderStatus',      'NotEquals',        'O',                'Y'
union select 'D',        'Archived',         'Equals',           'N',                'Y'
/* Mandatory Filters */
union select 'M',        'OrderType',        'NotEquals',        'R',                'N'
union select 'M',        'OrderType',        'NotEquals',        'RU',               'N'

/* Add the default filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'CustomerOrders',
       @SelectionDescription = 'Customer Orders';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'OrderStatus',      'NotEquals',        'O',                'Y'
union select 'L',        'Archived',         'Equals',           'N',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'Open Customer Orders',
       @SelectionDescription = 'Open Customer Orders';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'OrderStatus',      'NotAnyOf',         'O,N,S,X',          'Y'
union select 'L',        'Archived',         'Equals',           'N',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'OrdersToWave',
       @SelectionDescription = 'Orders To Wave';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'OrderStatus',      'Equals',           'N',                'Y'
union select 'L',        'Archived',         'Equals',           'N',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'AllOrders',
       @SelectionDescription = 'All Orders';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'Archived',         'Equals',           'N',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'ArchivedOrders',
       @SelectionDescription = 'Archived Orders';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'Archived',         'Equals',           'Y',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

Go
