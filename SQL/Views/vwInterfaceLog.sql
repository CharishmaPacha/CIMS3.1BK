 /*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/19  KBB     Added Archived field (HA-1309)
  2020/08/28  RKC     Added CreatedOn (CIMSV3-195)
  2020/08/12  MS      Rename Status to InterfaceLogStatus (HA-283)
  2016/08/17  PSK     Changed the vwUDF's to use cast(' ' as varchar(50)).(CIMS-1027).
  2016/04/18  NB      Replaced InputXML with HasInputXML(CIMS-781)
  2014/01/09  DK      Initial Revision.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.vwInterfaceLog') is not null
  drop View dbo.vwInterfaceLog;
Go

Create View dbo.vwInterfaceLog (
  RecordId,

  SourceSystem,
  TargetSystem,

  InputXML, -- deprecated, do not use
  HasInputXML,

  RecordTypes,
  TransferType,
  InterfaceLogStatus,
  InterfaceLogStatusDesc,

  RecordsProcessed,
  RecordsFailed,
  RecordsPassed,

  SourceReference,

  StartTime,
  EndTime,

  AlertSent,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy,

  CreatedOn,

  /* Place holders for any new fields, if required */
  vwIL_UDF1,
  vwIL_UDF2,
  vwIL_UDF3,
  vwIL_UDF4,
  vwIL_UDF5)
as
select
  IL.RecordId,

  IL.SourceSystem,
  IL.TargetSystem ,

  null /* Input XML */,
  case when (IL.InputXML is not null) then 'I' /* Info or Data */ else null end,

  IL.RecordTypes,
  IL.TransferType,
  IL.Status,
  ST.StatusDescription,

  IL.RecordsProcessed,
  IL.RecordsFailed,
  IL.RecordsPassed,

  IL.SourceReference,

  IL.StartTime,
  IL.EndTime,

  IL.AlertSent,

  IL.Archived,
  IL.BusinessUnit,
  IL.CreatedDate,
  IL.ModifiedDate,
  IL.CreatedBy,
  IL.ModifiedBy,

  IL.CreatedOn,

  cast(' ' as varchar(50)), /* vwIL_UDF1 */
  cast(' ' as varchar(50)), /* vwIL_UDF2 */
  cast(' ' as varchar(50)), /* vwIL_UDF3 */
  cast(' ' as varchar(50)), /* vwIL_UDF4 */
  cast(' ' as varchar(50))  /* vwIL_UDF5 */

from
  InterfaceLog IL
  left outer join Statuses          ST   on (ST.StatusCode    = IL.Status       ) and
                                            (ST.Entity        = 'InterfaceLog'  )
;

Go
