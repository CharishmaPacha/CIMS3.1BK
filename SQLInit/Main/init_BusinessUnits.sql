/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/04/06  TD      Syntax fixes.Removed semicolumns from the end.
  2012/04/15  YA      Changed BusinessUnit from 'LOEH' to 'TD' as Topson Downs specific.
  2011/07/08  AY      Customized for Loehmanns
------------------------------------------------------------------------------*/

Go

delete from BusinessUnits;

/*------------------------------------------------------------------------------
  BusinessUnit
------------------------------------------------------------------------------*/
insert into BusinessUnits
             (BusinessUnit,  BusinessUnitName,             Status,  CreatedBy,   SortSeq)
      select 'SCT',          'Supply Chain Technologies',  'A',     'SysAdmin',  1
--union select 'DEMO',         'The Demo Company',           'A',     'SysAdmin',  2
--union select 'LP',           'The Latin Products',         'A',     'SysAdmin',  100

Go
