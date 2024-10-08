/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/05  PK      Added Warehouse (HA-1233)
  2020/05/27  VM      Initial revision (HA-251)
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPrintRequests') is not null
  drop View dbo.vwPrintRequests;
Go

Create View dbo.vwPrintRequests (
  PrintRequestId,

  RequestOperation,
  RequestXML,
  RequestMode,

  PrintRequestStatus,
  PrintRequestStatusDesc,
  Priority,
  Notifications,

  Warehouse,

  PR_UDF1,
  PR_UDF2,
  PR_UDF3,
  PR_UDF4,
  PR_UDF5,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  PR.PrintRequestId,

  PR.RequestOperation,
  PR.RequestXML,
  PR.RequestMode,

  PR.PrintRequestStatus,
  ST.StatusDescription,
  PR.Priority,
  PR.Notifications,

  PR.Warehouse,

  PR.PR_UDF1,
  PR.PR_UDF2,
  PR.PR_UDF3,
  PR.PR_UDF4,
  PR.PR_UDF5,

  PR.Archived,
  PR.BusinessUnit,
  PR.CreatedDate,
  PR.ModifiedDate,
  PR.CreatedBy,
  PR.ModifiedBy
from
  PrintRequests PR
  left outer join Statuses ST on (ST.StatusCode    = PR.PrintRequestStatus) and
                                 (ST.Entity        = 'PrintRequest'       ) and
                                 (ST.BusinessUnit  = PR.BusinessUnit      );

Go
