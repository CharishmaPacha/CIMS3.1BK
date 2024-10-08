/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/10  NB      Initialise UserFilters with a Default Value(CIMSV3-103)
  2019/12/19  SK      PermissionId is deprecated to be referenced (CIMS-2656)
  2019/12/11  AY      Setup default Warehouse on Users
  2019/05/29  SK      Insert PermissionName to RolePermissions table (CIMS-2656)
  2018/03/01  AY      Standardize User Ids (CIMS-1903)
  2016/02/01  AY      Corrected userids to remove references to foxfire india in emails.
                      Give all permissions to Role 1 using trigger, hence commented it out here
  2014/12/03  VM      Turned off to provide permissions to all roles except SysAdmin by default
  2014/10/22  VM      Provide all export to PDF/XLS feature permissions to all roles by default
  2012/04/16  AY      Added a new RFUser for RF Testing with a simple password and
                      changed BU to be generic
  2012/04/15  YA      Changed BusinessUnit from 'LOEH' to 'TD' as Topson Downs specific.
  2011/09/08  VM      Created 'admin' user for client
  2010/06/28  NB      Initial Revision.
------------------------------------------------------------------------------*/

Go

delete from Users;
--delete from RolePermissions; /* commented this as we are inserting all permissions by trigger while creating blank DB */

--Disable Trigger [tr_Users_IOI_AddUser] on Users;

/* Get the default Warehouse */
declare @vDefaultWarehouse TWarehouse;

select top 1 @vDefaultWarehouse = LookupCode
from vwLookUps
where LookUpCategory = 'Warehouse'
order by SortSeq;

insert into Users (UserName, Password, FirstName, LastName, Email, IsActive, BusinessUnit)
            select 'cimsadmin', 'Fcd3bK2lUwesO/+6k0hUug==' /* rf!c0nnect */, 'CIMS',        'Administrator',BusinessUnit + 'support@cloudimsystems.com',   1, BusinessUnit from vwBusinessUnits
      union select 'superuser', 'QMfirncgbkBuoZfh1DotuQ==' /* Sup3ruser */,   BusinessUnit, 'Administrator',               'superuser@cimscustomer.com',   1, BusinessUnit from vwBusinessUnits
      union select 'rfuser',    'xrzzzFqS+qo='             /* 123 */,        'RF',          'User',                        'rfuser@cimscustomer.com',      1, BusinessUnit from vwBusinessUnits

/* Update default Warehouse for standard users created above */
update Users
set DefaultWarehouse = @vDefaultWarehouse;

insert into UserRoles (UserId, RoleId)
            select UserId, 999 from Users where UserName = 'cimsadmin' /* SysAdmin */
      union select UserId, 2   from Users where UserName = 'superuser'    /* Client's Admin */
      union select UserId, 20  from Users where UserName = 'rfuser'   /* Default RF User for Testing */;

/* Provide all permissions to SysAdmin */
/* This is not handled in trig_Permissions */
--insert into RolePermissions (RoleId, PermissionId)
--  select 1 /* SysAdmin */, PermissionId from Permissions where IsVisible = 1;

/* Provide permission of Export to PDF and Excel to all roles by default */
insert into RolePermissions (RoleId, PermissionName)
  select R.RoleId, P.PermissionName from Roles R, Permissions P
  where (((P.PermissionName like '%XLSExport%')  or
          (P.PermissionName like '%PDFExport%')) and
          (R.RoleId <> 1) and (P.IsVisible <> 0) /* We did for 0 in trig_Permissions*/ );

--Enable Trigger [tr_Users_IOI_AddUser] on Users;

/* Update users created with default filter groups */
update Users
set UserFilters = '<UserFilters><FilterGroup><GroupKey>Warehouse</GroupKey><FilterValues><FilterRecord><FilterValue>*</FilterValue></FilterRecord></FilterValues></FilterGroup></UserFilters>'
where UserFilters is null;
