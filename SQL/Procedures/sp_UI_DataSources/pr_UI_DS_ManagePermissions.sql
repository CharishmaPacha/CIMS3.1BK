/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/05  AY      pr_UI_DS_ManagePermissions: Show permissions sorted correctly (OBV3-597)
  2021/07/08  NB      Added pr_UI_DS_ManagePermissions(CIMSV3-1341)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_UI_DS_ManagePermissions') is not null
  drop Procedure pr_UI_DS_ManagePermissions;
Go
/*------------------------------------------------------------------------------
  Prod pr_UI_DS_ManagePermissions: Datasource procedure for Manage Permissions page.
   The data is returned via #ResultDataSet
------------------------------------------------------------------------------*/
Create Procedure pr_UI_DS_ManagePermissions
  (@xmlInput     XML,
   @OutputXML    TXML = null output)
as
  declare @vBusinessUnit      TBusinessUnit,
          @vUserId            TUserId,
          @vInputRoleId       integer,
          @vInputUserId       TUserId;

begin /* pr_UI_DS_ManagePermissions */

  /* #ResultDataSet of type vwUIRolePermissions should have been created by caller */
  if (object_id('tempdb..#ResultDataSet')) is null return;

  select @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @vUserId        = Record.Col.value('(SessionInfo/UserId)[1]',       'TUserName'),
         @vInputRoleId   = Record.Col.value('(Data/RoleId)[1]',              'integer'),
         @vInputUserId   = Record.Col.value('(Data/UserId)[1]',              'TUserId')
  from @xmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlInput = null ));

  if (@vInputRoleId is null) and (@vInputUserId is null)
    begin
      insert into #ResultMessages (MessageType, MessageText) select 'E' /* Error */, 'User or Role required!!!';
      return;
    end

  if (object_id('tempdb..#ManagePermissions_UserRoles') is not null)
    drop table #ManagePermissions_UserRoles;

  select * into #ManagePermissions_UserRoles from UserRoles where 1=2;

  insert into #ManagePermissions_UserRoles(UserId, RoleId)
    select UserId, RoleId
    from UserRoles
    where (UserId = coalesce(@vInputUserId, UserId)) and
          (RoleId = coalesce(@vInputRoleId, RoleId));

  /* there can be instances when no user is assigned the selected role
     in this scenario, insert the inputs directly into the temp table */
   if (not exists (select  * from #ManagePermissions_UserRoles))
     insert into #ManagePermissions_UserRoles(UserId, RoleId)
       select coalesce(@vInputUserId, 0), coalesce(@vInputRoleId, 0);

  insert into #ResultDataSet(RolePermissionKey, PermissionId, PermissionName, Application, Operation, Description,
                             IsActive, IsVisible, RoleId, RolePermissionId, IsAllowed, IsAllowedBitValue,
                             RoleName, RoleDescription, OperationDescription, NodeLevel, SortSeq)
    select RolePermissionKey, PermissionId, PermissionName, Application, Operation, Description,
          IsActive, IsVisible, RoleId, RolePermissionId, IsAllowed, IsAllowedBitValue,
          RoleName, RoleDescription, OperationDescription, NodeLevel, SortSeq
    from vwActiveUIRolePermissions
    where (RoleId in (select RoleId from #ManagePermissions_UserRoles))
    order by SortSeq;

  /* UI expects the Primary Permission for UI and RF to have Operation as null */
  update #ResultDataSet
  set Operation = null
  where (Operation = PermissionName);

end /* pr_UI_DS_ManagePermissions */

Go
