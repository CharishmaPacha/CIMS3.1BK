/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/08  MS      Removed ImportResults selection, Adhoc selection will be created (HA-293)
  2020/04/15  MS      Setup Selection type as default (HA-157)
  2020/03/26  TK      Setup visibility Selections (JL-163)
  2020/03/07  MS      Initial revision (CIMSV3-740)
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName,
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

--For All DE Tables default Filter value would be ExchangeStatus N Or E, since we have to show Error Records as well in UI

/******************************************************************************/
/* CIMSDE_ImportASNLPNs */

delete from @ttSelectionFilters;
select @ContextName          = 'List.CIMSDE_ImportASNLPNs',
       @SelectionName        = 'ToImport',
       @SelectionDescription = 'Waiting & Failed Imports';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ExchangeStatus',   'IsAnyOf',          'N,E',              'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visibility */, @ttSelectionFilters;

/******************************************************************************/
/* CIMSDE_ImportASNLPNDetails */

delete from @ttSelectionFilters;
select @ContextName          = 'List.CIMSDE_ImportASNLPNDetails',
       @SelectionName        = 'ToImport',
       @SelectionDescription = 'Waiting & Failed Imports';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ExchangeStatus',   'IsAnyOf',          'N,E',              'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visibility */, @ttSelectionFilters;

/******************************************************************************/
/* CIMSDE_ImportCartonTypes */

delete from @ttSelectionFilters;
select @ContextName          = 'List.CIMSDE_ImportCartonTypes',
       @SelectionName        = 'ToImport',
       @SelectionDescription = 'Waiting & Failed Imports';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ExchangeStatus',   'IsAnyOf',          'N,E',              'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visibility */, @ttSelectionFilters;

/******************************************************************************/
/* CIMSDE_ImportContacts */

delete from @ttSelectionFilters;
select @ContextName          = 'List.CIMSDE_ImportContacts',
       @SelectionName        = 'ToImport',
       @SelectionDescription = 'Waiting & Failed Imports';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ExchangeStatus',   'IsAnyOf',          'N,E',              'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visibility */, @ttSelectionFilters;

/******************************************************************************/
/* CIMSDE_ImportNotes */

delete from @ttSelectionFilters;
select @ContextName          = 'List.CIMSDE_ImportNotes',
       @SelectionName        = 'ToImport',
       @SelectionDescription = 'Waiting & Failed Imports';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ExchangeStatus',   'IsAnyOf',          'N,E',              'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visibility */, @ttSelectionFilters;

/******************************************************************************/
/* CIMSDE_ImportOrderDetails */

delete from @ttSelectionFilters;
select @ContextName          = 'List.CIMSDE_ImportOrderDetails',
       @SelectionName        = 'ToImport',
       @SelectionDescription = 'Waiting & Failed Imports';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ExchangeStatus',   'IsAnyOf',          'N,E',              'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visibility */, @ttSelectionFilters;

/******************************************************************************/
/* CIMSDE_ImportOrderHeaders */

delete from @ttSelectionFilters;
select @ContextName          = 'List.CIMSDE_ImportOrderHeaders',
       @SelectionName        = 'ToImport',
       @SelectionDescription = 'Waiting & Failed Imports';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ExchangeStatus',   'IsAnyOf',          'N,E',              'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visibility */, @ttSelectionFilters;

/******************************************************************************/
/* CIMSDE_ImportReceiptDetails */

delete from @ttSelectionFilters;
select @ContextName          = 'List.CIMSDE_ImportReceiptDetails',
       @SelectionName        = 'ToImport',
       @SelectionDescription = 'Waiting & Failed Imports';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ExchangeStatus',   'IsAnyOf',          'N,E',              'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visibility */, @ttSelectionFilters;

/******************************************************************************/
/* CIMSDE_ImportReceiptHeaders */

delete from @ttSelectionFilters;
select @ContextName          = 'List.CIMSDE_ImportReceiptHeaders',
       @SelectionName        = 'ToImport',
       @SelectionDescription = 'Waiting & Failed Imports';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ExchangeStatus',   'IsAnyOf',          'N,E',              'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visibility */, @ttSelectionFilters;

/******************************************************************************/
/* CIMSDE_ImportSKUPrePacks */

delete from @ttSelectionFilters;
select @ContextName          = 'List.CIMSDE_ImportSKUPrePacks',
       @SelectionName        = 'ToImport',
       @SelectionDescription = 'Waiting & Failed Imports';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ExchangeStatus',   'IsAnyOf',          'N,E',              'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visibility */, @ttSelectionFilters;

/******************************************************************************/
/* CIMSDE_ImportSKUs */

delete from @ttSelectionFilters;
select @ContextName          = 'List.CIMSDE_ImportSKUs',
       @SelectionName        = 'ToImport',
       @SelectionDescription = 'Waiting & Failed Imports';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ExchangeStatus',   'IsAnyOf',          'N,E',              'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visibility */, @ttSelectionFilters;

/******************************************************************************/
/* CIMSDE_ImportUPCs */

delete from @ttSelectionFilters;
select @ContextName          = 'List.CIMSDE_ImportUPCs',
       @SelectionName        = 'ToImport',
       @SelectionDescription = 'Waiting & Failed Imports';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ExchangeStatus',   'IsAnyOf',          'N,E',              'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visibility */, @ttSelectionFilters;

/******************************************************************************/

Go
