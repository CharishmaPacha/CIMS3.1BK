/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/25  MRK     Corrections to Selection Filter Type code (CIMSV3-979)
  2020/05/04  SV      Changes to show Wave's AT (HA-291)
  2020/04/23  NB/SV   Initial revision (HA-231)
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'List.ATEntity',
        @SelectionName         TName,
        @SelectionDescription  TDescription,
        @ttSelectionFilters    TSelectionFilters;

/******************************************************************************/
/* Selection for use with Audit Trail calls from Locations Listing */
delete from @ttSelectionFilters;
select @SelectionName        = 'LocationAuditTrail',
       @SelectionDescription = 'Location Audit Trail';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~LocationId~',     'N'
union select 'D',        'EntityType',       'Equals',           'Location',         'N'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Selection for use with Audit Trail calls from LPNs Listing */
delete from @ttSelectionFilters;
select @SelectionName        = 'LPNAuditTrail',
       @SelectionDescription = 'LPN Audit Trail';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~LPNId~',          'N'
union select 'D',        'EntityType',       'Equals',           'LPN',              'N'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Selection for use with Audit Trail calls from Orders Listing */
delete from @ttSelectionFilters;
select @SelectionName        = 'OrderAuditTrail',
       @SelectionDescription = 'Order Audit Trail';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~OrderId~',        'N'
union select 'D',        'EntityType',       'Equals',           'PickTicket',       'N'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Selection for use with Audit Trail calls from Pallets Listing */
delete from @ttSelectionFilters;
select @SelectionName        = 'PalletAuditTrail',
       @SelectionDescription = 'Pallet Audit Trail';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~PalletId~',       'N'
union select 'D',        'EntityType',       'Equals',           'Pallet',           'N'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Selection for use with Audit Trail calls from Receipts Listing */
delete from @ttSelectionFilters;
select @SelectionName        = 'ReceiptAuditTrail',
       @SelectionDescription = 'Receipt Audit Trail';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~ReceiptId~',      'N'
union select 'D',        'EntityType',       'Equals',           'Receipt',          'N'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Selection for use with Audit Trail calls from Receivers Listing */
delete from @ttSelectionFilters;
select @SelectionName        = 'ReceiverAuditTrail',
       @SelectionDescription = 'Receiver Audit Trail';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~ReceiverId~',     'N'
union select 'D',        'EntityType',       'Equals',           'Receiver',         'N'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Selection for use with Audit Trail calls from SKUss Listing */
delete from @ttSelectionFilters;
select @SelectionName        = 'SKUAuditTrail',
       @SelectionDescription = 'SKU Audit Trail';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~SKUId~',          'N'
union select 'D',        'EntityType',       'Equals',           'SKU',              'N'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Selection for use with Audit Trail calls from Tasks Listing */
delete from @ttSelectionFilters;
select @SelectionName        = 'TaskAuditTrail',
       @SelectionDescription = 'Task Audit Trail';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~TaskId~',         'N'
union select 'D',        'EntityType',       'Equals',           'Task',             'N'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Selection for use with Audit Trail calls from Receipts Listing */
delete from @ttSelectionFilters;
select @SelectionName        = 'UserAuditTrail',
       @SelectionDescription = 'User Audit Trail';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~UserId~',         'N'
union select 'D',        'EntityType',       'Equals',           'User',             'N'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Selection for use with Audit Trail calls from Waves Listing */
delete from @ttSelectionFilters;
select @SelectionName        = 'WaveAuditTrail',
       @SelectionDescription = 'Wave Audit Trail';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~RecordId~',       'N'
union select 'D',        'EntityType',       'Equals',           'Wave',             'N'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, 'N' /* Visible */, @ttSelectionFilters;

/******************************************************************************/
/* Selection for use with Audit Trail calls from Loads Listing */
delete from @ttSelectionFilters;
select @SelectionName        = 'LoadAuditTrail',
       @SelectionDescription = 'Load Audit Trail';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'EntityId',         'Equals',           '~LoadId~',         'N'
union select 'D',        'EntityType',       'Equals',           'Load',             'N'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type: Default */, 'N' /* Visible */, @ttSelectionFilters;

Go
