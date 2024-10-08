/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/28  PKK     Added new selection ArchivedReceipts (HA-2796)
  2020/04/10  TK      QtyToReceive > 0 cannot be a default filter and added new
                      selection Open Receipts (CIMSV3-754)
  2020/03/26  TK      Setup visibility Selections (JL-163)
  2020/01/07  YJ      Initial revision (JL-54)
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'List.ReceiptHeaders',
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
      select 'D',        'Archived',         'Equals',           'N',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'CurrentReceipts',
       @SelectionDescription = 'Current Receipts';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'Archived',         'Equals',           'N',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'InProcessReceipts',
       @SelectionDescription = 'In Process Receipts';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ReceiptStatus',    'IsAnyOf',          'T,R,E',            'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'OpenReceipts',
       @SelectionDescription = 'Open Receipts';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ReceiptStatus',    'NotAnyOf',         'C,X',              'Y'
union select 'L',        'QtyToReceive',     'GreaterThan',      '0',                'Y';

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'ArchivedReceipts',
       @SelectionDescription = 'Archived Receipts';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'Archived',         'Equals',           'Y',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

Go
