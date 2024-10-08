/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/07  PKK     Added new selection Archived LPNs (HA-2796)
  2020/09/29  AY      Added negation global filter for Archived Field (CIMSV3-1088)
  2020/05/14  MS      Initial revision (HA-202)
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName        = null,
        @SelectionName         TName        = 'RCV_EntityInfo',
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
select @ContextName           = 'RCV_EntityInfo_Summary',
       @SelectionName         = null,
       @SelectionDescription  = null;

insert into @ttDefaultFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'ReceiverId',       'Equals',           '~ReceiverId~',     'N'
union select '!G',       'Archived',         null,               null,               'N'

/* Add the default filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* Summary */
select @ContextName           = 'RCV_EntityInfo_Summary',
       @SelectionName         = 'RCV_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* LPNs */
select @ContextName           = 'RCV_EntityInfo_LPNs',
       @SelectionName         = 'RCV_EntityInfo',
       @SelectionDescription  = 'Default';

/* Add the default filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible - No */, @ttDefaultFilters;

/******************************************************************************/
/* Archived LPNs */
delete from @ttSelectionFilters;
select @SelectionName        = 'RCV_EntityInfo_ArchivedLPNs',
       @SelectionDescription = 'Archived LPNs';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'Archived',         'Equals',           'Y',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* AuditTrail */
delete from @ttSelectionFilters;
select @ContextName           = 'RCV_EntityInfo_AuditTrail',
       @SelectionName         = 'RCV_EntityInfo',
       @SelectionDescription  = 'Default';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~ReceiverId~',     'N'
union select 'D',        'EntityType',       'Equals',           'Receiver',         'N'
union select '!G',       'Archived',         null,               null,               'N'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, 'N' /* Visible */, @ttSelectionFilters;

Go
