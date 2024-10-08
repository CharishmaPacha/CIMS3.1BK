/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/07/18  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwAuditTrail') is not null
  drop View dbo.vwAuditTrail;
Go

Create View dbo.vwAuditTrail (
  AuditId,
  ActivityType,
  ActivityDateTime,

  NumOrders,
  NumPallets,
  NumLPNs,
  NumSKUs,

  InnerPacks,
  Quantity,

  Comment,
  Archived,
  ProductivityFlag,
  ProductivityId,

  DeviceId,
  BusinessUnit,
  UserId
) As
select
  A.AuditId,
  A.ActivityType,
  A.ActivityDateTime,

  A.NumOrders,
  A.NumPallets,
  A.NumLPNs,
  A.NumSKUs,

  A.InnerPacks,
  A.Quantity,

  A.Comment,
  A.Archived,
  A.ProductivityFlag,
  A.ProductivityId,

  A.DeviceId,
  A.BusinessUnit,
  A.UserId
From
AuditTrail A

Go
