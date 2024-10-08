/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved.

  Revision History:

  Date        Person  Comments

  2014/11/27  PKS     Initial revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwUserLogin') is not null
  drop View dbo.vwUserLogin;
Go

Create View dbo.vwUserLogin(
  AuditId,
  UserName,
  LoginTime,
  DeviceId
) As
select
  AuditId,
  UserId,
  convert(varchar(24), ActivityDateTime, 113),
  DeviceId
from AuditTrail

Go
