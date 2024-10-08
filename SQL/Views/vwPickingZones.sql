/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/01/25  VM      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPickingZones') is not null
  drop View dbo.vwPickingZones;
Go

Create View dbo.vwPickingZones (
    ZoneId,
    ZoneDesc,
    Status,
    StatusDescription
) as
select
  PZL.LookUpCode,
  PZL.LookUpDescription,
  PZS.Status,
  PZS.StatusDescription
from
LookUps PZL
  left outer join Statuses  PZS  on (PZL.Status       = PZS.StatusCode  ) and
                                    (PZS.Entity       = 'Status'        ) and
                                    (PZS.BusinessUnit = PZL.BusinessUnit)
where (PZL.LookUpCategory = 'PickZones')
;

Go
