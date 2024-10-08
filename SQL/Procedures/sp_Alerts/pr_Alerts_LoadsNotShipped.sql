/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/26  OK      pr_Alerts_LoadsNotShipped: Added new procedure to send Loads which are not being shipped (HA-2379)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_LoadsNotShipped') is not null
  drop Procedure pr_Alerts_LoadsNotShipped;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_LoadsNotShipped:
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_LoadsNotShipped
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 43200 /* Works for entities which are modified in 30 days */,
   @EntityId                    TRecordId = null,
   @ReturnDataSet               TFlags    = 'N',
   @EmailIfNoAlert              TFlags    = 'N')
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vAlertCategory     TCategory;

begin
  /* Initialize */
  select @vAlertCategory = Object_Name(@@ProcId), -- pr_ will be trimmed by pr_Email_SendDBAlert
         @vRecordId      = 0;

  /* Get the Loads which are not being shipped since more than 30 minutes */
  select LoadId, LoadNumber, LoadTypeDesc as LoadType, LoadStatusDesc Status, NumOrders Orders,
         FromWarehouse Warehouse, ShipVia, CreatedDate CreatedDate, ModifiedDate ShipLastTried
  into #ttAlertData
  from vwLoads with (nolock)
  where (Status = 'SI' /* Shipping In-progress */) and
        (datediff(mi, ModifiedDate, getdate()) between 60 and @ShowModifiedInLastXMinutes) and
        (LoadId = coalesce(@EntityId, LoadId));

  /* Return if no records are fetched */
  if (@@rowcount = 0) return(0);

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #ttAlertData;
      return(0);
    end

  /* Email the results */
  exec pr_Email_SendQueryResults @vAlertCategory, '#ttAlertData', null /* order by */, @BusinessUnit;
end /* pr_Alerts_LoadsNotShipped */

Go
