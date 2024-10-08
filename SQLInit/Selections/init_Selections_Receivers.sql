/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/07  PKK     Added new selection Archived Receivers (HA-2796)
  2020/07/07  AY      Setup Current Receivers selection
  2020/06/25  MRK     Corrections to Selection Filter Type code (CIMSV3-979)
  2020/04/06  MS      Initial revision (JL-192)
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'List.Receivers',
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
select @SelectionName        = 'OpenReceivers',
       @SelectionDescription = 'Open Receivers';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ReceiverStatus',   'Equals',           'O',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'Current Receivers',
       @SelectionDescription = 'Current Receivers';

-- insert into @ttSelectionFilters
--             (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
--       select 'L',        'Archived',         'Equals',           'N',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'ArchivedReceivers',
       @SelectionDescription = 'Archived Receivers';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'Archived',         'Equals',           'Y',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

Go
