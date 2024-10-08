/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/11  SJ      Initial revision
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'List.PutawayRules',
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
select @SelectionName        = 'ActiveRules',
       @SelectionDescription = 'Active Rules';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
    select   'D',       'Status',            'Equals',           'A',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

Go
