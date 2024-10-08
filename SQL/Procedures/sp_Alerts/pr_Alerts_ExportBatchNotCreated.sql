/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_ExportBatchNotCreated') is not null
  drop Procedure pr_Alerts_ExportBatchNotCreated;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_ExportBatchNotCreated: If there is data in Exports table that
    has not been processed for the last 1 hr, then raise an alert.
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_ExportBatchNotCreated
  (@BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessage,
          @vRecordId        TRecordId;

  declare @vAlertCategory   TCategory;
begin
  /* Initialize */
  select @vAlertCategory = Object_Name(@@ProcId), -- pr_ will be trimmed by pr_Email_SendDBAlert
         @vRecordId      = 0;

  /* get the Export records for which batch is not generated since more than one hour */
  select OrderId, LoadId, TransType, count(*) NoOfRecords
  into #OrdersToExport
  from Exports with (nolock)
  where (Status= 'N') and (ExportBatch = 0) and
        (datediff(hour, CreatedDate, getdate()) > 1)
  group by OrderId, LoadId, TransType;

  if (@@rowcount = 0) return(0);

  /* Email the results */
  exec pr_Email_SendQueryResults @vAlertCategory, '#OrdersToExport', null /* order by */, @BusinessUnit;
end /* pr_Alerts_ExportBatchNotCreated */

Go
