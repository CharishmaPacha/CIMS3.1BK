 /*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/12  MS      Added InterfaceLogStatus & Statusdesc (HA-283)
  2016/08/17  PSK     Changed the vwUDF's to use cast(' ' as varchar(50)).(CIMS-1027).
  2016/04/18  NB      Replaced InputXML with HasInputXML, and ResultXML with HasResultXML (CIMS-781)
  2014/01/09  DK      Initial Revision.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.vwInterfaceLogDetails') is not null
  drop View dbo.vwInterfaceLogDetails;
Go

Create View dbo.vwInterfaceLogDetails (
  RecordId,
  ParentLogId,
  TransferType,
  RecordType,
  InterfaceLogStatus,
  LogMessage,

  LogDateTime,

  KeyData,
  HostReference,
  InputXML,  -- deprecated, do not use
  ResultXML, -- deprecated, do not use,
  HasInputXML,
  HasResultXML,
  LogDate,
  BusinessUnit,

  /* Place holders for any new fields, if required */
  vwILD_UDF1,
  vwILD_UDF2,
  vwILD_UDF3,
  vwILD_UDF4,
  vwILD_UDF5)
as
select
  ILD.RecordId,
  ILD.ParentLogId,
  ILD.TransferType,
  ILD.RecordType,
  ILD.Status,
  ILD.LogMessage,

  ILD.LogDateTime,
  ILD.KeyData,
  ILD.HostReference,
  null /* Input XML */,
  null /* Result XML */,
  case when (ILD.InputXML is not null) then 'I'  /* Info / Data */ else null end,
  case when (ILD.ResultXML is not null) then 'E' /* Error */ else null end,
  ILD.LogDate,
  ILD.BusinessUnit,

  cast(' ' as varchar(50)), /* vwILD_UDF1 */
  cast(' ' as varchar(50)), /* vwILD_UDF2 */
  cast(' ' as varchar(50)), /* vwILD_UDF3 */
  cast(' ' as varchar(50)), /* vwILD_UDF4 */
  cast(' ' as varchar(50))  /* vwILD_UDF5 */

from
  InterfaceLogDetails ILD
;

Go
