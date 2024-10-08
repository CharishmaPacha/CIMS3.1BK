/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/27  AY      Initial revision
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'List.ReceiptDetails',
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
      select 'D',        'QtyToReceive',     'GreaterThan',      '0',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'OpenReceipts',
       @SelectionDescription = 'Open Receipts';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ReceiptStatus',    'NotEquals',        'C',                'Y'
union select 'D',        'ReceiptStatus',    'NotEquals',        'X',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'InProcessReceipts',
       @SelectionDescription = 'In Process Receipts';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'ReceiptStatus',    'IsAnyOf',          'T,R,E',            'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

Go
