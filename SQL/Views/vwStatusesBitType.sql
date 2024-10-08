/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/03/08  VK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwStatusesBitType') is not null
  drop View dbo.vwStatusesBitType;
Go

Create View dbo.vwStatusesBitType (
  Entity,
  StatusCode,
  SortSeq,
  StatusDescription,
  Status
)As
select
  SB.Entity,
  cast(SB.StatusCode as bit),
  SB.SortSeq,
  SB.StatusDescription,
  Sb.Status
from Statuses SB
where Entity = 'StatusBitType';

Go
