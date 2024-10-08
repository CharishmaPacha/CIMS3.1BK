/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/23  NB      Added Warehouse mandatory filter (CIMSV3-103)
  2020/06/08  NB      Added BusinessUnit global filter (CIMSV3-954)
  2020/05/30  AJ      Temporary fix: Commented Visible field to fix controls page issue (HA-686)
  2020/05/21  KBB     Changed the filter type (HA-549) 
  2020/07/11  AY      If the dataset has Visible field, then we only need to show Visible = True records
  2020/03/26  TK      Setup visibility Selections (JL-163)
  2017/09/25  AY      Initial revision.
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName = '',
        @SelectionName         TName,
        @SelectionDescription  TDescription,
        @ttSelectionFilters    TSelectionFilters;

/******************************************************************************/
delete from @ttSelectionFilters;
select @SelectionName        = 'Global',
       @SelectionDescription = null;

insert into @ttSelectionFilters
            (FilterType, FieldName,          FilterOperation,    FilterValue,                        Visible)
      select 'G',        'Archived',         'Equals',           'N',                                'Y'
union select 'G',        'BusinessUnit',     'Equals',           '~SessionKey_BusinessUnit~',        'N'      -- This is never displayed to Users
union select 'M',        'Warehouse',        'Equals',           '~SessionKey_UserFilter_Warehouse~','N'      -- This is never displayed to Users
/* The following Visible configuration is commented temporarily due to Visible field datatype defined differently in different tables - need to revisit */
--union select 'G',        'Visible',          'Equals',           'N',                'Y'

exec pr_Setup_Selections @ContextName, @SelectionName, @SelectionDescription, 'D' /* Selection Type- Default */, default /* Visible */, @ttSelectionFilters;

Go
