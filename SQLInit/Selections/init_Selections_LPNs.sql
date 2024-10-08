/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/28  PKK     Added new selection ArchivedLPNs (HA-2796)
  2020/06/17  NB      Added Mandatory Filter for Warehouse User Filter (CIMSV3-103)
  2020/04/09  MS      Changes description for ReceivedNotPutaway (HA-141)
  2020/04/03  AY      Changed selection name to ReservedLPNs (JL-190)
  2020/03/26  TK      set visible false for EntityInfo (JL-163)
  2020/01/08  MS      Added selection layouts for InTransit LPNs (JL-56)
  2019/07/15  RKC     Added selection layouts for Totes and carts in LPNs page (CID-729)
  2019/05/11  NB      Renamed Status to LPNStatus (CIMSV3-138)
  2018/01/23  NB      Added default filters for EntityInfo LPNs List(CIMSV3-151)
  2017/10/04  NB      Introduced Default Filters - added to every new selection in UI (CIMSV3-11)
  2017/09/06  NB      Removed Visible column for Insert Selections(CIMSV3-11)
  2017/08/03  NB      Initial revision.
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'List.LPNs',
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
select @SelectionName = null;

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'Archived',         'Equals',           'N',                'Y'
union select 'D',        'LPNStatus',        'NotEquals',        'I',                'N'
union select 'D',        'Quantity',         'GreaterThan',      '0',                'Y'
/* Mandatory Filter */
union select 'M',        'DestWarehouse',    'Equals',           '~SessionKey_UserFilter_Warehouse~', 'N';

/* Add the default and mandatory filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'AllLPNs',
       @SelectionDescription = 'All LPNs';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'D',        'Archived',         'Equals',           'N',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'Cart',
       @SelectionDescription = 'Carts';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'LPNType',          'Equals',           'A',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'Tote',
       @SelectionDescription = 'Totes';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'LPNType',          'Equals',           'TO',               'Y';

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'OnhandLPNs',
       @SelectionDescription = 'Onhand Inventory';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'Archived',         'Equals',           'N',                'N'
union select 'L',        'OnhandStatus',     'NotEquals',        'U',                'Y';

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'ReceivedNotPutaway',
       @SelectionDescription = 'LPNs not yet Putaway';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'LPNStatus',        'Equals',           'R',                'Y';

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'LPNsInReserve',
       @SelectionDescription = 'LPNs In Reserve';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'LocationType',     'Equals',           'R',                'Y';

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'PicklanesOnly',
       @SelectionDescription = 'Picklanes Only';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'LocationType',     'Equals',           'K',                'Y';

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'ReservedLPNs',
       @SelectionDescription = 'Reserved for Orders';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'Archived',         'Equals',           'N',                'Y'
union select 'L',        'OrderId',          'GreaterThan',      '0',                'Y';

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'LPNsInTransit',
       @SelectionDescription = 'LPNs In Transit';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'LPNStatus',        'Equals',           'T',                'Y';

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'OH.EntityInfo',
       @SelectionDescription = 'OH.EntityInfo';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'Archived',         'Equals',           'N',                'N'
union select 'L',        'OrderId',          'Equals',           '~OrderId~',        'N';

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, 'N' /* Visible - No */, @ttSelectionFilters;
/******************************************************************************/

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'ArchivedLPNs',
       @SelectionDescription = 'Archived LPNs';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
      select 'L',        'Archived',         'Equals',           'Y',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'U' /* Selection Type: User */, default /* Visible */, @ttSelectionFilters;

Go
