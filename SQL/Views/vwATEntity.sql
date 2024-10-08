/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/11/11  AY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwATEntity') is not null
  drop View dbo.vwATEntity;
Go

Create View dbo.vwATEntity (
  AuditId,
  ActivityType,
  ActivityDateTime,

  EntityType,
  EntityId,
  EntityKey,

  Comment,

  NumOrders,
  NumPallets,
  NumLPNs,
  NumSKUs,

  InnerPacks,
  Quantity,

  Archived,
  ProductivityFlag,
  ProductivityId,

  DeviceId,
  BusinessUnit,
  UserId
) As
select
  AT.AuditId,
  AT.ActivityType,
  AT.ActivityDateTime,

  AE.EntityType,
  AE.EntityId,
  AE.EntityKey,

  AT.Comment,

  AT.NumOrders,
  AT.NumPallets,
  AT.NumLPNs,
  AT.NumSKUs,

  AT.InnerPacks,
  AT.Quantity,

  AT.Archived,
  AT.ProductivityFlag,
  AT.ProductivityId,

  AT.DeviceId,
  AT.BusinessUnit,
  AT.UserId
From
AuditTrail AT join AuditEntities AE on AT.AuditId = AE.AuditId

Go
