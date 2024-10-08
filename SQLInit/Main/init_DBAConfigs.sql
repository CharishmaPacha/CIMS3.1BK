/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/15  SK      Initial Revision
------------------------------------------------------------------------------*/

Go

/*
Fields Explanation

Drive         - Drive letter on the system
Purpose       - Purpose of the drive on the system
MinFreeLimit  - The minimum disk space that should exist for the drive specified
LowFreeLimit  - The lowest possible disk space below which is regarded as high risk of application issues

*/

declare @vControlCategory    TCategory;

/* Clear any data already present */
if (exists(select * from DBAConfigs))
  begin
    truncate table DBAConfigs;
    dbcc checkident('DBAConfigs', reseed, 1);
  end

/*------------------------------------------------------------------------------*/
/* Drive DriveSpace related setup */
/*------------------------------------------------------------------------------*/
select @vControlCategory = 'DriveSpace';

insert into DBAConfigs
              (ControlCategory,   Drive,  Purpose,    Description,         MinFreeLimit, LowFreeLimit, Status, BusinessUnit)
      select   @vControlCategory, 'C',    'sys',      'SystemFiles',       '35',         '25',         'A',    BU.BusinessUnit from vwBusinessUnits BU
union select   @vControlCategory, 'D',    'db',       'DB files',          '50',         '25',         'A',    BU.BusinessUnit from vwBusinessUnits BU
union select   @vControlCategory, 'T',    'temp',     'TempDB files',      '25',         '15',         'A',    BU.BusinessUnit from vwBusinessUnits BU

Go