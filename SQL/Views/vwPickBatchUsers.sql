/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/06/21  AY      Changed to not retrieve Users of Inactive BusinessUnits
  2012/05/16  PKS     Migrated from FH.
  2012/03/21  AY      Added UserId, Name, ShortName fields
  2012/03/19  PKS     Initial revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPickBatchUsers') is not null
  drop View dbo.vwPickBatchUsers;
Go

Create View dbo.vwPickBatchUsers (
  UserId,
  UserName,
  Name,
  ShortName
) As
select
  U.UserId,
  U.UserName,
  U.Name,
  U.ShortName
from
((
  Users U
             join BusinessUnits BU  on (U.BusinessUnit = BU.BusinessUnit) and
                                       (BU.Status      = 'A' /* Active */)
  left outer join UserRoles     UR  on (U.UserId   = UR.UserId))
  left outer join Roles         R   on (UR.RoleId  = R.RoleId))
where (U.IsActive = 1 /* True */);

Go
