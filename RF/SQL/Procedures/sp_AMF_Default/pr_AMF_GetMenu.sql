/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  NB      pr_AMF_GetMenu: changes to consider Permission Active and Visible to Enabled and Visible values(AMF-81)
  2019/01/18  NB      pr_AMF_GetMenu modified to return UIIconPath(AMF-28)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_GetMenu') is not null
  drop Procedure pr_AMF_GetMenu;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFConnect_GetMenu: Used to retrieve the rfconnect menu for a user
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_GetMenu
  (@ParentMenuName         TName,
   @UserName               TUserId,
   @DeviceId               TDeviceId,
   @BusinessUnit           TBusinessUnit,
   @OutputXML              TXML       = null output)
as
  declare @UserRoleId     integer,
          @vxmlMainMenu   xml;
begin /* pr_AMF_GetMenu */
  /* Read the User Role to fetch the permissions for Menu Items */
  select @UserRoleId = UserRoles.RoleId
  from Users
  inner join UserRoles on (Users.UserId = UserRoles.UserId)
  where (Users.UserName = @UserName) and (BusinessUnit = @BusinessUnit);

  /* Following CTE is recursive in nature. It starts with MenuItems of input ParentMenuId, and recursively fetches all the MenuItems
     with respective Permission Allowed flag

     MenuItem has two flags used in the UI
       Visible - This is the table column from AMFMenuDetails
       Enabled - This is computed based on the Status column of the AMFMenuDetails record and Role Permission Is Allowed field value

    *Explanation of MenuItem Status Column and it's role in defining whether the option is visible and/or enabled*

    Status = Inactive means that that menu option is not applicable for the client implementation and not shown at all
    Status = Active means that that menu option is applicable for the client implementation.
    Whether the menu item is visible and/or enabled is decided based on permissions.
    Assuming Status is Active, following will be how Visible and Enabled will be defined and used

    Visible = True - Menu item shown to user.
              AMF_Menu.Visible and Permission.IsVisible must be set to True

    Enabled
      is True  - if user has permission
      is False - if user does not have permission.

      Permission should be Active and Allowed for a Menu Item to be Enabled
    */
  ;
  with MenuItems
  as
    (
      select AMP.*
      from AMF_Menu AMP
      where (AMP.ParentMenuName = @ParentMenuName) and (AMP.Status = 'A' /* Active */) and (AMP.Visible > 0)
      union all
      select AMC.*
      from AMF_Menu AMC
        join MenuItems PM on (PM.MenuName = AMC.ParentMenuName)
      where (AMC.Status = 'A' /* Active */) and (AMC.Visible > 0)
    )
  select @vxmlMainMenu = (select MI.RecordId, MI.MenuName, MI.Caption, MI.ParentMenuName, MI.WorkFlowName, MI.FormName,
                                case when ((MI.Visible = 1) and (coalesce(PER.IsVisible, 0) = 1)) then 1 else 0 end as Visible,
                                case when ((coalesce(PER.IsActive, 0) = 1) and (coalesce(PER.IsAllowed, 0) = 1)) then 1 else 0 end as Enabled,
                                MI.SortSeq, PER.IsAllowed, RFWF.FormName,
                                 '~/Content/Images/Menu_' +  coalesce(MI.ParentMenuName + '_', '') + MI.MenuName + '.png' as UIIconPath
                         from MenuItems MI
                           left outer join vwRolePermissions PER on (PER.RoleId = @UserRoleId) and (PER.PermissionName = MI.PermissionName)
                           left outer join AMF_WorkFlowDetails RFWF on  (RFWF.WorkFlowName = MI.WorkFlowName) and
                                                                        ((RFWF.FormCondition is null) or (RFWF.FormSequence = 1))
                         where (MI.Visible > 0)
                         order by MI.SortSeq, MI.RecordId
                         FOR XML RAW('MenuItem'), TYPE, ELEMENTS, ROOT('MenuItems'));

  select @OutputXML = convert(varchar(max), @vxmlMainMenu);
end /* pr_AMF_GetMenu */

Go

