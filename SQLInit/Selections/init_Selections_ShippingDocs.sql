/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/12  NB      Initial revision(HA-2114)
  
  The file is for the default selection filter setup needed for Shipping Docs Page
  these selection filters are setup to assist in filtering the data displayed in different controls
  of the Shipping Docs page
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = 'Shipping_ShippingDocs', -- ContextName is <ParentMenuId>_<MenuId>
        @SelectionName         TName,
        @SelectionDescription  TDescription,
        @ttSelectionFilters    TSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'Standard',
       @SelectionDescription = 'Standard';

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,        Visible)
/* Mandatory Filter */
     select 'M',        'Warehouse',         'Equals',           '~SessionKey_UserFilter_Warehouse~', 'N';

/* Add the default and mandatory filters */
exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

