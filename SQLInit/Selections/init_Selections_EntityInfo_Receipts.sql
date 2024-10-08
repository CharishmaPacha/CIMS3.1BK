/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/04  SAK     Initial revision (HA-2723)
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName        = null,
        @SelectionName         TName        = 'RH_EntityInfo',
        @SelectionDescription  TDescription = 'Default',
        @ttDefaultFilters      TSelectionFilters,
        @ttSelectionFilters    TSelectionFilters;

/******************************************************************************/
/* Default Selection Filters for the Context
   These selection filter records are not bound to any Selection. They are used as a Master set
   of Filters to add to a New Selection. The addition of these new filters is done in the UI
   where the user has a choice to retain/edit/remove these filters, prior to saving the Selections
*/
delete from @ttDefaultFilters;
select @ContextName          = 'RH_EntityInfo',
       @SelectionName        = null,
       @SelectionDescription = null;

insert into @ttDefaultFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ReceiptId',        'Equals',           '~ReceiptId~',      'N'
union select '!G',       'Archived',         null,               null,               'N'

/* Add the default filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* Summary */
select @ContextName          = 'RH_EntityInfo_Summary',
       @SelectionName        = 'RH_EntityInfo',
       @SelectionDescription = 'Default';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/* Add the default filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* Receipt Details */
select @ContextName          = 'RH_EntityInfo_Details',
       @SelectionName        = 'RH_EntityInfo',
       @SelectionDescription = 'Default';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/* Add the default filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* LPNs */
select @ContextName          = 'RH_EntityInfo_LPNs',
       @SelectionName        = 'RH_EntityInfo',
       @SelectionDescription = 'Default';

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/* Add the default filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* AuditTrail */
delete from @ttSelectionFilters;
select @ContextName          = 'RH_EntityInfo_AuditTrail',
       @SelectionName        = 'RH_EntityInfo',
       @SelectionDescription = 'Default';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~ReceiptId~',      'N'
union select 'D',        'EntityType',       'Equals',           'Receipt',          'N'
union select '!G',       'Archived',         null,               null,               'N'

/* Add the default filters without selection name, so that these are added to newly created selections */
exec pr_Setup_Selections @ContextName, null, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/* Add the default filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible */, @ttSelectionFilters;

Go
