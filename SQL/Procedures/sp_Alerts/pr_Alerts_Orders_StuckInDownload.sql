/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/10  RKC     pr_Alerts_Orders_StuckInDownload: Initial revision (BK-433)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_Orders_StuckInDownload') is not null
  drop Procedure pr_Alerts_Orders_StuckInDownload;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_OrdersNot_PreProcessed: This procedure used to Get the list of Orders which
   not yet been pre-processed for more than one hour after being imported from CIMSDE.
   If those are not yet processed all orders still show as downloaded status.
   Such that we can not process them further with those orders.So We need to give an alert.
   Such we can fix the issue if any.

  @ReturnDataSet
    - Can be set to 'Y' when called EXCLUSIVELY from TSQL.
    - Ignores sending Alert
    - Returns dataset only

  EmailIfNoAlert - N: Would not send any email if there is nothing to alert
                   Y: Would send an email even if there is nothing to alert.
                      A job could be setup to do this once a month so that we know
                      that the job is active and running

------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_Orders_StuckInDownload
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 60 /* Orders not off download in 60 mins */,
   @ReturnDataSet               TFlags    = 'N',
   @EmailIfNoAlert              TFlags    = 'N')
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessage,
          @vRecordId        TRecordId;

  declare @vAlertCategory   TCategory;
begin
  /* Initialize */
  select @vAlertCategory = object_Name(@@ProcId), -- pr_ will be trimmed by pr_Email_SendDBAlert
         @vRecordId      = 0;

  /* Get the list of Orders which are still in Downloaded status after a long time. Either they were
     pre-processed or had errors.  */
  select OrderId, PickTicket, OrderType, SalesOrder, CustPO, Account, AccountName, ShipFrom, ShipToName, PreprocessFlag,
         cast('' as varchar(max)) ErrorMessage
  into #OrdersStuckInDownload
  from OrderHeaders with (nolock)
  where (Status = 'O' /* Downloaded */) and
        (datediff(mi, CreatedDate, getdate()) > @ShowModifiedInLastXMinutes);

  /* Get the Error info for which are the orders not yet pre-processed */
  select OH.OrderId, string_Agg(N.Message, ' || ') ErrorMessage
  into #ErrorInfo
  from #OrdersStuckInDownload OH
    left join Notifications N with (nolock) on (OH.OrderId = N.EntityId)
  where (N.EntityType = 'Order') and
        (N.status     = 'A')
  group by OH.OrderId
  order by OH.OrderId desc;

  /* Save the error back to #OrdersStuckInDownload */
  update OSID
  set ErrorMessage = EI.ErrorMessage
  from #OrdersStuckInDownload OSID join #ErrorInfo EI on (OSID.OrderId = EI.OrderId);

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #OrdersStuckInDownload;
      return(0);
    end

  /* email the results */
  if (@EmailIfNoAlert = 'Y') or (exists (select * from #OrdersStuckInDownload))
    exec pr_Email_SendQueryResults @vAlertCategory, '#OrdersStuckInDownLoad', null /* order by */, @BusinessUnit;
end /* pr_Alerts_Orders_StuckInDownload */

Go
