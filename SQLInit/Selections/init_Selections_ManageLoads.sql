/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/27  AJM     Added selection CreatedLoads, AutocreateLoads (HA-1943)
  2020/06/25  NB      Initial Revision(CIMSV3-996)
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'ManageLoads.OpenLoads',
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
            (FilterType, FieldName,          FilterOperation,    FilterValue,                        Visible)
/* Mandatory Filter */
     select 'M',        'FromWarehouse',    'Equals',           '~SessionKey_UserFilter_Warehouse~', 'N'

/* Add the default and mandatory filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'UserCreatedLoads',
       @SelectionDescription = 'User created Loads';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'CreatedBy',        'NotEquals',        'cIMSAgent',        'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'AutoCreatedLoads',
       @SelectionDescription = 'Auto created Loads';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'CreatedBy',        'Equals',           'cIMSAgent',        'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'L' /* Selection Type- Listing */, default /* Visible */, @ttSelectionFilters;

Go
