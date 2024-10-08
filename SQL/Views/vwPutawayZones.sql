/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/03/10  PV      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPutawayZones') is not null
  drop View dbo.vwPutawayZones;
Go

Create View dbo.vwPutawayZones (
    ZoneId,
    ZoneDesc,
    Status,
    StatusDescription,
    BusinessUnit
) as
select
  PZL.LookUpCode,
  PZL.LookUpDescription,
  PZS.Status,
  PZS.StatusDescription,
  PZL.BusinessUnit
from
LookUps PZL
  left outer join Statuses  PZS  on (PZL.Status       = PZS.StatusCode  ) and
                                    (PZS.Entity       = 'Status'        ) and
                                    (PZS.BusinessUnit = PZL.BusinessUnit)
where (PZL.LookUpCategory = 'PutawayZones')
;

Go
